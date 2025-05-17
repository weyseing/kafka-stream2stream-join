CREATE STREAM streamtostream_stream_buyer_intake WITH 
(KAFKA_TOPIC='streamtostream_stream_buyer_intake', VALUE_FORMAT='AVRO', TIMESTAMP='create_date') AS
SELECT
    AFTER->id, AFTER->name, 
    PARSE_TIMESTAMP(AFTER->create_date, 'yyyy-MM-dd''T''HH:mm:ssX') AS create_date
FROM streamtostream_stream_buyer
WHERE AFTER IS NOT NULL
EMIT CHANGES;