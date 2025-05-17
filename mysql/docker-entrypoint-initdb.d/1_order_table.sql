USE db_data;

CREATE TABLE IF NOT EXISTS `order` (
  id INT PRIMARY KEY AUTO_INCREMENT,
  product VARCHAR(100),
  amount INT,
  buyer_id INT,
  product_group_id INT,
  create_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO `order` (id, product, amount, buyer_id, create_date, product_group_id) VALUES
  (1,  'Widget',      2, 1, '2024-05-12 09:30:00', 1),
  (2,  'Gadget',      3, 2, '2024-05-12 09:30:00', 1),
  (3,  'Doodad',      1, 3, '2024-05-12 09:30:00', 1),
  (4,  'Gizmo',       5, 1, '2024-05-12 09:30:00', 1),
  (5,  'Widget',      7, 2, '2024-05-12 09:30:00', 2),
  (6,  'Gadget',      4, 3, '2024-05-12 09:30:00', 2),
  (7,  'Doodad',      6, 1, '2024-05-12 09:30:00', 2),
  (8,  'Thingamajig', 8, 2, '2024-05-12 09:30:00', 3),
  (9,  'Gizmo',       2, 3, '2024-05-12 09:30:00', 3),
  (10, 'Widget',      9, 1, '2024-05-12 09:30:00', 3);