-- WIGOS station id (e.g. 0-231-0-63450), by which wis2box observations are queried.
-- fmisid stays the integer key. Idempotent.

ALTER TABLE public.locations ADD COLUMN IF NOT EXISTS wigos_id text;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'locations_wigos_id_format_check') THEN
    ALTER TABLE public.locations ADD CONSTRAINT locations_wigos_id_format_check
      CHECK (wigos_id IS NULL OR wigos_id ~ '^[0-9]+-[0-9]+-[0-9]+-[0-9A-Za-z]{1,16}$');
  END IF;
END
$$;

CREATE UNIQUE INDEX IF NOT EXISTS locations_wigos_id_uniq_idx ON public.locations (wigos_id);

COMMENT ON COLUMN public.locations.wigos_id IS 'WIGOS station identifier, e.g. 0-231-0-63450. Used to query and match observations from WIS 2.0 sources.';

CREATE OR REPLACE VIEW public.locations_v AS
 SELECT l.fmisid,
    ll.code AS language_code,
    lt.translation AS name,
    l.geom,
    l.external_info,
    l.wigos_id
   FROM public.locations l,
    public.localization_languages ll,
    public.localization_entries le,
    public.localization_translations lt
  WHERE ((l.name_id = le.id) AND (lt.language_id = ll.id) AND (lt.entry_id = le.id));

-- Separate from add_location_f so its positional calls stay unambiguous.
CREATE OR REPLACE FUNCTION public.set_location_wigos_id_f(_target_id integer, _wigos_id text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.locations SET wigos_id = _wigos_id WHERE fmisid = _target_id;
  IF NOT FOUND THEN
    RAISE NOTICE 'Location % does not exist', _target_id;
    RETURN FALSE;
  END IF;
  RETURN TRUE;
END;
$$;

ALTER FUNCTION public.set_location_wigos_id_f(_target_id integer, _wigos_id text) OWNER TO verifadmin;
