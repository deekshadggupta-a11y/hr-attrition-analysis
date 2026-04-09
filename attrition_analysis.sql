SELECT column_name 
FROM information_schema.columns
WHERE table_name = 'hr_attrition';


--overall attrition rate 
select count(*) as totalEmployee,
sum("AttritionFlag") as TotalAttritions,
round(sum("AttritionFlag")*100.0/count(*),1) as AttritionRate from hr_attrition;


----attrition by department
select "Department",
count(*) as totalEmployee,
sum("AttritionFlag") as TotalAttritions,
round(sum("AttritionFlag")*100.0/count(*),1) as AttritionRate from hr_attrition
group by "Department" order by AttritionRate Desc;


---Attrition by salary band
select "SalaryBand",
count(*) as totalEmployee,
sum("AttritionFlag") as TotalAttritions,
round(sum("AttritionFlag")*100.0/count(*),1) as AttritionRate from hr_attrition
group by "SalaryBand" order by AttritionRate Desc;


---Attrition by Tenure Band
select "TenureBand",
count(*) as totalEmployee,
sum("AttritionFlag") as TotalAttritions,
round(sum("AttritionFlag")*100.0/count(*),1) as AttritionRate from hr_attrition
group by "TenureBand" order by AttritionRate Desc;


--Top 5 job roles with higher attrition
SELECT "JobRole",
count(*) as totalEmployee,
sum("AttritionFlag") as TotalAttritions,
round(sum("AttritionFlag")*100.0/count(*),1) as AttritionRate from hr_attrition
group by "JobRole" order by AttritionRate desc limit 5;


--average salary: left vs stayed
select "Attrition",
round(avg("MonthlyIncome"),0) as avgSalary,
round(avg("YearsAtCompany"),1) as avgTenure,
round(avg("Age"),1) as avgAge from hr_attrition
group by "Attrition" order by "Attrition" desc;


--high risk employees by department
with DeptRisk as (
select "Department","JobRole","Age","MonthlyIncome","JobSatisfaction","AttritionFlag","High_Risk",
count(*) over (partition by "Department") as DeptTotalEmployees,
sum("High_Risk") over (partition by "Department") as DeptHighRiskCount,
rank() over (partition by "Department" order by "MonthlyIncome" ASC) as SalaryRank
from hr_attrition where "High_Risk"=1
)
select "Department","JobRole","Age","MonthlyIncome","JobSatisfaction",DeptTotalEmployees, DeptHighRiskCount, SalaryRank 
from DeptRisk order by "Department" , SalaryRank;