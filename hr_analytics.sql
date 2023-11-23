/*=========================
 IMPORTING THE DATASET
=========================*/

CREATE TABLE hr (
attrition_date DATE,
age	INTEGER,
attrition TEXT,
business_travel	TEXT,
daily_rate NUMERIC,
department	TEXT,
distance_from_home	NUMERIC,
education	TEXT,
education_field	TEXT,
employee_count	INTEGER,
employee_number	INTEGER,
environment_satisfaction	TEXT,
gender	TEXT,
hourly_rate	NUMERIC,
job_involvement	INTEGER,
job_level	INTEGER,
job_role	TEXT,
job_satisfaction	INTEGER,
marital_status	TEXT,
monthly_income	NUMERIC,
monthly_rate	NUMERIC,
num_companies_worked	INTEGER,
over_18	TEXT,
over_time	TEXT,
percent_salary_hike	NUMERIC,
performance_rating	INTEGER,
relationship_satisfaction	INTEGER,
standard_hours	NUMERIC,
stock_option_level	INTEGER,
total_working_years	INTEGER,
training_times_last_year	INTEGER,
work_life_balance	INTEGER,
years_at_company	INTEGER,
years_in_current_role	INTEGER,
years_since_last_promotion	INTEGER,
years_with_curr_manager INTEGER
)

SELECT * FROM hr
LIMIT 5

-- if using original csv (values separated by tabs):
-- \COPY hr FROM 'C:\Users\Public\hr_analytics_data.csv' WITH CSV HEADER DELIMITER E'\t'

-- if using altered csv (values separated by commas):
-- \COPY hr FROM 'C:\Users\Public\HR_Attrition.csv' WITH CSV HEADER DELIMITER ','


/*=========================
 BIRD'S EYE VIEW
=========================*/

-- 1. Average age (overall + by department and job role)

SELECT
ROUND(AVG(age),1) AS average_age
FROM hr

SELECT
department,
ROUND(AVG(age),1) AS average_age
FROM hr
GROUP BY 1

SELECT
job_role,
ROUND(AVG(age),1) AS average_age
FROM hr
GROUP BY 1

-- 2. Age_group distribution, overall + percentage

WITH age_group_cte AS (
SELECT
age,
CASE WHEN age >=18 AND age<25 THEN '<25'
	 WHEN age >=25 AND age<35 THEN '25-34'
	 WHEN age >=35 AND age<45 THEN '35-44'
	 WHEN age >=45 AND age<=55 THEN '45-55'
	 WHEN age >55 THEN '>55' END AS age_group
FROM hr
)

SELECT
age_group,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),2) AS pct
FROM age_group_cte
GROUP BY 1
ORDER BY ARRAY_POSITION(ARRAY['<25','25-34','35-44','45-55','>55'],age_group)

-- 3. Age_group distribution, by department

WITH age_group_cte AS (
SELECT
age,
department,
CASE WHEN age >=18 AND age<25 THEN '<25'
	 WHEN age >=25 AND age<35 THEN '25-34'
	 WHEN age >=35 AND age<45 THEN '35-44'
	 WHEN age >=45 AND age<=55 THEN '45-55'
	 WHEN age >55 THEN '>55' END AS age_group
FROM hr
)

SELECT
department,
age_group,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) AS pct
FROM age_group_cte
GROUP BY 1,2
ORDER BY department, ARRAY_POSITION(ARRAY['<25','25-34','35-44','45-55','>55'],age_group)

-- 4. Gender distribution by department + percentage

SELECT
department,
gender,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 5. Gender distribution by department + percentage (different display method)

SELECT 
department,
COUNT(*) FILTER (WHERE gender='Female') AS female_count,
COUNT(*) FILTER (WHERE gender='Male') AS male_count,
ROUND(100.0*COUNT(*) FILTER (WHERE gender='Female')/COUNT(*),2) AS female_pct,
ROUND(100.0*COUNT(*) FILTER (WHERE gender='Male')/COUNT(*),2) AS male_pct
FROM hr
GROUP BY 1
ORDER BY 1

-- Similarly, we can obtain distributions for any field that interests us, 
-- such as job_role , education, monthly_income, etc


-- 6. Average years at the company (overall tenure + by department)

SELECT
ROUND(AVG(years_at_company),1) AS average_years_at_company
FROM hr

SELECT
department,
ROUND(AVG(years_at_company),1) AS average_years_at_company
FROM hr
GROUP BY 1

-- 7. Average years in the current role (overall + by department)

SELECT
ROUND(AVG(years_in_current_role),1) AS average_years_in_current_role
FROM hr

SELECT
department,
ROUND(AVG(years_in_current_role),1) AS average_years_in_current_role
FROM hr
GROUP BY 1

-- 8. Average years since last promotion (overall + by department)

SELECT
ROUND(AVG(years_since_last_promotion),1) AS average_years_since_last_promotion
FROM hr

SELECT
department,
ROUND(AVG(years_since_last_promotion),1) AS average_years_since_last_promotion
FROM hr
GROUP BY 1

-- 9. Average years with the current manager (overall + by department)

SELECT
ROUND(AVG(years_with_curr_manager),1) AS average_years_with_curr_manager
FROM hr

SELECT
department,
ROUND(AVG(years_with_curr_manager),1) AS average_years_with_curr_manager
FROM hr
GROUP BY 1

-- 10. Salary comparisons to benchmarks (tenure, position, department, gender)

WITH benchmarks_cte AS (
SELECT
employee_number,
years_at_company AS tenure,
job_role,
department,
gender,
monthly_income AS salary,
ROUND(AVG(monthly_income) OVER (PARTITION BY years_at_company)) AS tenure_salary_benchmark,
ROUND(AVG(monthly_income) OVER (PARTITION BY job_role)) AS job_role_salary_benchmark,
ROUND(AVG(monthly_income) OVER (PARTITION BY department)) AS department_salary_benchmark,
ROUND(AVG(monthly_income) OVER (PARTITION BY gender)) AS gender_salary_benchmark
FROM hr
)

SELECT
employee_number,
tenure,
job_role,
department,
gender,
salary,
tenure_salary_benchmark,
ROUND(100.0*(salary - tenure_salary_benchmark)/tenure_salary_benchmark,1) AS tenure_pct_diff,
job_role_salary_benchmark,
ROUND(100.0*(salary - job_role_salary_benchmark)/job_role_salary_benchmark,1) AS job_role_pct_diff,
department_salary_benchmark,
ROUND(100.0*(salary - department_salary_benchmark)/department_salary_benchmark,1) AS department_pct_diff,
gender_salary_benchmark,
ROUND(100.0*(salary - gender_salary_benchmark)/gender_salary_benchmark,1) AS gender_pct_diff
FROM benchmarks_cte
ORDER BY 1
LIMIT 10

/*=========================
 ATTRITION ANALYSIS
=========================*/

-- 1. Retention vs Attrition (absolute + percentage), Total Attrition, Current Employees (number)

SELECT
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (),2) AS pct
FROM hr
GROUP BY 1

-- 2.1 Retention vs Attrition by department

SELECT
department,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 2.2 Retention vs Attrition by department (different display method)

WITH attr_by_dept AS(
SELECT 
department,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) END AS attrition_pct
FROM hr
GROUP BY department, attrition
)

SELECT
department,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_dept
GROUP BY department
ORDER BY department

-- 3.1 Retention vs Attrition by role

SELECT
job_role,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY job_role),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 3.2 Retention vs Attrition by role (different display method)

WITH attr_by_role AS(
SELECT 
job_role,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY job_role),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY job_role),2) END AS attrition_pct
FROM hr
GROUP BY job_role, attrition
ORDER BY job_role
)

SELECT
job_role,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_role
GROUP BY job_role
ORDER BY job_role

-- 4.1 Retention vs Attrition by gender

SELECT
gender,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY gender),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 4.2 Retention vs Attrition by gender (different display method)

WITH attr_by_gender AS(
SELECT 
gender,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY gender),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY gender),2) END AS attrition_pct
FROM hr
GROUP BY gender, attrition
ORDER BY gender
)

SELECT
gender,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_gender
GROUP BY gender
ORDER BY gender


-- 5.1 Retention vs Attrition by education

SELECT
education,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY education),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2


-- 5.2 Retention vs Attrition by education (different display method)

WITH attr_by_education AS(
SELECT 
education,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY education),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY education),2) END AS attrition_pct
FROM hr
GROUP BY education, attrition
ORDER BY education
)

SELECT
education,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_education
GROUP BY education
ORDER BY education

-- 6.1 Retention vs Attrition by age group

WITH age_group_cte AS (
SELECT
age,
CASE WHEN age >=18 AND age<25 THEN '<25'
	 WHEN age >=25 AND age<35 THEN '25-34'
	 WHEN age >=35 AND age<45 THEN '35-44'
	 WHEN age >=45 AND age<=55 THEN '45-55'
	 WHEN age >55 THEN '>55' END AS age_group,
attrition
FROM hr
)

SELECT
age_group,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY age_group),2) AS pct
FROM age_group_cte
GROUP BY 1,2
ORDER BY ARRAY_POSITION(ARRAY['<25','25-34','35-44','45-55','>55'],age_group), attrition

-- 6.2 Retention vs Attrition by age group (different display method)

WITH age_group_cte AS (
SELECT
age,
CASE WHEN age >=18 AND age<25 THEN '<25'
	 WHEN age >=25 AND age<35 THEN '25-34'
	 WHEN age >=35 AND age<45 THEN '35-44'
	 WHEN age >=45 AND age<=55 THEN '45-55'
	 WHEN age >55 THEN '>55' END AS age_group,
attrition
FROM hr
--ORDER BY 1
)

, attr_by_age_group AS(
SELECT 
age_group,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY age_group),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY age_group),2) END AS attrition_pct
FROM age_group_cte
GROUP BY age_group, attrition
--ORDER BY age_group
)

SELECT
age_group,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_age_group
GROUP BY age_group
ORDER BY ARRAY_POSITION(ARRAY['<25','25-34','35-44','45-55','>55'],age_group)

-- 7.1 Retention vs Attrition by amount of business travel

SELECT
business_travel,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY business_travel),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 7.2 Retention vs Attrition by amount of business travel (different display method)

WITH attr_by_travel AS(
SELECT 
business_travel,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY business_travel),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY business_travel),2) END AS attrition_pct
FROM hr
GROUP BY business_travel, attrition
ORDER BY business_travel
)

SELECT
business_travel,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_travel
GROUP BY business_travel
ORDER BY business_travel

-- 8.1 Retention vs Attrition by distance from home

WITH distance_from_home_cte AS (
SELECT
distance_from_home,
CASE WHEN distance_from_home >=1 AND distance_from_home<10 THEN '<10'
	 WHEN distance_from_home >=10 AND distance_from_home<=20 THEN '10-20'
	 WHEN distance_from_home >20 AND distance_from_home<45 THEN '>20'
	 END AS distance_from_home_group,
attrition
FROM hr
)

SELECT
distance_from_home_group,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY distance_from_home_group),2) AS pct
FROM distance_from_home_cte
GROUP BY 1,2
ORDER BY ARRAY_POSITION(ARRAY['<10','10-20','>20'],distance_from_home_group), attrition

-- 8.2 Retention vs Attrition by distance from home (different display method)

WITH distance_from_home_cte AS (
SELECT
distance_from_home,
CASE WHEN distance_from_home >=1 AND distance_from_home<10 THEN '<10'
	 WHEN distance_from_home >=10 AND distance_from_home<=20 THEN '10-20'
	 WHEN distance_from_home >20 AND distance_from_home<45 THEN '>20'
	 END AS distance_from_home_group,
attrition
FROM hr
)

, attr_by_distance_from_home AS(
SELECT 
distance_from_home_group,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY distance_from_home_group),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY distance_from_home_group),2) END AS attrition_pct
FROM distance_from_home_cte
GROUP BY distance_from_home_group, attrition
ORDER BY distance_from_home_group
)

SELECT
distance_from_home_group,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_distance_from_home 
GROUP BY distance_from_home_group
ORDER BY ARRAY_POSITION(ARRAY['<10','10-20','>20'],distance_from_home_group)

-- 9.1 Retention vs Attrition by num_companies_worked 

SELECT
num_companies_worked,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY num_companies_worked),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 9.2 Retention vs Attrition by num_companies_worked (different display method)

WITH attr_by_num_previous_workplaces AS(
SELECT 
num_companies_worked,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY num_companies_worked),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY num_companies_worked),2) END AS attrition_pct
FROM hr
GROUP BY num_companies_worked, attrition
ORDER BY num_companies_worked
)

SELECT
num_companies_worked,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_num_previous_workplaces
GROUP BY num_companies_worked
ORDER BY num_companies_worked

-- 10.1 Retention vs Attrition by over_time

SELECT
over_time,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY over_time),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 10.2 Retention vs Attrition by over_time (different display method)

WITH attr_by_over_time AS(
SELECT 
over_time,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY over_time),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY over_time),2) END AS attrition_pct
FROM hr
GROUP BY over_time, attrition
ORDER BY over_time
)

SELECT
over_time,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_over_time
GROUP BY over_time
ORDER BY over_time

-- 11.1 Retention vs Attrition by years_at_company 

WITH years_at_company_cte AS (
SELECT
years_at_company,
CASE WHEN years_at_company < 5 THEN '<5'
	 WHEN years_at_company >= 5 AND years_at_company <= 9 THEN '5-9'
	 WHEN years_at_company >= 10 AND years_at_company <= 14 THEN '10-14'
	 WHEN years_at_company >= 15 AND years_at_company <= 19 THEN '15-19'
	 WHEN years_at_company >= 20 AND years_at_company <= 24 THEN '20-24'
	 WHEN years_at_company >= 25 AND years_at_company <= 29 THEN '25-29'
	 WHEN years_at_company >= 30 AND years_at_company <= 35 THEN '30-35'
	 WHEN years_at_company > 35 THEN '>35'
	 END AS years_at_company_group,
attrition
FROM hr
)

SELECT
years_at_company_group,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY years_at_company_group),2) AS pct
FROM years_at_company_cte
GROUP BY 1,2
ORDER BY ARRAY_POSITION(ARRAY['<5','5-9','10-14','15-19','20-24','25-29','30-35','>35'],years_at_company_group), attrition

-- 11.2 Retention vs Attrition by years_at_company (different display method)

WITH years_at_company_cte AS (
SELECT
years_at_company,
CASE WHEN years_at_company < 5 THEN '<5'
	 WHEN years_at_company >= 5 AND years_at_company <= 9 THEN '5-9'
	 WHEN years_at_company >= 10 AND years_at_company <= 14 THEN '10-14'
	 WHEN years_at_company >= 15 AND years_at_company <= 19 THEN '15-19'
	 WHEN years_at_company >= 20 AND years_at_company <= 24 THEN '20-24'
	 WHEN years_at_company >= 25 AND years_at_company <= 29 THEN '25-29'
	 WHEN years_at_company >= 30 AND years_at_company <= 35 THEN '30-35'
	 WHEN years_at_company > 35 THEN '>35'
	 END AS years_at_company_group,
attrition
FROM hr
)

, attr_by_years_at_company AS(
SELECT 
years_at_company_group,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY years_at_company_group),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY years_at_company_group),2) END AS attrition_pct
FROM years_at_company_cte
GROUP BY years_at_company_group, attrition
ORDER BY years_at_company_group
)

SELECT
years_at_company_group,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_years_at_company
GROUP BY years_at_company_group
ORDER BY ARRAY_POSITION(ARRAY['<5','5-9','10-14','15-19','20-24','25-29','30-35','>35'],years_at_company_group)

-- 12.1 Retention vs Attrition by years_in_current_role 

WITH years_in_current_role_cte AS (
SELECT
years_in_current_role,
CASE WHEN years_in_current_role = 0 THEN '<1'
	 WHEN years_in_current_role >= 1 AND years_in_current_role <= 3 THEN '1-3'
	 WHEN years_in_current_role >= 4 AND years_in_current_role <= 6 THEN '4-6'
	 WHEN years_in_current_role >= 7 AND years_in_current_role <= 9 THEN '7-9'
	 WHEN years_in_current_role >= 10 AND years_in_current_role <= 12 THEN '10-12'
	 WHEN years_in_current_role >= 13 AND years_in_current_role <= 15 THEN '13-15'
	 WHEN years_in_current_role > 15 THEN '>15'
	 END AS years_in_current_role_group,
attrition
FROM hr
)

SELECT
years_in_current_role_group,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY years_in_current_role_group),2) AS pct
FROM years_in_current_role_cte
GROUP BY 1,2
ORDER BY ARRAY_POSITION(ARRAY['<1','1-3','4-6','7-9','10-12','13-15','>15'],years_in_current_role_group), attrition

-- 12.2 Retention vs Attrition by years_in_current_role (different display method)

WITH years_in_current_role_cte AS (
SELECT
years_in_current_role,
CASE WHEN years_in_current_role = 0 THEN '<1'
	 WHEN years_in_current_role >= 1 AND years_in_current_role <= 3 THEN '1-3'
	 WHEN years_in_current_role >= 4 AND years_in_current_role <= 6 THEN '4-6'
	 WHEN years_in_current_role >= 7 AND years_in_current_role <= 9 THEN '7-9'
	 WHEN years_in_current_role >= 10 AND years_in_current_role <= 12 THEN '10-12'
	 WHEN years_in_current_role >= 13 AND years_in_current_role <= 15 THEN '13-15'
	 WHEN years_in_current_role > 15 THEN '>15'
	 END AS years_in_current_role_group,
attrition
FROM hr
)

, attr_by_years_in_current_role AS(
SELECT 
years_in_current_role_group,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY years_in_current_role_group),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY years_in_current_role_group),2) END AS attrition_pct
FROM years_in_current_role_cte
GROUP BY years_in_current_role_group, attrition
ORDER BY years_in_current_role_group
)

SELECT
years_in_current_role_group,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_years_in_current_role
GROUP BY years_in_current_role_group
ORDER BY ARRAY_POSITION(ARRAY['<1','1-3','4-6','7-9','10-12','13-15','>15'],years_in_current_role_group)

-- 13.1 Retention vs Attrition by monthly_income

WITH monthly_income_cte AS (
SELECT
monthly_income,
CASE WHEN monthly_income > 1000 AND monthly_income <= 5000 THEN '1000 - 5000'
	 WHEN monthly_income > 5000 AND monthly_income <= 10000 THEN '5001 - 10000'
	 WHEN monthly_income > 10000 AND monthly_income <= 15000 THEN '10001 - 15000'
	 WHEN monthly_income > 15000 THEN '> 15000'
	 END AS monthly_income_group,
attrition
FROM hr
)

SELECT
monthly_income_group,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY monthly_income_group),2) AS pct
FROM monthly_income_cte
GROUP BY 1,2
ORDER BY ARRAY_POSITION(ARRAY['1000 - 5000','5001 - 10000','10001 - 15000','> 15000'],monthly_income_group), attrition

-- 13.2 Retention vs Attrition by monthly_income (different display method)

WITH monthly_income_cte AS (
SELECT
monthly_income,
CASE WHEN monthly_income > 1000 AND monthly_income <= 5000 THEN '1000 - 5000'
	 WHEN monthly_income > 5000 AND monthly_income <= 10000 THEN '5001 - 10000'
	 WHEN monthly_income > 10000 AND monthly_income <= 15000 THEN '10001 - 15000'
	 WHEN monthly_income > 15000 THEN '> 15000'
	 END AS monthly_income_group,
attrition
FROM hr
)
, attr_by_monthly_income AS(
SELECT 
monthly_income_group,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY monthly_income_group),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY monthly_income_group),2) END AS attrition_pct
FROM monthly_income_cte
GROUP BY monthly_income_group, attrition
ORDER BY monthly_income_group
)

SELECT
monthly_income_group,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_monthly_income
GROUP BY monthly_income_group
ORDER BY ARRAY_POSITION(ARRAY['1000 - 5000','5001 - 10000','10001 - 15000','> 15000'],monthly_income_group)

-- 14.1 Retention vs Attrition by stock_option_level

SELECT
stock_option_level,
attrition,
COUNT(*),
ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY stock_option_level),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 14.2 Retention vs Attrition by stock_option_level (different display method)

WITH attr_by_stock_option_level AS(
SELECT 
stock_option_level,
CASE WHEN attrition = 'No' THEN COUNT(*) END AS retention,
CASE WHEN attrition = 'Yes' THEN COUNT(*) END AS attrition,
CASE WHEN attrition = 'No' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY stock_option_level),2) END AS retention_pct,
CASE WHEN attrition = 'Yes' THEN ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY stock_option_level),2) END AS attrition_pct
FROM hr
GROUP BY stock_option_level, attrition
ORDER BY stock_option_level
)

SELECT
stock_option_level,
MAX(retention) AS retention,
MAX(attrition) AS attrition,
MAX(retention_pct) AS retention_pct,
MAX(attrition_pct) AS attrition_pct
FROM attr_by_stock_option_level
GROUP BY stock_option_level
ORDER BY stock_option_level

-- 15.1 Attrition Trend (weekly + comparison to previous week in pct)

WITH weeks_cte AS (
SELECT
DATE_TRUNC('week', attrition_date)::DATE AS attrition_week,
*
FROM hr
)

, weekly_attrition AS (
SELECT 
attrition_week,
COUNT(CASE WHEN attrition = 'Yes' THEN attrition END) AS attrition
FROM weeks_cte
GROUP BY 1
ORDER BY 1
)

SELECT
*,
ROUND(100.0*(attrition-LAG(attrition) OVER ())/LAG(attrition) OVER (),2) AS pct_change
FROM weekly_attrition

-- 15.2 Attrition Trend (monthly + comparison to previous month in pct)

WITH months_cte AS (
SELECT
DATE_TRUNC('month', attrition_date)::DATE AS attrition_month,
*
FROM hr
)

, monthly_attrition AS (
SELECT 
attrition_month,
TO_CHAR(attrition_month,'Month'),
COUNT(CASE WHEN attrition = 'Yes' THEN attrition END) AS attrition
FROM months_cte
GROUP BY 1
ORDER BY 1
)

SELECT
*,
ROUND(100.0*(attrition-LAG(attrition) OVER ())/LAG(attrition) OVER (),2) AS pct_change
FROM monthly_attrition

-- 15.3 Attrition Trend (quarterly + comparison to previous quarter in pct)

WITH quarters_cte AS (
SELECT
DATE_TRUNC('quarter', attrition_date)::DATE as attrition_quarter,
*
FROM hr
)

, quarterly_attrition AS (
SELECT 
attrition_quarter,
TO_CHAR(attrition_quarter,'"Q"Q YYYY') AS quarter,
COUNT(CASE WHEN attrition = 'Yes' THEN attrition END) AS attrition
FROM quarters_cte
GROUP BY 1
ORDER BY 1
)

SELECT
*,
ROUND(100.0*(attrition-LAG(attrition) OVER ())/LAG(attrition) OVER (),2) AS pct_change
FROM quarterly_attrition

-- 15.4 Attrition Trend (yearly + comparison to previous year in pct)

WITH years_cte AS (
SELECT
EXTRACT('year' FROM attrition_date) AS attrition_year,
*
FROM hr
)

, yearly_attrition AS (
SELECT 
attrition_year,
COUNT(CASE WHEN attrition = 'Yes' THEN attrition END) AS attrition
FROM years_cte
GROUP BY 1
ORDER BY 1
)

SELECT
*,
ROUND(100.0*(attrition-LAG(attrition) OVER ())/LAG(attrition) OVER (),1) AS pct_change
FROM yearly_attrition


/*=========================
 EMPLOYEE SATISFACTION
=========================*/

-- 1. Environment satisfaction distribution, by department

SELECT 
department,
environment_satisfaction,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 2. Job satisfaction distribution, by department

SELECT 
department,
job_satisfaction,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 3. Relationship satisfaction distribution, by department

SELECT 
department,
relationship_satisfaction,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY department),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2


-- Just as before, we can also find these same three metrics (environment, job and relationship satisfaction) for any grouping 
-- other than department by simply subtituting department with what interests us (e.g. job_role, gender, education, age_group, etc)
-- Example:

SELECT 
gender,
environment_satisfaction,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY gender),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

SELECT 
gender,
job_satisfaction,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY gender),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

SELECT 
gender,
relationship_satisfaction,
COUNT(*),
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY gender),2) AS pct
FROM hr
GROUP BY 1,2
ORDER BY 1,2

-- 4. Average satisfaction by employee

SELECT 
employee_number,
attrition,
environment_satisfaction,
job_satisfaction,
relationship_satisfaction,
work_life_balance
employee_number,
ROUND((environment_satisfaction::NUMERIC + job_satisfaction::NUMERIC + relationship_satisfaction::NUMERIC + work_life_balance::INT)/4,1) AS average_satisfaction
FROM hr
LIMIT 10

-- 5. Average satisfaction, attrition vs retention

WITH satisfaction_cte AS (
SELECT 
employee_number,
attrition,
environment_satisfaction,
job_satisfaction,
relationship_satisfaction,
work_life_balance
employee_number,
ROUND((environment_satisfaction::NUMERIC + job_satisfaction::NUMERIC + relationship_satisfaction::NUMERIC + work_life_balance::INT)/4,1) AS average_satisfaction
FROM hr
)

SELECT
attrition,
ROUND(AVG(average_satisfaction),1) AS avg_satisfaction
FROM satisfaction_cte
GROUP BY 1
ORDER BY 1

