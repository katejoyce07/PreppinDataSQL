WITH RECURSIVE ACC AS (
    SELECT 
        `Account Number` AS account_number,
        `Account Type` AS account_type,
        TRIM(SUBSTRING_INDEX(`Account Holder Id`, ',', 1)) AS account_holder_id,
        `Balance Date` AS balance_date,
        `Balance` AS balance,
        TRIM(SUBSTRING(`Account Holder Id`, LENGTH(SUBSTRING_INDEX(`Account Holder Id`, ',', 1)) + 2)) AS remaining_ids
    FROM `pd_week7accountinfo_2023`
    WHERE `Account Holder Id` IS NOT NULL

    UNION ALL

    SELECT
        account_number,
        account_type,
        TRIM(SUBSTRING_INDEX(remaining_ids, ',', 1)),
        balance_date,
        balance,
        TRIM(SUBSTRING(remaining_ids, LENGTH(SUBSTRING_INDEX(remaining_ids, ',', 1)) + 2))
    FROM ACC
    WHERE remaining_ids != ''
)

SELECT 
    D.`Transaction ID`,
    P.`Account_To` AS account_to,
    D.`Transaction Date`,
    ACC.account_number,
    ACC.account_type,
    ACC.balance_date,
    ACC.balance,
    H.`Name`,
    H.`Date of Birth` AS date_of_birth,
    CONCAT('0', H.`Contact Number`) AS contact_number,
    H.`First Line of Address` AS first_line_of_address
FROM `pd_week7trandet_2023` AS D
INNER JOIN `pd_week7_tranpath_2023` AS P ON D.`Transaction ID` = P.`Transaction ID`
INNER JOIN ACC ON ACC.account_number = P.`Account_From`
INNER JOIN `pd_week7accountholder_2023` AS H ON H.`Account Holder ID` = ACC.account_holder_id
WHERE D.`Cancelled?` = 'N'
AND D.value > 1000
AND ACC.account_type != 'Platinum';
