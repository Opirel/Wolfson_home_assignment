-- create audit table and generic trigger function for womens_dept
CREATE TABLE IF NOT EXISTS womens_dept.audit_log (
  audit_id   bigserial PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  username   text,
  operation  text,
  schema_name text,
  table_name text,
  old_row    jsonb,
  new_row    jsonb,
  note       text
);

CREATE OR REPLACE FUNCTION womens_dept.f_audit() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO womens_dept.audit_log(username, operation, schema_name, table_name, new_row)
    VALUES (current_user, TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME, to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO womens_dept.audit_log(username, operation, schema_name, table_name, old_row, new_row)
    VALUES (current_user, TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO womens_dept.audit_log(username, operation, schema_name, table_name, old_row)
    VALUES (current_user, TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME, to_jsonb(OLD));
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- attach triggers idempotently to core tables
DO $$
DECLARE
  tbl text;
  tbls text[] := ARRAY['doctors','nurses','patient_info','patient_admissions','wards_and_rooms'];
  trg  text;
BEGIN
  FOREACH tbl IN ARRAY tbls LOOP
    trg := 'audit_' || tbl || '_trigger';
    IF NOT EXISTS (
      SELECT 1
      FROM pg_trigger t
      JOIN pg_class c ON t.tgrelid = c.oid
      JOIN pg_namespace n ON c.relnamespace = n.oid
      WHERE t.tgname = trg AND n.nspname = 'womens_dept'
    ) THEN
      EXECUTE format(
        'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON womens_dept.%I FOR EACH ROW EXECUTE FUNCTION womens_dept.f_audit()',
        trg, tbl
      );
    END IF;
  END LOOP;
END
$$ LANGUAGE plpgsql;

-- Ensure any DO blocks explicitly declare plpgsql (defensive)
DO $$
BEGIN
  -- audit setup logic...
  NULL;
END
$$ LANGUAGE plpgsql;