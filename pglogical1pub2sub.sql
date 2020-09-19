-----------------------------------------------------------------
----------  PGLOGICAL WITH 1 PROVIDER WITH 2 SUBSCRIBER  ----------
-----------------------------------------------------------------


-- PROVIDER (Port-1111 )

CREATE EXTENSION pglogical;

CREATE TABLE tbl (id int primary key,name varchar);

SELECT pglogical.create_node (
    node_name := 'provider',
    dns := 'host=localhost port=1111 dbname=db'
);

SELECT pglogical.replication_set_add_table (
    set_name := 'default', relation := 'tbl', synchronize_data := true
);



-- SUBSCRIBER1 (Port-2222 DB-sub1)

CREATE EXTENSION pglogical;

CREATE TABLE tbl (id int primary key,name varchar);

SELECT pglogical.create_node (
    node_name := 'subscriber1',
    dsn := 'host=localhost port=2222 dbname=sub1'
);

SELECT pglogical.create_subscription (
    subscription_name := 'subscription1',
    provider_dsn := 'host=localhost port=1111 dbname=db'
);



-- SUBSCRIBER2 (Port-2222 DB-sub2)

CREATE EXTENSION pglogical;

CREATE TABLE tbl (id int primaty key, name varchar);

SELECT pglogical.create_node (
    node_name := 'subscriber2',
    dsn := 'host=localhost port=2222 dbname=sub2'
);

SELECT pglogical.create_subscription (
    subscription_name := 'subscribtion2',
    provider_dsn := 'host=localhost port=1111 dbname=db'
);



-- PROVIDER (Port-1111 DB- db)

INSERT INTO tbl VALUES (1, 'ROHIT SHARMA');
INSERT INTO tbl VALUES (2, 'K RAHUL');

SELECT * FROM tbl;



-- SUBSCRIBER1 (Port-2222 DB-sub1)

SELECT * FROM tbl;



-- SUBSCRIBER2 (Port-2222 DB-sub2)

SELECT * FROM tbl;
