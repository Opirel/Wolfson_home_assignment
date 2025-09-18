-- Use the schema first in this session
SET search_path = womens_dept, public;


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

-- GRANT womens_dept_rw TO app_backend;    -- removed duplicate
GRANT womens_dept_ro TO analyst_ro;

-- Replace per-database ALTER ROLE statements (which referenced a non-existent DB)
-- with global role settings:
ALTER ROLE app_backend SET search_path = womens_dept, public;
ALTER ROLE analyst_ro SET search_path = womens_dept, public;

-- Apply grants to existing objects (defaults only affect NEW tables)
-- If tables already exist, explicitly grant now:
GRANT USAGE ON SCHEMA womens_dept TO womens_dept_ro, womens_dept_rw;

GRANT SELECT ON ALL TABLES     IN SCHEMA womens_dept TO womens_dept_ro;
GRANT SELECT ON ALL SEQUENCES  IN SCHEMA womens_dept TO womens_dept_ro;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA womens_dept TO womens_dept_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA womens_dept TO womens_dept_rw;


