CREATE STREAM streamtostream_stream_join WITH 
(KAFKA_TOPIC='streamtostream_stream_join', VALUE_FORMAT='AVRO') AS
SELECT
    o.id AS order_id,
    o.product AS product,
    o.buyer_id AS buyer_id,
    o.amount AS amount,
    o.create_date AS create_date,
    b.name AS buyer_name
FROM streamtostream_stream_order_intake o
JOIN streamtostream_stream_buyer_intake b
WITHIN (5 MINUTES, 10 MINUTES)
ON o.buyer_id = b.id;