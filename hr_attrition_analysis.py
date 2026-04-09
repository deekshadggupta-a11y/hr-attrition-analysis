# ============================================================
# HR ATTRITION ANALYSIS — Portfolio Project
# Tools: Python (Pandas + NumPy)
# Dataset: IBM HR Analytics (Kaggle)
# Author: Deeksha Gupta
# ============================================================

import pandas as pd
import numpy as np

# ============================================================
# STEP 1 — LOAD DATA
# ============================================================

df = pd.read_csv('WA_Fn-UseC_-HR-Employee-Attrition.csv')

print("=" * 50)
print("STEP 1: DATA LOADED")
print("=" * 50)
print(f"Rows: {df.shape[0]}, Columns: {df.shape[1]}")
print()


# ============================================================
# STEP 2 — EXPLORE DATA
# ============================================================

print("=" * 50)
print("STEP 2: DATA EXPLORATION")
print("=" * 50)

# First look at the data
print("First 5 rows:")
print(df.head())
print()

# Column names and data types
print("Column Data Types:")
print(df.dtypes)
print()

# Check for missing values
print("Missing Values per Column:")
print(df.isnull().sum())
print()

# Statistical summary
print("Statistical Summary:")
print(df.describe())
print()


# ============================================================
# STEP 3 — CLEAN DATA
# ============================================================

print("=" * 50)
print("STEP 3: DATA CLEANING")
print("=" * 50)

# 3a. Drop columns that have no analytical value
# EmployeeCount, Over18, StandardHours are same for all rows
cols_to_drop = ['EmployeeCount', 'Over18', 'StandardHours']
df.drop(columns=cols_to_drop, inplace=True)
print(f"Dropped columns: {cols_to_drop}")

# 3b. Convert Attrition from Yes/No to 1/0 for calculations
df['AttritionFlag'] = df['Attrition'].apply(lambda x: 1 if x == 'Yes' else 0)
print("Converted Attrition Yes/No → 1/0 (AttritionFlag column added)")

# 3c. Handle missing values (IBM dataset is clean but good practice)
print(f"Missing values after cleaning: {df.isnull().sum().sum()}")
print()


# ============================================================
# STEP 4 — ADD CALCULATED COLUMNS
# ============================================================

print("=" * 50)
print("STEP 4: ADDING CALCULATED COLUMNS")
print("=" * 50)

# 4a. Salary Band — categorize employees by salary
def salary_band(salary):
    if salary < 3000:
        return 'Low'
    elif salary < 6000:
        return 'Medium'
    elif salary < 10000:
        return 'High'
    else:
        return 'Very High'

df['SalaryBand'] = df['MonthlyIncome'].apply(salary_band)
print("Added SalaryBand column — Low / Medium / High / Very High")

# 4b. Tenure Band — group employees by years at company
def tenure_band(years):
    if years <= 2:
        return 'New (0-2 yrs)'
    elif years <= 5:
        return 'Mid (3-5 yrs)'
    elif years <= 10:
        return 'Senior (6-10 yrs)'
    else:
        return 'Veteran (10+ yrs)'

df['TenureBand'] = df['YearsAtCompany'].apply(tenure_band)
print("Added TenureBand column — New / Mid / Senior / Veteran")

# 4c. Flag high risk employees using NumPy
# High risk = Low job satisfaction AND low salary AND young age
low_satisfaction = df['JobSatisfaction'] <= 2
low_income_threshold = np.percentile(df['MonthlyIncome'], 25)
low_income = df['MonthlyIncome'] < low_income_threshold
young_employee = df['Age'] < 35

df['HighRisk'] = (low_satisfaction & low_income & young_employee).astype(int)
print(f"Added HighRisk flag — threshold salary: ${low_income_threshold:.0f}")
print(f"High risk employees identified: {df['HighRisk'].sum()}")
print()


# ============================================================
# STEP 5 — ANALYSIS
# ============================================================

print("=" * 50)
print("STEP 5: KEY BUSINESS INSIGHTS")
print("=" * 50)

# 5a. Overall attrition rate
total_employees = len(df)
attrition_count = df['AttritionFlag'].sum()
attrition_rate = (attrition_count / total_employees) * 100
print(f"Overall Attrition Rate: {attrition_rate:.1f}%")
print(f"Total Employees: {total_employees} | Left: {attrition_count}")
print()

# 5b. Attrition by Department
print("Attrition Rate by Department:")
dept_attrition = df.groupby('Department').agg(
    TotalEmployees=('AttritionFlag', 'count'),
    AttritionCount=('AttritionFlag', 'sum')
).reset_index()
dept_attrition['AttritionRate%'] = (
    dept_attrition['AttritionCount'] / dept_attrition['TotalEmployees'] * 100
).round(1)
print(dept_attrition.to_string(index=False))
print()

# 5c. Attrition by Salary Band
print("Attrition Rate by Salary Band:")
salary_attrition = df.groupby('SalaryBand').agg(
    TotalEmployees=('AttritionFlag', 'count'),
    AttritionCount=('AttritionFlag', 'sum')
).reset_index()
salary_attrition['AttritionRate%'] = (
    salary_attrition['AttritionCount'] / salary_attrition['TotalEmployees'] * 100
).round(1)
print(salary_attrition.to_string(index=False))
print()

# 5d. Attrition by Tenure Band
print("Attrition Rate by Tenure:")
tenure_attrition = df.groupby('TenureBand').agg(
    TotalEmployees=('AttritionFlag', 'count'),
    AttritionCount=('AttritionFlag', 'sum')
).reset_index()
tenure_attrition['AttritionRate%'] = (
    tenure_attrition['AttritionCount'] / tenure_attrition['TotalEmployees'] * 100
).round(1)
print(tenure_attrition.to_string(index=False))
print()

# 5e. Average salary of employees who left vs stayed
print("Average Monthly Income — Left vs Stayed:")
income_comparison = df.groupby('Attrition')['MonthlyIncome'].mean().round(0)
print(income_comparison)
print()

# 5f. NumPy statistical analysis on income
print("Monthly Income Statistics (NumPy):")
income_arr = df['MonthlyIncome'].values
print(f"  Mean:   ${np.mean(income_arr):,.0f}")
print(f"  Median: ${np.median(income_arr):,.0f}")
print(f"  Std Dev:${np.std(income_arr):,.0f}")
print(f"  25th Percentile: ${np.percentile(income_arr, 25):,.0f}")
print(f"  75th Percentile: ${np.percentile(income_arr, 75):,.0f}")
print(f"  90th Percentile: ${np.percentile(income_arr, 90):,.0f}")
print()

# 5g. High risk employee summary
print("High Risk Employee Summary:")
high_risk_summary = df[df['HighRisk'] == 1].groupby('Department').agg(
    HighRiskCount=('HighRisk', 'sum'),
    AttritionAmongHighRisk=('AttritionFlag', 'sum')
).reset_index()
print(high_risk_summary.to_string(index=False))
print()


# ============================================================
# STEP 6 — EXPORT CLEAN DATA FOR POWER BI
# ============================================================

print("=" * 50)
print("STEP 6: EXPORTING CLEAN DATA")
print("=" * 50)

# Export main cleaned dataset
df.to_csv('hr_clean_data.csv', index=False)
print("Exported: hr_clean_data.csv — main dataset for Power BI")

# Export department summary for SQL analysis
dept_attrition.to_csv('hr_dept_summary.csv', index=False)
print("Exported: hr_dept_summary.csv — department summary")

# Export high risk employees
df[df['HighRisk'] == 1].to_csv('hr_high_risk.csv', index=False)
print("Exported: hr_high_risk.csv — high risk employees")

print()
print("=" * 50)
print("PYTHON ANALYSIS COMPLETE!")
print("Next step: Load hr_clean_data.csv into SQL for queries")
print("Then: Load into Power BI for dashboard")
print("=" * 50)
