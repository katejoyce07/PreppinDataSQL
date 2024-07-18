WITH CTE AS (
    SELECT *, 'pd2023_wk04_january' AS tablename FROM `pd_week4_jan`
    UNION ALL 
    SELECT *, 'pd2023_wk04_february' AS tablename FROM `pd_week4_jan`
    UNION ALL 
    SELECT *, 'pd2023_wk04_march' AS tablename FROM `pd_week4_jan`
    UNION ALL 
    SELECT *, 'pd2023_wk04_april' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_may' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_june' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_july' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_august' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_september' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_october' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_november' AS tablename FROM `pd_week4_jan`
    UNION ALL
    SELECT *, 'pd2023_wk04_december' AS tablename FROM `pd_week4_jan`
),
PRE_PIVOT AS (
    SELECT 
        id,
          CONCAT_WS('-', SUBSTRING_INDEX(`tablename`, '_', 2), 
                    SUBSTRING_INDEX(SUBSTRING_INDEX(`tablename`, '_', -2), '_', 1), 
                    `Joining Day`
               ) AS joining_date,
        `Demographic`,
        value
    FROM CTE
),
POST_PIVOT AS (
    SELECT 
        id,
        joining_date,
        MAX(CASE WHEN `Demographic` = 'Ethnicity' THEN value END) AS ethnicity,
        MAX(CASE WHEN `Demographic` = 'Account Type' THEN value END) AS account_type,
        MAX(CASE WHEN `Demographic` = 'Date of Birth' THEN `Value` END) AS date_of_birth,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY joining_date ASC) AS rn
    FROM PRE_PIVOT
    GROUP BY id, joining_date
)
SELECT 
    id,
    joining_date,
    account_type,
    date_of_birth,
    ethnicity
FROM POST_PIVOT
WHERE rn = 1;
