# Setup
- Create docker network via `docker network create global-net`
- Create all Kafka connectors in `connector` folder.
- Create all Ksql streams/tables in `ksql` folder via `./tools/ksqldb_connect.sh`.
- Table in `MySQL DB` will be used as dummy data.

# Supported Join Types
- ksqlDB supports these stream-stream joins (all need a `WITHIN` time window).
    - `FULL OUTER JOIN`
    - `INNER JOIN`
    - `LEFT JOIN` / `LEFT OUTER JOIN`
    - `RIGHT JOIN` / `RIGHT OUTER JOIN`

# Reset
To reset for practice, follow these steps.
- Ensure **remove dummy data** to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > DELETE FROM `supplier` WHERE id > 3;
    > ```

- Ensure **recreate streams** to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_supplier_intake;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

# Multi-Join Flow
In ksqlDB, the order of streams in a multi-stage join (`(((A JOIN B) JOIN C) JOIN D)`).

- Create **JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join WITH 
    > (KAFKA_TOPIC='streamtostream_stream_join', VALUE_FORMAT='AVRO') AS
    > SELECT 
    >     o.id AS order_id,
    >     o.product AS product,
    >     o.create_date AS o_create_date,
    >     
    >     o.buyer_id AS o_buyer_id,
    >     b.id AS b_buyer_id,
    >     b.name AS buyer_name,
    >     b.create_date AS b_create_date,
    >     
    >     o.product_group_id AS o_product_group_id,
    >     p.id AS p_product_group_id,
    >     p.name AS product_group_name,
    >     p.create_date AS p_create_date,
    > 
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

---
### Event from Stream C
- Insert **dummy data**.
    > ```sql
    > INSERT INTO `supplier` (`id`, `name`, `create_date`) VALUES ('4', 'TopSupplies4', '2024-05-13 09:30:00');
    > INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES ('5', 'Clothing5', '4', '2024-05-13 09:30:00');
    > ```

- **Result:** Since the event happened in Stream C `(product_group)`, it appears in the results for Stream C even though there's no matching data from Stream A `(order)` or Stream B `(buyer)`.
    > ```
    > +-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    > |O_SUPPLIER_|ORDER_ID   |PRODUCT    |O_CREATE_DA|O_BUYER_ID |B_BUYER_ID |BUYER_NAME |B_CREATE_DA|O_PRODUCT_G|P_PRODUCT_G|PRODUCT_GRO|P_CREATE_DA|S_SUPPLIER_|SUPPLIER_NA|S_CREATE_DA|
    > |ID         |           |           |TE         |           |           |           |TE         |ROUP_ID    |ROUP_ID    |UP_NAME    |TE         |ID         |ME         |TE         |
    > +-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
    > |4          |null       |null       |null       |null       |null       |null       |null       |null       |5          |Clothing5  |2024-05-13T|4          |TopSupplies|2024-05-13T|
    > |           |           |           |           |           |           |           |           |           |           |           |09:30:00.00|           |4          |09:30:00.00|
    > |           |           |           |           |           |           |           |           |           |           |           |0          |           |           |0          |
    > ```

---
### Event from Stream B
- Insert **dummy data**.
```sql
INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '3', '6', '2024-05-20 09:30:00');

INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES ('6', 'Clothing6', '6', '2024-05-20 09:30:00');

INSERT INTO `supplier` (`id`, `name`, `create_date`) VALUES ('6', 'TopSupplies6', '2024-05-20 09:30:00');

INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('5', 'Buyer5', '2024-05-20 09:30:00');
```

- **Result:** No join result as no join result from `(A JOIN B)`.


# Cascading Streams
- This is to compare 2 methods:
    - **Cascading Join:** `2+1 Structure`
    - **3-Streams Join:** `((A JOIN B) JOIN C)` directly

- Create **1st JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join_order_buyer WITH
    > (KAFKA_TOPIC='streamtostream_stream_join_order_buyer', VALUE_FORMAT='AVRO') AS
    > SELECT
    >     ROWKEY AS join_key,
    > 
    >     o.id AS order_id,
    >     o.product,
    >     o.product_group_id,
    >     o.create_date AS o_create_date,
    >     o.buyer_id AS o_buyer_id,
    > 
    >     b.id AS b_buyer_id,
    >     b.name AS buyer_name,
    >     b.create_date AS b_create_date
    > FROM streamtostream_stream_order_intake o
    > FULL OUTER JOIN streamtostream_stream_buyer_intake b
    >     WITHIN (5 MINUTES, 10 MINUTES)
    >     ON o.buyer_id = b.id
    > EMIT CHANGES;
    > ```

- Create **2nd JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join_order_buyer_pg WITH
    > (KAFKA_TOPIC='streamtostream_stream_join_order_buyer_pg', VALUE_FORMAT='AVRO') AS
    > SELECT
    >     ROWKEY AS join_key,
    > 
    >     FROM_UNIXTIME(a.ROWTIME) AS a_row_time,
    >     FROM_UNIXTIME(p.ROWTIME) AS p_row_time,
    > 
    >     a.order_id,
    >     a.product,
    >     a.product_group_id,
    >     a.o_create_date,
    >     a.o_buyer_id,
    >     a.b_buyer_id,
    >     a.buyer_name,
    >     a.b_create_date,
    > 
    >     p.id AS pg_id,
    >     p.name AS pg_name,
    >     p.create_date AS pg_create_date
    > FROM streamtostream_stream_join_order_buyer a
    > FULL OUTER JOIN streamtostream_stream_product_group_intake p
    >     WITHIN (15 MINUTES, 30 MINUTES)
    >     ON a.product_group_id = p.id
    > EMIT CHANGES;
    > ```

---
### `Buyer` Event
- Insert **dummy data**.
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '1', '4', '5', '2024-05-20 09:30:00');
    > 
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-20 09:40:00');
    > ```

- **Result:** 
    - Joined result as `stream buyer` event is 10 mins after `stream order` event.
    - Joined stream's **ROWTIME** is `2024-05-20T09:40:00` (MAX of A & B's timestamp).
    > ```
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |ROW_TIME          |A_ROW_TIME        |P_ROW_TIME        |ORDER_ID          |O_BUYER_ID        |B_BUYER_ID        |B_CREATE_DATE     |PG_ID             |PG_NAME           |PG_CREATE_DATE    |
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |2024-05-20T09:40:0|2024-05-20T09:40:0|null              |10                |4                 |4                 |2024-05-20T09:40:0|null              |null              |null              |
    > |0.000             |0.000             |                  |                  |                  |                  |0.000             |                  |                  |                  |
    > ```

---
### `Order` Event
- Insert **dummy data**.
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('11', 'Gizmo', '1', '4', '5', '2024-05-20 09:45:00');
    > ```

- **Result:**: 
    - Joined result as `stream order` event is 5 mins after `stream buyer` event.
    - Joined stream's **ROWTIME** is `2024-05-20T09:45:00` (MAX of A & B's timestamp).
    > ```
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |ROW_TIME          |JOIN_KEY          |ORDER_ID          |PRODUCT           |PRODUCT_GROUP_ID  |O_CREATE_DATE     |O_BUYER_ID        |B_BUYER_ID        |BUYER_NAME        |B_CREATE_DATE     |
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |2024-05-20T09:45:0|4                 |11                |Gizmo             |5                 |2024-05-20T09:45:0|4                 |4                 |Charlie4          |2024-05-20T09:40:0|
    > |0.000             |                  |                  |                  |                  |0.000             |                  |                  |                  |0.000             |
    > ```

---
### `Product Group` Event
- Insert **dummy data**.
    > ```sql
    > INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES ('5', 'Clothing5', '1', '2024-05-20 10:10:00');
    > ```

- **Result:** Both events are joined, as both timestamp `09:40` and `09:45` is in `product group` window `10:10 - 30mins = 09:40` to `10:10 + 15mins = 10:25`.
    > ```
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |ROW_TIME          |A_ROW_TIME        |P_ROW_TIME        |ORDER_ID          |O_BUYER_ID        |B_BUYER_ID        |B_CREATE_DATE     |PG_ID             |PG_NAME           |PG_CREATE_DATE    |
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |2024-05-20T10:10:0|2024-05-20T09:40:0|2024-05-20T10:10:0|10                |4                 |4                 |2024-05-20T09:40:0|5                 |Clothing5         |2024-05-20T10:10:0|
    > |0.000             |0.000             |0.000             |                  |                  |                  |0.000             |                  |                  |0.000             |
    > |2024-05-20T10:10:0|2024-05-20T09:45:0|2024-05-20T10:10:0|11                |4                 |4                 |2024-05-20T09:40:0|5                 |Clothing5         |2024-05-20T10:10:0|
    > |0.000             |0.000             |0.000             |                  |                  |                  |0.000             |                  |                  |0.000             |
    > ```

- Insert **dummy data**.
    > ```sql
    > UPDATE `product_group` SET `create_date` = '2024-05-20 10:15:00' WHERE `product_group`.`id` = 5;
    > ```

- **Result:** Only `9:45` events are joined, as timestamp `09:45` is in `product group` window `10:15 - 30mins = 09:45` to `10:15 + 15mins = 10:30`.
    > ```
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |ROW_TIME          |A_ROW_TIME        |P_ROW_TIME        |ORDER_ID          |O_BUYER_ID        |B_BUYER_ID        |B_CREATE_DATE     |PG_ID             |PG_NAME           |PG_CREATE_DATE    |
    > +------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
    > |2024-05-20T10:15:0|2024-05-20T09:45:0|2024-05-20T10:15:0|11                |4                 |4                 |2024-05-20T09:40:0|5                 |Clothing5         |2024-05-20T10:15:0|
    > |0.000             |0.000             |0.000             |                  |                  |                  |0.000             |                  |                  |0.000             |
    > ```

# Window & Grace Period
- **Window**
    - Window of **stream A event** = `timestamp - 5mins` to `timestamp + 10mins`
    - Window of **stream B event** = `timestamp - 10mins` to `timestamp + 5mins`

- **Grace Period**
    - Grace period of **stream A event** = window end `(timestamp + 10mins)` + grace period `(2 mins)`
    - Grace period of **stream B event** = window end `(timestamp + 5mins)` + grace period `(2 mins)`

- **ROWTIME of joined stream:** `MAX(stream A timestamp, stream B timestamp)`

- Create **stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join_order_buyer WITH
    > (KAFKA_TOPIC='streamtostream_stream_join_order_buyer', VALUE_FORMAT='AVRO') AS
    > SELECT
    >     ROWKEY AS join_key,
    >     FROM_UNIXTIME(o.ROWTIME) AS o_rowtime,
    >     FROM_UNIXTIME(b.ROWTIME) AS b_rowtime,
    > 
    >     o.id AS order_id,
    >     o.product,
    >     o.product_group_id,
    >     o.create_date AS o_create_date,
    >     o.buyer_id AS o_buyer_id,
    > 
    >     b.id AS b_buyer_id,
    >     b.name AS buyer_name,
    >     b.create_date AS b_create_date
    > FROM streamtostream_stream_order_intake o
    > FULL OUTER JOIN streamtostream_stream_buyer_intake b
    >     WITHIN (5 MINUTES, 10 MINUTES) GRACE PERIOD 2 MINUTES
    >     ON o.buyer_id = b.id
    > EMIT CHANGES;
    > ```

---
### Window
- Create **dummy data**.
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '4', '3', '2024-05-20 10:30:00');
    > ```

- No join result as `buyer` event is 11mins after `order` event.
    > ```sql
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-20 10:41:00');
    > ```

- **Result:** No join result as `buyer` event.
    - Window of **order** `(10:30)` = `10:25` to `10:40`
    - Window of **buyer** `(10:41)` = `10:31` to `10:46`
    > ```sql
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-20 10:41:00');
    > ```

- **Result:** Has join result
    - Window of **order** `(10:30)` = `10:25` to `10:40`
    - Window of **buyer** `(10:40)` = `10:30` to `10:45`
    > ```sql
    > UPDATE `buyer` SET `create_date` = '2024-05-20 10:40:00' WHERE `buyer`.`id` = 4;
    > ```

- **Result:** Has join result
    - Window of **order** `(10:30)` = `10:25` to `10:40`
    - Window of **buyer** `(10:30)` = `10:20` to `10:35`
    > ```sql
    > UPDATE `buyer` SET `create_date` = '2024-05-20 10:30:00' WHERE `buyer`.`id` = 4;
    > ```

- **Result:** Has join result
    - Window of **order** `(10:30)` = `10:25` to `10:40`
    - Window of **buyer** `(10:25)` = `10:15` to `10:30`
    > ```sql
    > UPDATE `buyer` SET `create_date` = '2024-05-20 10:25:00' WHERE `buyer`.`id` = 4;
    > ```

- **Result:** Null result from `order`
    - Window of **order** `(10:30)` = `10:25` to `10:40`
    - Window of **buyer** `(10:24)` = `10:14` to `10:29`
    > ```sql
    > UPDATE `buyer` SET `create_date` = '2024-05-20 10:24:00' WHERE `buyer`.`id` = 4;
    > ```

### Grace Period
- Create **dummy data**.
```sql

```