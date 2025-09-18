-- ensure we insert into the correct schema
SET search_path = womens_dept, public;

-- fail fast if core tables weren't created
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'womens_dept' AND table_name = 'doctors'
  ) THEN
    RAISE EXCEPTION 'Table womens_dept.doctors does not exist — check 03_core_tables.sql';
  END IF;
END$$;

-- ---------- Doctors ----------
INSERT INTO doctors (doctor_name, doctor_phone_number, specialization, employment_status) VALUES
 ('Dr. Miriam Levi',   '0523456781', 'Maternal-Fetal Medicine', 'Active'),
 ('Dr. Talia Rosen',   '0549876543', 'Gynecologic Oncology',     'Active'),
 ('Dr. Daniel Peretz', '0501234567', 'Obstetrics',               'Active'),
 ('Dr. Yael Shapira',  '0537654321', 'Breast Oncology',          'Active'),
 ('Dr. Ron Golan',     '0581122334', 'Urogynecology',            'Active'),
 ('Dr. Maya Bar-On',   '0559988776', 'Reproductive Endocrinology','Active'),
 ('Dr. Amir Cohen',    '0564433221', 'General Gynecology',       'Active'),
 ('Dr. Noga Adler',    '0575566778', 'Gynecologic Surgery',      'OnLeave')
ON CONFLICT (doctor_phone_number) DO NOTHING;

-- ---------- Nurses (includes the four you mentioned) ----------
INSERT INTO nurses (nurse_name, nurse_phone_number, nurse_sex, nurse_gender, employment_status) VALUES
  ('Nurse Cohen',     '0521112233', 'Female','Female','Active'),
  ('Nurse Levi',      '0542223344', 'Female','Female','Active'),
  ('Nurse Shahar',    '0503334455', 'Female','Female','Active'),
  ('Nurse Ben Ami',   '0534445566', 'Female','Female','Active'),
  ('Nurse Azulay',    '0585556677', 'Female','Female','Active'),
  ('Nurse Peretz',    '0556667788', 'Female','Female','Active'),
  ('Nurse Shapira',   '0567778899', 'Female','Female','Active'),
  ('Nurse Bar-On',    '0578889900', 'Female','Female','Active'),
  ('Nurse Golan',     '0529990011', 'Male','Male','Active'),
  ('Nurse Adler',     '0540001122', 'Female','Female','Active'),
  ('Nurse Hadar',     '0501113344', 'Male','Male','Active'),
  ('Nurse Lavi',      '0532224455', 'Female','Female','Active'),
  ('Nurse Tal',       '0583335566', 'Female','Female','Active'),
  ('Nurse Yaari',     '0554446677', 'Female','Female','Active'),
  ('Nurse Regev',     '0565557788', 'Female','Female','Active'),
  ('Nurse Rimon',     '0576668899', 'Female','Female','Active'),
  ('Nurse Aviv',      '0527779900', 'Female','Female','Active'),
  ('Nurse Gal',       '0548880011', 'Male','Male','Active'),
  ('Nurse Eden',      '0509991122', 'Female','Female','Active'),
  ('Nurse Maayan',    '0530002233', 'Female','Female','Active')
ON CONFLICT (nurse_phone_number) DO NOTHING;

-- ---------- Doctor schedule (Mon–Fri for active doctors) ----------
INSERT INTO doctor_schedule (doctor_id, work_day)
SELECT d.doctor_id, wd::weekday
FROM doctors d
CROSS JOIN (VALUES ('Monday'),('Tuesday'),('Wednesday'),('Thursday'),('Friday')) AS days(wd)
WHERE d.employment_status = 'Active'
ON CONFLICT (doctor_id, work_day) DO NOTHING;

-- Weekends for a couple of doctors
INSERT INTO doctor_schedule (doctor_id, work_day)
SELECT d.doctor_id, wd::weekday
FROM doctors d
JOIN (VALUES ('Saturday'),('Sunday')) AS w(wd) ON TRUE
WHERE d.doctor_name IN ('Dr. Talia Rosen','Dr. Daniel Peretz')
ON CONFLICT (doctor_id, work_day) DO NOTHING;

-- ---------- Nurse schedule (staggered 5-on / 2-off) ----------
-- Batch A: Mon–Fri
INSERT INTO nurse_schedule (nurse_id, work_day)
SELECT n.nurse_id, wd::weekday
FROM nurses n
CROSS JOIN (VALUES ('Monday'),('Tuesday'),('Wednesday'),('Thursday'),('Friday')) AS days(wd)
WHERE n.nurse_id % 2 = 0 AND n.employment_status='Active'
ON CONFLICT (nurse_id, work_day) DO NOTHING;

-- Batch B: Wed–Sun
INSERT INTO nurse_schedule (nurse_id, work_day)
SELECT n.nurse_id, wd::weekday
FROM nurses n
CROSS JOIN (VALUES ('Wednesday'),('Thursday'),('Friday'),('Saturday'),('Sunday')) AS days(wd)
WHERE n.nurse_id % 2 = 1 AND n.employment_status='Active'
ON CONFLICT (nurse_id, work_day) DO NOTHING;

-- ---------- Patients ----------
INSERT INTO patient_info
 (patient_national_id, patient_name, patient_phone_number, date_of_birth, blood_type,
  insurance_number, emergency_contact_name, emergency_contact_phone)
VALUES
 ('123456789','Ariella Katz','0501239876','1992-05-14','A+','0000000001','Noa Katz','0523456789'),
 ('987654321','Rina Azulay','0548765432','1987-11-03','O-','0000000002','Lior Azulay','0539876543'),
 ('111222333','Dana Levi','0521122334','1990-01-22','B+','0000000003','Yair Levi','0509988776'),
 ('444555666','Shira Cohen','0534455667','1995-07-09','AB-','0000000004','Eden Cohen','0542233445'),
 ('777888999','Noa Shapira','0587788990','1985-03-30','O+','0000000005','Tamar Shapira','0523344556'),
 ('246813579','Michal Bar-On','0552468135','1993-11-11','A-','0000000006','Gil Bar-On','0531357924'),
 ('135792468','Hila Golan','0501357924','1989-02-18','B-','0000000007','Omer Golan','0542468135'),
 ('102938475','Yael Adler','0521029384','1991-06-25','AB+','0000000008','Nadav Adler','0535647382'),
 ('564738291','Lior Regev','0545647382','1996-09-12','A+','0000000009','Tal Regev','0501928374'),
 ('192837465','Gal Rimon','0501928374','1988-12-05','O-','0000000010','Itai Rimon','0522233445'),
 ('223344556','Aviv Tal','0532233445','1994-04-04','B+','0000000011','Roei Tal','0546655443'),
 ('665544332','Maayan Lavi','0546655443','1992-10-10','A-','0000000012','Adi Lavi','0502233445')
ON CONFLICT (patient_national_id) DO NOTHING;

-- ---------- Admissions ----------
WITH pick_doc AS (
  SELECT array_agg(doctor_id ORDER BY doctor_id) AS docs
  FROM womens_dept.doctors
  WHERE doctor_name IN (
    'Dr. Talia Rosen','Dr. Miriam Levi','Dr. Daniel Peretz','Dr. Yael Shapira'
  )
)
INSERT INTO womens_dept.patient_admissions
  (patient_id, attending_doctor_id, ward, room, bed, admission_date, admission_reason)
SELECT
  p.patient_id,
  pick_doc.docs[((row_number() OVER (ORDER BY p.patient_id) - 1) % cardinality(pick_doc.docs)) + 1] AS attending_doctor_id,
  x.ward, x.room, x.bed,
  -- use interval arithmetic and cast to date
  (CURRENT_DATE - (((row_number() OVER (ORDER BY p.patient_id)) % 5)::int * INTERVAL '1 day'))::date AS admission_date,
  CASE (row_number() OVER (ORDER BY p.patient_id)) % 4
    WHEN 0 THEN 'Observation'
    WHEN 1 THEN 'Pre-op'
    WHEN 2 THEN 'Post-op'
    ELSE 'Chemotherapy'
  END AS admission_reason
FROM womens_dept.patient_info p
CROSS JOIN pick_doc
JOIN LATERAL (
  SELECT w.ward, w.room, w.bed
  FROM womens_dept.wards_and_rooms w
  WHERE NOT EXISTS (
    SELECT 1 FROM womens_dept.patient_admissions a
    WHERE a.ward = w.ward AND a.room = w.room AND a.bed = w.bed AND a.discharge_date IS NULL
  )
  ORDER BY w.ward, w.room, w.bed
  LIMIT 1
) AS x ON TRUE
WHERE p.patient_id IN (
  SELECT patient_id FROM womens_dept.patient_info ORDER BY patient_id LIMIT 10
)
ON CONFLICT DO NOTHING;
