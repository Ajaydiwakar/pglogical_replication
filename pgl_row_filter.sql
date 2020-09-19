---------------------------------------------------------
---------------  ROW FILTER IN PGLOGICAL  ---------------
---------------------------------------------------------


-- PROVIDER (Port-1111)
--postgres@rootadmin# psql -p 1111 postgres

--postgres # \c db
CREATE EXTENSION pglogical;

create table car (
	id BIGSERIAL NOT NULL PRIMARY KEY,
	make VARCHAR(100) NOT NULL,
	model VARCHAR(100) NOT NULL,
	price NUMERIC(19, 2) NOT NULL
);

SELECT pglogical.create_node (
    node_name := 'provider',
    dsn := 'host=localhost port=1111 dbname=db'
);

SELECT pglogical.replication_set_add_table ( 
    set_name := 'default', relation := 'car', synchronize_data := true,
    row_filter := 'price > 59000'
);


-- TO COPY THE SAMETABLE car from Port-1111 to Port-2222 Use:   
--postgres@rootadmin #pg_dump -t car -s db -p 1111 | psql -p 2222 db;

--Before executing the above command make sure you have created the same database ( ex here is db ) in port 2222 otherwsie pg_dump will throw error


-- SUBSCRIBER (Port-2222)
--postgres#\c db

CREATE EXTENSION pglogical;

-- or create the table manually instead of using pg_dump
create table car (
	id BIGSERIAL NOT NULL PRIMARY KEY,
	make VARCHAR(100) NOT NULL,
	model VARCHAR(100) NOT NULL,
	price NUMERIC(19, 2) NOT NULL
);

SELECT pglogical.create_node (
    node_name := 'subscriber',
    dsn := 'host=localhost port=2222 dbname=db'
);

SELECT pglogical.create_subscription (
    subscription_name := 'subscription', 
    provider_dsn := 'host=localhost port=1111 dbname=db'
);



-- PROVIDER (Port-1111)
INSERT INTO car VALUES( 11 , 'TOYOTA-2020' , 'ETIOS' , 35000);
INSERT INTO car VALUES( 21 , 'MERCEDES BENZ - 2019' , 'GLA' , 4500000)
INSERT INTO car VALUES( 81 , 'MERCEDES BENZ - 2020' , 'AMG-Coupe' , 9500000)
INSERT INTO car VALUES( 91 , 'MAHINDRA - 2020' , '4x4 - MATIC' , 850000)
INSERT INTO car VALUES( 101 , 'HYUNDAI-2020' , 'i20' , 55000);

SELECT * FROM car;



-- SUBSCRIBER (Port-2222)

SELECT * FROM car;

select count(id) from car;

-- Here you will find only rows which has price >  59000 will be listed 

-- PROVIDER (Port-9999)

select count(id) from car where (price > 59000);

