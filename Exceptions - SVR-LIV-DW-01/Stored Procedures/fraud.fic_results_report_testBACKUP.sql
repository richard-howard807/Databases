SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 21/02/2018
-- Description:	Webby Ticket 295245 (Based on the Fraud Indicator Score report)
-- =============================================
-- ES 2020-03-12 42547 Amended the logic to look at the FIC Process task rather than
--						filter based on the FIC score which is based on case details

--==============================================

create PROCEDURE [fraud].[fic_results_report_testBACKUP]

	@Department varchar(MAX)
	, @Team varchar(MAX)
	, @Handler varchar(MAX)
	, @ClientGroupName varchar(MAX)
	
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Handler') IS NOT NULL   DROP TABLE #Handler
	IF OBJECT_ID('tempdb..#ClientGroupName') IS NOT NULL   DROP TABLE #ClientGroupName
	IF OBJECT_ID('tempdb..#FICProcess') IS NOT NULL   DROP TABLE #FICProcess

	--SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)
	--SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)
	--SELECT ListValue  INTO #Handler FROM 	dbo.udt_TallySplit(',', @Handler)
	--SELECT ListValue  INTO #ClientGroupName FROM 	dbo.udt_TallySplit(',', @ClientGroupName)

	CREATE TABLE #Department 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Department
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Department) 

	CREATE TABLE #Team 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Team
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Team) 

	CREATE TABLE #Handler 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Handler
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Handler) 

	CREATE TABLE #ClientGroupName 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #ClientGroupName
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @ClientGroupName) 

	SELECT fileID, tskDesc, tskDue, tskCompleted 
	INTO #FICProcess
	FROM MS_Prod.dbo.dbTasks
	WHERE (tskDesc LIKE 'FIC Process'
	OR tskDesc LIKE '%ADM: Complete fraud indicator checklist%')
	AND tskActive=1

	 SELECT 
		 [Client Code] = dim_matter_header_current.client_code
		 ,[Matter Number]=dim_matter_header_current.matter_number
		 ,[Date Opened] = dim_matter_header_current.date_opened_case_management
		 ,[Matter Description]=dim_matter_header_current.matter_description
		 ,dim_matter_header_current.matter_owner_full_name
		 ,dim_fed_hierarchy_history.hierarchylevel2hist AS Area 
		 ,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
		 ,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
		 ,dim_detail_core_details.suspicion_of_fraud
		 ,referral_reason AS [Referral Reason]
		 ,CASE WHEN date_closed_case_management IS NULL THEN DATEDIFF(DAY, date_opened_case_management,GETDATE())
					ELSE DATEDIFF(DAY,date_opened_case_management, date_closed_case_management) END AS [Days Opened]

		 ,fic =	 total_points_calc 

		 ,dim_detail_fraud.el_points AS FRA130
		 ,dim_detail_fraud.pl_points AS FRA131
		 ,dim_detail_fraud.motor_freight_liveried_points AS FRA133
		 ,dim_detail_fraud.motor_personal_line_insurance_points AS FRA134
		 ,dim_detail_fraud.disease_points AS FRA135
		 ,dim_detail_fraud.rmg_el_points AS FRA137
		 ,dim_detail_fraud.rmg_pl_points AS FRA129
		 ,fic_fraud_transfer_date [fic_review_date]
		 ,fic_fraud_transfer [fic_revew]
		 ,date_received 
		 ,date_intel_report_sent
		 ,FICProcess.tskDue
		 ,FICProcess.tskCompleted
		 ,FICProcess.tskDesc
		 ,ms_fileid
		 ,work_type_group
		 ,ISNULL(client_group_name, client_name) AS [Client Group Name]
		 		,dim_detail_core_details.[fixed_fee] AS [Fixed Fee]
		,ISNULL(fact_finance_summary.[fixed_fee_amount], 0) AS [Fixed Fee Amount]
		,RTRIM(ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0)) AS [Fee Arrangement]
		,fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
		,CASE WHEN FICProcess.tskDue IS NULL THEN 1 ELSE 0 END AS [CountNoprocessdue]
	  
		,CASE WHEN FICProcess.tskDue IS NOT NULL AND FICProcess.tskCompleted IS NULL THEN 1 ELSE 0 END AS [countcompleteddate]
		,CASE WHEN FICProcess.tskCompleted IS NOT NULL AND dim_detail_fraud.total_points_calc IS NULL THEN 1 ELSE 0 END AS [countblankscore]
		,CASE WHEN FICProcess.tskCompleted IS NOT NULL AND dim_detail_fraud.total_points_calc < 15 THEN 1 ELSE 0 END AS [countless15]
		,CASE WHEN FICProcess.tskCompleted IS NOT NULL AND dim_detail_fraud.total_points_calc > 15 THEN 1 ELSE 0 END AS [countmore15]
	
		, CASE WHEN (dim_matter_header_current.fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee ' AND ISNULL(fact_finance_summary.fixed_fee_amount, 0) = 0  ) OR (ISNULL(fact_finance_summary.defence_costs_reserve,0) = 0 ) THEN 1 ELSE 0
		END AS [countfixeddefence]

	FROM 
	red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key  
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'        
	AND GETDATE() BETWEEN dss_start_date AND dss_end_date 
	AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON fact_dimension_main.dim_detail_outcome_key = dim_detail_outcome.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw..dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
	LEFT OUTER JOIN red_dw..dim_detail_core_details ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

	--LEFT OUTER JOIN (SELECT fileID, tskDesc, tskCompleted 
	--			FROM MS_Prod.dbo.dbTasks
	--			WHERE tskDesc LIKE 'FIC Process'
	--			AND tskCompleted IS NOT NULL 
	--			AND tskActive=1) AS FICProcess ON FICProcess.fileID=ms_fileid


	INNER JOIN #Department AS Department ON Department.ListValue = hierarchylevel3hist 
	INNER JOIN #Team AS Team ON Team.ListValue = hierarchylevel4hist 
	INNER JOIN #Handler AS Handler ON Handler.ListValue = matter_owner_full_name 
	INNER JOIN #ClientGroupName AS ClientGroupName ON ClientGroupName.ListValue = ISNULL(client_group_name, client_name) 
	
	LEFT OUTER JOIN #FICProcess FICProcess ON FICProcess.fileID = ms_fileid

	WHERE 
		--dim_matter_header_current.date_closed_case_management IS NULL
	 dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
		--AND dim_detail_outcome.date_claim_concluded IS NULL

		AND LOWER(referral_reason) LIKE '%dispute%'
		--AND suspicion_of_fraud ='No'
		AND work_type_group IN ('EL','PL All','Motor','Disease')

		--AND fic_fraud_transfer='Yes'
		-- fic score
		--AND CASE WHEN 
		--	ISNULL(dim_detail_fraud.el_points,0)  
		--	+ ISNULL(dim_detail_fraud.pl_points,0)
		--	+ ISNULL(dim_detail_fraud.motor_freight_liveried_points,0)
		--	+ ISNULL(dim_detail_fraud.motor_personal_line_insurance_points,0)
		--	+ ISNULL(dim_detail_fraud.disease_points,0)
		--	 > 14 
	 -- 	 OR ISNULL(dim_detail_fraud.rmg_el_points,0) > 5 
		-- OR ISNULL(dim_detail_fraud.rmg_pl_points,0) > 5
		-- THEN 1 ELSE 0 END =1
		
		--test examples
		 --AND fact_dimension_main.client_code='Z1001'
		 --AND fact_dimension_main.matter_number='00078456'
		 
		 --AND fact_dimension_main.client_code='N12105'
		 --AND fact_dimension_main.matter_number='00000627'

		 --AND ms_fileid='5070040'

		 --aborted process logic below
		--AND CASE WHEN (dim_detail_fraud.el_points > 15 AND dim_detail_fraud.fic_el  <> '26.00')
		--		OR (dim_detail_fraud.pl_points > 15 AND dim_detail_fraud.fic_pl  <> '22.00')
		--		OR (dim_detail_fraud.motor_self_drive_points >15 AND dim_detail_fraud.fic_selfdrive <> '13.00')
		--		OR (dim_detail_fraud.motor_freight_liveried_points > 15 AND dim_detail_fraud.fic_freight <> '13.00')
		--		OR (dim_detail_fraud.motor_personal_line_insurance_points >15 AND dim_detail_fraud.fic_pli <> '13.00')
		--		OR (dim_detail_fraud.disease_points  > 5 AND dim_detail_fraud.fic_disease <> '34.00')
		--		OR (dim_detail_fraud.rmg_el_points > 5 AND dim_detail_fraud.fic_rmg_el  <> '63.00')
		--		OR (dim_detail_fraud.rmg_pl_points > 15 AND dim_detail_fraud.fic_rmg_pl <> '63.00') THEN 1 ELSE 0 END = 1

END




--SELECT fileID, tskDesc, tskCompleted,*
--				FROM MS_Prod.dbo.dbTasks
--				WHERE tskDesc LIKE 'FIC Process'
--				AND tskActive=1
GO
