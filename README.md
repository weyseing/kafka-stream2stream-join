# Setup
- Create docker network via `docker network create global-net`
- Create all Kafka connectors in `connector` folder.
- Create all Ksql streams/tables in `ksql` folder.
- Table in `MySQL DB` will be used as dummy data.

# Supported Join Types
- **Reference:** https://docs.confluent.io/platform/current/ksqldb/developer-guide/joins/join-streams-and-tables.html#join-capabilities
- ksqlDB supports these stream-stream joins (all need a `WITHIN` time window).
    - `INNER JOIN`
    - `LEFT JOIN` / `LEFT OUTER JOIN`
    - `RIGHT JOIN` / `RIGHT OUTER JOIN`
    - `OUTER JOIN` / `FULL OUTER JOIN`

# JOIN Types
### OUTER JOIN
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

- **No matching**
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

- **Match 1 Stream**
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

    - Match 2nd & 3rd stream
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