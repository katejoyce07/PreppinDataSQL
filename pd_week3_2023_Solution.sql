SELECT * FROM `pd_week3_2023`;
SELECT * FROM `pd_week1_2023`;


WITH CTE AS (
  SELECT 
    CASE 
      WHEN `Online or In-Person` = 1 THEN 'Online'
      WHEN `Online or In-Person` = 2 THEN 'In-Person'
    END AS online_in_person,
    QUARTER(STR_TO_DATE(`Transaction Date`, '%d/%m/%Y %H:%i:%s')) AS quarter,
    SUM(value) AS total_value
  FROM `pd_week1_2023`
  WHERE LEFT(`Transaction Code`, 3) = 'DSB'
  GROUP BY 1,2
)


SELECT U.`Online or In-Person`,
U.quarter,
U.target as Quarterly_Targets,
V.total_value,
(V.total_value - U.target) as Variance_to_Target
FROM `pd_week3_2023` AS T
INNER JOIN (
  SELECT 
    `Online or In-Person`,
    '1' AS quarter, Q1 AS target 
  FROM `pd_week3_2023`
  UNION ALL
  SELECT 
    `Online or In-Person`,
    '2' AS quarter, Q2 AS target 
  FROM `pd_week3_2023`
  UNION ALL
  SELECT 
    `Online or In-Person`,
    '3' AS quarter, Q3 AS target 
  FROM `pd_week3_2023`
  UNION ALL
  SELECT 
    `Online or In-Person`,
    '4' AS quarter, Q4 AS target 
  FROM `pd_week3_2023`
) AS U
ON T.`Online or In-Person` = U.`Online or In-Person`
INNER JOIN CTE AS V 
ON T.`Online or In-Person`= V.online_in_person 
AND U.quarter = V.quarter
GROUP BY U.quarter, U.`Online or In-Person`, U.target;