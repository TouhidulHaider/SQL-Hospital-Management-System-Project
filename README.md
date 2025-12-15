# 🏥 Hospital Management System (PostgreSQL)

## Overview
This project implements a **Hospital Management System** database in **PostgreSQL**.  
It models wards, staff, patients, treatments, appointments, and billing, with triggers and stored functions to automate workflows.  
The schema supports **Revenue Cycle Management (RCM)-style analytics** such as occupancy tracking, billing automation, and treatment revenue reporting.

---

## Features
- **Normalized Schema** with 7 core tables:
  - `Wards`, `Staff`, `Patients`, `Treatments`, `Patient_Treatment`, `Appointments`, `Billing`
- **Trigger:** Auto-updates ward occupancy when patients are admitted.
- **Stored Function:** Calculates patient bills based on treatments and updates billing records.
- **Data Population:** Sample records for wards, staff, patients, treatments, and billing.
- **EDA Queries:**
  - Ward occupancy rates
  - Active patients per doctor
  - Revenue by treatment type
  - Average patient length of stay per doctor

---

## Tech Stack
- **Database:** PostgreSQL 15+
- **Language:** SQL / PLpgSQL
- **Concepts:** Triggers, Stored Functions, Joins, Aggregations, Constraints

---

## How to Run
1. Clone or copy the SQL script.
2. Run in PostgreSQL:
   ```bash
   psql -U postgres -f hospital_management.sql
