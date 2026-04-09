# 📊 HR Attrition Analysis — End to End Data Analytics Project

![Python](https://img.shields.io/badge/Python-3.10-blue?logo=python)
![Pandas](https://img.shields.io/badge/Pandas-2.0-darkblue?logo=pandas)
![NumPy](https://img.shields.io/badge/NumPy-1.24-lightblue?logo=numpy)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue?logo=postgresql)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-yellow?logo=powerbi)
![Status](https://img.shields.io/badge/Status-Completed-green)

---

## 📌 Project Overview

This project performs a **complete end-to-end HR Attrition Analysis** on the IBM HR Analytics dataset (1,470 employees) to identify key factors driving employee attrition and provide actionable insights for HR teams.

The project is structured in **three layers:**

```
Layer 1 — Python (Pandas + NumPy)
    → Data cleaning, transformation & statistical analysis
            ↓
Layer 2 — SQL (PostgreSQL)
    → Analytical queries & aggregations
            ↓
Layer 3 — Power BI
    → Interactive dashboard with DAX, RLS & slicers
```

---

## 🎯 Business Questions Answered

| # | Business Question | Tool Used |
|---|---|---|
| 1 | What is the overall attrition rate? | Python + SQL + Power BI |
| 2 | Which department has the highest attrition? | SQL + Power BI |
| 3 | Do low salary employees leave more? | Python + SQL + Power BI |
| 4 | Do new employees leave more than veterans? | Python + SQL + Power BI |
| 5 | What is the average salary of employees who left vs stayed? | SQL |
| 6 | Which job roles have highest attrition? | SQL + Power BI |
| 7 | Which employees are at highest risk of leaving? | Python + Power BI |

---

## 📁 Project Structure

```
hr-attrition-analysis/
│
├── 📂 data/
│   ├── WA_Fn-UseC_-HR-Employee-Attrition.csv    ← Raw dataset (Kaggle)
│   ├── hr_clean_data.csv                          ← Cleaned dataset (Python output)
│   ├── hr_dept_summary.csv                        ← Department summary
│   ├── hr_high_risk.csv                           ← High risk employees
│   └── user_mapping.csv                           ← RLS user mapping table
│
├── 📂 python/
│   └── HR_attrition_analysis.py                  ← Complete Python script
│
├── 📂 sql/
│   └── attrition_queries.sql                     ← All 7 SQL queries
│
├── 📂 powerbi/
│   └── HR_attrition_analysis_dashboard.pbix      ← Power BI dashboard file
│
├── 📂 screenshots/
│   └── Dashboard.png                             ← Dashboard screenshot
│
└── README.md                                      ← You are here
```

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| **Python 3.10** | Data cleaning, transformation, feature engineering |
| **Pandas** | DataFrame operations, groupby analysis, missing value handling |
| **NumPy** | Statistical calculations, percentile analysis, array operations |
| **PostgreSQL** | Database storage, analytical SQL queries |
| **SQLAlchemy** | Python to PostgreSQL connection |
| **Power BI Desktop** | Interactive dashboard, DAX measures, RLS |
| **DAX** | KPI measures — Attrition Rate, Total Attrition |
| **Power Query** | Data transformation in Power BI |

---

## 📊 Dataset

**Source:** [IBM HR Analytics Employee Attrition Dataset — Kaggle](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset)

| Property | Value |
|---|---|
| Rows | 1,470 employees |
| Columns | 35 features |
| Target | Attrition (Yes/No) |
| Domain | Human Resources |

**Key columns used:**
- `Age`, `Department`, `JobRole`, `MonthlyIncome`
- `YearsAtCompany`, `JobSatisfaction`, `Attrition`
- `BusinessTravel`, `OverTime`, `EducationField`

---

## 🐍 Layer 1 — Python Analysis

### Setup

```bash
pip install pandas numpy sqlalchemy psycopg2-binary
```

### What the script does:

**Step 1 — Load & Explore**
```python
import pandas as pd
import numpy as np

df = pd.read_csv('WA_Fn-UseC_-HR-Employee-Attrition.csv')
print(df.shape)        # (1470, 35)
print(df.isnull().sum()) # check missing values
```

**Step 2 — Clean Data**
```python
# Drop columns with no analytical value
df.drop(columns=['EmployeeCount', 'Over18', 'StandardHours'], inplace=True)

# Convert Attrition Yes/No → 1/0
df['AttritionFlag'] = df['Attrition'].apply(lambda x: 1 if x == 'Yes' else 0)
```

**Step 3 — Feature Engineering**
```python
# Salary Band categorization
def salary_band(salary):
    if salary < 3000:   return 'Low'
    elif salary < 6000: return 'Medium'
    elif salary < 10000: return 'High'
    else: return 'Very High'

df['SalaryBand'] = df['MonthlyIncome'].apply(salary_band)

# Tenure Band categorization
def tenure_band(years):
    if years <= 2:   return 'New(0-2y)'
    elif years <= 5: return 'Mid(3-5y)'
    elif years <= 10: return 'Senior(6-10y)'
    else: return 'Veteran(10+y)'

df['TenureBand'] = df['YearsAtCompany'].apply(tenure_band)

# High Risk Flag using NumPy percentile
low_income_threshold = np.percentile(df['MonthlyIncome'], 25)
df['HighRisk'] = (
    (df['JobSatisfaction'] <= 2) &
    (df['MonthlyIncome'] < low_income_threshold) &
    (df['Age'] < 35)
).astype(int)
```

**Step 4 — Key Insights from Python**

```python
# Overall attrition rate
attrition_rate = df['AttritionFlag'].mean() * 100
print(f"Overall Attrition Rate: {attrition_rate:.1f}%")  # 16.1%

# Attrition by department
dept_attrition = df.groupby('Department').agg(
    TotalEmployees=('AttritionFlag', 'count'),
    AttritionCount=('AttritionFlag', 'sum')
).reset_index()
dept_attrition['AttritionRate%'] = (
    dept_attrition['AttritionCount'] / dept_attrition['TotalEmployees'] * 100
).round(1)
```

**Step 5 — Load to PostgreSQL**
```python
from sqlalchemy import create_engine
from urllib.parse import quote_plus

engine = create_engine(
    f"postgresql+psycopg2://postgres:{quote_plus('yourpassword')}@localhost:5432/attrition_analysis"
)
df.to_sql('hr_attrition', engine, if_exists='replace', index=False)
```

---

## 🗄️ Layer 2 — SQL Queries

### Query 1 — Overall Attrition Rate
```sql
SELECT 
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS TotalAttrition,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition;
```

### Query 2 — Attrition by Department
```sql
SELECT 
    "Department",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "Department"
ORDER BY AttritionRate DESC;
```

### Query 3 — Attrition by Salary Band
```sql
SELECT 
    "SalaryBand",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "SalaryBand"
ORDER BY AttritionRate DESC;
```

### Query 4 — Attrition by Tenure Band
```sql
SELECT 
    "TenureBand",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "TenureBand"
ORDER BY AttritionRate DESC;
```

### Query 5 — Top 5 Job Roles with Highest Attrition
```sql
SELECT 
    "JobRole",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "JobRole"
ORDER BY AttritionRate DESC
LIMIT 5;
```

### Query 6 — Average Salary: Left vs Stayed
```sql
SELECT 
    "Attrition",
    ROUND(AVG("MonthlyIncome"), 0) AS AvgSalary,
    ROUND(AVG("YearsAtCompany"), 1) AS AvgTenure,
    ROUND(AVG("Age"), 1) AS AvgAge
FROM hr_attrition
GROUP BY "Attrition"
ORDER BY "Attrition" DESC;
```

### Query 7 — High Risk Employees by Department (Window Functions + CTE)
```sql
WITH DeptRisk AS (
    SELECT 
        "Department",
        "JobRole",
        "Age",
        "MonthlyIncome",
        "JobSatisfaction",
        "AttritionFlag",
        "High_Risk",
        COUNT(*) OVER (PARTITION BY "Department") AS DeptTotalEmployees,
        SUM("High_Risk") OVER (PARTITION BY "Department") AS DeptHighRiskCount,
        RANK() OVER (PARTITION BY "Department" ORDER BY "MonthlyIncome" ASC) AS SalaryRank
    FROM hr_attrition
    WHERE "High_Risk" = 1
)
SELECT 
    "Department",
    "JobRole",
    "Age",
    "MonthlyIncome",
    "JobSatisfaction",
    DeptTotalEmployees,
    DeptHighRiskCount,
    SalaryRank
FROM DeptRisk
ORDER BY "Department", SalaryRank;
```

---

## 📈 Layer 3 — Power BI Dashboard

### DAX Measures

```dax
-- Total Employees
Total Employees = COUNT(hr_clean_data[EmployeeNumber])

-- Total Attrition
Total Attrition = SUM(hr_clean_data[AttritionFlag])

-- Attrition Rate %
Attrition Rate % = 
DIVIDE(
    SUM(hr_clean_data[AttritionFlag]),
    COUNT(hr_clean_data[EmployeeNumber]),
    0
) * 100
```

### Dashboard Features
- ✅ 3 KPI Cards — Total Employees, Total Attrition, Attrition Rate %
- ✅ Bar Charts — Attrition by Department, Salary Band, Tenure Band
- ✅ Pie Chart — Attrition Yes vs No distribution
- ✅ Table — Job Role level attrition breakdown
- ✅ 4 Slicers — Department, SalaryBand, TenureBand, Attrition
- ✅ Row Level Security (RLS) — Department based access control

### Row Level Security
```dax
-- Static RLS — Department Manager role
[Department] = "Sales"

-- Dynamic RLS Architecture (for Power BI Service deployment)
[Department] IN
CALCULATETABLE(
    VALUES(user_mapping[Department]),
    FILTER(
        user_mapping,
        user_mapping[Email] = USERPRINCIPALNAME()
    )
)
```

---

## 🔍 Key Insights Discovered

| Insight | Finding |
|---|---|
| Overall Attrition Rate | **16.1%** of employees left |
| Highest attrition department | **Sales — 20.6%** |
| Salary impact | **Low salary band — 27%** attrition vs 5.5% for Very High |
| Tenure impact | **New employees (0-2y) — 31.2%** attrition vs 4.9% for Veterans |
| Age impact | Leavers average age **33.6** vs stayers **37.6** |
| Salary gap | Leavers earned **$2,045 less** on average than stayers |

---

## 💡 Business Recommendations

1. **Focus retention on Sales department** — highest attrition at 20.6%
2. **Review compensation for low salary band** — 27% attrition is unsustainable
3. **Strengthen onboarding program** — new employees (0-2y) leaving at 31.2%
4. **Target younger employees** — average leaver age is 33.6
5. **Monitor high risk employees** — flagged using satisfaction + salary + age criteria

---

## 🚀 How to Run This Project

### Prerequisites
```bash
pip install pandas numpy sqlalchemy psycopg2-binary
```

### Step 1 — Download Dataset
Download from [Kaggle](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset)
Place `WA_Fn-UseC_-HR-Employee-Attrition.csv` in the `data/` folder

### Step 2 — Run Python Script
```bash
cd python
python HR_attrition_analysis.py
```
This generates `hr_clean_data.csv`, `hr_dept_summary.csv`, `hr_high_risk.csv`

### Step 3 — Set up PostgreSQL
```bash
# Create database
createdb attrition_analysis

# Update connection string in script
engine = create_engine("postgresql+psycopg2://postgres:yourpassword@localhost:5432/attrition_analysis")
```

### Step 4 — Run SQL Queries
Open `sql/attrition_queries.sql` in pgAdmin or any PostgreSQL client

### Step 5 — Open Power BI Dashboard
Open `powerbi/HR_attrition_analysis_Dashboard.pbix` in Power BI Desktop

---

## 📸 Dashboard Preview

![HR Attrition Dashboard](Dashboard.png)

---

## 👩‍💻 Author

**Deeksha Gupta**
- 💼 Data Analyst | Power BI Developer
- 🏆 Microsoft PL-300 Certified
- 📧 deeksha513g@gmail.com
- 🔗 [LinkedIn](https://www.linkedin.com/in/deeksha-gupta)
- 🐙 [GitHub](https://github.com/deekshadggupta-a11y)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

⭐ **If you found this project helpful, please give it a star!**
