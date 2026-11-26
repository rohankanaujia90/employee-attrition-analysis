"""
Employee Attrition Analysis - Step 1: clean, profile and prepare the IBM HR dataset.

Run from the project root:
    python python/01_clean_and_profile.py
    python python/01_clean_and_profile.py --input data/raw/some_other_file.csv

Outputs:
    data/clean/hr_attrition_clean.csv  -> loaded into Oracle (STG_HR_EMPLOYEE); also usable in Power BI
    reports/data_quality_report.md     -> data-quality report deliverable
    console output                     -> attrition figures to compare in the manual verification step
"""
import argparse
import re
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "data" / "raw" / "WA_Fn-UseC_-HR-Employee-Attrition.csv"
CLEAN_OUT = ROOT / "data" / "clean" / "hr_attrition_clean.csv"
REPORT_OUT = ROOT / "reports" / "data_quality_report.md"

SMALL_GROUP_THRESHOLD = 5  # groups smaller than this give unreliable attrition rates

# Column order MUST match sql/02_load_staging.ctl and STG_HR_EMPLOYEE in sql/01_ddl.sql
CLEAN_COLS = [
    "EMPLOYEE_NUMBER", "AGE", "AGE_BAND", "GENDER", "MARITAL_STATUS",
    "DEPARTMENT", "JOB_ROLE", "JOB_LEVEL", "EDUCATION", "EDUCATION_FIELD",
    "BUSINESS_TRAVEL", "DISTANCE_FROM_HOME", "OVERTIME",
    "MONTHLY_INCOME", "SALARY_BAND", "PERCENT_SALARY_HIKE", "STOCK_OPTION_LEVEL",
    "TOTAL_WORKING_YEARS", "YEARS_AT_COMPANY", "TENURE_BAND", "YEARS_IN_CURRENT_ROLE",
    "YEARS_SINCE_LAST_PROMOTION", "YEARS_WITH_CURR_MANAGER", "NUM_COMPANIES_WORKED",
    "TRAINING_TIMES_LAST_YEAR", "ENVIRONMENT_SATISFACTION", "JOB_SATISFACTION",
    "RELATIONSHIP_SATISFACTION", "WORK_LIFE_BALANCE", "JOB_INVOLVEMENT",
    "PERFORMANCE_RATING", "ATTRITION", "ATTRITION_FLAG", "INCOME_OUTLIER_FLAG",
]

NUMERIC_COLS = [
    "EMPLOYEE_NUMBER", "AGE", "JOB_LEVEL", "EDUCATION", "DISTANCE_FROM_HOME",
    "MONTHLY_INCOME", "PERCENT_SALARY_HIKE", "STOCK_OPTION_LEVEL", "TOTAL_WORKING_YEARS",
    "YEARS_AT_COMPANY", "YEARS_IN_CURRENT_ROLE", "YEARS_SINCE_LAST_PROMOTION",
    "YEARS_WITH_CURR_MANAGER", "NUM_COMPANIES_WORKED", "TRAINING_TIMES_LAST_YEAR",
    "ENVIRONMENT_SATISFACTION", "JOB_SATISFACTION", "RELATIONSHIP_SATISFACTION",
    "WORK_LIFE_BALANCE", "JOB_INVOLVEMENT", "PERFORMANCE_RATING",
]

REQUIRED = ["EMPLOYEE_NUMBER", "ATTRITION", "DEPARTMENT", "GENDER", "YEARS_AT_COMPANY", "MONTHLY_INCOME"]


def to_snake_upper(name: str) -> str:
    """'YearsWithCurrManager' -> 'YEARS_WITH_CURR_MANAGER'."""
    name = name.strip().lstrip("﻿")
    snake = re.sub(r"(?<!^)(?=[A-Z])", "_", name).upper()
    return {"OVER_TIME": "OVERTIME"}.get(snake, snake)


def rate_table(df: pd.DataFrame, col: str) -> pd.DataFrame:
    g = (
        df.groupby(col, observed=True)["ATTRITION_FLAG"]
        .agg(employees="count", leavers="sum")
        .reset_index()
    )
    g["attrition_rate_pct"] = (g["leavers"] / g["employees"] * 100).round(2)
    return g


def md_table(df: pd.DataFrame) -> str:
    """Minimal markdown table (avoids needing the 'tabulate' package)."""
    cols = [str(c) for c in df.columns]
    lines = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    for row in df.itertuples(index=False):
        lines.append("| " + " | ".join(str(v) for v in row) + " |")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Clean and profile the IBM HR attrition dataset")
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    args = parser.parse_args()

    if not args.input.exists():
        raise SystemExit(f"Input file not found: {args.input}\nDownload it from Kaggle into data/raw/ (see README).")

    log: list[str] = []  # human-readable notes for the report

    # ---------------------------------------------------------------- 1. Load
    raw = pd.read_csv(args.input, encoding="utf-8-sig")
    raw_rows, raw_cols = raw.shape
    df = raw.copy()
    df.columns = [to_snake_upper(c) for c in df.columns]

    missing_required = [c for c in REQUIRED if c not in df.columns]
    if missing_required:
        raise SystemExit(f"Required columns missing from input: {missing_required}")

    # Trim whitespace in text columns
    for c in df.select_dtypes(include="object").columns:
        df[c] = df[c].str.strip()

    # ------------------------------------------------- 2. Null profile (raw)
    null_profile = df.isna().sum()
    null_profile = null_profile[null_profile > 0]

    # ----------------------------------------------- 3. Constant columns
    constant_cols = [c for c in df.columns if df[c].nunique(dropna=False) <= 1]
    df = df.drop(columns=constant_cols)
    if constant_cols:
        log.append(f"Dropped constant columns (one value only): {', '.join(constant_cols)}.")

    # ------------------------------------------------------ 4. Duplicates
    full_dupes = int(df.duplicated().sum())
    df = df.drop_duplicates()
    id_dupes = int(df.duplicated(subset="EMPLOYEE_NUMBER").sum())
    dupe_ids = df.loc[df.duplicated(subset="EMPLOYEE_NUMBER", keep=False), "EMPLOYEE_NUMBER"].unique().tolist()
    df = df.drop_duplicates(subset="EMPLOYEE_NUMBER", keep="first")
    log.append(f"Fully duplicated rows removed: {full_dupes}.")
    log.append(f"Duplicate EmployeeNumber rows removed (kept first): {id_dupes}"
               + (f" (IDs: {dupe_ids[:20]})." if dupe_ids else "."))

    # -------------------------------------------------- 5. Attrition values
    df["ATTRITION"] = df["ATTRITION"].astype(str).str.strip().str.title()
    invalid_attr = ~df["ATTRITION"].isin(["Yes", "No"])
    n_invalid_attr = int(invalid_attr.sum())
    df = df[~invalid_attr].copy()
    log.append(f"Rows with invalid Attrition value (not Yes/No) dropped: {n_invalid_attr}.")
    df["ATTRITION_FLAG"] = (df["ATTRITION"] == "Yes").astype(int)

    # ------------------------------------------------- 6. Numeric coercion
    for c in [c for c in NUMERIC_COLS if c in df.columns]:
        before_nulls = df[c].isna().sum()
        df[c] = pd.to_numeric(df[c], errors="coerce")
        bad = int(df[c].isna().sum() - before_nulls)
        if bad:
            log.append(f"`{c}`: {bad} non-numeric values set to null.")
    for c in ["AGE", "YEARS_AT_COMPANY", "MONTHLY_INCOME", "TOTAL_WORKING_YEARS"]:
        neg = df[c] < 0
        if neg.any():
            log.append(f"`{c}`: {int(neg.sum())} negative values set to null.")
            df.loc[neg, c] = np.nan

    # --------------------------------------------- 7. Missing tenure
    missing_tenure = int(df["YEARS_AT_COMPANY"].isna().sum())
    log.append(f"Missing tenure (YearsAtCompany): {missing_tenure} rows. Kept, with TENURE_BAND = 'Unknown'.")
    inconsistent_tenure = int((df["YEARS_AT_COMPANY"] > df["TOTAL_WORKING_YEARS"]).sum())
    log.append(f"Tenure greater than total working years (inconsistent): {inconsistent_tenure} rows. Kept and reported.")

    # --------------------------------------------- 8. Salary outliers (IQR)
    q1, q3 = df["MONTHLY_INCOME"].quantile([0.25, 0.75])
    iqr = q3 - q1
    low, high = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    df["INCOME_OUTLIER_FLAG"] = ((df["MONTHLY_INCOME"] < low) | (df["MONTHLY_INCOME"] > high)).astype(int)
    n_outliers = int(df["INCOME_OUTLIER_FLAG"].sum())
    log.append(
        f"Salary outliers (IQR rule, outside {low:,.0f} to {high:,.0f}): {n_outliers} rows flagged "
        "(INCOME_OUTLIER_FLAG = 1). Kept, because they are real high earners such as managers and directors."
    )

    # --------------------------------------------- 9. Bands
    df["TENURE_BAND"] = pd.cut(
        df["YEARS_AT_COMPANY"], bins=[-0.1, 2, 5, 10, np.inf],
        labels=["0-2 yrs", "3-5 yrs", "6-10 yrs", "11+ yrs"],
    ).astype(object).fillna("Unknown")
    df["SALARY_BAND"] = pd.cut(
        df["MONTHLY_INCOME"], bins=[-0.1, 2999.99, 5999.99, 9999.99, np.inf],
        labels=["<3K", "3K-6K", "6K-10K", "10K+"],
    ).astype(object).fillna("Unknown")
    df["AGE_BAND"] = pd.cut(
        df["AGE"], bins=[0, 25, 35, 45, 120],
        labels=["18-25", "26-35", "36-45", "46-60"],
    ).astype(object).fillna("Unknown")

    # --------------------------------------------- 10. Small groups
    small_groups = []
    for col in ["DEPARTMENT", "JOB_ROLE"]:
        counts = df[col].value_counts()
        for name, n in counts[counts < SMALL_GROUP_THRESHOLD].items():
            small_groups.append(f"{col} = '{name}' has only {n} employee(s); its attrition rate is unreliable.")
    if not small_groups:
        small_groups.append(f"No department or job role has fewer than {SMALL_GROUP_THRESHOLD} employees.")

    # --------------------------------------------- 11. Write clean CSV
    CLEAN_OUT.parent.mkdir(parents=True, exist_ok=True)
    out_cols = [c for c in CLEAN_COLS if c in df.columns]
    missing_out = [c for c in CLEAN_COLS if c not in df.columns]
    if missing_out:
        raise SystemExit(f"Columns expected by the SQL loader are missing: {missing_out}")
    int_cols = [c for c in NUMERIC_COLS if df[c].notna().all()]
    df[int_cols] = df[int_cols].astype(int)
    df[out_cols].to_csv(CLEAN_OUT, index=False)

    # --------------------------------------------- 12. Summary tables
    total, leavers = len(df), int(df["ATTRITION_FLAG"].sum())
    overall_rate = round(leavers / total * 100, 2)
    breakdowns = {
        "Department": rate_table(df, "DEPARTMENT"),
        "Gender": rate_table(df, "GENDER"),
        "Tenure band": rate_table(df, "TENURE_BAND"),
        "Salary band": rate_table(df, "SALARY_BAND"),
        "Overtime": rate_table(df, "OVERTIME"),
        "Job satisfaction (1=Low, 4=Very High)": rate_table(df, "JOB_SATISFACTION"),
    }
    income_compare = (
        df.groupby("ATTRITION")["MONTHLY_INCOME"].agg(["count", "mean", "median"]).round(0).reset_index()
    )

    # --------------------------------------------- 13. Report
    REPORT_OUT.parent.mkdir(parents=True, exist_ok=True)
    parts = [
        "# Data-Quality Report: Employee Attrition Analysis",
        f"_Generated {datetime.now():%Y-%m-%d %H:%M} by `python/01_clean_and_profile.py`_",
        "## Row and column reconciliation",
        md_table(pd.DataFrame({
            "stage": ["Raw file", "Clean file"],
            "rows": [raw_rows, total],
            "columns": [raw_cols, len(out_cols)],
        })),
        f"Rows removed: **{raw_rows - total}**. Clean file: `data/clean/{CLEAN_OUT.name}`.",
        "## Null values in the raw file",
        md_table(null_profile.rename("nulls").reset_index().rename(columns={"index": "column"}))
        if not null_profile.empty else "No null values found in any column.",
        "## Checks and actions",
        "\n".join(f"- {line}" for line in log),
        "## Small groups (single-employee department test case)",
        "\n".join(f"- {line}" for line in small_groups),
        "## Headline figures",
        f"- Total employees: **{total}**\n- Leavers: **{leavers}**\n- Overall attrition rate: **{overall_rate}%**",
        "## Monthly income: leavers vs stayers",
        md_table(income_compare),
    ]
    for title, table in breakdowns.items():
        parts += [f"## Attrition by {title.lower()}", md_table(table)]
    REPORT_OUT.write_text("\n\n".join(parts) + "\n", encoding="utf-8")

    # --------------------------------------------- 14. Console summary
    print(f"Raw: {raw_rows} rows x {raw_cols} cols  ->  Clean: {total} rows x {len(out_cols)} cols")
    print(f"Total employees: {total} | Leavers: {leavers} | Attrition rate: {overall_rate}%\n")
    for title, table in breakdowns.items():
        print(f"--- {title} ---")
        print(table.to_string(index=False), "\n")
    print(f"Clean CSV written to : {CLEAN_OUT}")
    print(f"Report written to    : {REPORT_OUT}")


if __name__ == "__main__":
    main()
