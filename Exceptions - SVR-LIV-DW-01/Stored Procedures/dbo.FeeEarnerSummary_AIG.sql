SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[FeeEarnerSummary_AIG]

AS


BEGIN
DECLARE @DatasetID VARCHAR(2000) 
SET @DatasetID='226'

DECLARE @ClientGroup VARCHAR(10)
SET @ClientGroup='00000013'

DECLARE @employeeid VARCHAR(1000)
SET @employeeid=NULL


    --create a temp table called #feeearner that will be inserted into later on 
    CREATE TABLE #feeearner (feeearner_code NVARCHAR(10) COLLATE DATABASE_DEFAULT);

    --if employeee id is not null then use it to pull the fee_earner codes from dim_fed_hir
    IF (@employeeid IS  NULL)
    BEGIN

        INSERT INTO #feeearner
        (
            feeearner_code
        )
        (SELECT DISTINCT
             fed_code
         FROM red_dw.dbo.dim_matter_header_current
		 INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		  ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
         WHERE fed_code IS NOT NULL
		 AND client_group_code='00000013'
			   
			   );
    END

    IF OBJECT_ID('tempDB..#caselist') IS NOT NULL
        DROP TABLE #caselist;
    IF OBJECT_ID('tempDB..#exceptions') IS NOT NULL
        DROP TABLE #exceptions;
    IF OBJECT_ID('tempDB..#dataset') IS NOT NULL
        DROP TABLE #dataset;


    IF OBJECT_ID('tempDB..#details_missing_from_matter') IS NOT NULL
        DROP TABLE #details_main;
    IF OBJECT_ID('tempDB..#details_missing_from_matter') IS NOT NULL
        DROP TABLE #details_missing_from_matter;
    IF OBJECT_ID('tempDB..#details_not_linked') IS NOT NULL
        DROP TABLE #details_not_linked;


SELECT dim_fed_hierarchy_history.employeeid,
		CASE WHEN date_closed_case_management IS NULL THEN 0 ELSE 1 END open_closed,
       COUNT(dim_matter_header_current.case_id) cases
INTO #critria_cases
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.dim_detail_core_details
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
    LEFT JOIN red_dw.dbo.dim_detail_outcome
        ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE fact_dimension_main.client_code <> 'ml'
      AND 1 = 1
    and  referral_reason LIKE 'Dispute%' AND 
(
	date_claim_concluded IS NULL  OR 
	date_claim_concluded >= '2017-01-01'  
)  AND 
dim_matter_header_current.reporting_exclusions = 0    AND 
LOWER(ISNULL(outcome_of_case, '')) NOT in ('exclude from reports','returned to client')  AND 
(
	date_closed_case_management >= '2017-01-01' OR date_closed_case_management IS NULL
)       
AND 
employeeid NOT IN 
('D7FCD8D2-A936-472A-8CEB-1BCBECFF65B9','49452DCE-A032-42C2-B328-AFCFE1079561','A7C4010A-8F29-4058-A11E-220C5461036F') AND 
(
	dim_matter_header_current.ms_only = 1  

)
AND hierarchylevel2hist = 'Legal Ops - Claims' AND work_type_code <> '0032'
GROUP BY dim_fed_hierarchy_history.employeeid,date_closed_case_management



    /*Datastes*/
    SELECT val AS datasetid
    INTO #dataset
    FROM split_delimited_to_rows(@DatasetID, ',');

    /*Exceptions*/
    SELECT case_id,
           MainDetail,
           FieldName,
           COUNT(DISTINCT exceptionruleid) AS ExceptionTotal,
           SUM(CriticalCount) AS CriticalTotal
    INTO #exceptions
    FROM
    (
        SELECT ex.case_id,
               1 AS ExceptionCount,
               ex.exceptionruleid,
               CAST(ISNULL(ex.critical, 0) AS INT) AS CriticalCount,
               LEFT(flink.detailsused, LEN(flink.detailsused) - CHARINDEX(',', flink.detailsused)) AS MainDetail,
               COALESCE(df.alias, f.fieldname) AS FieldName
        FROM red_dw.dbo.fact_exceptions_update ex
            JOIN red_dw.dbo.fact_dimension_main fdm
                ON fdm.master_fact_key = ex.master_fact_key
            LEFT JOIN red_dw.dbo.dim_matter_header_current dmhc WITH (NOLOCK)
                ON dmhc.dim_matter_header_curr_key = ex.dim_matter_header_curr_key
            LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history dfhh
                ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
            LEFT JOIN red_dw.dbo.ds_sh_exceptions_fields f
                ON ex.exceptionruleid = f.fieldid
                   AND f.dss_current_flag = 'Y'
            LEFT JOIN red_dw.dbo.ds_sh_exceptions_dataset_fields df
                ON f.fieldid = df.fieldid
                   AND df.dss_current_flag = 'Y'
            LEFT JOIN red_dw.dbo.ds_sh_exceptions_fields flink
                ON f.linkedfieldid = flink.fieldid
                   AND flink.dss_current_flag = 'Y'
        WHERE df.datasetid = ex.datasetid
              AND (
                      df.datasetid IN (
                                          SELECT dataset.datasetid FROM #dataset dataset
                                      )
                      OR @DatasetID = ''
                  )
              AND ex.duplicate_flag = 0 --This might be needed
              AND ex.miscellaneous_flag = 0 --This might be needed
              --AND dfhh.employeeid = @employeeid
             -- AND dmhc.date_closed_case_management IS NULL
    ) exceptions
    GROUP BY case_id,
             MainDetail,
             FieldName;

    /*Caselist*/
    SELECT DISTINCT
        feu.case_id,
        feu.client_code client,
        feu.matter_number matter,
		dmhc.master_client_code master_client,
        dmhc.master_matter_number master_matter,
        dmhc.matter_description case_public_desc1,
        dmhc.date_closed_case_management date_closed,
        feu.fed_code,
        dfhh.name FeeEarnerName,
        cashdr.case_grp,
        dim_client.client_group_code cl_clgrp,
		ms_only,
		dmhc.date_closed_case_management,
		dfhh.employeeid
    INTO #caselist
    FROM red_dw.dbo.fact_exceptions_update feu
        JOIN red_dw.dbo.fact_dimension_main fdm
            ON fdm.master_fact_key = feu.master_fact_key
        JOIN red_dw.dbo.dim_fed_hierarchy_history dfhh
            ON dfhh.dim_fed_hierarchy_history_key = feu.dim_fed_hierarchy_history_key
        JOIN red_dw.dbo.dim_matter_header_current dmhc WITH (NOLOCK)
            ON fdm.dim_matter_header_curr_key = dmhc.dim_matter_header_curr_key
        LEFT JOIN red_dw.dbo.dim_client
            ON dim_client.dim_client_key = fdm.dim_client_key
       left JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
            ON cashdr.case_id = dmhc.case_id
               AND cashdr.current_flag = 'Y'
    WHERE (
              feu.datasetid IN (
                                   SELECT dataset.datasetid FROM #dataset dataset
                               )
              OR @DatasetID = ''
          )
          --AND dfhh.employeeid = @employeeid
          --AND dmhc.date_closed_case_management IS NULL
          AND (
                  dim_client.client_group_code = @ClientGroup
                  OR @ClientGroup = 'ALL'
              );

    --query for the reports
    SELECT caselist.case_id,
           exceptions.FieldName,
           RTRIM(COALESCE(cmdettab.tab_desc, cmdettab_parent.tab_desc, 'Misc.')) AS tab_name,
           COALESCE(cmdettab.tab_order, cmdettab_parent.tab_order, 9999998) AS tab_order,
           exceptions.ExceptionTotal,
           exceptions.CriticalTotal,
		   ms_only,
		date_closed_case_management
    INTO #details_main
    FROM #caselist caselist
        JOIN red_dw.dbo.ds_sh_axxia_casdet casdet
            ON caselist.case_id = casdet.case_id
               AND casdet.current_flag = 'Y'
        JOIN red_dw.dbo.ds_sh_artiion_caslup caslup
            ON casdet.case_detail_code = caslup.case_detail_code
        LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet AS casdet_parent
            ON casdet.case_id = casdet_parent.case_id
               AND casdet_parent.current_flag = 'Y'
               AND casdet.cd_parent = casdet_parent.seq_no
               AND ISNULL(casdet_parent.cd_parent, 0) = 0
        LEFT JOIN #exceptions exceptions
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
    WHERE --caslup.dt_hidden = 'N'
        --AND 			
        NOT (
                COALESCE(cmdettab.tab_desc, cmdettab_parent.tab_desc) IS NULL
                AND ISNULL(casdet.cd_parent, 0) <> 0
            )
        AND ISNULL(caslup_parent.case_detail_code, '') NOT IN ( 'FTR049', 'NMI065', 'NMI066' )
        AND (
                ISNULL(casdet.cd_parent, 0) = 0
                OR casdet_parent.case_id IS NOT NULL
            )
			AND exceptions.ExceptionTotal IS NOT null;

    -- exceptions which are not linked to a details which are missing from a matter...
    SELECT caselist.case_id,
           exsummary.FieldName,
           RTRIM(COALESCE(cmdettab.tab_desc, cmdettab_parent.tab_desc, 'Misc.')) AS tab_name,
           COALESCE(cmdettab.tab_order, cmdettab_parent.tab_order, 9999998) AS tab_order,
           exsummary.ExceptionTotal AS ExceptionTotal,
           exsummary.CriticalTotal AS CriticalTotal
    INTO #details_missing_from_matter
    FROM #caselist caselist
        OUTER APPLY
    (
        SELECT case_id,
               MainDetail,
               FieldName,
               ExceptionTotal,
               CriticalTotal
        FROM #exceptions
        WHERE case_id = caselist.case_id
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
    WHERE 
	--NOT (
 --                 COALESCE(cmdettab.tab_desc, cmdettab_parent.tab_desc) IS NULL
 --                AND caslup_parent.case_detail_code IS NOT NULL
 --             ) -- Exclude Misc details which have a parent.
 ----         --AND caslup.dt_hidden = 'N'
 --         AND 
		  casdet.case_id IS NULL;


    -- exceptions which are not linked to a particular detail...
    SELECT caselist.case_id,
           exsummary.FieldName,
           'Case Level Exceptions' AS tab_name,
           0 AS tab_order,
           exsummary.ExceptionTotal AS ExceptionTotal,
           exsummary.CriticalTotal AS CriticalTotal
    INTO #details_not_linked
    FROM #caselist caselist
        LEFT JOIN
        (
            SELECT case_id,
                   MainDetail,
                   FieldName,
                   ExceptionTotal,
                   CriticalTotal
            FROM #exceptions
        ) exsummary
            ON exsummary.case_id = caselist.case_id
               AND exsummary.MainDetail IS NULL AND ExceptionTotal IS NOT null;




    SELECT exlist.case_id,
           REPLACE(LTRIM(REPLACE(RTRIM(caselist.client), '0', ' ')), ' ', '0') + ' / '
           + REPLACE(LTRIM(REPLACE(RTRIM(caselist.matter), '0', ' ')), ' ', '0') AS matter_ref,
		   RTRIM(caselist.master_client)+' / '+RTRIM(caselist.master_matter) master_matter_ref,
           RTRIM(caselist.case_public_desc1) AS case_public_desc1,
           caselist.date_closed AS DateClosed,
           RTRIM(caselist.fed_code) AS mg_feearn,
           RTRIM(caselist.FeeEarnerName) AS FeeEarnerName,
           (
               SELECT Exceptions.dbo.Concatenate(FieldName, ' | ')
               FROM #exceptions exceptions
               WHERE case_id = exlist.case_id
           ) AS exstring,
           Exceptions.dbo.Concatenate(FieldName, ' | ') AS tabstring,
           tab_name,
           tab_order,
		   ms_only,
		date_closed_case_management,
           SUM(ISNULL(ExceptionTotal, 0)) AS MIProjectExceptionTotal,
           SUM(ISNULL(CriticalTotal, 0)) AS MIProjectCriticalTotal,
           COUNT(1) AS DetailTotal,
		      isnull(closed_critria_cases, 0) closed_critria_cases, 
	    isnull(open_critria_cases,0) open_critria_cases,
	    isnull(critria_cases,0) critria_cases
    FROM #caselist caselist
	LEFT JOIN (
				SELECT employeeid,
				SUM(closed_critria_cases) closed_critria_cases,
				SUM(open_critria_cases) open_critria_cases ,
				SUM(critria_cases) critria_cases
				FROM 
				(
				SELECT 
				employeeid, 
				SUM(cases) critria_cases,
				CASE WHEN #critria_cases.open_closed = 1 then SUM(#critria_cases.cases) END closed_critria_cases,
				CASE WHEN #critria_cases.open_closed = 0 then SUM(#critria_cases.cases) END open_critria_cases
				FROM #critria_cases
				GROUP BY open_closed ,
				employeeid 
				) result GROUP BY 
				employeeid  ) #critria_cases
        ON #critria_cases.employeeid = caselist.employeeid
        INNER JOIN
        (
            SELECT case_id,
                   FieldName,
                   tab_name,
                   tab_order,
                   ExceptionTotal,
                   CriticalTotal
            FROM #details_main
            UNION 
            SELECT case_id,
                   FieldName,
                   tab_name,
                   tab_order,
                   ExceptionTotal,
                   CriticalTotal
            FROM #details_missing_from_matter
            UNION 
            SELECT case_id,
                   FieldName,
                   tab_name,
                   tab_order,
                   ExceptionTotal,
                   CriticalTotal
            FROM #details_not_linked
        ) exlist
            ON caselist.case_id = exlist.case_id
    GROUP BY exlist.case_id,
             caselist.client,
             caselist.matter,
			 caselist.master_client,
			caselist.master_matter,
             caselist.case_public_desc1,
             caselist.date_closed,
             caselist.fed_code,
             caselist.FeeEarnerName,
             tab_name,
             tab_order,
			 ms_only,
		date_closed_case_management,
		  closed_critria_cases , 
	    open_critria_cases ,
	   critria_cases		

END;


GO
