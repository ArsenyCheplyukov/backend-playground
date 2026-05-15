-- OVER() with empty parens: aggregate over entire result set
-- (or entire partition if PARTITION BY is added)
SELECT id,
    amount,
    SUM(amount) OVER () AS total
FROM orders
LIMIT 5;
-- Each row gets the same total. SUM is computed once across all rows.
-- Different from SELECT SUM(amount) FROM orders: that collapses to 1 row.
-- Window keeps row granularity, attaches aggregate alongside.
-- PARTITION BY: aggregate per group, but keep individual rows
SELECT id,
    user_id,
    amount,
    SUM(amount) OVER (PARTITION BY user_id) AS user_total
FROM orders
WHERE user_id IN (1, 2, 3)
ORDER BY user_id,
    id;
-- user_total is the same within each user_id group.
-- All orders of user 1 show their total. Same for user 2, 3.
-- Adding ORDER BY inside OVER changes the implicit frame
-- See 02-frame-clause.sql for the full story
SELECT id,
    user_id,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS rn,
    SUM(amount) OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS running_sum
FROM orders
WHERE user_id IN (1, 2)
ORDER BY user_id,
    rn;
-- running_sum accumulates: row 1 = amount, row 2 = sum of top 2, etc.
-- ROW_NUMBER unaffected by frame (it's a ranking function, not aggregate).