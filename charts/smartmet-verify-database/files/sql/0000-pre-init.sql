-- Note: the passwords and permissions are obviously only for development and testing purposes!
-- Each CREATE ROLE is wrapped in a DO block so the script is idempotent and safe to re-run
-- on an existing cluster (e.g. when CNPG managed.roles has already created some roles).
-- CREATE ROLE IF NOT EXISTS is not available until PostgreSQL 17.

DO $$ BEGIN CREATE ROLE verif_data_rw    WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verif_meta_rw    WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verif_ro         WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE ROLE verifadmin       WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verifapi_restore WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verifely         WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verifimport      WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verifrun         WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verifmeta        WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verifwww_len     WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE ROLE verifwww         WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

GRANT verif_data_rw TO verifimport;
GRANT verif_data_rw TO verifrun;
GRANT verif_meta_rw TO verifmeta;
GRANT verif_ro TO verif_data_rw;
GRANT verif_ro TO verif_meta_rw;
GRANT verif_ro TO verifely;
GRANT verif_ro TO verifwww;
GRANT verif_ro TO verifwww_len;

-- PostgreSQL system user
DO $$ BEGIN CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'password'; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
