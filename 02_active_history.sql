CREATE SCHEMA adm AUTHORIZATION postgres;

CREATE TABLE adm.pg_stat_activity_history (
        sample_time timestamptz ,
        datid oid NULL,
        pid int4 NULL,
        leader_pid int4 NULL,
        usesysid oid NULL,
        application_name text NULL,
        client_addr inet NULL,
        client_hostname text NULL,
        client_port int4 NULL,
        backend_start timestamptz NULL,
        xact_start timestamptz NULL,
        state_change timestamptz NULL,
        wait_event_type text NULL,
        wait_event text NULL,
        state text NULL,
        backend_xid xid NULL,
        backend_xmin xid NULL,
        query_id int8 NULL,
        query text null,
        query_start timestamptz NULL,
        duration numeric NULL
) PARTITION BY RANGE (sample_time);

CREATE INDEX pg_stat_act_h_idx_stime ON adm.pg_stat_activity_history USING btree (sample_time);


INSERT INTO cron.job (schedule,command,nodename,nodeport,"database",username,active,jobname) VALUES
	 ('20 0 * * *'
	  ,'select adm.create_day_partition(''pg_stat_activity_history'', ''adm'');  commit ;'
	 ,'',5432
	 ,'postgres','postgres',true,'part_awr_hist');
	
INSERT INTO cron.job (schedule,command,nodename,nodeport,"database",username,active,jobname) VALUES
         ('30 0 * * *'
          ,'select adm.drop_old_day_partition(''pg_stat_activity_history'', ''adm'', 14);  commit ;'
         ,'',5432
         ,'postgres','postgres',true,'del_part_awr_hist');
		 
select adm.create_day_partition('pg_stat_activity_history', 'adm');

CREATE OR REPLACE FUNCTION adm.pg_stat_activity_snapshot()
 RETURNS void AS 
$$
DECLARE
start_ts timestamp := (select clock_timestamp());
ldiff numeric := 0;
BEGIN
        WHILE ldiff < 60
        LOOP
insert
        into adm.pg_stat_activity_history
select
        clock_timestamp() as sample_time,
        datid ,
        pid ,
        leader_pid ,
        usesysid ,
        application_name ,
        client_addr inet ,
        client_hostname ,
        client_port ,
        backend_start ,
        xact_start ,
        state_change ,
        wait_event_type ,
        wait_event ,
        state ,
        backend_xid ,
        backend_xmin ,
        query_id ,
        query ,
        query_start ,
        1000 * extract(EPOCH from (clock_timestamp()-query_start)) as duration -- milliseconds (1/1000sec)
 from pg_stat_activity
 where state <> 'idle' and usename <> 'replicator'
        and pid != pg_backend_pid();

        perform pg_stat_clear_snapshot();
        perform pg_sleep(10);
        ldiff := EXTRACT (EPOCH FROM (clock_timestamp() - start_ts));

        END LOOP;
END $$ LANGUAGE plpgsql;


INSERT INTO cron.job (schedule, command, nodename, nodeport, database, username) values
('* * * * *', 'SELECT adm.pg_stat_activity_snapshot();', '', 5432, 'postgres', 'postgres');
		 
COMMIT;		 