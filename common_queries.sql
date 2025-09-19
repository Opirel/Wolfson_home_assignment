-- Copy‑paste ready verification queries for WomensDeptDB
-- Usage: docker exec -it WomensDeptCont psql -U postgres -d "WomensDeptDB" -f /docker-entrypoint-initdb.d/commun_searches.sql
-- Or paste blocks below directly into a psql prompt.

-- 1) Session info
SELECT current_database() AS db, current_user AS user, current_setting('search_path') AS search_path;

-- 2) Schema/table inventory
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'womens_dept'
ORDER BY table_name;

-- 3) Row counts
SELECT 'doctors' AS table_name, count(*) FROM womens_dept.doctors;
SELECT 'nurses' AS table_name, count(*) FROM womens_dept.nurses;
SELECT 'doctor_schedule' AS table_name, count(*) FROM womens_dept.doctor_schedule;
SELECT 'nurse_schedule' AS table_name, count(*) FROM womens_dept.nurse_schedule;
SELECT 'audit_log' AS table_name, count(*) FROM womens_dept.audit_log;

-- 4) Sample rows
SELECT * FROM womens_dept.doctors ORDER BY doctor_id LIMIT 10;
SELECT * FROM womens_dept.nurses ORDER BY nurse_id LIMIT 10;

-- 5) Schedules with people (joins)
SELECT ds.schedule_id, ds.work_day, d.doctor_id, d.doctor_name
FROM womens_dept.doctor_schedule ds
JOIN womens_dept.doctors d USING (doctor_id)
ORDER BY d.doctor_id, ds.work_day
LIMIT 50;

SELECT ns.schedule_id, ns.work_day, n.nurse_id, n.nurse_name
FROM womens_dept.nurse_schedule ns
JOIN womens_dept.nurses n USING (nurse_id)
ORDER BY n.nurse_id, ns.work_day
LIMIT 50;

-- 6) FK/orphan checks (should return 0 rows)
SELECT ds.*
FROM womens_dept.doctor_schedule ds
LEFT JOIN womens_dept.doctors d ON ds.doctor_id = d.doctor_id
WHERE d.doctor_id IS NULL;

SELECT ns.*
FROM womens_dept.nurse_schedule ns
LEFT JOIN womens_dept.nurses n ON ns.nurse_id = n.nurse_id
WHERE n.nurse_id IS NULL;

-- 7) Enum values
SELECT unnest(enum_range(NULL::womens_dept.weekday)) AS weekday;

-- 8) Indexes
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'womens_dept'
ORDER BY tablename, indexname;

-- 9) Sequences / identity info
SELECT table_name, column_name, pg_get_serial_sequence(format('%I.%I', table_schema, table_name), column_name) AS seq_name
FROM information_schema.columns
WHERE table_schema = 'womens_dept' AND (column_default LIKE 'nextval(%' OR is_identity = 'YES')
ORDER BY table_name;

-- 10) Role & DB search_path settings
SELECT rolname, rolconfig FROM pg_roles WHERE rolcanlogin ORDER BY rolname;
SELECT datname, unnest(setconfig) AS config
FROM pg_db_role_setting
JOIN pg_database ON pg_database.oid = pg_db_role_setting.setdatabase
WHERE datname = 'WomensDeptDB';

-- 11) Quick health / unqualified selects (depends on search_path)
SELECT count(*) FROM doctors;                -- expects search_path to include womens_dept
SELECT count(*) FROM womens_dept.doctors;    -- always works

-- 12) Recent audit entries (if present)
SELECT * FROM womens_dept.audit_log ORDER BY created_at DESC LIMIT 25;