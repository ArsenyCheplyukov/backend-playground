-- Three frame behaviors on the same data (user_id = 2, 9 orders)
-- A. Default frame WITH ORDER BY inside OVER:
--    implicit ROWS/RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--    → running aggregate
SELECT id,
    amount,
    SUM(amount) OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS frame_default
FROM orders
WHERE user_id = 2
ORDER BY amount DESC;
-- B. Explicit full partition: overrides the implicit running behavior
--    despite ORDER BY being present
SELECT id,
    amount,
    SUM(amount) OVER (
        PARTITION BY user_id
        ORDER BY amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS frame_full
FROM orders
WHERE user_id = 2
ORDER BY amount DESC;
-- All rows show the same total (4468 for user 2).
-- C. Sliding window: current row + 2 preceding
SELECT id,
    amount,
    SUM(amount) OVER (
        PARTITION BY user_id
        ORDER BY amount DESC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS frame_3rolling
FROM orders
WHERE user_id = 2
ORDER BY amount DESC;
-- Row 1: just current (no preceding)
-- Row 2: current + 1 preceding
-- Row 3+: current + 2 preceding (window slides)
-- Frame clause flavors that exist (only ROWS practiced):
-- - ROWS:   physical row offset (predictable, intuitive)
-- - RANGE:  value-based offset on ORDER BY column
-- - GROUPS: peer-group offset
-- Default in PostgreSQL is RANGE when ORDER BY present, which behaves like
-- ROWS for distinct values but differs on ties. Use ROWS explicitly to avoid surprises.