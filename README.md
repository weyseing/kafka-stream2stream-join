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

# Guide
### INNER JOIN
