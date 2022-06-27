SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-06-15
-- Description: #152584 New report request for Zurich and Sabre for cost rates claimed/paid analysis 
-- =============================================
*/

CREATE PROCEDURE [dbo].[abi_costs_data_collection] 

AS

BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED




DROP TABLE IF EXISTS #assoc_address

SELECT *
INTO #assoc_address
FROM (
		SELECT 
			assoc_unpivot.fileID
			, assoc_unpivot.assocType + '-' + assoc_unpivot.details AS column_name
			, assoc_unpivot.value
		FROM (
				SELECT --TOP 1000
					dbAssociates.fileID
					, dbAssociates.assocType
					, dbContact.contName
					, CAST(dbAddress.addPostcode AS NVARCHAR(80)) AS addPostcode
					--, CONCAT(dbContact.contName, dbAddress.addPostcode)	AS assoc_concat
				FROM MS_Prod.config.dbAssociates
					INNER JOIN MS_Prod.config.dbContact
						ON dbContact.contID = dbAssociates.contID
					INNER JOIN MS_Prod..dbAddress
						ON dbAddress.addID = dbContact.contDefaultAddress
					INNER JOIN MS_Prod.config.dbFile
						ON dbFile.fileID = dbAssociates.fileID
					INNER JOIN MS_Prod.config.dbClient
						ON dbClient.clID = dbFile.clID
				WHERE 1 = 1
					AND dbClient.clNo IN ('W15564', 'Z1001')
					AND dbAssociates.assocType IN ('CLAIMANTSOLS', 'CLAIMANTREP', 'CLAIMANT')
					AND dbAssociates.assocActive = 1
					--AND dbAssociates.fileID = 4769147
			) AS assoc_details
		UNPIVOT
			(
				[value]
				FOR details IN (contName, addPostcode)
			) AS assoc_unpivot
	) AS assoc_details_2
PIVOT
	(
		MAX(value)
		FOR column_name IN ([CLAIMANT-contName], [CLAIMANT-addPostcode], [CLAIMANTSOLS-contName], [CLAIMANTSOLS-addPostcode], [CLAIMANTREP-contName], [CLAIMANTREP-addPostcode])
	) AS assoc_pivot



SELECT 
	'Weightmans LLP'			AS [Panel Firm]
	, dim_client_involvement.insurerclient_reference			AS [Insurer Reference]
	, dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number			AS [Panel Firm Reference]
	, #assoc_address.[CLAIMANTSOLS-contName]					AS [Claimant Solicitor]
	, #assoc_address.[CLAIMANT-addPostcode]					AS [Claimant Solicitor Postcode]
	, ISNULL(fact_finance_summary.damages_paid, 0)				AS [Agreed Damages Amount]
	, ISNULL(fact_finance_summary.tp_total_costs_claimed, 0)			AS [Total Claimant Costs Claimed]
	, ISNULL(fact_finance_summary.claimants_costs_paid, 0)			AS [Claimant Costs Paid]
	, ISNULL(fact_finance_summary.tp_total_costs_claimed, 0) - ISNULL(fact_finance_summary.claimants_costs_paid, 0)		AS [Saving]
	, dim_detail_core_details.proceedings_issued		AS [Litigated Y/N]
	, dim_detail_core_details.will_the_court_require_a_cost_budget			AS [Costs Budget Y/N]
	, dim_matter_worktype.work_type_name				AS [Claim Type]
	, NULL			AS [Office the TP Solicitor is Predominantly Attached to]
	, #assoc_address.[CLAIMANT-addPostcode]			AS [Claimant's Location]
	, fact_detail_claim.grade_a_rate_claimed			AS [Grade A Rate Claimed]
	, fact_detail_claim.grade_b_rate_claimed			AS [Grade B Rate Claimed]
	, fact_detail_claim.grade_c_rate_claimed			AS [Grade C Rate Claimed]
	, fact_detail_claim.grade_d_rate_claimed			AS [Grade D Rate Claimed]
	, fact_detail_claim.grade_a_rate_awarded			AS [Grade A Rate Offered, Agreed or Awarded]
	, fact_detail_claim.grade_b_rate_awarded			AS [Grade B Rate Offered, Agreed or Awarded]
	, fact_detail_claim.grade_c_rate_awarded			AS [Grade C Rate Offered, Agreed or Awarded]
	, fact_detail_claim.grade_d_rate_awarded			AS [Grade D Rate Offered, Agreed or Awarded]
	, dim_detail_outcome.costs_outcome					AS [Nature of the Costs Settlement]
	, dim_detail_core_details.referral_reason
	, dim_detail_core_details.track		AS [Track]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
			AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
	LEFT OUTER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
		ON fact_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #assoc_address
		ON #assoc_address.fileID = dim_matter_header_current.ms_fileid
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code IN ('W15564', 'Z1001')
	AND ISNULL(LOWER(RTRIM(dim_detail_core_details.referral_reason)), '') IN ('costs dispute', 'dispute on liability', 'dispute on quantum', 'dispute on liability and quantum', 'infant approval')
	AND dim_detail_outcome.date_costs_settled >= '2022-01-01'
	AND ISNULL(LOWER(RTRIM(dim_detail_core_details.method_of_claimants_funding)), '') <> 'frc'
	AND ISNULL(LOWER(RTRIM(dim_detail_outcome.outcome_of_case)), '') NOT LIKE 'discontinued%'
	AND ISNULL(LOWER(RTRIM(dim_detail_outcome.outcome_of_case)), '') NOT IN ('exclude from reports', 'returned to client', 'won at trial', 'struck out')
	AND ISNULL(LOWER(RTRIM(dim_detail_outcome.costs_outcome)), '') NOT LIKE 'no order %claimant% costs'
	AND ISNULL(LOWER(RTRIM(dim_detail_outcome.costs_outcome)), '') NOT LIKE 'paid claimant% fixed costs'
	AND ISNULL(LOWER(RTRIM(dim_detail_outcome.global_settlement)), '')	<> 'yes'
	AND ISNULL(dim_employee.locationidud, '') <> 'Glasgow'

END 



GO
