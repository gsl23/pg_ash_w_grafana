# pg_ash_w_grafana

Active session history in Postgresql with partitioning and grafana visualisation. 
Tested in postgresql v15.3 and Grafana v11.2.0. 

**Prerequirements. **

pg_cron extension must be installed. 

**Installation. **
1. Install .sql files through postgres user in order : 
01_part_functions.sql
02_active_history.sql

2. Setup Grafana dashboard
   2.1 Add datasource through user with select sgrants on postrgres database, table adm.pg_stat_activity_history.
   2.2 Add new dashboard : : New ->  Upload dashboard JSON file -> grafana_dashboard_p_ash_wp.json 
