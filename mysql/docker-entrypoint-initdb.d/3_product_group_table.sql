USE db_data;

CREATE TABLE IF NOT EXISTS product_group (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  create_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO product_group (name, create_date) VALUES
  ('Electronics', '2024-05-12 09:30:00'),
  ('Household',   '2024-05-12 09:30:00'),
  ('Toys',        '2024-05-12 09:30:00'),
  ('Clothing',    '2024-05-12 09:30:00');