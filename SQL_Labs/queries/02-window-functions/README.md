# Window Functions

Practice session: 2026-05-15.

## Concepts covered

- `OVER()` clause: empty, `PARTITION BY`, `PARTITION BY + ORDER BY`
- Frame clause: implicit default vs explicit `ROWS BETWEEN ...`
- Ranking: `ROW_NUMBER`, `RANK`, `DENSE_RANK` — behavior on ties
- Top-N per group pattern: WF in subquery/CTE, filter in outer `WHERE`
- `LAG` for comparing with previous row in window

## Key gotcha

Adding `ORDER BY` inside `OVER()` implicitly changes the default frame
from `UNBOUNDED PRECEDING / UNBOUNDED FOLLOWING` (whole partition)
to `UNBOUNDED PRECEDING / CURRENT ROW` (running aggregate).
This is why `SUM(x) OVER (PARTITION BY g)` and
`SUM(x) OVER (PARTITION BY g ORDER BY x)` return different things —
not because of sorting, but because frame changed.

## Execution order

`FROM → WHERE → GROUP BY → HAVING → SELECT (windows) → DISTINCT → ORDER BY → LIMIT`

Window functions are computed in the SELECT phase. They can be referenced
in `ORDER BY` of the same query but NOT in `WHERE`/`GROUP BY`/`HAVING`
(those run earlier). Use subquery or CTE to filter on window results.

## Schema reference

Working DB: `shop`

- `users(id, status, created_at, country)` — 1M rows
- `orders(id, user_id, amount)` — 10M rows, no index on user_id

- `orders(id, user_id, amount)` — 10M rows, no index on user_id
