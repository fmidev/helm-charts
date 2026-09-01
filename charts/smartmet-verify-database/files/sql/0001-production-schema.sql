

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;












CREATE EXTENSION IF NOT EXISTS pgstattuple WITH SCHEMA public;



COMMENT ON EXTENSION pgstattuple IS 'show tuple-level statistics';



CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;



COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';



CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;



COMMENT ON EXTENSION postgis_raster IS 'PostGIS raster types and functions';



CREATE FUNCTION public.add_area_f(_target_id integer, _name character varying, _languagecode1 character, _target_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _target_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _target_description3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  target INT;
BEGIN

  SELECT id INTO target FROM targets WHERE id = _target_id;

  IF FOUND THEN
    RAISE NOTICE 'Area % exists already', _target_id;
    RETURN FALSE;
  END IF;

  EXECUTE 'INSERT INTO targets (id, type_id) VALUES (' || quote_nullable(_target_id) || ',' || 3 || ')';
  EXECUTE 'INSERT INTO areas (id, name) VALUES (' || quote_nullable(_target_id) || ',' || quote_nullable(_name)
|| ')';

  PERFORM add_translation_f('areas',_target_id, _languagecode1, 'description_id', _target_description1);

  IF _languagecode2 IS NOT NULL AND _target_description2 IS NOT NULL THEN
    PERFORM add_translation_f('areas',_target_id, _languagecode2,'description_id', _target_description2);
  END IF;

  IF _languagecode3 IS NOT NULL AND _target_description3 IS NOT NULL THEN
    PERFORM add_translation_f('areas',_target_id, _languagecode3, 'description_id', _target_description3);
  END IF;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_area_f(_target_id integer, _name character varying, _languagecode1 character, _target_description1 text, _languagecode2 character, _target_description2 text, _languagecode3 character, _target_description3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_estimator_f(_estimator_id integer, _estimator_name character varying, _minimum_value numeric, _maximum_value numeric, _scale smallint, _character character varying, _languagecode1 character, _estimator_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _estimator_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _estimator_description3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    estimator INT;
BEGIN

    SELECT id INTO estimator FROM estimators WHERE id = _estimator_id;

    IF FOUND THEN
        RAISE NOTICE 'Estimator % exists already', _estimator_id;
        RETURN FALSE;
    END IF;

    EXECUTE 'INSERT INTO estimators (id, name, minimum_value, maximum_value, scale,character) VALUES ('
                || quote_nullable(_estimator_id) || ','
                || quote_nullable(_estimator_name) || ','
                || quote_nullable(_minimum_value) || ','
                || quote_nullable(_maximum_value) || ','
                || quote_nullable(_scale) || ','
                || quote_nullable(_character) || ');';

    PERFORM add_translation_f('estimators', _estimator_id, _languagecode1, 'description_id', _estimator_description1);

    IF _languagecode2 IS NOT NULL AND _estimator_description2 IS NOT NULL THEN
        PERFORM add_translation_f('estimators', _estimator_id, _languagecode2, 'description_id', _estimator_description2);
    END IF;

    IF _languagecode3 IS NOT NULL AND _estimator_description3 IS NOT NULL THEN
        PERFORM add_translation_f('estimators', _estimator_id, _languagecode3, 'description_id', _estimator_description3);
    END IF;

    RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_estimator_f(_estimator_id integer, _estimator_name character varying, _minimum_value numeric, _maximum_value numeric, _scale smallint, _character character varying, _languagecode1 character, _estimator_description1 text, _languagecode2 character, _estimator_description2 text, _languagecode3 character, _estimator_description3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_location_f(_target_id integer, _location_kind_id smallint, _longitude numeric, _latitude numeric, _elevation numeric, _languagecode1 character, _target_name1 text, _languagecode2 character DEFAULT NULL::bpchar, _target_name2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _target_name3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  target INT;
BEGIN

  SELECT id INTO target FROM targets WHERE id = _target_id;

  IF FOUND THEN
    RAISE NOTICE 'Target % exists already', _target_id;
    RETURN FALSE;
  END IF;


  EXECUTE 'INSERT INTO targets (id, type_id) VALUES (' || quote_nullable(_target_id) || ',' || 1 || ')';
  EXECUTE 'INSERT INTO locations (fmisid, kind_id, geom, elevation) VALUES ('
|| quote_nullable(_target_id)
|| ','
|| quote_nullable(_location_kind_id)
|| ', ST_SetSrid(ST_MakePoint('
|| quote_nullable(_longitude)
|| ', '
|| quote_nullable(_latitude)
|| '), 4326), '
|| quote_nullable(_elevation)
|| ')';

  PERFORM add_translation_f('locations',_target_id, _languagecode1,'name_id', _target_name1);

  IF _languagecode2 IS NOT NULL AND _target_name2 IS NOT NULL THEN
    PERFORM add_translation_f('locations',_target_id, _languagecode2,'name_id', _target_name2);
  END IF;

  IF _languagecode3 IS NOT NULL AND _target_name3 IS NOT NULL THEN
    PERFORM add_translation_f('locations',_target_id, _languagecode3, 'name_id', _target_name3);
  END IF;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_location_f(_target_id integer, _location_kind_id smallint, _longitude numeric, _latitude numeric, _elevation numeric, _languagecode1 character, _target_name1 text, _languagecode2 character, _target_name2 text, _languagecode3 character, _target_name3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_location_kind_f(_location_kind_id integer, _location_kind_name character varying, _languagecode1 character, _location_kind_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _location_kind_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _location_kind_description3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  location_kind INT;
BEGIN

  SELECT id INTO location_kind FROM location_kinds WHERE id = _location_kind_id;

  IF FOUND THEN
    RAISE NOTICE 'location_kind % exists already', _location_kind_id;
    RETURN FALSE;
  END IF;

  EXECUTE 'INSERT INTO location_kinds (id, name) VALUES ('
|| quote_nullable(_location_kind_id) || ','
|| quote_nullable(_location_kind_name) || ');';

  PERFORM add_translation_f('location_kinds', _location_kind_id, _languagecode1, 'description_id', _location_kind_description1);

  IF _languagecode2 IS NOT NULL AND _location_kind_description2 IS NOT NULL THEN
    PERFORM add_translation_f('location_kinds', _location_kind_id, _languagecode2, 'description_id', _location_kind_description2);
  END IF;

  IF _languagecode3 IS NOT NULL AND _location_kind_description3 IS NOT NULL THEN
    PERFORM add_translation_f('location_kinds', _location_kind_id, _languagecode3, 'description_id', _location_kind_description3);
  END IF;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_location_kind_f(_location_kind_id integer, _location_kind_name character varying, _languagecode1 character, _location_kind_description1 text, _languagecode2 character, _location_kind_description2 text, _languagecode3 character, _location_kind_description3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_parameter_f(_parameter_id integer, _parameter_name character varying, _minimum_value numeric, _maximum_value numeric, _unit character varying, _languagecode1 character, _parameter_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _parameter_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _parameter_description3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
parameter INT;
BEGIN

SELECT id
INTO parameter
FROM parameters
WHERE id = _parameter_id;

IF
FOUND THEN
    RAISE NOTICE 'Parameter % exists already', _parameter_id;
RETURN FALSE;
END IF;

EXECUTE 'INSERT INTO parameters (id, name, minimum_value, maximum_value, unit) VALUES ('
    || quote_nullable(_parameter_id) || ','
    || quote_nullable(_parameter_name) || ','
    || quote_nullable(_minimum_value) || ','
    || quote_nullable(_maximum_value) || ','
    || quote_nullable(_unit) || ');';

PERFORM
add_translation_f('parameters', _parameter_id, _languagecode1, 'description_id', _parameter_description1);

  IF
_languagecode2 IS NOT NULL AND _parameter_description2 IS NOT NULL THEN
    PERFORM add_translation_f('parameters', _parameter_id, _languagecode2, 'description_id', _parameter_description2);
END IF;

  IF
_languagecode3 IS NOT NULL AND _parameter_description3 IS NOT NULL THEN
    PERFORM add_translation_f('parameters', _parameter_id, _languagecode3, 'description_id', _parameter_description3);
END IF;

RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_parameter_f(_parameter_id integer, _parameter_name character varying, _minimum_value numeric, _maximum_value numeric, _unit character varying, _languagecode1 character, _parameter_description1 text, _languagecode2 character, _parameter_description2 text, _languagecode3 character, _parameter_description3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_period_type_f(_period_type_id integer, _period_type_name character varying, _languagecode1 character, _period_type_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _period_type_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _period_type_description3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  period_type INT;
BEGIN

  SELECT id INTO period_type FROM period_types WHERE id = _period_type_id;

  IF FOUND THEN
    RAISE NOTICE 'period_type % exists already', _period_type_id;
    RETURN FALSE;
  END IF;

  EXECUTE 'INSERT INTO period_types (id, name) VALUES ('
|| quote_nullable(_period_type_id) || ','
|| quote_nullable(_period_type_name) || ');';

  PERFORM add_translation_f('period_types', _period_type_id, _languagecode1, 'description_id', _period_type_description1);

  IF _languagecode2 IS NOT NULL AND _period_type_description2 IS NOT NULL THEN
    PERFORM add_translation_f('period_types', _period_type_id, _languagecode2, 'description_id', _period_type_description2);
  END IF;

  IF _languagecode3 IS NOT NULL AND _period_type_description3 IS NOT NULL THEN
    PERFORM add_translation_f('period_types', _period_type_id, _languagecode3, 'description_id', _period_type_description3);
  END IF;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_period_type_f(_period_type_id integer, _period_type_name character varying, _languagecode1 character, _period_type_description1 text, _languagecode2 character, _period_type_description2 text, _languagecode3 character, _period_type_description3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_producer_f(_producer_id integer, _producer_name character varying, _languagecode1 character, _producer_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _producer_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _producer_description3 text DEFAULT NULL::text, _producer_arrival_leadtime smallint DEFAULT NULL::smallint, _producer_analysis_hours character varying DEFAULT NULL::character varying, _producer_color_id smallint DEFAULT NULL::smallint) RETURNS boolean
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

    EXECUTE 'INSERT INTO producers (id, name) VALUES (' || quote_nullable(_producer_id) || ',' ||
            quote_nullable(_producer_name) || ')';

    EXECUTE 'UPDATE producers SET arrival_leadtime=' || quote_nullable(_producer_arrival_leadtime) || ' WHERE id=' ||
            quote_nullable(_producer_id);

    EXECUTE 'UPDATE producers SET analysis_hours=' || quote_nullable(_producer_analysis_hours) || ' WHERE id=' ||
            quote_nullable(_producer_id);

    EXECUTE 'UPDATE producers SET color_id=' || quote_nullable(_producer_color_id) || ' WHERE id=' ||
            quote_nullable(_producer_id);

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


CREATE FUNCTION public.add_targetgroup_f(_target_id integer, _target_name character varying, _languagecode1 character, _target_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _target_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _target_description3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  target INT;
BEGIN

  SELECT id INTO target FROM targets WHERE id = _target_id;

  IF FOUND THEN
    RAISE NOTICE 'Target % exists already', _target_id;
    RETURN FALSE;
  END IF;

  EXECUTE 'INSERT INTO targets (id, type_id) VALUES (' || quote_nullable(_target_id) || ',' || 2 || ')';
  EXECUTE 'INSERT INTO targetgroups (id, name) VALUES (' || quote_nullable(_target_id) || ',' || quote_nullable(_target_name) || ')';

  PERFORM add_translation_f('targetgroups', _target_id, _languagecode1, 'description_id', _target_description1);

  IF _languagecode2 IS NOT NULL AND _target_description2 IS NOT NULL THEN
    PERFORM add_translation_f('targetgroups', _target_id, _languagecode2, 'description_id', _target_description2);
  END IF;

  IF _languagecode3 IS NOT NULL AND _target_description3 IS NOT NULL THEN
    PERFORM add_translation_f('targetgroups', _target_id, _languagecode3, 'description_id', _target_description3);
  END IF;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_targetgroup_f(_target_id integer, _target_name character varying, _languagecode1 character, _target_description1 text, _languagecode2 character, _target_description2 text, _languagecode3 character, _target_description3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_translation_f(_tablename text, _entity_id integer, _languagecode character, _columnname1 text, _translation1 text, _columnname2 text DEFAULT NULL::text, _translation2 text DEFAULT NULL::text, _columnname3 text DEFAULT NULL::text, _translation3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  _localization_language_id INT;
  _localization_entry_id INT;
  _localization_translation_translation TEXT;
  _pkey_column TEXT;
BEGIN
  -- Check if language is valid

  SELECT ll.id INTO _localization_language_id FROM localization_languages ll WHERE ll.code = _languagecode;

  IF NOT FOUND THEN
    RAISE NOTICE 'Language % not found from localization_language', _languagecode;
    RETURN FALSE;
  END IF;

  --
  -- First column
  --

  SELECT le.id INTO _localization_entry_id FROM localization_entries le WHERE le.tablename = _tablename AND le.columnname = _columnname1 AND le.entity_id = _entity_id;

  IF NOT FOUND THEN
    INSERT INTO localization_entries (id, tablename, columnname, entity_id) VALUES (DEFAULT, _tablename, _columnname1, _entity_id) RETURNING id INTO _localization_entry_id;
  END IF;

  SELECT lt.translation INTO _localization_translation_translation FROM localization_translations lt WHERE lt.entry_id = _localization_entry_id AND lt.language_id = _localization_language_id;

  IF NOT FOUND THEN
    INSERT INTO localization_translations (entry_id, language_id, translation) VALUES (_localization_entry_id, _localization_language_id, _translation1);
    RAISE NOTICE 'Inserted new translation for %.%, language %, id %: %', _tablename, _columnname1, _languagecode, _entity_id,_translation1;
  ELSE
    UPDATE localization_translations SET translation = _translation1 WHERE entry_id = _localization_entry_id AND language_id = _localization_language_id;
    RAISE NOTICE 'Updated translation for %.%, language %, id %: %', _tablename, _columnname1, _languagecode, _entity_id, _translation1;
  END IF;

  -- UPDATE the actual table to contain localication id
  SELECT a.attname INTO STRICT _pkey_column FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) WHERE i.indrelid = quote_ident(_tablename)::regclass AND i.indisprimary;
  EXECUTE 'UPDATE ' || _tablename || ' SET ' || _columnname1 || ' = ' || _localization_entry_id || ' WHERE ' || _pkey_column || ' = ' || _entity_id;

  --
  -- Second column
  --

  IF _columnname2 IS NOT NULL AND _translation2 IS NOT NULL THEN
    SELECT le.id INTO _localization_entry_id FROM localization_entries le WHERE le.tablename = _tablename AND le.columnname = _columnname2 AND le.entity_id = _entity_id;

    IF NOT FOUND THEN
      INSERT INTO localization_entries (id, tablename, columnname, entity_id) VALUES (DEFAULT, _tablename, _columnname2, _entity_id) RETURNING id INTO _localization_entry_id;
    END IF;

    SELECT lt.translation INTO _localization_translation_translation FROM localization_translations lt WHERE lt.entry_id = _localization_entry_id AND lt.language_id = _localization_language_id;

    IF NOT FOUND THEN
      INSERT INTO localization_translations (entry_id, language_id, translation) VALUES (_localization_entry_id, _localization_language_id, _translation2);
      RAISE NOTICE 'Inserted new translation for %.%, language %, id %: %', _tablename, _columnname2, _languagecode, _entity_id,_translation2;
    ELSE
      UPDATE localization_translations SET translation = _translation2 WHERE entry_id = _localization_entry_id AND language_id = _localization_language_id;
      RAISE NOTICE 'Updated translation for %.%, language %, id %: %', _tablename, _columnname2, _languagecode, _entity_id, _translation2;
    END IF;

    EXECUTE 'UPDATE ' || _tablename || ' SET ' || _columnname2 || ' = ' || _localization_entry_id || ' WHERE ' || _pkey_column || ' = ' || _entity_id;

  END IF;

  --
  -- Third column
  --

  IF _columnname3 IS NOT NULL AND _translation3 IS NOT NULL THEN
    SELECT le.id INTO _localization_entry_id FROM localization_entries le WHERE le.tablename = _tablename AND le.columnname = _columnname3 AND le.entity_id = _entity_id;

    IF NOT FOUND THEN
      INSERT INTO localization_entries (id, tablename, columnname, entity_id) VALUES (DEFAULT, _tablename, _columnname3, _entity_id) RETURNING id INTO _localization_entry_id;
    END IF;

    SELECT lt.translation INTO _localization_translation_translation FROM localization_translations lt WHERE lt.entry_id = _localization_entry_id AND lt.language_id = _localization_language_id;
    IF NOT FOUND THEN
      INSERT INTO localization_translations (entry_id, language_id, translation) VALUES (_localization_entry_id, _localization_language_id, _translation3);
      RAISE NOTICE 'Inserted new translation for %.%, language %, id %: %', _tablename, _columnname3, _languagecode, _entity_id,_translation3;
    ELSE
      UPDATE localization_translations SET translation = _translation3 WHERE entry_id = _localization_entry_id AND language_id = _localization_language_id;
      RAISE NOTICE 'Updated translation for %.%, language %, id %: %', _tablename, _columnname3, _languagecode, _entity_id, _translation3;
    END IF;

    EXECUTE 'UPDATE ' || _tablename || ' SET ' || _columnname3 || ' = ' || _localization_entry_id || ' WHERE ' || _pkey_column || ' = ' || _entity_id;

  END IF;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_translation_f(_tablename text, _entity_id integer, _languagecode character, _columnname1 text, _translation1 text, _columnname2 text, _translation2 text, _columnname3 text, _translation3 text) OWNER TO verifadmin;


CREATE FUNCTION public.add_warning_level_f(_warning_level_severity_id integer, _warning_level_severity_name character varying, _warning_level_severity_color character varying, _languagecode1 character, _warning_level_description1 text, _languagecode2 character DEFAULT NULL::bpchar, _warning_level_description2 text DEFAULT NULL::text, _languagecode3 character DEFAULT NULL::bpchar, _warning_level_description3 text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
warning_level INT;
BEGIN

SELECT severity_id
INTO warning_level
FROM warning_levels
WHERE severity_id = _warning_level_severity_id;

IF
FOUND THEN
        RAISE NOTICE 'warning_level % exists already', _warning_level_severity_id;
RETURN FALSE;
END IF;

EXECUTE 'INSERT INTO warning_levels (severity_id, severity_name, severity_color) VALUES ('
    || quote_nullable(_warning_level_severity_id) || ','
    || quote_nullable(_warning_level_severity_name) || ','
    || quote_nullable(_warning_level_severity_color) ||');';

PERFORM
add_translation_f('warning_levels', _warning_level_severity_id, _languagecode1, 'description_id', _warning_level_description1);

    IF
_languagecode2 IS NOT NULL AND _warning_level_description2 IS NOT NULL THEN
        PERFORM add_translation_f('warning_levels', _warning_level_severity_id, _languagecode2, 'description_id', _warning_level_description2);
END IF;

    IF
_languagecode3 IS NOT NULL AND _warning_level_description3 IS NOT NULL THEN
        PERFORM add_translation_f('warning_levels', _warning_level_severity_id, _languagecode3, 'description_id', _warning_level_description3);
END IF;

RETURN TRUE;
END;
$$;


ALTER FUNCTION public.add_warning_level_f(_warning_level_severity_id integer, _warning_level_severity_name character varying, _warning_level_severity_color character varying, _languagecode1 character, _warning_level_description1 text, _languagecode2 character, _warning_level_description2 text, _languagecode3 character, _warning_level_description3 text) OWNER TO verifadmin;


CREATE FUNCTION public.delete_forecasts_if_no_more_forecasts_f(producerid integer, startdate date, enddate date) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
BEGIN

    FOR rec IN
        SELECT producer_id, analysis_time
        FROM forecasts
        WHERE producer_id = producerId
          AND analysis_time >= startDate
          AND analysis_time < endDate
        ORDER BY analysis_time
        LOOP
            EXECUTE format(
                    'DELETE FROM forecasts where producer_id=%s and analysis_time=%s AND (SELECT count(*) from model_data WHERE producer_id=%s AND analysis_time=%s)=0',
                    rec.producer_id, quote_nullable(rec.analysis_time), rec.producer_id, quote_nullable(rec.analysis_time));
        END LOOP;

END;
$$;


ALTER FUNCTION public.delete_forecasts_if_no_more_forecasts_f(producerid integer, startdate date, enddate date) OWNER TO verifadmin;


CREATE FUNCTION public.delete_old_view_group_rows() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
DELETE
FROM view_group_sessions
WHERE created_at < NOW() - INTERVAL '7 days';
RETURN NULL;
END;
$$;


ALTER FUNCTION public.delete_old_view_group_rows() OWNER TO verifadmin;


CREATE FUNCTION public.drop_target_f(_target_id integer) RETURNS boolean
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $$
DECLARE
  type INT;
BEGIN

  SELECT type_id INTO type FROM targets WHERE id = _target_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Target % does not exist', _target_id;
  END IF;

  IF type = 1 THEN
    DELETE FROM targetgroup_map WHERE target_id = _target_id;
    DELETE FROM locations WHERE fmisid = _target_id;
  ELSIF type = 2 THEN
    DELETE FROM targetgroups WHERE id = _target_id;
  ELSIF type = 3 THEN
    DELETE FROM areas WHERE id = _target_id;
  END IF;

  DELETE FROM localization_entries WHERE tablename IN ('locations', 'targetgroups', 'areas') AND entity_id = _target_id;
  DELETE FROM targets WHERE id = _target_id;
  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.drop_target_f(_target_id integer) OWNER TO verifadmin;


CREATE FUNCTION public.fn_triggerall(doenable boolean) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
mytables RECORD;
BEGIN
  FOR mytables IN SELECT c.relname FROM pg_class c, pg_namespace n WHERE c.relhastriggers AND NOT c.relname LIKE 'pg_%' AND c.oid = n.oid AND n.nspname = 'public'
  LOOP
    IF DoEnable THEN
      EXECUTE 'ALTER TABLE ' || mytables.relname || ' ENABLE TRIGGER ALL';
    ELSE
      EXECUTE 'ALTER TABLE ' || mytables.relname || ' DISABLE TRIGGER ALL';
    END IF;
  END LOOP;

  RETURN 1;

END;
$$;


ALTER FUNCTION public.fn_triggerall(doenable boolean) OWNER TO postgres;


CREATE FUNCTION public.load_rr24h06_from_rr1h_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    parameterId1h  INTEGER := 5; -- 1 h precipitation
    parameterId24h INTEGER := 16; -- 24 h precipitation
    lowLeadtime    INTEGER;
    uppLeadtime    INTEGER;
    ahour          CHAR(2);
    aminute        CHAR(2);
    counter        INTEGER;
    rec            RECORD;
BEGIN

    -- select load_rr24h06_from_rr1h_f(10,100968,2,'2019-08-10','2019-08-12');

    CREATE TEMP TABLE temp_rr24h_analysis_times
    (
        analysis_time TIMESTAMPTZ NOT NULL
    );

    CREATE TEMP TABLE temp_rr24h06_results
    (
        analysis_time TIMESTAMPTZ NOT NULL,
        leadtime      INT         NOT NULL,
        forecaster_id INT,
        value_sum     NUMERIC,
        hour_count    INT         NOT NULL
    );

    EXECUTE FORMAT('INSERT INTO temp_rr24h_analysis_times (analysis_time) '
                       'SELECT analysis_time '
                       'FROM model_data md '
                       'WHERE md.producer_id=%s AND md.target_id=%s AND parameter_id=%s AND md.analysis_time>=%s AND md.analysis_time<%s '
                       'GROUP BY md.analysis_time ORDER BY md.analysis_time;', producerId, targetId, parameterId1h,
                   quote_nullable(startDate), quote_nullable(endDate));

    -- loop variable of loop over rows must be a record or row variable or list of scalar variables
    FOR rec IN -- Lasketaan 24h sadekertymä tunnin sadekertymistä jokaiselle analyysiajalle
        SELECT analysis_time FROM temp_rr24h_analysis_times
        LOOP

            ahour := TO_CHAR(rec.analysis_time at time zone 'UTC', 'HH24');
            aminute := TO_CHAR(rec.analysis_time at time zone 'UTC', 'MI');

            CASE ahour
                WHEN '00' THEN lowLeadtime := 7;
                WHEN '01' THEN lowLeadtime := 6;
                WHEN '02' THEN lowLeadtime := 5;
                WHEN '03' THEN lowLeadtime := 4;
                WHEN '04' THEN lowLeadtime := 3;
                WHEN '05' THEN lowLeadtime := 2;
                WHEN '06' THEN lowLeadtime := 1;
                WHEN '07' THEN lowLeadtime := 24;
                WHEN '08' THEN lowLeadtime := 23;
                WHEN '09' THEN lowLeadtime := 22;
                WHEN '10' THEN lowLeadtime := 21;
                WHEN '11' THEN lowLeadtime := 20;
                WHEN '12' THEN lowLeadtime := 19;
                WHEN '13' THEN lowLeadtime := 18;
                WHEN '14' THEN lowLeadtime := 17;
                WHEN '15' THEN lowLeadtime := 16;
                WHEN '16' THEN lowLeadtime := 15;
                WHEN '17' THEN lowLeadtime := 14;
                WHEN '18' THEN lowLeadtime := 13;
                WHEN '19' THEN lowLeadtime := 12;
                WHEN '20' THEN lowLeadtime := 11;
                WHEN '21' THEN lowLeadtime := 10;
                WHEN '22' THEN lowLeadtime := 9;
                WHEN '23' THEN lowLeadtime := 8;
                ELSE continue;
                END CASE;


            uppLeadtime = lowLeadtime + 23;

            IF (aminute::INT > 30) THEN
                lowLeadtime = lowLeadtime - 1;
                uppLeadtime = uppLeadtime - 1;
            END IF;

            counter := 0;
            WHILE counter < dayCount
                LOOP

                    -- Lasketaan kertymät väliaikaistauluun
                    EXECUTE FORMAT('INSERT INTO temp_rr24h06_results (analysis_time,leadtime,forecaster_id,value_sum,hour_count)
                      SELECT %s, %s, min(forecaster_id), sum(value), count(value)
              FROM model_data md2
              WHERE md2.producer_id=%s AND md2.target_id=%s AND md2.parameter_id=%s AND md2.analysis_time=%s
                AND md2.leadtime>=%s AND md2.leadtime<=%s;',
                                   quote_nullable(rec.analysis_time), uppLeadtime + counter * 24, producerId, targetId, parameterId1h,
                                   quote_nullable(rec.analysis_time), lowLeadtime + counter * 24, uppLeadtime + counter * 24);

                    -- RAISE NOTICE '% % % %', rec.analysis_time, lowLeadtime + counter*24, uppLeadtime + counter*24;

                    counter = counter + 1;
                END LOOP;
        END LOOP;

    DROP TABLE temp_rr24h_analysis_times;

   ------------- Siirretään 24h sadekertymät mallin ennustetauluun----------------------------------
    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_sum, hour_count FROM temp_rr24h06_results WHERE hour_count = 24 AND forecaster_id IS NOT NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value, forecaster_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterId24h, rec.leadtime, rec.value_sum,
                           rec.forecaster_id);
        END LOOP;

    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_sum, hour_count FROM temp_rr24h06_results WHERE hour_count = 24 AND forecaster_id IS NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value)
            VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterId24h, rec.leadtime, rec.value_sum);
        END LOOP;

    DROP TABLE temp_rr24h06_results;
    -------------------------------------------------------------------------------------------------

END;
$$;


ALTER FUNCTION public.load_rr24h06_from_rr1h_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_rr24h06_from_rr1h_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  rec RECORD;
BEGIN

  FOR rec IN -- Lasketaan 24h sadekertymä tunnin sadekertymistä asemaryhmän asemille
  SELECT target_id FROM targetgroup_map tm WHERE tm.group_id=targetGroupId ORDER BY tm.target_id
  LOOP
    EXECUTE load_rr24h06_from_rr1h_f(producerId,rec.target_id,dayCount,startDate,endDate);
  END LOOP;

END;
$$;


ALTER FUNCTION public.load_rr24h06_from_rr1h_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmax18_from_t_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    parameterIdT      INTEGER := 1;
    parameterIdtmax18 INTEGER := 9;
    lowLeadtime       INTEGER;
    uppLeadtime       INTEGER;
    ahour             CHAR(2);
    counter           INTEGER;
    rec               RECORD;
BEGIN

    CREATE TEMP TABLE temp_tmax18_analysis_times
    (
        analysis_time TIMESTAMPTZ NOT NULL
    );

    CREATE TEMP TABLE temp_tmax18_results
    (
        analysis_time TIMESTAMPTZ NOT NULL,
        leadtime      INT,
        forecaster_id INT,
        value_max     NUMERIC,
        hour_count    INT         NOT NULL
    );

    EXECUTE FORMAT('INSERT INTO temp_tmax18_analysis_times (analysis_time)
                 SELECT analysis_time
                 FROM model_data md
                 WHERE md.producer_id=%s AND md.target_id=%s AND parameter_id=%s AND md.analysis_time>=%s AND md.analysis_time<%s
                 GROUP BY md.analysis_time ORDER BY md.analysis_time;',
                   producerId, targetId, parameterIdT, quote_nullable(startDate), quote_nullable(endDate));

    -- loop variable of loop over rows must be a record or row variable or list of scalar variables
    FOR rec IN -- Etsitään tmax18 hetkellisistä lämpötiloista jokaiselle analyysiajalle
        SELECT analysis_time FROM temp_tmax18_analysis_times
        LOOP
            ahour := TO_CHAR(rec.analysis_time at time zone 'UTC', 'HH24');
            IF (ahour IN ('06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17')) THEN
                lowLeadtime := -11;
                uppLeadtime := 12;
            ELSE
                lowLeadtime := 1;
                uppLeadtime := 24;
            END IF;

            counter := 0;
            WHILE counter < dayCount
                LOOP

                    -- Lasketaan yön alimmat lämpötilat väliaikaistauluun
                    EXECUTE FORMAT('INSERT INTO temp_tmax18_results (analysis_time,leadtime,forecaster_id,value_max,hour_count)
                      SELECT %s, max(leadtime), min(forecaster_id), max(value), count(value)
              FROM model_data md2
              WHERE md2.producer_id=%s AND md2.target_id=%s AND md2.parameter_id=%s AND md2.analysis_time=%s
                AND md2.leadtime>=%s AND md2.leadtime<=%s
                        AND TO_CHAR(md2.analysis_time at time zone %s + md2.leadtime*interval%s,%s) in(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);',
                                   quote_nullable(rec.analysis_time), producerId, targetId,
                                   parameterIdT,
                                   quote_nullable(rec.analysis_time), lowLeadtime + counter * 24,
                                   uppLeadtime + counter * 24,
                                   quote_nullable('UTC'), quote_nullable('1 hour'), quote_nullable('HH24'),
                                   quote_nullable('06'), quote_nullable('07'), quote_nullable('08'),
                                   quote_nullable('09'), quote_nullable('10'), quote_nullable('11'),
                                   quote_nullable('12'), quote_nullable('13'), quote_nullable('14'),
                                   quote_nullable('15'), quote_nullable('16'), quote_nullable('17'),
                                   quote_nullable('18'));

                    -- RAISE NOTICE '% % %', rec.analysis_time, lowLeadtime + counter*24, uppLeadtime + counter*24;

                    counter = counter + 1;
                END LOOP;
        END LOOP;

    DROP TABLE temp_tmax18_analysis_times;

    ------------- Siirretään päivänn ylimmat lämpötilat mallin ennustetauluun------------------------
    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_max
        FROM temp_tmax18_results
        WHERE hour_count >= 3
          AND forecaster_id IS NOT NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value, forecaster_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdtmax18, rec.leadtime, rec.value_max, rec.forecaster_id);
        END LOOP;

    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_max
        FROM temp_tmax18_results
        WHERE hour_count >= 3
          AND forecaster_id IS NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value)
            VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdtmax18, rec.leadtime, rec.value_max);
        END LOOP;

    DROP TABLE temp_tmax18_results;
    -------------------------------------------------------------------------------------------------

END;
$$;


ALTER FUNCTION public.load_tmax18_from_t_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmax18_from_t_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
BEGIN

    FOR rec IN -- Etsitään päivän maksimit asemaryhmän asemille asemille
        SELECT target_id FROM targetgroup_map tm WHERE tm.group_id = targetGroupId ORDER BY tm.target_id
        LOOP
            EXECUTE load_tmax18_from_t_f(producerId, rec.target_id, dayCount, startDate, endDate);
        END LOOP;

END;
$$;


ALTER FUNCTION public.load_tmax18_from_t_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmax18_from_tf50_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    parameterIdT      INTEGER := 211;
    parameterIdtmax18 INTEGER := 215;
    lowLeadtime       INTEGER;
    uppLeadtime       INTEGER;
    ahour             CHAR(2);
    counter           INTEGER;
    rec               RECORD;
BEGIN

    CREATE TEMP TABLE temp_tmax18_analysis_times
    (
        analysis_time TIMESTAMPTZ NOT NULL
    );

    CREATE TEMP TABLE temp_tmax18_results
    (
        analysis_time TIMESTAMPTZ NOT NULL,
        leadtime      INT,
        forecaster_id INT,
        value_max     NUMERIC,
        hour_count    INT         NOT NULL
    );

    EXECUTE FORMAT('INSERT INTO temp_tmax18_analysis_times (analysis_time)
                 SELECT analysis_time
                 FROM model_data md
                 WHERE md.producer_id=%s AND md.target_id=%s AND parameter_id=%s AND md.analysis_time>=%s AND md.analysis_time<%s
                 GROUP BY md.analysis_time ORDER BY md.analysis_time;',
                   producerId, targetId, parameterIdT, quote_nullable(startDate), quote_nullable(endDate));


    -- loop variable of loop over rows must be a record or row variable or list of scalar variables
    FOR rec IN -- Etsitään tmax18 hetkellisistä lämpötiloista jokaiselle analyysiajalle
        SELECT analysis_time FROM temp_tmax18_analysis_times
        LOOP

            ahour := TO_CHAR(rec.analysis_time at time zone 'UTC', 'HH24');
            IF (ahour IN ('06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17')) THEN
                lowLeadtime := -11;
                uppLeadtime := 12;
            ELSE
                lowLeadtime := 1;
                uppLeadtime := 24;
            END IF;

            counter := 0;
            WHILE counter < dayCount
                LOOP

                    -- Lasketaan yön alimmat lämpötilat väliaikaistauluun
                    EXECUTE FORMAT('INSERT INTO temp_tmax18_results (analysis_time,leadtime,forecaster_id,value_max,hour_count)
                      SELECT %s, max(leadtime), min(forecaster_id), max(value), count(value)
              FROM model_data md2
              WHERE md2.producer_id=%s AND md2.target_id=%s AND md2.parameter_id=%s AND md2.analysis_time=%s
                AND md2.leadtime>=%s AND md2.leadtime<=%s
                        AND TO_CHAR(md2.analysis_time at time zone %s + md2.leadtime*interval%s,%s) in(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);',
                                   quote_nullable(rec.analysis_time), producerId, targetId, parameterIdT,
                                   quote_nullable(rec.analysis_time), lowLeadtime + counter * 24, uppLeadtime + counter * 24,
                                   quote_nullable('UTC'), quote_nullable('1 hour'), quote_nullable('HH24'),
                                   quote_nullable('06'), quote_nullable('07'), quote_nullable('08'), quote_nullable('09'), quote_nullable('10'),
                                   quote_nullable('11'),
                                   quote_nullable('12'), quote_nullable('13'), quote_nullable('14'), quote_nullable('15'), quote_nullable('16'),
                                   quote_nullable('17'), quote_nullable('18'));

                    -- RAISE NOTICE '% % %', rec.analysis_time, lowLeadtime + counter*24, uppLeadtime + counter*24;

                    counter = counter + 1;
                END LOOP;
        END LOOP;

    DROP TABLE temp_tmax18_analysis_times;

    ------------- Siirretään päivänn ylimmat lämpötilat mallin ennustetauluun------------------------
    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_max FROM temp_tmax18_results WHERE hour_count >= 3 AND forecaster_id IS NOT NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value, forecaster_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdtmax18, rec.leadtime, rec.value_max,
                           rec.forecaster_id);
        END LOOP;

    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_max FROM temp_tmax18_results WHERE hour_count >= 3 AND forecaster_id IS NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value)
            VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdtmax18, rec.leadtime, rec.value_max);
        END LOOP;

    DROP TABLE temp_tmax18_results;
    -------------------------------------------------------------------------------------------------

END;
$$;


ALTER FUNCTION public.load_tmax18_from_tf50_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmax18_from_tf50_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  rec RECORD;
BEGIN

  FOR rec IN -- Etsitään päivän maksimit asemaryhmän asemille asemille
  SELECT target_id FROM targetgroup_map tm WHERE tm.group_id=targetGroupId ORDER BY tm.target_id
  LOOP
    EXECUTE load_tmax18_from_tf50_f(producerId,rec.target_id,dayCount,startDate,endDate);
  END LOOP;

END;
$$;


ALTER FUNCTION public.load_tmax18_from_tf50_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmin06_from_t_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    parameterIdT      INTEGER := 1;
    parameterIdTmin06 INTEGER := 8;
    lowLeadtime       INTEGER;
    uppLeadtime       INTEGER;
    ahour             CHAR(2);
    counter           INTEGER;
    rec               RECORD;
BEGIN

    CREATE TEMP TABLE temp_tmin06_analysis_times
    (
        analysis_time TIMESTAMPTZ NOT NULL
    );

    CREATE TEMP TABLE temp_tmin06_results
    (
        analysis_time TIMESTAMPTZ NOT NULL,
        leadtime      INT,
        forecaster_id INT,
        value_min     NUMERIC,
        hour_count    INT         NOT NULL
    );

    EXECUTE FORMAT('INSERT INTO temp_tmin06_analysis_times (analysis_time)
                 SELECT analysis_time
                 FROM model_data md
                 WHERE md.producer_id=%s AND md.target_id=%s AND parameter_id=%s AND md.analysis_time>=%s AND md.analysis_time<%s
                 GROUP BY md.analysis_time ORDER BY md.analysis_time;',
                   producerId, targetId, parameterIdT, quote_nullable(startDate), quote_nullable(endDate));

    -- loop variable of loop over rows must be a record or row variable or list of scalar variables
    FOR rec IN -- Etsitään Tmin06 hetkellisistä lämpötiloista jokaiselle analyysiajalle
        SELECT analysis_time FROM temp_tmin06_analysis_times
        LOOP

            ahour := TO_CHAR(rec.analysis_time at time zone 'UTC', 'HH24');
            IF (ahour IN ('18', '19', '20', '21', '22', '23', '00', '01', '02', '03', '04', '05')) THEN
                lowLeadtime := -11;
                uppLeadtime := 12;
            ELSE
                lowLeadtime := 1;
                uppLeadtime := 24;
            END IF;

            counter := 0;
            WHILE counter < dayCount
                LOOP

                    -- Lasketaan yön alimmat lämpötilat väliaikaistauluun
                    EXECUTE FORMAT('INSERT INTO temp_tmin06_results (analysis_time,leadtime,forecaster_id,value_min,hour_count)
                      SELECT %s, max(leadtime), min(forecaster_id), min(value), count(value)
              FROM model_data md2
              WHERE md2.producer_id=%s AND md2.target_id=%s AND md2.parameter_id=%s AND md2.analysis_time=%s
                AND md2.leadtime>=%s AND md2.leadtime<=%s
                        AND TO_CHAR(md2.analysis_time at time zone %s + md2.leadtime*interval%s,%s) in(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);',
                                   quote_nullable(rec.analysis_time), producerId, targetId, parameterIdT,
                                   quote_nullable(rec.analysis_time), lowLeadtime + counter * 24, uppLeadtime + counter * 24,
                                   quote_nullable('UTC'), quote_nullable('1 hour'), quote_nullable('HH24'),
                                   quote_nullable('18'), quote_nullable('19'), quote_nullable('20'), quote_nullable('21'), quote_nullable('22'),
                                   quote_nullable('23'),
                                   quote_nullable('00'), quote_nullable('01'), quote_nullable('02'), quote_nullable('03'), quote_nullable('04'),
                                   quote_nullable('05'), quote_nullable('06'));

                    -- RAISE NOTICE '% % %', rec.analysis_time, lowLeadtime + counter*24, uppLeadtime + counter*24;

                    counter = counter + 1;
                END LOOP;
        END LOOP;

    DROP TABLE temp_tmin06_analysis_times;


    ------------- Siirretään yön alimmat lämpötilat mallin ennustetauluun----------------------------
    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_min FROM temp_tmin06_results WHERE hour_count >= 3 AND forecaster_id IS NOT NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value, forecaster_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdTmin06, rec.leadtime, rec.value_min,
                           rec.forecaster_id);
        END LOOP;

    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_min FROM temp_tmin06_results WHERE hour_count >= 3 AND forecaster_id IS NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value)
            VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdTmin06, rec.leadtime, rec.value_min);
        END LOOP;

    DROP TABLE temp_tmin06_results;

END;
$$;


ALTER FUNCTION public.load_tmin06_from_t_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmin06_from_t_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  rec RECORD;
BEGIN

  FOR rec IN -- Etsitään yön minimit asemaryhmän asemille asemille
  SELECT target_id FROM targetgroup_map tm WHERE tm.group_id=targetGroupId ORDER BY tm.target_id
  LOOP
    EXECUTE load_tmin06_from_t_f(producerId,rec.target_id,dayCount,startDate,endDate);
  END LOOP;

END;
$$;


ALTER FUNCTION public.load_tmin06_from_t_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmin06_from_tf50_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    parameterIdT      INTEGER := 211;
    parameterIdTmin06 INTEGER := 214;
    lowLeadtime       INTEGER;
    uppLeadtime       INTEGER;
    ahour             CHAR(2);
    counter           INTEGER;
    rec               RECORD;
BEGIN

    CREATE TEMP TABLE temp_tmin06_analysis_times
    (
        analysis_time TIMESTAMPTZ NOT NULL
    );

    CREATE TEMP TABLE temp_tmin06_results
    (
        analysis_time TIMESTAMPTZ NOT NULL,
        leadtime      INT,
        forecaster_id INT,
        value_min     NUMERIC,
        hour_count    INT         NOT NULL
    );

    EXECUTE FORMAT('INSERT INTO temp_tmin06_analysis_times (analysis_time)
                 SELECT analysis_time
                 FROM model_data tn
                 WHERE tn.producer_id=%s AND tn.target_id=%s AND parameter_id=%s AND tn.analysis_time>=%s AND tn.analysis_time<%s
                 GROUP BY tn.analysis_time ORDER BY tn.analysis_time;',
                   producerId, targetId, parameterIdT, quote_nullable(startDate), quote_nullable(endDate));

    -- loop variable of loop over rows must be a record or row variable or list of scalar variables
    FOR rec IN -- Etsitään Tmin06 hetkellisistä lämpötiloista jokaiselle analyysiajalle
        SELECT analysis_time FROM temp_tmin06_analysis_times
        LOOP

            ahour := TO_CHAR(rec.analysis_time at time zone 'UTC', 'HH24');
            IF (ahour IN ('18', '19', '20', '21', '22', '23', '00', '01', '02', '03', '04', '05')) THEN
                lowLeadtime := -11;
                uppLeadtime := 12;
            ELSE
                lowLeadtime := 1;
                uppLeadtime := 24;
            END IF;

            counter := 0;
            WHILE counter < dayCount
                LOOP

                    -- Lasketaan yön alimmat lämpötilat väliaikaistauluun
                    EXECUTE FORMAT('INSERT INTO temp_tmin06_results (analysis_time,leadtime,forecaster_id,value_min,hour_count)
                      SELECT %s, max(leadtime), min(forecaster_id), min(value), count(value)
              FROM model_data tn2
              WHERE tn2.producer_id=%s AND tn2.target_id=%s AND tn2.parameter_id=%s AND tn2.analysis_time=%s
                AND tn2.leadtime>=%s AND tn2.leadtime<=%s
                        AND TO_CHAR(tn2.analysis_time at time zone %s + tn2.leadtime*interval%s,%s) in(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);',
                                   quote_nullable(rec.analysis_time), producerId, targetId, parameterIdT,
                                   quote_nullable(rec.analysis_time), lowLeadtime + counter * 24, uppLeadtime + counter * 24,
                                   quote_nullable('UTC'), quote_nullable('1 hour'), quote_nullable('HH24'),
                                   quote_nullable('18'), quote_nullable('19'), quote_nullable('20'), quote_nullable('21'), quote_nullable('22'),
                                   quote_nullable('23'),
                                   quote_nullable('00'), quote_nullable('01'), quote_nullable('02'), quote_nullable('03'), quote_nullable('04'),
                                   quote_nullable('05'), quote_nullable('06'));

                    -- RAISE NOTICE '% % %', rec.analysis_time, lowLeadtime + counter*24, uppLeadtime + counter*24;

                    counter = counter + 1;
                END LOOP;
        END LOOP;

    DROP TABLE temp_tmin06_analysis_times;

    ------------- Siirretään yön alimmat lämpötilat mallin ennustetauluun----------------------------
    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_min FROM temp_tmin06_results WHERE hour_count >= 3 AND forecaster_id IS NOT NULL
        LOOP
            --RAISE NOTICE '% % % % % % %', producerId, quote_nullable(rec.analysis_time), targetId, parameterIdTmin06, rec.leadtime, rec.value_min, rec.forecaster_id;
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value, forecaster_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdTmin06, rec.leadtime, rec.value_min,
                           rec.forecaster_id);
        END LOOP;

    FOR rec IN
        SELECT analysis_time, leadtime, forecaster_id, value_min FROM temp_tmin06_results WHERE hour_count >= 3 AND forecaster_id IS NULL
        LOOP
            EXECUTE FORMAT('INSERT INTO model_data (producer_id, analysis_time, target_id, parameter_id, leadtime, value)
            VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;',
                           producerId, quote_nullable(rec.analysis_time), targetId, parameterIdTmin06, rec.leadtime, rec.value_min);
        END LOOP;

    DROP TABLE temp_tmin06_results;
    -------------------------------------------------------------------------------------------------

END;
$$;


ALTER FUNCTION public.load_tmin06_from_tf50_f(producerid integer, targetid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.load_tmin06_from_tf50_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  rec RECORD;
BEGIN

  FOR rec IN -- Etsitään yön minimit asemaryhmän asemille asemille
  SELECT target_id FROM targetgroup_map tm WHERE tm.group_id=targetGroupId ORDER BY tm.target_id
  LOOP
    EXECUTE load_tmin06_from_tf50_f(producerId,rec.target_id,dayCount,startDate,endDate);
  END LOOP;

END;
$$;


ALTER FUNCTION public.load_tmin06_from_tf50_targetgroup_f(producerid integer, targetgroupid integer, daycount integer, startdate text, enddate text) OWNER TO verifadmin;


CREATE FUNCTION public.store_last_modified_f() RETURNS trigger
    LANGUAGE plpgsql STABLE STRICT SECURITY DEFINER
    AS $$
BEGIN
  NEW.modified_last := current_timestamp;
  NEW.modified_by := session_user;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.store_last_modified_f() OWNER TO verifadmin;


CREATE FUNCTION public.targets_type_id_check_f() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
BEGIN

  IF TG_ARGV[0]::int <> NEW.type_id THEN
    RAISE EXCEPTION 'Target with class_id % not allowed in table %', NEW.type_id, TG_TABLE_NAME;
  END IF;

  RETURN NEW;

END;
$$;


ALTER FUNCTION public.targets_type_id_check_f() OWNER TO verifadmin;


CREATE FUNCTION public.update_used_models_all_producers_f(startdate date, enddate date) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  rec RECORD;
BEGIN

  FOR rec IN
  SELECT id FROM producers ORDER BY id
  LOOP
    EXECUTE update_used_models_f(rec.id, startDate, endDate);
  END LOOP;

END;
$$;


ALTER FUNCTION public.update_used_models_all_producers_f(startdate date, enddate date) OWNER TO verifadmin;


CREATE FUNCTION public.update_used_models_f(producerid integer, startdate date, enddate date) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  row_lks location_kinds%ROWTYPE;
  row_tgm targetgroup_map%ROWTYPE;
  rec RECORD;
BEGIN

  -- cast(to_char(analysis_time,'HH24') as smallint)

  FOR rec IN
  SELECT f.producer_id,f.analysis_time FROM forecasts f WHERE f.producer_id=producerId AND f.analysis_time >= startDate AND f.analysis_time < endDate ORDER BY analysis_time
  LOOP

    FOR row_lks IN
    SELECT * FROM location_kinds
    LOOP
      EXECUTE format('INSERT INTO used_model_hours (producer_id,parameter_id,analysis_hour,leadtime) SELECT DISTINCT %s as integer, tn.parameter_id, EXTRACT(HOUR FROM tn.analysis_time AT TIME ZONE %s) as smallint, tn.leadtime FROM model_data tn WHERE tn.producer_id=%s AND tn.analysis_time=%s AND tn.target_id IN(SELECT l.fmisid FROM locations l WHERE l.kind_id=%s) ON CONFLICT DO NOTHING', rec.producer_id, quote_nullable('UTC'), rec.producer_id, quote_nullable(rec.analysis_time), row_lks.id);

      EXECUTE format('INSERT INTO used_model_locations (producer_id,parameter_id,location_id,location_kind_id) SELECT DISTINCT tn.producer_id, tn.parameter_id, tn.target_id, %s FROM model_data tn WHERE tn.producer_id=%s AND tn.analysis_time=%s AND tn.target_id IN(SELECT l.fmisid FROM locations l WHERE l.kind_id=%s) ON CONFLICT DO NOTHING', row_lks.id,  rec.producer_id, quote_nullable(rec.analysis_time), row_lks.id);
    END LOOP;

    FOR row_tgm IN
    SELECT * FROM targetgroup_map
    LOOP
      EXECUTE format('INSERT INTO used_model_groups (producer_id,parameter_id,group_id) SELECT DISTINCT tn.producer_id, tn.parameter_id, %s FROM model_data tn WHERE tn.producer_id=%s AND tn.analysis_time=%s AND tn.target_id IN(SELECT tgm.target_id FROM targetgroup_map tgm WHERE tgm.group_id=%s) ON CONFLICT DO NOTHING', row_tgm.group_id,  rec.producer_id, quote_nullable(rec.analysis_time), row_tgm.group_id);
    END LOOP;

  END LOOP;

END;
$$;


ALTER FUNCTION public.update_used_models_f(producerid integer, startdate date, enddate date) OWNER TO verifadmin;


CREATE FUNCTION public.validate_endwind_corr_coeff_f(targetid integer, sensorno integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  slope_limit_a NUMERIC := 0.05 ; -- per 5 degrees
  slope_limit_b NUMERIC := 0.10 ; -- per 5 degrees
  slope_limit_c NUMERIC := 0.03 ; -- per 5 degrees
  slope_limit_d NUMERIC := 0.04 ; -- per 5 degrees
  rec RECORD;
BEGIN

  CREATE TEMP TABLE temp_corr_coeff(
    angle_i INT,
    coeff_i NUMERIC,
    slope_left NUMERIC,
    slope_right NUMERIC
  );

  -- used 5 degrees step
  EXECUTE FORMAT('INSERT INTO temp_corr_coeff (angle_i,coeff_i,slope_left,slope_right)
                 SELECT c2.angle,c2.coefficient,c2.coefficient-c1.coefficient,c3.coefficient-c2.coefficient
                 FROM wind_correction_coefficients c1, wind_correction_coefficients c2, wind_correction_coefficients c3, wind_correction_sets s
                 WHERE c1.angle+5=c2.angle AND c2.angle=c3.angle-5 AND c1.set_id=c2.set_id AND c1.set_id=c3.set_id AND c1.set_id=s.id and s.target_id=%s AND s.sensor_no=%s AND s.valid_to IS NULL
                 ORDER BY c2.angle;', targetId, sensorNo);

  -- upper clause not handle 5 first and latest angles
  EXECUTE FORMAT('INSERT INTO temp_corr_coeff (angle_i,coeff_i,slope_left,slope_right) SELECT c.angle,c.coefficient,0.0,0.0
                 FROM wind_correction_coefficients c, wind_correction_sets s
                 WHERE c.set_id=s.id and s.target_id=%s AND s.sensor_no=%s AND s.valid_to IS NULL AND c.angle IN(1,2,3,4,5,356,357,358,359,360)
                 ORDER BY c.angle;', targetId, sensorNo);

  -- loop variable of loop over rows must be a record or row variable or list of scalar variables
  FOR rec IN
  SELECT angle_i,coeff_i,slope_left,slope_right FROM temp_corr_coeff
  LOOP

    IF (rec.coeff_i <= 1.0 AND ((ABS(rec.slope_left) >= slope_limit_a AND ABS(rec.slope_right) >= slope_limit_a) OR ABS(rec.slope_left) >= slope_limit_b OR ABS(rec.slope_right) >= slope_limit_b)) THEN -- FALSE
      EXECUTE FORMAT('UPDATE wind_correction_coefficients SET is_enabled=FALSE WHERE angle=%s AND set_id = (SELECT id FROM wind_correction_sets WHERE target_id=%s AND sensor_no=%s and valid_to IS NULL);', rec.angle_i, targetId, sensorNo) ;

    ELSEIF (rec.coeff_i <= 1.1 AND rec.coeff_i > 1.0 AND ((ABS(rec.slope_left) >= slope_limit_c AND ABS(rec.slope_right) >= slope_limit_c) OR ABS(rec.slope_left) >= slope_limit_d OR ABS(rec.slope_right) >= slope_limit_d)) THEN -- FALSE
      EXECUTE FORMAT('UPDATE wind_correction_coefficients SET is_enabled=FALSE WHERE angle=%s AND set_id = (SELECT id FROM wind_correction_sets WHERE target_id=%s AND sensor_no=%s and valid_to IS NULL);', rec.angle_i, targetId, sensorNo) ;

    ELSEIF (rec.coeff_i <= 1.1) THEN -- TRUE
      EXECUTE FORMAT('UPDATE wind_correction_coefficients SET is_enabled=TRUE WHERE angle=%s AND set_id = (SELECT id FROM wind_correction_sets WHERE target_id=%s AND sensor_no=%s and valid_to IS NULL);', rec.angle_i, targetId, sensorNo) ;

    ELSE -- FALSE
      EXECUTE FORMAT('UPDATE wind_correction_coefficients SET is_enabled=FALSE WHERE angle=%s AND set_id = (SELECT id FROM wind_correction_sets WHERE target_id=%s AND sensor_no=%s and valid_to IS NULL);', rec.angle_i, targetId, sensorNo) ;
    END IF;

  END LOOP ;

  DROP TABLE temp_corr_coeff ;

END ;
$$;


ALTER FUNCTION public.validate_endwind_corr_coeff_f(targetid integer, sensorno integer) OWNER TO verifadmin;

SET default_tablespace = '';


CREATE TABLE public.model_data (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    forecaster_id integer
)
PARTITION BY LIST (producer_id);


ALTER TABLE public.model_data OWNER TO verifadmin;

SET default_table_access_method = heap;


CREATE TABLE public.adf_preop_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT adf_preop_forecasts_producer_id_check CHECK ((producer_id = 55))
);


ALTER TABLE public.adf_preop_forecasts OWNER TO verifadmin;


CREATE TABLE public.results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric
)
PARTITION BY LIST (producer_id);


ALTER TABLE public.results OWNER TO verifadmin;


CREATE TABLE public.adf_preop_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT adf_preop_results_producer_id_chk CHECK ((producer_id = 55))
);


ALTER TABLE public.adf_preop_results OWNER TO verifadmin;


CREATE TABLE public.aifs_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT aifs_forecasts_producer_id_check CHECK ((producer_id = 54))
);


ALTER TABLE public.aifs_forecasts OWNER TO verifadmin;


CREATE TABLE public.aifs_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT aifs_results_producer_id_chk CHECK ((producer_id = 54))
);


ALTER TABLE public.aifs_results OWNER TO verifadmin;


CREATE TABLE public.aila_preop_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT aila_preop_forecasts_producer_id_check CHECK ((producer_id = 53))
);


ALTER TABLE public.aila_preop_forecasts OWNER TO verifadmin;


CREATE TABLE public.aila_preop_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT aila_preop_results_producer_id_chk CHECK ((producer_id = 53))
);


ALTER TABLE public.aila_preop_results OWNER TO verifadmin;


CREATE TABLE public.airport_forecast_view_settings (
    producer_id integer NOT NULL,
    location_id_view integer NOT NULL,
    location_id_data integer NOT NULL,
    parameter_id_view integer NOT NULL,
    parameter_id_data integer NOT NULL,
    estimator_id integer NOT NULL
);


ALTER TABLE public.airport_forecast_view_settings OWNER TO verifadmin;


CREATE TABLE public.airport_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT airport_forecasts_producer_id_check CHECK ((producer_id = 23))
);


ALTER TABLE public.airport_forecasts OWNER TO verifadmin;


CREATE TABLE public.airport_raw_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT airport_raw_results_producer_id_chk CHECK ((producer_id = 24))
);


ALTER TABLE public.airport_raw_results OWNER TO verifadmin;


CREATE TABLE public.airport_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT airport_results_producer_id_chk CHECK ((producer_id = 23))
);


ALTER TABLE public.airport_results OWNER TO verifadmin;


CREATE TABLE public.apple_weather_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT apple_weather_forecasts_producer_id_check CHECK ((producer_id = 46))
);


ALTER TABLE public.apple_weather_forecasts OWNER TO verifadmin;


CREATE TABLE public.apple_weather_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT apple_weather_results_producer_id_chk CHECK ((producer_id = 46))
);


ALTER TABLE public.apple_weather_results OWNER TO verifadmin;


CREATE TABLE public.areas (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description_id integer,
    modified_by text,
    modified_last timestamp with time zone,
    geom public.geometry,
    CONSTRAINT areas_id_check CHECK (((id > 0) AND (id < 10000))),
    CONSTRAINT enforce_dims_geom CHECK ((public.st_ndims(geom) = 2)),
    CONSTRAINT enforce_geotype_geom CHECK (((public.geometrytype(geom) = 'MULTIPOLYGON'::text) OR (geom IS NULL))),
    CONSTRAINT enforce_srid_geom CHECK ((public.st_srid(geom) = 4326))
);


ALTER TABLE public.areas OWNER TO verifadmin;


CREATE TABLE public.available_observations (
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    is_used boolean DEFAULT true NOT NULL,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.available_observations OWNER TO verifadmin;


CREATE TABLE public.base_result_orders (
    producer_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    period_type_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    priority integer DEFAULT 1 NOT NULL,
    CONSTRAINT base_result_orders_priority_chk CHECK ((priority >= 1))
);


ALTER TABLE public.base_result_orders OWNER TO verifadmin;


CREATE TABLE public.blend_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT blend_forecasts_producer_id_check CHECK ((producer_id = 12))
);


ALTER TABLE public.blend_forecasts OWNER TO verifadmin;


CREATE TABLE public.blend_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT blend_results_producer_id_chk CHECK ((producer_id = 12))
);


ALTER TABLE public.blend_results OWNER TO verifadmin;


CREATE TABLE public.bris_preop_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT bris_preop_forecasts_producer_id_check CHECK ((producer_id = 50))
);


ALTER TABLE public.bris_preop_forecasts OWNER TO verifadmin;


CREATE TABLE public.bris_preop_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT bris_preop_results_producer_id_chk CHECK ((producer_id = 50))
);


ALTER TABLE public.bris_preop_results OWNER TO verifadmin;


CREATE TABLE public.climatology (
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    clim_time timestamp with time zone NOT NULL,
    value numeric NOT NULL,
    statistic_name character varying(20) NOT NULL
);


ALTER TABLE public.climatology OWNER TO verifadmin;


CREATE TABLE public.climatology_orders (
    id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    statistic_name character varying(20) NOT NULL,
    ordered_time timestamp with time zone DEFAULT now() NOT NULL,
    started_time timestamp with time zone,
    delivered_time timestamp with time zone,
    climatology_count integer,
    CONSTRAINT climatology_orders_climatology_count_chk CHECK (((climatology_count IS NULL) OR (climatology_count >= 0)))
);


ALTER TABLE public.climatology_orders OWNER TO verifadmin;


CREATE SEQUENCE public.climatology_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.climatology_orders_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.climatology_orders_id_seq OWNED BY public.climatology_orders.id;



CREATE TABLE public.climcorecmwf_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT climcorecmwf_forecasts_producer_id_check CHECK ((producer_id = 27))
);


ALTER TABLE public.climcorecmwf_forecasts OWNER TO verifadmin;


CREATE TABLE public.climcorecmwf_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT climcorecmwf_results_producer_id_chk CHECK ((producer_id = 27))
);


ALTER TABLE public.climcorecmwf_results OWNER TO verifadmin;


CREATE TABLE public.climcorhirlam_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT climcorhirlam_forecasts_producer_id_check CHECK ((producer_id = 24))
);


ALTER TABLE public.climcorhirlam_forecasts OWNER TO verifadmin;


CREATE TABLE public.climcorhirlam_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT climcorhirlam_results_producer_id_chk CHECK ((producer_id = 24))
);


ALTER TABLE public.climcorhirlam_results OWNER TO verifadmin;


CREATE TABLE public.climcormeps_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT climcormeps_forecasts_producer_id_check CHECK ((producer_id = 26))
);


ALTER TABLE public.climcormeps_forecasts OWNER TO verifadmin;


CREATE TABLE public.climcormeps_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT climcormeps_results_producer_id_chk CHECK ((producer_id = 26))
);


ALTER TABLE public.climcormeps_results OWNER TO verifadmin;


CREATE TABLE public.copernicus_nemo_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT copernicus_nemo_results_producer_id_chk CHECK ((producer_id = 42))
);


ALTER TABLE public.copernicus_nemo_results OWNER TO verifadmin;


CREATE TABLE public.derivative_estimators (
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    weighted_average boolean DEFAULT true NOT NULL,
    base_id integer NOT NULL,
    base_parameter_id integer NOT NULL,
    base_estimator_id integer NOT NULL,
    base_leadtime integer NOT NULL,
    base_analysis_hour smallint NOT NULL
);


ALTER TABLE public.derivative_estimators OWNER TO verifadmin;


CREATE TABLE public.derivative_rvm (
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    base_parameter_id integer NOT NULL,
    base_estimator_id integer NOT NULL,
    comparison_producer_id integer NOT NULL,
    best_base_value numeric NOT NULL
);


ALTER TABLE public.derivative_rvm OWNER TO verifadmin;


CREATE TABLE public.dnncormeps_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT dnncormeps_forecasts_producer_id_check CHECK ((producer_id = 40))
);


ALTER TABLE public.dnncormeps_forecasts OWNER TO verifadmin;


CREATE TABLE public.dnncormeps_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT dnncormeps_results_producer_id_chk CHECK ((producer_id = 40))
);


ALTER TABLE public.dnncormeps_results OWNER TO verifadmin;


CREATE TABLE public.dwd_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT dwd_forecasts_producer_id_check CHECK ((producer_id = 8))
);


ALTER TABLE public.dwd_forecasts OWNER TO verifadmin;


CREATE TABLE public.dwd_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT dwd_results_producer_id_chk CHECK ((producer_id = 8))
);


ALTER TABLE public.dwd_results OWNER TO verifadmin;


CREATE TABLE public.ecmwf_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    forecaster_id integer,
    CONSTRAINT ecmwf_forecasts_producer_id_check CHECK ((producer_id = 2))
);


ALTER TABLE public.ecmwf_forecasts OWNER TO verifadmin;


CREATE TABLE public.ecmwf_probability_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT ecmwf_probability_forecasts_producer_id_check CHECK ((producer_id = 45))
);


ALTER TABLE public.ecmwf_probability_forecasts OWNER TO verifadmin;


CREATE TABLE public.ecmwf_probability_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT ecmwf_probability_results_producer_id_chk CHECK ((producer_id = 45))
);


ALTER TABLE public.ecmwf_probability_results OWNER TO verifadmin;


CREATE TABLE public.ecmwf_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT ecmwf_results_producer_id_chk CHECK ((producer_id = 2))
);


ALTER TABLE public.ecmwf_results OWNER TO verifadmin;


CREATE TABLE public.ecmwfeps_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT ecmwfeps_forecasts_producer_id_check CHECK ((producer_id = 25))
);


ALTER TABLE public.ecmwfeps_forecasts OWNER TO verifadmin;


CREATE TABLE public.ecmwfeps_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT ecmwfeps_results_producer_id_chk CHECK ((producer_id = 25))
);


ALTER TABLE public.ecmwfeps_results OWNER TO verifadmin;


CREATE TABLE public.estimators (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description_id integer,
    minimum_value numeric,
    maximum_value numeric,
    modified_by text,
    modified_last timestamp with time zone,
    scale smallint NOT NULL,
    "character" character varying(100) DEFAULT 'UNDEFINED'::character varying NOT NULL
);


ALTER TABLE public.estimators OWNER TO verifadmin;


CREATE SEQUENCE public.estimators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estimators_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.estimators_id_seq OWNED BY public.estimators.id;



CREATE TABLE public.localization_entries (
    id integer NOT NULL,
    tablename text NOT NULL,
    columnname text NOT NULL,
    entity_id integer NOT NULL,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.localization_entries OWNER TO verifadmin;


CREATE TABLE public.localization_languages (
    id integer NOT NULL,
    code character varying(2) NOT NULL,
    description text,
    modified_by text,
    modified_last timestamp with time zone,
    CONSTRAINT localization_languages_code_chk CHECK ((length((code)::text) = 2))
);


ALTER TABLE public.localization_languages OWNER TO verifadmin;


CREATE TABLE public.localization_translations (
    entry_id integer NOT NULL,
    language_id integer NOT NULL,
    translation text NOT NULL,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.localization_translations OWNER TO verifadmin;


CREATE VIEW public.estimators_v AS
 SELECT s.id,
    s.name,
    ll.code AS language_code,
    lt.translation AS description,
    s.minimum_value,
    s.maximum_value
   FROM public.estimators s,
    public.localization_languages ll,
    public.localization_entries le,
    public.localization_translations lt
  WHERE ((s.description_id = le.id) AND (lt.language_id = ll.id) AND (lt.entry_id = le.id));


ALTER VIEW public.estimators_v OWNER TO verifadmin;


CREATE TABLE public.fid (
    forecaster_id integer
);


ALTER TABLE public.fid OWNER TO verifadmin;


CREATE TABLE public.forecaster_privileges (
    id integer NOT NULL,
    forecaster_id integer NOT NULL,
    watcher_id integer NOT NULL,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.forecaster_privileges OWNER TO verifadmin;


CREATE SEQUENCE public.forecaster_privileges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forecaster_privileges_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.forecaster_privileges_id_seq OWNED BY public.forecaster_privileges.id;



CREATE TABLE public.forecasterid (
    forecaster_id integer
);


ALTER TABLE public.forecasterid OWNER TO verifadmin;


CREATE SEQUENCE public.forecasters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forecasters_id_seq OWNER TO verifadmin;


CREATE TABLE public.forecasters (
    id integer DEFAULT nextval('public.forecasters_id_seq'::regclass) NOT NULL,
    username character varying(100) NOT NULL,
    realname character varying(100),
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.forecasters OWNER TO verifadmin;


CREATE TABLE public.forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    arrive_time timestamp with time zone,
    information text,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.forecasts OWNER TO verifadmin;


COMMENT ON COLUMN public.forecasts.arrive_time IS 'Unused. Nothing reads this column; where populated it repeats analysis_time. Arrival-time verification uses producers.arrival_leadtime and producers.analysis_hours. Only fmi-verification-loader writes a meaningful value, the time it queried EDR.';



CREATE TABLE public.gfs_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT gfs_forecasts_producer_id_check CHECK ((producer_id = 14))
);


ALTER TABLE public.gfs_forecasts OWNER TO verifadmin;


CREATE TABLE public.gfs_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT gfs_results_producer_id_chk CHECK ((producer_id = 14))
);


ALTER TABLE public.gfs_results OWNER TO verifadmin;


CREATE TABLE public.grade_colors (
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    min_value numeric NOT NULL,
    max_value numeric NOT NULL,
    num_steps smallint NOT NULL,
    low_color character varying(10) DEFAULT 'BLUE'::character varying NOT NULL,
    high_color character varying(10) DEFAULT 'RED'::character varying NOT NULL,
    mid_color character varying(10) DEFAULT 'WHITE'::character varying NOT NULL,
    CONSTRAINT grade_colors_check CHECK ((max_value > min_value)),
    CONSTRAINT grade_colors_num_steps_check CHECK ((num_steps >= 0))
);


ALTER TABLE public.grade_colors OWNER TO verifadmin;


CREATE TABLE public.harmonie_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT harmonie_forecasts_producer_id_check CHECK ((producer_id = 3))
);


ALTER TABLE public.harmonie_forecasts OWNER TO verifadmin;


CREATE TABLE public.harmonie_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT harmonie_results_producer_id_chk CHECK ((producer_id = 3))
);


ALTER TABLE public.harmonie_results OWNER TO verifadmin;


CREATE TABLE public.helsinki_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT helsinki_forecasts_producer_id_check CHECK ((producer_id = 18))
);


ALTER TABLE public.helsinki_forecasts OWNER TO verifadmin;


CREATE TABLE public.helsinki_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT helsinki_results_producer_id_chk CHECK ((producer_id = 18))
);


ALTER TABLE public.helsinki_results OWNER TO verifadmin;


CREATE TABLE public.hirlam_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT hirlam_forecasts_producer_id_check CHECK ((producer_id = 9))
);


ALTER TABLE public.hirlam_forecasts OWNER TO verifadmin;


CREATE TABLE public.hirlam_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT hirlam_results_producer_id_chk CHECK ((producer_id = 9))
);


ALTER TABLE public.hirlam_results OWNER TO verifadmin;


CREATE TABLE public.icao_stations (
    fmisid integer NOT NULL,
    icao_code character varying(4) NOT NULL,
    modified_by text,
    modified_last timestamp with time zone,
    CONSTRAINT icao_stations_fmisid_check CHECK ((fmisid > 100000))
);


ALTER TABLE public.icao_stations OWNER TO verifadmin;


CREATE TABLE public.icon_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT icon_forecasts_producer_id_check CHECK ((producer_id = 13))
);


ALTER TABLE public.icon_forecasts OWNER TO verifadmin;


CREATE TABLE public.icon_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT icon_results_producer_id_chk CHECK ((producer_id = 13))
);


ALTER TABLE public.icon_results OWNER TO verifadmin;


CREATE TABLE public.kairosnwc_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT kairosnwc_forecasts_producer_id_check CHECK ((producer_id = 52))
);


ALTER TABLE public.kairosnwc_forecasts OWNER TO verifadmin;


CREATE TABLE public.kairosnwc_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT kairosnwc_results_producer_id_chk CHECK ((producer_id = 52))
);


ALTER TABLE public.kairosnwc_results OWNER TO verifadmin;


CREATE TABLE public.laps_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT laps_forecasts_producer_id_check CHECK ((producer_id = 35))
);


ALTER TABLE public.laps_forecasts OWNER TO verifadmin;


CREATE TABLE public.laps_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT laps_results_producer_id_chk CHECK ((producer_id = 35))
);


ALTER TABLE public.laps_results OWNER TO verifadmin;


CREATE SEQUENCE public.localization_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.localization_entries_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.localization_entries_id_seq OWNED BY public.localization_entries.id;



CREATE SEQUENCE public.localization_languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.localization_languages_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.localization_languages_id_seq OWNED BY public.localization_languages.id;



CREATE TABLE public.location_kinds (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description_id integer,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.location_kinds OWNER TO verifadmin;


CREATE SEQUENCE public.location_kinds_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.location_kinds_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.location_kinds_id_seq OWNED BY public.location_kinds.id;



CREATE TABLE public.locations (
    fmisid integer NOT NULL,
    name_id integer,
    geom public.geometry,
    elevation numeric,
    external_info text,
    modified_by text,
    modified_last timestamp with time zone,
    kind_id smallint,
    CONSTRAINT enforce_dims_geometry CHECK ((public.st_ndims(geom) = 2)),
    CONSTRAINT enforce_geotype_geometry CHECK (((public.geometrytype(geom) = 'POINT'::text) OR (geom IS NULL))),
    CONSTRAINT enforce_srid_geometry CHECK ((public.st_srid(geom) = 4326)),
    CONSTRAINT locations_fmisid_check CHECK ((fmisid > 100000))
);


ALTER TABLE public.locations OWNER TO verifadmin;


CREATE VIEW public.locations_v AS
 SELECT l.fmisid,
    ll.code AS language_code,
    lt.translation AS name,
    l.geom,
    l.external_info
   FROM public.locations l,
    public.localization_languages ll,
    public.localization_entries le,
    public.localization_translations lt
  WHERE ((l.name_id = le.id) AND (lt.language_id = ll.id) AND (lt.entry_id = le.id));


ALTER VIEW public.locations_v OWNER TO verifadmin;


CREATE TABLE public.maisemakalmec_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT maisemakalmec_forecasts_producer_id_check CHECK ((producer_id = 31))
);


ALTER TABLE public.maisemakalmec_forecasts OWNER TO verifadmin;


CREATE TABLE public.maisemakalmec_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT maisemakalmec_results_producer_id_chk CHECK ((producer_id = 31))
);


ALTER TABLE public.maisemakalmec_results OWNER TO verifadmin;


CREATE TABLE public.maisemasmartmet_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT maisemasmartmet_forecasts_producer_id_check CHECK ((producer_id = 30))
);


ALTER TABLE public.maisemasmartmet_forecasts OWNER TO verifadmin;


CREATE TABLE public.maisemasmartmet_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT maisemasmartmet_results_producer_id_chk CHECK ((producer_id = 30))
);


ALTER TABLE public.maisemasmartmet_results OWNER TO verifadmin;


CREATE TABLE public.meps_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT meps_forecasts_producer_id_check CHECK ((producer_id = 10))
);


ALTER TABLE public.meps_forecasts OWNER TO verifadmin;


CREATE TABLE public.meps_ml_preop_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT meps_ml_preop_forecasts_producer_id_check CHECK ((producer_id = 47))
);


ALTER TABLE public.meps_ml_preop_forecasts OWNER TO verifadmin;


CREATE TABLE public.meps_ml_preop_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT meps_ml_preop_results_producer_id_chk CHECK ((producer_id = 47))
);


ALTER TABLE public.meps_ml_preop_results OWNER TO verifadmin;


CREATE TABLE public.meps_probability_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT meps_probability_forecasts_producer_id_check CHECK ((producer_id = 44))
);


ALTER TABLE public.meps_probability_forecasts OWNER TO verifadmin;


CREATE TABLE public.meps_probability_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT meps_probability_results_producer_id_chk CHECK ((producer_id = 44))
);


ALTER TABLE public.meps_probability_results OWNER TO verifadmin;


CREATE TABLE public.meps_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT meps_results_producer_id_chk CHECK ((producer_id = 10))
);


ALTER TABLE public.meps_results OWNER TO verifadmin;


CREATE TABLE public.met_no_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT met_no_forecasts_producer_id_check CHECK ((producer_id = 6))
);


ALTER TABLE public.met_no_forecasts OWNER TO verifadmin;


CREATE TABLE public.met_no_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT met_no_results_producer_id_chk CHECK ((producer_id = 6))
);


ALTER TABLE public.met_no_results OWNER TO verifadmin;


CREATE TABLE public.metcoopnwc_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT metcoopnwc_forecasts_producer_id_check CHECK ((producer_id = 17))
);


ALTER TABLE public.metcoopnwc_forecasts OWNER TO verifadmin;


CREATE TABLE public.metcoopnwc_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT metcoopnwc_results_producer_id_chk CHECK ((producer_id = 17))
);


ALTER TABLE public.metcoopnwc_results OWNER TO verifadmin;


CREATE TABLE public.model_parameter_views (
    parameter_id integer NOT NULL,
    general_view boolean DEFAULT true NOT NULL,
    aviation_view boolean DEFAULT false NOT NULL
);


ALTER TABLE public.model_parameter_views OWNER TO verifadmin;


CREATE TABLE public.mos_development_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT mos_development_forecasts_producer_id_check CHECK ((producer_id = 15))
);


ALTER TABLE public.mos_development_forecasts OWNER TO verifadmin;


CREATE TABLE public.mos_development_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT mos_development_results_producer_id_chk CHECK ((producer_id = 15))
);


ALTER TABLE public.mos_development_results OWNER TO verifadmin;


CREATE TABLE public.mos_production_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT mos_production_forecasts_producer_id_check CHECK ((producer_id = 4))
);


ALTER TABLE public.mos_production_forecasts OWNER TO verifadmin;


CREATE TABLE public.mos_production_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT mos_production_results_producer_id_chk CHECK ((producer_id = 4))
);


ALTER TABLE public.mos_production_results OWNER TO verifadmin;


CREATE TABLE public.moseckrigingx_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT moseckrigingx_forecasts_producer_id_check CHECK ((producer_id = 35))
);


ALTER TABLE public.moseckrigingx_forecasts OWNER TO verifadmin;


CREATE TABLE public.moseckrigingx_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT moseckrigingx_results_producer_id_chk CHECK ((producer_id = 35))
);


ALTER TABLE public.moseckrigingx_results OWNER TO verifadmin;


CREATE TABLE public.mosecmkriging_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT mosecmkriging_forecasts_producer_id_check CHECK ((producer_id = 11))
);


ALTER TABLE public.mosecmkriging_forecasts OWNER TO verifadmin;


CREATE TABLE public.mosecmkriging_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT mosecmkriging_results_producer_id_chk CHECK ((producer_id = 11))
);


ALTER TABLE public.mosecmkriging_results OWNER TO verifadmin;


CREATE TABLE public.nemo_mw_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT nemo_mw_forecasts_producer_id_check CHECK ((producer_id = 38))
);


ALTER TABLE public.nemo_mw_forecasts OWNER TO verifadmin;


CREATE TABLE public.nemo_mw_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT nemo_mw_results_producer_id_chk CHECK ((producer_id = 38))
);


ALTER TABLE public.nemo_mw_results OWNER TO verifadmin;


CREATE TABLE public.nemo_n2000_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT nemo_n2000_forecasts_producer_id_check CHECK ((producer_id = 39))
);


ALTER TABLE public.nemo_n2000_forecasts OWNER TO verifadmin;


CREATE TABLE public.nemo_n2000_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT nemo_n2000_results_producer_id_chk CHECK ((producer_id = 39))
);


ALTER TABLE public.nemo_n2000_results OWNER TO verifadmin;


CREATE TABLE public.network_map (
    id integer NOT NULL,
    network_id integer NOT NULL,
    target_id integer NOT NULL,
    station_id character varying(50) NOT NULL,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.network_map OWNER TO verifadmin;


CREATE SEQUENCE public.network_map_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.network_map_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.network_map_id_seq OWNED BY public.network_map.id;



CREATE TABLE public.networks (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description_id integer,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.networks OWNER TO verifadmin;


CREATE SEQUENCE public.networks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.networks_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.networks_id_seq OWNED BY public.networks.id;



CREATE TABLE public.oaasecmwf_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT oaasecmwf_forecasts_producer_id_check CHECK ((producer_id = 20))
);


ALTER TABLE public.oaasecmwf_forecasts OWNER TO verifadmin;


CREATE TABLE public.oaasecmwf_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT oaasecmwf_results_producer_id_chk CHECK ((producer_id = 20))
);


ALTER TABLE public.oaasecmwf_results OWNER TO verifadmin;


CREATE TABLE public.oaashirlam_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT oaashirlam_forecasts_producer_id_check CHECK ((producer_id = 19))
);


ALTER TABLE public.oaashirlam_forecasts OWNER TO verifadmin;


CREATE TABLE public.oaashirlam_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT oaashirlam_results_producer_id_chk CHECK ((producer_id = 19))
);


ALTER TABLE public.oaashirlam_results OWNER TO verifadmin;


CREATE TABLE public.observation_endwind_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT observation_endwind_forecasts_producer_id_check CHECK ((producer_id = 59))
);


ALTER TABLE public.observation_endwind_forecasts OWNER TO verifadmin;


CREATE TABLE public.observation_endwind_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT observation_endwind_results_producer_id_chk CHECK ((producer_id = 59))
);


ALTER TABLE public.observation_endwind_results OWNER TO verifadmin;


CREATE TABLE public.observation_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT observation_forecasts_producer_id_check CHECK ((producer_id = 51))
);


ALTER TABLE public.observation_forecasts OWNER TO verifadmin;


CREATE TABLE public.observation_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT observation_results_producer_id_chk CHECK ((producer_id = 51))
);


ALTER TABLE public.observation_results OWNER TO verifadmin;


CREATE TABLE public.pangu_weather_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT pangu_weather_forecasts_producer_id_check CHECK ((producer_id = 33))
);


ALTER TABLE public.pangu_weather_forecasts OWNER TO verifadmin;


CREATE TABLE public.pangu_weather_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT pangu_weather_results_producer_id_chk CHECK ((producer_id = 33))
);


ALTER TABLE public.pangu_weather_results OWNER TO verifadmin;


CREATE TABLE public.parameter_class_limits (
    base_parameter_id integer NOT NULL,
    class_no integer NOT NULL,
    parameter_id integer NOT NULL,
    minimum_value numeric,
    maximum_value numeric,
    CONSTRAINT parameter_class_limits_class_no_check CHECK ((class_no >= 1)),
    CONSTRAINT parameter_class_limits_minimum_value_less_than_maximum_chk CHECK ((((minimum_value IS NULL) AND (maximum_value IS NOT NULL)) OR ((minimum_value IS NOT NULL) AND (maximum_value IS NULL)) OR ((minimum_value IS NOT NULL) AND (maximum_value IS NOT NULL) AND (minimum_value < maximum_value))))
);


ALTER TABLE public.parameter_class_limits OWNER TO verifadmin;


CREATE TABLE public.parameter_map (
    id integer NOT NULL,
    parameter_id integer NOT NULL,
    category character varying(50) NOT NULL,
    alternative_id character varying(80),
    alternative_name character varying(50),
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.parameter_map OWNER TO verifadmin;


CREATE SEQUENCE public.parameter_map_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parameter_map_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.parameter_map_id_seq OWNED BY public.parameter_map.id;



CREATE TABLE public.parameters (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description_id integer,
    minimum_value numeric,
    maximum_value numeric,
    unit character varying(100),
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.parameters OWNER TO verifadmin;


CREATE SEQUENCE public.parameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parameters_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.parameters_id_seq OWNED BY public.parameters.id;



CREATE VIEW public.parameters_v AS
 SELECT s.id,
    s.name,
    ll.code AS language_code,
    lt.translation AS description,
    s.minimum_value,
    s.maximum_value,
    s.unit
   FROM public.parameters s,
    public.localization_languages ll,
    public.localization_entries le,
    public.localization_translations lt
  WHERE ((s.description_id = le.id) AND (lt.language_id = ll.id) AND (lt.entry_id = le.id));


ALTER VIEW public.parameters_v OWNER TO verifadmin;


CREATE TABLE public.peps_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT peps_forecasts_producer_id_check CHECK ((producer_id = 5))
);


ALTER TABLE public.peps_forecasts OWNER TO verifadmin;


CREATE TABLE public.peps_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT peps_results_producer_id_chk CHECK ((producer_id = 5))
);


ALTER TABLE public.peps_results OWNER TO verifadmin;


CREATE TABLE public.period_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description_id integer,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.period_types OWNER TO verifadmin;


CREATE SEQUENCE public.period_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.period_types_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.period_types_id_seq OWNED BY public.period_types.id;



CREATE TABLE public.periods (
    id integer NOT NULL,
    type character varying(50) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    modified_by text,
    modified_last timestamp with time zone,
    CONSTRAINT periods_start_date_end_date_check CHECK ((start_date <= end_date))
);


ALTER TABLE public.periods OWNER TO verifadmin;


CREATE SEQUENCE public.periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.periods_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.periods_id_seq OWNED BY public.periods.id;



CREATE TABLE public.producers (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description_id integer,
    modified_by text,
    modified_last timestamp with time zone,
    arrival_leadtime smallint,
    analysis_hours character varying(61),
    color_id smallint
);


ALTER TABLE public.producers OWNER TO verifadmin;


CREATE VIEW public.producers_v AS
 SELECT s.id,
    s.name,
    ll.code AS language_code,
    lt.translation AS description
   FROM public.producers s,
    public.localization_languages ll,
    public.localization_entries le,
    public.localization_translations lt
  WHERE ((s.description_id = le.id) AND (lt.language_id = ll.id) AND (lt.entry_id = le.id));


ALTER VIEW public.producers_v OWNER TO verifadmin;


CREATE TABLE public.result_orders (
    id integer NOT NULL,
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    ordered_time timestamp with time zone DEFAULT now() NOT NULL,
    started_time timestamp with time zone,
    delivered_time timestamp with time zone,
    result_count integer,
    priority integer DEFAULT 1 NOT NULL,
    CONSTRAINT result_orders_priority_chk CHECK ((priority >= 1)),
    CONSTRAINT result_orders_result_count_chk CHECK (((result_count IS NULL) OR (result_count >= 0)))
);


ALTER TABLE public.result_orders OWNER TO verifadmin;


CREATE SEQUENCE public.result_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.result_orders_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.result_orders_id_seq OWNED BY public.result_orders.id;



CREATE TABLE public.result_parameter_views (
    parameter_id integer NOT NULL,
    general_view boolean DEFAULT true NOT NULL,
    aviation_view boolean DEFAULT false NOT NULL
);


ALTER TABLE public.result_parameter_views OWNER TO verifadmin;


CREATE TABLE public.road_sections (
    section_id character varying(30) NOT NULL,
    road_number integer NOT NULL,
    road_section_number integer NOT NULL,
    description character varying(120),
    geom public.geometry,
    CONSTRAINT enforce_dims_geom CHECK ((public.st_ndims(geom) = 2)),
    CONSTRAINT enforce_geotype_geom CHECK (((public.geometrytype(geom) = 'MULTILINESTRING'::text) OR (geom IS NULL))),
    CONSTRAINT enforce_srid_geom CHECK ((public.st_srid(geom) = 4326))
);


ALTER TABLE public.road_sections OWNER TO verifadmin;


CREATE TABLE public.sea_level_warning_limits (
    location_id integer NOT NULL,
    area_id integer NOT NULL,
    base_parameter_id integer NOT NULL,
    parameter_id integer NOT NULL,
    warning_index smallint NOT NULL,
    warning_level numeric NOT NULL
);


ALTER TABLE public.sea_level_warning_limits OWNER TO verifadmin;


CREATE TABLE public.smartmet_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    forecaster_id integer,
    CONSTRAINT smartmet_forecasts_producer_id_check CHECK ((producer_id = 1))
);


ALTER TABLE public.smartmet_forecasts OWNER TO verifadmin;


CREATE VIEW public.smartmet_forecasts_v AS
 SELECT f.analysis_time,
    f.arrive_time,
    (f.analysis_time + ((sf.leadtime)::double precision * '01:00:00'::interval)) AS forecast_time,
    sf.target_id,
    sf.parameter_id,
    p.name AS parameter_name,
    sf.leadtime,
    sf.value
   FROM public.forecasts f,
    public.model_data sf,
    public.parameters p
  WHERE ((f.analysis_time = sf.analysis_time) AND (f.producer_id = sf.producer_id) AND (f.producer_id = 1) AND (p.id = sf.parameter_id));


ALTER VIEW public.smartmet_forecasts_v OWNER TO postgres;


CREATE TABLE public.smartmet_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT smartmet_results_producer_id_chk CHECK ((producer_id = 1))
);


ALTER TABLE public.smartmet_results OWNER TO verifadmin;


CREATE VIEW public.smartmet_results_v AS
 SELECT sr.producer_id,
    pe.start_date,
    pe.end_date,
    sr.parameter_id,
    sr.estimator_id,
    sr.forecaster_id,
    sr.analysis_hour,
    sr.target_id,
    sr.leadtime,
    sr.count_u,
    sr.value_u,
    sr.count_a,
    sr.value_a
   FROM public.results sr,
    public.periods pe
  WHERE ((sr.period_id = pe.id) AND (sr.producer_id = 1));


ALTER VIEW public.smartmet_results_v OWNER TO postgres;


CREATE TABLE public.smartmetnwc_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT smartmetnwc_forecasts_producer_id_check CHECK ((producer_id = 16))
);


ALTER TABLE public.smartmetnwc_forecasts OWNER TO verifadmin;


CREATE TABLE public.smartmetnwc_preop_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    forecaster_id integer,
    CONSTRAINT smartmetnwc_preop_forecasts_producer_id_check CHECK ((producer_id = 32))
);


ALTER TABLE public.smartmetnwc_preop_forecasts OWNER TO verifadmin;


CREATE TABLE public.smartmetnwc_preop_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT smartmetnwc_preop_results_producer_id_chk CHECK ((producer_id = 32))
);


ALTER TABLE public.smartmetnwc_preop_results OWNER TO verifadmin;


CREATE TABLE public.smartmetnwc_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT smartmetnwc_results_producer_id_chk CHECK ((producer_id = 16))
);


ALTER TABLE public.smartmetnwc_results OWNER TO verifadmin;


CREATE TABLE public.smhi_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT smhi_forecasts_producer_id_check CHECK ((producer_id = 7))
);


ALTER TABLE public.smhi_forecasts OWNER TO verifadmin;


CREATE TABLE public.smhi_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT smhi_results_producer_id_chk CHECK ((producer_id = 7))
);


ALTER TABLE public.smhi_results OWNER TO verifadmin;


CREATE TABLE public.special_observations (
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    obs_time timestamp with time zone NOT NULL,
    value numeric NOT NULL
);


ALTER TABLE public.special_observations OWNER TO verifadmin;


CREATE TABLE public.target_level_results (
    year integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    leadtime integer NOT NULL,
    value numeric NOT NULL
);


ALTER TABLE public.target_level_results OWNER TO verifadmin;


CREATE TABLE public.target_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.target_types OWNER TO verifadmin;


CREATE SEQUENCE public.target_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.target_types_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.target_types_id_seq OWNED BY public.target_types.id;



CREATE TABLE public.targetgroup_map (
    group_id integer NOT NULL,
    target_id integer NOT NULL,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.targetgroup_map OWNER TO verifadmin;


CREATE TABLE public.targetgroups (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description_id integer,
    modified_by text,
    modified_last timestamp with time zone,
    CONSTRAINT targetgroups_id_check CHECK (((id >= 10000) AND (id < 100000)))
);


ALTER TABLE public.targetgroups OWNER TO verifadmin;


CREATE VIEW public.targetgroups_v AS
 SELECT l.id,
    l.name,
    lt.translation AS description,
    ll.code AS language_code
   FROM public.targetgroups l,
    public.localization_languages ll,
    public.localization_entries le,
    public.localization_translations lt
  WHERE ((l.description_id = le.id) AND (ll.id = lt.language_id) AND (lt.entry_id = le.id));


ALTER VIEW public.targetgroups_v OWNER TO verifadmin;


CREATE TABLE public.targets (
    id integer NOT NULL,
    type_id integer NOT NULL,
    modified_by text,
    modified_last timestamp with time zone
);


ALTER TABLE public.targets OWNER TO verifadmin;


CREATE VIEW public.targets_v AS
 SELECT l.fmisid AS target_id,
    tt.name AS target_type,
    ll.code AS language_code,
    lt.translation AS description
   FROM public.locations l,
    public.target_types tt,
    public.targets t,
    public.localization_entries le,
    public.localization_languages ll,
    public.localization_translations lt
  WHERE ((tt.id = t.type_id) AND (t.id = l.fmisid) AND (le.id = l.name_id) AND (le.id = lt.entry_id) AND (lt.language_id = ll.id))
UNION ALL
 SELECT g.id AS target_id,
    tt.name AS target_type,
    ll.code AS language_code,
    lt.translation AS description
   FROM public.targetgroups g,
    public.targets t,
    public.target_types tt,
    public.localization_entries le,
    public.localization_languages ll,
    public.localization_translations lt
  WHERE ((tt.id = t.type_id) AND (t.id = g.id) AND (le.id = g.description_id) AND (le.id = lt.entry_id) AND (lt.language_id = ll.id))
UNION ALL
 SELECT a.id AS target_id,
    tt.name AS target_type,
    ll.code AS language_code,
    lt.translation AS description
   FROM public.areas a,
    public.targets t,
    public.target_types tt,
    public.localization_entries le,
    public.localization_languages ll,
    public.localization_translations lt
  WHERE ((tt.id = t.type_id) AND (t.id = a.id) AND (le.id = a.description_id) AND (le.id = lt.entry_id) AND (lt.language_id = ll.id));


ALTER VIEW public.targets_v OWNER TO verifadmin;


CREATE TABLE public.temp_load (
    producer_id integer,
    analysis_time timestamp with time zone,
    target_id integer,
    parameter_id integer,
    forecaster_id integer,
    leadtime integer,
    value numeric
);


ALTER TABLE public.temp_load OWNER TO verifadmin;


CREATE TABLE public.tiesaa_hila_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT tiesaa_forecasts_producer_id_check CHECK ((producer_id = 21))
);


ALTER TABLE public.tiesaa_hila_forecasts OWNER TO verifadmin;


CREATE TABLE public.tiesaa_hila_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT tiesaa_results_producer_id_chk CHECK ((producer_id = 21))
);


ALTER TABLE public.tiesaa_hila_results OWNER TO verifadmin;


CREATE TABLE public.tiesaa_lentokentta_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT tiesaa_lentokentta_forecasts_producer_id_check CHECK ((producer_id = 34))
);


ALTER TABLE public.tiesaa_lentokentta_forecasts OWNER TO verifadmin;


CREATE TABLE public.tiesaa_lentokentta_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT tiesaa_lentokentta_results_producer_id_chk CHECK ((producer_id = 34))
);


ALTER TABLE public.tiesaa_lentokentta_results OWNER TO verifadmin;


CREATE TABLE public.tiesaa_piste_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT tiesaapiste_forecasts_producer_id_check CHECK ((producer_id = 22))
);


ALTER TABLE public.tiesaa_piste_forecasts OWNER TO verifadmin;


CREATE TABLE public.tiesaa_piste_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT tiesaapiste_results_producer_id_chk CHECK ((producer_id = 22))
);


ALTER TABLE public.tiesaa_piste_results OWNER TO verifadmin;


CREATE TABLE public.tiesaa_tiejakso_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT tiesaa_tiejakso_forecasts_producer_id_check CHECK ((producer_id = 41))
);


ALTER TABLE public.tiesaa_tiejakso_forecasts OWNER TO verifadmin;


CREATE TABLE public.tiesaa_tiejakso_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT tiesaa_tiejakso_results_producer_id_chk CHECK ((producer_id = 41))
);


ALTER TABLE public.tiesaa_tiejakso_results OWNER TO verifadmin;


CREATE TABLE public.ui_sort_order (
    entity_table character varying(63) NOT NULL,
    entity_id integer NOT NULL,
    sort_order integer NOT NULL,
    CONSTRAINT ui_sort_order_sort_order_check CHECK ((sort_order >= 1))
);


ALTER TABLE public.ui_sort_order OWNER TO verifadmin;


CREATE TABLE public.used_area_result_estimators (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    estimator_id integer NOT NULL
);


ALTER TABLE public.used_area_result_estimators OWNER TO verifadmin;


CREATE TABLE public.used_area_result_hours (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    leadtime integer NOT NULL
);


ALTER TABLE public.used_area_result_hours OWNER TO verifadmin;


CREATE TABLE public.used_area_result_targets (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    area_id integer NOT NULL
);


ALTER TABLE public.used_area_result_targets OWNER TO verifadmin;


CREATE TABLE public.used_group_result_estimators (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    estimator_id integer NOT NULL
);


ALTER TABLE public.used_group_result_estimators OWNER TO verifadmin;


CREATE TABLE public.used_group_result_hours (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    leadtime integer NOT NULL
);


ALTER TABLE public.used_group_result_hours OWNER TO verifadmin;


CREATE TABLE public.used_group_result_targets (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.used_group_result_targets OWNER TO verifadmin;


CREATE TABLE public.used_location_result_estimators (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    estimator_id integer NOT NULL
);


ALTER TABLE public.used_location_result_estimators OWNER TO verifadmin;


CREATE TABLE public.used_location_result_groups (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.used_location_result_groups OWNER TO verifadmin;


CREATE TABLE public.used_location_result_hours (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    leadtime integer NOT NULL
);


ALTER TABLE public.used_location_result_hours OWNER TO verifadmin;


CREATE TABLE public.used_location_result_targets (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL,
    location_id integer NOT NULL,
    location_kind_id smallint NOT NULL
);


ALTER TABLE public.used_location_result_targets OWNER TO verifadmin;


CREATE TABLE public.used_model_areas (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    area_id integer NOT NULL
);


ALTER TABLE public.used_model_areas OWNER TO verifadmin;


CREATE TABLE public.used_model_groups (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.used_model_groups OWNER TO verifadmin;


CREATE TABLE public.used_model_hours (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    leadtime integer NOT NULL
);


ALTER TABLE public.used_model_hours OWNER TO verifadmin;


CREATE TABLE public.used_model_locations (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    location_id integer NOT NULL,
    location_kind_id smallint NOT NULL
);


ALTER TABLE public.used_model_locations OWNER TO verifadmin;


CREATE TABLE public.used_zero_limit_results (
    producer_id integer NOT NULL,
    parameter_id integer NOT NULL,
    period_id integer NOT NULL
);


ALTER TABLE public.used_zero_limit_results OWNER TO verifadmin;


CREATE TABLE public.user_view_settings (
    user_name character varying(100) NOT NULL,
    settings text NOT NULL
);


ALTER TABLE public.user_view_settings OWNER TO verifadmin;


CREATE TABLE public.vire_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT vire_forecasts_producer_id_check CHECK ((producer_id = 49))
);


ALTER TABLE public.vire_forecasts OWNER TO verifadmin;


CREATE TABLE public.vire_preop_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT vire_preop_forecasts_producer_id_check CHECK ((producer_id = 48))
);


ALTER TABLE public.vire_preop_forecasts OWNER TO verifadmin;


CREATE TABLE public.vire_preop_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT vire_preop_results_producer_id_chk CHECK ((producer_id = 48))
);


ALTER TABLE public.vire_preop_results OWNER TO verifadmin;


CREATE TABLE public.vire_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT vire_results_producer_id_chk CHECK ((producer_id = 49))
);


ALTER TABLE public.vire_results OWNER TO verifadmin;


CREATE TABLE public.virenwc_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT virenwc_forecasts_producer_id_check CHECK ((producer_id = 57))
);


ALTER TABLE public.virenwc_forecasts OWNER TO verifadmin;


CREATE TABLE public.virenwc_preop_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT virenwc_preop_forecasts_producer_id_check CHECK ((producer_id = 58))
);


ALTER TABLE public.virenwc_preop_forecasts OWNER TO verifadmin;


CREATE TABLE public.virenwc_preop_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT virenwc_preop_results_producer_id_chk CHECK ((producer_id = 58))
);


ALTER TABLE public.virenwc_preop_results OWNER TO verifadmin;


CREATE TABLE public.virenwc_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT virenwc_results_producer_id_chk CHECK ((producer_id = 57))
);


ALTER TABLE public.virenwc_results OWNER TO verifadmin;


CREATE TABLE public.warning_levels (
    severity_id integer NOT NULL,
    severity_name character varying(20) NOT NULL,
    description_id integer,
    modified_by text,
    modified_last timestamp with time zone,
    severity_color character varying(20) NOT NULL
);


ALTER TABLE public.warning_levels OWNER TO verifadmin;


CREATE TABLE public.warning_rule_conditions (
    id integer NOT NULL,
    warning_rule_id integer NOT NULL,
    parameter_id integer NOT NULL,
    low_limit double precision,
    upper_limit double precision,
    low_inclusive boolean DEFAULT true NOT NULL,
    upper_inclusive boolean DEFAULT false NOT NULL,
    modified_by text,
    modified_last timestamp with time zone,
    CONSTRAINT warning_rule_conditions_at_least_one_limit_chk CHECK (((low_limit IS NOT NULL) OR (upper_limit IS NOT NULL))),
    CONSTRAINT warning_rule_conditions_limit_order_chk CHECK (((low_limit IS NULL) OR (upper_limit IS NULL) OR (low_limit <= upper_limit)))
);


ALTER TABLE public.warning_rule_conditions OWNER TO verifadmin;


ALTER TABLE public.warning_rule_conditions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.warning_rule_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE public.warning_rules (
    id integer NOT NULL,
    target_id integer NOT NULL,
    severity_id integer NOT NULL,
    valid_from_month smallint DEFAULT 1 NOT NULL,
    valid_from_day smallint DEFAULT 1 NOT NULL,
    valid_to_month smallint DEFAULT 12 NOT NULL,
    valid_to_day smallint DEFAULT 31 NOT NULL,
    description text,
    modified_by text,
    modified_last timestamp with time zone,
    CONSTRAINT warning_rules_from_day_chk CHECK (((valid_from_day >= 1) AND (valid_from_day <= 31))),
    CONSTRAINT warning_rules_from_month_chk CHECK (((valid_from_month >= 1) AND (valid_from_month <= 12))),
    CONSTRAINT warning_rules_to_day_chk CHECK (((valid_to_day >= 1) AND (valid_to_day <= 31))),
    CONSTRAINT warning_rules_to_month_chk CHECK (((valid_to_month >= 1) AND (valid_to_month <= 12)))
);


ALTER TABLE public.warning_rules OWNER TO verifadmin;


ALTER TABLE public.warning_rules ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.warning_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE public.wasp_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT wasp_forecasts_producer_id_check CHECK ((producer_id = 56))
);


ALTER TABLE public.wasp_forecasts OWNER TO verifadmin;


CREATE TABLE public.wasp_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT wasp_results_producer_id_chk CHECK ((producer_id = 56))
);


ALTER TABLE public.wasp_results OWNER TO verifadmin;


CREATE TABLE public.waveecmwf_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT waveecmwf_forecasts_producer_id_check CHECK ((producer_id = 37))
);


ALTER TABLE public.waveecmwf_forecasts OWNER TO verifadmin;


CREATE TABLE public.waveecmwf_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT waveecmwf_results_producer_id_chk CHECK ((producer_id = 37))
);


ALTER TABLE public.waveecmwf_results OWNER TO verifadmin;


CREATE TABLE public.wavefmiecmwf_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT wavefmiecmwf_forecasts_producer_id_check CHECK ((producer_id = 28))
);


ALTER TABLE public.wavefmiecmwf_forecasts OWNER TO verifadmin;


CREATE TABLE public.wavefmiecmwf_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT wavefmiecmwf_results_producer_id_chk CHECK ((producer_id = 28))
);


ALTER TABLE public.wavefmiecmwf_results OWNER TO verifadmin;


CREATE TABLE public.wavefmiharmonie_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT wavefmiharmonie_forecasts_producer_id_check CHECK ((producer_id = 36))
);


ALTER TABLE public.wavefmiharmonie_forecasts OWNER TO verifadmin;


CREATE TABLE public.wavefmiharmonie_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT wavefmiharmonie_results_producer_id_chk CHECK ((producer_id = 36))
);


ALTER TABLE public.wavefmiharmonie_results OWNER TO verifadmin;


CREATE TABLE public.wavefmihirlam_forecasts (
    producer_id integer NOT NULL,
    analysis_time timestamp with time zone NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    forecaster_id integer,
    leadtime integer NOT NULL,
    value numeric NOT NULL,
    CONSTRAINT wavefmihirlam_forecasts_producer_id_check CHECK ((producer_id = 29))
);


ALTER TABLE public.wavefmihirlam_forecasts OWNER TO verifadmin;


CREATE TABLE public.wavefmihirlam_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    forecaster_id integer DEFAULT '-1'::integer NOT NULL,
    leadtime integer NOT NULL,
    analysis_hour smallint NOT NULL,
    count_u integer,
    value_u numeric,
    count_a integer,
    value_a numeric,
    CONSTRAINT wavefmihirlam_results_producer_id_chk CHECK ((producer_id = 29))
);


ALTER TABLE public.wavefmihirlam_results OWNER TO verifadmin;


CREATE TABLE public.wind_correction_coefficients (
    id integer NOT NULL,
    set_id integer NOT NULL,
    angle integer NOT NULL,
    coefficient numeric(5,4) NOT NULL,
    is_enabled boolean DEFAULT false NOT NULL,
    CONSTRAINT wind_correction_coefficients_angle_chk CHECK (((angle > 0) AND (angle <= 360))),
    CONSTRAINT wind_correction_coefficients_positive_coefficient_chk CHECK ((coefficient > (0)::numeric))
);


ALTER TABLE public.wind_correction_coefficients OWNER TO verifadmin;


CREATE SEQUENCE public.wind_correction_coefficients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wind_correction_coefficients_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.wind_correction_coefficients_id_seq OWNED BY public.wind_correction_coefficients.id;



CREATE TABLE public.wind_correction_sets (
    id integer NOT NULL,
    target_id integer NOT NULL,
    sensor_no smallint DEFAULT 1 NOT NULL,
    valid_from timestamp with time zone NOT NULL,
    valid_to timestamp with time zone,
    area_id integer NOT NULL,
    secondary_area_id integer,
    tertiary_area_id integer,
    sensor_height_msl numeric,
    level_corr_coeff numeric,
    CONSTRAINT wind_correction_sets_positive_sensor_no_chk CHECK ((sensor_no >= 1)),
    CONSTRAINT wind_correction_sets_valid_from_less_than_valid_to_chk CHECK (((valid_to IS NULL) OR (valid_from < valid_to)))
);


ALTER TABLE public.wind_correction_sets OWNER TO verifadmin;


CREATE SEQUENCE public.wind_correction_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wind_correction_sets_id_seq OWNER TO verifadmin;


ALTER SEQUENCE public.wind_correction_sets_id_seq OWNED BY public.wind_correction_sets.id;



CREATE TABLE public.wind_roughness (
    fmisid integer NOT NULL,
    sensor_no smallint NOT NULL,
    sector integer NOT NULL,
    valid_from timestamp with time zone NOT NULL,
    valid_to timestamp with time zone NOT NULL,
    roughness numeric,
    CONSTRAINT wind_roughness_fmisid_check CHECK ((fmisid > 100000)),
    CONSTRAINT wind_roughness_positive_sensor_no_chk CHECK ((sensor_no >= 1)),
    CONSTRAINT wind_roughness_sector_chk CHECK (((sector > 0) AND (sector <= 360))),
    CONSTRAINT wind_roughness_valid_from_less_than_valid_to_chk CHECK ((valid_from < valid_to))
);


ALTER TABLE public.wind_roughness OWNER TO verifadmin;


CREATE TABLE public.wind_roughness_sea_validity (
    fmisid integer NOT NULL,
    sector integer NOT NULL,
    valid_from timestamp with time zone NOT NULL,
    valid_to timestamp with time zone NOT NULL,
    is_valid boolean DEFAULT false NOT NULL,
    CONSTRAINT wind_roughness_sea_validity_fmisid_check CHECK ((fmisid > 100000)),
    CONSTRAINT wind_roughness_sea_validity_sector_chk CHECK (((sector > 0) AND (sector <= 360))),
    CONSTRAINT wind_roughness_sea_validity_valid_from_less_than_valid_to_chk CHECK ((valid_from < valid_to))
);


ALTER TABLE public.wind_roughness_sea_validity OWNER TO verifadmin;


CREATE TABLE public.zero_limit_results (
    producer_id integer NOT NULL,
    period_id integer NOT NULL,
    target_id integer NOT NULL,
    parameter_id integer NOT NULL,
    estimator_id integer NOT NULL,
    analysis_hour smallint NOT NULL,
    leadtime integer NOT NULL,
    category character varying(5) NOT NULL,
    count_u integer NOT NULL,
    value_u numeric,
    count_a integer NOT NULL,
    value_a numeric
);


ALTER TABLE public.zero_limit_results OWNER TO verifadmin;


ALTER TABLE ONLY public.model_data ATTACH PARTITION public.adf_preop_forecasts FOR VALUES IN (55);



ALTER TABLE ONLY public.results ATTACH PARTITION public.adf_preop_results FOR VALUES IN (55);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.aifs_forecasts FOR VALUES IN (54);



ALTER TABLE ONLY public.results ATTACH PARTITION public.aifs_results FOR VALUES IN (54);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.aila_preop_forecasts FOR VALUES IN (53);



ALTER TABLE ONLY public.results ATTACH PARTITION public.aila_preop_results FOR VALUES IN (53);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.airport_forecasts FOR VALUES IN (23);



ALTER TABLE ONLY public.results ATTACH PARTITION public.airport_results FOR VALUES IN (23);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.apple_weather_forecasts FOR VALUES IN (46);



ALTER TABLE ONLY public.results ATTACH PARTITION public.apple_weather_results FOR VALUES IN (46);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.blend_forecasts FOR VALUES IN (12);



ALTER TABLE ONLY public.results ATTACH PARTITION public.blend_results FOR VALUES IN (12);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.bris_preop_forecasts FOR VALUES IN (50);



ALTER TABLE ONLY public.results ATTACH PARTITION public.bris_preop_results FOR VALUES IN (50);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.climcorecmwf_forecasts FOR VALUES IN (27);



ALTER TABLE ONLY public.results ATTACH PARTITION public.climcorecmwf_results FOR VALUES IN (27);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.climcorhirlam_forecasts FOR VALUES IN (24);



ALTER TABLE ONLY public.results ATTACH PARTITION public.climcorhirlam_results FOR VALUES IN (24);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.climcormeps_forecasts FOR VALUES IN (26);



ALTER TABLE ONLY public.results ATTACH PARTITION public.climcormeps_results FOR VALUES IN (26);



ALTER TABLE ONLY public.results ATTACH PARTITION public.copernicus_nemo_results FOR VALUES IN (42);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.dnncormeps_forecasts FOR VALUES IN (40);



ALTER TABLE ONLY public.results ATTACH PARTITION public.dnncormeps_results FOR VALUES IN (40);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.dwd_forecasts FOR VALUES IN (8);



ALTER TABLE ONLY public.results ATTACH PARTITION public.dwd_results FOR VALUES IN (8);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.ecmwf_forecasts FOR VALUES IN (2);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.ecmwf_probability_forecasts FOR VALUES IN (45);



ALTER TABLE ONLY public.results ATTACH PARTITION public.ecmwf_probability_results FOR VALUES IN (45);



ALTER TABLE ONLY public.results ATTACH PARTITION public.ecmwf_results FOR VALUES IN (2);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.gfs_forecasts FOR VALUES IN (14);



ALTER TABLE ONLY public.results ATTACH PARTITION public.gfs_results FOR VALUES IN (14);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.helsinki_forecasts FOR VALUES IN (18);



ALTER TABLE ONLY public.results ATTACH PARTITION public.helsinki_results FOR VALUES IN (18);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.hirlam_forecasts FOR VALUES IN (9);



ALTER TABLE ONLY public.results ATTACH PARTITION public.hirlam_results FOR VALUES IN (9);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.icon_forecasts FOR VALUES IN (13);



ALTER TABLE ONLY public.results ATTACH PARTITION public.icon_results FOR VALUES IN (13);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.kairosnwc_forecasts FOR VALUES IN (52);



ALTER TABLE ONLY public.results ATTACH PARTITION public.kairosnwc_results FOR VALUES IN (52);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.laps_forecasts FOR VALUES IN (35);



ALTER TABLE ONLY public.results ATTACH PARTITION public.laps_results FOR VALUES IN (35);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.maisemakalmec_forecasts FOR VALUES IN (31);



ALTER TABLE ONLY public.results ATTACH PARTITION public.maisemakalmec_results FOR VALUES IN (31);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.maisemasmartmet_forecasts FOR VALUES IN (30);



ALTER TABLE ONLY public.results ATTACH PARTITION public.maisemasmartmet_results FOR VALUES IN (30);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.meps_forecasts FOR VALUES IN (10);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.meps_ml_preop_forecasts FOR VALUES IN (47);



ALTER TABLE ONLY public.results ATTACH PARTITION public.meps_ml_preop_results FOR VALUES IN (47);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.meps_probability_forecasts FOR VALUES IN (44);



ALTER TABLE ONLY public.results ATTACH PARTITION public.meps_probability_results FOR VALUES IN (44);



ALTER TABLE ONLY public.results ATTACH PARTITION public.meps_results FOR VALUES IN (10);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.met_no_forecasts FOR VALUES IN (6);



ALTER TABLE ONLY public.results ATTACH PARTITION public.met_no_results FOR VALUES IN (6);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.metcoopnwc_forecasts FOR VALUES IN (17);



ALTER TABLE ONLY public.results ATTACH PARTITION public.metcoopnwc_results FOR VALUES IN (17);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.mos_development_forecasts FOR VALUES IN (15);



ALTER TABLE ONLY public.results ATTACH PARTITION public.mos_development_results FOR VALUES IN (15);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.mosecmkriging_forecasts FOR VALUES IN (11);



ALTER TABLE ONLY public.results ATTACH PARTITION public.mosecmkriging_results FOR VALUES IN (11);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.nemo_mw_forecasts FOR VALUES IN (38);



ALTER TABLE ONLY public.results ATTACH PARTITION public.nemo_mw_results FOR VALUES IN (38);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.nemo_n2000_forecasts FOR VALUES IN (39);



ALTER TABLE ONLY public.results ATTACH PARTITION public.nemo_n2000_results FOR VALUES IN (39);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.oaasecmwf_forecasts FOR VALUES IN (20);



ALTER TABLE ONLY public.results ATTACH PARTITION public.oaasecmwf_results FOR VALUES IN (20);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.oaashirlam_forecasts FOR VALUES IN (19);



ALTER TABLE ONLY public.results ATTACH PARTITION public.oaashirlam_results FOR VALUES IN (19);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.observation_endwind_forecasts FOR VALUES IN (59);



ALTER TABLE ONLY public.results ATTACH PARTITION public.observation_endwind_results FOR VALUES IN (59);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.observation_forecasts FOR VALUES IN (51);



ALTER TABLE ONLY public.results ATTACH PARTITION public.observation_results FOR VALUES IN (51);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.pangu_weather_forecasts FOR VALUES IN (33);



ALTER TABLE ONLY public.results ATTACH PARTITION public.pangu_weather_results FOR VALUES IN (33);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.peps_forecasts FOR VALUES IN (5);



ALTER TABLE ONLY public.results ATTACH PARTITION public.peps_results FOR VALUES IN (5);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.smartmet_forecasts FOR VALUES IN (1);



ALTER TABLE ONLY public.results ATTACH PARTITION public.smartmet_results FOR VALUES IN (1);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.smartmetnwc_forecasts FOR VALUES IN (16);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.smartmetnwc_preop_forecasts FOR VALUES IN (32);



ALTER TABLE ONLY public.results ATTACH PARTITION public.smartmetnwc_preop_results FOR VALUES IN (32);



ALTER TABLE ONLY public.results ATTACH PARTITION public.smartmetnwc_results FOR VALUES IN (16);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.smhi_forecasts FOR VALUES IN (7);



ALTER TABLE ONLY public.results ATTACH PARTITION public.smhi_results FOR VALUES IN (7);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.tiesaa_hila_forecasts FOR VALUES IN (21);



ALTER TABLE ONLY public.results ATTACH PARTITION public.tiesaa_hila_results FOR VALUES IN (21);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.tiesaa_lentokentta_forecasts FOR VALUES IN (34);



ALTER TABLE ONLY public.results ATTACH PARTITION public.tiesaa_lentokentta_results FOR VALUES IN (34);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.tiesaa_piste_forecasts FOR VALUES IN (22);



ALTER TABLE ONLY public.results ATTACH PARTITION public.tiesaa_piste_results FOR VALUES IN (22);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.tiesaa_tiejakso_forecasts FOR VALUES IN (41);



ALTER TABLE ONLY public.results ATTACH PARTITION public.tiesaa_tiejakso_results FOR VALUES IN (41);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.vire_forecasts FOR VALUES IN (49);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.vire_preop_forecasts FOR VALUES IN (48);



ALTER TABLE ONLY public.results ATTACH PARTITION public.vire_preop_results FOR VALUES IN (48);



ALTER TABLE ONLY public.results ATTACH PARTITION public.vire_results FOR VALUES IN (49);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.virenwc_forecasts FOR VALUES IN (57);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.virenwc_preop_forecasts FOR VALUES IN (58);



ALTER TABLE ONLY public.results ATTACH PARTITION public.virenwc_preop_results FOR VALUES IN (58);



ALTER TABLE ONLY public.results ATTACH PARTITION public.virenwc_results FOR VALUES IN (57);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.wasp_forecasts FOR VALUES IN (56);



ALTER TABLE ONLY public.results ATTACH PARTITION public.wasp_results FOR VALUES IN (56);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.waveecmwf_forecasts FOR VALUES IN (37);



ALTER TABLE ONLY public.results ATTACH PARTITION public.waveecmwf_results FOR VALUES IN (37);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.wavefmiecmwf_forecasts FOR VALUES IN (28);



ALTER TABLE ONLY public.results ATTACH PARTITION public.wavefmiecmwf_results FOR VALUES IN (28);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.wavefmiharmonie_forecasts FOR VALUES IN (36);



ALTER TABLE ONLY public.results ATTACH PARTITION public.wavefmiharmonie_results FOR VALUES IN (36);



ALTER TABLE ONLY public.model_data ATTACH PARTITION public.wavefmihirlam_forecasts FOR VALUES IN (29);



ALTER TABLE ONLY public.results ATTACH PARTITION public.wavefmihirlam_results FOR VALUES IN (29);



ALTER TABLE ONLY public.climatology_orders ALTER COLUMN id SET DEFAULT nextval('public.climatology_orders_id_seq'::regclass);



ALTER TABLE ONLY public.estimators ALTER COLUMN id SET DEFAULT nextval('public.estimators_id_seq'::regclass);



ALTER TABLE ONLY public.forecaster_privileges ALTER COLUMN id SET DEFAULT nextval('public.forecaster_privileges_id_seq'::regclass);



ALTER TABLE ONLY public.localization_entries ALTER COLUMN id SET DEFAULT nextval('public.localization_entries_id_seq'::regclass);



ALTER TABLE ONLY public.localization_languages ALTER COLUMN id SET DEFAULT nextval('public.localization_languages_id_seq'::regclass);



ALTER TABLE ONLY public.location_kinds ALTER COLUMN id SET DEFAULT nextval('public.location_kinds_id_seq'::regclass);



ALTER TABLE ONLY public.network_map ALTER COLUMN id SET DEFAULT nextval('public.network_map_id_seq'::regclass);



ALTER TABLE ONLY public.networks ALTER COLUMN id SET DEFAULT nextval('public.networks_id_seq'::regclass);



ALTER TABLE ONLY public.parameter_map ALTER COLUMN id SET DEFAULT nextval('public.parameter_map_id_seq'::regclass);



ALTER TABLE ONLY public.parameters ALTER COLUMN id SET DEFAULT nextval('public.parameters_id_seq'::regclass);



ALTER TABLE ONLY public.period_types ALTER COLUMN id SET DEFAULT nextval('public.period_types_id_seq'::regclass);



ALTER TABLE ONLY public.periods ALTER COLUMN id SET DEFAULT nextval('public.periods_id_seq'::regclass);



ALTER TABLE ONLY public.result_orders ALTER COLUMN id SET DEFAULT nextval('public.result_orders_id_seq'::regclass);



ALTER TABLE ONLY public.target_types ALTER COLUMN id SET DEFAULT nextval('public.target_types_id_seq'::regclass);



ALTER TABLE ONLY public.wind_correction_coefficients ALTER COLUMN id SET DEFAULT nextval('public.wind_correction_coefficients_id_seq'::regclass);



ALTER TABLE ONLY public.wind_correction_sets ALTER COLUMN id SET DEFAULT nextval('public.wind_correction_sets_id_seq'::regclass);



ALTER TABLE ONLY public.model_data
    ADD CONSTRAINT model_data_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.adf_preop_forecasts
    ADD CONSTRAINT adf_preop_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.adf_preop_results
    ADD CONSTRAINT adf_preop_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.aifs_forecasts
    ADD CONSTRAINT aifs_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.aifs_results
    ADD CONSTRAINT aifs_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.aila_preop_forecasts
    ADD CONSTRAINT aila_preop_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.aila_preop_results
    ADD CONSTRAINT aila_preop_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.airport_forecast_view_settings
    ADD CONSTRAINT airport_forecast_view_settings_pkey PRIMARY KEY (producer_id, location_id_view, parameter_id_view, estimator_id);



ALTER TABLE ONLY public.airport_forecasts
    ADD CONSTRAINT airport_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.airport_raw_results
    ADD CONSTRAINT airport_raw_results_pkey PRIMARY KEY (period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.airport_results
    ADD CONSTRAINT airport_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.apple_weather_forecasts
    ADD CONSTRAINT apple_weather_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.apple_weather_results
    ADD CONSTRAINT apple_weather_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.available_observations
    ADD CONSTRAINT available_observations_pkey PRIMARY KEY (target_id, parameter_id);



ALTER TABLE ONLY public.base_result_orders
    ADD CONSTRAINT base_result_orders_pkey PRIMARY KEY (producer_id, target_id, parameter_id, estimator_id, period_type_id, forecaster_id);



ALTER TABLE ONLY public.blend_forecasts
    ADD CONSTRAINT blend_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.blend_results
    ADD CONSTRAINT blend_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.bris_preop_forecasts
    ADD CONSTRAINT bris_preop_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.bris_preop_results
    ADD CONSTRAINT bris_preop_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.climatology_orders
    ADD CONSTRAINT climatology_orders_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.climatology
    ADD CONSTRAINT climatology_pkey PRIMARY KEY (target_id, parameter_id, clim_time, statistic_name);



ALTER TABLE ONLY public.climcorecmwf_forecasts
    ADD CONSTRAINT climcorecmwf_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.climcorecmwf_results
    ADD CONSTRAINT climcorecmwf_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.climcorhirlam_forecasts
    ADD CONSTRAINT climcorhirlam_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.climcorhirlam_results
    ADD CONSTRAINT climcorhirlam_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.climcormeps_forecasts
    ADD CONSTRAINT climcormeps_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.climcormeps_results
    ADD CONSTRAINT climcormeps_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.copernicus_nemo_results
    ADD CONSTRAINT copernicus_nemo_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.derivative_estimators
    ADD CONSTRAINT derivative_estimators_class_limits_pkey PRIMARY KEY (parameter_id, estimator_id, leadtime, analysis_hour, weighted_average, base_id);



ALTER TABLE ONLY public.derivative_rvm
    ADD CONSTRAINT derivative_rvm_class_limits_pkey PRIMARY KEY (parameter_id, estimator_id);



ALTER TABLE ONLY public.dnncormeps_forecasts
    ADD CONSTRAINT dnncormeps_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.dnncormeps_results
    ADD CONSTRAINT dnncormeps_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.dwd_forecasts
    ADD CONSTRAINT dwd_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.dwd_results
    ADD CONSTRAINT dwd_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.ecmwf_forecasts
    ADD CONSTRAINT ecmwf_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.ecmwf_probability_forecasts
    ADD CONSTRAINT ecmwf_probability_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.ecmwf_probability_results
    ADD CONSTRAINT ecmwf_probability_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.ecmwf_results
    ADD CONSTRAINT ecmwf_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.ecmwfeps_forecasts
    ADD CONSTRAINT ecmwfeps_forecasts_pkey PRIMARY KEY (analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.ecmwfeps_results
    ADD CONSTRAINT ecmwfeps_results_pkey PRIMARY KEY (period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.estimators
    ADD CONSTRAINT estimators_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.forecaster_privileges
    ADD CONSTRAINT forecaster_privileges_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.forecasters
    ADD CONSTRAINT forecasters_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.forecasts
    ADD CONSTRAINT forecasts_pkey PRIMARY KEY (producer_id, analysis_time);



ALTER TABLE ONLY public.gfs_forecasts
    ADD CONSTRAINT gfs_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.gfs_results
    ADD CONSTRAINT gfs_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.grade_colors
    ADD CONSTRAINT grade_colors_pkey PRIMARY KEY (parameter_id, estimator_id);



ALTER TABLE ONLY public.harmonie_forecasts
    ADD CONSTRAINT harmonie_forecasts_pkey PRIMARY KEY (analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.harmonie_results
    ADD CONSTRAINT harmonie_results_pkey PRIMARY KEY (period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.helsinki_forecasts
    ADD CONSTRAINT helsinki_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.helsinki_results
    ADD CONSTRAINT helsinki_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.hirlam_forecasts
    ADD CONSTRAINT hirlam_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.hirlam_results
    ADD CONSTRAINT hirlam_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.icao_stations
    ADD CONSTRAINT icao_stations_pkey PRIMARY KEY (fmisid);



ALTER TABLE ONLY public.icon_forecasts
    ADD CONSTRAINT icon_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.icon_results
    ADD CONSTRAINT icon_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.kairosnwc_forecasts
    ADD CONSTRAINT kairosnwc_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.kairosnwc_results
    ADD CONSTRAINT kairosnwc_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.laps_forecasts
    ADD CONSTRAINT laps_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.laps_results
    ADD CONSTRAINT laps_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.localization_entries
    ADD CONSTRAINT localization_entries_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.localization_languages
    ADD CONSTRAINT localization_languages_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.localization_translations
    ADD CONSTRAINT localization_translations_pkey PRIMARY KEY (entry_id, language_id);



ALTER TABLE ONLY public.location_kinds
    ADD CONSTRAINT location_kinds_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.maisemakalmec_forecasts
    ADD CONSTRAINT maisemakalmec_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.maisemakalmec_results
    ADD CONSTRAINT maisemakalmec_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.maisemasmartmet_forecasts
    ADD CONSTRAINT maisemasmartmet_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.maisemasmartmet_results
    ADD CONSTRAINT maisemasmartmet_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.meps_forecasts
    ADD CONSTRAINT meps_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.meps_ml_preop_forecasts
    ADD CONSTRAINT meps_ml_preop_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.meps_ml_preop_results
    ADD CONSTRAINT meps_ml_preop_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.meps_probability_forecasts
    ADD CONSTRAINT meps_probability_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.meps_probability_results
    ADD CONSTRAINT meps_probability_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.meps_results
    ADD CONSTRAINT meps_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.met_no_forecasts
    ADD CONSTRAINT met_no_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.met_no_results
    ADD CONSTRAINT met_no_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.metcoopnwc_forecasts
    ADD CONSTRAINT metcoopnwc_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.metcoopnwc_results
    ADD CONSTRAINT metcoopnwc_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.model_parameter_views
    ADD CONSTRAINT model_parameter_views_pkey PRIMARY KEY (parameter_id);



ALTER TABLE ONLY public.mos_development_forecasts
    ADD CONSTRAINT mos_development_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.mos_development_results
    ADD CONSTRAINT mos_development_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.mos_production_forecasts
    ADD CONSTRAINT mos_production_forecasts_pkey PRIMARY KEY (analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.mos_production_results
    ADD CONSTRAINT mos_production_results_pkey PRIMARY KEY (period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.moseckrigingx_forecasts
    ADD CONSTRAINT moseckrigingx_forecasts_pkey PRIMARY KEY (analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.moseckrigingx_results
    ADD CONSTRAINT moseckrigingx_results_pkey PRIMARY KEY (period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.mosecmkriging_forecasts
    ADD CONSTRAINT mosecmkriging_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.mosecmkriging_results
    ADD CONSTRAINT mosecmkriging_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.nemo_mw_forecasts
    ADD CONSTRAINT nemo_mw_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.nemo_mw_results
    ADD CONSTRAINT nemo_mw_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.nemo_n2000_forecasts
    ADD CONSTRAINT nemo_n2000_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.nemo_n2000_results
    ADD CONSTRAINT nemo_n2000_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.network_map
    ADD CONSTRAINT network_map_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.networks
    ADD CONSTRAINT networks_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.oaasecmwf_forecasts
    ADD CONSTRAINT oaasecmwf_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.oaasecmwf_results
    ADD CONSTRAINT oaasecmwf_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.oaashirlam_forecasts
    ADD CONSTRAINT oaashirlam_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.oaashirlam_results
    ADD CONSTRAINT oaashirlam_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.observation_endwind_forecasts
    ADD CONSTRAINT observation_endwind_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.observation_endwind_results
    ADD CONSTRAINT observation_endwind_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.observation_forecasts
    ADD CONSTRAINT observation_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.observation_results
    ADD CONSTRAINT observation_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.pangu_weather_forecasts
    ADD CONSTRAINT pangu_weather_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.pangu_weather_results
    ADD CONSTRAINT pangu_weather_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.parameter_class_limits
    ADD CONSTRAINT parameter_class_limits_pkey PRIMARY KEY (base_parameter_id, class_no);



ALTER TABLE ONLY public.parameter_map
    ADD CONSTRAINT parameter_map_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.peps_forecasts
    ADD CONSTRAINT peps_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.peps_results
    ADD CONSTRAINT peps_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.period_types
    ADD CONSTRAINT period_types_name_key UNIQUE (name);



ALTER TABLE ONLY public.period_types
    ADD CONSTRAINT period_types_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.producers
    ADD CONSTRAINT producers_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.result_orders
    ADD CONSTRAINT result_orders_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.result_parameter_views
    ADD CONSTRAINT result_parameter_views_pkey PRIMARY KEY (parameter_id);



ALTER TABLE ONLY public.road_sections
    ADD CONSTRAINT road_sections_pkey PRIMARY KEY (section_id);



ALTER TABLE ONLY public.sea_level_warning_limits
    ADD CONSTRAINT sea_level_warning_limits_pkey PRIMARY KEY (location_id, area_id, base_parameter_id, parameter_id);



ALTER TABLE ONLY public.smartmet_forecasts
    ADD CONSTRAINT smartmet_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.smartmet_results
    ADD CONSTRAINT smartmet_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.smartmetnwc_forecasts
    ADD CONSTRAINT smartmetnwc_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.smartmetnwc_preop_forecasts
    ADD CONSTRAINT smartmetnwc_preop_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.smartmetnwc_preop_results
    ADD CONSTRAINT smartmetnwc_preop_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.smartmetnwc_results
    ADD CONSTRAINT smartmetnwc_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.smhi_forecasts
    ADD CONSTRAINT smhi_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.smhi_results
    ADD CONSTRAINT smhi_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.special_observations
    ADD CONSTRAINT special_observations_pkey PRIMARY KEY (target_id, parameter_id, obs_time);



ALTER TABLE ONLY public.locations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (fmisid);



ALTER TABLE ONLY public.target_level_results
    ADD CONSTRAINT target_level_results_pkey PRIMARY KEY (year, target_id, parameter_id, estimator_id, leadtime);



ALTER TABLE ONLY public.target_types
    ADD CONSTRAINT target_types_name_uniq_idx UNIQUE (name);



ALTER TABLE ONLY public.target_types
    ADD CONSTRAINT target_types_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.targetgroup_map
    ADD CONSTRAINT targetgroup_map_pkey PRIMARY KEY (group_id, target_id);



ALTER TABLE ONLY public.targetgroups
    ADD CONSTRAINT targetgroups_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.tiesaa_hila_forecasts
    ADD CONSTRAINT tiesaa_hila_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.tiesaa_hila_results
    ADD CONSTRAINT tiesaa_hila_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.tiesaa_lentokentta_forecasts
    ADD CONSTRAINT tiesaa_lentokentta_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.tiesaa_lentokentta_results
    ADD CONSTRAINT tiesaa_lentokentta_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.tiesaa_piste_forecasts
    ADD CONSTRAINT tiesaa_piste_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.tiesaa_piste_results
    ADD CONSTRAINT tiesaa_piste_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.tiesaa_tiejakso_forecasts
    ADD CONSTRAINT tiesaa_tiejakso_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.tiesaa_tiejakso_results
    ADD CONSTRAINT tiesaa_tiejakso_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.ui_sort_order
    ADD CONSTRAINT ui_sort_order_pkey PRIMARY KEY (entity_table, entity_id);



ALTER TABLE ONLY public.used_area_result_estimators
    ADD CONSTRAINT used_area_result_estimators_pkey PRIMARY KEY (producer_id, parameter_id, period_id, analysis_hour, estimator_id);



ALTER TABLE ONLY public.used_area_result_hours
    ADD CONSTRAINT used_area_result_hours_pkey PRIMARY KEY (producer_id, parameter_id, period_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.used_area_result_targets
    ADD CONSTRAINT used_area_result_targets_pkey PRIMARY KEY (producer_id, parameter_id, period_id, area_id);



ALTER TABLE ONLY public.used_group_result_estimators
    ADD CONSTRAINT used_group_result_estimators_pkey PRIMARY KEY (producer_id, parameter_id, period_id, analysis_hour, estimator_id);



ALTER TABLE ONLY public.used_group_result_hours
    ADD CONSTRAINT used_group_result_hours_pkey PRIMARY KEY (producer_id, parameter_id, period_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.used_group_result_targets
    ADD CONSTRAINT used_group_result_targets_pkey PRIMARY KEY (producer_id, parameter_id, period_id, group_id);



ALTER TABLE ONLY public.used_location_result_estimators
    ADD CONSTRAINT used_location_result_estimators_pkey PRIMARY KEY (producer_id, parameter_id, period_id, analysis_hour, estimator_id);



ALTER TABLE ONLY public.used_location_result_groups
    ADD CONSTRAINT used_location_result_groups_pkey PRIMARY KEY (producer_id, parameter_id, period_id, group_id);



ALTER TABLE ONLY public.used_location_result_hours
    ADD CONSTRAINT used_location_result_hours_pkey PRIMARY KEY (producer_id, parameter_id, period_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.used_location_result_targets
    ADD CONSTRAINT used_location_result_targets_pkey PRIMARY KEY (producer_id, parameter_id, period_id, location_id);



ALTER TABLE ONLY public.used_model_areas
    ADD CONSTRAINT used_model_areas_pkey PRIMARY KEY (producer_id, parameter_id, area_id);



ALTER TABLE ONLY public.used_model_groups
    ADD CONSTRAINT used_model_groups_pkey PRIMARY KEY (producer_id, parameter_id, group_id);



ALTER TABLE ONLY public.used_model_hours
    ADD CONSTRAINT used_model_hours_pkey PRIMARY KEY (producer_id, parameter_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.used_model_locations
    ADD CONSTRAINT used_model_locations_pkey PRIMARY KEY (producer_id, parameter_id, location_id);



ALTER TABLE ONLY public.used_zero_limit_results
    ADD CONSTRAINT used_zero_limit_results_pkey PRIMARY KEY (producer_id, parameter_id, period_id);



ALTER TABLE ONLY public.user_view_settings
    ADD CONSTRAINT user_view_settings_pkey PRIMARY KEY (user_name);



ALTER TABLE ONLY public.vire_forecasts
    ADD CONSTRAINT vire_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.vire_preop_forecasts
    ADD CONSTRAINT vire_preop_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.vire_preop_results
    ADD CONSTRAINT vire_preop_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.vire_results
    ADD CONSTRAINT vire_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.virenwc_forecasts
    ADD CONSTRAINT virenwc_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.virenwc_preop_forecasts
    ADD CONSTRAINT virenwc_preop_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.virenwc_preop_results
    ADD CONSTRAINT virenwc_preop_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.virenwc_results
    ADD CONSTRAINT virenwc_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.warning_levels
    ADD CONSTRAINT warning_levels_pkey PRIMARY KEY (severity_id);



ALTER TABLE ONLY public.warning_rule_conditions
    ADD CONSTRAINT warning_rule_conditions_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.warning_rule_conditions
    ADD CONSTRAINT warning_rule_conditions_unique_condition UNIQUE (warning_rule_id, parameter_id, low_limit, upper_limit, low_inclusive, upper_inclusive);



ALTER TABLE ONLY public.warning_rules
    ADD CONSTRAINT warning_rules_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.warning_rules
    ADD CONSTRAINT warning_rules_unique_rule UNIQUE (target_id, severity_id, valid_from_month, valid_from_day, valid_to_month, valid_to_day);



ALTER TABLE ONLY public.wasp_forecasts
    ADD CONSTRAINT wasp_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.wasp_results
    ADD CONSTRAINT wasp_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.waveecmwf_forecasts
    ADD CONSTRAINT waveecmwf_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.waveecmwf_results
    ADD CONSTRAINT waveecmwf_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.wavefmiecmwf_forecasts
    ADD CONSTRAINT wavefmiecmwf_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.wavefmiecmwf_results
    ADD CONSTRAINT wavefmiecmwf_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.wavefmiharmonie_forecasts
    ADD CONSTRAINT wavefmiharmonie_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.wavefmiharmonie_results
    ADD CONSTRAINT wavefmiharmonie_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.wavefmihirlam_forecasts
    ADD CONSTRAINT wavefmihirlam_forecasts_pkey PRIMARY KEY (producer_id, analysis_time, target_id, parameter_id, leadtime);



ALTER TABLE ONLY public.wavefmihirlam_results
    ADD CONSTRAINT wavefmihirlam_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id, analysis_hour, leadtime);



ALTER TABLE ONLY public.wind_correction_coefficients
    ADD CONSTRAINT wind_correction_coefficients_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.wind_correction_sets
    ADD CONSTRAINT wind_correction_sets_pkey PRIMARY KEY (id);



ALTER TABLE ONLY public.zero_limit_results
    ADD CONSTRAINT zero_limit_results_pkey PRIMARY KEY (producer_id, period_id, target_id, parameter_id, estimator_id, analysis_hour, leadtime, category);



CREATE UNIQUE INDEX areas_name_uniq_idx ON public.areas USING btree (name);



CREATE UNIQUE INDEX climatology_orders_pptpef_uniq_idx ON public.climatology_orders USING btree (target_id, parameter_id, statistic_name);



CREATE UNIQUE INDEX estimators_name_uniq_idx ON public.estimators USING btree (name);



CREATE UNIQUE INDEX forecaster_privileges_forecaster_watcher_uniq_idx ON public.forecaster_privileges USING btree (forecaster_id, watcher_id);



CREATE UNIQUE INDEX forecasters_username_uniq_idx ON public.forecasters USING btree (username);



CREATE UNIQUE INDEX localization_entries_table_column_uniq_idx ON public.localization_entries USING btree (tablename, columnname, entity_id);



CREATE UNIQUE INDEX location_kinds_name_uniq_idx ON public.location_kinds USING btree (name);



CREATE UNIQUE INDEX network_map_network_station_uniq_idx ON public.network_map USING btree (network_id, target_id);



CREATE UNIQUE INDEX networks_name_uniq_idx ON public.networks USING btree (name);



CREATE UNIQUE INDEX parameter_map_parameter_id_category_uniq_idx ON public.parameter_map USING btree (parameter_id, category);



CREATE UNIQUE INDEX parameters_name_uniq_idx ON public.parameters USING btree (name);



CREATE UNIQUE INDEX period_types_name_uniq_idx ON public.period_types USING btree (name);



CREATE UNIQUE INDEX periods_pse_uniq_idx ON public.periods USING btree (type, start_date, end_date);



CREATE UNIQUE INDEX producers_name_uniq_idx ON public.producers USING btree (name);



CREATE UNIQUE INDEX result_orders_pptpef_uniq_idx ON public.result_orders USING btree (producer_id, period_id, target_id, parameter_id, estimator_id, forecaster_id);



CREATE UNIQUE INDEX targetgroups_name_uniq_idx ON public.targetgroups USING btree (name);



CREATE UNIQUE INDEX ui_sort_order_ts_uniq_idx ON public.ui_sort_order USING btree (entity_table, sort_order);



CREATE UNIQUE INDEX warning_levels_severity_color_uniq_idx ON public.warning_levels USING btree (severity_color);



CREATE UNIQUE INDEX warning_levels_severity_name_uniq_idx ON public.warning_levels USING btree (severity_name);



CREATE UNIQUE INDEX wind_correction_coefficients_ss_uniq_idx ON public.wind_correction_coefficients USING btree (set_id, angle);



CREATE UNIQUE INDEX wind_correction_sets_tsv_uniq_idx ON public.wind_correction_sets USING btree (target_id, sensor_no, valid_to);



CREATE UNIQUE INDEX wind_roughness_fssvv_uniq_idx ON public.wind_roughness USING btree (fmisid, sensor_no, sector, valid_from, valid_to);



CREATE UNIQUE INDEX wind_roughness_sea_validity_fsvv_uniq_idx ON public.wind_roughness_sea_validity USING btree (fmisid, sector, valid_from, valid_to);



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.adf_preop_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.adf_preop_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.aifs_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.aifs_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.aila_preop_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.aila_preop_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.airport_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.airport_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.apple_weather_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.apple_weather_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.blend_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.blend_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.bris_preop_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.bris_preop_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.climcorecmwf_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.climcorecmwf_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.climcorhirlam_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.climcorhirlam_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.climcormeps_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.climcormeps_results_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.copernicus_nemo_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.dnncormeps_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.dnncormeps_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.dwd_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.dwd_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.ecmwf_forecasts_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.ecmwf_probability_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.ecmwf_probability_results_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.ecmwf_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.gfs_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.gfs_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.helsinki_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.helsinki_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.hirlam_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.hirlam_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.icon_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.icon_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.kairosnwc_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.kairosnwc_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.laps_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.laps_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.maisemakalmec_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.maisemakalmec_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.maisemasmartmet_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.maisemasmartmet_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.meps_forecasts_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.meps_ml_preop_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.meps_ml_preop_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.meps_probability_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.meps_probability_results_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.meps_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.met_no_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.met_no_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.metcoopnwc_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.metcoopnwc_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.mos_development_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.mos_development_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.mosecmkriging_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.mosecmkriging_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.nemo_mw_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.nemo_mw_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.nemo_n2000_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.nemo_n2000_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.oaasecmwf_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.oaasecmwf_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.oaashirlam_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.oaashirlam_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.observation_endwind_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.observation_endwind_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.observation_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.observation_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.pangu_weather_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.pangu_weather_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.peps_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.peps_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.smartmet_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.smartmet_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.smartmetnwc_forecasts_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.smartmetnwc_preop_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.smartmetnwc_preop_results_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.smartmetnwc_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.smhi_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.smhi_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.tiesaa_hila_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.tiesaa_hila_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.tiesaa_lentokentta_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.tiesaa_lentokentta_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.tiesaa_piste_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.tiesaa_piste_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.tiesaa_tiejakso_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.tiesaa_tiejakso_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.vire_forecasts_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.vire_preop_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.vire_preop_results_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.vire_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.virenwc_forecasts_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.virenwc_preop_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.virenwc_preop_results_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.virenwc_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.wasp_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.wasp_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.waveecmwf_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.waveecmwf_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.wavefmiecmwf_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.wavefmiecmwf_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.wavefmiharmonie_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.wavefmiharmonie_results_pkey;



ALTER INDEX public.model_data_pkey ATTACH PARTITION public.wavefmihirlam_forecasts_pkey;



ALTER INDEX public.results_pkey ATTACH PARTITION public.wavefmihirlam_results_pkey;



CREATE TRIGGER areas_modified_last_trg BEFORE UPDATE ON public.areas FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER available_observations_modified_last_trg BEFORE UPDATE ON public.available_observations FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER estimators_modified_last_trg BEFORE UPDATE ON public.estimators FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER forecaster_privileges_modified_last_trg BEFORE UPDATE ON public.forecaster_privileges FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER forecasters_modified_last_trg BEFORE UPDATE ON public.forecasters FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER forecasts_id_seq_trg BEFORE INSERT ON public.forecasts FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER icao_stations_modified_last_trg BEFORE UPDATE ON public.icao_stations FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER localization_entries_modified_last_trg BEFORE UPDATE ON public.localization_entries FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER localization_languages_modified_last_trg BEFORE UPDATE ON public.localization_languages FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER location_kinds_modified_last_trg BEFORE UPDATE ON public.location_kinds FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER locations_modified_last_trg BEFORE UPDATE ON public.locations FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER network_map_modified_last_trg BEFORE UPDATE ON public.network_map FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER networks_modified_last_trg BEFORE UPDATE ON public.networks FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER parameter_map_modified_last_trg BEFORE UPDATE ON public.parameter_map FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER parameters_modified_last_trg BEFORE UPDATE ON public.parameters FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER period_types_modified_last_trg BEFORE UPDATE ON public.period_types FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER periods_modified_last_trg BEFORE UPDATE ON public.periods FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER producers_modified_last_trg BEFORE UPDATE ON public.producers FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER target_types_modified_last_trg BEFORE UPDATE ON public.target_types FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER targetgroup_map_modified_last_trg BEFORE UPDATE ON public.targetgroup_map FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER targetgroups_modified_last_trg BEFORE UPDATE ON public.targetgroups FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER targets_modified_last_trg BEFORE UPDATE ON public.targets FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER warning_levels_modified_last_trg BEFORE UPDATE ON public.warning_levels FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER warning_rule_conditions_modified_last_trg BEFORE UPDATE ON public.warning_rule_conditions FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



CREATE TRIGGER warning_rules_modified_last_trg BEFORE UPDATE ON public.warning_rules FOR EACH ROW EXECUTE FUNCTION public.store_last_modified_f();



ALTER TABLE ONLY public.airport_forecast_view_settings
    ADD CONSTRAINT airport_forecast_view_settings_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.airport_forecast_view_settings
    ADD CONSTRAINT airport_forecast_view_settings_parameter_data_id_fkey FOREIGN KEY (parameter_id_data) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.airport_forecast_view_settings
    ADD CONSTRAINT airport_forecast_view_settings_parameter_view__id_fkey FOREIGN KEY (parameter_id_view) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.airport_forecast_view_settings
    ADD CONSTRAINT airport_forecast_view_settings_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.airport_raw_results
    ADD CONSTRAINT airport_raw_results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.airport_raw_results
    ADD CONSTRAINT airport_raw_results_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.airport_raw_results
    ADD CONSTRAINT airport_raw_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.airport_raw_results
    ADD CONSTRAINT airport_raw_results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.airport_raw_results
    ADD CONSTRAINT airport_raw_results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.airport_raw_results
    ADD CONSTRAINT airport_raw_results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id);



ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_id_fkey FOREIGN KEY (id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.available_observations
    ADD CONSTRAINT available_observations_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.available_observations
    ADD CONSTRAINT available_observations_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.base_result_orders
    ADD CONSTRAINT base_result_orders_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.base_result_orders
    ADD CONSTRAINT base_result_orders_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.base_result_orders
    ADD CONSTRAINT base_result_orders_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.base_result_orders
    ADD CONSTRAINT base_result_orders_period_type_id_fkey FOREIGN KEY (period_type_id) REFERENCES public.period_types(id);



ALTER TABLE ONLY public.base_result_orders
    ADD CONSTRAINT base_result_orders_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.base_result_orders
    ADD CONSTRAINT base_result_orders_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.climatology
    ADD CONSTRAINT climatology_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.climatology
    ADD CONSTRAINT climatology_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.derivative_estimators
    ADD CONSTRAINT derivative_estimators_base_estimator_id_fkey FOREIGN KEY (base_estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.derivative_estimators
    ADD CONSTRAINT derivative_estimators_base_parameter_id_fkey FOREIGN KEY (base_parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.derivative_estimators
    ADD CONSTRAINT derivative_estimators_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.derivative_estimators
    ADD CONSTRAINT derivative_estimators_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.derivative_rvm
    ADD CONSTRAINT derivative_rvm_base_estimator_id_fkey FOREIGN KEY (base_estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.derivative_rvm
    ADD CONSTRAINT derivative_rvm_base_parameter_id_fkey FOREIGN KEY (base_parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.derivative_rvm
    ADD CONSTRAINT derivative_rvm_comparison_producer_id_fkey FOREIGN KEY (comparison_producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.derivative_rvm
    ADD CONSTRAINT derivative_rvm_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.derivative_rvm
    ADD CONSTRAINT derivative_rvm_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.ecmwfeps_forecasts
    ADD CONSTRAINT ecmwfeps_forecasts_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.ecmwfeps_forecasts
    ADD CONSTRAINT ecmwfeps_forecasts_forecasts_fkey FOREIGN KEY (producer_id, analysis_time) REFERENCES public.forecasts(producer_id, analysis_time);



ALTER TABLE ONLY public.ecmwfeps_forecasts
    ADD CONSTRAINT ecmwfeps_forecasts_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.ecmwfeps_forecasts
    ADD CONSTRAINT ecmwfeps_forecasts_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.ecmwfeps_forecasts
    ADD CONSTRAINT ecmwfeps_forecasts_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.ecmwfeps_results
    ADD CONSTRAINT ecmwfeps_results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.ecmwfeps_results
    ADD CONSTRAINT ecmwfeps_results_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.ecmwfeps_results
    ADD CONSTRAINT ecmwfeps_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.ecmwfeps_results
    ADD CONSTRAINT ecmwfeps_results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.ecmwfeps_results
    ADD CONSTRAINT ecmwfeps_results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.ecmwfeps_results
    ADD CONSTRAINT ecmwfeps_results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.estimators
    ADD CONSTRAINT estimators_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id);



ALTER TABLE ONLY public.forecaster_privileges
    ADD CONSTRAINT forecaster_privileges_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.forecaster_privileges
    ADD CONSTRAINT forecaster_privileges_watcher_id_fkey FOREIGN KEY (watcher_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.forecasts
    ADD CONSTRAINT forecasts_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.grade_colors
    ADD CONSTRAINT grade_colors_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.grade_colors
    ADD CONSTRAINT grade_colors_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.harmonie_forecasts
    ADD CONSTRAINT harmonie_forecasts_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.harmonie_forecasts
    ADD CONSTRAINT harmonie_forecasts_forecasts_fkey FOREIGN KEY (producer_id, analysis_time) REFERENCES public.forecasts(producer_id, analysis_time);



ALTER TABLE ONLY public.harmonie_forecasts
    ADD CONSTRAINT harmonie_forecasts_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.harmonie_forecasts
    ADD CONSTRAINT harmonie_forecasts_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.harmonie_forecasts
    ADD CONSTRAINT harmonie_forecasts_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.harmonie_results
    ADD CONSTRAINT harmonie_results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.harmonie_results
    ADD CONSTRAINT harmonie_results_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.harmonie_results
    ADD CONSTRAINT harmonie_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.harmonie_results
    ADD CONSTRAINT harmonie_results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.harmonie_results
    ADD CONSTRAINT harmonie_results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.harmonie_results
    ADD CONSTRAINT harmonie_results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.icao_stations
    ADD CONSTRAINT icao_stations_fmisid_fkey FOREIGN KEY (fmisid) REFERENCES public.locations(fmisid);



ALTER TABLE ONLY public.localization_translations
    ADD CONSTRAINT localization_translations_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES public.localization_entries(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.localization_translations
    ADD CONSTRAINT localization_translations_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.localization_languages(id);



ALTER TABLE ONLY public.location_kinds
    ADD CONSTRAINT location_kinds_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id);



ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_fmisid_fkey FOREIGN KEY (fmisid) REFERENCES public.targets(id);



ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_kind_id_fkey FOREIGN KEY (kind_id) REFERENCES public.location_kinds(id);



ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_name_id_fkey FOREIGN KEY (name_id) REFERENCES public.localization_entries(id) ON DELETE CASCADE;



ALTER TABLE public.model_data
    ADD CONSTRAINT model_data_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE public.model_data
    ADD CONSTRAINT model_data_forecasts_fkey FOREIGN KEY (producer_id, analysis_time) REFERENCES public.forecasts(producer_id, analysis_time);



ALTER TABLE public.model_data
    ADD CONSTRAINT model_data_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE public.model_data
    ADD CONSTRAINT model_data_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE public.model_data
    ADD CONSTRAINT model_data_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.model_parameter_views
    ADD CONSTRAINT model_parameter_views_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.mos_production_forecasts
    ADD CONSTRAINT mos_production_forecasts_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.mos_production_forecasts
    ADD CONSTRAINT mos_production_forecasts_forecasts_fkey FOREIGN KEY (producer_id, analysis_time) REFERENCES public.forecasts(producer_id, analysis_time);



ALTER TABLE ONLY public.mos_production_forecasts
    ADD CONSTRAINT mos_production_forecasts_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.mos_production_forecasts
    ADD CONSTRAINT mos_production_forecasts_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.mos_production_forecasts
    ADD CONSTRAINT mos_production_forecasts_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.mos_production_results
    ADD CONSTRAINT mos_production_results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.mos_production_results
    ADD CONSTRAINT mos_production_results_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.mos_production_results
    ADD CONSTRAINT mos_production_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.mos_production_results
    ADD CONSTRAINT mos_production_results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.mos_production_results
    ADD CONSTRAINT mos_production_results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.mos_production_results
    ADD CONSTRAINT mos_production_results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.moseckrigingx_forecasts
    ADD CONSTRAINT moseckrigingx_forecasts_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.moseckrigingx_forecasts
    ADD CONSTRAINT moseckrigingx_forecasts_forecasts_fkey FOREIGN KEY (producer_id, analysis_time) REFERENCES public.forecasts(producer_id, analysis_time);



ALTER TABLE ONLY public.moseckrigingx_forecasts
    ADD CONSTRAINT moseckrigingx_forecasts_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.moseckrigingx_forecasts
    ADD CONSTRAINT moseckrigingx_forecasts_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.moseckrigingx_forecasts
    ADD CONSTRAINT moseckrigingx_forecasts_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.moseckrigingx_results
    ADD CONSTRAINT moseckrigingx_results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.moseckrigingx_results
    ADD CONSTRAINT moseckrigingx_results_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.moseckrigingx_results
    ADD CONSTRAINT moseckrigingx_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.moseckrigingx_results
    ADD CONSTRAINT moseckrigingx_results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.moseckrigingx_results
    ADD CONSTRAINT moseckrigingx_results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.moseckrigingx_results
    ADD CONSTRAINT moseckrigingx_results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.network_map
    ADD CONSTRAINT network_map_network_id_fkey FOREIGN KEY (network_id) REFERENCES public.networks(id);



ALTER TABLE ONLY public.network_map
    ADD CONSTRAINT network_map_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.networks
    ADD CONSTRAINT networks_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id);



ALTER TABLE ONLY public.parameter_class_limits
    ADD CONSTRAINT parameter_class_limits_base_parameter_id_fkey FOREIGN KEY (base_parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.parameter_class_limits
    ADD CONSTRAINT parameter_class_limits_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.parameter_map
    ADD CONSTRAINT parameter_map_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id) ON DELETE CASCADE;



ALTER TABLE ONLY public.period_types
    ADD CONSTRAINT period_types_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id) ON DELETE CASCADE;



ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_type_fkey FOREIGN KEY (type) REFERENCES public.period_types(name);



ALTER TABLE ONLY public.producers
    ADD CONSTRAINT producers_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id) ON DELETE CASCADE;



ALTER TABLE ONLY public.result_orders
    ADD CONSTRAINT result_orders_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.result_orders
    ADD CONSTRAINT result_orders_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE ONLY public.result_orders
    ADD CONSTRAINT result_orders_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.result_orders
    ADD CONSTRAINT result_orders_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.result_orders
    ADD CONSTRAINT result_orders_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.result_orders
    ADD CONSTRAINT result_orders_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.result_parameter_views
    ADD CONSTRAINT result_parameter_views_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE public.results
    ADD CONSTRAINT results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE public.results
    ADD CONSTRAINT results_forecaster_id_fkey FOREIGN KEY (forecaster_id) REFERENCES public.forecasters(id);



ALTER TABLE public.results
    ADD CONSTRAINT results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE public.results
    ADD CONSTRAINT results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE public.results
    ADD CONSTRAINT results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE public.results
    ADD CONSTRAINT results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.sea_level_warning_limits
    ADD CONSTRAINT sea_level_warning_limits_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id);



ALTER TABLE ONLY public.sea_level_warning_limits
    ADD CONSTRAINT sea_level_warning_limits_base_parameter_id_fkey FOREIGN KEY (base_parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.sea_level_warning_limits
    ADD CONSTRAINT sea_level_warning_limits_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(fmisid);



ALTER TABLE ONLY public.sea_level_warning_limits
    ADD CONSTRAINT sea_level_warning_limits_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.sea_level_warning_limits
    ADD CONSTRAINT sea_level_warning_limits_warning_index_fkey FOREIGN KEY (warning_index) REFERENCES public.warning_levels(severity_id);



ALTER TABLE ONLY public.special_observations
    ADD CONSTRAINT special_observations_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.special_observations
    ADD CONSTRAINT special_observations_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.target_level_results
    ADD CONSTRAINT target_level_results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.target_level_results
    ADD CONSTRAINT target_level_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.target_level_results
    ADD CONSTRAINT target_level_results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.targetgroup_map
    ADD CONSTRAINT targetgroup_map_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.targetgroups(id);



ALTER TABLE ONLY public.targetgroup_map
    ADD CONSTRAINT targetgroup_map_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.targetgroups
    ADD CONSTRAINT targetgroups_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id) ON DELETE CASCADE;



ALTER TABLE ONLY public.targetgroups
    ADD CONSTRAINT targetgroups_id_fkey FOREIGN KEY (id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.target_types(id);



ALTER TABLE ONLY public.used_area_result_estimators
    ADD CONSTRAINT used_area_result_estimators_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.used_area_result_estimators
    ADD CONSTRAINT used_area_result_estimators_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_area_result_estimators
    ADD CONSTRAINT used_area_result_estimators_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_area_result_estimators
    ADD CONSTRAINT used_area_result_estimators_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_area_result_hours
    ADD CONSTRAINT used_area_result_hours_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_area_result_hours
    ADD CONSTRAINT used_area_result_hours_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_area_result_hours
    ADD CONSTRAINT used_area_result_hours_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_area_result_targets
    ADD CONSTRAINT used_area_result_targets_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id);



ALTER TABLE ONLY public.used_area_result_targets
    ADD CONSTRAINT used_area_result_targets_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_area_result_targets
    ADD CONSTRAINT used_area_result_targets_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_area_result_targets
    ADD CONSTRAINT used_area_result_targets_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_group_result_estimators
    ADD CONSTRAINT used_group_result_estimators_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.used_group_result_estimators
    ADD CONSTRAINT used_group_result_estimators_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_group_result_estimators
    ADD CONSTRAINT used_group_result_estimators_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_group_result_estimators
    ADD CONSTRAINT used_group_result_estimators_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_group_result_hours
    ADD CONSTRAINT used_group_result_hours_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_group_result_hours
    ADD CONSTRAINT used_group_result_hours_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_group_result_hours
    ADD CONSTRAINT used_group_result_hours_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_group_result_targets
    ADD CONSTRAINT used_group_result_targets_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.targetgroups(id);



ALTER TABLE ONLY public.used_group_result_targets
    ADD CONSTRAINT used_group_result_targets_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_group_result_targets
    ADD CONSTRAINT used_group_result_targets_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_group_result_targets
    ADD CONSTRAINT used_group_result_targets_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_location_result_estimators
    ADD CONSTRAINT used_location_result_estimators_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.used_location_result_estimators
    ADD CONSTRAINT used_location_result_estimators_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_location_result_estimators
    ADD CONSTRAINT used_location_result_estimators_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_location_result_estimators
    ADD CONSTRAINT used_location_result_estimators_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_location_result_groups
    ADD CONSTRAINT used_location_result_groups_location_id_fkey FOREIGN KEY (group_id) REFERENCES public.targetgroups(id);



ALTER TABLE ONLY public.used_location_result_groups
    ADD CONSTRAINT used_location_result_groups_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_location_result_groups
    ADD CONSTRAINT used_location_result_groups_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_location_result_groups
    ADD CONSTRAINT used_location_result_groups_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_location_result_hours
    ADD CONSTRAINT used_location_result_hours_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_location_result_hours
    ADD CONSTRAINT used_location_result_hours_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_location_result_hours
    ADD CONSTRAINT used_location_result_hours_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_location_result_targets
    ADD CONSTRAINT used_location_result_targets_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(fmisid);



ALTER TABLE ONLY public.used_location_result_targets
    ADD CONSTRAINT used_location_result_targets_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_location_result_targets
    ADD CONSTRAINT used_location_result_targets_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_location_result_targets
    ADD CONSTRAINT used_location_result_targets_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_model_groups
    ADD CONSTRAINT used_model_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.targetgroups(id);



ALTER TABLE ONLY public.used_model_groups
    ADD CONSTRAINT used_model_groups_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_model_groups
    ADD CONSTRAINT used_model_groups_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_model_hours
    ADD CONSTRAINT used_model_hours_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_model_hours
    ADD CONSTRAINT used_model_hours_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_model_locations
    ADD CONSTRAINT used_model_locations_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(fmisid);



ALTER TABLE ONLY public.used_model_locations
    ADD CONSTRAINT used_model_locations_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_model_locations
    ADD CONSTRAINT used_model_locations_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.used_zero_limit_results
    ADD CONSTRAINT used_zero_limit_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.used_zero_limit_results
    ADD CONSTRAINT used_zero_limit_results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.used_zero_limit_results
    ADD CONSTRAINT used_zero_limit_results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.warning_levels
    ADD CONSTRAINT warning_levels_description_id_fkey FOREIGN KEY (description_id) REFERENCES public.localization_entries(id);



ALTER TABLE ONLY public.warning_rule_conditions
    ADD CONSTRAINT warning_rule_conditions_parameter_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.warning_rule_conditions
    ADD CONSTRAINT warning_rule_conditions_rule_fkey FOREIGN KEY (warning_rule_id) REFERENCES public.warning_rules(id) ON DELETE CASCADE;



ALTER TABLE ONLY public.warning_rules
    ADD CONSTRAINT warning_rules_severity_fkey FOREIGN KEY (severity_id) REFERENCES public.warning_levels(severity_id);



ALTER TABLE ONLY public.warning_rules
    ADD CONSTRAINT warning_rules_target_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.wind_correction_coefficients
    ADD CONSTRAINT wind_correction_coefficients_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.wind_correction_sets(id);



ALTER TABLE ONLY public.wind_correction_sets
    ADD CONSTRAINT wind_correction_sets_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id);



ALTER TABLE ONLY public.wind_correction_sets
    ADD CONSTRAINT wind_correction_sets_secondary_area_id_fkey FOREIGN KEY (secondary_area_id) REFERENCES public.areas(id);



ALTER TABLE ONLY public.wind_correction_sets
    ADD CONSTRAINT wind_correction_sets_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);



ALTER TABLE ONLY public.wind_correction_sets
    ADD CONSTRAINT wind_correction_sets_tertiary_area_id_fkey FOREIGN KEY (tertiary_area_id) REFERENCES public.areas(id);



ALTER TABLE ONLY public.wind_roughness
    ADD CONSTRAINT wind_roughness_fmisid_fkey FOREIGN KEY (fmisid) REFERENCES public.targets(id);



ALTER TABLE ONLY public.wind_roughness_sea_validity
    ADD CONSTRAINT wind_roughness_sea_validity_fmisid_fkey FOREIGN KEY (fmisid) REFERENCES public.targets(id);



ALTER TABLE ONLY public.zero_limit_results
    ADD CONSTRAINT zero_limit_results_estimator_id_fkey FOREIGN KEY (estimator_id) REFERENCES public.estimators(id);



ALTER TABLE ONLY public.zero_limit_results
    ADD CONSTRAINT zero_limit_results_parameter_id_fkey FOREIGN KEY (parameter_id) REFERENCES public.parameters(id);



ALTER TABLE ONLY public.zero_limit_results
    ADD CONSTRAINT zero_limit_results_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id);



ALTER TABLE ONLY public.zero_limit_results
    ADD CONSTRAINT zero_limit_results_producer_id_fkey FOREIGN KEY (producer_id) REFERENCES public.producers(id);



ALTER TABLE ONLY public.zero_limit_results
    ADD CONSTRAINT zero_limit_results_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.targets(id);






GRANT ALL ON SCHEMA public TO verifadmin;



GRANT ALL ON FUNCTION public.raster_in(cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_out(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.box2d_in(cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO verifadmin;



GRANT ALL ON FUNCTION public.box2df_in(cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO verifadmin;



GRANT ALL ON FUNCTION public.box3d_in(cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_analyze(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_out(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_send(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_in(cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_recv(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO verifadmin;



GRANT ALL ON FUNCTION public.gidx_in(cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO verifadmin;



GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO verifadmin;



GRANT ALL ON FUNCTION public.box3d(public.box2d) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(public.box2d) TO verifadmin;



GRANT ALL ON FUNCTION public.box(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.box2d(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.geography(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.bytea(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.box(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.box2d(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.box3d(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.bytea(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geography(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.path(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.point(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.polygon(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.text(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(path) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(point) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(polygon) TO verifadmin;



GRANT ALL ON FUNCTION public.box3d(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.bytea(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_convexhull(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry(text) TO verifadmin;



GRANT ALL ON FUNCTION public.__st_countagg_transfn(agg public.agg_count, rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._add_overview_constraint(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, factor integer) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint(cn name, sql text) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._add_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_overview_constraint(ovschema name, ovtable name, ovcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint(rastschema name, rasttable name, cn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_regular_blocking(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._drop_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._overview_constraint(ov public.raster, factor integer, refschema name, reftable name, refcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._overview_constraint_info(ovschema name, ovtable name, ovcolumn name, OUT refschema name, OUT reftable name, OUT refcolumn name, OUT factor integer) TO verifadmin;



GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO verifadmin;



GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO verifadmin;



GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO verifadmin;



GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO verifadmin;



GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO verifadmin;



GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_alignment(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_coverage_tile(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_extent(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_index(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_nodata_values(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_num_bands(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_out_db(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_pixel_types(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_regular_blocking(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_scale(rastschema name, rasttable name, rastcolumn name, axis character) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_spatially_unique(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_info_srid(rastschema name, rasttable name, rastcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_nodata_values(rast public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_out_db(rast public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public._raster_constraint_pixel_types(rast public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO verifadmin;



GRANT ALL ON FUNCTION public._st_aspect4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO verifadmin;



GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public._st_clip(rast public.raster, nband integer[], geom public.geometry, nodataval double precision[], crop boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_colormap(rast public.raster, nband integer, colormap text, method text) TO verifadmin;



GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_contains(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_containsproperly(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_convertarray4ma(value double precision[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_count(rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_countagg_finalfn(agg public.agg_count) TO verifadmin;



GRANT ALL ON FUNCTION public._st_countagg_transfn(agg public.agg_count, rast public.raster, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_countagg_transfn(agg public.agg_count, rast public.raster, nband integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_countagg_transfn(agg public.agg_count, rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_coveredby(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_covers(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_dfullywithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_dwithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_gdalwarp(rast public.raster, algorithm text, maxerr double precision, srid integer, scalex double precision, scaley double precision, gridx double precision, gridy double precision, skewx double precision, skewy double precision, width integer, height integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_hillshade4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_mapalgebra(rastbandargset public.rastbandarg[], expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_mapalgebra(rastbandargset public.rastbandarg[], callbackfunc regprocedure, pixeltype text, distancex integer, distancey integer, extenttype text, customextent public.raster, mask double precision[], weighted boolean, VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_neighborhood(rast public.raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_overlaps(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_pixelaspolygons(rast public.raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public._st_rastertoworldcoord(rast public.raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_reclass(rast public.raster, VARIADIC reclassargset public.reclassarg[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_roughness4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_samealignment_finalfn(agg public.agg_samealignment) TO verifadmin;



GRANT ALL ON FUNCTION public._st_samealignment_transfn(agg public.agg_samealignment, rast public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public._st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[], hasnosetvalue boolean, nosetvalue double precision, keepnodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_slope4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_summarystats_finalfn(internal) TO verifadmin;



GRANT ALL ON FUNCTION public._st_summarystats_transfn(internal, public.raster, boolean, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_summarystats_transfn(internal, public.raster, integer, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_summarystats_transfn(internal, public.raster, integer, boolean, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_tile(rast public.raster, width integer, height integer, nband integer[], padwithnodata boolean, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_touches(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_tpi4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_tri4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_union_finalfn(internal) TO verifadmin;



GRANT ALL ON FUNCTION public._st_union_transfn(internal, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public._st_union_transfn(internal, public.raster, integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_union_transfn(internal, public.raster, text) TO verifadmin;



GRANT ALL ON FUNCTION public._st_union_transfn(internal, public.raster, public.unionarg[]) TO verifadmin;



GRANT ALL ON FUNCTION public._st_union_transfn(internal, public.raster, integer, text) TO verifadmin;



GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO verifadmin;



GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public._st_within(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public._st_worldtorastercoord(rast public.raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer) TO verifadmin;



GRANT ALL ON FUNCTION public._updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.addauth(text) TO verifadmin;



GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.addoverviewconstraints(ovtable name, ovcolumn name, reftable name, refcolumn name, ovfactor integer) TO verifadmin;



GRANT ALL ON FUNCTION public.addoverviewconstraints(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, ovfactor integer) TO verifadmin;



GRANT ALL ON FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.checkauth(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.checkauthtrigger() TO verifadmin;



GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO verifadmin;



GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO verifadmin;



GRANT ALL ON FUNCTION public.disablelongtransactions() TO verifadmin;



GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO verifadmin;



GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO verifadmin;



GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO verifadmin;



GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO verifadmin;



GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO verifadmin;



GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO verifadmin;



GRANT ALL ON FUNCTION public.dropoverviewconstraints(ovtable name, ovcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public.dropoverviewconstraints(ovschema name, ovtable name, ovcolumn name) TO verifadmin;



GRANT ALL ON FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.enablelongtransactions() TO verifadmin;



GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO verifadmin;



GRANT ALL ON FUNCTION public.fn_triggerall(doenable boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_contained_by_raster(public.geometry, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_raster_contain(public.geometry, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_raster_overlap(public.geometry, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.geomfromewkt(text) TO verifadmin;



GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO verifadmin;



GRANT ALL ON FUNCTION public.gettransactionid() TO verifadmin;



GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO verifadmin;



GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO verifadmin;



GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO verifadmin;



GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO verifadmin;



GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO verifadmin;



GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO verifadmin;



GRANT ALL ON FUNCTION public.longtransactionsenabled() TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO verifadmin;



GRANT ALL ON FUNCTION public.pg_relpages(relname regclass) TO verifadmin;



GRANT ALL ON FUNCTION public.pg_relpages(relname text) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO verifadmin;



GRANT ALL ON FUNCTION public.pgstatginindex(relname regclass, OUT version integer, OUT pending_pages integer, OUT pending_tuples bigint) TO verifadmin;



GRANT ALL ON FUNCTION public.pgstathashindex(relname regclass, OUT version integer, OUT bucket_pages bigint, OUT overflow_pages bigint, OUT bitmap_pages bigint, OUT unused_pages bigint, OUT live_items bigint, OUT dead_items bigint, OUT free_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.pgstatindex(relname regclass, OUT version integer, OUT tree_level integer, OUT index_size bigint, OUT root_block_no bigint, OUT internal_pages bigint, OUT leaf_pages bigint, OUT empty_pages bigint, OUT deleted_pages bigint, OUT avg_leaf_density double precision, OUT leaf_fragmentation double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.pgstatindex(relname text, OUT version integer, OUT tree_level integer, OUT index_size bigint, OUT root_block_no bigint, OUT internal_pages bigint, OUT leaf_pages bigint, OUT empty_pages bigint, OUT deleted_pages bigint, OUT avg_leaf_density double precision, OUT leaf_fragmentation double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.pgstattuple(reloid regclass, OUT table_len bigint, OUT tuple_count bigint, OUT tuple_len bigint, OUT tuple_percent double precision, OUT dead_tuple_count bigint, OUT dead_tuple_len bigint, OUT dead_tuple_percent double precision, OUT free_space bigint, OUT free_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.pgstattuple(relname text, OUT table_len bigint, OUT tuple_count bigint, OUT tuple_len bigint, OUT tuple_percent double precision, OUT dead_tuple_count bigint, OUT dead_tuple_len bigint, OUT dead_tuple_percent double precision, OUT free_space bigint, OUT free_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.pgstattuple_approx(reloid regclass, OUT table_len bigint, OUT scanned_percent double precision, OUT approx_tuple_count bigint, OUT approx_tuple_len bigint, OUT approx_tuple_percent double precision, OUT dead_tuple_count bigint, OUT dead_tuple_len bigint, OUT dead_tuple_percent double precision, OUT approx_free_space bigint, OUT approx_free_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_full_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_gdal_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_geos_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_lib_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_libjson_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_libxml_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_noop(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_proj_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_raster_lib_build_date() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_raster_lib_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_raster_scripts_installed() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_scripts_released() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_svn_version() TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO verifadmin;



GRANT ALL ON FUNCTION public.postgis_version() TO verifadmin;



GRANT ALL ON FUNCTION public.raster_above(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_below(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_contain(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_contained(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_contained_by_geometry(public.raster, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_eq(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_geometry_contain(public.raster, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_geometry_overlap(public.raster, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_hash(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_left(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_overabove(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_overbelow(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_overlap(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_overleft(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_overright(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_right(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.raster_same(public.raster, public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_addband(rast public.raster, addbandargset public.addbandarg[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_addband(torast public.raster, fromrasts public.raster[], fromband integer, torastindex integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_addband(rast public.raster, index integer, outdbfile text, outdbindex integer[], nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_addband(rast public.raster, outdbfile text, outdbindex integer[], index integer, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxcount(rast public.raster, sample_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxcount(rast public.raster, exclude_nodata_value boolean, sample_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxcount(rast public.raster, nband integer, sample_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxcount(rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxquantile(rast public.raster, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxquantile(rast public.raster, exclude_nodata_value boolean, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxquantile(rast public.raster, sample_percent double precision, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxquantile(rast public.raster, nband integer, sample_percent double precision, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_approxquantile(rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_area(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_area(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asbinary(public.raster, outasin boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asewkt(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgdalraster(rast public.raster, format text, options text[], srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgeojson(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgml(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asjpeg(rast public.raster, options text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asjpeg(rast public.raster, nbands integer[], options text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asjpeg(rast public.raster, nbands integer[], quality integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asjpeg(rast public.raster, nband integer, options text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asjpeg(rast public.raster, nband integer, quality integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_askml(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_aspect(rast public.raster, nband integer, customextent public.raster, pixeltype text, units text, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_aspng(rast public.raster, options text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_aspng(rast public.raster, nbands integer[], options text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_aspng(rast public.raster, nbands integer[], compression integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_aspng(rast public.raster, nband integer, options text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_aspng(rast public.raster, nband integer, compression integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, ref public.raster, pixeltype text[], value double precision[], nodataval double precision[], touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, ref public.raster, pixeltype text, value double precision, nodataval double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_assvg(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astext(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astiff(rast public.raster, options text[], srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astiff(rast public.raster, compression text, srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astiff(rast public.raster, nbands integer[], options text[], srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astiff(rast public.raster, nbands integer[], compression text, srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_band(rast public.raster, nbands integer[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_band(rast public.raster, nband integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_band(rast public.raster, nbands text, delimiter character) TO verifadmin;



GRANT ALL ON FUNCTION public.st_bandisnodata(rast public.raster, forcechecking boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_centroid(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_clip(rast public.raster, nband integer[], geom public.geometry, nodataval double precision[], crop boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO verifadmin;



GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_colormap(rast public.raster, colormap text, method text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_colormap(rast public.raster, nband integer, colormap text, method text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_contains(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_contains(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_containsproperly(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_containsproperly(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_count(rast public.raster, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_count(rast public.raster, nband integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_coveredby(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_coveredby(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_covers(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_covers(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_covers(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_createoverview(tab regclass, col name, factor integer, algo text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dfullywithin(rast1 public.raster, rast2 public.raster, distance double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dfullywithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_disjoint(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_disjoint(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distance(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distinct4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_distinct4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dumpaspolygons(rast public.raster, band integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dumpvalues(rast public.raster, nband integer[], exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dumpvalues(rast public.raster, nband integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dwithin(rast1 public.raster, rast2 public.raster, distance double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_dwithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_envelope(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_findextent(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_fromgdalraster(gdaldata bytea, srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_gdaldrivers(OUT idx integer, OUT short_name text, OUT long_name text, OUT can_read boolean, OUT can_write boolean, OUT create_options text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_geotransform(public.raster, OUT imag double precision, OUT jmag double precision, OUT theta_i double precision, OUT theta_ij double precision, OUT xoffset double precision, OUT yoffset double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_gmltosql(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_hasnoband(rast public.raster, nband integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_height(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_hillshade(rast public.raster, nband integer, customextent public.raster, pixeltype text, azimuth double precision, altitude double precision, max_bright double precision, scale double precision, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(geomin public.geometry, rast public.raster, band integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, nodataval double precision[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, returnband text, nodataval double precision[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, returnband text, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, nodataval double precision[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, returnband text, nodataval double precision[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, returnband text, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersects(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_invdistweight4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_iscoveragetile(rast public.raster, coverage public.raster, tilewidth integer, tileheight integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isempty(rast public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_length(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_length(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO verifadmin;



GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linefromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_m(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makeemptycoverage(tilewidth integer, tileheight integer, width integer, height integer, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision, srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makeemptyraster(rast public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, pixelsize double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast public.raster, pixeltype text, expression text, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast public.raster, nband integer, pixeltype text, expression text, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rastbandargset public.rastbandarg[], callbackfunc regprocedure, pixeltype text, extenttype text, customextent public.raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast1 public.raster, rast2 public.raster, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast public.raster, nband integer[], callbackfunc regprocedure, pixeltype text, extenttype text, customextent public.raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast public.raster, nband integer, callbackfunc regprocedure, mask double precision[], weighted boolean, pixeltype text, extenttype text, customextent public.raster, VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast public.raster, nband integer, callbackfunc regprocedure, pixeltype text, extenttype text, customextent public.raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebra(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, callbackfunc regprocedure, pixeltype text, extenttype text, customextent public.raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebraexpr(rast public.raster, pixeltype text, expression text, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebraexpr(rast public.raster, band integer, pixeltype text, expression text, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebraexpr(rast1 public.raster, rast2 public.raster, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mapalgebraexpr(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_max4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_max4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mean4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mean4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_memsize(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_metadata(rast public.raster, OUT upperleftx double precision, OUT upperlefty double precision, OUT width integer, OUT height integer, OUT scalex double precision, OUT scaley double precision, OUT skewx double precision, OUT skewy double precision, OUT srid integer, OUT numbands integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_min4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_min4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_minconvexhull(rast public.raster, nband integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mindist4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_minpossiblevalue(pixeltype text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_nearestvalue(rast public.raster, pt public.geometry, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_nearestvalue(rast public.raster, band integer, pt public.geometry, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_neighborhood(rast public.raster, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_neighborhood(rast public.raster, band integer, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_neighborhood(rast public.raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_notsamealignmentreason(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_numbands(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_overlaps(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_overlaps(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelascentroid(rast public.raster, x integer, y integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelascentroids(rast public.raster, band integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelaspoint(rast public.raster, x integer, y integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelaspoints(rast public.raster, band integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelaspolygon(rast public.raster, x integer, y integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelaspolygons(rast public.raster, band integer, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelheight(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelofvalue(rast public.raster, search double precision[], exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelofvalue(rast public.raster, search double precision, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelofvalue(rast public.raster, nband integer, search double precision[], exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelofvalue(rast public.raster, nband integer, search double precision, exclude_nodata_value boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pixelwidth(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_points(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_quantile(rast public.raster, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_quantile(rast public.raster, exclude_nodata_value boolean, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_quantile(rast public.raster, nband integer, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_quantile(rast public.raster, nband integer, exclude_nodata_value boolean, quantile double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_range4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_range4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rastertoworldcoord(rast public.raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rastertoworldcoordx(rast public.raster, xr integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rastertoworldcoordx(rast public.raster, xr integer, yr integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rastertoworldcoordy(rast public.raster, yr integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rastertoworldcoordy(rast public.raster, xr integer, yr integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_reclass(rast public.raster, VARIADIC reclassargset public.reclassarg[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_reclass(rast public.raster, reclassexpr text, pixeltype text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_reclass(rast public.raster, nband integer, reclassexpr text, pixeltype text, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_resample(rast public.raster, ref public.raster, usescale boolean, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_resample(rast public.raster, ref public.raster, algorithm text, maxerr double precision, usescale boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_resample(rast public.raster, scalex double precision, scaley double precision, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_resample(rast public.raster, width integer, height integer, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rescale(rast public.raster, scalexy double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rescale(rast public.raster, scalex double precision, scaley double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_resize(rast public.raster, percentwidth double precision, percentheight double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_resize(rast public.raster, width integer, height integer, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_resize(rast public.raster, width text, height text, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_reskew(rast public.raster, skewxy double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_reskew(rast public.raster, skewx double precision, skewy double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_retile(tab regclass, col name, ext public.geometry, sfx double precision, sfy double precision, tw integer, th integer, algo text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_rotation(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_roughness(rast public.raster, nband integer, pixeltype text, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_roughness(rast public.raster, nband integer, customextent public.raster, pixeltype text, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_samealignment(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_samealignment(ulx1 double precision, uly1 double precision, scalex1 double precision, scaley1 double precision, skewx1 double precision, skewy1 double precision, ulx2 double precision, uly2 double precision, scalex2 double precision, scaley2 double precision, skewx2 double precision, skewy2 double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_scalex(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_scaley(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setbandnodatavalue(rast public.raster, nodatavalue double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setgeoreference(rast public.raster, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setgeotransform(rast public.raster, imag double precision, jmag double precision, theta_i double precision, theta_ij double precision, xoffset double precision, yoffset double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setrotation(rast public.raster, rotation double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setscale(rast public.raster, scale double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setscale(rast public.raster, scalex double precision, scaley double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setskew(rast public.raster, skew double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setskew(rast public.raster, skewx double precision, skewy double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setsrid(rast public.raster, srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setupperleft(rast public.raster, upperleftx double precision, upperlefty double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setvalue(rast public.raster, x integer, y integer, newvalue double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setvalue(rast public.raster, band integer, x integer, y integer, newvalue double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setvalues(rast public.raster, nband integer, geomvalset public.geomval[], keepnodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[], keepnodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], nosetvalue double precision, keepnodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setvalues(rast public.raster, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_skewx(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_skewy(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_slope(rast public.raster, nband integer, customextent public.raster, pixeltype text, units text, scale double precision, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalexy double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalex double precision, scaley double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, algorithm text, maxerr double precision, scalex double precision, scaley double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_srid(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_stddev4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_stddev4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_sum4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_sum4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_summary(public.geography) TO verifadmin;



GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_summary(rast public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO verifadmin;



GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_tile(rast public.raster, width integer, height integer, padwithnodata boolean, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_tile(rast public.raster, nband integer[], width integer, height integer, padwithnodata boolean, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_tile(rast public.raster, nband integer, width integer, height integer, padwithnodata boolean, nodataval double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_touches(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_touches(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_tpi(rast public.raster, nband integer, pixeltype text, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_tpi(rast public.raster, nband integer, customextent public.raster, pixeltype text, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(rast public.raster, alignto public.raster, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(rast public.raster, srid integer, scalexy double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(rast public.raster, srid integer, scalex double precision, scaley double precision, algorithm text, maxerr double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transform(rast public.raster, srid integer, algorithm text, maxerr double precision, scalex double precision, scaley double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_tri(rast public.raster, nband integer, pixeltype text, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_tri(rast public.raster, nband integer, customextent public.raster, pixeltype text, interpolate_nodata boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_upperleftx(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_upperlefty(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuecount(rast public.raster, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuecount(rast public.raster, nband integer, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuecount(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rast public.raster, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rast public.raster, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rast public.raster, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rast public.raster, nband integer, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_width(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_within(rast1 public.raster, rast2 public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_within(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO verifadmin;



GRANT ALL ON FUNCTION public.st_wkttosql(text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoord(rast public.raster, pt public.geometry, OUT columnx integer, OUT rowy integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoord(rast public.raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoordx(rast public.raster, xw double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoordx(rast public.raster, pt public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoordx(rast public.raster, xw double precision, yw double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoordy(rast public.raster, yw double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoordy(rast public.raster, pt public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_worldtorastercoordy(rast public.raster, xw double precision, yw double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_x(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.st_y(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.st_z(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO verifadmin;



GRANT ALL ON FUNCTION public.unlockrows(text) TO verifadmin;



GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.updaterastersrid(table_name name, column_name name, new_srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_countagg(public.raster, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_countagg(public.raster, integer, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_countagg(public.raster, integer, boolean, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_samealignment(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_summarystatsagg(public.raster, boolean, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_summarystatsagg(public.raster, integer, boolean) TO verifadmin;



GRANT ALL ON FUNCTION public.st_summarystatsagg(public.raster, integer, boolean, double precision) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(public.geometry) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(public.raster) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(public.raster, integer) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(public.raster, text) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(public.raster, public.unionarg[]) TO verifadmin;



GRANT ALL ON FUNCTION public.st_union(public.raster, integer, text) TO verifadmin;



GRANT SELECT ON TABLE public.model_data TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.model_data TO verif_data_rw;
GRANT SELECT ON TABLE public.model_data TO replicator;



GRANT SELECT ON TABLE public.adf_preop_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.adf_preop_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.results TO verif_data_rw;



GRANT SELECT ON TABLE public.adf_preop_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.adf_preop_results TO verif_data_rw;



GRANT SELECT ON TABLE public.aifs_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.aifs_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.aifs_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.aifs_results TO verif_data_rw;



GRANT SELECT ON TABLE public.aila_preop_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.aila_preop_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.aila_preop_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.aila_preop_results TO verif_data_rw;



GRANT SELECT ON TABLE public.airport_forecast_view_settings TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.airport_forecast_view_settings TO verif_data_rw;



GRANT SELECT ON TABLE public.airport_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.airport_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.airport_raw_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.airport_raw_results TO verif_data_rw;



GRANT SELECT ON TABLE public.airport_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.airport_results TO verif_data_rw;



GRANT SELECT ON TABLE public.apple_weather_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.apple_weather_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.apple_weather_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.apple_weather_results TO verif_data_rw;



GRANT SELECT ON TABLE public.areas TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.areas TO verif_meta_rw;
GRANT SELECT ON TABLE public.areas TO replicator;



GRANT SELECT ON TABLE public.available_observations TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.available_observations TO verif_meta_rw;



GRANT SELECT ON TABLE public.base_result_orders TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.base_result_orders TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.base_result_orders TO verif_data_rw;



GRANT SELECT ON TABLE public.blend_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.blend_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.blend_forecasts TO replicator;



GRANT SELECT ON TABLE public.blend_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.blend_results TO verif_data_rw;
GRANT SELECT ON TABLE public.blend_results TO replicator;



GRANT SELECT ON TABLE public.bris_preop_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.bris_preop_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.bris_preop_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.bris_preop_results TO verif_data_rw;



GRANT SELECT ON TABLE public.climatology TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.climatology TO verif_data_rw;
GRANT SELECT ON TABLE public.climatology TO replicator;



GRANT SELECT ON TABLE public.climatology_orders TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.climatology_orders TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.climatology_orders TO verif_data_rw;



GRANT SELECT ON SEQUENCE public.climatology_orders_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.climatology_orders_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.climatology_orders_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.climcorecmwf_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.climcorecmwf_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.climcorecmwf_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.climcorecmwf_results TO verif_data_rw;



GRANT SELECT ON TABLE public.climcorhirlam_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.climcorhirlam_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.climcorhirlam_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.climcorhirlam_results TO verif_data_rw;



GRANT SELECT ON TABLE public.climcormeps_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.climcormeps_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.climcormeps_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.climcormeps_results TO verif_data_rw;



GRANT SELECT ON TABLE public.copernicus_nemo_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.copernicus_nemo_results TO verif_data_rw;



GRANT SELECT ON TABLE public.derivative_estimators TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.derivative_estimators TO verif_meta_rw;
GRANT SELECT ON TABLE public.derivative_estimators TO replicator;



GRANT SELECT ON TABLE public.derivative_rvm TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.derivative_rvm TO verif_meta_rw;
GRANT SELECT ON TABLE public.derivative_rvm TO replicator;



GRANT SELECT ON TABLE public.dnncormeps_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.dnncormeps_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.dnncormeps_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.dnncormeps_results TO verif_data_rw;



GRANT SELECT ON TABLE public.dwd_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.dwd_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.dwd_forecasts TO replicator;



GRANT SELECT ON TABLE public.dwd_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.dwd_results TO verif_data_rw;
GRANT SELECT ON TABLE public.dwd_results TO replicator;



GRANT SELECT ON TABLE public.ecmwf_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.ecmwf_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.ecmwf_forecasts TO replicator;



GRANT SELECT ON TABLE public.ecmwf_probability_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.ecmwf_probability_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.ecmwf_probability_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.ecmwf_probability_results TO verif_data_rw;



GRANT SELECT ON TABLE public.ecmwf_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.ecmwf_results TO verif_data_rw;
GRANT SELECT ON TABLE public.ecmwf_results TO replicator;



GRANT SELECT ON TABLE public.ecmwfeps_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.ecmwfeps_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.ecmwfeps_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.ecmwfeps_results TO verif_data_rw;



GRANT SELECT ON TABLE public.estimators TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.estimators TO verif_meta_rw;
GRANT SELECT ON TABLE public.estimators TO replicator;



GRANT SELECT ON SEQUENCE public.estimators_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.estimators_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.estimators_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.localization_entries TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.localization_entries TO verif_meta_rw;
GRANT SELECT ON TABLE public.localization_entries TO replicator;



GRANT SELECT ON TABLE public.localization_languages TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.localization_languages TO verif_meta_rw;
GRANT SELECT ON TABLE public.localization_languages TO replicator;



GRANT SELECT ON TABLE public.localization_translations TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.localization_translations TO verif_meta_rw;
GRANT SELECT ON TABLE public.localization_translations TO replicator;



GRANT SELECT ON TABLE public.estimators_v TO PUBLIC;
GRANT SELECT ON TABLE public.estimators_v TO replicator;



GRANT SELECT ON TABLE public.fid TO replicator;
GRANT SELECT ON TABLE public.fid TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.fid TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.fid TO verif_data_rw;



GRANT SELECT ON TABLE public.forecaster_privileges TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.forecaster_privileges TO verif_meta_rw;
GRANT SELECT ON TABLE public.forecaster_privileges TO replicator;



GRANT SELECT ON SEQUENCE public.forecaster_privileges_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.forecaster_privileges_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.forecaster_privileges_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.forecasterid TO replicator;
GRANT SELECT ON TABLE public.forecasterid TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forecasterid TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forecasterid TO verif_data_rw;



GRANT ALL ON SEQUENCE public.forecasters_id_seq TO verif_data_rw;
GRANT ALL ON SEQUENCE public.forecasters_id_seq TO verif_meta_rw;
GRANT SELECT ON SEQUENCE public.forecasters_id_seq TO verif_ro;



GRANT SELECT ON TABLE public.forecasters TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.forecasters TO verif_meta_rw;
GRANT INSERT ON TABLE public.forecasters TO verif_data_rw;
GRANT SELECT ON TABLE public.forecasters TO replicator;
GRANT SELECT,UPDATE ON TABLE public.forecasters TO verifwww;



GRANT SELECT ON TABLE public.forecasts TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.forecasts TO replicator;



GRANT SELECT ON TABLE public.gfs_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.gfs_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.gfs_forecasts TO replicator;



GRANT SELECT ON TABLE public.gfs_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.gfs_results TO verif_data_rw;
GRANT SELECT ON TABLE public.gfs_results TO replicator;



GRANT SELECT ON TABLE public.grade_colors TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.grade_colors TO verif_data_rw;



GRANT SELECT ON TABLE public.harmonie_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.harmonie_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.harmonie_forecasts TO replicator;



GRANT SELECT ON TABLE public.harmonie_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.harmonie_results TO verif_data_rw;
GRANT SELECT ON TABLE public.harmonie_results TO replicator;



GRANT SELECT ON TABLE public.helsinki_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.helsinki_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.helsinki_forecasts TO replicator;



GRANT SELECT ON TABLE public.helsinki_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.helsinki_results TO verif_data_rw;
GRANT SELECT ON TABLE public.helsinki_results TO replicator;



GRANT SELECT ON TABLE public.hirlam_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.hirlam_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.hirlam_forecasts TO replicator;



GRANT SELECT ON TABLE public.hirlam_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.hirlam_results TO verif_data_rw;
GRANT SELECT ON TABLE public.hirlam_results TO replicator;



GRANT SELECT ON TABLE public.icao_stations TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.icao_stations TO verif_meta_rw;



GRANT SELECT ON TABLE public.icon_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.icon_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.icon_forecasts TO replicator;



GRANT SELECT ON TABLE public.icon_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.icon_results TO verif_data_rw;
GRANT SELECT ON TABLE public.icon_results TO replicator;



GRANT SELECT ON TABLE public.kairosnwc_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.kairosnwc_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.kairosnwc_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.kairosnwc_results TO verif_data_rw;



GRANT SELECT ON TABLE public.laps_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.laps_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.laps_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.laps_results TO verif_data_rw;



GRANT SELECT ON SEQUENCE public.localization_entries_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.localization_entries_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.localization_entries_id_seq TO verif_data_rw;



GRANT SELECT ON SEQUENCE public.localization_languages_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.localization_languages_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.localization_languages_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.location_kinds TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.location_kinds TO verif_data_rw;
GRANT SELECT ON TABLE public.location_kinds TO replicator;



GRANT SELECT ON SEQUENCE public.location_kinds_id_seq TO verif_ro;



GRANT SELECT ON TABLE public.locations TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.locations TO verif_meta_rw;
GRANT SELECT ON TABLE public.locations TO replicator;



GRANT SELECT ON TABLE public.locations_v TO PUBLIC;
GRANT SELECT ON TABLE public.locations_v TO replicator;



GRANT SELECT ON TABLE public.maisemakalmec_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.maisemakalmec_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.maisemakalmec_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.maisemakalmec_results TO verif_data_rw;



GRANT SELECT ON TABLE public.maisemasmartmet_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.maisemasmartmet_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.maisemasmartmet_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.maisemasmartmet_results TO verif_data_rw;



GRANT SELECT ON TABLE public.meps_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.meps_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.meps_forecasts TO replicator;



GRANT SELECT ON TABLE public.meps_ml_preop_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.meps_ml_preop_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.meps_ml_preop_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.meps_ml_preop_results TO verif_data_rw;



GRANT SELECT ON TABLE public.meps_probability_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.meps_probability_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.meps_probability_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.meps_probability_results TO verif_data_rw;



GRANT SELECT ON TABLE public.meps_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.meps_results TO verif_data_rw;
GRANT SELECT ON TABLE public.meps_results TO replicator;



GRANT SELECT ON TABLE public.met_no_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.met_no_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.met_no_forecasts TO replicator;



GRANT SELECT ON TABLE public.met_no_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.met_no_results TO verif_data_rw;
GRANT SELECT ON TABLE public.met_no_results TO replicator;



GRANT SELECT ON TABLE public.metcoopnwc_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.metcoopnwc_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.metcoopnwc_forecasts TO replicator;



GRANT SELECT ON TABLE public.metcoopnwc_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.metcoopnwc_results TO verif_data_rw;



GRANT SELECT ON TABLE public.model_parameter_views TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.model_parameter_views TO verif_meta_rw;



GRANT SELECT ON TABLE public.mos_development_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.mos_development_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.mos_development_forecasts TO replicator;



GRANT SELECT ON TABLE public.mos_development_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.mos_development_results TO verif_data_rw;
GRANT SELECT ON TABLE public.mos_development_results TO replicator;



GRANT SELECT ON TABLE public.mos_production_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.mos_production_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.mos_production_forecasts TO replicator;



GRANT SELECT ON TABLE public.mos_production_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.mos_production_results TO verif_data_rw;
GRANT SELECT ON TABLE public.mos_production_results TO replicator;



GRANT SELECT ON TABLE public.moseckrigingx_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.moseckrigingx_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.moseckrigingx_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.moseckrigingx_results TO verif_data_rw;



GRANT SELECT ON TABLE public.mosecmkriging_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.mosecmkriging_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.mosecmkriging_forecasts TO replicator;



GRANT SELECT ON TABLE public.mosecmkriging_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.mosecmkriging_results TO verif_data_rw;
GRANT SELECT ON TABLE public.mosecmkriging_results TO replicator;



GRANT SELECT ON TABLE public.nemo_mw_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.nemo_mw_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.nemo_mw_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.nemo_mw_results TO verif_data_rw;



GRANT SELECT ON TABLE public.nemo_n2000_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.nemo_n2000_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.nemo_n2000_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.nemo_n2000_results TO verif_data_rw;



GRANT SELECT ON TABLE public.network_map TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.network_map TO verif_meta_rw;
GRANT SELECT ON TABLE public.network_map TO replicator;



GRANT ALL ON SEQUENCE public.network_map_id_seq TO verif_meta_rw;
GRANT SELECT ON SEQUENCE public.network_map_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.network_map_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.networks TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.networks TO verif_meta_rw;
GRANT SELECT ON TABLE public.networks TO replicator;



GRANT SELECT ON SEQUENCE public.networks_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.networks_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.networks_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.oaasecmwf_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.oaasecmwf_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.oaasecmwf_forecasts TO replicator;



GRANT SELECT ON TABLE public.oaasecmwf_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.oaasecmwf_results TO verif_data_rw;
GRANT SELECT ON TABLE public.oaasecmwf_results TO replicator;



GRANT SELECT ON TABLE public.oaashirlam_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.oaashirlam_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.oaashirlam_forecasts TO replicator;



GRANT SELECT ON TABLE public.oaashirlam_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.oaashirlam_results TO verif_data_rw;
GRANT SELECT ON TABLE public.oaashirlam_results TO replicator;



GRANT SELECT ON TABLE public.observation_endwind_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.observation_endwind_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.observation_endwind_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.observation_endwind_results TO verif_data_rw;



GRANT SELECT ON TABLE public.observation_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.observation_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.observation_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.observation_results TO verif_data_rw;



GRANT SELECT ON TABLE public.pangu_weather_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.pangu_weather_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.pangu_weather_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.pangu_weather_results TO verif_data_rw;



GRANT SELECT ON TABLE public.parameter_class_limits TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.parameter_class_limits TO verif_meta_rw;
GRANT SELECT ON TABLE public.parameter_class_limits TO replicator;



GRANT SELECT ON TABLE public.parameter_map TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.parameter_map TO verif_meta_rw;
GRANT SELECT ON TABLE public.parameter_map TO replicator;



GRANT ALL ON SEQUENCE public.parameter_map_id_seq TO verif_meta_rw;
GRANT SELECT ON SEQUENCE public.parameter_map_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.parameter_map_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.parameters TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.parameters TO verif_meta_rw;
GRANT SELECT ON TABLE public.parameters TO replicator;



GRANT SELECT ON SEQUENCE public.parameters_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.parameters_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.parameters_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.parameters_v TO PUBLIC;
GRANT SELECT ON TABLE public.parameters_v TO replicator;



GRANT SELECT ON TABLE public.peps_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.peps_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.peps_forecasts TO replicator;



GRANT SELECT ON TABLE public.peps_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.peps_results TO verif_data_rw;
GRANT SELECT ON TABLE public.peps_results TO replicator;



GRANT SELECT ON TABLE public.period_types TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.period_types TO verif_meta_rw;
GRANT SELECT ON TABLE public.period_types TO replicator;



GRANT SELECT ON SEQUENCE public.period_types_id_seq TO verif_ro;



GRANT SELECT ON TABLE public.periods TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.periods TO verif_meta_rw;
GRANT INSERT,DELETE,UPDATE ON TABLE public.periods TO verif_data_rw;
GRANT SELECT ON TABLE public.periods TO replicator;



GRANT SELECT ON SEQUENCE public.periods_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.periods_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.periods_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.producers TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.producers TO verif_meta_rw;
GRANT SELECT ON TABLE public.producers TO replicator;



GRANT SELECT ON TABLE public.producers_v TO PUBLIC;
GRANT SELECT ON TABLE public.producers_v TO replicator;



GRANT SELECT ON TABLE public.result_orders TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.result_orders TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.result_orders TO verif_data_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.result_orders TO verifwww;
GRANT SELECT ON TABLE public.result_orders TO replicator;



GRANT SELECT ON SEQUENCE public.result_orders_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.result_orders_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.result_orders_id_seq TO verif_data_rw;
GRANT SELECT,USAGE ON SEQUENCE public.result_orders_id_seq TO verifwww;



GRANT SELECT ON TABLE public.result_parameter_views TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.result_parameter_views TO verif_meta_rw;



GRANT SELECT ON TABLE public.road_sections TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.road_sections TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.road_sections TO verif_data_rw;



GRANT SELECT ON TABLE public.sea_level_warning_limits TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.sea_level_warning_limits TO verif_meta_rw;



GRANT SELECT ON TABLE public.smartmet_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smartmet_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.smartmet_forecasts TO replicator;



GRANT ALL ON TABLE public.smartmet_forecasts_v TO verifadmin;
GRANT SELECT ON TABLE public.smartmet_forecasts_v TO PUBLIC;



GRANT SELECT ON TABLE public.smartmet_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smartmet_results TO verif_data_rw;
GRANT SELECT ON TABLE public.smartmet_results TO replicator;



GRANT ALL ON TABLE public.smartmet_results_v TO verifadmin;
GRANT SELECT ON TABLE public.smartmet_results_v TO PUBLIC;



GRANT SELECT ON TABLE public.smartmetnwc_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smartmetnwc_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.smartmetnwc_forecasts TO replicator;



GRANT SELECT ON TABLE public.smartmetnwc_preop_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smartmetnwc_preop_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.smartmetnwc_preop_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smartmetnwc_preop_results TO verif_data_rw;



GRANT SELECT ON TABLE public.smartmetnwc_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smartmetnwc_results TO verif_data_rw;



GRANT SELECT ON TABLE public.smhi_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smhi_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.smhi_forecasts TO replicator;



GRANT SELECT ON TABLE public.smhi_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.smhi_results TO verif_data_rw;
GRANT SELECT ON TABLE public.smhi_results TO replicator;



GRANT SELECT ON TABLE public.special_observations TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.special_observations TO verif_data_rw;
GRANT SELECT ON TABLE public.special_observations TO replicator;



GRANT SELECT ON TABLE public.target_level_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.target_level_results TO verif_data_rw;
GRANT SELECT ON TABLE public.target_level_results TO replicator;



GRANT SELECT ON TABLE public.target_types TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.target_types TO verif_meta_rw;
GRANT SELECT ON TABLE public.target_types TO replicator;



GRANT SELECT ON SEQUENCE public.target_types_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.target_types_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.target_types_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.targetgroup_map TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.targetgroup_map TO verif_meta_rw;
GRANT SELECT ON TABLE public.targetgroup_map TO replicator;



GRANT SELECT ON TABLE public.targetgroups TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.targetgroups TO verif_meta_rw;
GRANT SELECT ON TABLE public.targetgroups TO replicator;



GRANT SELECT ON TABLE public.targetgroups_v TO PUBLIC;
GRANT SELECT ON TABLE public.targetgroups_v TO replicator;



GRANT SELECT ON TABLE public.targets TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.targets TO verif_meta_rw;
GRANT SELECT ON TABLE public.targets TO replicator;



GRANT SELECT ON TABLE public.targets_v TO PUBLIC;
GRANT SELECT ON TABLE public.targets_v TO replicator;



GRANT SELECT ON TABLE public.temp_load TO replicator;
GRANT SELECT ON TABLE public.temp_load TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.temp_load TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.temp_load TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_hila_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_hila_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_hila_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_hila_results TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_lentokentta_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_lentokentta_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_lentokentta_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_lentokentta_results TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_piste_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_piste_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_piste_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_piste_results TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_tiejakso_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_tiejakso_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.tiesaa_tiejakso_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.tiesaa_tiejakso_results TO verif_data_rw;



GRANT SELECT ON TABLE public.ui_sort_order TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ui_sort_order TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ui_sort_order TO verif_data_rw;
GRANT SELECT ON TABLE public.ui_sort_order TO replicator;



GRANT SELECT ON TABLE public.used_area_result_estimators TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_area_result_estimators TO verif_data_rw;



GRANT SELECT ON TABLE public.used_area_result_hours TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_area_result_hours TO verif_data_rw;



GRANT SELECT ON TABLE public.used_area_result_targets TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_area_result_targets TO verif_data_rw;
GRANT SELECT ON TABLE public.used_area_result_targets TO replicator;



GRANT SELECT ON TABLE public.used_group_result_estimators TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_group_result_estimators TO verif_data_rw;



GRANT SELECT ON TABLE public.used_group_result_hours TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_group_result_hours TO verif_data_rw;



GRANT SELECT ON TABLE public.used_group_result_targets TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_group_result_targets TO verif_data_rw;
GRANT SELECT ON TABLE public.used_group_result_targets TO replicator;



GRANT SELECT ON TABLE public.used_location_result_estimators TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_location_result_estimators TO verif_data_rw;



GRANT SELECT ON TABLE public.used_location_result_groups TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_location_result_groups TO verif_data_rw;



GRANT SELECT ON TABLE public.used_location_result_hours TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_location_result_hours TO verif_data_rw;



GRANT SELECT ON TABLE public.used_location_result_targets TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_location_result_targets TO verif_data_rw;
GRANT SELECT ON TABLE public.used_location_result_targets TO replicator;



GRANT SELECT ON TABLE public.used_model_areas TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_model_areas TO verif_data_rw;
GRANT SELECT ON TABLE public.used_model_areas TO replicator;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_model_areas TO verif_meta_rw;



GRANT SELECT ON TABLE public.used_model_groups TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_model_groups TO verif_data_rw;
GRANT SELECT ON TABLE public.used_model_groups TO replicator;



GRANT SELECT ON TABLE public.used_model_hours TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_model_hours TO verif_data_rw;
GRANT SELECT ON TABLE public.used_model_hours TO replicator;



GRANT SELECT ON TABLE public.used_model_locations TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_model_locations TO verif_data_rw;
GRANT SELECT ON TABLE public.used_model_locations TO replicator;



GRANT SELECT ON TABLE public.used_zero_limit_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.used_zero_limit_results TO verif_data_rw;



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_view_settings TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.user_view_settings TO verif_meta_rw;
GRANT SELECT ON TABLE public.user_view_settings TO replicator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_view_settings TO verifwww;



GRANT SELECT ON TABLE public.vire_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.vire_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.vire_preop_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.vire_preop_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.vire_preop_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.vire_preop_results TO verif_data_rw;



GRANT SELECT ON TABLE public.vire_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.vire_results TO verif_data_rw;



GRANT SELECT ON TABLE public.virenwc_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.virenwc_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.virenwc_forecasts TO replicator;



GRANT SELECT ON TABLE public.virenwc_preop_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.virenwc_preop_forecasts TO verif_data_rw;
GRANT SELECT ON TABLE public.virenwc_preop_forecasts TO replicator;



GRANT SELECT ON TABLE public.virenwc_preop_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.virenwc_preop_results TO verif_data_rw;



GRANT SELECT ON TABLE public.virenwc_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.virenwc_results TO verif_data_rw;



GRANT SELECT ON TABLE public.warning_levels TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.warning_levels TO verif_data_rw;
GRANT SELECT ON TABLE public.warning_levels TO replicator;
GRANT INSERT,DELETE,UPDATE ON TABLE public.warning_levels TO verif_meta_rw;



GRANT SELECT ON TABLE public.warning_rule_conditions TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.warning_rule_conditions TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.warning_rule_conditions TO verif_data_rw;



GRANT SELECT ON TABLE public.warning_rules TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.warning_rules TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.warning_rules TO verif_data_rw;



GRANT SELECT ON TABLE public.wasp_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wasp_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.wasp_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wasp_results TO verif_data_rw;



GRANT SELECT ON TABLE public.waveecmwf_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.waveecmwf_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.waveecmwf_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.waveecmwf_results TO verif_data_rw;



GRANT SELECT ON TABLE public.wavefmiecmwf_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wavefmiecmwf_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.wavefmiecmwf_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wavefmiecmwf_results TO verif_data_rw;



GRANT SELECT ON TABLE public.wavefmiharmonie_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wavefmiharmonie_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.wavefmiharmonie_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wavefmiharmonie_results TO verif_data_rw;



GRANT SELECT ON TABLE public.wavefmihirlam_forecasts TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wavefmihirlam_forecasts TO verif_data_rw;



GRANT SELECT ON TABLE public.wavefmihirlam_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.wavefmihirlam_results TO verif_data_rw;



GRANT SELECT ON TABLE public.wind_correction_coefficients TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_correction_coefficients TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_correction_coefficients TO verif_data_rw;
GRANT SELECT ON TABLE public.wind_correction_coefficients TO replicator;



GRANT ALL ON SEQUENCE public.wind_correction_coefficients_id_seq TO verif_data_rw;
GRANT SELECT ON SEQUENCE public.wind_correction_coefficients_id_seq TO verif_ro;



GRANT SELECT ON TABLE public.wind_correction_sets TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_correction_sets TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_correction_sets TO verif_data_rw;
GRANT SELECT ON TABLE public.wind_correction_sets TO replicator;



GRANT SELECT ON SEQUENCE public.wind_correction_sets_id_seq TO verif_ro;
GRANT ALL ON SEQUENCE public.wind_correction_sets_id_seq TO verif_meta_rw;
GRANT ALL ON SEQUENCE public.wind_correction_sets_id_seq TO verif_data_rw;



GRANT SELECT ON TABLE public.wind_roughness TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_roughness TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_roughness TO verif_data_rw;



GRANT SELECT ON TABLE public.wind_roughness_sea_validity TO verif_ro;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_roughness_sea_validity TO verif_meta_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wind_roughness_sea_validity TO verif_data_rw;



GRANT SELECT ON TABLE public.zero_limit_results TO verif_ro;
GRANT INSERT,DELETE,UPDATE ON TABLE public.zero_limit_results TO verif_data_rw;



ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO verifadmin;



