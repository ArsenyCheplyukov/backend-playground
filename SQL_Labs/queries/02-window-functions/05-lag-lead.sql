-- LAG(col, n)  = value from n rows BEFORE current, in ORDER BY order
-- LEAD(col, n) = value from n rows AFTER current
-- n defaults to 1
-- First row has no predecessor → LAG returns NULL.
-- amount - NULL = NULL (NULL propagates through arithmetic).
SELECT id,
    user_id,
    amount,
    LAG(amount, 1) OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS prev_amount,
    amount - LAG(amount, 1) OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS diff
FROM orders
WHERE user_id = 2
ORDER BY amount DESC;
-- Output for user 2 (9 orders):
--   amount | prev | diff
--   -------|------|------
--   925    | NULL | NULL     ← first row, no predecessor
--   819    | 925  | -106
--   716    | 819  | -103
--   ...
-- Gotchas:
-- 1. Window alias scope: cannot reference LAG(amount) by alias in the same SELECT.
--    Must repeat the full expression (or wrap in CTE).
-- 2. ORDER BY direction affects sign of diff.
--    DESC → diff is negative (amount decreasing as we go down).
--    ASC  → diff is positive (amount increasing).
-- 3. NULL on first row: use COALESCE if you need 0 instead of NULL.
--    Open question for next session: COALESCE inside LAG or outside?
--    LAG(amount, 1, 0) — third arg = default value when no predecessor.