# Setup
- Create docker network via `docker network create global-net`
- Create all Kafka connectors in `connector` folder.
- Create all Ksql streams/tables in `ksql` folder.
- Table in `MySQL DB` will be used as dummy data.

# Supported Join Types
- **Reference:** https://docs.confluent.io/platform/current/ksqldb/developer-guide/joins/join-streams-and-tables.html#join-capabilities
- ksqlDB supports these stream-stream joins (all need a `WITHIN` time window).
    - `FULL OUTER JOIN`
    - `INNER JOIN`
    - `LEFT JOIN` / `LEFT OUTER JOIN`
    - `RIGHT JOIN` / `RIGHT OUTER JOIN`

#  Join Event Flow
- In ksqlDB, **which stream** the event comes from **affects how the joins are processed**, according to the pattern `(((A JOIN B) JOIN C) JOIN D)`.
- **Event from C:** If it can't match with results from streams A and B, it stops and won't be joined with D.
- **Event from D:** It always tries to join with previous streams, no matter what happened before, but only produces a result if everything matches in the end.

### Example: Event from Stream C
- Ensure **remove dummy data** to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > DELETE FROM `supplier` WHERE id > 3;
    > ```

- Ensure **recreate streams** to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_join;
    > DROP STREAM streamtostream_stream_supplier_intake;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Create **JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join WITH 
    > (KAFKA_TOPIC='streamtostream_stream_join', VALUE_FORMAT='AVRO') AS
    > SELECT 
    >     -- ROWKEY AS join_rowkey, -- only for OUTER JOIN
    >     o.id AS order_id,
    >     o.product AS product,
    >     o.create_date AS o_create_date,
    >     
    >     -- buyer
    >     o.buyer_id AS o_buyer_id,
    >     b.id AS b_buyer_id,
    >     b.name AS buyer_name,
    >     b.create_date AS b_create_date,
    >     
    >     -- product group
    >     o.product_group_id AS o_product_group_id,
    >     p.id AS p_product_group_id,
    >     p.name AS product_group_name,
    >     p.create_date AS p_create_date,
    > 
    >     -- supplier
    >     p.supplier_id AS o_supplier_id,
    >     s.id AS s_supplier_id,
    >     s.name AS supplier_name,
    >     s.create_date AS s_create_date
    > 
    > FROM streamtostream_stream_order_intake o
    > LEFT JOIN streamtostream_stream_buyer_intake b
    >     WITHIN (5 MINUTES, 10 MINUTES)
    >     ON o.buyer_id = b.id
    > RIGHT JOIN streamtostream_stream_product_group_intake p
    >     WITHIN (15 MINUTES, 30 MINUTES)
    >     ON o.product_group_id = p.id
    > LEFT JOIN streamtostream_stream_supplier_intake s
    >     WITHIN (20 MINUTES, 40 MINUTES)
    >     ON p.supplier_id = s.id
    > EMIT CHANGES;
    > ```

- Pull request to JOIN stream to **check result**.
    ```sql
    SELECT * FROM streamtostream_stream_join EMIT CHANGES;
    ```

- Insert **dummy data**.
    > ```sql
    > INSERT INTO `supplier` (`id`, `name`, `create_date`) VALUES ('4', 'TopSupplies4', '2024-05-13 09:30:00');
    > INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES ('5', 'Clothing5', '4', '2024-05-13 09:30:00');
    > ```

- **Result:** Since the event happened in Stream C `(product_group)`, it appears in the results for Stream C even though there’s no matching data from Stream A `(order)` or Stream B `(buyer)`.
    > ```
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |O_SUPPLIER_ID   |ORDER_ID        |PRODUCT         |O_CREATE_DATE   |O_BUYER_ID      |B_BUYER_ID      |BUYER_NAME      |B_CREATE_DATE   |O_PRODUCT_GROUP_|P_PRODUCT_GROUP_|PRODUCT_GROUP_NA|P_CREATE_DATE   |S_SUPPLIER_ID   |SUPPLIER_NAME   |S_CREATE_DATE   |
    > |                |                |                |                |                |                |                |                |ID              |ID              |ME              |                |                |                |                |
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |4               |null            |null            |null            |null            |null            |null            |null            |null            |5               |Clothing5       |2024-05-13T09:30|4               |TopSupplies4    |2024-05-13T09:30|
    > |                |                |                |                |                |                |                |                |                |                |                |:00.000         |                |                |:00.000         |
    > ```

### Example: Event from Stream B
- Ensure **remove dummy data** to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > DELETE FROM `supplier` WHERE id > 3;
    > ```

- Ensure **recreate streams** to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_join;
    > DROP STREAM streamtostream_stream_supplier_intake;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Create **JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join WITH 
    > (KAFKA_TOPIC='streamtostream_stream_join', VALUE_FORMAT='AVRO') AS
    > SELECT 
    >     -- ROWKEY AS join_rowkey, -- only for OUTER JOIN
    >     o.id AS order_id,
    >     o.product AS product,
    >     o.create_date AS o_create_date,
    >     
    >     -- buyer
    >     o.buyer_id AS o_buyer_id,
    >     b.id AS b_buyer_id,
    >     b.name AS buyer_name,
    >     b.create_date AS b_create_date,
    >     
    >     -- product group
    >     o.product_group_id AS o_product_group_id,
    >     p.id AS p_product_group_id,
    >     p.name AS product_group_name,
    >     p.create_date AS p_create_date,
    > 
    >     -- supplier
    >     p.supplier_id AS o_supplier_id,
    >     s.id AS s_supplier_id,
    >     s.name AS supplier_name,
    >     s.create_date AS s_create_date
    > 
    > FROM streamtostream_stream_order_intake o
    > LEFT JOIN streamtostream_stream_buyer_intake b
    >     WITHIN (5 MINUTES, 10 MINUTES)
    >     ON o.buyer_id = b.id
    > RIGHT JOIN streamtostream_stream_product_group_intake p
    >     WITHIN (15 MINUTES, 30 MINUTES)
    >     ON o.product_group_id = p.id
    > LEFT JOIN streamtostream_stream_supplier_intake s
    >     WITHIN (20 MINUTES, 40 MINUTES)
    >     ON p.supplier_id = s.id
    > EMIT CHANGES;
    > ```

- Pull request to JOIN stream to **check result**.
    ```sql
    SELECT * FROM streamtostream_stream_join EMIT CHANGES;
    ```

- Insert **dummy data**.
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '999', '5', '2024-05-12 09:30:00');
    > INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES ('5', 'Clothing5', '4', '2024-05-12 09:30:00');
    > INSERT INTO `supplier` (`id`, `name`, `create_date`) VALUES ('4', 'TopSupplies4', '2024-05-12 09:30:00');
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-12 09:30:00');
    > ```

- **Result:** If an event happens in Stream B (`buyer`), there’s no output because it doesn't find a match with Stream A (`order`). So, it won’t continue to Stream C (`product_group`) or Stream D (`supplier`), even if there are matches in those streams for Stream A.
    > ```
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |O_SUPPLIER_ID   |ORDER_ID        |PRODUCT         |O_CREATE_DATE   |O_BUYER_ID      |B_BUYER_ID      |BUYER_NAME      |B_CREATE_DATE   |O_PRODUCT_GROUP_|P_PRODUCT_GROUP_|PRODUCT_GROUP_NA|P_CREATE_DATE   |S_SUPPLIER_ID   |SUPPLIER_NAME   |S_CREATE_DATE   |
    > |                |                |                |                |                |                |                |                |ID              |ID              |ME              |                |                |                |                |
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |4               |null            |null            |null            |null            |null            |null            |null            |null            |5               |Clothing5       |2024-05-12T09:30|null            |null            |null            |
    > |                |                |                |                |                |                |                |                |                |                |                |:00.000         |                |                |                |
    > |4               |null            |null            |null            |null            |null            |null            |null            |null            |5               |Clothing5       |2024-05-12T09:30|4               |TopSupplies4    |2024-05-12T09:30|
    > |                |                |                |                |                |                |                |                |                |                |                |:00.000         |                |                |:00.000         |
    > ```

# Join Window
A **window** in ksqlDB stream-stream joins defines the allowed time difference between events from each stream for the join to occur.

**Window Examples:**
- `WITHIN 10 MINUTES` — events from Stream A and Stream B will match if they arrive within 10 minutes of each other.
- `WITHIN (5 MINUTES, 10 MINUTES)` — matches if Stream B’s event is from 5 minutes **before** to 10 minutes **after** Stream A’s event.

**Scenarios:**
- If **Stream A** event at 12:00 and **Stream B** event at 12:09 (`WITHIN 10 MINUTES`): join matches.
- If **Stream A** at 12:00 and **Stream B** at 11:55: with `WITHIN (5 MINUTES, 10 MINUTES)`, join matches (B occurred 5 minutes before A).
- If **Stream A** at 12:00 and **Stream B** at 12:09: with `WITHIN (5 MINUTES, 10 MINUTES)`, join matches (B occurred 9 minutes after A).

### Example
- Ensure **remove dummy data** to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > DELETE FROM `supplier` WHERE id > 3;
    > ```

- Ensure **recreate streams** to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_join;
    > DROP STREAM streamtostream_stream_supplier_intake;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Create **JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join WITH 
    > (KAFKA_TOPIC='streamtostream_stream_join', VALUE_FORMAT='AVRO') AS
    > SELECT 
    >     ROWKEY AS join_rowkey,
    >     o.id AS order_id,
    >     o.product AS product,
    >     o.create_date AS o_create_date,
    > 
    >     -- buyer
    >     o.buyer_id AS o_buyer_id,
    >     b.id AS b_buyer_id,
    >     b.name AS buyer_name,
    >     b.create_date AS b_create_date,
    > 
    >     -- product group
    >     o.product_group_id AS o_product_group_id,
    >     p.id AS p_product_group_id,
    >     p.name AS product_group_name,
    >     p.create_date AS p_create_date
    > 
    > FROM streamtostream_stream_order_intake o
    > FULL OUTER JOIN streamtostream_stream_buyer_intake b
    >     WITHIN (5 MINUTES, 10 MINUTES)
    >     ON o.buyer_id = b.id
    > FULL OUTER JOIN streamtostream_stream_product_group_intake p
    >     WITHIN (15 MINUTES, 30 MINUTES)
    >     ON o.product_group_id = p.id
    > EMIT CHANGES;
    > ```

- Pull request to JOIN stream to **check result**.
    ```sql
    SELECT * FROM streamtostream_stream_join EMIT CHANGES;
    ```

- Create **dummy data** for **inside window BEFORE**.
    > ```sql
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-13 09:25:00');
    > INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES ('5', 'Clothing5', '1', '2024-05-13 09:15:00');
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '4', '5', '2024-05-13 09:30:00');
    > ```

- **Result:** The `buyer` record matches because it arrived `5 minutes before` the order, and the `product_group` record matches because it arrived `15 minutes before` the order.
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |5                    |null                 |null                 |null                 |null                 |null                 |null                 |null                 |null                 |5                    |Clothing5            |2024-05-13T09:15:00.0|
    > |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |00                   |
    > |5                    |10                   |Gizmo                |2024-05-13T09:30:00.0|4                    |null                 |null                 |null                 |5                    |5                    |Clothing5            |2024-05-13T09:15:00.0|
    > |                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |00                   |
    > |5                    |10                   |Gizmo                |2024-05-13T09:30:00.0|4                    |4                    |Charlie4             |2024-05-13T09:25:00.0|5                    |5                    |Clothing5            |2024-05-13T09:15:00.0|
    > |                     |                     |                     |00                   |                     |                     |                     |00                   |                     |                     |                     |00                   |
    > ```

- Create **dummy data** for **outside window BEFORE**.
    > ```sql
    > INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES ('6', 'Clothing6', '1', '2024-05-13 09:20:00');
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('11', 'Gizmo', '2', '4', '6', '2024-05-13 09:31:00');
    > ```

- **Result:** The `buyer` record NOT matches because it arrived `6 minutes before` the order, and the `product_group` record matches because it arrived `11 minutes before` the order.
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |6                    |null                 |null                 |null                 |null                 |null                 |null                 |null                 |null                 |6                    |Clothing6            |2024-05-13T09:20:00.0|
    > |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |00                   |
    > |6                    |11                   |Gizmo                |2024-05-13T09:31:00.0|4                    |null                 |null                 |null                 |6                    |6                    |Clothing6            |2024-05-13T09:20:00.0|
    > |                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |00                   |
    > ```

- Create **dummy data** for **outside window AFTER**.
```sql
INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('12', 'Gizmo', '2', '4', '6', '2024-05-13 09:14:00');
```

- **Result:** The `buyer` record NOT matches because it arrived `11 minutes after` the order, and the `product_group` record matches because it arrived `6 minutes after` the order.
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |6                    |12                   |Gizmo                |2024-05-13T09:14:00.0|4                    |null                 |null                 |null                 |6                    |6                    |Clothing6            |2024-05-13T09:20:00.0|
    > |                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |00                   |
    > ```