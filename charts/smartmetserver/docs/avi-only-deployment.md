# AVI-only SmartMet Server deployment

How to run the `smartmetserver` chart so that the **AVI engine** (and
optionally the **AVI plugin**) talks to a populated AVI PostGIS
database, with the **EDR plugin** as the HTTP API surface.

This is the configuration that lets you reach things like
`/edr/collections/metar`, `/edr/collections/taf`, `/edr/collections/sigmet`
without needing any querydata, observation or grid data.

For the database side, see
[`avi-database-setup.md`](avi-database-setup.md). This document
assumes the AVI database already exists and is reachable.

## 1. Image requirements

The default `fmidev/smartmetserver` image:

- Includes `smartmet-engine-avi` (`engines/avi.so` is loaded).
- Currently **does not include** `smartmet-plugin-avi`. With the
  `avi.so` plugin missing, smartmetd refuses to start if it is listed
  in `plugins:` (see PR
  [`fmidev/docker-smartmetserver#18`](https://github.com/fmidev/docker-smartmetserver/pull/18)
  to add the package).
- Image versions older than `26.03.x` had a memory bug that crashed
  the avi engine at init when given a real `postgis` config (engines 1
  and 2 init, then `double free or corruption (out)`). Use a recent
  image such as `26.03.19` or newer.

## 2. Helm values

The canonical minimum-viable values file is in
[`examples/values-avi-only.yaml`](../examples/values-avi-only.yaml).
Use it as a starting point:

```bash
PASS=$(kubectl get secret <db-secret> -o jsonpath='{.data.password}' | base64 -d)
helm upgrade --install smartmetserver-avi charts/smartmetserver \
  -n aviengine \
  -f charts/smartmetserver/examples/values-avi-only.yaml \
  --set "smartmetConf.avi.engine.postgis.password=$PASS"
```

The example pins the minimum engines and plugins for an AVI-focused
deployment:

| `smartmetConf.engines` | `smartmetConf.plugins` |
| --- | --- |
| `avi`, `geonames`, `gis`, `grid`, `querydata` | `edr` |

Why not fewer:

- `geonames`, `gis`, `grid`, `querydata` are **hard ELF symbol deps of
  `edr.so`** — drop any of them and the plugin fails to load with
  `undefined symbol: SmartMet::Engine::<Name>::Engine`. Their data
  files do not need to be populated, but the engines must initialize.
- `sputnik`, `contour`, `observation` from the chart defaults are not
  needed and can stay removed.
- All other plugins (`autocomplete`, `download`, `timeseries`, `wms`)
  can also stay removed for an AVI-only deployment.

The chart still:

- Renders `avi-engine.conf` and `avi-plugin.conf` from
  `smartmetConf.avi.*` values into a `Secret`.
- Mounts those at `/etc/smartmet/engines/avi.conf` and
  `/etc/smartmet/plugins/avi.conf`.

The avi plugin is **not** added to the rendered plugins list
automatically. Add `avi` to `smartmetConf.plugins` explicitly when
the image ships `plugins/avi.so` (tracked in
[`fmidev/docker-smartmetserver#18`](https://github.com/fmidev/docker-smartmetserver/pull/18)).

## 3. EDR config (manual override)

The `edr` plugin needs two extra blocks added to its config to expose
AVI-backed collections. The chart does **not** template the EDR config
today, so you have to provide it yourself via a ConfigMap and patch the
deployment.

Steps:

1. Read the image's default `edr.conf` from a running pod:

   ```bash
   kubectl exec -n aviengine <pod> -- cat /etc/smartmet/plugins/edr.conf > edr.conf
   ```

2. Edit the resulting file:

   - Flip `aviengine_disabled = true;` to `aviengine_disabled = false;`.
   - Add an `avi` top-level group (this is what defines which
     collections actually exist):

     ```text
     avi:
     {
       period_length = 30;
       collections:
       (
         { name = "metar";  countries = ["EE"]; },
         { name = "taf";    countries = ["EE"]; },
         { name = "sigmet"; countries = ["EE"]; }
       );
     };
     ```

     **Use `countries` or `icaos`, not `bbox`** — there is a known
     engine bug where `queryStationsWithBBoxes` does not join the FIR
     table even when the SELECT references it
     (`missing FROM-clause entry for table "fi"`).

   - Inside the existing `collection_info { … }` block, add an
     `avi_engine` array next to `querydata_engine`. This supplies
     human-readable metadata for the collections:

     ```text
     collection_info:
     {
       querydata_engine: ( … existing entries … ),
       avi_engine:
       (
         { id = "metar";  title = "METAR message";
           description = "A METAR describes the current weather conditions at a location";
           keywords = ["METAR"]; },
         { id = "taf";    title = "TAF message";
           description = "A Terminal Aerodrome Forecast message";
           keywords = ["TAF"]; },
         { id = "sigmet"; title = "SIGMET message";
           description = "Significant Meteorological Information is a severe weather advisory…";
           keywords = ["SIGMET"]; }
       )
     }
     ```

3. Create a ConfigMap with the merged file:

   ```bash
   kubectl create configmap smartmet-edr-conf -n aviengine \
     --from-file=edr.conf=edr.conf
   ```

4. Mount it over the image's `/etc/smartmet/plugins/edr.conf`:

   ```bash
   kubectl patch deployment smartmetserver-avi -n aviengine --type=json -p '[
     {"op":"add","path":"/spec/template/spec/volumes/-","value":{"name":"smartmet-edr-config","configMap":{"name":"smartmet-edr-conf"}}},
     {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts/-","value":{"name":"smartmet-edr-config","mountPath":"/etc/smartmet/plugins/edr.conf","subPath":"edr.conf"}}
   ]'
   ```

The ConfigMap mount will survive the next chart upgrade unless you
explicitly remove it. A first-class chart option for overriding
`edr.conf` is a planned follow-up — until then, this manual mount is
the supported workaround.

## 4. Verification

```bash
# Cert and ingress reachable
curl -fsSk https://avi.example.com/edr/collections >/dev/null && echo OK

# Avi-backed collections show up
curl -sSk https://avi.example.com/edr/collections \
  | python3 -c "import json,sys; [print(c['id'],'-',c['title']) for c in json.load(sys.stdin)['collections']]"
# expected:
#   metar - METAR message
#   sigmet - SIGMET message
#   taf - TAF message
```

If the collections list is empty:

- Check the pod logs for `permission denied`, `Unknown country code`,
  or `missing FROM-clause` — they point to the database setup steps in
  [`avi-database-setup.md`](avi-database-setup.md) and the `bbox` →
  `countries` workaround above.
- Check that the `aviengine_disabled = false` change actually took
  effect: `kubectl exec <pod> -- grep aviengine_disabled /etc/smartmet/plugins/edr.conf`.

The only smartmet-side configuration not yet covered by chart values
is `edr.conf` (collections, query types, output formats), hence the
ConfigMap workaround in section 3.
