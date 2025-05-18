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

- **Result:** Since the event happened in Stream C `(product_group)`, it appears in the results for Stream C even though there's no matching data from Stream A `(order)` or Stream B `(buyer)`.
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

- **Result:** If an event happens in Stream B (`buyer`), there's no output because it doesn't find a match with Stream A (`order`). So, it won't continue to Stream C (`product_group`) or Stream D (`supplier`), even if there are matches in those streams for Stream A.
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
- This document provides `INSERT` statements for demonstrating the backward part of ksqlDB stream-stream join windows. We will show scenarios where events from one stream arrive _before_ the event from the "primary" stream, and how they either join (if within the `WITHIN` window) or do not join (if outside the `WITHIN` window).
- **Base Timestamp:** `2024-05-19 12:00:00 PM`
- **Join Windows:**
    * **Order (A) to Buyer (B):** `WITHIN (5 MINUTES, 10 MINUTES)`
        * When an Order event arrives (A), it will look for Buyer events (B) between 5 minutes _before_ A's timestamp and 10 minutes _after_ A's timestamp.
    * **Order (A) to Product Group (C):** `WITHIN (15 MINUTES, 30 MINUTES)`
        * When an Order event arrives (A), it will look for Product Group events (C) between 15 minutes _before_ A's timestamp and 30 minutes _after_ A's timestamp.

---
### Setup
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
---

### Scenario 1 (WITHIN): Order (Stream A)

In this scenario, we insert events from the Buyer (Stream B) and Product Group (Stream C) streams first, with timestamps _before_ the Order event's timestamp, and _within_ the backward part of the `WITHIN` windows relative to the Order event.

* **Buyer B event timestamp:** `11:58:00 AM` (relative to A at 12:00:00 PM, this is 2 minutes before - **within** A-B backward window of 5 mins)
* **Product Group C event timestamp:** `11:50:00 AM` (relative to A at 12:00:00 PM, this is 10 minutes before - **within** A-C backward window of 15 mins)
* **Order A event timestamp:** `12:00:00 PM`
* **Expected:** When Order arrives at 12:00:00 PM, it should join with both Buyer (at 11:58:00 AM) and Product Group 8 (at 11:50:00 AM) because their timestamps are within the backward part of the respective join windows relative to Order's timestamp.

```sql
-- Insert Buyer and Product Group events first
INSERT INTO `buyer` (id, name, create_date) VALUES (4, 'Buyer Four', '2024-05-19 11:58:00');
INSERT INTO `product_group` (id, name, create_date) VALUES (5, 'Software', '2024-05-19 11:50:00');

-- Then insert the Order event (the primary event in this scenario)
INSERT INTO `order` (id, product, amount, create_date, buyer_id, product_group_id) VALUES (10, 'Monitor', 1, '2024-05-19 12:00:00', 4, 5);
```
- **Result:**
```
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|null                 |null                 |null                 |null                 |null                 |4                    |Buyer Four           |2024-05-19T11:58:00.0|null                 |null                 |null                 |null                 |
|                     |                     |                     |                     |                     |                     |                     |00                   |                     |                     |                     |                     |
|5                    |null                 |null                 |null                 |null                 |null                 |null                 |null                 |null                 |5                    |Software             |2024-05-19T11:50:00.0|
|                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |00                   |
|5                    |10                   |Monitor              |2024-05-19T12:00:00.0|4                    |4                    |Buyer Four           |2024-05-19T11:58:00.0|5                    |5                    |Software             |2024-05-19T11:50:00.0|
|                     |                     |                     |00                   |                     |                     |                     |00                   |                     |                     |                     |00                   |
```

---

### Scenario 1 (WITHOUT): Order (Stream A)

In this scenario, we insert events from the Buyer (Stream B) and Product Group (Stream C) streams first, with timestamps _before_ the Order event's timestamp, but _outside_ the backward part of the `WITHIN` windows relative to the Order event.

* **Buyer B event timestamp:** `11:54:00 AM` (relative to A at 12:00:00 PM, this is 6 minutes before - **outside** A-B backward window of 5 mins)
* **Product Group C event timestamp:** `11:44:00 AM` (relative to A at 12:00:00 PM, this is 16 minutes before - **outside** A-C backward window of 15 mins)
* **Order A event timestamp:** `12:00:00 PM`
* **Expected:** When Order arrives at 12:00:00 PM, it should **NOT** join with Buyer (at 11:54:00 AM) or Product Group (at 11:44:00 AM) because their timestamps are outside the backward part of the respective join windows relative to Order's timestamp. Order should appear in the join stream with nulls for buyer and product group details.

```sql
-- Insert Buyer and Product Group events first
INSERT INTO `buyer` (id, name, create_date) VALUES (5, 'Buyer Seven', '2024-05-19 11:54:00');
INSERT INTO `product_group` (id, name, create_date) VALUES (6, 'Office Supplies', '2024-05-19 11:44:00');

-- Then insert the Order event (the primary event in this scenario)
INSERT INTO `order` (id, product, amount, create_date, buyer_id, product_group_id) VALUES (11, 'Stapler', 1, '2024-05-19 12:00:00', 5, 6);
```
- **Result:**
```
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|null                 |null                 |null                 |null                 |null                 |5                    |Buyer Seven          |2024-05-19T11:54:00.0|null                 |null                 |null                 |null                 |
|                     |                     |                     |                     |                     |                     |                     |00                   |                     |                     |                     |                     |
|6                    |null                 |null                 |null                 |null                 |null                 |null                 |null                 |null                 |6                    |Office Supplies      |2024-05-19T11:44:00.0|
|                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |00                   |
|6                    |11                   |Stapler              |2024-05-19T12:00:00.0|5                    |null                 |null                 |null                 |6                    |null                 |null                 |null                 |
|                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |                     |
```

---
### Scenario 2 (WITHIN): Buyer (Stream B)
In this scenario, we insert events from the Order (Stream A) and Product Group (Stream C - which joins with A) streams first, with timestamps that would allow a join when the Buyer event arrives later.

* **Order A event timestamp:** `11:55:00 AM` (relative to B at 12:00:00 PM, this is 5 minutes before - **within** A-B backward window of 10 mins)
* **Product Group C event timestamp:** `12:10:00 PM` (relative to A at 11:55:00 AM, this is 15 minutes after - **within** A-C forward window of 30 mins)
* **Buyer B event timestamp:** `12:00:00 PM`
* **Expected:** When Buyer arrives at 12:00:00 PM, it should join with Order (at 11:55:00 AM) because Order's timestamp is within the backward part of the A-B join window relative to Buyer's timestamp. The join with Product Group will depend on whether Product Group's timestamp is within the A-C window relative to Order's timestamp.

```sql
-- Insert Order and Product Group events first
INSERT INTO `order` (id, product, amount, create_date, buyer_id, product_group_id) VALUES (12, 'Webcam', 1, '2024-05-19 11:55:00', 6, 7);
INSERT INTO `product_group` (id, name, create_date) VALUES (7, 'Peripherals', '2024-05-19 12:10:00');

-- Then insert the Buyer event (the primary event in this scenario)
INSERT INTO `buyer` (id, name, create_date) VALUES (6, 'Buyer Five', '2024-05-19 12:00:00');
```

- **Result:**
```
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|7                    |12                   |Webcam               |2024-05-19T11:55:00.0|6                    |null                 |null                 |null                 |7                    |null                 |null                 |null                 |
|                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |                     |
|7                    |12                   |Webcam               |2024-05-19T11:55:00.0|6                    |null                 |null                 |null                 |7                    |7                    |Peripherals          |2024-05-19T12:10:00.0|
|                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |00                   |
|7                    |12                   |Webcam               |2024-05-19T11:55:00.0|6                    |6                    |Buyer Five           |2024-05-19T12:00:00.0|7                    |7                    |Peripherals          |2024-05-19T12:10:00.0|
|                     |                     |                     |00                   |                     |                     |                     |00                   |                     |                     |                     |00                   |
```

---
### Scenario 2 (WITHOUT): Buyer (Stream B) 
In this scenario, we insert an Order event (Stream A) first, with a timestamp _before_ the Buyer event's timestamp, but _outside_ the backward part of the `WITHIN` window relative to the Buyer event.

* **Order A event timestamp:** `11:49:00 AM` (relative to B at 12:00:00 PM, this is 11 minutes before - **outside** A-B backward window of 10 mins)
* **Product Group C event timestamp:** (relative to A at 11:49:00 AM, let's put it outside A-C window too) e.g., `11:30:00 AM` (11:49 - 19 mins - outside A-C backward window of 15 mins)
* **Buyer B event timestamp:** `12:00:00 PM`
* **Expected:** When Buyer arrives at 12:00:00 PM, it should **NOT** join with Order (at 11:49:00 AM) because Order's timestamp is outside the backward part of the A-B join window relative to Buyer's timestamp. Buyer should appear in the join stream with nulls for order details.

```sql
-- Insert Order and Product Group events first
INSERT INTO `order` (id, product, amount, create_date, buyer_id, product_group_id) VALUES (13, 'Mousepad', 1, '2024-05-19 11:49:00', 7, 8);
INSERT INTO `product_group` (id, name, create_date) VALUES (8, 'Desk Accessories', '2024-05-19 11:30:00');

-- Then insert the Buyer event (the primary event in this scenario)
INSERT INTO `buyer` (id, name, create_date) VALUES (7, 'Buyer Eight', '2024-05-19 12:00:00');
```

- **Result:**
```
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
|8                    |13                   |Mousepad             |2024-05-19T11:49:00.0|7                    |null                 |null                 |null                 |8                    |null                 |null                 |null                 |
|                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |                     |
|8                    |null                 |null                 |null                 |null                 |null                 |null                 |null                 |null                 |8                    |Desk Accessories     |2024-05-19T11:30:00.0|
|                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |00                   |
|null                 |null                 |null                 |null                 |null                 |7                    |Buyer Eight          |2024-05-19T12:00:00.0|null                 |null                 |null                 |null                 |
|                     |                     |                     |                     |                     |                     |                     |00                   |                     |                     |                     |                     |
```

---
### Scenario 3 (WITHIN): Product Group (Stream C)
In this scenario, we insert events from the Order (Stream A) and Buyer (Stream B - which joins with A) streams first, with timestamps that would allow a join when the Product Group event arrives later.

* Order A event timestamp: 11:45:00 AM (relative to C at 12:00:00 PM, this is 15 minutes before - **within** A-C backward window of 30 mins)
* Buyer B event timestamp: 11:50:00 AM (relative to A at 11:45:00 AM, this is 5 minutes after - **within** A-B forward window of 10 mins)
* Product Group C event timestamp: 12:00:00 PM
* **Expected:** When Product Group 10 arrives at 12:00:00 PM, it should join with Order 107 (at 11:45:00 AM) because Order 107's timestamp is within the backward part of the A-C join window relative to Product Group 10's timestamp. The join with Buyer 6 will depend on whether Buyer 6's timestamp is within the A-B window relative to Order 107's timestamp.

`-- Insert Order and Buyer events first
INSERT INTO streamtostream_stream_order_intake (id, product, create_date, buyer_id, product_group_id) VALUES (107, 'Printer', '2024-05-19T11:45:00Z', 6, 10) AT TIMESTAMPS 1716085500000;
INSERT INTO streamtostream_stream_buyer_intake (id, name, create_date) VALUES (6, 'Buyer Six', '2024-05-19T11:50:00Z') AT TIMESTAMPS 1716085800000;

-- Then insert the Product Group event (the primary event in this scenario)
INSERT INTO streamtostream_stream_product_group_intake (id, name, create_date) VALUES (10, 'Office', '2024-05-19T12:00:00Z') AT TIMESTAMPS 1716086400000;
`

### **Scenario 3 (WITHOUT): Product Group (Stream C) is primary, arrives _last_, finds events _outside_ backward window**

In this scenario, we insert an Order event (Stream A) first, with a timestamp _before_ the Product Group event's timestamp, but _outside_ the backward part of the `WITHIN` window relative to the Product Group event.

* Order A event timestamp: 11:29:00 AM (relative to C at 12:00:00 PM, this is 31 minutes before - **outside** A-C backward window of 30 mins)
* Buyer B event timestamp: (relative to A at 11:29:00 AM, let's put it outside A-B window too) e.g., 11:20:00 AM (11:29 - 9 mins - outside A-B backward window of 5 mins)
* Product Group C event timestamp: 12:00:00 PM
* **Expected:** When Product Group 13 arrives at 12:00:00 PM, it should **not** join with Order 110 (at 11:29:00 AM) because Order 110's timestamp is outside the backward part of the A-C join window relative to Product Group 13's timestamp. Product Group 13 should appear in the join stream with nulls for order details.

`-- Insert Order and Buyer events first
INSERT INTO streamtostream_stream_order_intake (id, product, create_date, buyer_id, product_group_id) VALUES (110, 'Shredder', '2024-05-19T11:29:00Z', 9, 13) AT TIMESTAMPS 1716084540000;
INSERT INTO streamtostream_stream_buyer_intake (id, name, create_date) VALUES (9, 'Buyer Nine', '2024-05-19T11:20:00Z') AT TIMESTAMPS 1716084000000;

-- Then insert the Product Group event (the primary event in this scenario)
INSERT INTO streamtostream_stream_product_group_intake (id, name, create_date) VALUES (13, 'Paper Handling', '2024-05-19T12:00:00Z') AT TIMESTAMPS 1716086400000;
`

Remember to run the `SELECT * FROM streamtostream_stream_join EMIT CHANGES;` query in your ksqlDB environment to observe the results of these inserts in the join stream. You should see the join output appear shortly after you insert the "last" event in each scenario, showing either a successful join (WITHIN) or no join (WITHOUT).