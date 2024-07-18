USE preppin_data;

SELECT *
FROM `pd_week1_2023`;

-- Q1

SELECT 
    LEFT(`Transaction Code`, 3) AS bank,
    SUM(`Value`) AS total_value
FROM
    `pd_week1_2023`
GROUP BY bank;

-- Q2
SELECT
  LEFT(`Transaction Code`, 3) AS bank,
  CASE 
    WHEN `Online or In-Person`=1 THEN 'Online'
    WHEN `Online or In-Person`=2 THEN 'In-Person'
  END as online_in_person,
  DAYNAME(STR_TO_DATE(`Transaction Date`, '%d/%m/%Y %H:%i:%s')) as day_of_week,
  SUM(value) as total_value
FROM `pd_week1_2023`
GROUP BY bank, online_in_person, day_of_week;

-- Q3
SELECT
 LEFT(`Transaction Code`, 3) AS bank,
`Customer Code`,
SUM(value) as total_value
FROM `pd_week1_2023`
GROUP BY bank,
`Customer Code`;
    

