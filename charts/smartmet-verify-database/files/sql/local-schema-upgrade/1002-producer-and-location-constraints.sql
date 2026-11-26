-- Constraints the applications already assume (#55, #57). Idempotent; a no-op on
-- data at FMI, where no row violates them.

BEGIN;
-- Fail fast rather than queue every reader behind the ACCESS EXCLUSIVE locks; retry if it times out.
SET LOCAL lock_timeout = '5s';

-- Omitted (NULL) arguments keep the column defaults.
CREATE OR REPLACE FUNCTION public.add_producer_f(_producer_id integer, _producer_name character varying, _languagecode1 character, _producer_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _producer_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _producer_description3 text DEFAULT NULL::text, _producer_arrival_leadtime smallint DEFAULT NULL::smallint, _producer_analysis_hours character varying DEFAULT NULL::character varying, _producer_color_id smallint DEFAULT NULL::smallint) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    producer INT;
BEGIN

    SELECT id INTO producer FROM producers WHERE id = _producer_id;

    IF FOUND THEN
        RAISE NOTICE 'Producer % exists already', _producer_id;
        RETURN FALSE;
    END IF;

    INSERT INTO producers (id, name) VALUES (_producer_id, _producer_name);

    IF _producer_arrival_leadtime IS NOT NULL THEN
        UPDATE producers SET arrival_leadtime = _producer_arrival_leadtime WHERE id = _producer_id;
    END IF;

    IF _producer_analysis_hours IS NOT NULL THEN
        UPDATE producers SET analysis_hours = _producer_analysis_hours WHERE id = _producer_id;
    END IF;

    UPDATE producers SET color_id = _producer_color_id WHERE id = _producer_id;

    PERFORM add_translation_f('producers', _producer_id, _languagecode1, 'description_id', _producer_description1);

    IF _languagecode2 IS NOT NULL AND _producer_description2 IS NOT NULL THEN
        PERFORM add_translation_f('producers', _producer_id, _languagecode2, 'description_id', _producer_description2);
    END IF;

    IF _languagecode3 IS NOT NULL AND _producer_description3 IS NOT NULL THEN
        PERFORM add_translation_f('producers', _producer_id, _languagecode3, 'description_id', _producer_description3);
    END IF;

    RETURN TRUE;
END;
$$;

ALTER FUNCTION public.add_producer_f(_producer_id integer, _producer_name character varying, _languagecode1 character, _producer_description1 text, _languagecode2 character, _producer_description2 text, _languagecode3 character, _producer_description3 text, _producer_arrival_leadtime smallint, _producer_analysis_hours character varying, _producer_color_id smallint) OWNER TO verifadmin;

-- #55: analysis_hours NOT NULL, all hours by default; arrival_leadtime 0 by
-- default (nullable: Producer exposes it as Optional).
UPDATE public.producers SET analysis_hours = '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23'
 WHERE analysis_hours IS NULL;
UPDATE public.producers SET arrival_leadtime = 0 WHERE arrival_leadtime IS NULL;
ALTER TABLE public.producers
    ALTER COLUMN analysis_hours SET DEFAULT '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23',
    ALTER COLUMN analysis_hours SET NOT NULL,
    ALTER COLUMN arrival_leadtime SET DEFAULT 0;

-- #57: Location maps kind_id as mandatory. Fails if a row has none; set those
-- first.
ALTER TABLE public.locations ALTER COLUMN kind_id SET NOT NULL;

COMMIT;
