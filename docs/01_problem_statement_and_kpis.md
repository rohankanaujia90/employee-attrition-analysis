# Problem Statement and KPI Definitions

## Problem statement

Employee attrition is expensive. Every leaver means hiring and training costs, lost knowledge and
lower team productivity. The HR team of a mid-sized company (1,470 employees) wants to know:

1. **How big is the problem?** What is the overall attrition rate?
2. **Where is it concentrated?** Which departments, job roles, tenure groups and salary bands lose
   the most people?
3. **What drives it?** Do overtime, low pay, low job satisfaction or short tenure go with higher attrition?

**Goal:** a verified, reproducible pipeline (Python → Oracle SQL → Power BI) and a dashboard that
lets HR managers slice attrition by department and gender, plus at least 3 insights backed by charts.

**Scope:** one snapshot of employee records (IBM HR Analytics dataset). The project is descriptive
analysis, not a prediction model.

## KPI definitions

| # | KPI | Formula | Notes |
|---|---|---|---|
| 1 | Total Employees | `COUNT(employee_id)` | Everyone in the snapshot (stayed + left) |
| 2 | Leavers | `COUNT(*) WHERE attrition = 'Yes'` | Stored as `attrition_flag = 1` |
| 3 | **Attrition Rate %** | `Leavers / Total Employees × 100` | Main KPI. Calculated per group for every breakdown |
| 4 | Active Employees | `Total Employees − Leavers` | |
| 5 | Avg Monthly Income (Leavers vs Stayers) | `AVG(monthly_income)` split by attrition | Shows the pay gap |
| 6 | Avg Tenure | `AVG(years_at_company)` | In years |
| 7 | Overtime Attrition Rate % | Attrition Rate where `overtime = 'Yes'` | Driver KPI |

## Band definitions (used in Python, SQL and Power BI)

| Band | Source column | Groups |
|---|---|---|
| Tenure band | `YearsAtCompany` | `0-2 yrs`, `3-5 yrs`, `6-10 yrs`, `11+ yrs`, `Unknown` (missing tenure) |
| Salary band | `MonthlyIncome` | `<3K`, `3K-6K`, `6K-10K`, `10K+` |
| Age band | `Age` | `18-25`, `26-35`, `36-45`, `46-60` |

## Acceptance criteria (from the project list)

- Attrition rate is correct by department and tenure, checked by hand (`docs/04_manual_verification.md`).
- At least 3 insights, each backed by a chart (`docs/05_insights_summary.md`).
- The dashboard has slicers for **department** and **gender**.

## Test cases handled

| Test case | How it is handled |
|---|---|
| Missing tenure | Row is kept; `TENURE_BAND = 'Unknown'`; count logged in the data-quality report |
| Salary outliers | Flagged with the IQR rule (`INCOME_OUTLIER_FLAG = 1`). Kept, because high earners are real employees |
| Single-employee (small) departments or roles | Groups with fewer than 5 employees are listed in the report with a warning that their rate is unreliable |
| Duplicate employee IDs | The first record is kept and the rest are logged |
| Invalid attrition values | Anything other than Yes/No is dropped and logged |
| Constant columns | `EmployeeCount`, `Over18` and `StandardHours` have one value each and are dropped |
