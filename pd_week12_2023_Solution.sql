use preppin_data;

WITH FillYear AS (
    SELECT 
        MAX(`Year`) OVER(ORDER BY `Row Number`) AS year_filled,
        `Date`, 
        `Bank holiday`
    FROM `preppin_data`.`pd_week12_bh`
),
BankHolidays AS (
    SELECT 
        STR_TO_DATE(CONCAT(`Date`, '-', year_filled), '%d-%b-%Y') AS holiday_date,
        `Bank holiday` AS bank_holiday
    FROM FillYear
    WHERE `Date` <> '' 
),
ReportingWithFlag AS (
    SELECT 
        STR_TO_DATE(UK.`Date`, '%d/%m/%Y') AS record_date, 
        DAYNAME(STR_TO_DATE(UK.`Date`, '%d/%m/%Y')) AS weekday_name,
        CASE
            WHEN LEFT(DAYNAME(STR_TO_DATE(UK.`Date`, '%d/%m/%Y')), 1) = 'S' OR BH.bank_holiday IS NOT NULL THEN 'N'
            ELSE 'Y'
        END AS reporting_flag,
        UK.`New Customers` AS new_customers,
        BH.bank_holiday
    FROM 
        pd_week12_newcust AS UK
    LEFT JOIN 
        BankHolidays AS BH 
    ON 
        STR_TO_DATE(UK.`Date`, '%d/%m/%Y') = BH.holiday_date
),
NonReportingDates AS (
    SELECT DISTINCT record_date AS non_reporting_date
    FROM ReportingWithFlag
    WHERE reporting_flag = 'N'
),
ReportingLookup AS (
    SELECT 
        NR.non_reporting_date,
        MIN(R.record_date) AS next_reporting_date
    FROM 
        ReportingWithFlag R
    INNER JOIN 
        NonReportingDates NR 
    ON NR.non_reporting_date < R.record_date
    WHERE R.reporting_flag = 'Y'
    GROUP BY NR.non_reporting_date
),
UKReporting AS (
    SELECT 
        COALESCE(L.next_reporting_date, R.record_date) AS effective_date,
        CONCAT(DATE_FORMAT(COALESCE(L.next_reporting_date, R.record_date), '%b'), '-', YEAR(COALESCE(L.next_reporting_date, R.record_date))) AS report_month,
        SUM(R.new_customers) AS total_new_customers
    FROM 
        ReportingWithFlag R
    LEFT JOIN 
        ReportingLookup L 
    ON R.record_date = L.non_reporting_date
    GROUP BY effective_date, report_month
),
UKLastDay AS (
    SELECT 
        report_month,
        MAX(effective_date) AS last_date
    FROM UKReporting
    GROUP BY report_month
),
UKReportingAdjusted AS (
    SELECT 
        CASE 
            WHEN L.last_date IS NULL THEN CONCAT(MONTHNAME(UK.effective_date), '-', YEAR(UK.effective_date))
            ELSE CONCAT(MONTHNAME(DATE_ADD(UK.effective_date, INTERVAL 1 MONTH)), '-', YEAR(DATE_ADD(UK.effective_date, INTERVAL 1 MONTH)))
        END AS reporting_month,
        UK.effective_date AS reporting_date,
        ROW_NUMBER() OVER(PARTITION BY 
            CASE 
                WHEN L.last_date IS NULL THEN CONCAT(MONTHNAME(UK.effective_date), '-', YEAR(UK.effective_date))
                ELSE CONCAT(MONTHNAME(DATE_ADD(UK.effective_date, INTERVAL 1 MONTH)), '-', YEAR(DATE_ADD(UK.effective_date, INTERVAL 1 MONTH)))
            END 
            ORDER BY UK.effective_date
        ) AS reporting_day,
        UK.total_new_customers AS uk_new_customers
    FROM 
        UKReporting UK
    LEFT JOIN 
        UKLastDay L 
    ON UK.effective_date = L.last_date
    WHERE UK.effective_date < '2023-12-31'
),
ROIReporting AS (
    SELECT 
        `Reporting Month` AS roi_reporting_month,
        `Reporting Day` AS roi_reporting_day,
        `New Customers` AS roi_new_customers,
        `Reporting Date` AS roi_reporting_date
    FROM pd_week12_newcustrep
),
MatchedUKDates AS (
    SELECT 
        UK.reporting_month,
        UK.reporting_day,
        UK.reporting_date,
        UK.uk_new_customers,
        COALESCE(ROI.roi_new_customers, 0) AS roi_new_customers,
        ROI.roi_reporting_month
    FROM 
        UKReportingAdjusted UK
    LEFT JOIN 
        ROIReporting ROI 
    ON UK.reporting_date = ROI.roi_reporting_date
),
ROIAdjusted AS (
    SELECT 
        ROI.roi_reporting_month,
        ROI.roi_reporting_day,
        ROI.roi_new_customers,
        ROI.roi_reporting_date,
        MIN(UK2.reporting_date) AS next_uk_date
    FROM 
        ROIReporting ROI
    LEFT JOIN 
        UKReportingAdjusted UK 
    ON ROI.roi_reporting_date = UK.reporting_date
    LEFT JOIN 
        UKReportingAdjusted UK2 
    ON UK2.reporting_date > ROI.roi_reporting_date
    WHERE UK.reporting_date IS NULL
    GROUP BY 
        ROI.roi_reporting_month, 
        ROI.roi_reporting_day, 
        ROI.roi_new_customers, 
        ROI.roi_reporting_date
),
CombinedData AS (
    SELECT 
        UK.reporting_month,
        UK.reporting_day,
        UK.reporting_date,
        0 AS uk_new_customers,
        ROI.roi_new_customers,
        ROI.roi_reporting_month
    FROM 
        ROIAdjusted ROI
    INNER JOIN 
        UKReportingAdjusted UK 
    ON UK.reporting_date = ROI.next_uk_date

    UNION ALL

    SELECT 
        reporting_month,
        reporting_day,
        reporting_date,
        uk_new_customers,
        roi_new_customers,
        roi_reporting_month
    FROM 
        MatchedUKDates
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
    SUM(uk_new_customers) AS uk_new_customers,
    SUM(roi_new_customers) AS roi_new_customers
FROM 
    CombinedData
GROUP BY 
    misaligned_flag,
    reporting_month,
    reporting_day,
    reporting_date,
    roi_reporting_month;
