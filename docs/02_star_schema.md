# Star Schema

The clean CSV is loaded into a staging table, then split into one fact table and three dimension
tables. Bands (tenure, salary, age) stay on the fact table as attributes because each one comes
from a single column of the fact row.

```mermaid
erDiagram
    DIM_DEPARTMENT ||--o{ FACT_EMPLOYEE : "dept_id"
    DIM_JOB_ROLE ||--o{ FACT_EMPLOYEE : "role_id"
    DIM_EDUCATION_FIELD ||--o{ FACT_EMPLOYEE : "edu_field_id"

    DIM_DEPARTMENT {
        NUMBER dept_id PK
        VARCHAR2 dept_name
    }
    DIM_JOB_ROLE {
        NUMBER role_id PK
        VARCHAR2 role_name
    }
    DIM_EDUCATION_FIELD {
        NUMBER edu_field_id PK
        VARCHAR2 edu_field_name
    }
    FACT_EMPLOYEE {
        NUMBER employee_id PK
        NUMBER dept_id FK
        NUMBER role_id FK
        NUMBER edu_field_id FK
        NUMBER age
        VARCHAR2 age_band
        VARCHAR2 gender
        VARCHAR2 marital_status
        NUMBER job_level
        VARCHAR2 overtime
        NUMBER monthly_income
        VARCHAR2 salary_band
        NUMBER years_at_company
        VARCHAR2 tenure_band
        NUMBER job_satisfaction
        NUMBER work_life_balance
        VARCHAR2 attrition
        NUMBER attrition_flag
        NUMBER income_outlier_flag
    }
```

Data flow:

```
Kaggle CSV ──► Python (clean, band, flag) ──► hr_attrition_clean.csv
          ──► SQL*Loader ──► STG_HR_EMPLOYEE ──► DIM_* + FACT_EMPLOYEE ──► VW_* views ──► Power BI
```

*GitHub renders the Mermaid block as a diagram. For the report, paste it into https://mermaid.live
and export a PNG, or use SQL Developer → File → Data Modeler → Import → Data Dictionary.*
