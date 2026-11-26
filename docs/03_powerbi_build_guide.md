# Power BI Build Guide

Save the file as `powerbi/Employee_Attrition.pbix`.

## 1. Get the data

**Option A, Oracle (preferred, because it shows the full pipeline):**
Home → Get Data → Oracle database → Server: `localhost:1521/XEPDB1` → Import → sign in with your
schema user → choose **VW_EMPLOYEE_ANALYTICS**.
*(Power BI needs the 64-bit Oracle client or ODAC. If the connector reports a missing provider,
install "Oracle Client for Microsoft Tools" from oracle.com.)*

**Option B, CSV fallback:** Get Data → Text/CSV → `data/clean/hr_attrition_clean.csv`.
If you use this option, add the sort-order columns from step 2 yourself.

Rename the table to **Employees**.

## 2. Model prep (Power Query / Data view)

- Check the data types: `MONTHLY_INCOME` and `YEARS_AT_COMPANY` must be whole numbers, and `ATTRITION_FLAG` a whole number.
- Select `TENURE_BAND` → Column tools → **Sort by column** → `TENURE_BAND_ORDER`. Do the same for `SALARY_BAND` with `SALARY_BAND_ORDER`.
- Build a hierarchy **Org**: `DEPARTMENT` → `JOB_ROLE`. It powers the drill-down.
- Hide the `*_ORDER` and `EMPLOYEE_ID` columns from report view.

## 3. DAX measures

Create a blank table named `_Measures` (Enter data → OK) and add:

```DAX
Total Employees = COUNTROWS ( Employees )

Leavers = SUM ( Employees[ATTRITION_FLAG] )

Active Employees = [Total Employees] - [Leavers]

Attrition Rate % = DIVIDE ( [Leavers], [Total Employees], 0 )

Avg Monthly Income = AVERAGE ( Employees[MONTHLY_INCOME] )

Avg Income Leavers =
    CALCULATE ( [Avg Monthly Income], Employees[ATTRITION] = "Yes" )

Avg Income Stayers =
    CALCULATE ( [Avg Monthly Income], Employees[ATTRITION] = "No" )

Avg Tenure (yrs) = AVERAGE ( Employees[YEARS_AT_COMPANY] )

Overtime Attrition Rate % =
    CALCULATE ( [Attrition Rate %], Employees[OVERTIME] = "Yes" )

Attrition vs Company Avg (pp) =
    ( [Attrition Rate %]
      - CALCULATE ( [Attrition Rate %], ALLSELECTED ( Employees ) ) ) * 100
```

Format `Attrition Rate %` and `Overtime Attrition Rate %` as **Percentage, 1 decimal**.

## 4. Report pages

### Page 1: Overview
| Visual | Fields |
|---|---|
| 5 KPI cards | Total Employees, Leavers, Attrition Rate %, Avg Monthly Income, Avg Tenure (yrs) |
| Clustered bar | Axis: DEPARTMENT · Values: Attrition Rate % · Tooltip: Leavers, Total Employees |
| Donut | Legend: GENDER · Values: Leavers |
| Column chart | Axis: TENURE_BAND · Values: Attrition Rate % |
| **Slicer** | DEPARTMENT (dropdown) |
| **Slicer** | GENDER (buttons/tiles) |

### Page 2: Attrition Drivers
| Visual | Fields |
|---|---|
| Column chart | SALARY_BAND vs Attrition Rate % |
| Clustered column | OVERTIME vs Attrition Rate % |
| Line or column | JOB_SATISFACTION_LABEL vs Attrition Rate % |
| Column chart | AGE_BAND vs Attrition Rate % |
| Cards | Avg Income Leavers vs Avg Income Stayers |
| Slicers | Sync DEPARTMENT and GENDER from page 1 (View → Sync slicers) |

### Page 3: Drill-down
| Visual | Fields |
|---|---|
| Bar chart with **Org** hierarchy | Turn on drill mode (↓ arrow) to go from Department to Job Role |
| Matrix | Rows: DEPARTMENT, JOB_ROLE · Columns: TENURE_BAND · Values: Attrition Rate % · conditional-format background (red = high) |
| Table | Top job roles: JOB_ROLE, Total Employees, Leavers, Attrition Rate % (sorted descending) |

Optional: right-click a department bar → **Drill through** to a detail page that shows a table
of employees in that department.

## 5. Check before you submit

- With no slicers applied, the cards must match the SQL results: `Total Employees` = Q1 total, `Attrition Rate %` = Q1 rate.
- Set the Department slicer to each department in turn and confirm the rate matches SQL query Q2.
- Take screenshots of each page for the report and the README.
