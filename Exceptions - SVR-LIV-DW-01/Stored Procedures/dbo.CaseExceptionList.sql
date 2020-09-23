SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--[dbo].[CaseExceptionList] 358138,'29,40,47,50,51,52,53,54,62,63,75,82,83,84,94,95,98'

CREATE PROCEDURE [dbo].[CaseExceptionList] (
	  @CaseID INT
	, @DatasetID VARCHAR(max) = ''
)
AS

/*
--Test parameters
DECLARE @CaseID INT = 366131
DECLARE @DatasetID VARCHAR(100) = '29,40,47,50,51,52,53,54,62,63,75,82,83,84,94,95,98'*/

BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	WITH exceptions AS (
		SELECT  distinct ex.case_id
			,ex.exceptionruleid
			 , COALESCE(df.alias, f.fieldname) AS ExceptionRule
			 , MAX(f.narrative + ISNULL(d.descriptionsuffix, '')) AS Narrative
			 , LEFT(flink.detailsused, LEN(flink.detailsused) - CHARINDEX(',', flink.detailsused)) AS MainDetail
			 , MAX(df.severity) severity
			 , max(CAST(df.critical AS int)) critical
		FROM red_dw.dbo.fact_exceptions_update ex --Reporting_DW.Exceptions.StagingData ex
		--INNER JOIN axxia01.dbo.cashdr ON ex.case_id = axxia01.dbo.cashdr.case_id
		INNER JOIN red_dw.dbo.ds_sh_exceptions_fields f ON ex.exceptionruleid = f.fieldid AND f.dss_current_flag = 'Y' --Reporting_DW.Exceptions.Fields f ON ex.ExceptionRuleID = f.FieldID
		LEFT JOIN red_dw.dbo.ds_sh_exceptions_dataset_fields df ON f.fieldid = df.fieldid AND df.datasetid = ex.datasetid AND df.dss_current_flag = 'Y'--Reporting_DW.Exceptions.DatasetFields df ON f.FieldID = df.FieldID
		LEFT JOIN red_dw.dbo.ds_sh_exceptions_fields flink ON f.linkedfieldid = flink.fieldid AND flink.dss_current_flag = 'Y' --Reporting_DW.Exceptions.Fields flink ON f.LinkedFieldID = flink.FieldID
		LEFT JOIN red_dw.dbo.ds_sh_exceptions_datasets d ON df.datasetid = d.datasetid AND d.dss_current_flag = 'Y'--Reporting_DW.Exceptions.Datasets d ON df.DatasetID = d.DatasetID
		WHERE df.datasetid = ex.datasetid
			AND (df.datasetid IN (SELECT val AS datasetid FROM split_delimited_to_rows(@DatasetID, ',')) OR @DatasetID = '')
		AND ex.case_id = @CaseID
		AND ex.test = 0
        AND (ex.miscellaneous_flag <> 1
        AND ex.duplicate_flag <> 1)
		GROUP BY  ex.case_id
			,ex.exceptionruleid
			,df.alias
			,f.fieldname
			,flink.detailsused

	)
	SELECT cashdr.case_id
		 , REPLACE(LTRIM(REPLACE(RTRIM(cashdr.client), '0', ' ')), ' ', '0')
			+ ' / ' + REPLACE(LTRIM(REPLACE(RTRIM(cashdr.matter), '0', ' ')), ' ', '0') AS matter_ref
		 , RTRIM(cashdr.case_public_desc1) AS case_public_desc1
		 , RTRIM(feearn.ds_descrn) AS FeeEarnerName
		 , cashdr.date_opened
		 , cashdr.date_closed
		 , RTRIM(COALESCE(cmdettab.tab_desc, (CASE WHEN ISNULL(casdet.cd_parent, 0) = 0 THEN NULL ELSE cmdettab_parent.tab_desc END), 'Misc.')) AS tab_name
		 , COALESCE(cmdettab.tab_order, (CASE WHEN ISNULL(casdet.cd_parent, 0) = 0 THEN NULL ELSE cmdettab_parent.tab_order END), 9999998) AS tab_order
		 , DENSE_RANK() OVER (PARTITION BY cashdr.case_id ORDER BY COALESCE(cmdettab.tab_order, (CASE WHEN ISNULL(casdet.cd_parent, 0) = 0 THEN NULL ELSE cmdettab_parent.tab_order END), 9999998)) AS tabnum
		 , ROW_NUMBER() OVER (PARTITION BY cashdr.case_id ORDER BY COALESCE(cmdettab.tab_order, (CASE WHEN ISNULL(casdet.cd_parent, 0) = 0 THEN NULL ELSE cmdettab_parent.tab_order END), 9999998), (CASE WHEN caslup_parent.case_detail_desc IS NULL THEN caslup.case_detail_desc ELSE caslup_parent.case_detail_desc END), casdet.cd_parent, casdet.seq_no) AS rownum
		 , RTRIM(caslup_parent.case_detail_code) AS parent_code
		 , RTRIM(caslup_parent.case_detail_desc) AS parent_desc
		 --, caslup_parent.seq_no AS parent_seq_no
		 , RTRIM(caslup.case_detail_code) AS case_detail_code
		 , RTRIM(caslup.case_detail_desc) AS case_detail_desc
		 , casdet.seq_no
		 , casdet.cd_parent
		 , CONVERT(VARCHAR(10), casdet.case_date, 120) AS case_date
		 , CONVERT(VARCHAR(1), casdet.case_mkr) AS case_mkr
		 , CONVERT(VARCHAR(60), ISNULL(RTRIM(stdetlst.sd_listxt), RTRIM(casdet.case_text))) AS case_text
		 , CONVERT(VARCHAR(20), casdet.case_value) AS case_value
		 , (CASE WHEN rectyp.flag_date = 'Y' THEN ISNULL(CONVERT(VARCHAR(10), casdet.case_date, 103) + ' | ', '') ELSE '' END)
		   + (CASE WHEN rectyp.flag_mkr = 'Y' THEN ISNULL(CONVERT(VARCHAR(1), casdet.case_mkr) + ' | ', '') ELSE '' END)
		   + (CASE WHEN rectyp.flag_text = 'Y' THEN ISNULL(CONVERT(VARCHAR(60), ISNULL(RTRIM(stdetlst.sd_listxt), NULLIF(RTRIM(casdet.case_text), '')) + ' | '), '') ELSE '' END)
		   + (CASE WHEN rectyp.flag_val = 'Y' THEN (CASE WHEN caslup.dt_integer = 'y' THEN ISNULL(CONVERT(VARCHAR(20), CAST(casdet.case_value AS DECIMAL(13,0))) + ' | ', '')
														ELSE ISNULL(CONVERT(VARCHAR(20), casdet.case_value) + ' | ', '') END) ELSE '' END) AS combined_entry
		 , exsummary.exstring
		 , exsummary.exnarrative
		 , (CASE WHEN exsummary.exstring IS NULL THEN NULL ELSE exsummary.Severity END) AS Severity
		 , exsummary.Critical AS Critical
	FROM red_dw.dbo.ds_sh_axxia_cashdr cashdr --axxia01.dbo.cashdr
	INNER JOIN red_dw.dbo.ds_sh_axxia_camatgrp camatgrp ON cashdr.client = camatgrp.mg_client AND cashdr.matter = camatgrp.mg_matter AND camatgrp.current_flag = 'Y'--axxia01.dbo.camatgrp ON cashdr.client = camatgrp.mg_client AND cashdr.matter = camatgrp.mg_matter
	LEFT JOIN red_dw.dbo.ds_sh_axxia_cadescrp AS feearn ON camatgrp.mg_feearn = feearn.ds_reckey AND feearn.ds_rectyp = 'FE' AND feearn.dss_current_flag = 'Y'--axxia01.dbo.cadescrp AS feearn ON camatgrp.mg_feearn = feearn.ds_reckey AND feearn.ds_rectyp = 'FE'
	INNER JOIN red_dw.dbo.ds_sh_axxia_casdet casdet ON casdet.case_id = cashdr.case_id AND casdet.current_flag = 'Y' AND casdet.deleted_flag = 'N'--axxia01.dbo.casdet ON cashdr.case_id = casdet.case_id
	INNER JOIN red_dw.dbo.ds_sh_artiion_caslup caslup ON caslup.case_detail_code = casdet.case_detail_code --axxia01.dbo.caslup ON casdet.case_detail_code = axxia01.dbo.caslup.case_detail_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab casluptab ON casdet.case_detail_code = casluptab.detail_code AND cashdr.case_grp = casluptab.group_code --axxia01.dbo.casluptab ON casdet.case_detail_code = casluptab.detail_code AND cashdr.case_grp = casluptab.group_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_cmdettab cmdettab ON casluptab.tab_code = cmdettab.tab_code--axxia01.dbo.cmdettab ON casluptab.tab_code = cmdettab.tab_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_stdetlst stdetlst ON casdet.case_text = stdetlst.sd_liscod AND casdet.case_detail_code = stdetlst.sd_detcod --axxia01.dbo.stdetlst ON casdet.case_text = stdetlst.sd_liscod AND casdet.case_detail_code = stdetlst.sd_detcod
	LEFT JOIN red_dw.dbo.ds_sh_artiion_cmldetsubd cmldetsubd ON cmldetsubd.sub_detail = casdet.case_detail_code --AND cmldetsubd.sequence = casdet.seq_no  -- removed SG to match reports
	--axxia01.dbo.cmldetsubd ON cmldetsubd.sub_detail = casdet.case_detail_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_caslup caslup_parent ON cmldetsubd.detail_code = caslup_parent.case_detail_code --axxia01.dbo.caslup AS caslup_parent ON cmldetsubd.detail_code = caslup_parent.case_detail_code
	--LEFT JOIN axxia01.dbo.casdet AS casdet_parent ON casdet.case_id = casdet_parent.case_id AND cmldetsubd.sequence = casdet_parent.seq_no
	LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab casluptab_parent ON caslup_parent.case_detail_code = casluptab_parent.detail_code AND cashdr.case_grp = casluptab_parent.group_code --axxia01.dbo.casluptab AS casluptab_parent ON caslup_parent.case_detail_code = casluptab_parent.detail_code AND cashdr.case_grp = casluptab_parent.group_code
	LEFT JOIN red_dw.dbo.load_artiion_cmdettab cmdettab_parent ON casluptab_parent.tab_code = cmdettab_parent.tab_code --axxia01.dbo.cmdettab AS cmdettab_parent ON casluptab_parent.tab_code = cmdettab_parent.tab_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_rectyp rectyp ON caslup.case_detail_rectyp = rectyp.case_detail_rectyp --axxia01.dbo.rectyp ON caslup.case_detail_rectyp = rectyp.case_detail_rectyp
	--LEFT JOIN exsummary ON exsummary.case_id = cashdr.case_id AND exsummary.MainDetail = casdet.case_detail_code
	OUTER APPLY (SELECT Exceptions.dbo.Concatenate(ExceptionRule, ' | ') AS exstring
					, Exceptions.dbo.Concatenate(Narrative, ' | ') AS exnarrative
					, MAX(exmain.severity) AS Severity
					, MAX(CAST(exmain.critical AS INT)) AS Critical
				FROM exceptions exmain
				WHERE exmain.case_id = cashdr.case_id AND exmain.MainDetail = casdet.case_detail_code   -- cashdr.case_id
				GROUP BY exmain.case_id) exsummary
	WHERE cashdr.current_flag = 'Y'
	AND cashdr.case_id = @CaseID
	--AND NOT (COALESCE(cmdettab.tab_desc, cmdettab_parent.tab_desc) IS NULL AND ISNULL(casdet.cd_parent, 0) <> 0 AND caslup_parent.case_detail_code IS NULL) -- Exclude orphaned Misc details. --Removed As it wont show exceptions that are in the case plan but on the misc tab SG: 2016-09-01
	AND (ISNULL(casdet.cd_parent, 0) = 0 OR EXISTS (SELECT 1 FROM red_dw.dbo.ds_sh_axxia_casdet  AS casdet_parent WHERE casdet.case_id= casdet_parent.case_id AND casdet.cd_parent = casdet_parent.seq_no AND ISNULL(casdet_parent.cd_parent, 0) = 0) and casdet.current_flag = 'Y')
	AND caslup.dt_hidden = 'N'
	AND ISNULL(caslup_parent.case_detail_code, '') NOT IN ('FTR049', 'NMI059', 'NMI065', 'NMI066') -- Subdetails hidden on Bob's request
	UNION ALL	
	-- Include exceptions which are linked to a detail which doesn't exist in the matter...
	SELECT cashdr.case_id
		 , REPLACE(LTRIM(REPLACE(RTRIM(cashdr.client), '0', ' ')), ' ', '0')
			+ ' / ' + REPLACE(LTRIM(REPLACE(RTRIM(cashdr.matter), '0', ' ')), ' ', '0') AS matter_ref
		 , RTRIM(cashdr.case_public_desc1) AS case_public_desc1
		 , RTRIM(feearn.ds_descrn) AS FeeEarnerName
		 , cashdr.date_opened
		 , cashdr.date_closed
		 , RTRIM(COALESCE(cmdettab.tab_desc, NULL, 'Misc.')) AS tab_name
		 , COALESCE(cmdettab.tab_order, NULL, 9999998) AS tab_order
		 , DENSE_RANK() OVER (PARTITION BY cashdr.case_id ORDER BY COALESCE(cmdettab.tab_order, 9999998)) AS tabnum
		 , ROW_NUMBER() OVER (PARTITION BY cashdr.case_id ORDER BY COALESCE(cmdettab.tab_order, 9999998), (CASE WHEN caslup_parent.case_detail_desc IS NULL THEN caslup.case_detail_desc ELSE caslup_parent.case_detail_desc END)) AS rownum
		 , RTRIM(caslup_parent.case_detail_code) AS parent_code
		 , RTRIM(caslup_parent.case_detail_desc) AS parent_desc
		 --, caslup_parent.seq_no AS parent_seq_no
		 , RTRIM(caslup.case_detail_code) AS case_detail_code
		 , RTRIM(caslup.case_detail_desc) AS case_detail_desc
		 , 99999 AS seq_no
		 , 99999 AS cd_parent
		 , NULL AS case_date
		 , NULL AS case_mkr
		 , NULL AS case_text
		 , NULL AS case_value
		 , '' AS combined_entry
		 , exsummary.exstring
		 , exsummary.exnarrative
		 , (CASE WHEN exsummary.exstring IS NULL THEN NULL ELSE exsummary.Severity END) AS Severity
		 , exsummary.Critical AS Critical
	FROM red_dw.dbo.ds_sh_axxia_cashdr cashdr
	INNER JOIN red_dw.dbo.ds_sh_axxia_camatgrp camatgrp ON cashdr.client = camatgrp.mg_client AND cashdr.matter = camatgrp.mg_matter AND camatgrp.current_flag = 'Y'
	LEFT JOIN red_dw.dbo.ds_sh_axxia_cadescrp AS feearn ON camatgrp.mg_feearn = feearn.ds_reckey AND feearn.ds_rectyp = 'FE' AND feearn.dss_current_flag = 'Y'
	OUTER APPLY (SELECT Exceptions.dbo.Concatenate(ExceptionRule, ' | ') AS exstring
				, Exceptions.dbo.Concatenate(Narrative, ' | ') AS exnarrative
				, MAX(exmain.severity) AS Severity
				, MAX(CAST(exmain.critical AS INT)) AS Critical
				, exmain.MainDetail AS MainDetail
			FROM exceptions exmain
			WHERE exmain.case_id = cashdr.case_id --AND exmain.MainDetail = casdet.case_detail_code  -- cashdr.case_id
			GROUP BY exmain.case_id, exmain.MainDetail) exsummary
	LEFT JOIN red_dw.dbo.ds_sh_artiion_caslup caslup ON exsummary.MainDetail = caslup.case_detail_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab casluptab ON exsummary.MainDetail = casluptab.detail_code AND cashdr.case_grp = casluptab.group_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_cmdettab cmdettab ON casluptab.tab_code = cmdettab.tab_code
	--LEFT JOIN axxia01.dbo.stdetlst ON casdet.case_text = stdetlst.sd_liscod AND casdet.case_detail_code = stdetlst.sd_detcod
	LEFT JOIN red_dw.dbo.ds_sh_artiion_cmldetsubd cmldetsubd ON cmldetsubd.sub_detail = exsummary.MainDetail
	LEFT JOIN red_dw.dbo.ds_sh_artiion_caslup AS caslup_parent ON cmldetsubd.detail_code = caslup_parent.case_detail_code
	--LEFT JOIN axxia01.dbo.casdet AS casdet_parent ON casdet.case_id = casdet_parent.case_id AND cmldetsubd.sequence = casdet_parent.seq_no
	LEFT JOIN red_dw.dbo.ds_sh_artiion_casluptab AS casluptab_parent ON caslup_parent.case_detail_code = casluptab_parent.detail_code AND cashdr.case_grp = casluptab_parent.group_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_cmdettab AS cmdettab_parent ON casluptab_parent.tab_code = cmdettab_parent.tab_code
	LEFT JOIN red_dw.dbo.ds_sh_artiion_rectyp rectyp ON caslup.case_detail_rectyp = rectyp.case_detail_rectyp
	LEFT JOIN red_dw.dbo.ds_sh_axxia_casdet casdet ON cashdr.case_id = casdet.case_id AND caslup.case_detail_code = casdet.case_detail_code AND casdet.current_flag = 'Y' AND casdet.deleted_flag = 'N'
	WHERE cashdr.case_id = @CaseID
	AND cashdr.current_flag ='Y'
	AND (
	--(
	--NOT (COALESCE(cmdettab.tab_desc, cmdettab_parent.tab_desc) IS NULL AND caslup_parent.case_detail_code IS NULL) -- Exclude orphaned Misc details.
	--		--AND ISNULL(casdet.cd_parent, 0) = 0 OR EXISTS (SELECT 1 FROM axxia01.dbo.casdet AS casdet_parent WHERE casdet.case_id= casdet_parent.case_id AND casdet.cd_parent = casdet_parent.seq_no AND ISNULL(casdet_parent.cd_parent, 0) = 0)
	--)
			--AND 
			caslup.dt_hidden = 'N'
			AND ISNULL(caslup_parent.case_detail_code, '') NOT IN ('FTR049', 'NMI059', 'NMI065', 'NMI066') -- Subdetails hidden on Bob's request
		)
	AND casdet.case_id IS NULL
	UNION ALL
	-- Include exceptions which are not linked to a particular detail...
	SELECT cashdr.case_id
		 , REPLACE(LTRIM(REPLACE(RTRIM(cashdr.client), '0', ' ')), ' ', '0')
			+ ' / ' + REPLACE(LTRIM(REPLACE(RTRIM(cashdr.matter), '0', ' ')), ' ', '0') AS matter_ref
		 , RTRIM(cashdr.case_public_desc1) AS case_public_desc1
		 , RTRIM(feearn.ds_descrn) AS FeeEarnerName
		 , cashdr.date_opened
		 , cashdr.date_closed
		 , 'Case Level Exceptions' AS tab_name
		 , 0 AS tab_order
		 , 0 AS tabnum
		 , 0 AS rownum
		 , NULL AS parent_code
		 , NULL AS parent_desc
		 , NULL AS case_detail_code
		 , NULL AS case_detail_desc
		 , NULL AS seq_no
		 , NULL AS cd_parent
		 , NULL AS case_date
		 , NULL AS case_mkr
		 , NULL AS case_text
		 , NULL AS case_value
		 , NULL AS combined_entry
		 , exsummary.exstring
		 , exsummary.exnarrative
		 , (CASE WHEN exsummary.exstring IS NULL THEN NULL ELSE exsummary.Severity END) AS Severity
		 , exsummary.Critical AS Critical
	FROM red_dw.dbo.ds_sh_axxia_cashdr cashdr
	INNER JOIN red_dw.dbo.ds_sh_axxia_camatgrp camatgrp ON cashdr.client = camatgrp.mg_client AND cashdr.matter = camatgrp.mg_matter AND camatgrp.current_flag = 'Y'
	LEFT JOIN red_dw.dbo.ds_sh_axxia_cadescrp AS feearn ON camatgrp.mg_feearn = feearn.ds_reckey AND feearn.ds_rectyp = 'FE' AND feearn.dss_current_flag = 'Y'
	--LEFT JOIN exsummary ON exsummary.case_id = cashdr.case_id AND exsummary.MainDetail IS NULL
	OUTER APPLY (SELECT Exceptions.dbo.Concatenate(ExceptionRule, ' | ') AS exstring
					, Exceptions.dbo.Concatenate(Narrative, ' | ') AS exnarrative
					, MAX(exmain.severity) AS Severity
					, MAX(CAST(exmain.critical AS INT)) AS Critical
				FROM exceptions exmain
				WHERE exmain.case_id = cashdr.case_id AND MainDetail IS NULL
				GROUP BY exmain.case_id) exsummary
	WHERE cashdr.current_flag = 'Y'
	AND cashdr.case_id = @CaseID
END

GO
