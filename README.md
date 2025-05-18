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

# OUTER JOIN
### Setup
- Must have **ROWKEY** for **OUTER JOIN**.
    > ```sql
    > SELECT ROWKEY AS join_rowkey
    > ```

- Ensure delete dummy data to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > ```

- Ensure recreate streams below to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_join;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Check result.
    > ```sql
    > SELECT * FROM streamtostream_stream_join EMIT CHANGES;
    > ```

### No matching
- 2nd stream
    > ```sql
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-12 10:30:00');
    > ```
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |null                 |null                 |null                 |null                 |null                 |4                    |Charlie4             |2024-05-12T10:30:00.0|null                 |null                 |null                 |null                 |
    > |                     |                     |                     |                     |                     |                     |                     |00                   |                     |                     |                     |                     |
    > ```
    - **Result:** The new buyer record flows through as a result row with all other columns null, because a FULL OUTER JOIN preserves unmatched records from each joined stream.

- 3rd stream
    > ```sql
    > INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('5', 'Clothing5', '2024-05-12 11:30:00');
    > ```
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |5                    |null                 |null                 |null                 |null                 |null                 |null                 |null                 |null                 |5                    |Clothing5            |2024-05-12T11:30:00.0|
    > |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |                     |00                   |
    > ```
    - **Result:** The new product_group is output as a row with only its columns filled and the rest as null, since FULL OUTER JOIN ensures every new record in any participating stream appears in the output.

- 1st stream
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '4', '6', '2024-05-12 09:30:00');
    > ```
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |6                    |10                   |Gizmo                |2024-05-12T09:30:00.0|4                    |null                 |null                 |null                 |6                    |null                 |null                 |null                 |
    > |                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |                     |
    > ```
    - **Result:** The new order row appears with its columns and all unmatched columns from buyer and product_group as null, as FULL OUTER JOIN outputs every row from every stream, joined if possible, and null if not.

### Match 1 Stream
- Match 2nd stream
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('11', 'Gizmo', '2', '4', '6', '2024-05-12 10:30:00');
    > ```
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |6                    |11                   |Gizmo                |2024-05-12T10:30:00.0|4                    |4                    |Charlie4             |2024-05-12T10:30:00.0|6                    |null                 |null                 |null                 |
    > |                     |                     |                     |00                   |                     |                     |                     |00                   |                     |                     |                     |                     |
    > ```
    - **Result:** The new order record joins with a matching buyer (left side of the first FULL OUTER JOIN) and outputs a row, but since there’s no matching product_group, those fields are null because FULL OUTER JOIN preserves partial matches from any stream.

- Match 3rd stream
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('12', 'Gizmo', '2', '4', '5', '2024-05-12 11:30:00');
    > ```
    > ```
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
    > +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
    > |5                    |12                   |Gizmo                |2024-05-12T11:30:00.0|4                    |null                 |null                 |null                 |5                    |5                    |Clothing5            |2024-05-12T11:30:00.0|
    > |                     |                     |                     |00                   |                     |                     |                     |                     |                     |                     |                     |00                   |
    > ```
    - **Result:** The order record finds a match in product_group (right side of the second FULL OUTER JOIN) and outputs a partially filled row, while unmatched buyer columns remain null, again because FULL OUTER JOIN outputs all possible combinations with nulls for non-matching sides.

### Match ALL stream
> ```sql
> INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('5', 'Charlie5', '2024-05-12 12:30:00');
> INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('6', 'Clothing6', '2024-05-12 12:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('13', 'Gizmo', '2', '5', '6', '2024-05-12 12:30:00');
> ```
> ```
> +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
> |JOIN_ROWKEY          |ORDER_ID             |PRODUCT              |O_CREATE_DATE        |O_BUYER_ID           |B_BUYER_ID           |BUYER_NAME           |B_CREATE_DATE        |O_PRODUCT_GROUP_ID   |P_PRODUCT_GROUP_ID   |PRODUCT_GROUP_NAME   |P_CREATE_DATE        |
> +---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+
> |6                    |13                   |Gizmo                |2024-05-12T12:30:00.0|5                    |5                    |Charlie5             |2024-05-12T12:30:00.0|6                    |6                    |Clothing6            |2024-05-12T12:30:00.0|
> |                     |                     |                     |00                   |                     |                     |                     |00                   |                     |                     |                     |00                   |
> ```

# INNER JOIN
### Setup
- Ensure delete dummy data to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > ```

- Ensure recreate streams below to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_join;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Check result.
    > ```sql
    > SELECT * FROM streamtostream_stream_join EMIT CHANGES;
    > ```

### No matching
> ```sql
> INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-12 10:30:00');
> INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('5', 'Clothing5', '2024-05-12 11:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '4', '5', '2024-05-12 09:30:00');
> ```
- **Result:** No output. Records only appear if they match in every joined stream.

- **Match 1 Stream**
> ```sql
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('11', 'Gizmo', '2', '4', '5', '2024-05-12 10:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('12', 'Gizmo', '2', '4', '5', '2024-05-12 11:30:00');
> ```
- **Result:** No record flow through. Every row must have matching keys in all streams to appear in the INNER JOIN result.

- **Match ALL stream**
> ```sql
> INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('5', 'Charlie5', '2024-05-12 12:30:00');
> INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('6', 'Clothing6', '2024-05-12 12:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('13', 'Gizmo', '2', '5', '6', '2024-05-12 12:30:00');
> ```
> ```
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |O_PRODUCT_GROUP_ID     |ORDER_ID               |PRODUCT                |O_CREATE_DATE          |O_BUYER_ID             |B_BUYER_ID             |BUYER_NAME             |B_CREATE_DATE          |P_PRODUCT_GROUP_ID     |PRODUCT_GROUP_NAME     |P_CREATE_DATE          |
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |6                      |13                     |Gizmo                  |2024-05-12T12:30:00.000|5                      |5                      |Charlie5               |2024-05-12T12:30:00.000|6                      |Clothing6              |2024-05-12T12:30:00.000|
> ```

# LEFT JOIN
### Setup
- Ensure delete dummy data to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > ```

- Ensure recreate streams below to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_join;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Check result.
    > ```sql
    > SELECT * FROM streamtostream_stream_join EMIT CHANGES;
    > ```

### No matching
- 2nd stream
    > ```sql
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-12 10:30:00');
    > ```
    - **Result:** No result, because a LEFT JOIN only outputs rows when the leftmost source stream (order) receives new data, not when a joined stream does.

- 3rd stream
    > ```sql
    > INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('5', 'Clothing5', '2024-05-12 11:30:00');
    > ```
    - **Result:** No result, because the join sequence starts from order, so new records in product_group alone do not trigger output; only joins caused by new order rows are emitted.

- 1st stream
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '4', '6', '2024-05-12 09:30:00');
    > ```
    > ```
    > +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
    > |O_PRODUCT_GROUP_ID     |ORDER_ID               |PRODUCT                |O_CREATE_DATE          |O_BUYER_ID             |B_BUYER_ID             |BUYER_NAME             |B_CREATE_DATE          |P_PRODUCT_GROUP_ID     |PRODUCT_GROUP_NAME     |P_CREATE_DATE          |
    > +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
    > |6                      |10                     |Gizmo                  |2024-05-12T09:30:00.000|4                      |null                   |null                   |null                   |null                   |null                   |null                   |
    > ```

### Match 1 Stream
> ```sql
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('11', 'Gizmo', '2', '4', '5', '2024-05-12 10:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('12', 'Gizmo', '2', '4', '5', '2024-05-12 11:30:00');
> ```
> ```
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |O_PRODUCT_GROUP_ID     |ORDER_ID               |PRODUCT                |O_CREATE_DATE          |O_BUYER_ID             |B_BUYER_ID             |BUYER_NAME             |B_CREATE_DATE          |P_PRODUCT_GROUP_ID     |PRODUCT_GROUP_NAME     |P_CREATE_DATE          |
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |5                      |11                     |Gizmo                  |2024-05-12T10:30:00.000|4                      |4                      |Charlie4               |2024-05-12T10:30:00.000|null                   |null                   |null                   |
> |5                      |12                     |Gizmo                  |2024-05-12T11:30:00.000|4                      |null                   |null                   |null                   |5                      |Clothing5              |2024-05-12T11:30:00.000|
> ```

- **Result**
    - First row (matches buyer only):
        - After inserting a new order, the join immediately attempts to find a matching buyer (based on buyer_id), fills in those columns if found, then continues to join with product_group—if no match there, those fields are null.
    - Second row (matches product group only):
        - When another order is inserted, the join process checks for matching buyer first (none found, fields are null), then checks product_group (match found, those fields are filled), so only the product group columns are populated.

### Match ALL stream
> ```sql
> INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('5', 'Charlie5', '2024-05-12 12:30:00');
> INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('6', 'Clothing6', '2024-05-12 12:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('13', 'Gizmo', '2', '5', '6', '2024-05-12 12:30:00');
> ```
> ```
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |O_PRODUCT_GROUP_ID     |ORDER_ID               |PRODUCT                |O_CREATE_DATE          |O_BUYER_ID             |B_BUYER_ID             |BUYER_NAME             |B_CREATE_DATE          |P_PRODUCT_GROUP_ID     |PRODUCT_GROUP_NAME     |P_CREATE_DATE          |
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |6                      |13                     |Gizmo                  |2024-05-12T12:30:00.000|5                      |5                      |Charlie5               |2024-05-12T12:30:00.000|6                      |Clothing6              |2024-05-12T12:30:00.000|
> ```

# RIGHT JOIN
### Setup
- Ensure delete dummy data to avoid conflict.
    > ```sql
    > DELETE FROM `order` WHERE id > 9;
    > DELETE FROM `buyer` WHERE id > 3;
    > DELETE FROM `product_group` WHERE id > 4;
    > ```

- Ensure recreate streams below to avoid conflict.
    > ```sql
    > DROP STREAM streamtostream_stream_join;
    > DROP STREAM streamtostream_stream_product_group_intake;
    > DROP STREAM streamtostream_stream_buyer_intake;
    > DROP STREAM streamtostream_stream_order_intake;
    > ```

- Check result.
    > ```sql
    > SELECT * FROM streamtostream_stream_join EMIT CHANGES;
    > ```

### No matching
- 2nd stream
    > ```sql
    > INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('4', 'Charlie4', '2024-05-12 10:30:00');
    > ```
    **Result:** No result appears because, with consecutive RIGHT JOINs, a new buyer record will only show up if there is also a matching row in the rightmost product_group stream.

- 3rd stream
    > ```sql
    > INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('5', 'Clothing5', '2024-05-12 11:30:00');
    > ```
    > ```
    > +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
    > |O_PRODUCT_GROUP_ID     |ORDER_ID               |PRODUCT                |O_CREATE_DATE          |O_BUYER_ID             |B_BUYER_ID             |BUYER_NAME             |B_CREATE_DATE          |P_PRODUCT_GROUP_ID     |PRODUCT_GROUP_NAME     |P_CREATE_DATE          |
    > +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
    > |5                      |null                   |null                   |null                   |null                   |null                   |null                   |null                   |5                      |Clothing5              |2024-05-12T11:30:00.000|
    > ```
    - **Result:** A result row is created with product_group fields filled and all other columns null, since the final RIGHT JOIN always outputs every new product_group row regardless of upstream matches.

- 1st stream
    > ```sql
    > INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('10', 'Gizmo', '2', '4', '6', '2024-05-12 09:30:00');
    > ```
    **Result:** No result appears because a new order alone cannot propagate through unless there is also a corresponding product_group for the final RIGHT JOIN to include.

### Match 1 Stream
> ```sql
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('11', 'Gizmo', '2', '4', '5', '2024-05-12 10:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('12', 'Gizmo', '2', '4', '5', '2024-05-12 11:30:00');
> ```
- **Result:**
    - First insertion (order matches buyer only):
        - No result, because although the order matches a buyer in the first RIGHT JOIN, the combined row does not have a product_group match for the final RIGHT JOIN, so it is not included in the output.
    - Second insertion (order matches product_group only):
        - No result, because the order fails to match any buyer in the first RIGHT JOIN, so the row is dropped immediately and never considered by the next join.

# Match ALL stream
> ```sql
> INSERT INTO `buyer` (`id`, `name`, `create_date`) VALUES ('5', 'Charlie5', '2024-05-12 12:30:00');
> INSERT INTO `product_group` (`id`, `name`, `create_date`) VALUES ('6', 'Clothing6', '2024-05-12 12:30:00');
> INSERT INTO `order` (`id`, `product`, `amount`, `buyer_id`, `product_group_id`, `create_date`) VALUES ('13', 'Gizmo', '2', '5', '6', '2024-05-12 12:30:00');
> ```
> ```
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |O_PRODUCT_GROUP_ID     |ORDER_ID               |PRODUCT                |O_CREATE_DATE          |O_BUYER_ID             |B_BUYER_ID             |BUYER_NAME             |B_CREATE_DATE          |P_PRODUCT_GROUP_ID     |PRODUCT_GROUP_NAME     |P_CREATE_DATE          |
> +-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
> |6                      |null                   |null                   |null                   |null                   |null                   |null                   |null                   |6                      |Clothing6              |2024-05-12T12:30:00.000|
> |6                      |13                     |Gizmo                  |2024-05-12T12:30:00.000|5                      |5                      |Charlie5               |2024-05-12T12:30:00.000|6                      |Clothing6              |2024-05-12T12:30:00.000|
> ```
