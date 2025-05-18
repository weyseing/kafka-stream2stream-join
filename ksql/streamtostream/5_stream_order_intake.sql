CREATE STREAM streamtostream_stream_order_intake WITH 
(KAFKA_TOPIC='streamtostream_stream_order_intake', VALUE_FORMAT='AVRO', TIMESTAMP='create_date') AS
SELECT
    AFTER->id, AFTER->product, AFTER->amount, AFTER->buyer_id, AFTER->product_group_id,
    PARSE_TIMESTAMP(AFTER->create_date, 'yyyy-MM-dd''T''HH:mm:ssX') AS create_date
FROM streamtostream_stream_order
WHERE AFTER IS NOT NULL
EMIT CHANGES;