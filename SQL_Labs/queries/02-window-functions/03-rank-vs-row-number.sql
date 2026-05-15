-- Setup: inject duplicate amounts to expose ties behavior
INSERT INTO orders (user_id, amount)
VALUES (1, 136),
    (1, 136);
-- Compare three ranking functions on the same ORDER BY
SELECT id,
    user_id,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS rn,
    RANK() OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS rnk,
    DENSE_RANK() OVER (
        PARTITION BY user_id
        ORDER BY amount DESC
    ) AS dnk
FROM orders
WHERE user_id = 1
ORDER BY amount DESC;
-- Expected output for user_id = 1 after the inserts:
--
--   amount | rn | rnk | dnk
--   -------|----|-----|----
--   136    | 1  | 1   | 1   ← tie group
--   136    | 2  | 1   | 1   ← tie group
--   136    | 3  | 1   | 1   ← tie group
--   73     | 4  | 4   | 2   ← RANK jumps to 4 (position-based), DENSE_RANK to 2
--   72     | 5  | 5   | 3
--   69     | 6  | 6   | 4
--
-- ROW_NUMBER:  always unique. Order between tied rows is undefined
--              (depends on execution plan). Add tie-breaker if stability needed:
--              ORDER BY amount DESC, id
-- RANK:        ties get the lowest position of the group. Next non-tied row
--              gets its actual row position (gaps).
-- DENSE_RANK:  ties get same rank, next row is previous_rank + 1 (no gaps).
-- Selection guide:
-- Top-N strict (exactly 2 rows even with ties): ROW_NUMBER, but ties resolved arbitrarily
-- Top-N inclusive (include everyone tied at place N): RANK or DENSE_RANK, filter <= N
-- Top-N distinct values (top 3 distinct amounts):  DENSE_RANK, filter <= 3
-- Cleanup
DELETE FROM orders
WHERE id IN (10000001, 10000002);