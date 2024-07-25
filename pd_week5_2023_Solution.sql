WITH CTE AS (
    SELECT 
        SUBSTRING_INDEX(`Transaction Code`, '-', 1) AS bank,
        MONTHNAME(STR_TO_DATE(`Transaction Date`, '%d/%m/%Y %H:%i:%s')) AS month,
        SUM(`Value`) AS total_transaction_values
    FROM `pd_week1_2023`
    GROUP BY bank, month
),
Ranked_CTE AS (
    SELECT
        bank,
        month,
        total_transaction_values,
        RANK() OVER (PARTITION BY month ORDER BY total_transaction_values DESC) AS rnk
    FROM CTE
),
AVG_RANK AS (
    SELECT 
        bank,
        AVG(rnk) AS average_rank_across_all_months
    FROM Ranked_CTE
    GROUP BY bank
),
AVG_RNK_VALUE AS (
    SELECT 
        rnk,
        AVG(total_transaction_values) AS avg_transaction_per_rank
    FROM Ranked_CTE
    GROUP BY rnk
)
SELECT 
    Ranked_CTE.bank,
    Ranked_CTE.month,
    Ranked_CTE.total_transaction_values,
    Ranked_CTE.rnk,
    AVG_RANK.average_rank_across_all_months AS avg_rank_per_bank,
    AVG_RNK_VALUE.avg_transaction_per_rank AS avg_transaction_value_per_rank
FROM Ranked_CTE
INNER JOIN AVG_RANK ON AVG_RANK.bank = Ranked_CTE.bank
INNER JOIN AVG_RNK_VALUE ON AVG_RNK_VALUE.rnk = Ranked_CTE.rnk;
