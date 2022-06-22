SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-06-20
-- Description: #152518 proc to be used in the Collingwood dasboard
-- =============================================
*/

CREATE PROCEDURE [dbo].[collingwood_dashboard] 

AS

BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #assoc_details

SELECT *
INTO #assoc_details
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
					, CAST(dbAssociates.assocRef AS NVARCHAR(80))		AS assocRef
					, CAST(dbAddress.addPostcode AS NVARCHAR(80)) AS addPostcode
					--, CONCAT(dbContact.contName, dbAddress.addPostcode)	AS assoc_concat
				--SELECT dbAssociates.*
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
					AND dbClient.clNo IN ('W20218')
					AND dbAssociates.assocType IN ('INSURERCLIENT', 'CLAIMANT', 'CHO')
					AND dbAssociates.assocActive = 1
					--AND dbAssociates.fileID = 4769147
			) AS dbAssociates
		UNPIVOT
			(
				[value]
				FOR details IN (contName, assocRef, addPostcode)
			) AS assoc_unpivot
	) AS assoc_details
PIVOT
	(
		MAX(value)
		FOR column_name IN ([INSURERCLIENT-contName], [INSURERCLIENT-assocRef], [INSURERCLIENT-addPostcode], [CLAIMANT-contName], [CLAIMANT-assocRef], [CLAIMANT-addPostcode]
							, [CHO-contName], [CHO-assocRef], [CHO-addPostcode])
	) AS assoc_pivot




SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number			AS [Weightmans Reference]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)			AS [Date Case Opened]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE)			AS [Date Case Closed]
	, dim_matter_header_current.matter_owner_full_name			AS [Case Manager]
	, dim_matter_worktype.work_type_name			AS [Matter Type]
	, dim_matter_header_current.client_name			AS [Client Name]
	, #assoc_details.[INSURERCLIENT-assocRef]		AS [Insurer Client Reference]
	, dim_detail_core_details.present_position		AS [Present Position]
	, dim_detail_core_details.referral_reason		AS [Referral Reason]
	, dim_detail_core_details.proceedings_issued		AS [Proceedings Issued]
	, dim_detail_core_details.track			AS [Track]
	, dim_detail_core_details.suspicion_of_fraud			AS [Suspicion of Fraud?]
	, dim_detail_core_details.credit_hire			AS [Credit Hire]
	, COALESCE(IIF(dim_detail_hire_details.credit_hire_organisation_cho = 'Other', NULL, dim_detail_hire_details.credit_hire_organisation_cho),dim_detail_hire_details.other,#assoc_details.[CHO-contName])		AS [Credit Hire Organisation]
	, dim_detail_claim.number_of_claimants			AS [Number of Claimants]
	, dim_detail_core_details.does_claimant_have_personal_injury_claim		AS [Does the Claimant have a PI Claim?]
	, dim_detail_core_details.injury_type				AS [Description of Injury]
	, dim_detail_core_details.is_this_a_linked_file			AS [Linked File?]
	, CAST(dim_detail_core_details.incident_date AS DATE)		AS [Incident Date]
	, dim_detail_claim.dst_claimant_solicitor_firm				AS [Claimant's Solicitor]
	, #assoc_details.[CLAIMANT-addPostcode]				AS [Claimant's Postcode]
	, Doogal.Longitude			AS [Claimant - Longitude]
	, Doogal.Latitude			AS [Claimant - Latitude]
	, fact_finance_summary.damages_reserve			AS [Damages Reserve Current]
	, fact_detail_cost_budgeting.hastings_claimant_hire_claimed			AS [Hire Claimed]
	, fact_detail_reserve_detail.claimant_costs_reserve_current		AS [Claimant Costs Reserve Current]
	, fact_finance_summary.defence_costs_reserve			AS [Defence Costs Reserve Current]
	, dim_detail_outcome.outcome_of_case				AS [Outcome of Case]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)		AS [Date Claim Concluded]
	, fact_finance_summary.damages_paid				AS [Damages Paid by Client]
	, fact_detail_paid_detail.personal_injury_paid			AS [Personal Injury Paid]
	, fact_detail_paid_detail.hastings_total_hire_to_be_paid		AS [Hire Paid]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)			AS [Date Costs Settled]
	, fact_finance_summary.tp_total_costs_claimed				AS [Claimant's Total Costs Claimed against Client]
	, fact_finance_summary.claimants_costs_paid				AS [Claimant's Costs Paid by Client]
	, dim_detail_outcome.are_we_pursuing_a_recovery			AS [Are We Pursuing a Recovery?]
	, fact_finance_summary.total_recovery					AS [Total Recovery]
	, fact_finance_summary.total_amount_billed			AS [Total Bill Amount]
	, fact_finance_summary.defence_costs_billed				AS [Revenue Costs Billed]
	, fact_finance_summary.disbursements_billed				AS [Disbursements Billed]
	, fact_finance_summary.vat_billed					AS [VAT Billed]
	, fact_finance_summary.wip						AS [WIP]
	, fact_finance_summary.disbursement_balance			AS [Unbilled Disbursements]
	, CAST(fact_matter_summary_current.last_bill_date AS DATE)			AS [Last Bill Date]
	, CAST(fact_matter_summary_current.last_time_transaction_date AS DATE)		AS [Date of Last Time Posting]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
		ON dim_detail_hire_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
		ON fact_detail_cost_budgeting.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #assoc_details
		ON #assoc_details.fileID = dim_matter_header_current.ms_fileid
	LEFT OUTER JOIN red_dw.dbo.Doogal
		ON red_dw.dbo.Doogal.Postcode = #assoc_details.[CLAIMANT-addPostcode] COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code = 'W20218'
	AND RTRIM(LOWER(ISNULL(dim_detail_outcome.outcome_of_case, ''))) <> 'exclude from reports'

END
GO
