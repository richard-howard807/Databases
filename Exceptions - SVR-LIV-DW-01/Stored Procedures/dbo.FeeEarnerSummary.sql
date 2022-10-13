SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[FeeEarnerSummary](
	  @FeeEarnerCode VARCHAR(MAX)
	, @ClientGroup VARCHAR(10) = 'ALL'
	, @DatasetID VARCHAR(100) = ''  
)
AS


/*--Test parameters
DECLARE @FeeEarnerCode VARCHAR(MAX) = 'AAI';
DECLARE @ClientGroup VARCHAR(10) = 'ALL';
DECLARE @DatasetID VARCHAR(100) = '29,40,47,50,51,52,53,54,62,63,75,82,83,84,94,95,98';*/

BEGIN

    WITH    dataset
              AS ( SELECT   val AS datasetid
                   FROM     split_delimited_to_rows(@DatasetID, ',')
                 ),
            feeearner
              AS ( SELECT   val AS feeearner_code
                   FROM     split_delimited_to_rows(@FeeEarnerCode, ',')
                 ),
			/*Exceptions*/
            exceptions
              AS ( SELECT   case_id
                           ,MainDetail
                           ,FieldName
                           ,SUM(ExceptionCount) AS ExceptionTotal
                           ,SUM(CriticalCount) AS CriticalTotal
                   FROM     ( SELECT    ex.case_id
                                       ,1 AS ExceptionCount
                                       ,CAST(ISNULL(ex.critical, 0) AS INT) AS CriticalCount
                                       ,LEFT(flink.detailsused,
                                             LEN(flink.detailsused)
                                             - CHARINDEX(',',
                                                         flink.detailsused)) AS MainDetail
                                       ,COALESCE(df.alias, f.fieldname) AS FieldName
                              FROM      fact_exceptions_update ex
                              INNER JOIN ds_sh_exceptions_fields f
                                        ON ex.exceptionruleid = f.fieldid
                                           AND f.dss_current_flag = 'Y'
                              INNER JOIN ds_sh_exceptions_dataset_fields df
                                        ON f.fieldid = df.fieldid
                                           AND df.dss_current_flag = 'Y'
                              LEFT JOIN ds_sh_exceptions_fields flink
                                        ON f.linkedfieldid = flink.fieldid
                                           AND flink.dss_current_flag = 'Y'
                              WHERE     df.datasetid = ex.datasetid
                                        AND ( df.datasetid IN (
                                              SELECT    dataset.datasetid
                                              FROM      dataset )
                                              OR @DatasetID = ''
                                            )
                                        AND ex.fed_code IN (
                                        SELECT  feeearner.feeearner_code
                                        FROM    feeearner )
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
						   ,caclient.cl_clgrp
                   FROM     fact_exceptions_update feu
                    JOIN     dim_matter_header_current dmhc
                            ON feu.case_id = dmhc.case_id
                    JOIN     ds_sh_axxia_cashdr cashdr
                            ON cashdr.case_id = feu.case_id
                               AND cashdr.current_flag = 'Y'
                   JOIN     ds_sh_axxia_caclient caclient
                            ON dmhc.client_code = caclient.cl_accode
                               AND caclient.current_flag = 'Y'
                   WHERE    (feu.datasetid IN ( SELECT dataset.datasetid FROM dataset  )
							OR @DatasetID = '' )
	                            AND  feu.fed_code IN (SELECT feeearner.feeearner_code FROM feeearner)
                            AND dmhc.date_closed_case_management IS NULL
						 AND (caclient.cl_clgrp = @ClientGroup OR @ClientGroup = 'ALL')
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
                     JOIN   ds_sh_axxia_casdet casdet
                            ON caselist.case_id = casdet.case_id
                               AND casdet.current_flag = 'Y'
                     JOIN   ds_sh_artiion_caslup caslup
                            ON casdet.case_detail_code = caslup.case_detail_code
                     LEFT JOIN dbo.ds_sh_axxia_casdet AS casdet_parent
                            ON casdet.case_id = casdet_parent.case_id
                               AND casdet_parent.current_flag = 'Y'
                               AND casdet.cd_parent = casdet_parent.seq_no
                               AND ISNULL(casdet_parent.cd_parent, 0) = 0
                     LEFT JOIN exceptions
                            ON exceptions.case_id = caselist.case_id
                               AND exceptions.MainDetail = casdet.case_detail_code
                     LEFT JOIN ds_sh_artiion_casluptab casluptab
                            ON casdet.case_detail_code = casluptab.detail_code
                               AND caselist.case_grp = casluptab.group_code
                     LEFT JOIN ds_sh_artiion_cmdettab cmdettab
                            ON casluptab.tab_code = cmdettab.tab_code
                     LEFT JOIN ds_sh_artiion_cmldetsubd cmldetsubd
                            ON cmldetsubd.sub_detail = casdet.case_detail_code
                     LEFT JOIN ds_sh_artiion_caslup AS caslup_parent
                            ON cmldetsubd.detail_code = caslup_parent.case_detail_code
                     LEFT JOIN ds_sh_artiion_casluptab AS casluptab_parent
                            ON caslup_parent.case_detail_code = casluptab_parent.detail_code
                               AND caselist.case_grp = casluptab_parent.group_code
                     LEFT JOIN ds_sh_artiion_cmdettab AS cmdettab_parent
                            ON casluptab_parent.tab_code = cmdettab_parent.tab_code
                     WHERE  caslup.dt_hidden = 'N'
	   					  AND 			NOT ( COALESCE(cmdettab.tab_desc,
                                           cmdettab_parent.tab_desc) IS NULL
                                  AND ISNULL(casdet.cd_parent, 0) <> 0
                                )
                            AND ISNULL(caslup_parent.case_detail_code, '') NOT IN (
                            'FTR049', 'NMI065', 'NMI066' )
							AND (ISNULL(casdet.cd_parent,0) = 0 OR casdet_parent.case_id IS NOT null)
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
                     INNER JOIN ds_sh_artiion_caslup caslup
                            ON exsummary.MainDetail = caslup.case_detail_code
                     LEFT JOIN ds_sh_artiion_casluptab casluptab
                            ON exsummary.MainDetail = casluptab.detail_code
                               AND caselist.case_grp = casluptab.group_code
                     LEFT JOIN ds_sh_artiion_cmdettab cmdettab
                            ON casluptab.tab_code = cmdettab.tab_code
                     LEFT JOIN ds_sh_artiion_cmldetsubd cmldetsubd
                            ON cmldetsubd.sub_detail = exsummary.MainDetail
                     LEFT JOIN ds_sh_artiion_caslup AS caslup_parent
                            ON cmldetsubd.detail_code = caslup_parent.case_detail_code
                     LEFT JOIN ds_sh_artiion_casluptab AS casluptab_parent
                            ON caslup_parent.case_detail_code = casluptab_parent.detail_code
                               AND caselist.case_grp = casluptab_parent.group_code
                     LEFT JOIN ds_sh_artiion_cmdettab AS cmdettab_parent
                            ON casluptab_parent.tab_code = cmdettab_parent.tab_code
                     LEFT JOIN ds_sh_axxia_casdet casdet
                            ON caselist.case_id = casdet.case_id
                               AND caslup.case_detail_code = casdet.case_detail_code
                               AND casdet.current_flag = 'Y'
                     WHERE  NOT ( COALESCE(cmdettab.tab_desc,
                                           cmdettab_parent.tab_desc) IS NULL
                                  AND caslup_parent.case_detail_code IS NOT NULL
                                ) -- Exclude Misc details which have a parent.
                            AND caslup.dt_hidden = 'N'
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
