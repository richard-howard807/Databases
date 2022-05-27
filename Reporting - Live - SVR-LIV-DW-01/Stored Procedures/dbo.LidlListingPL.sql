SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-04-01
-- Description:	#141692, new Lidl listing report - pl
-- =============================================
CREATE PROCEDURE [dbo].[LidlListingPL] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		SELECT 
		 dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client / Matter Ref]
		,dim_matter_header_current.matter_description AS [Matter Description]
		,dim_matter_header_current.matter_owner_full_name AS [Case Handler ]
		,dim_client_involvement.insuredclient_reference AS [Insured Client Reference]
		,dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Clients Claims Handler]
		,dim_matter_header_current.date_opened_case_management AS [Date Opened]
		,dim_matter_header_current.date_closed_case_management AS [Date Closed]
		,dim_detail_core_details.[date_instructions_received] AS [Date Instructions Received]
		,dim_detail_core_details.[present_position] AS [Present Position]
		,dim_detail_core_details.[referral_reason] AS [Referral Reason]
		,dim_matter_worktype.work_type_name AS [Matter Type]
		,dim_detail_core_details.[incident_date] AS [Incident Date]
		,dim_detail_core_details.[incident_location] AS [Incident Location]
		,dim_detail_core_details.[incident_location_postcode] AS [Incident Postcode]
		,dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitor]
		,dim_detail_core_details.[track] AS [Track]
		,dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued?]
		,dim_detail_core_details.[date_initial_report_sent] AS [Initial Report Date]
		,dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Subsequent Report Date (most recent)]
		,dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
		,fact_finance_summary.[fixed_fee_amount] AS [Fixed Fee Amount]
		,fact_finance_summary.[damages_reserve] AS [Damages Reserve Current]
		,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [TP Costs Reserve Current]
		,fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve]
		,dim_detail_outcome.[outcome_of_case] AS [Outcome]
		,dim_detail_court.[date_of_trial] AS [Date of Trial - MI]
		,KD_TrialDate.[Trial date] AS [Date of Trial - Key Dates]
		,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
		,fact_finance_summary.[damages_paid] AS [Damages Paid]
		,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
		,fact_finance_summary.[tp_total_costs_claimed] AS [TP Costs Claimed]
		,fact_finance_summary.[claimants_costs_paid] AS [TP Costs Paid]
		,fact_finance_summary.defence_costs_billed AS [Revenue Billed]
		,fact_finance_summary.disbursements_billed AS [Disbursements Billed]
		,CASE WHEN clients_claims_handler_surname_forename LIKE '%,%' THEN 0 ELSE 1 END AS ClientClaimHandlerException
		,DATEDIFF(DAY,date_opened_case_management,GETDATE()) AS DaysOpened
		,DATEDIFF(MONTH,date_opened_case_management,GETDATE()) AS MonthOpened
		,CASE WHEN dim_detail_core_details.referral_reason LIKE '%Disp%' THEN 1 ELSE 0 END AS discase
		,CASE WHEN dim_detail_core_details.referral_reason LIKE '%Disp%' OR dim_detail_core_details.referral_reason LIKE '%Pre-action%' THEN 1 ELSE 0 END AS Prediscase
		,CASE WHEN dim_detail_core_details.present_position ='Claim and costs outstanding' THEN 0 ELSE 1 END AS PPRule
	,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS FileStatus
	,dim_detail_core_details.[brief_details_of_claim]
	,fact_finance_summary.wip
	,fact_finance_summary.[unpaid_bill_balance]
	
	FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
	ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
	ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
	ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
	ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
	ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
	ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
	ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
	ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
	ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

	LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [Trial date]
	FROM ms_prod.dbo.dbTasks WITH(NOLOCK) WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='Trial date - today'
	GROUP BY fileID) AS [KD_TrialDate] ON [KD_TrialDate].fileID=ms_fileid 


	WHERE dim_matter_header_current.reporting_exclusions=0
	AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
	AND (dim_matter_header_current.master_client_code='659' 
		OR (dim_matter_header_current.master_client_code IN ('A1001','A2002','Z1001') AND dim_client_involvement.insuredclient_name LIKE '%Lidl%'))
	AND dim_matter_worktype.work_type_group ='PL All'
	AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2021-01-01')

    
END
GO
