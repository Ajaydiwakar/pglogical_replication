---------------------------------------------------------
---------------  COLUMN FILTER IN PGLOGICAL  ---------------
---------------------------------------------------------


-- PROVIDER (Port-1111)
--postgres@rootadmin# psql -p 1111 postgres
--Now we are using new db named column_filter

--postgres # \c column_filter
CREATE EXTENSION pglogical;

create table car (
	id BIGSERIAL NOT NULL PRIMARY KEY,
	make VARCHAR(100) NOT NULL,
	model VARCHAR(100) NOT NULL,
	price NUMERIC(19, 2) NOT NULL
);

SELECT pglogical.create_node (
    node_name := 'provider',
    dsn := 'host=localhost port=1111 dbname=column_filter'
);

SELECT pglogical.replication_set_add_table ( 
    set_name := 'default', relation := 'car', synchronize_data := true,
    columns :='{id, model, price}'
);


-- TO COPY THE SAMETABLE car from Port-1111 to Port-2222 Use:   
--postgres@rootadmin #pg_dump -t car -s column_filter -p 1111 | psql -p 2222 column_filter;

--Before executing the above command make sure you have created the same database ( ex here is column_filter ) in port 2222 otherwsie pg_dump will throw error


-- SUBSCRIBER (Port-2222)
--create database column_filter
--postgres#\c column_filter

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
    dsn := 'host=localhost port=2222 dbname=column_filter'
);

SELECT pglogical.create_subscription (
    subscription_name := 'subscription', 
    provider_dsn := 'host=localhost port=1111 dbname=column_filter'
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


-- Here you will find only columns id , model and price will show up remaining column  make will not be shown 

