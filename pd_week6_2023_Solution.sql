WITH PRE_PIVOT AS (
    SELECT 
        `Customer ID`,
        SUBSTRING_INDEX(`pivot_columns`, '___', 1) AS `device`,
        SUBSTRING_INDEX(`pivot_columns`, '___', -1) AS `factor`,
        `value`
    FROM (
        SELECT 
            `Customer ID`,
            'MOBILE_APP___EASE_OF_USE' AS `pivot_columns`, `Mobile App - Ease of Use` AS `value` 
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'MOBILE_APP___EASE_OF_ACCESS', `Mobile App - Ease of Access` 
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'MOBILE_APP___NAVIGATION', `Mobile App - Navigation`
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'MOBILE_APP___LIKELIHOOD_TO_RECOMMEND', `Mobile App - Likelihood to Recommend`
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'MOBILE_APP___OVERALL_RATING', `Mobile App - Overall Rating`
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'ONLINE_INTERFACE___EASE_OF_USE', `Online Interface - Ease of Use`
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'ONLINE_INTERFACE___EASE_OF_ACCESS', `Online Interface - Ease of Access`
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'ONLINE_INTERFACE___NAVIGATION', `Online Interface - Navigation`
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'ONLINE_INTERFACE___LIKELIHOOD_TO_RECOMMEND', `Online Interface - Likelihood to Recommend`
        FROM `pd_week6_2023`
        UNION ALL
        SELECT 
            `Customer ID`,
            'ONLINE_INTERFACE___OVERALL_RATING', `Online Interface - Overall Rating`
        FROM `pd_week6_2023`
    ) AS `union`
),
FORMATTED_DATA AS (
    SELECT 
        `Customer ID` AS `customer_id`,
        `factor`,
        SUM(CASE WHEN `device` = 'MOBILE_APP' THEN `value` ELSE 0 END) AS `MOBILE_APP`,
        SUM(CASE WHEN `device` = 'ONLINE_INTERFACE' THEN `value` ELSE 0 END) AS `ONLINE_INTERFACE`
    FROM `PRE_PIVOT`
    WHERE `factor` <> 'OVERALL_RATING'
    GROUP BY `customer_id`,  `factor`
),
CATEGORIES AS (
    SELECT 
        `customer_id`,
        AVG(`MOBILE_APP`) AS `avg_mobile`,
        AVG(`ONLINE_INTERFACE`) AS `avg_online`,
        AVG(`MOBILE_APP`) - AVG(`ONLINE_INTERFACE`) AS `difference_in_ratings`,
        CASE 
            WHEN AVG(`MOBILE_APP`) - AVG(`ONLINE_INTERFACE`) >= 2 THEN 'Mobile App Superfan'
            WHEN AVG(`MOBILE_APP`) - AVG(`ONLINE_INTERFACE`) >= 1 THEN 'Mobile App Fan'
            WHEN AVG(`MOBILE_APP`) - AVG(`ONLINE_INTERFACE`) <= -2 THEN 'Online Interface Superfan'
            WHEN AVG(`MOBILE_APP`) - AVG(`ONLINE_INTERFACE`) <= -1 THEN 'Online Interface Fan'
            ELSE 'Neutral'
        END AS `fan_category`
    FROM `FORMATTED_DATA`
    GROUP BY `customer_id`
)
SELECT 
    `fan_category` AS `preference`,
    ROUND((COUNT(`customer_id`) / (SELECT COUNT(`customer_id`) FROM `CATEGORIES`)) * 100, 1) AS `percent_of_customers`
FROM `CATEGORIES`
GROUP BY `fan_category`;
