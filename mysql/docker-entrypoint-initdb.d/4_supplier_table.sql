USE db_data;

CREATE TABLE IF NOT EXISTS supplier (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  create_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO supplier (name, create_date) VALUES
  ('Acme Corp',    '2024-05-12 09:30:00'),
  ('BestWidgets',  '2024-05-12 09:30:00'),
  ('TopSupplies',  '2024-05-12 09:30:00');