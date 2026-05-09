-- =============================================================================
-- SQL DRILL — SESSION 01 (2026-05-09)
-- Schema: users(id, status, created_at, country) — 1M rows
--         orders(id, user_id, amount)             — 10M rows
-- Focus: GROUP BY, aggregations, JOIN, subqueries, NOT EXISTS, CASE WHEN
-- =============================================================================
-- -----------------------------------------------------------------------------
-- TASK 1: Top-3 countries by total order amount
-- Concepts: JOIN, GROUP BY, SUM, ORDER BY alias, LIMIT
-- Notes: LEFT JOIN was used initially — semantically wrong for this task.
--        INNER JOIN is correct: users without orders don't contribute to sum.
--        ORDER BY must reference alias, not duplicate the aggregate.
-- -----------------------------------------------------------------------------
SELECT u.country,
    SUM(o.amount) AS total_amount
FROM users AS u
    INNER JOIN orders AS o ON u.id = o.user_id
GROUP BY u.country
ORDER BY total_amount DESC
LIMIT 3;
-- -----------------------------------------------------------------------------
-- TASK 2: Users whose total order amount exceeds a threshold
-- Concepts: GROUP BY, SUM, HAVING
-- Notes: Threshold 600,000 was unreachable (max real sum ~16,000).
--        Adjusted to 10,000 — returns thousands of rows, always LIMIT in drill.
-- -----------------------------------------------------------------------------
SELECT user_id,
    COUNT(*) AS order_count,
    SUM(amount) AS total_amount
FROM orders
GROUP BY user_id
HAVING SUM(amount) > 10000
ORDER BY total_amount DESC
LIMIT 10;
-- -----------------------------------------------------------------------------
-- TASK 3: Countries where average order amount exceeds 500
-- Concepts: GROUP BY, AVG, HAVING
-- -----------------------------------------------------------------------------
SELECT u.country,
    AVG(o.amount) AS avg_amount
FROM users AS u
    INNER JOIN orders AS o ON u.id = o.user_id
GROUP BY u.country
HAVING AVG(o.amount) > 500
ORDER BY avg_amount DESC;
-- -----------------------------------------------------------------------------
-- TASK 4: Users with order count above the average order count per user
-- Concepts: subquery in HAVING, scalar subquery, AVG over grouped result
-- Notes: Avoid using reserved words (count, sum) as aliases in subqueries.
--        Two-level nesting was used — acceptable but can be flattened.
-- -----------------------------------------------------------------------------
SELECT user_id,
    COUNT(id) AS order_count
FROM orders
GROUP BY user_id
HAVING COUNT(id) > (
        SELECT AVG(cnt)
        FROM (
                SELECT COUNT(id) AS cnt
                FROM orders
                GROUP BY user_id
            ) AS per_user
    )
ORDER BY order_count DESC
LIMIT 10;
-- -----------------------------------------------------------------------------
-- TASK 5: Users whose ALL orders have amount < 500
-- Concepts: HAVING with MAX — cleaner than subquery here
-- Notes: HAVING MAX(amount) < 500 is semantically exact:
--        if max is below 500, all individual values are below 500.
--        A subquery-based approach would be more expensive without adding clarity.
-- -----------------------------------------------------------------------------
SELECT user_id,
    MAX(amount) AS max_amount
FROM orders
GROUP BY user_id
HAVING MAX(amount) < 500
ORDER BY max_amount DESC
LIMIT 10;
-- -----------------------------------------------------------------------------
-- TASK 6: Countries with more than 100,000 unique users who placed at least one order
-- Concepts: COUNT(DISTINCT), JOIN, HAVING
-- Notes: Initial attempt used a subquery with HAVING COUNT > 1 (wrong — "at least one").
--        Final version: COUNT(DISTINCT u.id) without subquery is cleaner and correct.
--        HAVING can reference the SELECT alias directly in PostgreSQL.
-- -----------------------------------------------------------------------------
SELECT u.country,
    COUNT(DISTINCT u.id) AS active_users
FROM users AS u
    INNER JOIN orders AS o ON o.user_id = u.id
GROUP BY u.country
HAVING COUNT(DISTINCT u.id) > 100000
ORDER BY active_users DESC;
-- -----------------------------------------------------------------------------
-- TASK 7: Users where max order is strictly greater than double their own average
-- Concepts: HAVING with multiple aggregates, no subquery needed
-- -----------------------------------------------------------------------------
SELECT user_id,
    MAX(amount) AS max_amount,
    AVG(amount) AS avg_amount
FROM orders
GROUP BY user_id
HAVING MAX(amount) > 2 * AVG(amount)
ORDER BY max_amount DESC
LIMIT 10;
-- -----------------------------------------------------------------------------
-- TASK 8: Users who placed NO orders
-- Concepts: NOT EXISTS with correlated subquery
-- Notes: NOT IN on 10M rows caused timeout — query was cancelled manually.
--        Problem with NOT IN: if subquery returns any NULL, entire result is empty.
--        NOT EXISTS with correlation is correct and index-friendly.
--        Correlated subquery: inner query references outer row via alias (u.id).
--        SELECT 1 — we don't care about the value, only existence of a row.
-- -----------------------------------------------------------------------------
SELECT id,
    country,
    status
FROM users AS u
WHERE NOT EXISTS (
        SELECT 1
        FROM orders AS o
        WHERE o.user_id = u.id
    )
LIMIT 10;
-- -----------------------------------------------------------------------------
-- TASK 9: Count of inactive users with no orders, grouped by country
-- Concepts: WHERE + NOT EXISTS (correlated), GROUP BY, COUNT
-- -----------------------------------------------------------------------------
SELECT country,
    COUNT(id) AS inactive_no_orders
FROM users AS u
WHERE status = 'inactive'
    AND NOT EXISTS (
        SELECT 1
        FROM orders AS o
        WHERE o.user_id = u.id
    )
GROUP BY country
ORDER BY inactive_no_orders DESC;
-- -----------------------------------------------------------------------------
-- TASK 10: Countries where avg amount of active users > avg amount of inactive users
-- Concepts: CASE WHEN inside AVG, ELSE NULL vs ELSE 0, HAVING on computed aggregates
-- Notes: ELSE 0 inflates the denominator — AVG counts the zero-value rows.
--        ELSE NULL is correct: AVG ignores NULLs automatically.
--        On synthetic uniform data, active ≈ inactive — no rows passed HAVING.
--        Remove HAVING to verify the query logic returns correct values.
-- -----------------------------------------------------------------------------
SELECT u.country,
    AVG(
        CASE
            WHEN u.status = 'active' THEN o.amount
            ELSE NULL
        END
    ) AS avg_active,
    AVG(
        CASE
            WHEN u.status = 'inactive' THEN o.amount
            ELSE NULL
        END
    ) AS avg_inactive
FROM users AS u
    INNER JOIN orders AS o ON o.user_id = u.id
GROUP BY u.country
HAVING AVG(
        CASE
            WHEN u.status = 'active' THEN o.amount
            ELSE NULL
        END
    ) > AVG(
        CASE
            WHEN u.status = 'inactive' THEN o.amount
            ELSE NULL
        END
    )
ORDER BY avg_active DESC;