-- =====================================================================
-- Employee Attrition Analysis | 06_validation_checks.sql
-- Every check should return PASS. Paste the results into docs/04_manual_verification.md.
-- =====================================================================

-- V1. Row counts reconcile: staging = fact (nothing lost in the joins)
SELECT 'V1 row count staging = fact' AS check_name,
       (SELECT COUNT(*) FROM stg_hr_employee) AS staging_rows,
       (SELECT COUNT(*) FROM fact_employee)   AS fact_rows,
       CASE WHEN (SELECT COUNT(*) FROM stg_hr_employee) = (SELECT COUNT(*) FROM fact_employee)
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM dual;

-- V2. Leaver counts reconcile
SELECT 'V2 leavers staging = fact' AS check_name,
       (SELECT SUM(attrition_flag) FROM stg_hr_employee) AS staging_leavers,
       (SELECT SUM(attrition_flag) FROM fact_employee)   AS fact_leavers,
       CASE WHEN (SELECT SUM(attrition_flag) FROM stg_hr_employee)
               = (SELECT SUM(attrition_flag) FROM fact_employee)
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM dual;

-- V3. No duplicate employee IDs in staging
SELECT 'V3 no duplicate employee IDs' AS check_name,
       COUNT(*) AS duplicate_ids,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM (SELECT employee_number FROM stg_hr_employee GROUP BY employee_number HAVING COUNT(*) > 1);

-- V4. Department totals add up to the overall total
SELECT 'V4 dept totals = overall' AS check_name,
       (SELECT SUM(employees) FROM vw_attrition_by_dept) AS sum_of_depts,
       (SELECT COUNT(*) FROM fact_employee)              AS overall,
       CASE WHEN (SELECT SUM(employees) FROM vw_attrition_by_dept) = (SELECT COUNT(*) FROM fact_employee)
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM dual;

-- V5. Tenure band totals add up to the overall total (no employee lost or counted twice)
SELECT 'V5 tenure totals = overall' AS check_name,
       (SELECT SUM(employees) FROM vw_attrition_by_tenure) AS sum_of_bands,
       (SELECT COUNT(*) FROM fact_employee)                AS overall,
       CASE WHEN (SELECT SUM(employees) FROM vw_attrition_by_tenure) = (SELECT COUNT(*) FROM fact_employee)
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM dual;

-- V6. Rows that failed to join to a dimension (orphans)
SELECT 'V6 staging rows with no department/role match' AS check_name,
       COUNT(*) AS orphan_rows,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM stg_hr_employee s
WHERE NOT EXISTS (SELECT 1 FROM fact_employee f WHERE f.employee_id = s.employee_number);

-- V7. Tenure band is consistent with years_at_company
SELECT 'V7 tenure band matches years' AS check_name,
       COUNT(*) AS mismatches,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM fact_employee
WHERE NOT (
       (years_at_company BETWEEN 0 AND 2  AND tenure_band = '0-2 yrs')
    OR (years_at_company BETWEEN 3 AND 5  AND tenure_band = '3-5 yrs')
    OR (years_at_company BETWEEN 6 AND 10 AND tenure_band = '6-10 yrs')
    OR (years_at_company > 10             AND tenure_band = '11+ yrs')
    OR (years_at_company IS NULL          AND tenure_band = 'Unknown')
);

-- V8. Missing-value summary for key columns
SELECT 'V8 nulls in key columns' AS check_name,
       SUM(CASE WHEN years_at_company IS NULL THEN 1 ELSE 0 END) AS null_tenure,
       SUM(CASE WHEN monthly_income   IS NULL THEN 1 ELSE 0 END) AS null_income,
       SUM(CASE WHEN gender           IS NULL THEN 1 ELSE 0 END) AS null_gender
FROM fact_employee;
