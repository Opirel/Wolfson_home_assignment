-- =========================================================
-- Women’s Department — core objects (schema, tables, FKs)
-- =========================================================

-- Work in our schema (create if someone deleted it)
CREATE SCHEMA IF NOT EXISTS womens_dept;
SET search_path = womens_dept, public;

-- 0) Weekday enum (create if missing)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'weekday') THEN
    CREATE TYPE weekday AS ENUM
      ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');
  END IF;
END$$;

-- 1) Doctors
CREATE TABLE IF NOT EXISTS doctors (
  doctor_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  doctor_name         VARCHAR(100) NOT NULL,
  doctor_phone_number CHAR(10) UNIQUE NOT NULL CHECK (doctor_phone_number ~ '^05[0-9]{8}$'),
  specialization      VARCHAR(80),
  employment_status   TEXT NOT NULL DEFAULT 'Active'
    CHECK (employment_status IN ('Active','OnLeave','Terminated'))
);

-- 2) Nurses
CREATE TABLE IF NOT EXISTS nurses (
  nurse_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nurse_name         VARCHAR(100) NOT NULL,
  nurse_phone_number CHAR(10) UNIQUE NOT NULL CHECK (nurse_phone_number ~ '^05[0-9]{8}$'),
  nurse_sex          TEXT CHECK (nurse_sex IN ('Male','Female','Intersex','Unknown')),
  nurse_gender       TEXT CHECK (nurse_gender IN ('Male','Female','Nonbinary','Other','PreferNotToSay','Unknown')),
  employment_status  TEXT NOT NULL DEFAULT 'Active'
    CHECK (employment_status IN ('Active','OnLeave','Terminated'))
);

-- 3) Weekly schedules (one row per person per day)
CREATE TABLE IF NOT EXISTS doctor_schedule (
  schedule_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  doctor_id   INT NOT NULL REFERENCES doctors(doctor_id) ON DELETE CASCADE,
  work_day    weekday NOT NULL,
  UNIQUE (doctor_id, work_day)
);

CREATE TABLE IF NOT EXISTS nurse_schedule (
  schedule_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nurse_id    INT NOT NULL REFERENCES nurses(nurse_id) ON DELETE CASCADE,
  work_day    weekday NOT NULL,
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

