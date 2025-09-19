-- Ensure DB default search_path is set correctly for WomensDeptDB (idempotent)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'WomensDeptDB') THEN
    EXECUTE 'ALTER DATABASE "WomensDeptDB" SET search_path = ''womens_dept, public''';
  END IF;
END
$$ LANGUAGE plpgsql;