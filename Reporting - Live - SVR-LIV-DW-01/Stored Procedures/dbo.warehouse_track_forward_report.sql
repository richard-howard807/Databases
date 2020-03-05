SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[warehouse_track_forward_report] (@Table VARCHAR(100), @Column VARCHAR(100))

AS 

DROP TABLE IF exists #tracker 

SELECT  fc_obj_key object_key, a.fc_col_key col_key, b.ft_table_name table_name, fc_col_name column_name, fc_data_type data_type, 
		fc_src_table source_table, fc_src_column source_column, fc_transform_code transformation, null connection, 'fact' Tabletype,
		b.ft_update_key updatekey, a.fc_src_strategy Col_comments, b.ft_description tbl_comments, b.ft_doc_3 grain, ft_doc_4 example_query, b.ft_doc_5 documented
	into #tracker
from red_dw.dbo.ws_fact_col a
inner join red_dw.dbo.ws_fact_tab b on a.fc_obj_key = b.ft_obj_key
WHERE fc_col_name NOT IN ('source_system_id') AND a.fc_eul_flag = 'Y'

union all

select  dc_obj_key object_key, a.dc_col_key, b.dt_table_name table_name, dc_col_name column_name, dc_data_type data_type, 
		dc_src_table source_table, dc_src_column source_column, dc_transform_code transformation, null connection, 'dim' Tabletype
		, b.dt_update_key, a.dc_src_strategy, b.dt_description, NULL, NULL, null
		-- select *
from red_dw.dbo.ws_dim_col a
inner join red_dw.dbo.ws_dim_tab b on a.dc_obj_key = b.dt_obj_key

union all

select  sc_obj_key object_key, a.sc_col_key, b.st_table_name table_name, sc_col_name column_name, sc_data_type data_type, 
		sc_src_table source_table, sc_src_column source_column, sc_transform_code transformation, null connection, 'stage' Tabletype
		, IIF(b.st_update_key = 0, b.st_build_key, b.st_update_key), a.sc_src_strategy, b.st_description, NULL, NULL, null
-- select *
from red_dw.dbo.ws_stage_col a
inner join red_dw.dbo.ws_stage_tab b on a.sc_obj_key = b.st_obj_key
WHERE b.st_table_name NOT LIKE '%axxia%'

union all

select  oc_obj_key object_key, a.oc_col_key, b.ot_table_name table_name, oc_col_name column_name, oc_data_type data_type, 
		oc_src_table source_table, oc_src_column source_column, oc_transform_code transformation, null connection, 'datastore' Tabletype
		, b.ot_update_key, a.oc_src_strategy, b.ot_description, NULL, NULL, null
		-- select *
from red_dw.dbo.ws_ods_col a
inner join red_dw.dbo.ws_ods_tab b on a.oc_obj_key = b.ot_obj_key
WHERE b.ot_table_name NOT LIKE '%axxia%'

union all

select  lc_obj_key object_key, a.lc_col_key, b.lt_table_name table_name, lc_col_name column_name, lc_data_type data_type, 
		lc_src_table source_table, lc_src_column source_column, lc_transform_code transformation, c.dc_name, 'load' Tabletype
		, NULL, a.lc_src_strategy, b.lt_description, NULL, NULL, null
-- select b.*
from red_dw.dbo.ws_load_col a
inner join red_dw.dbo.ws_load_tab b on a.lc_obj_key = b.lt_obj_key
left outer join red_dw.dbo.ws_dbc_connect c on c.dc_obj_key = b.lt_connect_key
WHERE b.lt_table_name NOT LIKE '%axxia%'

;

with track_forward as (
		SELECT object_key Parent_Key, col_key parent_col_key, column_name Parent_Name, object_key, col_key, table_name, column_name, data_type, source_table, source_column, transformation, connection
		, 1 AS level, updatekey, tbl_comments, Col_comments, grain, example_query, documented
		-- select *
		from #tracker
		WHERE LOWER(column_name) = LOWER(@Column)
		AND LOWER(#tracker.table_name) = LOWER(@Table)

		union all

		SELECT c.object_key Parent_key, c.col_key parent_col_key, c.column_name Parent_Name, a.object_key, a.col_key, a.table_name, a.column_name, a.data_type, a.source_table, a.source_column, a.transformation, a.connection
		, level+1, a.updatekey, a.tbl_comments, a.Col_comments, NULL, NULL, null
		-- select *
		FROM #tracker a
		inner join track_forward c on LOWER(a.table_name) IN (SELECT LOWER(table_name) FROM #tracker WHERE LOWER(#tracker.source_table) = LOWER(c.table_name))
		AND LOWER(a.source_column) = LOWER(c.column_name)
		AND a.table_name <> 'dim_date'
		WHERE level+1 < 99 -- stops loop error
	)


SELECT DISTINCT 'Forward' Direction,
				track_forward.Parent_Key,
                track_forward.Parent_Name,
                track_forward.object_key,
				track_forward.col_key,
				IIF(track_forward.parent_col_key = track_forward.col_key, NULL, track_forward.parent_col_key) parent_col_key,
                track_forward.table_name,
                track_forward.column_name,
                track_forward.data_type,
                track_forward.source_table,
                track_forward.source_column,
                cast (track_forward.transformation AS NVARCHAR(max)) transformation,
                track_forward.connection,
                track_forward.level,
                track_forward.updatekey,
                cast (track_forward.tbl_comments AS NVARCHAR(max)) tbl_comments,
                cast (track_forward.Col_comments AS NVARCHAR(max)) col_comments,
                cast (track_forward.grain AS NVARCHAR(max)) grain,
                cast (track_forward.example_query AS NVARCHAR(max)) example_query,
                cast (track_forward.documented AS NVARCHAR(max)) documented, 
		(SELECT STRING_AGG(CAST(pl_line + ' <br> ' AS NVARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY pl_line_no) AS proc_text
		FROM red_dw.dbo.ws_pro_line
		WHERE pl_obj_key = track_forward.updatekey) Update_procedure

from track_forward 
ORDER BY level






GO
