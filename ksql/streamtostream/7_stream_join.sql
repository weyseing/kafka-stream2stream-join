CREATE STREAM streamtostream_stream_join WITH 
(KAFKA_TOPIC='streamtostream_stream_join', VALUE_FORMAT='AVRO') AS
SELECT
    ROWKEY AS join_rowkey,
    o.id AS order_id,
    o.product AS product,
    o.create_date AS o_create_date,
    
    -- buyer
    o.buyer_id AS o_buyer_id,
    b.id AS b_buyer_id,
    b.name AS buyer_name,
    b.create_date AS b_create_date,
    
    -- product group
    o.product_group_id AS o_product_group_id,
    p.id AS p_product_group_id,
    p.name AS product_group_name,
    p.create_date AS p_create_date
FROM streamtostream_stream_order_intake o
FULL OUTER JOIN streamtostream_stream_buyer_intake b
    WITHIN (5 MINUTES, 10 MINUTES)
    ON o.buyer_id = b.id
FULL OUTER JOIN streamtostream_stream_product_group_intake p
    WITHIN (15 MINUTES, 30 MINUTES)
    ON o.product_group_id = p.id;