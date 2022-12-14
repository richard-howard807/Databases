SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Emily Smith
-- Create date: 15/09/2022
-- Description:	#166433 New Markerstudy Dashboards
-- =============================================

-- =============================================

CREATE PROCEDURE [dbo].[MarkerstudyDashboards]

AS
BEGIN

	SET NOCOUNT ON;


SELECT 
	RTRIM(dim_matter_header_current.client_code) +'-'+ dim_matter_header_current.matter_number AS [Weightmans Reference]
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
		, CASE WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'irwin michell%' THEN 'Irwin Mitchell'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'irwin micthell%' THEN 'Irwin Mitchell'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'irwin mitchel%' THEN 'Irwin Mitchell'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'lyons davidson%' THEN 'Lyons Davidson'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'slater gordon%' THEN 'Slater and Gordon'
				WHEN LTRIM(LOWER(COALESCE(claimantsols_name, claimantrep_name))) LIKE 'slater and gordon%' THEN 'Slater and Gordon'
				WHEN LTRIM(LOWER(COALESCE(claimantsols_name, claimantrep_name))) LIKE 'slater and gordan%' THEN 'Slater and Gordon'
				WHEN LTRIM(LOWER(COALESCE(claimantsols_name, claimantrep_name))) LIKE 'slater & gordon%' THEN 'Slater and Gordon'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'carpenters%' THEN 'Carpenters'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'minster law%' THEN 'Minster Law LTD'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'true solicitors%' THEN 'True Solicitors LLP'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'asons solicitors%' THEN 'Asons Solicitors'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'winn solicitors%' THEN 'Winn Solicitors'
				WHEN LOWER(COALESCE(claimantsols_name, claimantrep_name)) LIKE 'thompsons%' THEN 'Thompsons Solicitors'
				ELSE COALESCE(claimantsols_name, claimantrep_name)
			END AS [Claimant's Solicitor] --dst_claimant_solicitor_firm,
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
				, CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_own_legal_costs_reserve],fact_detail_reserve_detail.[motor_own_legal_costs_reserve],fact_detail_reserve_detail.[pl_own_legal_costs_reserve],prop_own_legal_costs_reserve) 
			WHEN dim_detail_core_details.[present_position] ='Claim and costs concluded but recovery outstanding' THEN 0 ELSE fact_finance_summary.[defence_costs_reserve_net] END AS [Defence Costs Reserve (Net)]
		, CASE WHEN dim_detail_core_details.[present_position] ='Claim and costs concluded but recovery outstanding' THEN 0 ELSE fact_finance_summary.[defence_costs_reserve] END AS [Defence Costs Reserve (Gross)]
		, fact_finance_summary.[total_reserve_net] AS [Total Reserve (Net)]
		, fact_finance_summary.[total_reserve] AS [Total Reserve (Gross)]
		, outcome_of_case AS [Outcome]
		, date_claim_concluded AS [Date Claim Concluded]
		, fact_finance_summary.[damages_paid] AS [Damges Paid (inc CRU)]
		, COALESCE(fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties],fact_finance_summary.[damages_paid]) AS [Total Settlement]
		, fact_finance_summary.[tp_total_costs_claimed] AS [TP Costs Claimed]
		, fact_finance_summary.[total_tp_costs_paid] AS [TP Costs Paid]
		, dim_detail_outcome.[date_costs_settled] AS [Date TP Costs Paid]
		, fact_finance_summary.defence_costs_billed AS [Defence Costs Billed to Date]
		, fact_finance_summary.disbursements_billed AS [Disbursements Billed to Date]
		, fact_finance_summary.total_amount_billed AS [Total Amount Billed]
		, CASE WHEN LOWER(work_type_name)='claims handling' THEN 'Converge' ELSE dim_detail_core_details.[referral_reason] END AS [Referral Reason]
		, dim_matter_group.matter_group_code AS [Matter Group Code]
		, dim_matter_group.matter_group_name AS [Matter Group Name]
		, dim_detail_core_details.[is_this_the_lead_file] AS [Is this the lead file?]
		, dim_detail_core_details.[is_this_a_linked_file] AS [Is this a Linked file?]
		, dim_detail_core_details.[associated_matter_numbers] AS [Associated Matter Numbers]
		, dim_detail_court.[date_of_trial] AS [Trial Date]
		, dim_matter_header_current.[fee_arrangement] AS [Fee Arrangement]
		, fact_finance_summary.[fixed_fee_amount] AS [Fixed Fee Amount]
		, dim_detail_outcome.[are_we_pursuing_a_recovery] AS [Are we pursing a recovery?]
		, dim_detail_core_details.do_clients_require_an_initial_report AS [Do Clients Require an Initial Report?]
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
		, CASE WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)=0 THEN '??0'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<50000 THEN '??1-??50,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=100000 THEN '??50,000-??100,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=250000 THEN '??100,000-??250,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=500000 THEN '??250,000-??500,000'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=1000000 THEN '??500,000-??1m'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)<=3000000 THEN '??1m-??3m'
				WHEN (CASE WHEN LOWER(work_type_name)='claims handling' THEN COALESCE(fact_detail_reserve_detail.[el_tp_injury_reserve],fact_detail_reserve_detail.[motor_tp_injury_reserve],fact_detail_reserve_detail.[pl_tp_injury_reserve]) ELSE fact_finance_summary.[damages_reserve] END)>3000000 THEN '>??3m' ELSE NULL END AS [Damages Banding]
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
        , CASE WHEN DATEPART(YEAR, date_claim_concluded) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, date_claim_concluded) = DATEPART(MONTH, GETDATE())-1 THEN 1 ELSE 0 END AS [Concluded in previous month]
		, CASE WHEN DATEPART(YEAR, dim_detail_outcome.[date_costs_settled]) = DATEPART(YEAR, GETDATE()) AND DATEPART(MONTH, dim_detail_outcome.[date_costs_settled]) = DATEPART(MONTH, GETDATE())-1 THEN 1 ELSE 0 END AS [Costs Settled in previous month]
		, fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction] AS [Interim Damages Paid by Client Pre-Instruction]
		, fact_finance_summary.[damages_interims] AS [Damages Interim]
		, dim_detail_claim.[date_recovery_concluded] AS [Date Recovery Concluded]
		, fact_finance_summary.[total_recovery] AS [Total Recovery]
		, dim_detail_core_details.[coop_target_settlement_date] AS [Target Settlement Date]
		, DATEDIFF(DAY, dim_detail_core_details.[coop_target_settlement_date], date_claim_concluded) AS [Target Settlement Days]
		, dim_detail_core_details.incident_location_postcode AS [Incident Location Postcode]
		, ClaimantsAddress.[claimant1_postcode] AS [Claimant's Postcode]
		, DATEDIFF(DAY, date_claim_concluded, dim_detail_outcome.[date_costs_settled]) AS [Costs Lifecycle]
		, CASE WHEN dim_detail_core_details.[present_position]='Claim and costs outstanding' THEN 'Damages Outstanding'
				WHEN dim_detail_core_details.[present_position]='Claim concluded but costs outstanding' THEN 'Costs Outstanding'
				WHEN dim_detail_core_details.[present_position]='Claim and costs concluded but recovery outstanding' THEN 'Recovery'
				WHEN dim_detail_core_details.[present_position]='Final bill due - claim and costs concluded' THEN 'Final Bill'
				WHEN dim_detail_core_details.[present_position]='Final bill sent - unpaid' THEN 'Final Bill'
				WHEN dim_detail_core_details.[present_position]='To be closed/minor balances to be clear' THEN 'Closed' ELSE dim_detail_core_details.[present_position] END AS [Present Position Group]
		-- 10/07/2018 Added LD
		--,[first_date_subsequent_sla_report_sent]
		,prev.prev_date_subsequent_sla_report_sent  [prev_date_subsequent_sla_report _sent]
		, dim_claimant_address.postcode as [Claimant Postcode]
		, Doogal.Longitude AS [Claimant Longitude]
		, Doogal.Latitude AS [Claimant Latitude]
		, dim_detail_outcome.[date_costs_settled]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays](COALESCE(dim_matter_header_current.date_opened_case_management,date_instructions_received ),dim_detail_core_details.[date_initial_report_sent]) AS [Days to Initial Report]
		, CASE WHEN LOWER(outcome_of_case) LIKE 'assessment of damages%' THEN 'Settled'
			WHEN LOWER(outcome_of_case) LIKE 'discontinued - indemnified by third party%' THEN 'Discontinued - pre-lit'
			WHEN LOWER(outcome_of_case) LIKE 'discontinued - post-lit%' THEN 'Discontinued - post-lit'
			WHEN LOWER(outcome_of_case) LIKE 'settled%' THEN 'Settled' ELSE outcome_of_case END AS [Outcome group]
		, dim_detail_outcome.[ll00_settlement_basis] AS [Settlement Basis]
		, CASE 	WHEN fact_finance_summary.[damages_paid]<=0 THEN '??0'
				WHEN fact_finance_summary.[damages_paid]<=50000 THEN '<??50,000'
				WHEN fact_finance_summary.[damages_paid]<=100000 THEN '??50,000-??100,000'
				WHEN fact_finance_summary.[damages_paid]<=250000 THEN '??100,000-??250,000'
				WHEN fact_finance_summary.[damages_paid]<=500000 THEN '??250,000-??500,000'
				WHEN fact_finance_summary.[damages_paid]<=1000000 THEN '??500,000-??1m'
				WHEN fact_finance_summary.[damages_paid]<=3000000 THEN '??1m-??3m'
				WHEN fact_finance_summary.[damages_paid]>3000000 THEN '>??3m' ELSE NULL END AS [Damages Paid Banding]
		, chargeable_minutes_recorded/60 AS [Hours Recorded]
		--15/01/2019 Added the below Future Loss of earnings for Christa
		,[future_loss_of_earnings_paid] --fact_detail_paid_detail[future_loss_of_earnings_paid]
		--06/02/2019 added large loss paid fields
		, ISNULL(fact_detail_paid_detail.[general_damages_paid_hundred_percent],0) --NMI219
		+ ISNULL(fact_detail_paid_detail.[interest_on_generals_paid_hundred_percent],0) --NMI220
			AS [General Damages]
		, ISNULL(fact_detail_paid_detail.[net_wage_loss_paid_hundred_percent],0) --NMI221
		+ ISNULL(fact_detail_paid_detail.[misc_specials_paid_hundred_percent],0) --NMI222
		+ ISNULL(fact_detail_paid_detail.[medical_physio_paid_hundred_percent],0) --NMI237
		+ ISNULL(fact_detail_paid_detail.[care_costs_paid_hundred_percent],0) --NMI224
		+ ISNULL(fact_detail_paid_detail.[aids_equipment_paid_hundred_percent],0) --NMI225
		+ ISNULL(fact_detail_paid_detail.[other_housing_etc_paid_hundred_percent],0) --NMI226
		+ ISNULL(fact_detail_paid_detail.[interest_on_specials_paid_hundred_percent],0) --NMI227
			AS [Past Losses]
		, ISNULL(fact_detail_paid_detail.[future_loss_of_wages_paid_hundred_percent],0) --NMI228
		+ ISNULL(fact_detail_paid_detail.[s_v_m_award_paid_hundred_percent],0) --NMI229
		+ ISNULL(fact_detail_paid_detail.[pension_loss_paid_hundred_percent],0) --NMI239
		    AS [Future Earnings]
		, fact_detail_paid_detail.[future_care_paid_hundred_percent] --NMI230
			AS [Future Care]
		, fact_detail_paid_detail.[future_aids_equipment_paid_hundred_percent] --NMI231
			AS [Future Aids & Equip.]
		, ISNULL(fact_detail_paid_detail.[domestic_diy_paid_hundred_percent],0) --NMI232
		+ ISNULL(fact_detail_paid_detail.[holidays_paid_hundred_percent],0) --NMI233
			AS [Future Misc]
		, fact_detail_paid_detail.[future_case_manager_paid_hundred_percent] --NMI234
			 AS [Future Case Manager]
		, ISNULL(fact_detail_paid_detail.[housing_paid_hundred_percent],0) --NMI235
		+ ISNULL(fact_detail_paid_detail.[housing_alterations_paid_hundred_percent],0) --NMI236
			as [Future Accomodation]
		, fact_detail_paid_detail.[medical_physio_paid_hundred_percent] --NMI237
			as [Future Medical/Physio]
		, fact_detail_paid_detail.[transport_paid_hundred_percent] --NMI238
			AS [Future Transport]
		, fact_detail_paid_detail.[court_of_protection_paid_hundred_percent] --NMI240
			as [Future C of P]
		, ms_only
		,red_dw.dbo.dim_detail_core_details.date_instructions_received
			,CASE WHEN DATEPART(mm,dim_detail_core_details.date_proceedings_issued)<=3 THEN 'Qtr1'
	WHEN DATEPART(mm,dim_detail_core_details.date_proceedings_issued)<=6 THEN 'Qtr2'
	WHEN DATEPART(mm,dim_detail_core_details.date_proceedings_issued)<=9 THEN 'Qtr3'
	WHEN DATEPART(mm,dim_detail_core_details.date_proceedings_issued)<=12 THEN 'Qtr4'
	ELSE NULL END AS [Calendar Quarter Proceedings Issued]
	,CAST(YEAR(dim_detail_core_details.date_proceedings_issued) as char(4)) + ' Q' + CAST(DATEPART(QUARTER,dim_detail_core_details.date_proceedings_issued) as char(1)) QuarterUniqueName
	 ,CASE when
           date.cal_quarter IN ( '201601', '201602', '201603', '201604')
		   --AND dim_detail_core_details.date_proceedings_issued>=dim_detail_core_details.date_instructions_received
		   THEN	 1
           ELSE
               0
       END AS ProceedingsIsuued_2016
	    ,CASE when
           date.cal_quarter IN ( '201701', '201702', '201703', '201704')
		   --AND dim_detail_core_details.date_proceedings_issued>=dim_detail_core_details.date_instructions_received
		   THEN	 1
           ELSE
               0
       END AS ProceedingsIsuued_2017 ,CASE when
           date.cal_quarter IN ( '201801', '201802', '201803', '201804')
		   --AND dim_detail_core_details.date_proceedings_issued>=dim_detail_core_details.date_instructions_received
		   THEN	 1
           ELSE
               0
       END AS ProceedingsIsuued_2018
	   ,CASE when
           date.cal_quarter IN ( '201901', '201902', '201903', '201904')
		   --AND dim_detail_core_details.date_proceedings_issued>=dim_detail_core_details.date_instructions_received
		   THEN	 1
           ELSE
               0
       END AS ProceedingsIsuued_2019
	   ,CASE when
           date.cal_quarter IN ( '202001', '202002', '202003', '202004')
		   --AND dim_detail_core_details.date_proceedings_issued>=dim_detail_core_details.date_instructions_received
		   THEN	 1
           ELSE
               0
       END AS ProceedingsIsuued_2020
	   ,CASE when
           date.cal_quarter IN ( '202101', '202102', '202103', '202104')
		   --AND dim_detail_core_details.date_proceedings_issued>=dim_detail_core_details.date_instructions_received
		   THEN	 1
           ELSE
               0
       END AS ProceedingsIsuued_2021
	     ,CASE when
           date.cal_quarter IN ( '202201', '202202', '202203', '202204')
		   --AND dim_detail_core_details.date_proceedings_issued>=dim_detail_core_details.date_instructions_received
		   THEN	 1
           ELSE
               0
       END AS ProceedingsIsuued_2022
	   ,CASE WHEN ISNULL(dim_detail_core_details.proceedings_issued,'')='Yes' THEN 'Litigated'  ELSE 'Pre-lit'  END AS Litigation
       ,CASE WHEN ISNULL(dim_detail_core_details.proceedings_issued,'')='Yes' AND dim_detail_core_details.date_proceedings_issued >date_instructions_received THEN 'Litigated Post Instructions'
	         WHEN ISNULL(dim_detail_core_details.proceedings_issued,'')='Yes' AND dim_detail_core_details.date_proceedings_issued <=date_instructions_received THEN'Litigated Pre Instructions' 
			 WHEN ISNULL(dim_detail_core_details.proceedings_issued,'')='Yes' AND  dim_detail_core_details.date_proceedings_issued IS NULL THEN NULL
			 WHEN ISNULL(dim_detail_core_details.proceedings_issued,'')='No'  THEN 'Pre-Lit'
			  ELSE null 
			 END AS LitigatedType
		,dim_detail_outcome.[date_claim_concluded]
		,dim_detail_claim.msg_limitation_date AS [MSG Limitation Date]
		,dim_detail_outcome.[date_claimants_costs_received] AS [Date Claimants Costs Received]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND GETDATE() BETWEEN dss_start_date AND dss_end_date 
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
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days ON fact_detail_elapsed_days.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN (SELECT fact_dimension_main.master_fact_key [fact_key], 
						dim_client.contact_salutation [claimant1_contact_salutation],
						dim_client.addresse [claimant1_addresse],
						dim_client.address_line_1 [claimant1_address_line_1],
						dim_client.address_line_2 [claimant1_address_line_2],
						dim_client.address_line_3 [claimant1_address_line_3],
						dim_client.address_line_4 [claimant1_address_line_4],
						dim_client.postcode [claimant1_postcode]
				FROM red_dw.dbo.dim_claimant_thirdparty_involvement
				INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
				INNER JOIN red_dw.dbo.dim_involvement_full ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
				INNER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
				WHERE dim_client.dim_client_key != 0 
				and dim_client.client_group_code = '00000004'
				) AS ClaimantsAddress ON fact_dimension_main.master_fact_key=ClaimantsAddress.fact_key


LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details prev ON prev.dim_detail_previous_details_key = fact_dimension_main.dim_detail_previous_details_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_address on dim_claimant_address.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.Doogal ON dim_claimant_address.postcode=Doogal.Postcode

LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care ON fact_detail_future_care.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_date as date ON  CAST(date.calendar_date AS DATE) = CAST(dim_detail_core_details.date_proceedings_issued AS DATE) 

WHERE dim_matter_header_current.master_client_code IN ('C1001','W24438')
AND dim_matter_header_current.reporting_exclusions=0
AND (date_claim_concluded is null OR date_claim_concluded>='2020-01-01')
AND (dim_matter_header_current.date_closed_case_management is null OR dim_matter_header_current.date_closed_case_management>='2020-01-01')
AND (fact_matter_summary_current.last_time_transaction_date IS NULL OR fact_matter_summary_current.last_time_transaction_date>='2020-01-01')
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_detail_core_details.coop_client_branch IN ('Complex Claims Manchester','Markerstudy Multi Track')
AND ISNULL(dim_detail_claim.msg_instruction_type,'') <>'MSG Project 3'
AND ISNULL(dim_matter_worktype.work_type_name,'')<>'PPO Administration'
AND ISNULL(dim_detail_core_details.[referral_reason],'')<>'Advice only'
AND ISNULL(dim_detail_core_details.[referral_reason],'')<>'Costs dispute'
AND dim_fed_hierarchy_history.hierarchylevel4hist<>'Regulatory Core'

END
GO
