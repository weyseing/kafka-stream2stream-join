CREATE STREAM streamtostream_stream_product_group_intake WITH 
(KAFKA_TOPIC='streamtostream_stream_product_group_intake', VALUE_FORMAT='AVRO', TIMESTAMP='create_date') AS
SELECT
    AFTER->id, AFTER->name, AFTER->supplier_id,
    PARSE_TIMESTAMP(AFTER->create_date, 'yyyy-MM-dd''T''HH:mm:ssX') AS create_date
FROM streamtostream_stream_product_group
WHERE AFTER IS NOT NULL
EMIT CHANGES;