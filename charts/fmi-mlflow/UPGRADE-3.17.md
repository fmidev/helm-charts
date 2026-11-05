# Upgrading MLflow 3.5.1 → 3.17.1

Step-by-step runbook: first a rehearsal in the test environment, then the prod upgrade, rollback and cleanup.
Run every command yourself, in the order given. Each risky step has a **Stop if** line: if that happens, don't continue, roll back.

## 1. What changes and why

| | 3.5.1 (now) | 3.17.1 |
|---|---|---|
| Image | built in-cluster by a BuildConfig into ImageStream `mlflow:v3.5.1` | `ghcr.io/mlflow/mlflow:v3.17.1-full` (already has auth, postgres and s3 deps) |
| Auth config | hand-made secret `mlflow-auth-config` (DB host + password inside) | ConfigMap `mlflow-auth` rendered by the chart, no secrets inside; DB credentials from `PGUSER`/`PGPASSWORD` |
| Database | `pg-cluster-v1` | `pg-cluster-v2`, restored from a backup taken in the upgrade window |
| Probes | none | `/health` startup/readiness/liveness |

Why a new database cluster:
* Both databases get schema migrations: `app` (tracking) and `users` (basic-auth).
* 3.13 rewrote the permission system into RBAC. The `users` database is migrated **automatically when the server starts**, and the old permission tables are dropped in later versions. An image downgrade alone can't get back to 3.5.1.
* So we never touch `pg-cluster-v1`. It stays as-is. Rollback = point everything back to it (`helm rollback`).
* Cost: anything users write after the cutover is lost if we roll back.

Behaviour changes users may notice:
* `default_permission = READ` still applies to every user and resource without an explicit grant (workspaces are not enabled, so `grant_default_workspace_access` has no effect). Explicit grants, including `NO_PERMISSIONS`/`DENY`, still win. Existing grants are converted to RBAC roles by the migration. Creators still get `MANAGE` on what they create.
* basic-auth is **fail-closed** (3.16): API endpoints without an explicit permission rule return 403 instead of being allowed.
* New *client* defaults once users upgrade their SDK: `mlflow.sklearn`/`lightgbm` save with `skops`, `mlflow.pytorch` with `pt2` (3.14).
* Old clients (3.5.x) work against the 3.17 server. A 3.17 client against a 3.5 server may not, which is why **users must not upgrade their client until the rollback window is closed**.

Release revisions referenced below (prod):
* **rev 4** = current release, 3.5.1. This is the rollback target.
* rev 5 = upgrade with `replicas: 0`, rev 6 = `replicas: 1`.

Check with `helm history mlflow` before starting; use your actual numbers if they differ.

## 2. Test environment rehearsal (ock)

Goal: run the exact prod procedure on a copy of **prod data**, including a rollback, and time each step.

Throughout this section, `<test-cluster>` is the name of the cluster currently running in test (`oc get cluster`).

### 2.1 Prerequisites

```bash
oc login <ock>          # make sure you are on the TEST cluster
oc project mlflow       # or whatever the test namespace is
oc get secret s3-credentials postgresql-mlflow-secret postgresql-superuser-secret flask-secret mlflow-auth-config
oc get csv | grep cloudnative-pg     # same CNPG version as prod (1.27.x)
```

* The test release must currently be on the **old chart** (3.5.1). Check with `helm history mlflow`.
* Get the old chart into a separate directory (it no longer exists in the working tree):
  ```bash
  git worktree add /tmp/mlflow-old main
  OLD=/tmp/mlflow-old/charts/fmi-mlflow
  ```
* Prod data means prod users: log in with prod credentials during the rehearsal.

### 2.2 Restore prod data into test on 3.5.1 (the starting point)

Protect the current test cluster, then restore the latest prod backup into a new test cluster `pg-rehearsal-v1` with the old chart:

```bash
oc annotate cluster <test-cluster> helm.sh/resource-policy=keep

helm upgrade mlflow $OLD -f values-test-3.5.1.yaml \
  --set mlflow.replicas=0 \
  --set postgresql.clusterName=pg-rehearsal-v1 \
  --set recovery.enabled=true --set recovery.ondemand=false \
  --set recovery.serverName=pg-cluster-v1 \
  --set objectStorage.s3.backupPath=backups/prod

oc get cluster pg-rehearsal-v1 -w      # wait for "Cluster in healthy state"
```

> The old chart can't read backups from one path and write to another, so `pg-rehearsal-v1` also *writes* its own backups/WALs to
> `s3://mlflow/backups/prod/pg-rehearsal-v1/`. It's a separate folder and doesn't affect prod, but delete it in 2.7.

Point the old auth config at the rehearsal cluster (this is the manual step the new chart removes):

```bash
oc get secret mlflow-auth-config -o jsonpath='{.data.basic-auth\.ini}' | base64 -d > /tmp/basic-auth.ini
sed -i "s/@[a-z0-9-]*-rw/@pg-rehearsal-v1-rw/" /tmp/basic-auth.ini     # check the result!
oc create secret generic mlflow-auth-config --from-file=basic-auth.ini=/tmp/basic-auth.ini --dry-run=client -o yaml | oc apply -f -
rm /tmp/basic-auth.ini

helm upgrade mlflow $OLD -f values-test-3.5.1.yaml --reuse-values --set mlflow.replicas=1
```

Baseline, before the upgrade:
* Open `https://mlflow.out.ock.fmi.fi` and log in. You should see prod's experiments.
* Run the smoke test script (2.5) with a **3.5.x client** and note the run id. This creates an artifact in `s3://mlflow/test/` that you'll download after the upgrade.
* Record the database state (2.6, "before").
* `helm history mlflow`: the last revision is your **rehearsal rollback target (`<REV_OLD>`)**.

### 2.3 Pre-flight

The same thing you'll do in prod: protect the rollback targets from deletion by Helm.

```bash
oc annotate cluster pg-rehearsal-v1 helm.sh/resource-policy=keep
oc annotate imagestream mlflow helm.sh/resource-policy=keep
```

### 2.4 Upgrade (time each step)

Follow **section 4 (Prod upgrade window)** step by step, with these substitutions:

| prod | test rehearsal |
|---|---|
| `pg-cluster-v1` | `pg-rehearsal-v1` |
| `pg-cluster-v2` | `pg-rehearsal-v2` |
| `values-prod.yaml` | `values-test.yaml` |
| `mlflow.out.ocp.fmi.fi` | `mlflow.out.ock.fmi.fi` |

### 2.5 Test checklist

Smoke test script (save as `smoke_test.py`; run it once with a 3.5.x client and once with a 3.17.x client in separate venvs):

```python
import os, tempfile
import mlflow

# export MLFLOW_TRACKING_URI=https://mlflow.out.ock.fmi.fi
# export MLFLOW_TRACKING_USERNAME=... MLFLOW_TRACKING_PASSWORD=...
mlflow.set_experiment("upgrade-smoke-test")
with mlflow.start_run() as run:
    mlflow.log_param("client_version", mlflow.__version__)
    mlflow.log_metric("m", 1.0)
    d = tempfile.mkdtemp()
    with open(f"{d}/small.txt", "w") as f:
        f.write("hello")
    with open(f"{d}/big.bin", "wb") as f:     # tests the route timeout
        f.write(os.urandom(500 * 1024 * 1024))
    mlflow.log_artifacts(d)
print("run id:", run.info.run_id)
out = mlflow.artifacts.download_artifacts(run_id=run.info.run_id, artifact_path="small.txt")
print("downloaded:", open(out).read())
```

Check everything:

- [ ] `oc get pods`: the mlflow pod is `Running` and `1/1 Ready` (probes pass, the image works with OpenShift's random UID)
- [ ] `oc logs deploy/mlflow` has no tracebacks (look for `psycopg`, `password authentication failed`, `Permission denied`)
- [ ] Login works for the admin user and for one normal user
- [ ] Old experiments, runs, metrics and registered models are visible
- [ ] The artifact of the **baseline run from 2.2** downloads (UI and `mlflow.artifacts.download_artifacts(run_id=...)`)
- [ ] The smoke test passes with a **3.5.x client** and with a **3.17.x client** (incl. the 500 MB upload)
- [ ] Permissions survived: compare the database state (2.6) before/after and check a few users in the new Admin UI (`/admin`)
- [ ] A normal user can't edit an experiment they only have READ on
- [ ] One real user flow: ask one user to point a typical training script at test, or run it yourself (fail-closed auth may 403 on something we didn't test)
- [ ] `curl -s https://mlflow.out.ock.fmi.fi/health` → `OK`

**Stop if** any of these fail; the fix goes into the chart before the prod window.

### 2.6 Database state (before/after)

Uses the [cnpg kubectl plugin](https://cloudnative-pg.io/documentation/current/kubectl-plugin/) (`kubectl krew install cnpg`, or a binary from the CNPG releases).
`kubectl cnpg psql` connects to the cluster's current primary, so you don't need to know which pod that is. Everything after `--` is passed to `psql`.
Make sure kubectl points at the right cluster and namespace (`kubectl config current-context`, or add `-n <namespace>`).

```bash
CLUSTER=pg-rehearsal-v1         # prod: pg-cluster-v1 before, pg-cluster-v2 after the upgrade
oc cnpg status $CLUSTER    # healthy, which pod is the primary, last backup / WAL archiving

oc cnpg psql $CLUSTER -- -d app -c "select version_num from alembic_version;" \
  -c "select pg_size_pretty(pg_database_size('app')) app, pg_size_pretty(pg_database_size('users')) users;" \
  -c "select count(*) experiments from experiments;" -c "select count(*) runs from runs;" \
  -c "select count(*) models from registered_models;"
oc cnpg psql $CLUSTER -- -d users -c "\dt" -c "select count(*) users from users;"
# before (3.5.1):
oc cnpg psql $CLUSTER -- -d users -c "select permission, count(*) from experiment_permissions group by 1;" \
  -c "select permission, count(*) from registered_model_permissions group by 1;"
# after (3.17.1):
oc cnpg psql $CLUSTER -- -d users -c "select * from alembic_version_auth;" -c "select count(*) from role_permissions;"
```

Experiments/runs/models/users counts must be equal before and after.

### 2.7 Rollback drill, then roll forward

1. Do the **rollback** (section 5) with `<REV_OLD>`, then check that 3.5.1 works again on `pg-rehearsal-v1`: log in and see the baseline run. Runs created after the upgrade are *not* visible; that's expected.
2. Roll forward again. The kept `pg-rehearsal-v2` is reused as-is:
   ```bash
   oc scale deploy/mlflow --replicas=0
   helm upgrade mlflow . -f values-test.yaml   # with the same window values as in 2.4, replicas: 1
   ```
   Run the smoke test once more.
3. Write down the timings of section 4 steps 2–6. That's your prod downtime estimate for the user announcement.

Cleanup after the rehearsal:
```bash
oc delete cluster pg-rehearsal-v1          # and <test-cluster> when you no longer need it
# delete s3://mlflow/backups/prod/pg-rehearsal-v1/ with your S3 client, e.g.
# aws --endpoint-url https://lake.fmi.fi s3 rm --recursive s3://mlflow/backups/prod/pg-rehearsal-v1/
git worktree remove /tmp/mlflow-old
```

## 3. Prod pre-flight (a few days before)

Nothing here causes downtime.

```bash
oc login <ocp>; oc project mlflow
helm history mlflow                        # note the deployed revision (4) = rollback target
helm get values mlflow > values-prod-deployed-rev4.yaml   # reference copy
```

1. Record the database state (2.6, "before") with `CLUSTER=pg-cluster-v1`. Keep the output.
2. CNPG operator: make sure it can't be auto-upgraded to 1.31, which removes the in-tree barman backups this chart uses. The Subscription isn't visible in the `mlflow` namespace; ask the cluster admin to confirm the CNPG `installPlanApproval` is `Manual`.
3. Check that the last scheduled backup is recent: `oc get backup | tail -3` should show `completed`.
4. Protect the rollback targets:
   ```bash
   oc annotate cluster pg-cluster-v1 helm.sh/resource-policy=keep
   oc annotate imagestream mlflow helm.sh/resource-policy=keep
   oc get cluster pg-cluster-v1 imagestream/mlflow -o jsonpath='{range .items[*]}{.metadata.annotations.helm\.sh/resource-policy}{"\n"}{end}'
   # → keep
   # keep
   ```
   **Stop if** the output isn't `keep` twice. Without it, step 4.3 deletes `pg-cluster-v1` together with its volumes.
5. Optional: pre-pull the new image (it's large) so the window isn't spent downloading. Start any pod with the image, or simply time the pull in the rehearsal.
6. Announce to users (adjust the times):

   > MLflow will be upgraded from 3.5.1 to 3.17.1 on **<date> <hh:mm>–<hh:mm>**. MLflow is unavailable during that time.
   > Please make sure no training runs are logging to MLflow during the break; runs that try to log will fail.
   > After the upgrade:
   > * keep using your current `mlflow` client version until **<date + 2 weeks>**; please don't upgrade it before that
   > * permissions stay as they are: everyone can see all experiments and models, and can only log to their own (or ones they were given access to)
   > * there is a new Admin UI at /admin for managing permissions

## 4. Prod upgrade window

Make sure `values-prod.yaml` has the new structure (`auth`, `route`, no `image.build`) and `tag: ""`.

### 4.1 Stop the server

```bash
oc scale deploy/mlflow --replicas=0
oc get pods -l app.kubernetes.io/name=mlflow      # wait until no mlflow pods are left
```

### 4.2 Take an on-demand backup of the current database

```bash
cat <<EOF | oc apply -f -
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: pre-3-17
spec:
  method: barmanObjectStore
  cluster:
    name: pg-cluster-v1
EOF
oc get backup pre-3-17 -w          # wait for phase "completed"
```

**Stop if** the backup fails. Start the server again (`oc scale deploy/mlflow --replicas=1`) and investigate.

### 4.3 Deploy the new chart with a new database cluster (server stays stopped)

Edit `values-prod.yaml`:

```yaml
mlflow:
  replicas: 0

recovery:
  enabled: true
  ondemand: true
  name: pre-3-17

postgresql:
  clusterName: pg-cluster-v2
```

Check what will happen, then upgrade:

```bash
helm template mlflow . -n mlflow -f values-prod.yaml | grep -E "artifacts-destination|backend-store|database_uri|name: pre-3-17"
# → --artifacts-destination=s3://mlflow/prod/    (must be exactly this)
# → postgresql://pg-cluster-v2-rw.mlflow:5432/... (twice)
helm upgrade mlflow . -f values-prod.yaml
oc get cluster -w                  # pg-cluster-v2 → "Cluster in healthy state"
```

Expected: `pg-cluster-v1` is still there and healthy. The BuildConfig and the `mlflow-config` ConfigMap are gone, and the ImageStream is kept.

**Stop if** `pg-cluster-v2` doesn't get healthy (`oc logs` of the `pg-cluster-v2-1-full-recovery-*` pod), or if `pg-cluster-v1` is gone. In both cases → rollback (section 5).

### 4.4 Migrate the databases

```bash
oc delete job mlflow-migrate-job --ignore-not-found
oc process mlflow-migrate | oc apply -f -
oc logs -f job/mlflow-migrate-job
```

Expected: alembic `Running upgrade ...` lines for the tracking database, then for the auth database, and finally `Migrations done`.

**Stop if** the job fails → rollback (section 5). `pg-cluster-v1` is untouched, so nothing is lost.

### 4.5 Start the server

Set `mlflow.replicas: 1` in `values-prod.yaml` and:

```bash
helm upgrade mlflow . -f values-prod.yaml
oc get pods -l app.kubernetes.io/name=mlflow -w      # 1/1 Ready
oc logs deploy/mlflow
```

### 4.6 Verify

Go through the checklist in 2.5 against `https://mlflow.out.ocp.fmi.fi` (the 3.5.x client run is enough; skip the 500 MB upload if you like), and compare the database state with 2.6 (`CLUSTER=pg-cluster-v2`).

All good → tell the users MLflow is back. Not good → rollback (section 5).

## 5. Rollback

Takes a few minutes. Restores exactly what was running before (rev 4): MLflow 3.5.1 from the ImageStream, `pg-cluster-v1`, and the `mlflow-auth-config` secret.

```bash
oc scale deploy/mlflow --replicas=0
helm rollback mlflow 4                      # test: <REV_OLD>
oc get builds                               # the rollback recreates the BuildConfig, which starts a new build:
oc cancel-build <the new build>             # cancel it, the existing v3.5.1 image is used as-is
oc get pods -l app.kubernetes.io/name=mlflow -w
```

* `pg-cluster-v2` stays (keep policy), so you can inspect what went wrong.
* Restore `values-prod.yaml` from `values-prod-3.5.1.yaml` so that your local values match what's running.
* Tell users: anything logged after the upgrade is gone. Artifacts uploaded after the upgrade stay in S3 unreferenced.

## 6. After the rollback window (~2 weeks)

When you're sure there's no going back:

```bash
oc delete cluster pg-cluster-v1             # deletes its volumes; the s3 backups stay until you delete them
oc delete imagestream mlflow
oc delete secret mlflow-auth-config
oc delete backup pre-3-17
```

In `values-prod.yaml`, set `recovery.enabled: false` (it only matters when a cluster is created, but keeps the values honest).

Tell users they can now upgrade their clients.

Follow-ups (separate projects):
* Migrate backups to the [Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/) before upgrading CNPG to 1.31 (in-tree barman still works in 1.30.x).
* Consider a garbage-collection CronJob (`mlflow gc --older-than 30d`) to clean up soft-deleted runs and their artifacts (the official chart has one in `templates/cronjob.yaml`).
