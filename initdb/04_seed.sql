@"
SET search_path = womens_dept, public;

-- ---------- Doctors ----------
INSERT INTO doctors (doctor_name, doctor_phone_number, specialization, employment_status) VALUES
 ('Dr. Miriam Levi',   '0501000001', 'Maternal-Fetal Medicine', 'Active'),
 ('Dr. Talia Rosen',   '0501000002', 'Gynecologic Oncology',     'Active'),
 ('Dr. Daniel Peretz', '0501000003', 'Obstetrics',               'Active'),
 ('Dr. Yael Shapira',  '0501000004', 'Breast Oncology',          'Active'),
 ('Dr. Ron Golan',     '0501000005', 'Urogynecology',            'Active'),
 ('Dr. Maya Bar-On',   '0501000006', 'Reproductive Endocrinology','Active'),
 ('Dr. Amir Cohen',    '0501000007', 'General Gynecology',       'Active'),
 ('Dr. Noga Adler',    '0501000008', 'Gynecologic Surgery',      'OnLeave')
ON CONFLICT (doctor_phone_number) DO NOTHING;

-- ---------- Nurses (includes the four you mentioned) ----------
INSERT INTO nurses (nurse_name, nurse_phone_number, nurse_sex, nurse_gender, employment_status) VALUES
 ('Nurse Cohen',     '0502000001', 'Female','Female','Active'),
 ('Nurse Levi',      '0502000002', 'Female','Female','Active'),
 ('Nurse Shahar',    '0502000003', 'Female','Female','Active'),
 ('Nurse Ben Ami',   '0502000004', 'Female','Female','Active'),
 ('Nurse Azulay',    '0502000005', 'Female','Female','Active'),
 ('Nurse Peretz',    '0502000006', 'Female','Female','Active'),
 ('Nurse Shapira',   '0502000007', 'Female','Female','Active'),
 ('Nurse Bar-On',    '0502000008', 'Female','Female','Active'),
 ('Nurse Golan',     '0502000009', 'Female','Female','Active'),
 ('Nurse Adler',     '0502000010', 'Female','Female','Active'),
 ('Nurse Hadar',     '0502000011', 'Female','Female','Active'),
 ('Nurse Lavi',      '0502000012', 'Female','Female','Active'),
 ('Nurse Tal',       '0502000013', 'Female','Female','Active'),
 ('Nurse Yaari',     '0502000014', 'Female','Female','Active'),
 ('Nurse Regev',     '0502000015', 'Female','Female','Active'),
 ('Nurse Rimon',     '0502000016', 'Female','Female','Active'),
 ('Nurse Aviv',      '0502000017', 'Female','Female','Active'),
 ('Nurse Gal',       '0502000018', 'Female','Female','Active'),
 ('Nurse Eden',      '0502000019', 'Female','Female','Active'),
 ('Nurse Maayan',    '0502000020', 'Female','Female','Active')
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
 ('123456789','Ariella Katz','0503000001','1992-05-14','A+','0000000001','Noa Katz','0509000001'),
 ('987654321','Rina Azulay','0503000002','1987-11-03','O-','0000000002','Lior Azulay','0509000002'),
 ('111222333','Dana Levi','0503000003','1990-01-22','B+','0000000003','Yair Levi','0509000003'),
 ('444555666','Shira Cohen','0503000004','1995-07-09','AB-','0000000004','Eden Cohen','0509000004'),
 ('777888999','Noa Shapira','0503000005','1985-03-30','O+','0000000005','Tamar Shapira','0509000005'),
 ('246813579','Michal Bar-On','0503000006','1993-11-11','A-','0000000006','Gil Bar-On','0509000006'),
 ('135792468','Hila Golan','0503000007','1989-02-18','B-','0000000007','Omer Golan','0509000007'),
 ('102938475','Yael Adler','0503000008','1991-06-25','AB+','0000000008','Nadav Adler','0509000008'),
 ('564738291','Lior Regev','0503000009','1996-09-12','A+','0000000009','Tal Regev','0509000009'),
 ('192837465','Gal Rimon','0503000010','1988-12-05','O-','0000000010','Itai Rimon','0509000010'),
 ('223344556','Aviv Tal','0503000011','1994-04-04','B+','0000000011','Roei Tal','0509000011'),
 ('665544332','Maayan Lavi','0503000012','1992-10-10','A-','0000000012','Adi Lavi','0509000012')
ON CONFLICT (patient_national_id) DO NOTHING;

-- ---------- Admissions ----------
WITH pick_doc AS (
  SELECT doctor_id
  FROM doctors
  WHERE doctor_name IN ('Dr. Talia Rosen','Dr. Miriam Levi','Dr. Daniel Peretz','Dr. Yael Shapira')
  ORDER BY doctor_id
)
INSERT INTO patient_admissions
 (patient_id, attending_doctor_id, ward, room, bed, admission_date, admission_reason)
SELECT p.patient_id,
       (SELECT doctor_id FROM pick_doc ORDER BY doctor_id LIMIT 1
        OFFSET ((row_number() OVER (ORDER BY p.patient_id)-1) % (SELECT COUNT(*) FROM pick_doc))) AS attending_doctor_id,
       x.ward, x.room, x.bed,
       CURRENT_DATE - ((row_number() OVER (ORDER BY p.patient_id)) % 5),
       CASE (row_number() OVER (ORDER BY p.patient_id)) % 4
         WHEN 0 THEN 'Observation'
         WHEN 1 THEN 'Pre-op'
         WHEN 2 THEN 'Post-op'
         ELSE 'Chemotherapy'
       END
FROM patient_info p
JOIN LATERAL (
  SELECT w.ward, w.room, w.bed
  FROM wards_and_rooms w
  WHERE NOT EXISTS (
    SELECT 1 FROM patient_admissions a
     WHERE a.ward=w.ward AND a.room=w.room AND a.bed=w.bed
       AND a.discharge_date IS NULL
  )
  ORDER BY w.ward, w.room, w.bed
  LIMIT 1
) AS x ON TRUE
WHERE p.patient_id IN (SELECT patient_id FROM patient_info ORDER BY patient_id LIMIT 10)
ON CONFLICT DO NOTHING;
"@ | Set-Content .\initdb\04_seed.sql -Encoding UTF8