SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- ===============================================
-- Author:		Emily Smith
-- Create date: 2021-03-24
-- Description:	#93185, new report for Chris Ball
-- ================================================
--
-- ================================================
CREATE PROCEDURE [dbo].[CentricaDefenceReport]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Matter Number]
		, dim_matter_header_current.matter_description AS [Matter Description]
		,dim_detail_core_details.present_position [Present Position]
		, dim_matter_header_current.matter_owner_full_name AS [Matter Owner]
		, dim_matter_header_current.date_opened_case_management AS [Date Opened]
		, dim_matter_header_current.date_closed_case_management AS [Date Closed]
		, dim_matter_worktype.work_type_name AS [Matter Type]
		, dim_client_involvement.client_reference AS [Client Ref]
		, dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Client Handler]
		, dim_detail_hire_details.claim_for_hire AS [Credit Hire]
		, dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud]
		, dim_detail_core_details.track AS [Track]
		, fact_finance_summary.damages_reserve AS [Damages Reserve]
		, fact_finance_summary.tp_costs_reserve AS [TP Costs Reserve]
		, fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
		, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
		, dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant Solicitor]
		, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
		, dim_detail_outcome.outcome_of_case AS [Outcome of Claim]
		, fact_finance_summary.damages_paid_to_date AS [Damages Paid]
		, fact_finance_summary.total_tp_costs_paid AS [TP Costs Paid]
		, CASE WHEN dim_detail_outcome.date_claim_concluded IS NOT NULL THEN DATEDIFF(DAY, dim_detail_core_details.date_instructions_received,dim_detail_outcome.date_claim_concluded)
			ELSE NULL END AS [Lifecycle]
			,dim_detail_core_details.[referral_reason]
	FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
	ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
	ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
	ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
	ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
	ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
	ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
	ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

	WHERE dim_matter_header_current.reporting_exclusions=0
	AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
	AND dim_matter_header_current.master_client_code='W15381'
	AND dim_matter_header_current.date_opened_case_management>='2017-01-01'
	AND ISNULL(dim_detail_core_details.referral_reason,'')<>'Recovery'
	AND work_type_name  NOT IN ('Debt Recovery','Contract')--asked to be removed #172622 
	AND dim_matter_header_current.date_closed_case_management IS NULL 
	--AND dim_matter_header_current.master_client_code='W15381' AND master_matter_number='558'

END
GO
