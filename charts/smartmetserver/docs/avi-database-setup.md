# AVI database setup

What you need to do **after** loading the public schemas from
[`fmidev/avidb-schema`](https://github.com/fmidev/avidb-schema/tree/main/postgresql)
to make the SmartMet AVI engine and EDR plugin actually work against the
database.

The standard schema files (`schema-postgresql.sql`,
`aerodrome-schema-postgresql.sql`, `icao-fir-schema-postgresql.sql`)
create tables, functions and indexes but do not by themselves leave the
database in a state the AVI engine will accept. The steps below cover
the gaps.

## Prerequisites

- PostgreSQL with the `postgis` extension (PostGIS 3.x recommended).
- The schema files have been applied to a database (the rest of this
  document assumes it is named `avi`).

## 1. Roles

The schema files reference roles `avidb_ro`, `avidb_rw` and
`avidb_iwxxm` in `GRANT` and `ALTER … OWNER TO …` statements. If you
skipped `privileges-postgresql.sql`, create the roles before applying
those scripts (or fix up afterwards):

```sql
CREATE ROLE avidb_ro;
CREATE ROLE avidb_rw;
-- avidb_iwxxm is only needed if you keep the IWXXM-related grants
CREATE ROLE avidb_iwxxm;
```

Roles are cluster-wide in PostgreSQL — create them once per cluster,
not per database.

When using CloudNativePG, the roles can be added in
`spec.bootstrap.initdb.postInitSQL` so they exist before the schema
SQL runs.

## 2. A login user for the engine

The roles created above are NOLOGIN groups. The AVI engine needs a
login role with a password. Use `avidb_ro` as the connecting user
(SmartMet only reads from this database):

```sql
ALTER ROLE avidb_ro WITH LOGIN PASSWORD '<pick-a-password>';
```

If you prefer a separate login user, create one and grant it the
group:

```sql
CREATE ROLE smartmet_avi LOGIN PASSWORD '<pick-a-password>';
GRANT avidb_ro TO smartmet_avi;
```

## 3. Read privileges

`privileges-postgresql.sql` grants `SELECT` to `avidb_ro` on a fixed
list of tables. If you skipped that file (or if any new tables were
added), grant SELECT explicitly:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO avidb_ro;

-- Make future tables in this schema readable by avidb_ro automatically:
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO avidb_ro;
```

The AVI engine will fail with `permission denied for table avidb_stations`
(or similar) if this is missing.

## 4. Minimum reference data

The AVI engine validates incoming queries against rows that already
exist in the database. With an empty schema you will hit two distinct
failure modes:

- `Unknown country code XX` — the engine checks the requested country
  against `avidb_stations.country_code`. With no stations, every
  country is "unknown".
- Empty result lists / no collection metadata in `/edr/collections`.

Seed the minimum reference data:

```sql
-- One station per country you intend to query against
INSERT INTO avidb_stations (icao_code, name, geom, elevation, country_code) VALUES
  ('EETN', 'Tallinn-Lennart Meri', ST_SetSRID(ST_MakePoint(24.832778, 59.413333), 4326), 40, 'EE'),
  ('EFHK', 'Helsinki-Vantaa',     ST_SetSRID(ST_MakePoint(24.963333, 60.317222), 4326), 51, 'FI');

-- Message types used by the configured collections
INSERT INTO avidb_message_types (type_id, type, description) VALUES
  (1, 'METAR',  'Aviation routine weather report'),
  (2, 'TAF',    'Terminal Aerodrome Forecast'),
  (3, 'SIGMET', 'Significant Meteorological Information')
ON CONFLICT DO NOTHING;
```

If you want to constrain `/avi` and `/edr` queries by FIR, also load at
least the FIR(s) you care about into `icao_fir_yhdistelma` /
`icao_fir_yhdiste`. Each row's `geom`/`areageom` must be a
`MULTIPOLYGON` in SRID 4326. Example for Tallinn FIR:

```sql
INSERT INTO icao_fir_yhdistelma (firname, region, icaocode, statecode, statename, geom)
VALUES (
  'TALLINN FIR', 'EUR', 'EETT', 'EST', 'ESTONIA',
  ST_Multi(ST_GeomFromText('POLYGON((<lon lat, lon lat, …>))', 4326))
);
```

## 5. Caveats

- The avi engine's `queryStationsWithBBoxes` builds invalid SQL when the
  EDR plugin has the FIR-id column selected (`SELECT … fi.firid FROM
  avidb_stations` — the `fi` alias is not joined). Use `countries` or
  `icaos` filters in the EDR `avi.collections` config, not `bbox`,
  until the engine fix lands.
- The connection user must use the same case as configured (`avidb_ro`,
  not `AVIDB_RO`); both the engine and PostgreSQL fold identifiers
  predictably here.
- `avidb_ro` only needs `SELECT`. Do not give it write privileges
  unless you also intend to ingest messages with the same role.

## 6. Verification

Once the steps above are done, this should succeed from a client
authenticating as the engine's user:

```sql
SELECT count(*) FROM avidb_stations;
SELECT count(*) FROM avidb_message_types;
SELECT extname FROM pg_extension WHERE extname = 'postgis';
```

If those return non-zero / `postgis`, the database is ready for the
AVI engine to connect.
