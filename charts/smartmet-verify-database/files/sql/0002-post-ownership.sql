-- Runs on verifapi as postgres (superuser) after the production schema.
-- Transfers database and public-schema ownership to verifadmin and grants
-- verif_ro USAGE on public so read-only roles can access objects.
ALTER DATABASE verifapi OWNER TO verifadmin;
ALTER SCHEMA public OWNER TO verifadmin;
GRANT USAGE ON SCHEMA public TO verif_ro;
GRANT CREATE ON SCHEMA public TO verifadmin;
