-- =========================================================
-- Women’s Department — core objects (schema, tables, FKs)
-- =========================================================

-- Work in our schema (create if someone deleted it)
CREATE SCHEMA IF NOT EXISTS womens_dept;
SET search_path = womens_dept;

-- 0) Weekday enum (create if missing)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'weekday') THEN
    CREATE TYPE weekday AS ENUM
      ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');
  END IF;
END
$$;

-- 1) ensure weekday enum exists (keep before any table using it)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'weekday' AND n.nspname = 'womens_dept'
  ) THEN
    EXECUTE $type$
      CREATE TYPE womens_dept.weekday AS ENUM (
        'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
      );
    $type$;
  END IF;
END
$$ LANGUAGE plpgsql;

-- 2) core tables: create doctors and nurses first (ensure these exist before schedules)
CREATE TABLE IF NOT EXISTS womens_dept.doctors (
  doctor_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  doctor_name TEXT NOT NULL,
  doctor_phone_number TEXT UNIQUE,
  doctor_sex TEXT,
  doctor_gender TEXT,
  specialization TEXT,
  employment_status TEXT
);

CREATE TABLE IF NOT EXISTS womens_dept.nurses (
  nurse_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nurse_name TEXT NOT NULL,
  nurse_phone_number TEXT UNIQUE,
  nurse_sex TEXT,
  nurse_gender TEXT,
  employment_status TEXT
);

-- 3) schedule tables: reference namespaced tables and namespaced enum
CREATE TABLE IF NOT EXISTS womens_dept.doctor_schedule (
  schedule_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  doctor_id   INT NOT NULL REFERENCES womens_dept.doctors(doctor_id) ON DELETE CASCADE,
  work_day    womens_dept.weekday NOT NULL,
  UNIQUE (doctor_id, work_day)
);

CREATE TABLE IF NOT EXISTS womens_dept.nurse_schedule (
  schedule_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nurse_id    INT NOT NULL REFERENCES womens_dept.nurses(nurse_id) ON DELETE CASCADE,
  work_day    womens_dept.weekday NOT NULL,
  UNIQUE (nurse_id, work_day)
);

-- 4) Bed catalog (each physical bed exactly once)
CREATE TABLE IF NOT EXISTS wards_and_rooms (
  ward VARCHAR(3) NOT NULL CHECK (ward IN ('A','B','C')),
  room SMALLINT   NOT NULL CHECK (room BETWEEN 1 AND 4),
  bed  SMALLINT   NOT NULL CHECK (bed  BETWEEN 1 AND 4),
  CONSTRAINT wards_and_rooms_pkey PRIMARY KEY (ward, room, bed)
);

-- Seed beds: Wards A–C, rooms 1–4, beds 1–4 (48 total)
INSERT INTO wards_and_rooms (ward, room, bed)
SELECT w, r, b
FROM (VALUES ('A'),('B'),('C')) AS W(w)
CROSS JOIN generate_series(1,4) AS r
CROSS JOIN generate_series(1,4) AS b
ON CONFLICT DO NOTHING;

-- 5) Patients (demographics; PII checks)
CREATE TABLE IF NOT EXISTS patient_info (
  patient_id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_national_id     CHAR(9)  UNIQUE NOT NULL CHECK (patient_national_id ~ '^[0-9]{9}$'),
  patient_name            VARCHAR(100) NOT NULL,
  patient_phone_number    CHAR(10) UNIQUE NOT NULL CHECK (patient_phone_number ~ '^05[0-9]{8}$'),
  date_of_birth           DATE NOT NULL,
  blood_type              VARCHAR(5) NOT NULL CHECK (blood_type IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  insurance_number        CHAR(10) UNIQUE NOT NULL CHECK (insurance_number ~ '^[0-9]{10}$'),
  emergency_contact_name  VARCHAR(100),
  emergency_contact_phone CHAR(10) CHECK (emergency_contact_phone ~ '^05[0-9]{8}$')
);

-- 6) Admissions (who is where, when, with which doctor)
CREATE TABLE IF NOT EXISTS patient_admissions (
  admission_id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id          INT NOT NULL REFERENCES patient_info(patient_id) ON DELETE RESTRICT,
  attending_doctor_id INT REFERENCES doctors(doctor_id) ON DELETE SET NULL,
  ward VARCHAR(3) NOT NULL,
  room SMALLINT   NOT NULL CHECK (room BETWEEN 1 AND 4),
  bed  SMALLINT   NOT NULL CHECK (bed  BETWEEN 1 AND 4),
  admission_date DATE NOT NULL DEFAULT CURRENT_DATE,
  discharge_date DATE,
  admission_reason VARCHAR(200),
  CHECK (discharge_date IS NULL OR discharge_date >= admission_date),
  FOREIGN KEY (ward, room, bed)
    REFERENCES wards_and_rooms(ward, room, bed)
      ON UPDATE CASCADE ON DELETE RESTRICT
);

-- add encrypted columns (bytea) and helper wrapper functions
ALTER TABLE IF EXISTS womens_dept.doctors
  ADD COLUMN IF NOT EXISTS doctor_phone_enc bytea;

ALTER TABLE IF EXISTS womens_dept.nurses
  ADD COLUMN IF NOT EXISTS nurse_phone_enc bytea;

-- helper SQL functions that accept a key (caller supplies key at runtime)
CREATE OR REPLACE FUNCTION womens_dept.encrypt_text(plain text, key text) RETURNS bytea AS $$
  SELECT pgp_sym_encrypt(plain, key);
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION womens_dept.decrypt_text(enc bytea, key text) RETURNS text AS $$
  SELECT pgp_sym_decrypt(enc, key);
$$ LANGUAGE SQL IMMUTABLE;

-- optional convenience view that requires key at runtime via session parameter ( safer: pass key to functions )

