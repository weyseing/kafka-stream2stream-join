# Setup
- Create docker network via `docker network create global-net`
- Create all Kafka connectors in `connector` folder.
- Create all Ksql streams/tables in `ksql` folder.
- `db_data.order` & `db_data.buyer` will be used as **sample table** in MySQL DB.

# Supported Join Types

ksqlDB provides the following join types for **stream-stream** joins (all require a `WITHIN` time window):

- INNER JOIN
- LEFT OUTER JOIN
- RIGHT OUTER JOIN
- FULL OUTER JOIN