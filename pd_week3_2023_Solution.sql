SELECT * FROM `pd_week3_2023`;
SELECT * FROM `pd_week1_2023`;


WITH CTE AS (
  SELECT 
    CASE 
      WHEN `Online or In-Person` = 1 THEN 'Online'
      WHEN `Online or In-Person` = 2 THEN 'In-Person'
    END AS online_in_person,
    QUARTER(`Transaction Date`) AS quarter,
    SUM(value) AS total_value
  FROM `pd_week1_2023`
  WHERE LEFT(`Transaction Code`, 3) = 'DSB'
  GROUP BY online_in_person, quarter
)

SELECT 
  T.`Online or In-Person`,
  V.total_value,
  U.target,
  V.total_value - U.target AS variance_from_target
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
AND CAST(REPLACE(T.quarter, 'Q', '') AS UNSIGNED) = CAST(U.quarter AS UNSIGNED)
INNER JOIN CTE AS V 
ON T.`Online or In-Person`= V.online_in_person 
AND T.quarter = V.quarter;
