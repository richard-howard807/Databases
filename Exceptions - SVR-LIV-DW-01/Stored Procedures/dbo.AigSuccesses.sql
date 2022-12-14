SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[AigSuccesses]

AS 

BEGIN


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
	, work_type_name AS [Work Type]
	, dim_detail_core_details.[brief_details_of_claim] AS [Brief details of claim]
	, fact_finance_summary.[damages_reserve] AS [Damages Reserve (gross)]
	, fact_detail_reserve_detail.[current_indemnity_reserve] AS [Claimant's Costs Reserve (gross)]
	, dim_detail_outcome.[outcome_of_case] AS [Outcome]
	, dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
	, fact_finance_summary.[damages_paid] AS [Damages Paid by Client]
	, CASE 
		WHEN fact_finance_summary.[damages_reserve] IS NULL OR fact_finance_summary.[damages_reserve]=0 THEN 
			NULL 
		ELSE 
			(ISNULL(fact_finance_summary.[damages_reserve] ,0) - ISNULL(fact_finance_summary.[damages_paid],0))  / fact_finance_summary.[damages_reserve] 
	  END											AS [% Saving against reserve (Damages)]
	, fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid by Client]
	, dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
	, (ISNULL(fact_finance_summary.[damages_reserve],0) + ISNULL(fact_detail_reserve_detail.[current_indemnity_reserve] ,0))
		- (ISNULL(fact_finance_summary.[damages_paid],0) + ISNULL(fact_finance_summary.[claimants_costs_paid],0)) AS [Total Saving on Indemnity Spend]
	, outcome_of_case
	, sector
	, dim_detail_core_details.aig_reference		AS [AIG Reference]
	, dim_detail_core_details.clients_claims_handler_surname_forename		AS [Client Claims Handler]
	, dim_detail_core_details.aig_instructing_office		AS [AIG Instructing Office]
	, dim_instruction_type.instruction_type			AS [AIG Instruction Type]
	, fact_detail_paid_detail.total_settlement_value_of_the_claim_paid_by_all_the_parties		AS [Damages Paid by All Parties]
	, fact_detail_paid_detail.claimants_total_costs_paid_by_all_parties			AS [Claimant Costs Paid by All Parties]
	, dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitor Firm ]
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
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'A2002'
	AND date_claim_concluded BETWEEN  '2021-01-01' AND GETDATE()
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
	----------------------Exclusions--------------------------------------
	AND ISNULL(sector,'') NOT LIKE '%Education%'
	AND ISNULL(sector,'') NOT LIKE '%Emergency Services%'
	AND ISNULL(sector,'') NOT LIKE '%Health%'
	AND ISNULL(sector,'') NOT LIKE '%Local & Central Government%'
	AND ISNULL(insured_sector,'') NOT LIKE '%Ambulance%'
	AND ISNULL(insured_sector,'') NOT LIKE '%Education%'
	AND ISNULL(insured_sector,'') NOT LIKE '%Fire%'
	AND ISNULL(insured_sector,'') NOT LIKE '%Local & Central Government%'
	AND ISNULL(insured_sector,'') NOT LIKE '%Police%'
	AND ISNULL(insured_sector,'') NOT LIKE '%Healthcare%'
	AND ISNULL(insured_sector,'') NOT LIKE '%Social Housing%'
	AND ISNULL(insured_sector, '') NOT LIKE '%Societies/political/religious%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%Council%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%Borough%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%MBC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%LBC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%CC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%BC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%DC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%Police%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%Constab%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%Fire%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%Health%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%NHS%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%School%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%University%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%College%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.client_name,'') NOT LIKE '%Housing%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%Council%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%Borough%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%MBC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%LBC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%CC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%BC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%DC%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%Police%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%Constab%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%Fire%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%Health%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%NHS%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%School%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%University%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%College%'
	AND ISNULL(red_dw.dbo.dim_matter_header_current.matter_description,'') NOT LIKE '%Housing%'
	AND ISNULL(outcome_of_case,'')<>'Returned to Client'
ORDER BY
	[Date Claim Concluded]

END 
GO
