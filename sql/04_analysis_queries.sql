-- =====================================================================
-- Employee Attrition Analysis | 04_analysis_queries.sql
-- Attrition rate = leavers / employees * 100
-- Run 05_views.sql first: a few queries reuse VW_EMPLOYEE_ANALYTICS.
-- =====================================================================

-- Q1. Overall attrition --------------------------------------------------
SELECT COUNT(*)                                         AS total_employees,
       SUM(attrition_flag)                              AS leavers,
       COUNT(*) - SUM(attrition_flag)                   AS active_employees,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2)   AS attrition_rate_pct
FROM fact_employee;

-- Q2. Attrition by department (acceptance criterion) ------------------
SELECT d.dept_name,
       COUNT(*)                                         AS employees,
       SUM(f.attrition_flag)                            AS leavers,
       ROUND(SUM(f.attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct,
       ROUND(RATIO_TO_REPORT(SUM(f.attrition_flag)) OVER () * 100, 2) AS share_of_all_leavers_pct
FROM fact_employee f
JOIN dim_department d ON d.dept_id = f.dept_id
GROUP BY d.dept_name
ORDER BY attrition_rate_pct DESC;

-- Q3. Attrition by tenure band (acceptance criterion) -----------------
SELECT tenure_band,
       COUNT(*)                                       AS employees,
       SUM(attrition_flag)                            AS leavers,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY tenure_band
ORDER BY CASE tenure_band WHEN '0-2 yrs' THEN 1 WHEN '3-5 yrs' THEN 2
                          WHEN '6-10 yrs' THEN 3 WHEN '11+ yrs' THEN 4 ELSE 5 END;

-- Q4. Attrition by salary band ----------------------------------------
SELECT salary_band,
       COUNT(*)                                       AS employees,
       SUM(attrition_flag)                            AS leavers,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY salary_band
ORDER BY CASE salary_band WHEN '<3K' THEN 1 WHEN '3K-6K' THEN 2
                          WHEN '6K-10K' THEN 3 WHEN '10K+' THEN 4 ELSE 5 END;

-- Q5. Department x tenure (matrix for the drill-down) ----------------
SELECT d.dept_name, f.tenure_band,
       COUNT(*)                                         AS employees,
       ROUND(SUM(f.attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee f
JOIN dim_department d ON d.dept_id = f.dept_id
GROUP BY d.dept_name, f.tenure_band
ORDER BY d.dept_name, f.tenure_band;

-- Q6. Attrition by department and gender ------------------------------
SELECT d.dept_name, f.gender,
       COUNT(*)                                         AS employees,
       SUM(f.attrition_flag)                            AS leavers,
       ROUND(SUM(f.attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee f
JOIN dim_department d ON d.dept_id = f.dept_id
GROUP BY d.dept_name, f.gender
ORDER BY d.dept_name, f.gender;

-- Q7. Overtime: likely the strongest driver ---------------------------
SELECT overtime,
       COUNT(*)                                       AS employees,
       SUM(attrition_flag)                            AS leavers,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY overtime;

-- Q8. Job roles ranked by attrition rate (RANK vs DENSE_RANK) --------
SELECT r.role_name,
       COUNT(*)                                         AS employees,
       SUM(f.attrition_flag)                            AS leavers,
       ROUND(SUM(f.attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct,
       RANK()       OVER (ORDER BY SUM(f.attrition_flag) / COUNT(*) DESC) AS rate_rank,
       DENSE_RANK() OVER (ORDER BY SUM(f.attrition_flag) / COUNT(*) DESC) AS rate_dense_rank
FROM fact_employee f
JOIN dim_job_role r ON r.role_id = f.role_id
GROUP BY r.role_name
ORDER BY rate_rank;

-- Q9. Pay gap: leavers vs stayers -------------------------------------
SELECT attrition,
       COUNT(*)                            AS employees,
       ROUND(AVG(monthly_income), 0)       AS avg_monthly_income,
       ROUND(MEDIAN(monthly_income), 0)    AS median_monthly_income,
       ROUND(AVG(years_at_company), 1)     AS avg_tenure_years,
       ROUND(AVG(job_satisfaction), 2)     AS avg_job_satisfaction
FROM fact_employee
GROUP BY attrition;

-- Q10. Attrition by job satisfaction and work-life balance -----------
SELECT job_satisfaction,
       COUNT(*)                                       AS employees,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY job_satisfaction
ORDER BY job_satisfaction;

SELECT work_life_balance,
       COUNT(*)                                       AS employees,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY work_life_balance
ORDER BY work_life_balance;

-- Q11. Age band ---------------------------------------------------------
SELECT age_band,
       COUNT(*)                                       AS employees,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee
GROUP BY age_band
ORDER BY age_band;

-- Q12. High-risk profile: overtime + low pay + short tenure ---------
SELECT COUNT(*)                                       AS employees,
       SUM(attrition_flag)                            AS leavers,
       ROUND(SUM(attrition_flag) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM fact_employee
WHERE overtime = 'Yes' AND salary_band = '<3K' AND tenure_band = '0-2 yrs';

-- Q13. Small-group warning (single-employee department test case) ---
SELECT dept_name, employees
FROM vw_attrition_by_dept
WHERE employees < 5;
