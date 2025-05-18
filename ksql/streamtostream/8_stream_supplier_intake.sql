CREATE STREAM streamtostream_stream_supplier_intake WITH 
(KAFKA_TOPIC='streamtostream_stream_supplier_intake', VALUE_FORMAT='AVRO', TIMESTAMP='create_date') AS
SELECT
    AFTER->id, AFTER->name, 
    PARSE_TIMESTAMP(AFTER->create_date, 'yyyy-MM-dd''T''HH:mm:ssX') AS create_date
FROM streamtostream_stream_supplier
WHERE AFTER IS NOT NULL
EMIT CHANGES;