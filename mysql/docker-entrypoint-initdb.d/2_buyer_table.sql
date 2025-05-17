USE db_data;

CREATE TABLE IF NOT EXISTS buyer (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  create_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO buyer (id, name, create_date) VALUES
  (1, 'Alice', '2024-05-12 09:30:00'),
  (2, 'Bob', '2024-05-12 09:30:00'),
  (3, 'Charlie', '2024-05-12 09:30:00');
