SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[FeeEarnerSummary](
	  @FeeEarnerCode VARCHAR(MAX) ='5178,PAS,2090,3427,1930,1485,2094,2078,NSX,1972,3755,3466,3422,2016,1687,5129,4993,PAT,5156,SHO,EBH,3452,4953,VEC,1579,RBZ,1732,3424,3120,3061,LUE,3458,NPR2,DFA,835,EJW,MSS,BFY5,SEH1,5432,3286,1803,CLM,5212,DJN,PAU,1365,5206,1839,DJC,EMC1,DAH,EDX     ,4937,5538,1692,3480,WAQ,3235,1889,EMC,1949,AAZ,5589,1287,BWM,3485,3487,WFX,5790,3393,TBS,3497,JCP,1785,3078'
	, @ClientGroup VARCHAR(10) = 'ALL'
	, @DatasetID VARCHAR(2000) = '42,43,44'  
	, @employeeid VARCHAR(1000) = NULL
)
AS
 --EXEC dbo.FeeEarnerSummary @FeeEarnerCode = 'AAI', -- varchar(max)
 --    @ClientGroup = 'ALL', -- varchar(10)
 --    @DatasetID = '29,40,47,50,51,52,53,54,62,63,75,82,83,84,94,95,98' -- varchar(100)
 

--Test parameters
--DECLARE @FeeEarnerCode VARCHAR(MAX) = '5178,PAS,2090,3427,1930,1485,2094,2078,NSX,1972,3755,3466,3422,2016,1687,5129,4993,PAT,5156,SHO,EBH,3452,4953,VEC,1579,RBZ,1732,3424,3120,3061,LUE,3458,NPR2,DFA,835,EJW,MSS,BFY5,SEH1,5432,3286,1803,CLM,5212,DJN,PAU,1365,5206,1839,DJC,EMC1,DAH,EDX     ,4937,5538,1692,3480,WAQ,3235,1889,EMC,1949,AAZ,5589,1287,BWM,3485,3487,WFX,5790,3393,TBS,3497,JCP,1785,3078';
--DECLARE @ClientGroup VARCHAR(10) = 'ALL';
--DECLARE @DatasetID VARCHAR(100) = '42,43,44';

BEGIN

CREATE TABLE #feeearner (feeearner_code NVARCHAR(10) COLLATE DATABASE_DEFAULT)

IF (@employeeid IS not NULL)
BEGIN

INSERT INTO #feeearner (feeearner_code) 
(SELECT DISTINCT fed_code  FROM red_Dw.dbo.dim_fed_hierarchy_history WHERE employeeid COLLATE DATABASE_DEFAULT = @employeeid COLLATE DATABASE_DEFAULT AND fed_code IS NOT null)
End

INSERT INTO #feeearner (feeearner_code) 
( SELECT   val AS feeearner_code FROM     split_delimited_to_rows(@FeeEarnerCode, ',')) 

SELECT DISTINCT  @employeeid   = employeeid FROM red_Dw.dbo.dim_fed_hierarchy_history WHERE fed_code = @FeeEarnerCode


   ; WITH    dataset
              AS ( SELECT   val AS datasetid
                   FROM     split_delimited_to_rows(@DatasetID, ',')
                 ),
			/*Exceptions*/
            exceptions
              AS ( SELECT   case_id
                           ,MainDetail
                           ,FieldName
                           ,SUM(ExceptionCount) AS ExceptionTotal
                           ,SUM(CriticalCount) AS CriticalTotal
                   FROM     ( SELECT   DISTINCT  ex.case_id
                                       ,1 AS ExceptionCount
                                       ,CAST(ISNULL(ex.critical, 0) AS INT) AS CriticalCount
                                       ,LEFT(flink.detailsused,
                                             LEN(flink.detailsused)
                                             - CHARINDEX(',',
                                                         flink.detailsused)) AS MainDetail
                                       ,COALESCE(df.alias, f.fieldname) AS FieldName
                              FROM      red_dw.dbo.fact_exceptions_update ex
							  JOIN	red_dw.dbo.fact_dimension_main fdm
								ON fdm.master_fact_key = ex.master_fact_key 
								JOIN	red_dw.dbo.dim_fed_hierarchy_history dfhh
								ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key 
                              INNER JOIN red_dw.dbo.ds_sh_exceptions_fields f
                                        ON ex.exceptionruleid = f.fieldid
                                           AND f.dss_current_flag = 'Y'
                              INNER JOIN red_dw.dbo.ds_sh_exceptions_dataset_fields df
                                        ON f.fieldid = df.fieldid
                                           AND df.dss_current_flag = 'Y'
                              LEFT JOIN red_dw.dbo.ds_sh_exceptions_fields flink
                                        ON f.linkedfieldid = flink.fieldid
                                           AND flink.dss_current_flag = 'Y'
                              WHERE     df.datasetid = ex.datasetid
                                        AND ( df.datasetid IN (
                                              SELECT    dataset.datasetid
                                              FROM      dataset )
                                              OR @DatasetID = ''
                                            )
										AND ex.duplicate_flag <> 1 --This might be needed
										AND ex.miscellaneous_flag <> 1 --This might be needed
                                        AND dfhh.employeeid = @employeeid
                            ) exceptions
                   GROUP BY case_id
                           ,MainDetail
                           ,FieldName
                 )/*Caselist*/
,           caselist
              AS ( SELECT DISTINCT
                            feu.case_id
                           ,feu.client_code client
                           ,feu.matter_number matter
                           ,dmhc.matter_description case_public_desc1
                           ,dmhc.date_closed_case_management date_closed
                           ,feu.fed_code
                           ,dmhc.matter_owner_full_name FeeEarnerName
                           ,cashdr.case_grp
						   ,dim_client.client_group_code cl_clgrp
                   FROM     red_dw.dbo.fact_exceptions_update feu
					JOIN	red_dw.dbo.fact_dimension_main fdm
					ON fdm.master_fact_key = feu.master_fact_key
					JOIN	red_dw.dbo.dim_fed_hierarchy_history dfhh
								ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key 
                    JOIN     red_dw.dbo.dim_matter_header_current dmhc
                            ON fdm.dim_matter_header_curr_key = dmhc.dim_matter_header_curr_key
					LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fdm.dim_client_key
                    JOIN     red_dw.dbo.ds_sh_axxia_cashdr cashdr
                            ON cashdr.case_id = dmhc.case_id
                               AND cashdr.current_flag = 'Y'
                   WHERE    (feu.datasetid IN ( SELECT dataset.datasetid FROM dataset  )
							OR @DatasetID = '' )
	                           AND dfhh.employeeid = @employeeid
						 AND (dim_client.client_group_code = @ClientGroup OR @ClientGroup = 'ALL')
                 )


        SELECT  exlist.case_id
               ,REPLACE(LTRIM(REPLACE(RTRIM(caselist.client), '0', ' ')), ' ',
                        '0') + ' / '
                + REPLACE(LTRIM(REPLACE(RTRIM(caselist.matter), '0', ' ')),
                          ' ', '0') AS matter_ref
               ,RTRIM(caselist.case_public_desc1) AS case_public_desc1
               ,caselist.date_closed AS DateClosed
               ,RTRIM(caselist.fed_code) AS mg_feearn
               ,RTRIM(caselist.FeeEarnerName) AS FeeEarnerName
               ,( SELECT    Exceptions.dbo.Concatenate(FieldName, ' | ')
                  FROM      exceptions
                  WHERE     case_id = exlist.case_id
                ) AS exstring
               ,Exceptions.dbo.Concatenate(FieldName, ' | ') AS tabstring
               ,tab_name
               ,tab_order
               ,SUM(ISNULL(ExceptionTotal, 0)) AS MIProjectExceptionTotal
               ,SUM(ISNULL(CriticalTotal, 0)) AS MIProjectCriticalTotal
               ,COUNT(1) AS DetailTotal
        FROM    caselist
        INNER JOIN ( SELECT caselist.case_id
                           ,exceptions.FieldName
                           ,RTRIM(COALESCE(cmdettab.tab_desc,
                                           cmdettab_parent.tab_desc, 'Misc.')) AS tab_name
                           ,COALESCE(cmdettab.tab_order,
                                     cmdettab_parent.tab_order, 9999998) AS tab_order
                           ,exceptions.ExceptionTotal
                           ,exceptions.CriticalTotal
                     FROM   caselist
                     JOIN   red_dw.dbo.ds_sh_axxia_casdet casdet
                            ON caselist.case_id = casdet.case_id
                               AND casdet.current_flag = 'Y'
                     JOIN   red_dw.dbo.ds_sh_artiion_caslup caslup
                            ON casdet.case_detail_code = caslup.case_detail_code
                     LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet AS casdet_parent
                            ON casdet.case_id = casdet_parent.case_id
                               AND casdet_parent.current_flag = 'Y'
                               AND casdet.cd_parent = casdet_parent.seq_no
                               AND ISNULL(casdet_parent.cd_parent, 0) = 0
                     LEFT JOIN exceptions
                            ON exceptions.case_id = caselist.case_id
                               AND exceptions.MainDetail = casdet.case_detail_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab casluptab
                            ON casdet.case_detail_code = casluptab.detail_code
                               AND caselist.case_grp = casluptab.group_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_cmdettab cmdettab
                            ON casluptab.tab_code = cmdettab.tab_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_cmldetsubd cmldetsubd
                            ON cmldetsubd.sub_detail = casdet.case_detail_code 
							--AND  cmldetsubd.sequence = casdet.seq_no  --Removed to match reports SG-25/10/2016
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_caslup AS caslup_parent
                            ON cmldetsubd.detail_code = caslup_parent.case_detail_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab AS casluptab_parent
                            ON caslup_parent.case_detail_code = casluptab_parent.detail_code
                               AND caselist.case_grp = casluptab_parent.group_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_cmdettab AS cmdettab_parent
                            ON casluptab_parent.tab_code = cmdettab_parent.tab_code
                     WHERE  --caslup.dt_hidden = 'N'
	   					  --AND 			
						  NOT ( COALESCE(cmdettab.tab_desc,
                                           cmdettab_parent.tab_desc) IS NULL
                                  AND ISNULL(casdet.cd_parent, 0) <> 0
                                )
                            AND ISNULL(caslup_parent.case_detail_code, '') NOT IN (
                            'FTR049', 'NMI065', 'NMI066' )
							AND (ISNULL(casdet.cd_parent,0) = 0 OR casdet_parent.case_id IS NOT NULL)
                     UNION ALL 
			-- exceptions which are not linked to a details which are missing from a matter...
                     SELECT caselist.case_id
                           ,exsummary.FieldName
                           ,RTRIM(COALESCE(cmdettab.tab_desc,
                                           cmdettab_parent.tab_desc, 'Misc.')) AS tab_name
                           ,COALESCE(cmdettab.tab_order,
                                     cmdettab_parent.tab_order, 9999998) AS tab_order
                           ,exsummary.ExceptionTotal AS ExceptionTotal
                           ,exsummary.CriticalTotal AS CriticalTotal
                     FROM   caselist
                     OUTER APPLY ( SELECT   case_id
                                           ,MainDetail
                                           ,FieldName
                                           ,ExceptionTotal
                                           ,CriticalTotal
                                   FROM     exceptions
                                   WHERE    case_id = caselist.case_id
                                 ) exsummary
                     INNER JOIN red_dw.dbo.ds_sh_artiion_caslup caslup
                            ON exsummary.MainDetail = caslup.case_detail_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab casluptab
                            ON exsummary.MainDetail = casluptab.detail_code
                               AND caselist.case_grp = casluptab.group_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_cmdettab cmdettab
                            ON casluptab.tab_code = cmdettab.tab_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_cmldetsubd cmldetsubd
                            ON cmldetsubd.sub_detail = exsummary.MainDetail
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_caslup AS caslup_parent
                            ON cmldetsubd.detail_code = caslup_parent.case_detail_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab AS casluptab_parent
                            ON caslup_parent.case_detail_code = casluptab_parent.detail_code
                               AND caselist.case_grp = casluptab_parent.group_code
                     LEFT JOIN red_dw.dbo.ds_sh_artiion_cmdettab AS cmdettab_parent
                            ON casluptab_parent.tab_code = cmdettab_parent.tab_code
                     LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet casdet
                            ON caselist.case_id = casdet.case_id
                               AND caslup.case_detail_code = casdet.case_detail_code
                               AND casdet.current_flag = 'Y'
                     WHERE  NOT ( COALESCE(cmdettab.tab_desc,
                                           cmdettab_parent.tab_desc) IS NULL
                                  AND caslup_parent.case_detail_code IS NOT NULL
                                ) -- Exclude Misc details which have a parent.
                            --AND caslup.dt_hidden = 'N'
                            AND casdet.case_id IS NULL
                     UNION ALL	
		-- exceptions which are not linked to a particular detail...
                     SELECT caselist.case_id
                           ,exsummary.FieldName
                           ,'Case Level Exceptions' AS tab_name
                           ,0 AS tab_order
                           ,exsummary.ExceptionTotal AS ExceptionTotal
                           ,exsummary.CriticalTotal AS CriticalTotal
                     FROM   caselist
                     LEFT JOIN ( SELECT case_id
                                       ,MainDetail
                                       ,FieldName
                                       ,ExceptionTotal
                                       ,CriticalTotal
                                 FROM   exceptions
                               ) exsummary
                            ON exsummary.case_id = caselist.case_id
                               AND exsummary.MainDetail IS NULL
                   ) AS exlist
                ON caselist.case_id = exlist.case_id
        GROUP BY exlist.case_id
               ,caselist.client
               ,caselist.matter
               ,caselist.case_public_desc1
               ,caselist.date_closed
               ,caselist.fed_code
               ,caselist.FeeEarnerName
               ,tab_name
               ,tab_order
	OPTION (OPTIMIZE FOR (@ClientGroup='ALL', @DatasetID='40,47,50,51,52,53,54'));
END; 


GO
