-- Brings a database built from an older 0001 to the mast_metadata and
-- warning_rules shape that 0001 (and fmi-verification-common 3.13.0) now has:
-- adds mast_metadata, folds warning_rule_conditions into warning_rules.
-- Idempotent; a no-op on a database that already has the new shape.

BEGIN;
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS public.mast_metadata (
    location_id integer NOT NULL,
    parameter_id integer NOT NULL,
    parameter_name text NOT NULL,
    sensor_no integer NOT NULL,
    sensor_height numeric NOT NULL,
    obstruction_direction_from numeric,
    obstruction_direction_to numeric,
    CONSTRAINT mast_metadata_obstruction_direction_from_check CHECK (((obstruction_direction_from IS NULL) OR ((obstruction_direction_from >= 0) AND (obstruction_direction_from < 360)))),
    CONSTRAINT mast_metadata_obstruction_direction_to_check CHECK (((obstruction_direction_to IS NULL) OR ((obstruction_direction_to >= 0) AND (obstruction_direction_to < 360)))),
    CONSTRAINT mast_metadata_pkey PRIMARY KEY (location_id, parameter_id, sensor_no),
    CONSTRAINT mast_metadata_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(fmisid),
    CONSTRAINT mast_metadata_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id)
);
ALTER TABLE public.mast_metadata OWNER TO verifadmin;
GRANT SELECT ON TABLE public.mast_metadata TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.mast_metadata TO verif_meta_rw;
GRANT SELECT ON TABLE public.mast_metadata TO replicator;

-- One parameter and limit pair per rule. Existing rules cannot be converted
-- automatically (a rule could have several conditions), so this stops if any exist.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.warning_rules'::regclass AND attname = 'parameter_id' AND NOT attisdropped) THEN
    IF EXISTS (SELECT 1 FROM public.warning_rules) THEN
      RAISE EXCEPTION 'warning_rules has rows: convert them from warning_rule_conditions by hand first';
    END IF;
    ALTER TABLE public.warning_rules
        ADD COLUMN parameter_id integer NOT NULL,
        ADD COLUMN low_limit double precision,
        ADD COLUMN upper_limit double precision,
        ADD COLUMN low_limit2 double precision,
        ADD COLUMN upper_limit2 double precision,
        ADD CONSTRAINT warning_rules_limit_order_chk CHECK (((low_limit IS NULL) OR (upper_limit IS NULL) OR (low_limit <= upper_limit))),
        ADD CONSTRAINT warning_rules_limit2_order_chk CHECK (((low_limit2 IS NULL) OR (upper_limit2 IS NULL) OR (low_limit2 <= upper_limit2))),
        ADD CONSTRAINT warning_rules_parameter_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id),
        DROP CONSTRAINT IF EXISTS warning_rules_unique_rule;
    CREATE UNIQUE INDEX warning_rules_unique_rule ON public.warning_rules USING btree
        (target_id, parameter_id, severity_id, low_limit, upper_limit, valid_from_month, valid_from_day, valid_to_month, valid_to_day) NULLS NOT DISTINCT;
  END IF;

  IF to_regclass('public.warning_rule_conditions') IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM public.warning_rule_conditions) THEN
      RAISE EXCEPTION 'warning_rule_conditions has rows: move them into warning_rules by hand first';
    END IF;
    DROP TABLE public.warning_rule_conditions;
  END IF;
END
$$;

COMMIT;
