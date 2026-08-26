-- Runs on verifapi as postgres (superuser) after the production schema and the
-- ownership transfer.
--
-- Reference data the applications require in every deployment. These are not
-- customer metadata: the names below are compiled into the GUI, so a database
-- without them yields a broken installation rather than an empty one.
--
-- target_types: TargetTypeRadioGroup preselects GROUP, then AREA, then LOCATION,
-- and leaves the radio group unset when it finds none of them. Every query form
-- then switches on the selected name, so an empty table makes the switch throw
--   Cannot invoke "String.hashCode()" because "<local>" is null
-- on the first view the user opens. Nineteen GUI classes reach that switch, so
-- the whole interface is affected, not one view.
--
-- Idempotent on purpose. The test image (Dockerfile.test) loads the same rows
-- from csv/metadata/target_types.csv in 0003-legacy-test-data.sql, which runs
-- first; without ON CONFLICT this file would abort that build on the unique
-- name index.

INSERT INTO public.target_types (id, name)
VALUES (1, 'LOCATION'),
       (2, 'GROUP'),
       (3, 'AREA')
ON CONFLICT DO NOTHING;

-- The id column defaults to nextval() on this sequence. The rows above set ids
-- explicitly, which does not advance it, so without this a later insert that
-- omits the id would collide with id 1.
SELECT setval('public.target_types_id_seq', (SELECT max(id) FROM public.target_types));
