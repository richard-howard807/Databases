SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[FraudSuccesses]
(
	@DateFrom DATE,
	@DateTo DATE,
	@Team VARCHAR(MAX),
	@Client VARCHAR(MAX)
)
AS 

BEGIN

SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Client') IS NOT NULL   DROP TABLE #Client

	
	SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit](',', @Team)
	SELECT ListValue  INTO #Client FROM Reporting.dbo.[udt_TallySplit](',', @Client)

SELECT 
	red_dw.dbo.dim_matter_header_current.client_name AS [Client Name]
	, CASE 
		WHEN outcome_of_case LIKE '%Discontinued%' OR outcome_of_case ='Struck out' 
		OR outcome_of_case ='Won at trial' THEN 
			'Claim repudiated' 
		ELSE 
			'% saving against damages reserve is 50% or greater' 
	  END							AS [Success Description]
	, master_client_code + '-' + master_matter_number AS [Mattersphere Weightmans Reference]
	, matter_description AS [Matter Description]
	, insuredclient_name AS [Insured Client Name]
	, insured_sector AS [Insured Sector]
	, dim_fed_hierarchy_history.name AS [Case Manager]
	, hierarchylevel4hist AS [Team]
	, COALESCE(dim_detail_fraud.[fraud_type_motor], dim_detail_fraud.[fraud_type_casualty], dim_detail_fraud.[fraud_type_disease]) AS [Fraud Type]
	, work_type_name AS [Work Type]
	, dim_detail_core_details.[brief_details_of_claim] AS [Brief Details of Claim]
	, fact_finance_summary.[damages_reserve] AS [Damages Reserve (gross)]
	, fact_detail_reserve_detail.[current_indemnity_reserve] AS [Claimant's Costs Reserve (gross)]
	, dim_detail_outcome.[outcome_of_case] AS [Outcome]
	, NULL AS [Finding of FD?]
	, dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
	, fact_finance_summary.[damages_paid] AS [Damages Paid by Client]
	, CASE 
		WHEN fact_finance_summary.[damages_reserve] IS NULL OR fact_finance_summary.[damages_reserve]=0 THEN 
			NULL 
		ELSE 
			(ISNULL(fact_finance_summary.[damages_reserve] ,0) - ISNULL(fact_finance_summary.[damages_paid],0))  / fact_finance_summary.[damages_reserve] 
	  END											AS [% Saving Against Reserve (Damages)]
	, fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid by Client]
	, dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
	, (ISNULL(fact_finance_summary.[damages_reserve],0) + ISNULL(fact_detail_reserve_detail.[current_indemnity_reserve] ,0))
		- (ISNULL(fact_finance_summary.[damages_paid],0) + ISNULL(fact_finance_summary.[claimants_costs_paid],0)) AS [Total Saving on Indemnity Spend]
	, sector AS [Sector]
	, dim_client_involvement.client_reference		AS [Client Reference]
	, dim_detail_core_details.clients_claims_handler_surname_forename		AS [Client Claims Handler]
	, dim_client_involvement.insurerclient_name		AS [Insurer Client Name]
	, dim_instruction_type.instruction_type			AS [Instruction Type]
	, fact_detail_paid_detail.total_settlement_value_of_the_claim_paid_by_all_the_parties		AS [Damages Paid by All Parties]
	, fact_detail_paid_detail.claimants_total_costs_paid_by_all_parties			AS [Claimant Costs Paid by All Parties]
	, dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitor Firm]
	, dim_detail_outcome.[are_we_pursuing_a_recovery] AS [Are we Pursuing a Recovery?]
	, fact_detail_recovery_detail.total_costs_recovered AS [Total Costs Recovered]

FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT 
			AND dss_current_flag='Y'
	INNER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client
		ON dim_client.client_code = dim_matter_header_current.client_code
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number 
	LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
		ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number
	LEFT JOIN red_dw.dbo.dim_detail_claim 
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
		ON fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
		ON dim_detail_fraud.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist
INNER JOIN #Client AS Client ON Client.ListValue COLLATE DATABASE_DEFAULT = ISNULL(dim_matter_header_current.client_group_name, dim_matter_header_current.client_name)


WHERE 1 = 1
	AND dim_matter_header_current.reporting_exclusions=0
	AND dim_detail_core_details.suspicion_of_fraud='Yes'
	--AND date_claim_concluded BETWEEN  '2021-01-01' AND GETDATE()
	AND dim_detail_outcome.date_claim_concluded>=@DateFrom
	AND dim_detail_outcome.date_claim_concluded<=@DateTo
	AND
	(
	outcome_of_case LIKE '%Discontinued%' 
	OR outcome_of_case ='Struck out' 
	OR outcome_of_case ='Won at trial'
	OR CASE 
		WHEN fact_finance_summary.[damages_reserve] IS NULL OR fact_finance_summary.[damages_reserve]=0 THEN 
			NULL 
		ELSE 
			(ISNULL(fact_finance_summary.[damages_reserve] ,0) - ISNULL(fact_finance_summary.[damages_paid],0))  / fact_finance_summary.[damages_reserve] 
	   END >= 0.5
	)
	
	AND ISNULL(outcome_of_case,'')<>'Returned to Client'
	AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from Reports'
ORDER BY
	[Date Claim Concluded]

END 
GO
