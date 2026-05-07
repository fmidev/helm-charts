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
- Image tag `26.01.14` and earlier hit a thread-safety bug in
  multi-engine init that aborts smartmetd with `free(): invalid
  pointer` / `double free or corruption (out)` immediately after the
  geonames admin handler registers, regardless of avidb data state.
  The bug was implicitly fixed by `26.02.09`. Use **`26.02.09` or
  newer** (the example values pin `26.03.19`).

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

## 3. EDR config override

The `edr` plugin needs two extra blocks added to its config to expose
AVI-backed collections. The chart accepts a full `edr.conf` body via
`smartmetConf.edrConf`. When set, the chart renders a Secret and
mounts it over `/etc/smartmet/plugins/edr.conf`. When empty (default),
the image's bundled config is used unchanged.

The simplest workflow:

1. Pull the image's default `edr.conf` from a running pod and use it
   as a starting point:

   ```bash
   kubectl exec -n aviengine <pod> -- cat /etc/smartmet/plugins/edr.conf > edr.conf
   ```

2. Edit it:

   - Flip `aviengine_disabled = true;` to `aviengine_disabled = false;`.
   - Add an `avi` top-level group defining the AVI collections. The
     example below uses Estonian aerodromes with one synthetic
     `EETT` station representing the FIR (see
     [`avi-database-setup.md`](avi-database-setup.md) §4 — "Synthetic
     FIR-station for SIGMET-as-single-location"):

     ```text
     avi:
     {
       period_length = 30;
       collections:
       (
         { name = "metar";  countries = ["EE"]; excludeicaofilters = ["EETT"]; },
         { name = "taf";    countries = ["EE"]; excludeicaofilters = ["EETT"]; },
         { name = "sigmet"; icaos     = ["EETT"]; }
       );
     };
     ```

     - `excludeicaofilters = ["EETT"]` keeps the synthetic FIR-station
       out of METAR/TAF results (where it isn't a real aerodrome).
     - `icaos = ["EETT"]` makes SIGMET collapse to a single FIR-level
       location instead of one entry per aerodrome.
     - **Use `countries` or `icaos`, not `bbox`** — there is a known
       engine bug where `queryStationsWithBBoxes` does not join the
       FIR table even when the SELECT references it
       (`missing FROM-clause entry for table "fi"`).

   - Inside the existing `collection_info { … }` block, add an
     `avi_engine` array next to `querydata_engine`:

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

3. Pass the edited file as `smartmetConf.edrConf` (the chart will
   wrap it in a Secret and mount it):

   ```bash
   helm upgrade --install smartmetserver-avi charts/smartmetserver \
     -n aviengine \
     -f charts/smartmetserver/examples/values-avi-only.yaml \
     --set-file "smartmetConf.edrConf=edr.conf" \
     --set "smartmetConf.avi.engine.postgis.password=$PASS"
   ```

   Or commit the body inline in your values file:

   ```yaml
   smartmetConf:
     edrConf: |
       verbose = true;
       aviengine_disabled = false;
       avi:
       {
         …
       };
       collection_info:
       {
         …
       };
   ```

Leaving `smartmetConf.edrConf` unset (or empty) reverts to the image's
bundled `edr.conf`.

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

If the pod crashes during init you can flip on smartmetd's backtrace
handler with `smartmetConf.server.stacktrace: true` and re-deploy.
That installs the boost::stacktrace signal handler so SIGSEGV/SIGABRT
prints frames before exit. Default is off because it adds startup
overhead.

If the collections list is empty:

- Check the pod logs for `permission denied`, `Unknown country code`,
  or `missing FROM-clause` — they point to the database setup steps in
  [`avi-database-setup.md`](avi-database-setup.md) and the `bbox` →
  `countries` workaround above.
- Check that the `aviengine_disabled = false` change actually took
  effect: `kubectl exec <pod> -- grep aviengine_disabled /etc/smartmet/plugins/edr.conf`.

All chart-side configuration for an AVI-only deployment is covered by
chart values: `smartmetConf.avi.*` for the engine/plugin configs and
`smartmetConf.edrConf` for the EDR plugin's full config body.
