CREATE SCHEMA IF NOT EXISTS womens_dept;

CREATE ROLE womens_dept_rw;   -- read/write bucket
CREATE ROLE womens_dept_ro;   -- read-only bucket


REVOKE ALL ON SCHEMA public FROM PUBLIC;

GRANT USAGE ON SCHEMA womens_dept TO womens_dept_ro, womens_dept_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA womens_dept
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO womens_dept_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA womens_dept
  GRANT SELECT ON TABLES TO womens_dept_ro;

ALTER DEFAULT PRIVILEGES IN SCHEMA womens_dept
  GRANT USAGE, SELECT ON SEQUENCES TO womens_dept_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA womens_dept
  GRANT SELECT ON SEQUENCES TO womens_dept_ro;


