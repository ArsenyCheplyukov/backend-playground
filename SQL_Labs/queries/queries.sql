-- Get users that are active and created less than some days ago
SELECT 'First Query, test just using Seq scan, Index scan and Hash Scan';
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM users
WHERE status = 'active'
  AND created_at > now() - interval '1 day';
-- Get users and their orders for users that are active
SELECT 'Second Query, test Joins: Nested Loop Join, Hash Join, Merge Join';
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM users u
  JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active';