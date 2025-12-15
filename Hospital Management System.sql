-- Database: Hospital Management System

-- DROP DATABASE IF EXISTS "Hospital Management System";

CREATE DATABASE "Hospital Management System"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- 1. WARDS Table
CREATE TABLE Wards (
    WardID INT PRIMARY KEY,
    WardName VARCHAR(50) NOT NULL,
    Capacity INT NOT NULL,
    CurrentOccupancy INT DEFAULT 0
);

-- 2. STAFF (Doctors/Nurses) Table
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Role VARCHAR(50) CHECK (Role IN ('Doctor', 'Nurse', 'Admin')) NOT NULL,
    Specialization VARCHAR(100), -- Nullable for Nurses/Admin
    DateHired DATE NOT NULL,
    Salary DECIMAL(10, 2),
    WardID INT,
    FOREIGN KEY (WardID) REFERENCES Wards(WardID)
);

-- 3. PATIENTS Table
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE,
    Gender CHAR(1),
    DateAdmitted DATE NOT NULL,
    DateDischarged DATE, -- Nullable
    AttendingDoctorID INT,
    FOREIGN KEY (AttendingDoctorID) REFERENCES Staff(StaffID)
);

-- 4. TREATMENTS Table
CREATE TABLE Treatments (
    TreatmentID INT PRIMARY KEY,
    TreatmentName VARCHAR(100) NOT NULL,
    Cost DECIMAL(10, 2) NOT NULL
);

-- 5. JUNCTION TABLE: PATIENT_TREATMENT (M:M relationship)
CREATE TABLE Patient_Treatment (
    RecordID SERIAL PRIMARY KEY,
    PatientID INT,
    TreatmentID INT,
    DateOfTreatment DATE,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (TreatmentID) REFERENCES Treatments(TreatmentID)
);


-- 6. APPOINTMENTS Table
CREATE TABLE Appointments (
    AppointmentID SERIAL PRIMARY KEY,
    PatientID INT,
    DoctorID INT,
    AppointmentDateTime TIMESTAMP NOT NULL,
    Status VARCHAR(20) CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled')),
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES Staff(StaffID)
);


-- 7. BILLING Table
CREATE TABLE Billing (
    BillID INT PRIMARY KEY,
    PatientID INT,
    BillDate DATE NOT NULL,
    TotalAmount DECIMAL(10, 2) DEFAULT 0,
    PaymentStatus VARCHAR(20) CHECK (PaymentStatus IN ('Pending', 'Paid', 'Partial')),
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);


-- TRIGGER: Update Ward Occupancy on Patient Admission/Discharge
CREATE OR REPLACE FUNCTION update_ward_occupancy()
RETURNS TRIGGER AS $$
BEGIN
    -- Increase occupancy when a patient is admitted
    UPDATE Wards
    SET CurrentOccupancy = CurrentOccupancy + 1
    WHERE WardID IN (
        SELECT WardID FROM Staff WHERE StaffID = NEW.AttendingDoctorID
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_UpdateWardOccupancy
AFTER INSERT ON Patients
FOR EACH ROW
EXECUTE FUNCTION update_ward_occupancy();


-- Stored Function: Calculate Patient's Total Bill
CREATE OR REPLACE FUNCTION CalculatePatientBill(p_patient_id INT)
RETURNS VOID AS $$
DECLARE
    total_cost DECIMAL(10,2);
BEGIN
    -- Calculate total treatment cost for the patient
    SELECT SUM(T.Cost)
    INTO total_cost
    FROM Patient_Treatment PT
    JOIN Treatments T ON PT.TreatmentID = T.TreatmentID
    WHERE PT.PatientID = p_patient_id;

    -- Update the existing bill record
    UPDATE Billing
    SET TotalAmount = total_cost
    WHERE PatientID = p_patient_id AND PaymentStatus = 'Pending';

    -- if no pending bill exists
    IF NOT FOUND THEN
        INSERT INTO Billing (PatientID, BillDate, TotalAmount, PaymentStatus)
        VALUES (p_patient_id, CURRENT_DATE, total_cost, 'Pending');
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Data Population and Manipulation (DML)
-- Wards
INSERT INTO Wards (WardID, WardName, Capacity) VALUES
(101, 'Emergency', 20),
(102, 'Cardiology', 15),
(103, 'Pediatrics', 10);

-- Staff (Attending doctors for patients must be doctors)
INSERT INTO Staff (StaffID, FirstName, LastName, Role, Specialization, DateHired, Salary, WardID) VALUES
(1, 'Dr. Alice', 'Smith', 'Doctor', 'Cardiology', '2015-05-10', 150000.00, 102),
(2, 'Dr. Bob', 'Johnson', 'Doctor', 'Pediatrics', '2018-11-20', 120000.00, 103),
(3, 'Nurse Carol', 'Davis', 'Nurse', NULL, '2019-01-05', 65000.00, 101),
(4, 'Dr. David', 'Lee', 'Doctor', 'Emergency Medicine', '2020-07-01', 130000.00, 101);

-- Patients
INSERT INTO Patients (PatientID, FirstName, LastName, DateOfBirth, Gender, DateAdmitted, AttendingDoctorID) VALUES
(1001, 'Eva', 'Green', '1985-03-15', 'F', '2024-10-01', 1), -- Cardiology
(1002, 'Frank', 'Harris', '2010-08-22', 'M', '2024-10-05', 2), -- Pediatrics
(1003, 'Grace', 'King', '1950-12-01', 'F', '2024-10-10', 4); -- Emergency

-- Treatments
INSERT INTO Treatments (TreatmentID, TreatmentName, Cost) VALUES
(501, 'ECG', 150.00),
(502, 'X-Ray', 200.00),
(503, 'Open Heart Surgery', 50000.00),
(504, 'Vaccination', 50.00);

-- Patient_Treatment
INSERT INTO Patient_Treatment (PatientID, TreatmentID, DateOfTreatment) VALUES
(1001, 501, '2024-10-01'), -- Eva: ECG
(1001, 503, '2024-10-03'), -- Eva: Surgery
(1002, 504, '2024-10-05'), -- Frank: Vaccination
(1003, 502, '2024-10-10'); -- Grace: X-Ray

-- Billing (Initial records)
INSERT INTO Billing (BillID, PatientID, BillDate, PaymentStatus) VALUES
(701, 1001, '2024-10-04', 'Pending'),
(702, 1002, '2024-10-06', 'Pending'),
(703, 1003, '2024-10-11', 'Pending');

-- EDA

-- What is the current occupancy rate for each ward?
SELECT
    WardName,
    CurrentOccupancy,
    Capacity,
    (CAST(CurrentOccupancy AS DECIMAL) / Capacity) * 100 AS OccupancyRate
FROM Wards
ORDER BY OccupancyRate DESC;


-- List all doctors and the count of patients currently under their care.
SELECT
    S.FirstName,
    S.LastName,
    S.Specialization,
    COUNT(P.PatientID) AS ActivePatients
FROM Staff S
LEFT JOIN Patients P ON S.StaffID = P.AttendingDoctorID
WHERE S.Role = 'Doctor' AND P.DateDischarged IS NULL
GROUP BY S.StaffID, S.FirstName, S.LastName, S.Specialization
ORDER BY ActivePatients DESC;


-- Find the total revenue generated from each treatment type.
SELECT
    T.TreatmentName,
    COUNT(PT.RecordID) AS TimesPerformed,
    SUM(T.Cost) AS TotalRevenue
FROM Patient_Treatment PT
JOIN Treatments T ON PT.TreatmentID = T.TreatmentID
GROUP BY T.TreatmentName
ORDER BY TotalRevenue DESC;


-- Find the average length of stay (in days) for patients treated by each doctor.
SELECT
    S.FirstName || ' ' || S.LastName AS DoctorName,
    AVG(P.DateDischarged - P.DateAdmitted) AS AvgLengthOfStay_Days
FROM Patients P
JOIN Staff S ON P.AttendingDoctorID = S.StaffID
WHERE P.DateDischarged IS NOT NULL
GROUP BY DoctorName
HAVING COUNT(P.PatientID) > 1
ORDER BY AvgLengthOfStay_Days DESC;


