SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-07-05
-- Description:	#156002 - new client report for Tokio Marine HCC (TMHCC)
-- =============================================
CREATE PROCEDURE [dbo].[TMHCCClaimsReport]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT  dim_client_involvement.insurerclient_reference AS [Tokio Marine HCC Reference]
	, dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Solicitors Reference]
	, dim_matter_header_current.matter_owner_full_name AS [Fee Earner]
	, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management) AS [Instructions Date]
	, dim_client_involvement.insuredclient_name AS [Insured name]
	, dim_claimant_thirdparty_involvement.claimant_name AS [Claimant name]
	, dim_detail_core_details.incident_date AS [Loss Date]
	, dim_detail_core_details.brief_details_of_claim AS [Brief Description of Accident Circumstances]
	, dim_detail_core_details.injury_type AS [Brief Description of Injury]
	, fact_finance_summary.[damages_paid_to_date] AS [Incurred/Paid to Date:Total Damages (include Interim Payments)]
	, fact_finance_summary.[total_tp_costs_paid_to_date] AS [Paid to Date: Claimant Costs (inc Disbs and VAT)]
	, Payor.[Billed to Tokio] AS [Defence fees invoiced to date:(include Disbs & VAT if paid by Tokio Marine HCC)]
	, fact_finance_summary.[damages_reserve_net] AS [Ongoing Reserve: Damages (Outstanding Total After Deduction of Damages Agreed/Incurred)]
	, fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net] AS [Ongoing reserve: Claimant costs(Outstanding Total after Deduction of Claimant Costs Agreed/Incurred)]
	, CASE WHEN dim_detail_core_details.[present_position] IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 0
		ELSE ISNULL(fact_finance_summary.[defence_costs_reserve],0)-ISNULL(Payor.[Billed to Tokio],0) END  AS [Ongoing reserve: Defence fees]--(Net Amount after Deduction of Defence Fees  Invoiced, include Disbs & VAT if paid by Tokio Marine HCC)]
	, ISNULL(fact_finance_summary.[damages_paid_to_date],0) +
	ISNULL(fact_finance_summary.[total_tp_costs_paid_to_date],0) +
	ISNULL(Payor.[Billed to Tokio],0) +
	ISNULL(fact_finance_summary.[damages_reserve_net],0) +
	ISNULL(fact_detail_reserve_detail.[current_claimant_solicitors_costs_reserve_net],0) +
	ISNULL(CASE WHEN dim_detail_core_details.[present_position] IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 0
		ELSE ISNULL(fact_finance_summary.[defence_costs_reserve],0)-ISNULL(Payor.[Billed to Tokio],0) END,0)
	AS [Total incurred:]
	, dim_detail_court.[date_of_trial] AS [Trial/Proof Date (if set)]
	, CASE WHEN dim_detail_core_details.[present_position] IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') THEN 'Closed'
		WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed' ELSE 'Open' END AS [Open/Closed]
--internal
	, dim_detail_core_details.referral_reason AS [Referral Reason]
	, dim_detail_core_details.present_position AS [Present Position]
	, fact_matter_summary_current.last_bill_date AS [Last Bill Date]
	, dim_detail_outcome.outcome_of_case AS [Outcome]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
	, dim_matter_header_current.date_closed_case_management AS [Date Closed]
	, fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant Costs Reserve]
	, fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve]
	, fact_finance_summary.[damages_paid] AS [Damages Paid]
	, fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid]
	, fact_finance_summary.[claimants_total_costs_paid_by_all_parties] AS [Claimant's Total Costs Paid by all Parties]
	, fact_finance_summary.[other_defendants_costs_paid] AS [Other Defendants Costs Paid]
	, fact_finance_summary.total_savings_damages_and_costs AS [Total Savings Damages and Costs]
	, fact_finance_summary.[interlocutory_costs_paid_to_claimant] AS [Interlocutory Costs Paid to Claimant]
	, fact_finance_summary.[detailed_assessment_costs_paid] AS [Detailed Assessment Costs Paid]
	, fact_finance_summary.damages_interims AS [Damages Interims]
	, fact_detail_paid_detail.[interim_costs_payments] AS [Interim Costs Payments]
	, fact_detail_paid_detail.[interim_costs_payments_by_client_pre_instruction] AS [Interim Costs Payments by Client Pre-Instruction]
	

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_detail_core_details.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN (SELECT dim_matter_header_current.dim_matter_header_curr_key
				, master_client_code + '-' + master_matter_number AS [Reference]
				,SUM(ARAmt) AS [Total Billed]
				,SUM(CASE WHEN Payor.DisplayName LIKE '%Tokio Marine%' THEN ARAmt ELSE 0 END) AS [Billed to Tokio]
				FROM red_dw.dbo.dim_matter_header_current
				INNER JOIN ms_prod.config.dbFile
				 ON ms_fileid=fileID
				INNER JOIN TE_3E_Prod.dbo.Matter
				 ON fileExtLinkID=MattIndex
				INNER JOIN TE_3E_Prod.dbo.InvMaster
				 ON MattIndex=LeadMatter
				INNER JOIN TE_3E_Prod.dbo.ARDetail
				 ON InvIndex=InvMaster
				LEFT OUTER JOIN  TE_3E_Prod.dbo.Payor
				 ON TE_3E_Prod.dbo.ARDetail.Payor=PayorIndex
				LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
				 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
				WHERE dim_matter_header_current.reporting_exclusions=0
				AND dim_matter_header_current.client_group_code='00000054'
				AND dim_matter_worktype.work_type_group IN ('EL', 'PL All', 'Disease', 'Motor')
				AND IsReversed=0
				AND InvNumber<>'PURGE'
				AND ARList  IN ('Bill','BillRev')
				GROUP BY dim_matter_header_current.dim_matter_header_curr_key, master_client_code + '-' + master_matter_number) AS [Payor]
				ON Payor.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND dim_matter_header_current.client_group_code='00000054'
AND dim_matter_worktype.work_type_group IN ('EL', 'PL All', 'Disease', 'Motor')
AND (((dim_matter_header_current.date_closed_case_management is NULL OR dim_matter_header_current.date_closed_case_management>='2022-01-01')
OR (dim_detail_core_details.[present_position] IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') AND fact_matter_summary_current.last_bill_date>='2022-01-01')))


END
GO
