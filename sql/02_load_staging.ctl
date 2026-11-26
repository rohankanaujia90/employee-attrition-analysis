-- =====================================================================
-- Employee Attrition Analysis | 02_load_staging.ctl (SQL*Loader)
-- Run from the PROJECT ROOT:
--   sqlldr userid=USER/PASSWORD@localhost/XEPDB1 control=sql/02_load_staging.ctl log=reports/sqlldr.log
-- Alternative: SQL Developer > right-click STG_HR_EMPLOYEE > Import Data.
-- =====================================================================
OPTIONS (SKIP=1)
LOAD DATA
CHARACTERSET UTF8
INFILE 'data/clean/hr_attrition_clean.csv'
BADFILE 'reports/stg_hr_employee.bad'
TRUNCATE
INTO TABLE stg_hr_employee
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    employee_number,
    age,
    age_band,
    gender,
    marital_status,
    department,
    job_role,
    job_level,
    education,
    education_field,
    business_travel,
    distance_from_home,
    overtime,
    monthly_income,
    salary_band,
    percent_salary_hike,
    stock_option_level,
    total_working_years,
    years_at_company,
    tenure_band,
    years_in_current_role,
    years_since_last_promotion,
    years_with_curr_manager,
    num_companies_worked,
    training_times_last_year,
    environment_satisfaction,
    job_satisfaction,
    relationship_satisfaction,
    work_life_balance,
    job_involvement,
    performance_rating,
    attrition,
    attrition_flag,
    income_outlier_flag
)
