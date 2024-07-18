SELECT * FROM `pd_week2_2023_sc`;
SELECT * FROM `pd_week2_2023_tran`;

SELECT
  REPLACE(`Sort Code`, '-', '') AS Sort_Code
FROM `pd_week2_2023_tran`;

SELECT 
  `Transaction ID`,
  CONCAT('GB', `Check Digits`, `Swift Code`, REPLACE(`Sort Code`, '-', ''), `Account Number`) as iban
FROM `pd_week2_2023_tran` as T
INNER JOIN `pd_week2_2023_sc` as S ON T.bank = S.bank;
