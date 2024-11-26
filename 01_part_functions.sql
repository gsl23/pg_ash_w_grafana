CREATE SCHEMA adm AUTHORIZATION postgres;

CREATE OR REPLACE FUNCTION adm.create_day_partition(t_name character varying, s_name character varying)
 RETURNS void AS 
$$
DECLARE
    sql_query TEXT;
    P_NAME VARCHAR(255);
    N INTEGER := 0;
    t_owner  VARCHAR(255);
begin

    select t.tableowner into t_owner from pg_tables t where t.tablename  = t_name and t.schemaname  = s_name ;

    while N <= 10
    loop
        P_NAME :=  T_NAME|| replace(cast(CURRENT_DATE + N as varchar ),'-','_');

      IF NOT EXISTS (select 1 as f1 from pg_tables t
        where t.tablename  =  P_NAME and t.schemaname = S_NAME ) then

       sql_query := 'CREATE TABLE  ' || S_NAME || '.' || P_NAME || ' PARTITION OF ' || S_NAME || '.' || T_NAME || ' FOR VALUES FROM ('''
        || CURRENT_DATE + N || ' 00:00:00'') TO (''' || CURRENT_DATE + N + 1 || ' 00:00:00'')' ;
        EXECUTE sql_query ;

        sql_query := 'ALTER TABLE ' || S_NAME || '.' || P_NAME || ' OWNER TO ' || t_owner;
        EXECUTE sql_query ;

       END IF;
    N := N+1 ;
   end loop;
--   commit;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION adm.drop_old_day_partition ( T_NAME VARCHAR(240) -- table name
    ,S_NAME VARCHAR(100) -- schema name
    ,days_ago integer  -- delete partitions older than N days
    )
  RETURNS void AS
$$
DECLARE
    v_parent_rec RECORD;
begin
    FOR v_parent_rec IN (
            select q.* , 'DROP TABLE ' || q.part_name as sql_query
                from (
                  SELECT cast( inhrelid::regclass as varchar) AS part_name
                    ,to_date (  replace(  cast( inhrelid::regclass as varchar)
                             ,case when ( S_NAME = 'public' or S_NAME = '' ) then ''
                                   else S_NAME || '.'
                                   end ||
                                   T_NAME,'') ,'yyyy_mm_dd') as dt                                   
                  FROM   pg_catalog.pg_inherits i
                  WHERE  inhparent = ( S_NAME || '.' || T_NAME )::regclass ) q
                where q.dt < current_date - days_ago  )
    LOOP
        EXECUTE v_parent_rec.sql_query ;
    END LOOP;
END $$ LANGUAGE plpgsql;
