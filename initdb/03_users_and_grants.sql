-- Use the schema first in this session
SET search_path = womens_dept;


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'womens_dept_rw') THEN
    CREATE ROLE womens_dept_rw;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'womens_dept_ro') THEN
    CREATE ROLE womens_dept_ro;
  END IF;
END$$;




-- App server: needs read/write to all business tables
CREATE ROLE app_backend LOGIN PASSWORD '(!want2code)';
GRANT womens_dept_rw TO app_backend;

-- Read-only analyst (can only read)
CREATE ROLE analyst_ro LOGIN PASSWORD '^letMeCData*';
GRANT womens_dept_ro TO analyst_ro;

-- Example clinician accounts (read-only)
CREATE ROLE dr_rosen_user   LOGIN PASSWORD 'Rose2Heal*';
CREATE ROLE nurse_cohen_user LOGIN PASSWORD '2C0hen4U';
GRANT womens_dept_ro TO dr_rosen_user;
GRANT womens_dept_ro TO nurse_cohen_user;

-- Quality-of-life: set default search_path for these users in this DB

ALTER ROLE app_backend SET search_path = 'womens_dept, public';
ALTER ROLE analyst_ro SET search_path = 'womens_dept, public';

-- Apply grants to existing objects (defaults only affect NEW tables)
-- If tables already exist, explicitly grant now:
GRANT USAGE ON SCHEMA womens_dept TO womens_dept_ro, womens_dept_rw;

GRANT SELECT ON ALL TABLES     IN SCHEMA womens_dept TO womens_dept_ro;
GRANT SELECT ON ALL SEQUENCES  IN SCHEMA womens_dept TO womens_dept_ro;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA womens_dept TO womens_dept_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA womens_dept TO womens_dept_rw;

-- ensure every session connecting to WomensDeptDB uses womens_dept first
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'WomensDeptDB') THEN
    EXECUTE 'ALTER DATABASE "WomensDeptDB" SET search_path = ''womens_dept, public''';
  END IF;
END
$$ LANGUAGE plpgsql;

-- After creating roles/grants: ensure each login role has a persistent search_path
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT rolname FROM pg_roles WHERE rolcanlogin LOOP
    -- idempotent: set role-level default to the desired textual search_path
    BEGIN
      EXECUTE format('ALTER ROLE %I SET search_path = %L', r.rolname, 'womens_dept, public');
    EXCEPTION WHEN others THEN
      -- ignore failures for roles we cannot alter in this context
      RAISE NOTICE 'Could not set search_path for role %', r.rolname;
    END;
  END LOOP;
END
$$ LANGUAGE plpgsql;


