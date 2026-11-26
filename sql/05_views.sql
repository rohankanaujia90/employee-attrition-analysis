-- =====================================================================
-- Employee Attrition Analysis | 05_views.sql
-- Views that Power BI connects to.
-- =====================================================================

-- Flat employee-level view: the main Power BI table
CREATE OR REPLACE VIEW vw_employee_analytics AS
SELECT f.employee_id,
       d.dept_name                AS department,
       r.role_name                AS job_role,
       e.edu_field_name           AS education_field,
       f.age, f.age_band, f.gender, f.marital_status, f.job_level, f.education,
       f.business_travel, f.distance_from_home, f.overtime,
       f.monthly_income, f.salary_band, f.percent_salary_hike, f.stock_option_level,
       f.total_working_years, f.years_at_company, f.tenure_band,
       f.years_in_current_role, f.years_since_last_promotion, f.years_with_curr_manager,
       f.num_companies_worked, f.training_times_last_year,
       f.environment_satisfaction, f.job_satisfaction, f.relationship_satisfaction,
       f.work_life_balance, f.job_involvement, f.performance_rating,
       f.attrition, f.attrition_flag, f.income_outlier_flag,
       -- sort keys so bands appear in logical order in Power BI ("Sort by column")
       CASE f.tenure_band WHEN '0-2 yrs' THEN 1 WHEN '3-5 yrs' THEN 2
                          WHEN '6-10 yrs' THEN 3 WHEN '11+ yrs' THEN 4 ELSE 5 END AS tenure_band_order,
       CASE f.salary_band WHEN '<3K' THEN 1 WHEN '3K-6K' THEN 2
                          WHEN '6K-10K' THEN 3 WHEN '10K+' THEN 4 ELSE 5 END   AS salary_band_order,
       CASE f.job_satisfaction WHEN 1 THEN 'Low' WHEN 2 THEN 'Medium'
                               WHEN 3 THEN 'High' WHEN 4 THEN 'Very High' END AS job_satisfaction_label,
       CASE f.work_life_balance WHEN 1 THEN 'Bad' WHEN 2 THEN 'Good'
                                WHEN 3 THEN 'Better' WHEN 4 THEN 'Best' END   AS work_life_balance_label
FROM fact_employee f
JOIN dim_department d           ON d.dept_id = f.dept_id
JOIN dim_job_role r             ON r.role_id = f.role_id
LEFT JOIN dim_education_field e ON e.edu_field_id = f.edu_field_id;

-- Aggregated views (used for SQL checks and quick visuals)
CREATE OR REPLACE VIEW vw_attrition_by_dept AS
SELECT department AS dept_name,
       COUNT(*)                                       AS employees,
       SUM(attrition_flag)                            AS leavers,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM vw_employee_analytics
GROUP BY department;

CREATE OR REPLACE VIEW vw_attrition_by_tenure AS
SELECT tenure_band, tenure_band_order,
       COUNT(*)                                       AS employees,
       SUM(attrition_flag)                            AS leavers,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM vw_employee_analytics
GROUP BY tenure_band, tenure_band_order;

CREATE OR REPLACE VIEW vw_attrition_by_salary AS
SELECT salary_band, salary_band_order,
       COUNT(*)                                       AS employees,
       SUM(attrition_flag)                            AS leavers,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM vw_employee_analytics
GROUP BY salary_band, salary_band_order;
