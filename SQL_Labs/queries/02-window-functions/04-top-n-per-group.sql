-- Pattern: filter by window function result requires subquery or CTE
-- because WHERE runs BEFORE the SELECT phase where windows are computed
-- DOES NOT WORK: window alias not visible in WHERE
-- SELECT user_id, id, amount,
--        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
-- FROM orders
-- WHERE user_id IN (1,2,3,4,5)
--   AND rn <= 2;
-- Subquery version
SELECT user_id,
    id,
    amount
FROM (
        SELECT user_id,
            id,
            amount,
            ROW_NUMBER() OVER (
                PARTITION BY user_id
                ORDER BY amount DESC
            ) AS rn
        FROM orders
        WHERE user_id IN (1, 2, 3, 4, 5)
    ) ranked
WHERE rn <= 2;
-- CTE version (equivalent, often more readable in multi-step queries)
WITH ranked AS (
    SELECT user_id,
        id,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY amount DESC
        ) AS rn
    FROM orders
    WHERE user_id IN (1, 2, 3, 4, 5)
)
SELECT user_id,
    id,
    amount
FROM ranked
WHERE rn <= 2;