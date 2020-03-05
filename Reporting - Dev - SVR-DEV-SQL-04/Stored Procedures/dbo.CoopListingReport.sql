SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 29-03-2018
-- Description:	Co-op Listing Report, webby 303775
-- =============================================

CREATE PROCEDURE [dbo].[CoopListingReport]

AS
BEGIN

	SET NOCOUNT ON;


SELECT RTRIM(dim_matter_header_current.client_code) +'-'+ dim_matter_header_current.matter_number AS [Weightmans Reference]
		, insurerclient_reference AS [Co-op Reference]
		, dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Co-op Handler]
		, dim_detail_core_details.[coop_client_branch] AS [Client Branch]
		, dim_detail_core_details.[coop_guid_reference_number] AS [GUID]
		, matter_description AS [Case Name]
		, name AS [Fee Earner]
		, hierarchylevel4hist AS [Team]
		, dim_matter_header_current.date_opened_case_management AS [Date Opened]
		, dim_matter_header_current.date_closed_case_management AS [Date Closed]
		, dim_detail_core_details.[present_position] AS [Present Position]
		, instruction_type AS [Instruction Type]
		, work_type_name AS [Work Type]
		, incident_date AS [Date of Accident]
		, COALESCE(claimantsols_name, claimantrep_name) AS [Claimant's Solicitor]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN 'Yes' ELSE dim_detail_core_details.[delegated] END AS [Delegated]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN 'No' ELSE dim_detail_core_details.[suspicion_of_fraud] END AS [Suspicion of Fraud]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN 'No' ELSE dim_detail_core_details.[credit_hire] END AS [Credit Hire]
		, dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued]
		, dim_detail_core_details.[date_proceedings_issued] AS [Date Proceedings Issued]
		, dim_detail_core_details.[track] AS [Track]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN dim_detail_client.[injury] ELSE LTRIM(REPLACE(RTRIM(brief_description_of_injury),RTRIM([injury_type]),'')) END AS [Injury Type]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve_net] END  AS [Damages Reserve (Net)]
		, fact_finance_summary.[damages_reserve] AS [Damages Reserve (Gross)]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_legal_costs_reserve],fact_detail_reserve_detail.[motor_tp_legal_costs_reserve],fact_detail_reserve_detail.[pl_tp_legal_costs_reserve],fact_detail_reserve_detail.[prop_tp_legal_costs_reserve]) ELSE fact_finance_summary.[tp_costs_reserve_net] END AS [TP Cost Reserve (Net)]
		, fact_finance_summary.[tp_costs_reserve] AS [TP Cost Reserve (Gross)]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_own_legal_costs_reserve],fact_detail_reserve_detail.[motor_own_legal_costs_reserve],fact_detail_reserve_detail.[pl_own_legal_costs_reserve],prop_own_legal_costs_reserve) ELSE fact_finance_summary.[defence_costs_reserve_net] END AS [Defence Costs Reserve (Net)]
		, fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve (Gross)]
		, fact_finance_summary.[total_reserve_net] AS [Total Reserve (Net)]
		, fact_finance_summary.[total_reserve] AS [Total Reserve (Gross)]
		, outcome_of_case AS [Outcome]
		, date_claim_concluded AS [Date Claim Concluded]
		, fact_finance_summary.[damages_paid] AS [Damges Paid (inc CRU)]
		, fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] AS [Total Settlement]
		, fact_finance_summary.[tp_total_costs_claimed] AS [TP Costs Claimed]
		, fact_finance_summary.[total_tp_costs_paid] AS [TP Costs Paid]
		, dim_detail_outcome.[date_costs_settled] AS [Date TP Costs Paid]
		, fact_finance_summary.defence_costs_billed AS [Defence Costs Billed to Date]
		, fact_finance_summary.disbursements_billed AS [Disbursements Billed to Date]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN 'Converge' ELSE dim_detail_core_details.[referral_reason] END AS [Referral Reason]
		, dim_matter_group.matter_group_code AS [Matter Group Code]
		, dim_matter_group.matter_group_name AS [Matter Group Name]
		, dim_detail_core_details.[is_this_the_lead_file] AS [Is this the lead file?]
		, dim_detail_core_details.[is_this_a_linked_file] AS [Is this a Linked file?]
		, dim_detail_core_details.[associated_matter_numbers] AS [Associated Matter Numbers]
		, dim_detail_court.[date_of_trial] AS [Trial Date]
		, dim_detail_client.[fee_arrangement] AS [Fee Arrangement]
		, fact_finance_summary.[fixed_fee_amount] AS [Fixed Fee Amount]
		, dim_detail_outcome.[are_we_pursuing_a_recovery] AS [Are we pursing a recovery?]
		, dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
		, dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Date Subsequent Report Sent]
		, fact_detail_paid_detail.[cru_paid_by_all_parties] AS [CRU Paid]
		, fact_detail_paid_detail.[future_care_paid] AS [Future Care Paid]
		, fact_detail_paid_detail.[future_loss_misc_paid] AS [Future Loss Paid]
		, fact_detail_paid_detail.[nhs_charges_paid_by_client] AS [NHS Charges Paid]
		, fact_detail_paid_detail.[past_care_paid] AS [Past Care Paid]
		, fact_detail_paid_detail.[past_loss_of_earnings_paid] AS [Past Loss of Earnings Paid]
		, fact_detail_client.[percent_of_clients_liability_awarded_agreed_post_insts_applied] AS [% Liability Agreed]
		, fact_matter_summary_current.last_bill_date AS [Date of Last Bill]
		, fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting]
		, CASE WHEN RTRIM(LOWER(dim_detail_core_details.[present_position]))='final bill due - claim and costs concluded' AND ISNULL(fact_finance_summary.unpaid_bill_balance,0)>0 THEN 'Closed'
				WHEN RTRIM(LOWER(dim_detail_core_details.[present_position]))='to be closed/minor balances to be clear' THEN 'Closed'
				WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed' ELSE 'Open' END AS [Status]
		, CASE WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)=0 THEN '£0'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=50000 THEN '£1-£50,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=100000 THEN '£50,000-£100,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=250000 THEN '£100,000-£250,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=3000000 THEN '£250,000-£3m'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)>3000000 THEN '>£3m' ELSE '£0' END AS [Damages Banding]
		, CASE WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Exclude from reports' THEN  'Exclude from reports'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Discontinued%'THEN 'Repudiated'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Won at trial%'THEN 'Repudiated'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Struck out%'THEN 'Repudiated'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Settled%'THEN 'Settled'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Lost at trial%'THEN 'Settled'
				WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Assessment of damages%'THEN 'Settled'
				ELSE NULL END [Repudiation - outcome]
		, CASE WHEN dim_matter_worktype.[work_type_name] LIKE '%NHSLA%' THEN 'NHSLA'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN 'PL All'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - Pol%' THEN 'PL Pol'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - OL%' THEN 'PL OL'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Prof Risk%' THEN 'PL All'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'EL %' THEN 'EL'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Motor%' THEN 'Motor'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN 'Disease'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'OI%' THEN 'OI'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'LMT%' THEN 'LMT'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Recovery%' THEN 'Recovery'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Insurance/Costs%' THEN 'Insurance Costs'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Education%' THEN 'Education'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Healthcare%' THEN 'Healthcare'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' THEN 'Other'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Health and %' THEN 'Health and Safety'
					ELSE 'Other'
			END	[Worktype Group]
        , CASE WHEN DATEPART(year, date_claim_concluded) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, date_claim_concluded) = DATEPART(MONTH, GETDATE())-1 THEN 1 ELSE 0 END AS [Concluded in previous month]
		, CASE WHEN DATEPART(year, dim_detail_outcome.[date_costs_settled]) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_detail_outcome.[date_costs_settled]) = DATEPART(MONTH, GETDATE())-1 THEN 1 ELSE 0 END AS [Costs Settled in previous month]
		, fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction] AS [Interim Damages Paid by Client Pre-Instruction]
		, fact_finance_summary.[damages_interims] AS [Damages Interim]
		, dim_detail_claim.[date_recovery_concluded] AS [Date Recovery Concluded]
		, fact_finance_summary.[total_recovery] AS [Total Recovery]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND getdate() BETWEEN dss_start_date AND dss_end_date 
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.client_code = fact_dimension_main.client_code
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_group ON dim_matter_group.dim_matter_group_key = dim_matter_header_current.dim_matter_group_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key=fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.client_code=dim_matter_header_current.client_code AND dim_detail_claim.matter_number=dim_matter_header_current.matter_number 

WHERE dim_client.client_group_name='Co-operative insurance'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management >='2017-01-01')
AND reporting_exclusions=0
AND LOWER(ISNULL(outcome_of_case,''))<>'exclude from reports'
AND dim_matter_header_current.client_code IN ('00046018', 'C1001','C15332','00215267') --this excludes commercial cases
AND LOWER(ISNULL(instruction_type,''))<>'costs only'

AND NOT((dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' OR dim_matter_worktype.[work_type_name] LIKE 'Third Party Capture%') 
AND (fact_matter_summary_current.last_bill_date<='2017-01-01' OR fact_matter_summary_current.[last_time_transaction_date]<='2017-01-01'))
 
AND ((fact_matter_summary_current.last_bill_date>='2017-01-01' OR fact_matter_summary_current.[last_time_transaction_date]>='2017-01-01')
OR (dim_detail_outcome.[date_costs_settled] IS NULL OR dim_detail_outcome.[date_costs_settled]>='2016-10-01')) --Co-op final bill within 90 days

--AND dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' 
--AND dim_matter_header_current.client_code='00046018' AND dim_matter_header_current.matter_number='00061499'



END
GO
