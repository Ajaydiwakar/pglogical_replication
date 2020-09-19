-- Distributed table using  CITUS DATA ----
-- Assuming that CITUS is installed and clusters are initialzed and configured from https://docs.citusdata.com/en/stable/installation/single_machine_debian.html#post-install


-- Started  three clusters with specified ports
/*
pg_ctl -D citus/coordinator -o "-p 9700" -l coordinator_logfile start
pg_ctl -D citus/worker1 -o "-p 9701" -l worker1_logfile start
pg_ctl -D citus/worker2 -o "-p 9702" -l worker2_logfile start

psql -p 9700 -c "CREATE EXTENSION citus;"
psql -p 9701 -c "CREATE EXTENSION citus;"
psql -p 9702 -c "CREATE EXTENSION citus;"

psql -p 9700 -c "SELECT * from master_add_node('localhost', 9701);"
psql -p 9700 -c "SELECT * from master_add_node('localhost', 9702);"


-- Under postgress@rootadmin  login
curl https://examples.citusdata.com/tutorial/companies.csv > companies.csv
curl https://examples.citusdata.com/tutorial/campaigns.csv > campaigns.csv
curl https://examples.citusdata.com/tutorial/ads.csv > ads.csv



-- psql -p 9700 postgres  */


CREATE TABLE companies (
    id bigint NOT NULL,
    name text NOT NULL,
    image_url text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE TABLE campaigns (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    name text NOT NULL,
    cost_model text NOT NULL,
    state text NOT NULL,
    monthly_budget bigint,
    blacklisted_site_urls text[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

CREATE TABLE ads (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    campaign_id bigint NOT NULL,
    name text NOT NULL,
    image_url text,
    target_url text,
    impressions_count bigint DEFAULT 0,
    clicks_count bigint DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

--create primary key indexes on each of the tables

ALTER TABLE companies ADD PRIMARY KEY (id);
ALTER TABLE campaigns ADD PRIMARY KEY (id, company_id);
ALTER TABLE ads ADD PRIMARY KEY (id, company_id);

-- Distributing tables 

SET citus.replication_model = 'streaming';

SELECT create_distributed_table('companies', 'id');
SELECT create_distributed_table('campaigns', 'company_id');
SELECT create_distributed_table('ads', 'company_id');

--Inserting a new row in master 9700 
INSERT INTO companies VALUES (5000, 'New Company', 'https://randomurl/image.png', now(), now());

--double the budget for all the campaigns of a company

UPDATE campaigns
SET monthly_budget = monthly_budget*2
WHERE company_id = 5;


-- Running transactions apaaning on multiple tables

BEGIN;
DELETE FROM campaigns WHERE id = 46 AND company_id = 5;
DELETE FROM ads WHERE campaign_id = 46 AND company_id = 5;
COMMIT;

--Creating a function which do deleteions 

CREATE OR REPLACE FUNCTION delete_campaign(company_id int, campaign_id int)
RETURNS void 
LANGUAGE plpgsql 
AS $$
BEGIN
  DELETE FROM campaigns
   WHERE id = $2 AND campaigns.company_id = $1;
  DELETE FROM ads
   WHERE ads.campaign_id = $2 AND ads.company_id = $1;
END;
$$;


SELECT create_distributed_function(
  'delete_campaign(int, int)', 'company_id',
  colocate_with := 'campaigns'
);

-- you can run the function as usual
SELECT delete_campaign(5, 46);


SELECT name, cost_model, state, monthly_budget
FROM campaigns
WHERE company_id = 5
ORDER BY monthly_budget DESC
LIMIT 10;

--running a join query across multiple tables to see information about running campaigns which receive the most clicks and impressions

SELECT campaigns.id, campaigns.name, campaigns.monthly_budget,
       sum(impressions_count) as total_impressions, sum(clicks_count) as total_clicks
FROM ads, campaigns
WHERE ads.company_id = campaigns.company_id
AND campaigns.company_id = 5
AND campaigns.state = 'running'
GROUP BY campaigns.id, campaigns.name, campaigns.monthly_budget
ORDER BY total_impressions, total_clicks;