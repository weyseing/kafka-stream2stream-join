USE db_data;

CREATE TABLE IF NOT EXISTS product_group (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  supplier_id INT,
  create_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO product_group (name, supplier_id, create_date) VALUES
  ('Electronics', 1, '2024-05-12 09:30:00'),
  ('Household',   2, '2024-05-12 09:30:00'),
  ('Toys',        3, '2024-05-12 09:30:00'),
  ('Clothing',    1, '2024-05-12 09:30:00');