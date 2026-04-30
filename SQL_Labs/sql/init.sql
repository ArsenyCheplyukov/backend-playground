-- Create table users
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  status TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  country TEXT NOT NULL
);
-- Create table orders
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INT,
  amount INT
);
-- Fill it with sinthetical data
INSERT INTO users(status, created_at, country)
SELECT CASE
    WHEN random() < 0.8 THEN 'active'
    ELSE 'inactive'
  END,
  now() - (random() * interval '365 days'),
  CASE
    WHEN random() < 0.3 THEN 'PL'
    WHEN random() < 0.6 THEN 'DE'
    ELSE 'NL'
  END
FROM generate_series(1, 1000000);
-- Fill orders with sinthetical data
INSERT INTO orders (user_id, amount)
SELECT (random() * 1000000)::int + 1,
  (random() * 1000)::int
FROM generate_series(1, 10000000);
-- Create index
CREATE INDEX idx_users_status_created ON users(status, created_at);