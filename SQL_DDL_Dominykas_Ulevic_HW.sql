-- testing envinronment
SELECT current_database(),
    current_user;
-- creating new schema
CREATE SCHEMA IF NOT EXISTS healthcare;
-- set healthcare as default schama
SET search_path TO healthcare,
    public;
-- creating first table to see 
CREATE TABLE healthcare.patients (
    patient_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL
);
SELECT *
FROM healthcare.patients;
-- Parent table: doctors will reference this table through role_id.
-- It must be created first so the foreign-key relationship can be added later.
CREATE TABLE IF NOT EXISTS healthcare.staff_roles (
    role_id integer GENERATED ALWAYS AS IDENTITY,
    role_name varchar(50) NOT NULL,
    CONSTRAINT staff_roles_pk PRIMARY KEY (role_id),
    CONSTRAINT staff_roles_name_unique UNIQUE (role_name)
);
-- creating other tables with no dependency on other
CREATE TABLE IF NOT EXISTS healthcare.treatment_types (
    treatment_type_id integer GENERATED ALWAYS AS IDENTITY,
    treatment_name varchar(150) NOT NULL,
    description varchar(500),
    standard_price decimal(10, 2) NOT NULL,
    CONSTRAINT treatment_types_pk PRIMARY KEY (treatment_type_id),
    CONSTRAINT treatment_types_name_unique UNIQUE (treatment_name),
    CONSTRAINT treatment_types_price_check CHECK (standard_price >= 0)
);
CREATE TABLE IF NOT EXISTS healthcare.doctors (
    doctor_id integer GENERATED ALWAYS AS IDENTITY,
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    phone_number varchar(20) NOT NULL,
    email varchar(255),
    role_id integer NOT NULL,
    CONSTRAINT doctors_pk PRIMARY KEY (doctor_id),
    CONSTRAINT doctors_phone_unique UNIQUE (phone_number),
    CONSTRAINT doctors_email_unique UNIQUE (email),
    CONSTRAINT doctors_role_fk FOREIGN KEY (role_id) REFERENCES healthcare.staff_roles (role_id)
);
CREATE TABLE IF NOT EXISTS healthcare.medications (
    medication_id integer GENERATED ALWAYS AS IDENTITY,
    medication_name varchar(150) NOT NULL,
    description varchar(500),
    CONSTRAINT medication_pk PRIMARY KEY (medication_id),
    CONSTRAINT medication_name_unique UNIQUE (medication_name)
);
-- tables with dependancies
CREATE TABLE IF NOT EXISTS healthcare.doctor_schedules (
    schedule_id integer GENERATED ALWAYS AS IDENTITY,
    doctor_id integer NOT NULL,
    start_at timestamp NOT NULL,
    end_at timestamp NOT NULL,
    schedule_status integer NOT NULL,
    CONSTRAINT doctor_schedules_pk PRIMARY KEY (schedule_id),
    CONSTRAINT doctor_schedules_doctor_fk FOREIGN KEY (doctor_id) REFERENCES healthcare.doctors (doctor_id),
    CONSTRAINT doctor_schedules_time_check CHECK (end_at > start_at)
);
CREATE TABLE IF NOT EXISTS healthcare.appointments (
    appointment_id integer GENERATED ALWAYS AS IDENTITY,
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    scheduled_at timestamp NOT NULL,
    reason varchar(300) NOT NULL,
    status varchar(30) NOT NULL DEFAULT 'Scheduled',
    CONSTRAINT appointments_pk PRIMARY KEY (appointment_id),
    CONSTRAINT appointments_doctor_fk FOREIGN KEY (doctor_id) REFERENCES healthcare.doctors (doctor_id),
    CONSTRAINT appointments_patient_fk FOREIGN KEY (patient_id) REFERENCES healthcare.patients (patient_id),
    CONSTRAINT appointments_date_check CHECK (scheduled_at > TIMESTAMP '2000-01-01'),
    CONSTRAINT appointments_status_check CHECK (
        status IN ('Scheduled', 'Completed', 'Cancelled')
    )
);
CREATE TABLE IF NOT EXISTS healthcare.appointment_status_history (
    history_id integer GENERATED ALWAYS AS IDENTITY,
    appointment_id integer NOT NULL,
    status varchar(30) NOT NULL,
    changed_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT appointment_status_history_pk PRIMARY KEY (history_id),
    CONSTRAINT appointment_status_history_appointment_fk FOREIGN KEY (appointment_id) REFERENCES healthcare.appointments (appointment_id),
    CONSTRAINT appointment_status_history_status_check CHECK (
        status IN ('Scheduled', 'Completed', 'Cancelled')
    )
);
CREATE TABLE IF NOT EXISTS healthcare.prescriptions (
    prescription_id integer GENERATED ALWAYS AS IDENTITY,
    appointment_id integer NOT NULL,
    issued_at timestamp NOT NULL,
    instructions varchar(300),
    CONSTRAINT prescriptions_pk PRIMARY KEY (prescription_id),
    CONSTRAINT prescriptions_appointment_fk FOREIGN KEY (appointment_id) REFERENCES healthcare.appointments (appointment_id),
    CONSTRAINT prescriptions_issued_date_check CHECK (issued_at > TIMESTAMP '2000-01-01')
);
CREATE TABLE IF NOT EXISTS healthcare.appointment_treatments (
    appointment_treatment_id integer GENERATED ALWAYS AS IDENTITY,
    appointment_id integer NOT NULL,
    treatment_type_id integer NOT NULL,
    performed_at timestamp NOT NULL,
    notes varchar(300),
    result varchar(500),
    CONSTRAINT appointment_treatments_pk PRIMARY KEY (appointment_treatment_id),
    CONSTRAINT appointment_treatments_appointment_fk FOREIGN KEY (appointment_id) REFERENCES healthcare.appointments (appointment_id),
    CONSTRAINT appointment_treatments_type_fk FOREIGN KEY (treatment_type_id) REFERENCES healthcare.treatment_types (treatment_type_id),
    CONSTRAINT appointment_treatments_date_check CHECK (performed_at > TIMESTAMP '2000-01-01')
);
CREATE TABLE IF NOT EXISTS healthcare.invoices (
    invoice_id integer GENERATED ALWAYS AS IDENTITY,
    appointment_id integer NOT NULL,
    issued_at timestamp NOT NULL,
    invoice_status varchar(30) NOT NULL DEFAULT 'Issued',
    CONSTRAINT invoices_pk PRIMARY KEY (invoice_id),
    CONSTRAINT invoices_appointment_unique UNIQUE (appointment_id),
    CONSTRAINT invoices_appointment_fk FOREIGN KEY (appointment_id) REFERENCES healthcare.appointments (appointment_id),
    CONSTRAINT invoices_status_check CHECK (
        invoice_status IN ('Issued', 'Paid', 'Cancelled')
    ),
    CONSTRAINT invoices_date_check CHECK (issued_at > TIMESTAMP '2000-01-01')
);
CREATE TABLE IF NOT EXISTS healthcare.invoice_lines (
    invoice_line_id integer GENERATED ALWAYS AS IDENTITY,
    invoice_id integer NOT NULL,
    appointment_treatment_id integer NOT NULL,
    amount decimal(10, 2) NOT NULL,
    CONSTRAINT invoice_lines_pk PRIMARY KEY (invoice_line_id),
    CONSTRAINT invoice_lines_invoice_fk FOREIGN KEY (invoice_id) REFERENCES healthcare.invoices (invoice_id),
    CONSTRAINT invoice_lines_treatment_fk FOREIGN KEY (appointment_treatment_id) REFERENCES healthcare.appointment_treatments (appointment_treatment_id),
    CONSTRAINT invoice_lines_amount_check CHECK (amount >= 0)
);
CREATE TABLE IF NOT EXISTS healthcare.payments (
    payment_id integer GENERATED ALWAYS AS IDENTITY,
    invoice_id integer NOT NULL,
    amount decimal(10, 2) NOT NULL,
    paid_at timestamp NOT NULL,
    payment_status varchar(30) NOT NULL DEFAULT 'Pending',
    CONSTRAINT payments_pk PRIMARY KEY (payment_id),
    CONSTRAINT payments_invoice_fk FOREIGN KEY (invoice_id) REFERENCES healthcare.invoices (invoice_id),
    CONSTRAINT payments_amount_check CHECK (amount >= 0),
    CONSTRAINT payments_date_check CHECK (paid_at > TIMESTAMP '2000-01-01'),
    CONSTRAINT payments_status_check CHECK (
        payment_status IN ('Pending', 'Completed', 'Failed')
    )
);
CREATE TABLE IF NOT EXISTS healthcare.prescription_medications (
    prescription_medication_id integer GENERATED ALWAYS AS IDENTITY,
    prescription_id integer NOT NULL,
    medication_id integer NOT NULL,
    dosage varchar(100) NOT NULL,
    frequency varchar(100) NOT NULL,
    duration varchar(100),
    CONSTRAINT prescription_medications_pk PRIMARY KEY (prescription_medication_id),
    CONSTRAINT prescription_medications_prescription_fk FOREIGN KEY (prescription_id) REFERENCES healthcare.prescriptions (prescription_id),
    CONSTRAINT prescription_medications_medication_fk FOREIGN KEY (medication_id) REFERENCES healthcare.medications (medication_id),
    CONSTRAINT prescription_medications_unique UNIQUE (prescription_id, medication_id)
);
CREATE TABLE IF NOT EXISTS healthcare.diagnostic_tests (
    diagnostic_test_id integer GENERATED ALWAYS AS IDENTITY,
    appointment_id integer NOT NULL,
    test_name varchar(150) NOT NULL,
    ordered_at timestamp NOT NULL,
    performed_at timestamp,
    result varchar(500),
    test_status varchar(30) NOT NULL DEFAULT 'Scheduled',
    CONSTRAINT diagnostic_tests_pk PRIMARY KEY (diagnostic_test_id),
    CONSTRAINT diagnostic_tests_appointment_fk FOREIGN KEY (appointment_id) REFERENCES healthcare.appointments (appointment_id),
    CONSTRAINT diagnostic_tests_ordered_date_check CHECK (ordered_at > TIMESTAMP '2000-01-01'),
    CONSTRAINT diagnostic_tests_performed_date_check CHECK (
        performed_at IS NULL
        OR performed_at >= ordered_at
    ),
    CONSTRAINT diagnostic_tests_status_check CHECK (
        test_status IN ('Scheduled', 'Completed', 'Cancelled')
    )
);
-- altering new column of record_ts 
ALTER TABLE healthcare.medications
ADD COLUMN IF NOT EXISTS record_ts date NOT NULL DEFAULT CURRENT_DATE;
-- Automizing the action of adding a new column for each table (created with ai)
DO $$
DECLARE table_record record;
BEGIN FOR table_record IN
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'healthcare'
    AND table_type = 'BASE TABLE' LOOP EXECUTE format(
        'ALTER TABLE healthcare.%I
             ADD COLUMN IF NOT EXISTS record_ts date
             NOT NULL DEFAULT CURRENT_DATE',
        table_record.table_name
    );
END LOOP;
END $$;
-- verification
SELECT table_name,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'healthcare'
    AND column_name = 'record_ts'
ORDER BY table_name;
SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'healthcare'
    AND table_type = 'BASE TABLE';
-- inserting values to a table
BEGIN;
INSERT INTO healthcare.staff_roles (role_name)
VALUES ('General Practitioner'),
    ('Nurse') ON CONFLICT (role_name) DO NOTHING
RETURNING role_id,
    role_name;
COMMIT;
-- cheking the result
SELECT *
FROM healthcare.staff_roles;
-- modifying table patiens
ALTER TABLE healthcare.patients
ADD COLUMN IF NOT EXISTS phone_number varchar(50) NOT NULL;
ALTER TABLE healthcare.patients
ADD COLUMN IF NOT EXISTS email varchar(50) NOT NULL;
INSERT INTO healthcare.patients (
        first_name,
        last_name,
        phone_number,
        email
    )
VALUES (
        'Jonas',
        'Petraitis',
        '+37060000001',
        'jonas.petraitis@example.com'
    ),
    (
        'Asta',
        'Kazlauskaitė',
        '+37060000002',
        'asta.kazlausk@sample.com'
    ) ON CONFLICT DO NOTHING
RETURNING patient_id,
    first_name,
    last_name,
    phone_number,
    email;
-- insert is auto commit
INSERT INTO healthcare.patients (
        first_name,
        last_name,
        phone_number,
        email
    )
VALUES (
        'Jonas',
        'Petraitis',
        '+37060000001',
        'jonas@example.com'
    ),
    (
        'Asta',
        'Kazlauskaitė',
        '+37060000002',
        'asta@example.com'
    )
RETURNING patient_id,
    first_name,
    last_name,
    record_ts;
-- verification
SELECT *
FROM healthcare.patients -- inserting other tables
INSERT INTO healthcare.doctors (
        first_name,
        last_name,
        phone_number,
        email,
        role_id
    )
SELECT v.first_name,
    v.last_name,
    v.phone_number,
    v.email,
    r.role_id
FROM (
        VALUES (
                'Petras',
                'Jonaitis',
                '+37060000003',
                'petras@example.com',
                'General Practitioner'
            ),
            (
                'Lina',
                'Petraitienė',
                '+37060000004',
                'lina@example.com',
                'Nurse'
            )
    ) AS v(
        first_name,
        last_name,
        phone_number,
        email,
        role_name
    )
    JOIN healthcare.staff_roles AS r ON r.role_name = v.role_name
RETURNING doctor_id,
    first_name,
    last_name,
    role_id,
    record_ts;
-- modifying table - change status from integer to defaul value available
ALTER TABLE healthcare.doctor_schedules
ALTER COLUMN schedule_status TYPE varchar(30) USING schedule_status::varchar;
ALTER TABLE healthcare.doctor_schedules
ALTER COLUMN schedule_status
SET DEFAULT 'Available';
ALTER TABLE healthcare.doctor_schedules
ADD CONSTRAINT doctor_schedules_status_check CHECK (
        schedule_status IN ('Available', 'Busy', 'Cancelled')
    );
-- inserting
BEGIN;
INSERT INTO healthcare.doctor_schedules (doctor_id, start_at, end_at)
SELECT d.doctor_id,
    s.start_at,
    s.end_at
FROM (
        VALUES (
                'petras@example.com',
                TIMESTAMP '2026-11-16 09:00:00',
                TIMESTAMP '2026-11-16 17:00:00'
            ),
            (
                'lina@example.com',
                TIMESTAMP '2026-11-16 10:00:00',
                TIMESTAMP '2026-11-16 18:00:00'
            )
    ) AS s(email, start_at, end_at)
    JOIN healthcare.doctors AS d ON d.email = s.email
WHERE s.end_at > s.start_at
RETURNING schedule_id,
    doctor_id,
    start_at,
    end_at,
    schedule_status,
    record_ts;
COMMIT;
INSERT INTO healthcare.treatment_types (
        treatment_name,
        description,
        standard_price
    )
VALUES (
        'Routine Consultation',
        'General medical consultation',
        10.00
    ),
    (
        'Blood Test',
        'Basic laboratory blood analysis',
        25.00
    ) ON CONFLICT (treatment_name) DO NOTHING
RETURNING treatment_type_id,
    treatment_name,
    description,
    standard_price,
    record_ts;
BEGIN;
INSERT INTO healthcare.appointments (
        patient_id,
        doctor_id,
        scheduled_at,
        reason
    )
SELECT p.patient_id,
    d.doctor_id,
    a.scheduled_at,
    a.reason
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                TIMESTAMP '2026-11-16 09:00:00',
                'Regular treatment'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                TIMESTAMP '2026-11-16 10:00:00',
                'Blood test'
            )
    ) AS a(p_email, d_email, scheduled_at, reason)
    JOIN healthcare.doctors AS d ON d.email = a.d_email
    JOIN healthcare.patients AS p ON p.email = a.p_email
RETURNING appointment_id,
    patient_id,
    doctor_id,
    scheduled_at,
    reason,
    status,
    record_ts;
COMMIT;
BEGIN;
INSERT INTO healthcare.appointment_status_history (
        appointment_id,
        status,
        changed_at
    )
SELECT a.appointment_id,
    h.status,
    h.changed_at
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                TIMESTAMP '2026-11-16 09:00:00',
                'Scheduled',
                TIMESTAMP '2026-11-13 10:00:00'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                TIMESTAMP '2026-11-16 10:00:00',
                'Scheduled',
                TIMESTAMP '2026-11-13 10:05:00'
            )
    ) AS h(
        p_email,
        d_email,
        scheduled_at,
        status,
        changed_at
    )
    JOIN healthcare.doctors AS d ON d.email = h.d_email
    JOIN healthcare.patients AS p ON p.email = h.p_email
    JOIN healthcare.appointments a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
    AND a.scheduled_at = h.scheduled_at
RETURNING history_id,
    appointment_id,
    status,
    changed_at;
COMMIT;
BEGIN;
INSERT INTO healthcare.diagnostic_tests (
        appointment_id,
        test_name,
        ordered_at,
        performed_at,
        result
    )
SELECT a.appointment_id,
    dt.test_name,
    dt.ordered_at,
    dt.performed_at,
    dt.result
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                'Vitamin D test',
                TIMESTAMP '2026-11-16 09:00:00',
                TIMESTAMP '2026-11-18 10:00:00',
                'Waiting for review'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                'Blood test',
                TIMESTAMP '2026-11-16 10:00:00',
                TIMESTAMP '2026-11-18 10:05:00',
                'Waiting for review'
            )
    ) AS dt(
        p_email,
        d_email,
        test_name,
        ordered_at,
        performed_at,
        result
    )
    JOIN healthcare.doctors AS d ON d.email = dt.d_email
    JOIN healthcare.patients AS p ON p.email = dt.p_email
    JOIN healthcare.appointments a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
RETURNING diagnostic_test_id,
    appointment_id,
    test_name,
    ordered_at,
    performed_at,
    result,
    test_status;
COMMIT;
INSERT INTO healthcare.medications (medication_name, description)
VALUES (
        'Paracetamol',
        'Used to relieve pain and reduce fever'
    ),
    (
        'Amoxicillin',
        'Antibiotic used to treat bacterial infections'
    ) ON CONFLICT (medication_name) DO NOTHING
RETURNING medication_id,
    medication_name,
    description,
    record_ts;
BEGIN;
INSERT INTO healthcare.prescriptions (
        appointment_id,
        issued_at,
        instructions
    )
SELECT a.appointment_id,
    pr.issued_at,
    pr.instructions
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                TIMESTAMP '2026-11-18 11:00:00',
                'Take one tablet after breakfast.'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                TIMESTAMP '2026-11-18 11:30:00',
                'Take one capsule twice daily.'
            )
    ) AS pr(
        p_email,
        d_email,
        issued_at,
        instructions
    )
    JOIN healthcare.doctors AS d ON d.email = pr.d_email
    JOIN healthcare.patients AS p ON p.email = pr.p_email
    JOIN healthcare.appointments a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
RETURNING prescription_id,
    appointment_id,
    issued_at,
    instructions;
COMMIT;
BEGIN;
INSERT INTO healthcare.prescription_medications (
        prescription_id,
        medication_id,
        dosage,
        frequency,
        duration
    )
SELECT pr.prescription_id,
    m.medication_id,
    pm.dosage,
    pm.frequency,
    pm.duration
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                TIMESTAMP '2026-11-16 09:00:00',
                'Paracetamol',
                '500 mg',
                'Twice daily',
                '5 days'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                TIMESTAMP '2026-11-16 10:00:00',
                'Amoxicillin',
                '500 mg',
                'Three times daily',
                '7 days'
            )
    ) AS pm(
        patient_email,
        doctor_email,
        scheduled_at,
        medication_name,
        dosage,
        frequency,
        duration
    )
    JOIN healthcare.patients AS p ON p.email = pm.patient_email
    JOIN healthcare.doctors AS d ON d.email = pm.doctor_email
    JOIN healthcare.appointments AS a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
    AND a.scheduled_at = pm.scheduled_at
    JOIN healthcare.prescriptions AS pr ON pr.appointment_id = a.appointment_id
    JOIN healthcare.medications AS m ON m.medication_name = pm.medication_name
RETURNING prescription_medication_id,
    prescription_id,
    medication_id,
    dosage,
    frequency,
    duration,
    record_ts;
COMMIT;
SELECT *
FROM healthcare.prescriptions;
SELECT *
FROM healthcare.prescription_medications
SELECT *
FROM healthcare.appointment_treatments
SELECT *
FROM healthcare.prescriptions;
BEGIN;
INSERT INTO healthcare.appointment_treatments (
        appointment_id,
        treatment_type_id,
        performed_at,
        notes,
        result
    )
SELECT a.appointment_id,
    t.treatment_type_id,
    at.performed_at,
    at.notes,
    at.result
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                TIMESTAMP '2026-11-16 09:00:00',
                'Routine Consultation',
                TIMESTAMP '2026-11-16 10:00:00',
                'Patient reported mild headache',
                'General examination completed'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                TIMESTAMP '2026-11-16 10:00:00',
                'Blood Test',
                TIMESTAMP '2026-11-16 11:00:00',
                'Blood sample collected',
                'Results within normal range'
            )
    ) AS at(
        patient_email,
        doctor_email,
        scheduled_at,
        treatment_name,
        performed_at,
        notes,
        result
    )
    JOIN healthcare.patients AS p ON p.email = at.patient_email
    JOIN healthcare.doctors AS d ON d.email = at.doctor_email
    JOIN healthcare.appointments AS a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
    AND a.scheduled_at = at.scheduled_at
    JOIN healthcare.treatment_types AS t ON t.treatment_name = at.treatment_name
RETURNING appointment_treatment_id,
    appointment_id,
    treatment_type_id,
    performed_at,
    notes,
    result,
    record_ts;
COMMIT;
SELECT *
FROM healthcare.appointment_treatments
SELECT *
FROM healthcare.treatment_types;
BEGIN;
INSERT INTO healthcare.invoices (appointment_id, issued_at)
SELECT a.appointment_id,
    i.issued_at
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                TIMESTAMP '2026-11-16 09:00:00'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                TIMESTAMP '2026-11-16 10:00:00'
            )
    ) AS i (
        patient_email,
        doctor_email,
        issued_at
    )
    JOIN healthcare.patients AS p ON p.email = i.patient_email
    JOIN healthcare.doctors AS d ON d.email = i.doctor_email
    JOIN healthcare.appointments AS a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
RETURNING invoice_id,
    appointment_id,
    issued_at,
    invoice_status;
COMMIT;
BEGIN;
INSERT INTO healthcare.invoice_lines (
        invoice_id,
        appointment_treatment_id,
        amount
    )
SELECT i.invoice_id,
    at.appointment_treatment_id,
    t.standard_price
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com'
            ),
            (
                'jonas@example.com',
                'lina@example.com'
            )
    ) AS il (patient_email, doctor_email)
    JOIN healthcare.patients AS p ON p.email = il.patient_email
    JOIN healthcare.doctors AS d ON d.email = il.doctor_email
    JOIN healthcare.appointments AS a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
    JOIN healthcare.appointment_treatments AS at ON at.appointment_id = a.appointment_id
    JOIN healthcare.treatment_types AS t ON t.treatment_type_id = at.treatment_type_id
    JOIN healthcare.invoices AS i ON i.appointment_id = a.appointment_id
RETURNING invoice_line_id,
    invoice_id,
    appointment_treatment_id,
    amount;
COMMIT;
BEGIN;
INSERT INTO healthcare.payments (
        invoice_id,
        amount,
        paid_at
    )
SELECT i.invoice_id,
    il.amount,
    paid.paid_at
FROM (
        VALUES (
                'asta@example.com',
                'petras@example.com',
                TIMESTAMP '2026-11-16 09:00:00'
            ),
            (
                'jonas@example.com',
                'lina@example.com',
                TIMESTAMP '2026-11-16 10:00:00'
            )
    ) AS paid (
        patient_email,
        doctor_email,
        paid_at
    )
    JOIN healthcare.patients AS p ON p.email = paid.patient_email
    JOIN healthcare.doctors AS d ON d.email = paid.doctor_email
    JOIN healthcare.appointments AS a ON a.patient_id = p.patient_id
    AND a.doctor_id = d.doctor_id
    JOIN healthcare.invoices AS i ON i.appointment_id = a.appointment_id
    JOIN healthcare.invoice_lines AS il ON il.invoice_id = i.invoice_id
RETURNING payment_id,
    invoice_id,
    amount,
    paid_at;
COMMIT;
SELECT *
FROM healthcare.payments;
-- veryfication
SELECT 'patients' AS table_name,
    COUNT(*) AS row_count
FROM healthcare.patients
UNION ALL
SELECT 'doctors',
    COUNT(*)
FROM healthcare.doctors
UNION ALL
SELECT 'appointments',
    COUNT(*)
FROM healthcare.appointments
UNION ALL
SELECT 'medications',
    COUNT(*)
FROM healthcare.medications
UNION ALL
SELECT 'treatment_types',
    COUNT(*)
FROM healthcare.treatment_types;
SELECT table_name,
    column_name,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'healthcare'
    AND column_name = 'record_ts'
ORDER BY table_name;
SELECT appointment_id,
    patient_id,
    doctor_id
FROM healthcare.appointments;