USE preppin_data;
WITH FILL_YEAR AS (
    SELECT 
        MAX(`Year`) OVER(ORDER BY `Row Number`) AS Year, -- Propagate the Year value
        `Date`, 
        `Bank holiday`
    FROM `preppin_data`.`pd_week12_bh`
),

BANK_HOLS AS (
    SELECT 
        STR_TO_DATE(CONCAT(`Date`, '-', `Year`), '%d-%b-%Y') AS date,
        `Bank holiday`
    FROM FILL_YEAR
    WHERE `Date` <> '' 
)
    
,  REPORTING_WITH_FLAG AS(
SELECT 
    STR_TO_DATE(UK.`Date`, '%d/%m/%Y') AS date, 
    dayname(STR_TO_DATE(UK.`Date`, '%d/%m/%Y')) as weekday,
    CASE
    WHEN LEFT(dayname(STR_TO_DATE(UK.`Date`, '%d/%m/%Y')),1) = 'S' or BH.`Bank holiday` IS NOT NULL THEN 'N'
    ELSE 'Y'
    END AS reporting_flag,
    `New Customers`,
    BH.`Bank holiday`
FROM 
    pd_week12_newcust AS UK
LEFT JOIN 
    BANK_HOLS AS BH 
ON 
    STR_TO_DATE(UK.`Date`, '%d/%m/%Y') = BH.date
)
    
, NON_REPORTING_DATES AS(
SELECT DISTINCT(date) as non_reporting_date
from REPORTING_WITH_FLAG
WHERE reporting_flag = 'N'
) 
    
, REPORTING_LOOKUP AS (
SELECT non_reporting_date,
min(date) as next_reporting_date
FROM REPORTING_WITH_FLAG AS R
INNER JOIN NON_REPORTING_DATES AS NR ON NR.non_reporting_date < R.date
where reporting_flag = 'Y'
group by non_reporting_date
)
    
, UK_REPORTING AS (
SELECT coalesce(next_reporting_date, date) as date,
CONCAT(DATE_FORMAT(COALESCE(next_reporting_date, date), '%b'), '-', YEAR(COALESCE(next_reporting_date, date))) AS month,
SUM(`New Customers`) AS new_customers
FROM REPORTING_WITH_FLAG AS R
LEFT JOIN REPORTING_LOOKUP AS L ON non_reporting_date = R.date
GROUP BY 1,2
)
    
, UK_LAST_DAY as (
SELECT month,
MAX(date) as last_date
FROM UK_REPORTING
group by month
)
    
, UK_REPORTING_ADJ AS(
SELECT 
    CASE 
        WHEN L.last_date IS NULL THEN CONCAT(MONTHNAME(UK.date), '-', YEAR(UK.date))
        ELSE CONCAT(MONTHNAME(DATE_ADD(UK.date, INTERVAL 1 MONTH)), '-', YEAR(DATE_ADD(UK.date, INTERVAL 1 MONTH)))
    END AS reporting_month,
date,
ROW_NUMBER() OVER(PARTITION BY
   (CASE 
        WHEN L.last_date IS NULL THEN CONCAT(MONTHNAME(UK.date), '-', YEAR(UK.date))
        ELSE CONCAT(MONTHNAME(DATE_ADD(UK.date, INTERVAL 1 MONTH)), '-', YEAR(DATE_ADD(UK.date, INTERVAL 1 MONTH)))
    END)  ORDER BY date
    ) as reporting_day,
new_customers as uk_new_customers
FROM UK_REPORTING AS UK
LEFT JOIN UK_LAST_DAY AS L 
    ON UK.date = L.last_date
WHERE date < '2023-12-31'
)
    
, ROI_DATA AS (
SELECT `Reporting Month` as roi_reporting_month,
`Reporting Day` as roi_reporting_day,
`New Customers` as roi_new_customers,
`Reporting Date` as roi_reporting_date
FROM pd_week12_newcustrep
)
    
, MATCHING_UK_DATES AS (
SELECT reporting_month,
reporting_day,
date as reporting_date,
uk_new_customers,
coalesce(roi_new_customers, 0) as roi_new_customers,
roi_reporting_month
FROM UK_REPORTING_ADJ AS UK
left JOIN ROI_DATA AS ROI ON UK.date = ROI.roi_reporting_date
)
    
, ROI_DATA_ADJ AS(
SELECT 
roi_reporting_month,
roi_reporting_day,
roi_new_customers,
roi_reporting_date,
min(UK2.date) AS next_uk_date
FROM ROI_DATA AS ROI
LEFT JOIN UK_REPORTING_ADJ AS UK ON UK.date = ROI.roi_reporting_date
LEFT JOIN UK_REPORTING_ADJ AS UK2 ON UK2.date > ROI.roi_reporting_date
WHERE UK.date IS NULL
GROUP BY roi_reporting_month,
roi_reporting_day,
roi_new_customers,
roi_reporting_date
)
    
, COMBINED AS (
SELECT reporting_month,
reporting_day,
date as reporting_date,
0 as uk_new_customers,
roi_new_customers,
roi_reporting_month
FROM ROI_DATA_ADJ AS ROI
INNER JOIN UK_REPORTING_ADJ AS UK ON UK.date = ROI.next_uk_date

UNION ALL

SELECT *
FROM MATCHING_UK_DATES
)
SELECT 
CASE
WHEN roi_reporting_month IS NULL THEN 'x'
WHEN LEFT(reporting_month, 3) = LEFT(roi_reporting_month, 3) THEN 'x'
ELSE ''
END AS misaligned_flag,
reporting_month,
reporting_day,
reporting_date,
SUM(uk_new_customers) as uk_new_customers,
SUM(roi_new_customers) as roi_new_customers
from COMBINED
GROUP BY
CASE
WHEN roi_reporting_month IS NULL THEN 'x'
WHEN LEFT(reporting_month, 3) = LEFT(roi_reporting_month, 3) THEN 'x'
ELSE ''
END,
reporting_month,
reporting_day,
reporting_date,
roi_reporting_month;
