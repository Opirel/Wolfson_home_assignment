-- Use the schema first in this session
SET search_path = hospital, public;


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_rw') THEN
    CREATE ROLE hospital_rw;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hospital_ro') THEN
    CREATE ROLE hospital_ro;
  END IF;
END$$;




-- App server: needs read/write to all business tables
CREATE ROLE app_backend LOGIN PASSWORD '(!want2code)';
GRANT hospital_rw TO app_backend;

-- Read-only analyst (can only read)
CREATE ROLE analyst_ro LOGIN PASSWORD '^letMeCData*';
GRANT hospital_ro TO analyst_ro;

-- Example clinician accounts (read-only)
CREATE ROLE dr_rosen_user   LOGIN PASSWORD 'Rose2Heal*';
CREATE ROLE nurse_cohen_user LOGIN PASSWORD '2C0hen4U';
GRANT hospital_ro TO dr_rosen_user;
GRANT hospital_ro TO nurse_cohen_user;

-- Quality-of-life: set default search_path for these users in this DB
-- (shortens object names, avoids needing hospital.* everywhere)
ALTER ROLE app_backend     IN DATABASE womens_dept SET search_path = hospital, public;
ALTER ROLE analyst_ro      IN DATABASE womens_dept SET search_path = hospital, public;
ALTER ROLE dr_rosen_user   IN DATABASE womens_dept SET search_path = hospital, public;
ALTER ROLE nurse_cohen_user IN DATABASE womens_dept SET search_path = hospital, public;

-- Apply grants to existing objects (defaults only affect NEW tables)
-- If tables already exist, explicitly grant now:
GRANT USAGE ON SCHEMA hospital TO hospital_ro, hospital_rw;

GRANT SELECT ON ALL TABLES     IN SCHEMA hospital TO hospital_ro;
GRANT SELECT ON ALL SEQUENCES  IN SCHEMA hospital TO hospital_ro;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA hospital TO hospital_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA hospital TO hospital_rw;


