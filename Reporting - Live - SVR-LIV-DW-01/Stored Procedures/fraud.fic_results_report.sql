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

CREATE PROCEDURE [fraud].[fic_results_report]

	@Department varchar(MAX)
	, @Team varchar(MAX)
	, @Handler varchar(MAX)
	
AS
BEGIN
	
	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Handler') IS NOT NULL   DROP TABLE #Handler

	SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)
	SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)
	SELECT ListValue  INTO #Handler FROM 	dbo.udt_TallySplit(',', @Handler)

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
		 ,ms_fileid

	FROM 
	red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key  
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'        
	AND GETDATE() BETWEEN dss_start_date AND dss_end_date 
	AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON fact_dimension_main.dim_detail_outcome_key = dim_detail_outcome.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw..dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
	LEFT OUTER JOIN red_dw..dim_detail_core_details ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key

	--LEFT OUTER JOIN (SELECT fileID, tskDesc, tskCompleted 
	--			FROM MS_Prod.dbo.dbTasks
	--			WHERE tskDesc LIKE 'FIC Process'
	--			AND tskCompleted IS NOT NULL 
	--			AND tskActive=1) AS FICProcess ON FICProcess.fileID=ms_fileid


	INNER JOIN #Department AS Department ON Department.ListValue COLLATE database_default = hierarchylevel3hist COLLATE database_default
	INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = hierarchylevel4hist COLLATE database_default
	INNER JOIN #Handler AS Handler ON Handler.ListValue COLLATE database_default = matter_owner_full_name COLLATE DATABASE_DEFAULT
	
	LEFT OUTER JOIN (SELECT fileID, tskDesc, tskDue, tskCompleted 
				FROM MS_Prod.dbo.dbTasks
				WHERE tskDesc LIKE 'FIC Process'
				AND tskActive=1) AS FICProcess ON FICProcess.fileID=ms_fileid

	WHERE 
		dim_matter_header_current.date_closed_case_management IS NULL
		AND dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management > '2019-01-01'
		AND dim_detail_outcome.date_claim_concluded IS NULL

		AND LOWER(referral_reason) LIKE '%dispute%'
		AND suspicion_of_fraud ='No'

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
