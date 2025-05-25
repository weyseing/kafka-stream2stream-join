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

# Multi-Stage Stream Joins: 2+1 Stream
This section details a ksqlDB multi-stage join where an initial stream `(Orders joined with Buyers)` is subsequently joined with a third stream `(Product Group)`, highlighting the impact of event timing and join windows.

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
    > DROP STREAM streamtostream_stream_join_order_buyer_pg;
    > DROP STREAM streamtostream_stream_join_order_buyer;
    > DROP STREAM streamtostream_stream_supplier_intake;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Create **1st JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join_order_buyer 
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
    > CREATE STREAM streamtostream_stream_join_order_buyer_pg 
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

- Pull request to JOIN stream to **check result**.
    > ```sql
    > -- 1st joined stream
    > SELECT FROM_UNIXTIME(ROWTIME) as row_time, * FROM streamtostream_stream_join_order_buyer EMIT CHANGES;
    >     
    > -- 2nd joined stream
    > SELECT FROM_UNIXTIME(ROWTIME) as row_time, * FROM streamtostream_stream_join_order_buyer_pg EMIT CHANGES;
    > ```

---
### Stage 1 Join: `Order` Event Arrives
> ```sql
> -- Buyer exists BEFORE order
> INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES
>   (4, 'Alice', '2024-05-20 09:56:00'); -- 4 min before order
> 
> -- Order event
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES
>   (10, 'Widget', 1, 4, 5, '2024-05-20 10:00:00');
> ```

- **Result:** The `FULL OUTER JOIN` produces two records.
    1. The first (ROWTIME `09:56:00`) occurs when the `Buyer` event ('Alice', id 4) arrives. At this point, no `Order` with `buyer_id = 4` has arrived within the window `Buyer.rowtime` expects for an `Order` (i.e., `Order.rowtime` between `[Buyer_timestamp - 10min, Buyer_timestamp + 5min]`). Thus, the Buyer event is output with `null` Order details.
    2. The second (ROWTIME `10:00:00`) occurs when the `Order` event (id 10, `buyer_id = 4`) arrives. It successfully joins with the 'Alice' `Buyer` event because `Buyer.id` matches `Order.buyer_id`, and the `Buyer`'s timestamp (`09:56:00`) is within the `Order`'s required window for a `Buyer` (i.e., `Buyer.rowtime` between `[Order_timestamp - 5min, Order_timestamp + 10min]`, which is `[09:55:00, 10:10:00]`).
    > ```sql
    > +--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+
    > |ROW_TIME                  |JOIN_KEY                  |ORDER_ID                  |PRODUCT                   |PRODUCT_GROUP_ID          |O_CREATE_DATE             |O_BUYER_ID                |B_BUYER_ID                |BUYER_NAME                |B_CREATE_DATE             |
    > +--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+
    > |2024-05-20T09:56:00.000   |4                         |null                      |null                      |null                      |null                      |null                      |4                         |Alice                     |2024-05-20T09:56:00.000   |
    > |2024-05-20T10:00:00.000   |4                         |10                        |Widget                    |5                         |2024-05-20T10:00:00.000   |4                         |4                         |Alice                     |2024-05-20T09:56:00.000   |
    > ```

---
### Stage 1 Join: `Buyer` Event Arrives
```sql
-- Order exists BEFORE buyer
INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES
  (11, 'Thingy', 1, 5, 5, '2024-05-20 10:20:00');

-- Buyer event inserted later
INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES
  (5, 'Bob', '2024-05-20 10:25:00'); -- 5 min after order
```

- **Result:** The `FULL OUTER JOIN` produces two records.
    1. The first (ROWTIME `10:20:00`) occurs when the `Order` event (id 11, `buyer_id = 5`) arrives. At this point, no `Buyer` with `id = 5` has arrived within the window `Order.rowtime` expects for a `Buyer` (i.e., `Buyer.rowtime` between `[Order_timestamp - 5min, Order_timestamp + 10min]`). Thus, the `Order` event is output with `null` Buyer details.
    2. The second (ROWTIME `10:25:00`) occurs when the `Buyer` event ('Bob', id 5) arrives. It successfully joins with the `Order` event (id 11) because `Order.buyer_id` matches `Buyer.id`, and the `Order`'s timestamp (`10:20:00`) is within the `Buyer`'s required window for an `Order` (i.e., `Order.rowtime` between `[Buyer_timestamp - 10min, Buyer_timestamp + 5min]`, which is `[10:15:00, 10:30:00]`).
    
    > ```sql
    > +--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+
    > |ROW_TIME                  |JOIN_KEY                  |ORDER_ID                  |PRODUCT                   |PRODUCT_GROUP_ID          |O_CREATE_DATE             |O_BUYER_ID                |B_BUYER_ID                |BUYER_NAME                |B_CREATE_DATE             |
    > +--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+--------------------------+
    > |2024-05-20T10:20:00.000   |5                         |11                        |Thingy                    |5                         |2024-05-20T10:20:00.000   |5                         |null                      |null                      |null                      |
    > |2024-05-20T10:25:00.000   |5                         |11                        |Thingy                    |5                         |2024-05-20T10:20:00.000   |5                         |5                         |Bob                       |2024-05-20T10:25:00.000   |
    > ```

---
### Stage 2 Join: Border Case `(AFTER at 30-minute Window Edge)`
```sql
-- Product Group event exactly at window edge (exactly 30 min after 10:25:00)
INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES
  (5, 'Electronics', 3, '2024-05-20 10:55:00'); 
```

- **Result:** The output shows a single, successfully joined record. The `ROWTIME` of this final joined event is `2024-05-20T10:55:00.000`, aligned with the arrival of the triggering `Product Group` event.
    - `A_ROW_TIME` (`10:25:00`) timestamp of the pre-existing record in `streamtostream_stream_join_order_buyer` (Order 11 'Thingy', Buyer 'Bob').
    - `P_ROW_TIME` (`10:55:00`) timestamp of the incoming `Product Group` event (id 5, 'Electronics').
The join is successful because their `product_group_id` (5) matches, and `A_ROW_TIME` (`10:25:00`) is exactly 30 minutes before `P_ROW_TIME` (`10:55:00`). This satisfies the `WITHIN (15 MINUTES, 30 MINUTES)` condition at its `t_a = t_p - 30 MINUTES` boundary (where `t_a` is `A_ROW_TIME` and `t_p` is `P_ROW_TIME`).

    > ```sql
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |ROW_TIME        |JOIN_KEY        |A_ROW_TIME      |P_ROW_TIME      |ORDER_ID        |PRODUCT         |PRODUCT_GROUP_ID|O_CREATE_DATE   |O_BUYER_ID      |B_BUYER_ID      |BUYER_NAME      |B_CREATE_DATE   |PG_ID           |PG_NAME         |PG_CREATE_DATE  |
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |2024-05-20T10:55|5               |2024-05-20T10:25|2024-05-20T10:55|11              |Thingy          |5               |2024-05-20T10:20|5               |5               |Bob             |2024-05-20T10:25|5               |Electronics     |2024-05-20T10:55|
    > |:00.000         |                |:00.000         |:00.000         |                |                |                |:00.000         |                |                |                |:00.000         |                |                |:00.000         |
    > ```

---
### Stage 2 Join: Border Case `(BEFORE at 15-minute Window Edge)`
```sql
-- First create a new order-buyer record with different product_group_id 
INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES
  (12, 'Tablet', 1, 5, 6, '2024-05-20 10:25:00'); -- Establishes A_ROW_TIME = 10:25:00
  
-- Product Group event inserted 15 minutes BEFORE A_ROW_TIME
INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES
  (6, 'Electronics', 2, '2024-05-20 10:10:00');  -- Tests A_ROW_TIME = P_ROWTIME + 15min boundary
```

- **Result:** The output shows a single, successfully joined record. The `ROWTIME` of this final joined event is `2024-05-20T10:25:00.000` (MAX of `A_ROW_TIME` (`10:25:00`) and `P_ROW_TIME` (`10:10:00`)).
    - `A_ROW_TIME` (`10:25:00`) from the first joined stream (Order 12 'Tablet', Buyer 'Bob', `product_group_id = 6`).
    - `P_ROW_TIME` (`10:10:00`) from the incoming `Product Group` event (id 6, 'Electronics').
The join is successful because `product_group_id` (6) matches, and `A_ROW_TIME` (`10:25:00`) equals `P_ROWTIME + 15 minutes` (`10:10:00 + 15min = 10:25:00`). This hits the boundary condition where the `Order-Buyer` event is 15 minutes after the `Product Group` event, at the edge of the valid join window `[09:40:00, 10:25:00]`.

    > ```sql
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |ROW_TIME        |JOIN_KEY        |A_ROW_TIME      |P_ROW_TIME      |ORDER_ID        |PRODUCT         |PRODUCT_GROUP_ID|O_CREATE_DATE   |O_BUYER_ID      |B_BUYER_ID      |BUYER_NAME      |B_CREATE_DATE   |PG_ID           |PG_NAME         |PG_CREATE_DATE  |
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |2024-05-20T10:25|6               |2024-05-20T10:25|2024-05-20T10:10|12              |Tablet          |6               |2024-05-20T10:25|5               |5               |Bob             |2024-05-20T10:25|6               |Electronics     |2024-05-20T10:10|
    > |:00.000         |                |:00.000         |:00.000         |                |                |                |:00.000         |                |                |                |:00.000         |                |                |:00.000         |
    > ```

---
### Stage 2 Join: Excluded Case `(Outside the Window)`
```sql
-- First create a new order-buyer record with different product_group_id
INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES
  (13, 'Gadget', 1, 5, 7, '2024-05-20 10:20:00');
-- after join buyer (ID=5), timestamp = '2024-05-20 10:25:00'
  
-- Then insert product group outside the window (31+ min after the joined stream time)
INSERT INTO `product_group` (`id`, `name`, `supplier_id`, `create_date`) VALUES
  (7, 'Toys', 2, '2024-05-20 10:56:00');  -- 31 min after joined stream - just outside window
```

- **Result:** The `FULL OUTER JOIN` results in a single output record originating from the `Product Group` stream, as no matching record was found in the `streamtostream_stream_join_order_buyer` stream within the specified time window.
    - The `ROWTIME` of the output is `2024-05-20T10:56:00.000`, aligned with the `Product Group` event.
    - All fields from `streamtostream_stream_join_order_buyer` (like `A_ROW_TIME`, `ORDER_ID`, `BUYER_NAME`, etc.) are `null`.
    - Fields from the `Product Group` stream (`P_ROW_TIME` (`10:56:00`), `PG_ID = 7`) are present.
This happens because the `A_ROW_TIME` (`10:20:00`) of the potential matching record (Order 13) is outside the required window `[10:26:00, 11:11:00]` relative to the `P_ROW_TIME` (`10:56:00`).

    > ```sql
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |ROW_TIME        |JOIN_KEY        |A_ROW_TIME      |P_ROW_TIME      |ORDER_ID        |PRODUCT         |PRODUCT_GROUP_ID|O_CREATE_DATE   |O_BUYER_ID      |B_BUYER_ID      |BUYER_NAME      |B_CREATE_DATE   |PG_ID           |PG_NAME         |PG_CREATE_DATE  |
    > +----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    > |2024-05-20T10:25|7               |2024-05-20T10:25|null            |13              |Gadget          |7               |2024-05-20T10:20|5               |5               |Bob             |2024-05-20T10:25|null            |null            |null            |
    > |:00.000         |                |:00.000         |                |                |                |                |:00.000         |                |                |                |:00.000         |                |                |                |
    > |2024-05-20T10:56|7               |null            |2024-05-20T10:56|null            |null            |null            |null            |null            |null            |null            |null            |7               |Toys            |2024-05-20T10:56|
    > |:00.000         |                |                |:00.000         |                |                |                |                |                |                |                |                |                |                |:00.000         |
    > ```

# Grace Period
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
    > DROP STREAM streamtostream_stream_join_order_buyer_pg;
    > DROP STREAM streamtostream_stream_join_order_buyer;
    > DROP STREAM streamtostream_stream_supplier_intake;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Create **JOIN stream** below.
    > ```sql
    > CREATE STREAM streamtostream_stream_join_order_buyer
    > WITH (KAFKA_TOPIC='streamtostream_stream_join_order_buyer') AS
    > SELECT
    >     ROWKEY as join_key,
    >     o.ROWTIME AS o_rowtime,
    >     b.ROWTIME AS b_rowtime,
    > 
    >     o.id AS order_id,
    >     o.product,
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

- Pull request to JOIN stream to **check result**.
    > ```sql
    > SELECT FROM_UNIXTIME(ROWTIME) as row_time, * FROM streamtostream_stream_join_order_buyer EMIT CHANGES;
    > ```



