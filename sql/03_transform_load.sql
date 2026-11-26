-- =====================================================================
-- Employee Attrition Analysis | 03_transform_load.sql
-- Moves data from STG_HR_EMPLOYEE into the dimensions and the fact table.
-- Safe to re-run: clears the star schema first.
-- =====================================================================

DELETE FROM fact_employee;
DELETE FROM dim_department;
DELETE FROM dim_job_role;
DELETE FROM dim_education_field;

-- Dimensions -----------------------------------------------------------
INSERT INTO dim_department (dept_name)
SELECT DISTINCT department FROM stg_hr_employee WHERE department IS NOT NULL;

INSERT INTO dim_job_role (role_name)
SELECT DISTINCT job_role FROM stg_hr_employee WHERE job_role IS NOT NULL;

INSERT INTO dim_education_field (edu_field_name)
SELECT DISTINCT education_field FROM stg_hr_employee WHERE education_field IS NOT NULL;

-- Fact -----------------------------------------------------------------
INSERT INTO fact_employee (
    employee_id, dept_id, role_id, edu_field_id,
    age, age_band, gender, marital_status, job_level, education, business_travel,
    distance_from_home, overtime, monthly_income, salary_band, percent_salary_hike,
    stock_option_level, total_working_years, years_at_company, tenure_band,
    years_in_current_role, years_since_last_promotion, years_with_curr_manager,
    num_companies_worked, training_times_last_year, environment_satisfaction,
    job_satisfaction, relationship_satisfaction, work_life_balance, job_involvement,
    performance_rating, attrition, attrition_flag, income_outlier_flag
)
SELECT
    s.employee_number, d.dept_id, r.role_id, e.edu_field_id,
    s.age, s.age_band, s.gender, s.marital_status, s.job_level, s.education, s.business_travel,
    s.distance_from_home, s.overtime, s.monthly_income, s.salary_band, s.percent_salary_hike,
    s.stock_option_level, s.total_working_years, s.years_at_company, NVL(s.tenure_band, 'Unknown'),
    s.years_in_current_role, s.years_since_last_promotion, s.years_with_curr_manager,
    s.num_companies_worked, s.training_times_last_year, s.environment_satisfaction,
    s.job_satisfaction, s.relationship_satisfaction, s.work_life_balance, s.job_involvement,
    s.performance_rating, s.attrition, s.attrition_flag, NVL(s.income_outlier_flag, 0)
FROM stg_hr_employee s
JOIN dim_department d           ON d.dept_name = s.department
JOIN dim_job_role r             ON r.role_name = s.job_role
LEFT JOIN dim_education_field e ON e.edu_field_name = s.education_field;

COMMIT;

-- Quick confirmation
SELECT 'STG_HR_EMPLOYEE' AS table_name, COUNT(*) AS row_count FROM stg_hr_employee
UNION ALL SELECT 'FACT_EMPLOYEE',       COUNT(*) FROM fact_employee
UNION ALL SELECT 'DIM_DEPARTMENT',      COUNT(*) FROM dim_department
UNION ALL SELECT 'DIM_JOB_ROLE',        COUNT(*) FROM dim_job_role
UNION ALL SELECT 'DIM_EDUCATION_FIELD', COUNT(*) FROM dim_education_field;
