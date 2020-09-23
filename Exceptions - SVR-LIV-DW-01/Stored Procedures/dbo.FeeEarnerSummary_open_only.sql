SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[FeeEarnerSummary_open_only]
(
    @FeeEarnerCode VARCHAR(MAX) = '5178,PAS,2090,3427,1930,1485,2094,2078,NSX,1972,3755,3466,3422,2016,1687,5129,4993,PAT,5156,SHO,EBH,3452,4953,VEC,1579,RBZ,1732,3424,3120,3061,LUE,3458,NPR2,DFA,835,EJW,MSS,BFY5,SEH1,5432,3286,1803,CLM,5212,DJN,PAU,1365,5206,1839,DJC,EMC1,DAH,EDX     ,4937,5538,1692,3480,WAQ,3235,1889,EMC,1949,AAZ,5589,1287,BWM,3485,3487,WFX,5790,3393,TBS,3497,JCP,1785,3078',
    @ClientGroup VARCHAR(10) = 'ALL',
    @DatasetID VARCHAR(2000) = '42,43,44',
    @employeeid VARCHAR(1000) = NULL
)
AS
--exec FeeEarnerSummary_open_only 
--@FeeEarnerCode=N'6076',
--@ClientGroup=N'ALL',
--@DatasetID=N'29,33,34,40,41,42,43,44,46,47,48,50,51,52,53,54,55,56,57,60,61,62,63,64,65,69,70,72,73,74,75,82,83,84,85,86,87,88,89,91,92,93,94,95,96,97,98,99,100,102,104,106,107,108,109,110,111,112,113,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,195,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225',
--@employeeid=N'FB3DDA41-169B-4282-838C-BE25A4A2B685'

BEGIN

    --create a temp table called #feeearner that will be inserted into later on 
    CREATE TABLE #feeearner (feeearner_code NVARCHAR(10) COLLATE DATABASE_DEFAULT);

    --if employeee id is not null then use it to pull the fee_earner codes from dim_fed_hir
    IF (@employeeid IS NOT NULL)
    BEGIN

        INSERT INTO #feeearner
        (
            feeearner_code
        )
        (SELECT DISTINCT
             fed_code
         FROM red_dw.dbo.dim_fed_hierarchy_history
         WHERE employeeid COLLATE DATABASE_DEFAULT = @employeeid COLLATE DATABASE_DEFAULT
               AND fed_code IS NOT NULL);
    END;

    INSERT INTO #feeearner
    (
        feeearner_code
    )
    (SELECT val AS feeearner_code
     FROM split_delimited_to_rows(@FeeEarnerCode, ',') );

    SELECT DISTINCT
        @employeeid = employeeid
    FROM red_dw.dbo.dim_fed_hierarchy_history
    WHERE fed_code = @FeeEarnerCode;

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
              AND ex.duplicate_flag <> 1 --This might be needed
              AND ex.miscellaneous_flag <> 1 --This might be needed
              AND dfhh.employeeid = @employeeid
              AND dmhc.date_closed_case_management IS NULL
    ) exceptions
    GROUP BY case_id,
             MainDetail,
             FieldName;

    /*Caselist*/
    SELECT DISTINCT
        feu.case_id,
        feu.client_code client,
        feu.matter_number matter,
        dmhc.matter_description case_public_desc1,
        dmhc.date_closed_case_management date_closed,
        feu.fed_code,
        dmhc.matter_owner_full_name FeeEarnerName,
        cashdr.case_grp,
        dim_client.client_group_code cl_clgrp
    INTO #caselist
    FROM red_dw.dbo.fact_exceptions_update feu
        JOIN red_dw.dbo.fact_dimension_main fdm
            ON fdm.master_fact_key = feu.master_fact_key
        JOIN red_dw.dbo.dim_fed_hierarchy_history dfhh
            ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
        JOIN red_dw.dbo.dim_matter_header_current dmhc WITH (NOLOCK)
            ON fdm.dim_matter_header_curr_key = dmhc.dim_matter_header_curr_key
        LEFT JOIN red_dw.dbo.dim_client
            ON dim_client.dim_client_key = fdm.dim_client_key
        JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr
            ON cashdr.case_id = dmhc.case_id
               AND cashdr.current_flag = 'Y'
    WHERE (
              feu.datasetid IN (
                                   SELECT dataset.datasetid FROM #dataset dataset
                               )
              OR @DatasetID = ''
          )
          AND dfhh.employeeid = @employeeid
          AND dmhc.date_closed_case_management IS NULL
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
           exceptions.CriticalTotal
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
           SUM(ISNULL(ExceptionTotal, 0)) AS MIProjectExceptionTotal,
           SUM(ISNULL(CriticalTotal, 0)) AS MIProjectCriticalTotal,
           COUNT(1) AS DetailTotal
    FROM #caselist caselist
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
             caselist.case_public_desc1,
             caselist.date_closed,
             caselist.fed_code,
             caselist.FeeEarnerName,
             tab_name,
             tab_order;


END;


GO
