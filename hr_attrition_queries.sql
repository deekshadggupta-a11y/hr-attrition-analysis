-- ============================================================
-- HR ATTRITION ANALYSIS — SQL Queries
-- Database: PostgreSQL
-- Dataset: IBM HR Analytics (1,470 employees)
-- Author: Deeksha Gupta
-- ============================================================


-- ============================================================
-- QUERY 1 — Overall Attrition Rate
-- ============================================================

SELECT 
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS TotalAttrition,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition;

-- Expected Output:
-- TotalEmployees | TotalAttrition | AttritionRate
-- 1470           | 237            | 16.1


-- ============================================================
-- QUERY 2 — Attrition by Department
-- ============================================================

SELECT 
    "Department",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "Department"
ORDER BY AttritionRate DESC;

-- Expected Output:
-- Department              | TotalEmployees | AttritionCount | AttritionRate
-- Sales                   | 446            | 92             | 20.6
-- Human Resources         | 63             | 12             | 19.0
-- Research & Development  | 961            | 133            | 13.8


-- ============================================================
-- QUERY 3 — Attrition by Salary Band
-- ============================================================

SELECT 
    "SalaryBand",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "SalaryBand"
ORDER BY AttritionRate DESC;

-- Expected Output:
-- SalaryBand | TotalEmployees | AttritionCount | AttritionRate
-- Low        | 289            | 78             | 27.0
-- Medium     | 559            | 101            | 18.1
-- High       | 440            | 48             | 10.9
-- Very High  | 182            | 10             | 5.5


-- ============================================================
-- QUERY 4 — Attrition by Tenure Band
-- ============================================================

SELECT 
    "TenureBand",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "TenureBand"
ORDER BY AttritionRate DESC;

-- Expected Output:
-- TenureBand      | TotalEmployees | AttritionCount | AttritionRate
-- New(0-2y)       | 314            | 98             | 31.2
-- Mid(3-5y)       | 387            | 76             | 19.6
-- Senior(6-10y)   | 402            | 45             | 11.2
-- Veteran(10+y)   | 367            | 18             | 4.9


-- ============================================================
-- QUERY 5 — Top 5 Job Roles with Highest Attrition
-- ============================================================

SELECT 
    "JobRole",
    COUNT(*) AS TotalEmployees,
    SUM("AttritionFlag") AS AttritionCount,
    ROUND(SUM("AttritionFlag") * 100.0 / COUNT(*), 1) AS AttritionRate
FROM hr_attrition
GROUP BY "JobRole"
ORDER BY AttritionRate DESC
LIMIT 5;


-- ============================================================
-- QUERY 6 — Average Salary, Tenure and Age: Left vs Stayed
-- ============================================================

SELECT 
    "Attrition",
    ROUND(AVG("MonthlyIncome"), 0) AS AvgSalary,
    ROUND(AVG("YearsAtCompany"), 1) AS AvgTenure,
    ROUND(AVG("Age"), 1) AS AvgAge
FROM hr_attrition
GROUP BY "Attrition"
ORDER BY "Attrition" DESC;

-- Expected Output:
-- Attrition | AvgSalary | AvgTenure | AvgAge
-- Yes       | 4787      | 5.1       | 33.6
-- No        | 6832      | 7.4       | 37.6

-- Key Insight: Employees who left earned $2,045 less on average
-- and were 4 years younger with 2.3 fewer years at company


-- ============================================================
-- QUERY 7 — High Risk Employees by Department
--           Using CTEs + Window Functions
-- ============================================================

WITH DeptRisk AS (
    SELECT 
        "Department",
        "JobRole",
        "Age",
        "MonthlyIncome",
        "JobSatisfaction",
        "AttritionFlag",
        "High_Risk",
        -- Window function 1: Total employees per department
        COUNT(*) OVER (PARTITION BY "Department") AS DeptTotalEmployees,
        -- Window function 2: Total high risk per department
        SUM("High_Risk") OVER (PARTITION BY "Department") AS DeptHighRiskCount,
        -- Window function 3: Rank by lowest salary within department
        RANK() OVER (
            PARTITION BY "Department" 
            ORDER BY "MonthlyIncome" ASC
        ) AS SalaryRank
    FROM hr_attrition
    WHERE "High_Risk" = 1  -- Filter high risk employees only
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

-- Key Insight: Rank 1 employees in each department are most financially
-- vulnerable high risk employees — priority targets for HR retention efforts
