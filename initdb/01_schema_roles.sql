SET search_path = hospital, public;

CREATE SCHEMA IF NOT EXISTS hospital;

CREATE ROLE hospital_rw;   -- read/write bucket
CREATE ROLE hospital_ro;   -- read-only bucket


REVOKE ALL ON SCHEMA public FROM PUBLIC;

GRANT USAGE ON SCHEMA hospital TO hospital_ro, hospital_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA hospital
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO hospital_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA hospital
  GRANT SELECT ON TABLES TO hospital_ro;

ALTER DEFAULT PRIVILEGES IN SCHEMA hospital
  GRANT USAGE, SELECT ON SEQUENCES TO hospital_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA hospital
  GRANT SELECT ON SEQUENCES TO hospital_ro;