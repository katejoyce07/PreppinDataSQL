WITH CTE AS (
SELECT `Account_To` as 'Account_ID',
`Transaction Date`,
`Value`,
`Balance`
FROM `preppin_data`.`pd_week7trandet_2023` as d
INNER JOIN `preppin_data`.`pd_week7_tranpath_2023` AS p ON d.`Transaction ID` = p.`Transaction ID`
INNER JOIN `preppin_data`.`pd_week7accountinfo_2023` AS a on A.`Account Number` = p.`Account_To`
WHERE `Cancelled?` != 'N' and `Balance Date` = '2023-01-31'
 
 UNION ALL
 
SELECT `Account_From` as 'Account_ID',
`Transaction Date`,
`Value` *(-1) as 'Value',
`Balance`
FROM `preppin_data`.`pd_week7trandet_2023` as d
INNER JOIN `preppin_data`.`pd_week7_tranpath_2023` AS p ON d.`Transaction ID` = p.`Transaction ID`
INNER JOIN `preppin_data`.`pd_week7accountinfo_2023` AS a on A.`Account Number` = p.`Account_From`
WHERE `Cancelled?` != 'N' AND `Balance Date` = '2023-01-31'

UNION ALL

SELECT `Account Number` AS 'Account_ID',
`Balance Date` as `Transaction Date`,
NULL as 'Value',
`Balance`
FROM `preppin_data`.`pd_week7accountinfo_2023`
)
SELECT `Account_ID`,
       `Transaction Date`,
       `Value`,
       `Balance`,
      SUM(COALESCE(`Value`,0))OVER (PARTITION BY `Account_ID` ORDER BY `Transaction Date`, `Value` DESC) + `Balance` AS `Running Sum`
FROM CTE
ORDER BY Account_ID, `Transaction Date`, `Value` DESC;

















