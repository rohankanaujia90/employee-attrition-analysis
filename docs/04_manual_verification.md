# Manual Verification of Attrition Rate

Acceptance criterion: *attrition rate correct by department and tenure; verify attrition rate manually.*

## Method (Excel, done independently of Python and SQL)

1. Open the **raw** Kaggle CSV in Excel.
2. Overall: `=COUNTIF(B:B,"Yes")` for leavers (B = Attrition) and `=COUNTA(B:B)-1` for the total.
3. By department: `=COUNTIFS(E:E,"Sales",B:B,"Yes") / COUNTIF(E:E,"Sales")` (E = Department).
   Repeat for each department.
4. By tenure: add a helper column with
   `=IF(AF2<=2,"0-2 yrs",IF(AF2<=5,"3-5 yrs",IF(AF2<=10,"6-10 yrs","11+ yrs")))`
   (adjust `AF` to the YearsAtCompany column), then use COUNTIFS the same way.
5. Write the numbers in the tables below, next to the Python output and the SQL output (Q1–Q3) and the Power BI card values.

*Reference values for the standard 1,470-row Kaggle file, for a sanity check:
1,470 employees, 237 leavers (16.12%); R&D 961/133 (13.84%), Sales 446/92 (20.63%),
HR 63/12 (19.05%). If your figures differ, check that you have the unmodified file.*

## Overall

| Source | Employees | Leavers | Attrition rate % |
|---|---|---|---|
| Excel (manual) | | | |
| Python | | | |
| Oracle SQL (Q1) | | | |
| Power BI card | | | |
| **Match?** | | | |

## By department

| Department | Excel % | Python % | SQL % (Q2) | Power BI % | Match? |
|---|---|---|---|---|---|
| Research & Development | | | | | |
| Sales | | | | | |
| Human Resources | | | | | |

## By tenure band

| Tenure band | Excel % | Python % | SQL % (Q3) | Power BI % | Match? |
|---|---|---|---|---|---|
| 0-2 yrs | | | | | |
| 3-5 yrs | | | | | |
| 6-10 yrs | | | | | |
| 11+ yrs | | | | | |

## SQL validation checks (06_validation_checks.sql)

| Check | Result |
|---|---|
| V1 row count staging = fact | |
| V2 leavers staging = fact | |
| V3 no duplicate employee IDs | |
| V4 dept totals = overall | |
| V5 tenure totals = overall | |
| V6 no orphan rows | |
| V7 tenure band matches years | |
