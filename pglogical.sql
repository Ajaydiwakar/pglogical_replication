------------------------------------------------------
----------  GETTING STARTED WITH PGLOGICAL  ----------
------------------------------------------------------

/* First under root login  write   
root@localhost# cd/ 
root /# mkdir postgress
Inside postgres directory create two three dir for clusters as pg_master , pg_worker1 and pg_worker2 
Now under root login only assign owner for all these three clusters as postgres
root@localhost# chown postgres:postgres pg_master pg_worker1 pg_worker2
Now login in postgres
root@localhost# sudo su - postgres
postgres@rootadmin # EXPORT PATH=$PATH:/usr/pgsql-12/bin ( use this only if direct cluster initdb doesnt works)
Initialize db in all three clusters postgres@rootadmin:~$ /usr/lib/postgresql/12/bin/initdb -D /postgres/pg_master -U postgres ( incase some error shows related to permission than make sure you follow the above step)
postgres@rootadmin:~$ /usr/lib/postgresql/12/bin/initdb -D /postgres/pg_worker1 -U postgres
postgres@rootadmin:~$ /usr/lib/postgresql/12/bin/initdb -D /postgres/pg_worker2 -U postgres 

Once db initialization done than need to make some changes in postgresql.conf file of all three clusters pg_master , pg_worker1 and pg_worker2 
postgres@rootadmin# vim /postgres/pg_master/postgresql.conf

set the varibales and uncomment the lines below in all three clusters
wal_level = 'logical'
max_worker_processes = 10   # one per database needed on provider node
                            # one per node needed on subscriber node
max_replication_slots = 10  # one per node needed on provider node
max_wal_senders = 10        # one per node needed on provider node
shared_preload_libraries = 'pglogical'

Once done start all clusters using 
postgres@rootadmin#/usr/lib/postgresql/12/bin/pg_ctl -D /postgres/pg_master start */

-- Here ports assigned are  pg_master(1111)  pg_worker1(2222) pg_worker2(3333)

--login In pg_master
--postgres@rootadmin# psql -p 1111 postgres

--Create a database named db and connect it than 
-- postgres#\c db

-- PUBLISHER (Port -1111)

CREATE EXTENSION pglogical; 

-- Pglogical extension is applicable on db based and not on cluster based so conenct the db first than create extension
--Now create the provider node:

SELECT pglogical.create_node(
    node_name := 'provider1',
    dsn := 'host=localhost port=1111 dbname=db'
);


CREATE TABLE tbl_1(id int primary key, name text, reg_time timestamp);

--Add all tables in public schema to the default replication set.

SELECT pglogical.replication_set_add_all_tables('default', ARRAY['public']);

-- Create a table and fetch data into it 

CREATE table public.Tech_Trainees
(
Trainee_ID serial,
Trainee_NAME character varying NOT NULL ,
Mobile_Number BIGINT NOT NULL,
Joining_date character varying(50),
Joining_Month character varying(20),
Previous_Profession character varying(50),
Batch_ID Integer NOT NULL,
PRIMARY KEY(Trainee_ID) ,
FOREIGN KEY(Batch_ID) references public.Batch(Batch_ID)
)


Create table public.Batch
(
Batch_ID INTEGER PRIMARY KEY  ,
Batch_type character varying(50) NOT NULL
)

SELECT * FROM pglogical.replication_set_table ;

postgres#\q


-- TO COPY THE SAMETABLE Tech_trainees from Port-1111 to Port-2222 Use:   
postgres@rootadmin #pg_dump -t tech_trainees -s db -p 1111 | psql -p 2222 db;

--Before executing the above command make sure you have created the same database ( ex here is db ) in port 2222 otherwsie pg_dump will throw error

-- SUB (Port-2222)

postgres@rootadmin#psql -p 2222 postgres
postgres#\c db

CREATE EXTENSION pglogical;

SELECT pglogical.create_node(
    node_name := 'subscriber1',
    dsn := 'host=localhost port=2222 dbname=db'
);

SELECT pglogical.create_subscription(
    subscription_name := 'subscription1',
    provider_dsn := 'host=localhost port=1111 dbname=db'
);



-- PUBLISHER (Port-1111)


INSERT INTO public.Tech_Trainees
(Trainee_NAME ,Mobile_Number ,Joining_date ,Joining_Month ,Previous_Profession ,Batch_ID) Values('Febin' , 8765413277 , '01-07-2020' , 'JULY' , 'SDE I' , 1);
INSERT INTO public.Tech_Trainees
(Trainee_NAME ,Mobile_Number ,Joining_date ,Joining_Month ,Previous_Profession ,Batch_ID) Values('Ajay' , 7765413271 , '01-07-2020' , 'JULY' , 'SDE II' , 4);
INSERT INTO public.Tech_Trainees
(Trainee_NAME ,Mobile_Number ,Joining_date ,Joining_Month ,Previous_Profession ,Batch_ID) Values('Abdul' , 9765413274 , '01-07-2020' , 'JULY' , 'Product Support Engineer' , 3);
INSERT INTO public.Tech_Trainees
(Trainee_NAME ,Mobile_Number ,Joining_date ,Joining_Month ,Previous_Profession ,Batch_ID) Values('Rishi' , 9765413273 , '01-07-2020' , 'JULY' , 'Cloud Intern' , 2);
INSERT INTO public.Tech_Trainees
(Trainee_NAME ,Mobile_Number ,Joining_date ,Joining_Month ,Previous_Profession ,Batch_ID) Values('Abhishek' , 8765413276 , '01-07-2020' , 'JULY' , 'Fresher Passout' , 1);


INSERT INTO public.Batch Values(1, 'DevOps Trainee');
INSERT INTO public.Batch Values(2, 'UI/UX Trainee');
INSERT INTO public.Batch Values(3, 'Application Stack Trainee');
INSERT INTO public.Batch Values(4, 'Cloud Engineer Trainee');

SELECT * FROM tech_trainees;



-- SUBSCRIBER (Port-2222)

SELECT * FROM tech_trainees;



-- PUBLISHER (Port-1111)
INSERT INTO public.Tech_Trainees
(Trainee_NAME ,Mobile_Number ,Joining_date ,Joining_Month ,Previous_Profession ,Batch_ID) Values('Rajiv' , 6765413277 , '01-07-2020' , 'JULY' , 'QA' , 4);

SELECT * FROM tech_trainees;



-- SUBSCRIBER (Port-2222)

SELECT * FROM tech_trainees;



--That's all you will find the same data will be replicated as per the provider node . Inorder to add more cluster just follow the same process 