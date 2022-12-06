SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-12-06
-- Description:	Initial create - #181751
-- =============================================

CREATE PROCEDURE [dbo].[predict_volume_report] --EXEC [dbo].[predict_volume_report]

AS

BEGIN

DROP TABLE IF EXISTS #pv_usage

SELECT 
	dbFile.fileID
	, SUM(IIF(udMICurrentReserves.bitMLAccessed = 1, 1, 0))		AS ml_launched
	, SUM(IIF(udMICurrentReserves.bitMLDataUsed = 1, 1, 0))		AS ml_data_used
	--, event_person.usrFullName		AS event_user
	--, MS_Prod.dbo.UTCToLocalTime(dbFileEvents.evWhen)		AS event_date
INTO #pv_usage
FROM MS_Prod.config.dbClient
	INNER JOIN MS_Prod.config.dbFile
		ON dbFile.clID = dbClient.clID
	INNER JOIN MS_Prod.dbo.udMICurrentReserves
		ON udMICurrentReserves.fileID = dbFile.fileID
	LEFT OUTER JOIN MS_Prod.dbo.dbFileEvents
		ON dbFileEvents.fileID = dbFile.fileID
	--INNER JOIN MS_Prod.dbo.dbUser AS event_person
	--	ON event_person.usrID = dbFileEvents.evusrID
WHERE
	udMICurrentReserves.bitMLAccessed = 1
	AND dbClient.clNo <> '30645'
	AND dbFileEvents.evType = 'MATTERLAB'
	AND MS_Prod.dbo.UTCToLocalTime(dbFileEvents.evWhen) >= '2022-11-14'
GROUP BY
	dbFile.fileID





SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Client/Matter Number]
	, dim_matter_header_current.matter_description		AS [Matter Description]
	, dim_client.client_name			AS [Client Name]
	, dim_client.client_group_name		AS [Client Group Name]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)		AS [Date Opened]
	, dim_fed_hierarchy_history.name				AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist			AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist		AS [Department]
	, dim_matter_worktype.work_type_name		AS [Matter Type]
	, dim_matter_worktype.work_type_group		AS [Matter Group]
	, dim_detail_core_details.present_position		AS [Present Position]
	, dim_detail_core_details.referral_reason		AS [Referral Reason]
	, dim_detail_core_details.does_claimant_have_personal_injury_claim		AS [Does Claimant Have Personal Injury Claim]
	, dim_detail_core_details.suspicion_of_fraud		AS [Suspicion of Fraud]
	, dim_matter_header_current.fee_arrangement			AS [Fee Arrangement]
	, dim_detail_core_details.method_of_claimants_funding		AS [Method of Claimant's Funding]
	, fact_finance_summary.damages_reserve		AS [Damages Reserve (Current)]
	, CASE
		WHEN LOWER(RTRIM(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN	
			fact_detail_reserve_detail.net_defence_costs_reserve		
		ELSE
			NULL
	  END										AS [Defence Costs Reserve (Current)]
	, CASE	
		WHEN dim_detail_core_details.method_of_claimants_funding = 'FRC' THEN
			NULL
		ELSE	
			fact_detail_reserve_detail.claimant_costs_reserve_current		
	  END									AS [Claimant's Costs Reserve (Current)]
	, dim_detail_outcome.outcome_of_case		AS [Outcome of Case]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)			AS [Date Claim Concluded]
	, fact_finance_summary.damages_paid		AS [Damages Paid by Client]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)			AS [Date Costs Settled]
	, CASE	
		WHEN dim_detail_core_details.method_of_claimants_funding = 'FRC' THEN
			NULL
		ELSE	
			fact_finance_summary.claimants_costs_paid		
	  END										AS [Claimant's (Total) Costs Paid by Client]
	, CASE
		WHEN LOWER(RTRIM(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN
			fact_finance_summary.total_amount_billed		
		ELSE 
			NULL
	  END												AS [Total Billed]
	, IIF(ISNULL(dim_detail_outcome.date_claim_concluded, '2022-11-14') >= '2022-11-14' , 'pilot', 'benchmark')	AS pilot_scheme
	, pv_usage.ml_launched
	, pv_usage.ml_data_used
	, CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NULL THEN
			NULL
		WHEN ISNULL(dim_detail_core_details.date_instructions_received, '9999-12-31') < dim_matter_header_current.date_opened_case_management THEN	
			DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)
		ELSE	
			DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_outcome.date_claim_concluded)
	  END			AS lifecycle
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN red_dw.dbo.dim_client
		ON dim_client.client_code = dim_matter_header_current.client_code
	INNER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #pv_usage AS pv_usage
			ON pv_usage.fileID = dim_matter_header_current.ms_fileid
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.client_code NOT IN ('00030645', '95000C', '00453737')
	AND dim_matter_header_current.matter_number <> 'ML'
	AND dim_detail_core_details.referral_reason LIKE 'Dispute %'
	AND (pv_usage.fileID IS NOT NULL
		OR 
		ISNULL(dim_detail_core_details.suspicion_of_fraud, '') <> 'Yes'
		AND dim_detail_outcome.date_claim_concluded >= '2021-05-01'
		AND dim_matter_worktype.work_type_group IN ('EL', 'PL All', 'Motor')
		AND dim_fed_hierarchy_history.hierarchylevel3hist IN ('Motor', 'Casualty')
		AND dim_matter_worktype.work_type_name NOT LIKE 'PL % Pol %'
		AND ISNULL(fact_finance_summary.damages_reserve, 0) BETWEEN 0 AND 350000
		AND LOWER(RTRIM(dim_client.client_group_name)) IN 
			(
				N'ageas'
				, N'aig'
				, N'allianz'
				, N'amtrust europe ltd'
				, N'premia uk services company'
				, N'aviva'
				, N'axa xl'
				, N'bibby group'
				, N'co-operative group'
				, N'coris uk limited'
				, N'covea insurance plc'
				, N'crawford & co'
				, N'crawford & co (broadspire)'
				, N'dhl'
				, N'direct commercial limited'
				, N'direct commercial ltd'
				, N'first central insurance management limited'
				, N'hdi'
				, N'jcb'
				, N'liberty insurance limited'
				, N'quest'
				, N'markel'
				, N'sabre'
				, N'sedgwick group'
				, N'cunnigham lindsay'
				, N'vericlaim'
				, N'tradex'
				, N'zurich'
			)
		AND LOWER(RTRIM(dim_client.client_type)) IN 
			(
				N'charity'
				, N'court'
				, N'insurance company'
				, N'insurer'
				, N'joint'
				, N'llp'
				, N'law firm'
				, N'limited company'
				, N'organisation'
				, N'partnership'
				, N'solicitor'
				, N'trust'
			)
		)


END

GO
