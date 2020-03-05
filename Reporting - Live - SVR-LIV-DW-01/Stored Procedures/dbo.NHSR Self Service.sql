SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<orlagh Kelly >
-- Create date: <2018-10-11>
-- Description:	<NHSR General Data file to be used for all general queries firm wide. ,,>
-- =============================================
CREATE PROCEDURE [dbo].[NHSR Self Service]
AS
BEGIN


    DECLARE @CurrentYear AS DATETIME = '2018-01-01',
            @nDate AS DATETIME = DATEADD(YYYY, -3, GETDATE());



    IF OBJECT_ID('Reporting.dbo.NHSRSelfService') IS NOT NULL
        DROP TABLE dbo.NHSRSelfService;
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here

    SELECT DISTINCT
           dim_matter_header_current.ms_only AS [MS Only],
           RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number AS [Weightmans Reference],
           fact_dimension_main.client_code AS [Client Code],
                                --, dim_matter_header_current.ms_client_code AS [MS Client Code]
           fact_dimension_main.matter_number AS [Matter Number],
           REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') AS [Mattersphere Client Code],
           REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Matter Number],
           REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'
           + REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Weightmans Reference],
           dim_matter_header_current.[matter_description] AS [Matter Description],
                                --, dim_fed_hierarchy_history.[display_name] AS [Case Manager Name]
           dim_fed_hierarchy_history.[name] AS [Case Manager],
           dim_employee.postid AS [Grade],
           CASE
               WHEN dim_fed_hierarchy_history.[leaver] = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS [Leaver?],
           dim_fed_hierarchy_history.[worksforname] AS [Team Manager],
           dim_detail_practice_area.[bcm_name] AS [BCM Name],
           dim_employee.locationidud AS [Office],
           dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team],
           dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department],
           dim_department.[department_code] AS [Department Code],
           dim_fed_hierarchy_history.[hierarchylevel2hist] [Division],
           dim_matter_worktype.[work_type_name] AS [Work Type],
           dim_matter_worktype.[work_type_code] AS [Work Type Code],
           CASE
               WHEN dim_matter_worktype.[work_type_name] LIKE '%NHSLA%' THEN
                   'NHSLA'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN
                   'PL All'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - Pol%' THEN
                   'PL Pol'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'PL - OL%' THEN
                   'PL OL'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Prof Risk%' THEN
                   'Prof Risk'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'EL %' THEN
                   'EL'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Motor%' THEN
                   'Motor'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN
                   'Disease'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'OI%' THEN
                   'OI'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'LMT%' THEN
                   'LMT'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Recovery%' THEN
                   'Recovery'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Insurance/Costs%' THEN
                   'Insurance Costs'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Education%' THEN
                   'Education'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Healthcare%' THEN
                   'Healthcare'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Claims Hand%' THEN
                   'Claims Handling'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'Health and %' THEN
                   'Health and Safety'
               ELSE
                   'Other'
           END [Worktype Group],
           dim_detail_health.[nhs_claim_status] [Claim status],
		   	dim_detail_core_details.[brief_details_of_claim] [Brief Details of Claim], 
           dim_detail_health.[nhs_comments] [Comments],
           dim_detail_health.[nhs_date_of_notification_to_nhsla] [ Date of notification to NHS R],
           dim_detail_claim.[defendant_trust] [ Defendant Trust],
           dim_detail_health.[nhs_location] [NHS Location],
           dim_detail_health.[nhs_scheme] [Scheme],
           dim_detail_health.[nhs_speciality] [Speciality],
           dim_detail_health.[nhs_aig_date_damages_cheque_sent] [Date damages cheque sent],
           dim_detail_health.[nhs_sabre_date_claimants_costs_paid] [Date costs paid],
           dim_detail_health.[nhs_who_dealt_with_costs] AS [Who dealt with  costs?],
           dim_detail_health.[nhs_any_publicity] [Any publicity?],
           dim_detail_health.[nhs_claim_novel_contentious_repercussive] [Claim, novel, contentious, repercussive?],
           dim_detail_health.[nhs_estimated_financial_year_of_settlement] [Estimated financial year of settlement],
           dim_detail_health.[nhs_instruction_type] [NHS Instruction type],
           dim_detail_health.[nhs_probability] [Probability],
           dim_detail_health.[nhs_risk_management_factor] AS [Risk management factor],
           dim_detail_health.[nhs_share] [Share],
           dim_detail_health.[nhs_date_expert_report_sent_to_nhsla] [Date expert report sent to client],
           dim_detail_health.[nhs_date_disclosure_concluded] AS [Date disclosure concluded],
           dim_instruction_type.instruction_type AS [Instruction Type],
           dim_client.client_name AS [Client Name],
           dim_client.client_group_name AS [Client Group Name],
           dim_client.[sector] AS [Client Sector],
           dim_client.segment AS [Client Segment ],
           client_partner_name AS [Client Partner Name],
           dim_client_involvement.[insurerclient_reference] AS [Insurer Client Reference FED],
           dim_client_involvement.[insurerclient_name] AS [Insurer Name FED],
           dim_detail_core_details.clients_claims_handler_surname_forename AS [Clients Claim Handler ],
           dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference FED],
           dim_client_involvement.[insuredclient_name] AS [Insured Client Name FED],
           dim_detail_core_details.insured_sector AS [Insured Sector],
           dim_detail_core_details.[insured_departmentdepot] AS [Insured Department],
           dim_detail_core_details.insured_departmentdepot_postcode AS [Insured Department Depot Postcode],
           dim_matter_header_current.date_opened_case_management AS [Date Case Opened],
           dim_matter_header_current.date_closed_case_management AS [Date Case Closed],
           dim_detail_critical_mi.date_closed AS [Converge Date Closed],
           dim_detail_core_details.present_position AS [Present Position],
                                --dim_detail_critical_mi.claim_status AS [Converge Claim Status],
           dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent],
           dim_detail_core_details.date_instructions_received AS [Date Instructions Received],
           dim_detail_core_details.status_on_instruction AS [Status On Instruction],
           dim_detail_core_details.referral_reason AS [Referral Reason],
           dim_detail_core_details.proceedings_issued AS [Proceedings Issued],
           dim_detail_core_details.date_proceedings_issued AS [Date Proceedings Issued],
           dim_detail_litigation.reason_for_litigation AS [Reason For Litigation],
           dim_court_involvement.court_reference AS [Court Reference],
           dim_court_involvement.court_name AS [Court Name],
           dim_detail_core_details.track AS [Track],
           dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?],
           COALESCE(
                       dim_detail_fraud.[fraud_initial_fraud_type],
                       dim_detail_fraud.[fraud_current_fraud_type],
                       dim_detail_fraud.[fraud_type_ageas],
                       dim_detail_fraud.[fraud_current_secondary_fraud_type],
                       dim_detail_client.[coop_fraud_current_fraud_type],
                       dim_detail_fraud.[fraud_type],
                       dim_detail_fraud.[fraud_type_disease_pre_lit]
                   ) AS [Fraud Type],
           dim_detail_core_details.credit_hire AS [Credit Hire],
           dim_agents_involvement.cho_name AS [Credit Hire Organisation],
           dim_detail_hire_details.[cho] AS [Credit Hire Organisation Detail],
           dim_claimant_thirdparty_involvement.[claimant_name] AS [Claimant Name],
           dim_detail_claim.[number_of_claimants] AS [Number of Claimants],
           fact_detail_client.number_of_defendants AS [Number of Defendants ],
           dim_detail_core_details.does_claimant_have_personal_injury_claim AS [Does the Claimant have a PI Claim? ],
           dim_detail_core_details.[brief_description_of_injury] AS [Description of Injury],
           CASE
               WHEN
               (
                   dim_client.client_code = '00041095'
                   AND dim_matter_worktype.[work_type_code] = '0023'
               ) THEN
                   'Regulatory'
               WHEN dim_matter_worktype.[work_type_name] LIKE 'EL%'
                    OR dim_matter_worktype.[work_type_name] LIKE 'PL%'
                    OR dim_matter_worktype.[work_type_name] LIKE 'Disease%' THEN
                   'Risk Pooling'
               WHEN
               (
                   (
                       dim_matter_worktype.[work_type_name] LIKE 'NHSLA%'
                       OR dim_matter_worktype.[work_type_code] = '0005'
                   )
                   AND dim_client_involvement.[insuredclient_name] LIKE '%Pennine%'
                   OR dim_matter_header_current.[matter_description] LIKE '%Pennine%'
               ) THEN
                   'Litigation'
           END AS [Litigation / Regulatory],
           dim_detail_core_details.[is_there_an_issue_on_liability] AS [Liability Issue],
           dim_detail_core_details.delegated AS [Delegated],
           dim_detail_core_details.[fixed_fee] AS [Fixed Fee],
           ISNULL(fact_finance_summary.[fixed_fee_amount], 0) AS [Fixed Fee Amount],
           ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0) AS [Fee Arrangement],
           dim_detail_finance.[output_wip_percentage_complete] AS [Percentage Completion],
           dim_detail_core_details.is_this_a_linked_file AS [Linked File?],
           dim_detail_health.leadfollow AS [Lead Follow],
           dim_detail_core_details.lead_file_matter_number_client_matter_number AS [Lead File Matter Number],
           dim_detail_core_details.[associated_matter_numbers] AS [Associated Matter Numbers],
           dim_detail_core_details.grpageas_motor_moj_stage AS [MoJ stage],
           dim_detail_core_details.incident_date AS [Incident Date],
           dim_detail_core_details.[incident_location] AS [Incident Location],
           dim_detail_core_details.has_the_claimant_got_a_cfa AS [Has the Claimant got a CFA? ],
           dim_detail_claim.cfa_entered_into_before_1_april_2013 AS [CFA entered into before 1 April 2013],
           dim_detail_claim.[dst_claimant_solicitor_firm ] AS [Claimant's Solicitor],
                                -- dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant's Solicitor],
           ClaimantsAddress.[claimant1_postcode] AS [Claimant's Postcode],
           fact_finance_summary.total_reserve AS [Total Reserve],
           ISNULL(fact_detail_reserve_detail.converge_disease_reserve, 0) AS [Converge Disease Reserve],
		   fact_finance_summary.[damages_reserve_initial] [Damages Reserve (Initial)],
           fact_finance_summary.damages_reserve AS [Damages Reserve Current ],
           fact_detail_paid_detail.hire_claimed AS [Hire Claimed ],
		   fact_finance_summary.[tp_costs_reserve_initial]  [Claimant Costs Reserve Current (Initial)], 
           fact_detail_reserve_detail.claimant_costs_reserve_current AS [Claimant Costs Reserve Current ],
		   
fact_finance_summary.[defence_costs_reserve_initial] AS [Defence Cost Reserve (Initial )], 
           fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve Current],
           CASE
               WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL
                    AND dim_matter_header_current.date_closed_case_management IS NOT NULL THEN
                   0
               ELSE
                   fact_finance_summary.[other_defendants_costs_reserve]
           END AS [Other Defendant's Costs Reserve (Net)],
           fact_detail_future_care.disease_total_estimated_settlement_value AS [Disease Total Estimated Settlement Value ],
           dim_detail_outcome.[outcome_of_case] AS [Outcome of Case],
           dim_detail_outcome.[ll00_settlement_basis] AS [Settlement basis],
           dim_detail_court.[date_of_trial] AS [Date of Trial],
           dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded],
           fact_finance_summary.damages_interims AS [Interim Damages],
           CASE
               WHEN fact_finance_summary.[damages_paid] IS NULL
                    AND fact_detail_paid_detail.[general_damages_paid] IS NULL
                    AND fact_detail_paid_detail.[special_damages_paid] IS NULL
                    AND fact_detail_paid_detail.[cru_paid] IS NULL THEN
                   NULL
               ELSE
           (CASE
                WHEN fact_finance_summary.[damages_paid] IS NULL THEN
           (ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
            + ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
           )
                ELSE
                    fact_finance_summary.[damages_paid]
            END
           )
           END AS [Damages Paid by Client ],
           fact_detail_paid_detail.[total_nil_settlements] AS [Outsource Damages Paid (WPS278+WPS279+WPS281)],
           fact_detail_paid_detail.personal_injury_paid AS [Personal Injury Paid],
           fact_detail_paid_detail.amount_hire_paid AS [Hire Paid ],
           CASE
               WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL
                    AND fact_detail_paid_detail.[total_nil_settlements] IS NULL THEN
                   NULL
               ELSE
           (CASE
                WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL THEN
           (CASE
                WHEN ISNULL(dim_detail_claim.[our_proportion_percent_of_damages], 0) = 0 THEN
                    NULL
                ELSE
           (ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
            + ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
           )
           / dim_detail_claim.[our_proportion_percent_of_damages]
            END
           )
                ELSE
                    fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties]
            END
           )
           END AS [Damages Paid (all parties) - Disease],
           dim_detail_outcome.date_referral_to_costs_unit AS [Date Referral to Costs Unit],
           dim_detail_outcome.[date_claimants_costs_received] AS [Date Claimants Costs Received],
           dim_detail_outcome.date_costs_settled AS [Date Costs Settled],
           dim_detail_client.date_settlement_form_sent_to_zurich AS [Date Settlement form Sent to Zurich WPS386 VE00571],
           fact_detail_paid_detail.interim_costs_payments AS [Interim Costs Payments],
           fact_detail_claim.[claimant_sols_total_costs_sols_claimed] AS [Total third party costs claimed (the sum of TRA094+NMI599+NMI600)],
           fact_finance_summary.[total_tp_costs_paid] AS [Total third party costs paid (sum of TRA072+NMI143+NMI379)],
           fact_finance_summary.tp_total_costs_claimed AS [Claimants Total Costs Claimed against Client],
           CASE
               WHEN fact_finance_summary.[claimants_costs_paid] IS NULL
                    AND fact_detail_paid_detail.[claimants_costs] IS NULL THEN
                   NULL
               ELSE
                   COALESCE(fact_finance_summary.[claimants_costs_paid], fact_detail_paid_detail.[claimants_costs])
           END AS [Claimant's Costs Paid by Client - Disease],
           red_dw.dbo.fact_detail_paid_detail.claimants_costs AS [Outsource Claimants Costs],
           fact_finance_summary.detailed_assessment_costs_claimed_by_claimant AS [Detailed Assessment Costs Claimed by Claimant],
           fact_finance_summary.detailed_assessment_costs_paid AS [Detailed Assessment Costs Paid],
           fact_finance_summary.[costs_claimed_by_another_defendant] AS [Costs Claimed by another Defendant],
           fact_detail_cost_budgeting.[costs_paid_to_another_defendant] AS [Costs Paid to Another Defendant],
           ISNULL(fact_finance_summary.[claimants_total_costs_paid_by_all_parties], 0) AS [Claimants Total Costs Paid by All Parties],
           red_dw.dbo.dim_detail_outcome.are_we_pursuing_a_recovery [Are we pursuing a recovery?],
           fact_finance_summary.total_recovery AS [Total Recovery (NMI112,NMI135,NMI136,NMI137)],
           fact_detail_recovery_detail.monies_received AS [Outsource Recovery Paid],
           fact_bill_detail_summary.bill_total AS [Total Bill Amount - Composite (IncVAT )],
           fact_finance_summary.[defence_costs_billed] AS [Revenue Costs Billed],
           fact_bill_detail_summary.disbursements_billed_exc_vat AS [Disbursements Billed ],
           fact_finance_summary.vat_billed AS [VAT Billed],
           fact_finance_summary.wip AS [WIP],
                                --    fact_finance_summary.[unpaid_disbursements] AS [Unpaid Disbursements],
           fact_finance_summary.disbursement_balance AS [Unbilled Disbursements],
           fact_matter_summary_current.[client_account_balance_of_matter] AS [Client Account Balance of Matter],
           fact_finance_summary.unpaid_bill_balance AS [Unpaid Bill Balance],
           CASE
               WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
                   NULL
               ELSE
                   fact_matter_summary_current.last_bill_date
           END AS [Last Bill Date],
           fact_bill_matter.last_bill_date [Last Bill Date Composite ],
           fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting],
           TimeRecorded.HoursRecorded AS [Hours Recorded],
           TimeRecorded.MinutesRecorded AS [Minutes Recorded],
           ((CASE
                 WHEN TimeRecorded.MinutesRecorded <= 12 THEN
                     0
                 WHEN TimeRecorded.MinutesRecorded > 12 THEN
                     TimeRecorded.MinutesRecorded - 12
             END
            ) * 115
           ) / 60 AS [Legal Spend exc (VAT)],
           fact_matter_summary_current.time_billed / 60 AS [Time Billed],
           NonPartnerHours AS [Total Non-Partner Hours Recorded],
           PartnerHours AS [Total Partner Hours Recorded],
           AssociateHours AS [Total Associate Hours Recorded],
           OtherHours AS [Total Other Hours Recorded],
           ParalegalHours AS [Total Paralegal Hours Recorded],
           [Partner/ConsultantTime] AS [Total Partner/Consultant Hours Recorded],
           [Solicitor/LegalExecTimeHours] AS [Total Solicitor/LegalExec Hours Recorded],
           TraineeHours AS [Total Trainee Hours Recorded],
           dim_detail_finance.[damages_banding] AS [Damages Banding],
           fact_detail_elapsed_days.[elapsed_days_live_files] AS [Elapsed Days Live Files],
           DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_outcome.date_costs_settled) AS [Elapsed Days to Costs Settlement],
		   DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.[date_claim_concluded])  AS  [Elapsed Days to Damages Concluded],

           red_dw.dbo.fact_finance_summary.commercial_costs_estimate [Current Costs Estimate],
           red_dw.dbo.fact_finance_summary.recovery_claimants_damages_via_third_party_contribution [Recovery Claimants Damages Via Third Party Contribution],
           red_dw.dbo.fact_finance_summary.recovery_defence_costs_from_claimant [Recovery Defence Costs From Claimant ],
           red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution [Recovery Claimants via Third Party Contribution ],
           red_dw.dbo.fact_finance_summary.recovery_defence_costs_via_third_party_contribution [Defence Costs via Third Party Contribution],
           dim_detail_claim.[dst_insured_client_name] AS [Insured Client Name],


		   fact_detail_client.nhs_annual_pp_ppo AS [Annual PP (PPO)],
fact_detail_client.nhs_capped_fee AS [Capped fee],
dim_detail_health.nhs_damages_tranche AS [Damages Tranche],
dim_detail_health.nhs_date_of_instruction_of_expert_for_schedule_1_and_2 AS [Date of instruction of expert for schedule 1 & 2],
  dim_detail_health.[zurichnhs_date_final_bill_sent_to_client] [Date final bill sent to client],
dim_detail_health.nhs_expected_settlement_date AS [Expected settlement date],
fact_detail_reserve_detail.nhs_gd_reserve AS [GD reserve],
fact_detail_reserve_detail.nhs_initial_meaningful_gd_reserve AS [Initial meaningful GD reserve],
fact_detail_reserve_detail.nhs_initial_meaningful_sd_reserve AS [Initial meaningful SD reserve],
fact_detail_reserve_detail.nhs_overall_reserve AS [Overall reserve],
dim_detail_health.nhs_prospects_of_success AS [Prospects of success ],
dim_detail_health.nhs_reason_for_trial AS [Reason for trIal],
dim_detail_health.nhs_recommended_to_proceed_to_trial AS [Recommended to proceed to trial],
fact_detail_client.nhs_retained_lump_sum_amount_ppo AS [Retained Lump sum amount (PPO)],
fact_detail_reserve_detail.nhs_sd_reserve AS [SD reserve],
dim_detail_health.nhs_stage_of_settlement AS [Stage of settlement],
dim_detail_health.nhs_type_of_instruction_billing AS [Type of instruction - billing],
dim_detail_health.[nhs_is_this_a_ppo_matter] AS [Is this a PPO matter? ],
dim_detail_health.[nhs_da_success] AS [DA success],
dim_detail_health.nhs_da_date  AS [DA date],
dim_detail_health.nhs_recommended_to_proceed_to_da AS [Recommended to proceed to DA],

           GETDATE() AS update_time,
                                ----, PFC.client_code, PFC.matter_number ---Financial year join [not needed ]

                                ----- Financial years Disbursements //Fees/ And Revenue 

                                --		--,isnull(PFC6.fees,0) AS FEES2014
                                --		--,isnull(PFC6.disbBilled, 0)AS DISB2014
                                --		--,isnull(PFC6.defence_costs_billed, 0)AS REV2014

                                --		--,isnull(PFC2.fees,0) AS FEES2015
                                --		--,isnull(PFC2.disbBilled, 0)AS DISB2015
                                --		--,isnull(PFC2.defence_costs_billed, 0)AS REV2015

                                --		--,isnull(PFC3.fees,0) AS FEES2016
                                --		--,isnull(PFC3.disbBilled,0) AS DISB2016
                                --		--,isnull(PFC3.defence_costs_billed,0) AS REV2016

                                --		--,isnull(PFC4.fees,0) AS FEES2017
                                --		--,isnull(PFC4.disbBilled,0) AS DISB2017
                                --		--,isnull(PFC4.defence_costs_billed,0) AS REV2017


                                --		--,isnull(PFC5.fees,0) AS FEES2018
                                --		--,isnull(PFC5.disbBilled,0) AS DISB2018
                                --		--,isnull(PFC5.defence_costs_billed,0) AS REV2018



                                --		, dim_detail_core_details.[claimants_date_of_birth] AS [Claimant's DOB]




                                --		, dim_detail_core_details.zurich_policy_holdername_of_insured AS [Policy Holder Name]



                                --,COALESCE([Insurer Reference],dim_client_involvement.insurerclient_reference) COLLATE database_default  AS [Insurer Reference]
                                --,COALESCE([Insurer Name],dim_client_involvement.insurerclient_name)COLLATE database_default   AS  [insurer contact ] 
                                --,COALESCE([Insured Reference],dim_client_involvement.insuredclient_reference)COLLATE database_default   AS [insured reference ]
                                --,COALESCE([Insured Name],dim_client_involvement.insuredclient_name)COLLATE database_default   AS  [Insured Contact]







                                --		, dim_detail_claim.accident_location AS [Accident Location]


                                --		, dim_detail_core_details.injury_type AS [Type of Injury]
                                --		, dim_detail_incident.[description_of_injury_v] AS [Injury Type]


                                --		, dim_experts_involvement.engineer_name AS [Engineer Name]
                                --				, dim_detail_core_details.[is_this_the_lead_file] AS [Lead File?]

                                --		, dim_detail_hire_details.cho_hire_start_date AS [Hire Start Date]
                                --		, dim_detail_hire_details.chp_hire_end_date AS [Hire End Date]


                                --		, dim_detail_claim.is_this_a_work_referral AS [Work Referral?]

                                --		, dim_detail_client.[coop_fraud_status] AS [Fraud Status]
                                --		, dim_detail_client.weightmans_comments AS [Weightmans Comments]
                                --		, dim_detail_core_details.date_of_current_estimate_to_complete_retainer AS [Date of Current Estimate to Complete Retainer]
                                --		, dim_detail_core_details.date_letter_of_claim AS [Date Letter of Claim]

                                --		, dim_detail_core_details.[date_pre_trial_report] AS [Date of Pre-Trial Report]


                                --		, dim_detail_court.[trial_window] AS [Trial Window]
                                --		, dim_detail_core_details.[date_start_of_trial_window] AS [Date Start of Trial Window]
                                --		, dim_detail_court.[date_end_of_trial_window] AS [Date End Of Trial Window]
                                --		, dim_detail_court.[infant_approval] AS [Infant Approval]



                                --		, dim_detail_core_details.sabre_reason_for_instructions AS [Reason for Instruction]

                                --		, dim_detail_core_details.date_subsequent_sla_report_sent AS [Sub Report]
                                --		, dim_detail_core_details.date_the_closure_report_sent AS [Closure Report]





                                --		, dim_detail_core_details.ccnumber AS [Live Claim]
                                --		, dim_detail_claim.live_case_status AS [Live Case Status]
                                --		, dim_detail_litigation.litigated AS [Litigated]

                                --		, dim_detail_critical_mi.closure_reason AS [Converge Closure Reason]







                                --		, fact_detail_elapsed_days.[elapsed_days_conclusion] AS [Elapsed Days Conclusion]

                                --		, fact_detail_paid_detail.fraud_savings AS [Fraud Savings]
                                --		--, fact_matter_summary_current.[last_financial_transaction_date] AS [Last Actioned]
                                --		, dim_detail_client.case_type_classification AS [Case Classification]


                                --		, dim_employee.levelidud AS [Level]
                                --		, dim_employee.postid AS [Post ID]
                                --		, dim_employee.payrollid AS [Payroll ID]
                                --		--, fact_employee_days_fte.fte AS [FTE]


                                --		, fact_matter_summary_current.[number_of_exceptions_mi] AS [Total MI Exceptions]
                                --		, fact_matter_summary_current.[critical_exceptions_mi] AS [Total Critical MI Exceptions]
                                --		, dim_detail_outcome.final_bill_date_grp AS [Final Bill Date GRP]
                                --		--, fact_all_time_activity.minutes_recorded AS [Time Recorded]


                                --		, dim_matter_header_current.[final_bill_date] AS [Date of Final Bill]



                                --		, 1 AS [Number of Records]

                                --		, 'Qtr' +' '+ CAST(dim_open_case_management_date.open_case_management_fin_quarter_no AS VARCHAR) AS [Financial Quarter Opened]



                                --		, cast(dim_open_case_management_date.open_case_management_fin_year - 1 as varchar) + '/' + cast(dim_open_case_management_date.open_case_management_fin_year as varchar) AS [Financial Year Opened] 
                                --		, 'Qtr' +' '+ CAST(dim_closed_case_management_date.closed_case_management_fin_quarter_no AS VARCHAR) AS [Financial Quarter Closed]
                                --		, cast(dim_closed_case_management_date.closed_case_management_fin_year - 1 as varchar) + '/' + cast(dim_closed_case_management_date.closed_case_management_fin_year as varchar) AS [Financial Year Closed] 
                                --		, CASE WHEN fact_detail_elapsed_days.[elapsed_days_live_files] <=100 THEN '0-100'
                                --				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=200 THEN '101-200'
                                --				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=300 THEN '201-300'
                                --				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=400 THEN '301-400'
                                --				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]<=600 THEN '401-600'
                                --				WHEN fact_detail_elapsed_days.[elapsed_days_live_files]>600 THEN '601+' END AS [Elapsed Days Live Bandings]
                                --		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL AND dim_detail_outcome.date_claim_concluded IS NULL THEN 1 ELSE 0 END AS [Number of Live Instructions]

                                --		--, ROW_NUMBER() OVER(PARTITION BY RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number ORDER BY RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number,dim_client_involvement.[insurerclient_reference] DESC) AS [Multiple Claimant]
                                --		--, dim_date_last_time.last_time_calendar_date
                                --		--, [Total Time Billed]
                                --		, DATEADD(wk, DATEDIFF(wk, 0, dim_detail_core_details.date_instructions_received), 0) AS [Week Commencing] --Monday of each week
                                --		, CAST(DATEPART(wk, dim_detail_core_details.date_instructions_received) AS CHAR (2)) +'/'+ CAST(DATEPART(YEAR,dim_detail_core_details.date_instructions_received) AS CHAR (4)) AS [Week Number]  
                                --		, DATEADD(yy,-4,GETDATE()) AS [GetDate 4 Years] -- this is 4 years from today

                                --		, CONVERT(VARCHAR(3),(dim_matter_header_current.date_opened_case_management)) + '-' + CONVERT(VARCHAR(4),YEAR(dim_matter_header_current.date_opened_case_management)) AS YearPeriod_MMYY
                                --		, CASE     WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear THEN 1               -- current may to dec
                                --                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) > @CurrentYear THEN 1               -- current jan to apr
                                --                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear THEN 2               -- historic1  (last year may to dec)
                                --                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-1 THEN 2             -- historic1  (last year jan to apr)
                                --                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-1 THEN 3             -- historic2  (2 years ago may to dec)
                                --                   WHEN datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = @CurrentYear-2 THEN 3             -- historic2  (2 years ago jan to apr)
                                --                   ELSE 4
                                --                   END 'PeriodType' 



                                --		, CASE WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=3 THEN 'Qtr1'
                                --				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=6 THEN 'Qtr2'
                                --				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=9 THEN 'Qtr3'
                                --				WHEN DATEPART(mm,dim_detail_core_details.date_instructions_received)<=12 THEN 'Qtr4'
                                --				ELSE NULL END AS [Calendar Quarter Received]
                                --		, CASE WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=3 THEN 'Qtr1'
                                --				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=6 THEN 'Qtr2'
                                --				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=9 THEN 'Qtr3'
                                --				WHEN DATEPART(mm,dim_matter_header_current.date_opened_case_management)<=12 THEN 'Qtr4'
                                --				ELSE NULL END AS [Calendar Quarter Opened]
                                --		, CASE WHEN dim_detail_core_details.present_position in ('To be closed/minor balances to be clear','Final bill sent - unpaid')
                                --								or (dim_matter_header_current.date_closed_case_management is not null ) THEN 'Closed' ELSE 'Open' END AS [Status]


                                --		, REPLACE(REPLACE(REPLACE(REPLACE(dim_matter_worktype.[work_type_name],char(9),' '),CHAR(10),' '),CHAR(13), ' '), 'DO NOT USE','') AS [All Work Types]
                                --		, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management) [Date Received/Opened]


                                --		, CASE WHEN dim_detail_outcome.date_costs_settled is not null or dim_matter_header_current.date_closed_case_management is not null THEN 1 ELSE 0 END AS [Sum Total of Concluded Matters]
                                --		, DATEDIFF(dd,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_costs_settled) as [Conclusion Days]



                                --		, DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_claim_concluded) AS [Elapsed Days to Outcome]

                                --		, CASE WHEN dim_detail_core_details.[motor_status] = 'Cancelled' THEN 'Closed'
                                --               WHEN --MaxFinalBillPaidDate >= ISNULL(MaxInterimBillDate,MaxFinalBillPaidDate)OR 
                                --					dim_matter_header_current.date_closed_case_management IS NOT NULL 
                                --                   OR (dim_detail_client.[europcartransferred_file]='Yes') THEN 'Closed'
                                --               ELSE 'Open' END AS [Filestatus]


                                --, CASE WHEN dim_detail_core_details.date_instructions_received BETWEEN DATEADD(Month,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))  AND DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) THEN 1 ELSE 0 END [Rolling 12 Months Concluded]
                                --, CASE WHEN dim_matter_header_current.date_opened_case_management BETWEEN DATEADD(Month,-11,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))  AND DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) THEN 1 ELSE 0 END [Rolling 12 Months Opened]
                                --, CASE WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Exclude from reports' THEN  'Exclude from reports'
                                --		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Discontinued%'THEN 'Repudiated'
                                --		WHEN dim_detail_outcome.[outcome_of_case] LIKE 'Won at trial%'THEN 'Repudiated'
                                --		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Struck out%'THEN 'Repudiated'
                                --		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Settled%'THEN 'Settled'
                                --		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Lost at trial%'THEN 'Settled'
                                --		WHEN dim_detail_outcome.[outcome_of_case] LIKE  'Assessment of damages%'THEN 'Settled'
                                --		ELSE NULL END [Repudiation - outcome]
                                --, CASE WHEN TimeRecorded.MinutesRecorded<=12 THEN 'Free 12 mins'
                                --		WHEN TimeRecorded.MinutesRecorded<=60 THEN '12 – 60 mins'
                                --		WHEN TimeRecorded.MinutesRecorded<=120 THEN '1 - 2 hours'
                                --		WHEN TimeRecorded.MinutesRecorded<=180 THEN '2 - 3 hours'
                                --		WHEN TimeRecorded.MinutesRecorded<=240 THEN '3 - 4 hours'
                                --		WHEN TimeRecorded.MinutesRecorded<=300 THEN '4 – 5 hours'
                                --		WHEN TimeRecorded.MinutesRecorded>300 THEN 'Over 5 hours'
                                --	ELSE NULL END AS [Time Recorded (Banded)]
                                --, CASE WHEN TimeRecorded.MinutesRecorded >=12 THEN 'Yes' ELSE 'No' END AS [Free 12 mins Used?]
                                --, CASE WHEN TimeRecorded.MinutesRecorded <=12 THEN 0 
                                --	WHEN TimeRecorded.MinutesRecorded>12 THEN TimeRecorded.MinutesRecorded-12 END AS [Chargeable Time]








                                --, DATEDIFF(DAY,dim_detail_outcome.[date_claimants_costs_received], dim_detail_outcome.date_costs_settled) AS [Days from Date receipt of Claimant's Costs to Date Costs Settled]
                                --, CASE WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management,dim_matter_header_current.[final_bill_date])
                                --	ELSE NULL END AS [Days from Date opened in FED to date of last bill on file (closed matters)]
                                --, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_critical_mi.date_closed) AS [Days from Date opened in FED to Converge Date Closed]
                                --, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management,dim_detail_client.[date_settlement_form_sent_to_zurich]) AS [Days from Date opened in FED to Date Settlement Form Sent to Zurich]
                                --, CAST((CASE WHEN MONTH(dim_matter_header_current.date_opened_case_management) >= 5 THEN CAST(YEAR(dim_matter_header_current.date_opened_case_management) as varchar) + '/' + CAST((YEAR(dim_matter_header_current.date_opened_case_management) + 1) AS varchar)
                                --               ELSE CAST((YEAR(dim_matter_header_current.date_opened_case_management) - 1) AS VARCHAR) + '/' + CAST(YEAR(dim_matter_header_current.date_opened_case_management) AS VARCHAR) 
                                --                 END) AS VARCHAR) [Whitbread Year Period]
                                --, CASE WHEN dim_detail_critical_mi.[litigated]='Yes' OR dim_detail_core_details.[proceedings_issued]='Yes' THEN 'Litigated' ELSE 'Pre-Litigated' END AS [Litigated/Proceedings Issued]

                                ----amended as requested by Ann-Marie 230096
                                ----, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL AND (dim_detail_outcome.[outcome_of_case] IS NOT NULL OR dim_detail_outcome.[date_claim_concluded] IS NOT NULL) THEN 'Damages Only Settled'
                                ----	WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL OR dim_detail_outcome.[date_costs_settled] IS NOT NULL OR dim_detail_client.[date_settlement_form_sent_to_zurich] IS NOT NULL  THEN 'Closed' ELSE 'Live' END AS [Status - Disease]
                                --, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed'
                                --		WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL AND (dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL) THEN 'Damages Only Settled'
                                --		WHEN dim_detail_outcome.[date_claim_concluded] IS NULL AND dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL THEN 'Live'
                                --		ELSE NULL END AS [Status - Disease]
                                --, COALESCE(dim_detail_core_details.[track],dim_detail_core_details.[zurich_track]) AS [Track - Disease]

                                --, CASE WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs concluded but recovery outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'Yes' THEN 'PP3 Lead' 
                                --             WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'Yes' THEN 'PP1 Lead'
                                --             WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs concluded but recovery outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'No' THEN 'PP3 Linked'
                                --             WHEN LOWER(ISNULL(dim_detail_core_details.[present_position],'')) = 'claim and costs outstanding' AND ISNULL(dim_detail_core_details.[is_this_the_lead_file],'Yes') = 'No' THEN 'PP1 Linked' END [PP Description]
                                ----, CASE WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] Like '%Credit Hire%' THEN FLOOR(60 * fact_employee_days_fte.fte)	
                                ----		WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE 'Motor Multi Track%' THEN FLOOR(40 * fact_employee_days_fte.fte)
                                ----              WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) LIKE 'fast track%' THEN FLOOR(50 * fact_employee_days_fte.fte)
                                ----		WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) LIKE 'motor%' THEN FLOOR(55 * fact_employee_days_fte.fte)
                                ----              WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) LIKE 'multi%' THEN FLOOR(55 * fact_employee_days_fte.fte)
                                ----              WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) = 'disease fraud' THEN FLOOR(50 * fact_employee_days_fte.fte)
                                ----              WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] IN ('Disease Birmingham','Disease Dartford','Disease Leicester','Disease Liverpool','Disease Midlands')  THEN FLOOR(40 * fact_employee_days_fte.fte)
                                ----              WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] IN ('Disease Pre Lit Birmingham','Disease Pre Lit Liverpool') THEN FLOOR(250 * fact_employee_days_fte.fte)
                                ----		ELSE FLOOR(30 * fact_employee_days_fte.fte) 
                                ----              END [Optimum Case Level]
                                ----, CASE WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] Like '%Credit Hire%' THEN FLOOR(30 * fact_employee_days_fte.fte)	
                                ----		ELSE FLOOR(30 * fact_employee_days_fte.fte) 
                                ----              END [Fraud Optimum Case Level]
                                ----, CASE WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] Like '%Credit Hire%' THEN FLOOR(60 * fact_employee_days_fte.fte)	
                                ----		ELSE FLOOR(30 * fact_employee_days_fte.fte) 
                                ----              END [Credit Hire Optimum Case Level]

                                --, COALESCE(dim_detail_claim.[claimants_solicitors_firm_name ], dim_claimant_thirdparty_involvement.claimantsols_name) AS [Claimant's Solicitors Firm]
                                --, CAST([DateClaimConcluded].fin_year-1 AS VARCHAR)+'/'+CAST([DateClaimConcluded].fin_year AS VARCHAR) AS [FY Date Claim Concluded]
                                --, CAST([DateCostsSettled].fin_year-1 AS VARCHAR)+'/'+CAST([DateCostsSettled].fin_year  AS VARCHAR) AS [FY Date Costs Settled]
                                --, CAST([DateInstructionsReceived].fin_year-1 AS VARCHAR)+'/'+CAST([DateInstructionsReceived].fin_year  AS VARCHAR) AS [FY Date Instructions Received]

                                --, dim_detail_claim.dst_claimant_solicitor_firm [DST Claimant Solicitors Form ]
                                --, dim_detail_claim.dst_insured_client_name [DST Insured Client Name ]


                                ----Fin 2015
                                --,isnull(FIND1.Rev,0) As [2016-Q1]
                                --,isnull(FIND2.Rev,0) As [2016-Q2]
                                --,isnull(FIND3.Rev,0) As [2016-Q3]
                                --,isnull(FIND4.Rev,0) As [2016-Q4]
                                ----Fin 2016
                                --,isnull(FIND5.Rev,0) As [2017-Q1]
                                --,isnull(FIND6.Rev,0) As [2017-Q2]
                                --,isnull(FIND7.Rev,0) As [2017-Q3]
                                --,isnull(FIND8.Rev,0) As [2017-Q4]
                                ----Fin 2017
                                --,isnull(FIND9.Rev,0) As [2018-Q1]
                                --,isnull(FIND10.Rev,0) As [2018-Q2]
                                --,isnull(FIND11.Rev,0) As [2018-Q3]
                                --,isnull(FIND12.Rev,0) As [2018-Q4]
                                ----Fin 2018
                                --,isnull(FIND13.Rev,0) As [2019-Q1]
                                ----isnull(FIND14.Rev,0) As [2019-Q2],
                                ----isnull(FIND15.Rev,0) As [2019-Q3],
                                ----isnull(FIND16.Rev,0) As [2019-Q4],


                                --,dim_detail_claim.cnf_received_date AS [Date CNF Recieved]
                                --,dim_detail_claim.cnf_acknowledgement_date AS [CNF Acknowledged]
                                --, dim_detail_practice_area.who_dropped_the_claim_out_of_portal AS [Who Dropped The Claim Out of Portal]
                                --, isnull(fact_detail_paid_detail.portal_costs,0) as [Portal Costs]
                                --, isnull(fact_detail_paid_detail.portal_disbursements, 0)as [Portal Disbursements]
                                --, dim_detail_health.reason_claim_left_the_portal AS [Reason Claim Left the Portal]
                                --	, CASE WHEN dim_matter_header_current.final_bill_flag=0 OR dim_matter_header_current.final_bill_flag IS NULL THEN 'N' ELSE 'Y' END AS [Final Bill Flag]

                                --		, CASE WHEN dim_detail_critical_mi.claim_status IN ('Open', 'Re-opened') THEN ''
                                --			   WHEN dim_detail_critical_mi.claim_status  IN ('Closed') AND (ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant,0)+ISNULL(fact_finance_summary.detailed_assessment_costs_paid,0))=0 THEN 'Nil Settlement'
                                --               WHEN dim_detail_critical_mi.claim_status  IN ('Closed') AND (ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.damages_paid,0)+ISNULL(fact_finance_summary.interlocutory_costs_paid_to_claimant,0)+ISNULL(fact_finance_summary.detailed_assessment_costs_paid,0))>0 THEN 'Payment Made'
                                --               END [Nill Settlement]
                                --		, CASE WHEN dim_matter_header_current.final_bill_flag=1 THEN '0'
                                --				WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN '0'
                                --				ELSE isnull(fact_finance_summary.commercial_costs_estimate_net,0)
                                --		  END AS [Outstanding Costs Estimate]
                                --		  	, fact_finance_summary.[total_amount_billed] AS [Total Amount Billed]
                                --		, ISNULL(fact_finance_summary.[total_amount_billed],0)-ISNULL(fact_finance_summary.vat_billed,0) [Total Amount Billed (exc VAT)]
                                --		, ISNULL(fact_finance_summary.commercial_costs_estimate,0)-(ISNULL(fact_finance_summary.[total_amount_billed],0)-ISNULL(fact_finance_summary.vat_billed,0)) [Total Outstanding Costs]
                                --		, ISNULL(fact_detail_future_care.[interlocutory_costs_claimed_by_claimant],0) + ISNULL(fact_finance_summary.[claimants_costs_paid],0) + ISNULL(fact_finance_summary.[detailed_assessment_costs_paid],0) + ISNULL(fact_finance_summary.[other_defendants_costs_paid],0) AS [Opponents Cost Spend]
                                --		, ISNULL(fact_finance_summary.[tp_costs_reserve_initial], 0) + ISNULL(fact_finance_summary.[other_defendants_costs_reserve_initial], 0) AS [Initial claimant's costs reserve / estimation] 

                                --		, fact_bill_detail_summary.bill_total_excl_vat AS [Total Bill Amount - Composite (excVAT)] 



                                --		, ISNULL(fact_finance_summary.commercial_costs_estimate,0)-(ISNULL(fact_bill_detail_summary.bill_total_excl_vat,0)) [Total Outstanding Costs - Composite]


                                --		, CASE WHEN fact_finance_summary.[claimants_total_costs_paid_by_all_parties] IS NULL AND fact_detail_paid_detail.[claimants_costs] IS NULL THEN NULL
                                --				ELSE (CASE WHEN fact_finance_summary.[claimants_total_costs_paid_by_all_parties] IS NULL THEN 
                                --			(CASE WHEN ISNULL(fact_detail_paid_detail.[our_proportion_costs ],0)=0 THEN NULL ELSE ISNULL(fact_detail_paid_detail.[claimants_costs],0)/fact_detail_paid_detail.[our_proportion_costs ] END) 
                                --				ELSE fact_finance_summary.[claimants_total_costs_paid_by_all_parties] END)  END AS [Claimant's Total Costs Paid (all parties) - Disease]

                                --		, isnull(fact_detail_paid_detail.tp_total_costs_claimed_all_parties,0) AS [TP Total Costs Claimed All Parties]
                                --		, fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction as [Interim Damages Paid by Client Preinstruction]


                                --		--,ISNULL(fact_finance_summary.[damages_paid],0)+ISNULL(fact_finance_summary.claimants_costs_paid,0)+ISNULL(fact_finance_summary.defence_costs_billed,0) as Indem
                                --, ISNULL(fact_finance_summary.indemnity_spend, 0) AS [Indemnity Spend ]
                                ----, fact_detail_paid_detail.[claimant_s_solicitor_s_base_costs_paid_vat] AS [Claimant's solicitor's base costs paid + VAT]
                                --, fact_finance_summary.[claimants_solicitors_disbursements_paid] AS [Claimant's solicitor's disbursements paid]




                                --, fact_finance_summary.[total_reserve_initial] AS [Total Reserve Initial]



                                --, dim_detail_core_details.aig_coverage_defence AS [AIG Converge Defence]
                                --, fact_detail_client.defence_costs AS [Defence Costs ]
                                --,fact_finance_summary.defence_costs_reserve_initial AS [Defence Costs Initial] 
                                --, fact_finance_summary.defence_costs_reserve_net AS [Defence Costs Reserve (NET)]
                                --, fact_finance_summary.other_defendants_costs_reserve_initial AS [Other Defendants Costs Reserve Initial]
                                --,fact_finance_summary.other_defendants_costs_paid AS [Other Defendants Costs Reserve Current]




                                --, fact_detail_paid_detail.amount_hire_paid AS [Amount Hired Paid ]
                                --, fact_detail_paid_detail.cru_paid_by_all_parties AS [CRU Paid by all Parties]
                                --, fact_detail_cost_budgeting.initial_costs_estimate AS [Initial Costs Estimate]

                                --, fact_detail_client.nhs_charges_paid_by_all_parties AS [NHS Charges Paid by all parties]



                                --,dim_detail_claim.date_recovery_concluded AS [Date Recovery Concluded] 
                                --,dim_detail_outcome.are_we_pursuing_a_recovery AS [Are We Persuing a Recovery? ]
                                --,fact_finance_summary.recovery_claimants_damages_via_third_party_contribution AS [Recovery Claimant Damages Via Third Party Contribution]
                                --,fact_finance_summary.recovery_defence_costs_via_third_party_contribution AS [Recovery Defence Costs Via Third Party Contribution]
                                --,fact_finance_summary.recovery_defence_costs_from_claimant as [Recovery Defence Costs from Claimant]
                                --,dim_detail_outcome.recovery_claimants_our_client_damages AS [Recovery Claimants (Our Client) Damages ]




                                --, fact_detail_paid_detail.general_damages_paid AS [General Damages Paid]
                                --, fact_detail_paid_detail.special_damages_paid AS [Special Damages Paid]
                                --, fact_detail_paid_detail.[claimant_s_solicitor_s_base_costs_paid_vat] AS [Claimant's solicitor's base costs paid + VAT]
                                --, fact_detail_reserve_detail.[claimant_s_solicitor_s_base_costs_claimed_vat] AS [Claimant's solicitor's base costs claimed + VAT]
                                --, fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction AS [Interim Damages Paid by Client Pre Instruction]



                                --, fact_detail_reserve_detail.[personal_injury_reserve_initial] AS [PI Reserve Initial]
                                --, fact_detail_cost_budgeting.[personal_injury_reserve_current] AS [PI Reserve Current]
                                --, dim_detail_outcome.grpageas_name_of_costs_negotiator AS [Name of Cost Negotiators (GPR AGEAS)]
                                --, dim_detail_outcome.mib_name_of_costs_negotiators AS  [Name of Cost Negotiators (MIB)]
                                --,dim_detail_client.service_category

                                ----------------------------------------
           [Revenue 2015/2016],
           [Revenue 2016/2017],
           [Revenue 2017/2018], ---- Added Per Request 8366
           [Revenue 2018/2019],
           [Hours Billed 2015/2016],
           [Hours Billed 2016/2017],
           [Hours Billed 2017/2018],
           [Hours Billed 2018/2019]
    ---------------------------------------------------
    INTO Reporting.dbo.NHSRSelfService
    --into generaldatafile20180810

    --ss.GeneralDataFile
    FROM red_dw.dbo.fact_dimension_main
        --inner join PFC on PFC.client_code = fact_dimension_main.client_code and PFC.matter_number = fact_dimension_main.matter_number
        --inner join FIND on FIND.client_code = fact_dimension_main.client_code and FIND.matter_number = fact_dimension_main.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement
            ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key
        LEFT OUTER JOIN red_dw.dbo.dim_client
            ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
            ON red_dw.dbo.dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
            ON red_dw.dbo.dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_department
            ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
            ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
            ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
            ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_court
            ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_health
            ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
            ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_incident
            ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_litigation
            ON dim_detail_litigation.dim_detail_litigation_key = fact_dimension_main.dim_detail_litigation_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
        LEFT OUTER JOIN red_dw.dbo.dim_experts_involvement
            ON dim_experts_involvement.dim_experts_involvemen_key = fact_dimension_main.dim_experts_involvemen_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
            ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
            ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
               AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
               AND GETDATE()
               BETWEEN dss_start_date AND dss_end_date
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary
            ON red_dw.dbo.fact_matter_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_last_bill_date
            ON dim_last_bill_date.dim_last_bill_date_key = fact_matter_summary.dim_last_bill_date_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi
            ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
        LEFT OUTER JOIN red_dw.dbo.dim_open_case_management_date
            ON dim_open_case_management_date.calendar_date = dim_matter_header_current.date_opened_case_management
        LEFT OUTER JOIN red_dw.dbo.dim_closed_case_management_date
            ON dim_closed_case_management_date.calendar_date = dim_matter_header_current.date_closed_case_management
        LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
            ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
            ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
            ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
            ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_client
            ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care
            ON fact_detail_future_care.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
            ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
            ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
            ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary
            ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key --added in for Composite Billing JL
        --LEFT OUTER JOIN [red_dw].[dbo].[fact_all_time_activity] ON fact_all_time_activity.master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
            ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
        LEFT OUTER JOIN red_dw.[dbo].[dim_instruction_type]
            ON [dim_instruction_type].[dim_instruction_type_key] = dim_matter_header_current.dim_instruction_type_key
        LEFT OUTER JOIN red_dw.dbo.dim_employee
            ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
        LEFT OUTER JOIN red_dw.dbo.fact_bill_matter
            ON fact_bill_matter.master_fact_key = fact_dimension_main.master_fact_key
        --LEFT OUTER JOIN red_dw.dbo.fact_employee_days_fte ON fact_employee_days_fte.dim_fed_hierarchy_history_key=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
        -- financial Quarters 
        -- left join FIND FIND1 ON fact_dimension_main.client_code = FIND1.client_code and fact_dimension_main.matter_number = FIND1.matter_number 
        --AND FIND1.bill_fin_quarter ='2016-Q1'

        -- left join FIND FIND2 ON fact_dimension_main.client_code = FIND2.client_code and fact_dimension_main.matter_number = FIND2.matter_number 
        --AND FIND2.bill_fin_quarter ='2016-Q2'

        --left join FIND FIND3 ON fact_dimension_main.client_code = FIND3.client_code and fact_dimension_main.matter_number = FIND3.matter_number 
        --AND FIND3.bill_fin_quarter = '2016-Q3'

        --left join FIND FIND4 ON fact_dimension_main.client_code = FIND4.client_code and fact_dimension_main.matter_number = FIND4.matter_number 
        --AND FIND4.bill_fin_quarter = '2016-Q4'

        --left join FIND FIND5 ON fact_dimension_main.client_code = FIND5.client_code and fact_dimension_main.matter_number = FIND5.matter_number 
        --AND FIND5.bill_fin_quarter = '2017-Q1'

        --left join FIND FIND6 ON fact_dimension_main.client_code = FIND6.client_code and fact_dimension_main.matter_number = FIND6.matter_number 
        --AND FIND6.bill_fin_quarter = '2017-Q2'

        --left join FIND FIND7 ON fact_dimension_main.client_code = FIND7.client_code and fact_dimension_main.matter_number = FIND7.matter_number 
        --AND FIND7.bill_fin_quarter = '2017-Q3'

        --left join FIND FIND8 ON fact_dimension_main.client_code = FIND8.client_code and fact_dimension_main.matter_number = FIND8.matter_number 
        --AND FIND8.bill_fin_quarter = '2017-Q4'

        --left join FIND FIND9 ON fact_dimension_main.client_code = FIND9.client_code and fact_dimension_main.matter_number = FIND9.matter_number 
        --AND FIND9.bill_fin_quarter = '2018-Q1'

        --left join FIND FIND10 ON fact_dimension_main.client_code = FIND10.client_code and fact_dimension_main.matter_number = FIND10.matter_number 
        --AND FIND10.bill_fin_quarter = '2018-Q2'

        --left join FIND FIND11 ON fact_dimension_main.client_code = FIND11.client_code and fact_dimension_main.matter_number = FIND11.matter_number 
        --AND FIND11.bill_fin_quarter = '2018-Q3'

        --left join FIND FIND12 ON fact_dimension_main.client_code = FIND12.client_code and fact_dimension_main.matter_number = FIND12.matter_number 
        --AND FIND12.bill_fin_quarter = '2018-Q4'

        --left join FIND FIND13 ON fact_dimension_main.client_code = FIND13.client_code and fact_dimension_main.matter_number = FIND13.matter_number 
        --AND FIND13.bill_fin_quarter = '2019-Q1'


        ----Financial year 
        --left join PFC PFC6 ON fact_dimension_main.client_code = PFC6.client_code and fact_dimension_main.matter_number = PFC6.matter_number 
        --AND PFC6.bill_fin_year = 2015

        --left join PFC PFC2 ON fact_dimension_main.client_code = PFC2.client_code and fact_dimension_main.matter_number = PFC2.matter_number 
        --AND PFC2.bill_fin_year = 2016

        --left join PFC PFC3 ON fact_dimension_main.client_code = PFC3.client_code and fact_dimension_main.matter_number = PFC3.matter_number 
        --AND PFC3.bill_fin_year = 2017

        --left join PFC PFC4 ON fact_dimension_main.client_code = PFC4.client_code and fact_dimension_main.matter_number = PFC4.matter_number 
        --AND PFC4.bill_fin_year = 2018

        --left join PFC PFC5 ON fact_dimension_main.client_code = PFC5.client_code and fact_dimension_main.matter_number = PFC5.matter_number 
        --AND PFC5.bill_fin_year = 2019



        LEFT OUTER JOIN
        (
            SELECT fact_dimension_main.master_fact_key [fact_key],
                   dim_client.contact_salutation [claimant1_contact_salutation],
                   dim_client.addresse [claimant1_addresse],
                   dim_client.address_line_1 [claimant1_address_line_1],
                   dim_client.address_line_2 [claimant1_address_line_2],
                   dim_client.address_line_3 [claimant1_address_line_3],
                   dim_client.address_line_4 [claimant1_address_line_4],
                   dim_client.postcode [claimant1_postcode]
            FROM red_dw.dbo.dim_claimant_thirdparty_involvement
                INNER JOIN red_dw.dbo.fact_dimension_main
                    ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
                INNER JOIN red_dw.dbo.dim_involvement_full
                    ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
                INNER JOIN red_dw.dbo.dim_client
                    ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
            WHERE dim_client.dim_client_key != 0
        ) AS ClaimantsAddress
            ON fact_dimension_main.master_fact_key = ClaimantsAddress.fact_key
        LEFT OUTER JOIN
        (
            SELECT fact_chargeable_time_activity.master_fact_key,
                   SUM(minutes_recorded) AS [MinutesRecorded],
                   SUM(minutes_recorded) / 60 AS [HoursRecorded]
            FROM red_dw.dbo.fact_chargeable_time_activity
                INNER JOIN red_dw.dbo.dim_matter_header_current
                    ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
            WHERE minutes_recorded <> 0
                  AND
                  (
                      dim_matter_header_current.date_closed_case_management >= '20120101'
                      OR dim_matter_header_current.date_closed_case_management IS NULL
                  )
            GROUP BY client_code,
                     matter_number,
                     fact_chargeable_time_activity.master_fact_key
        ) AS TimeRecorded
            ON TimeRecorded.master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
        LEFT OUTER JOIN
        (
            SELECT client_code,
                   matter_number,
                   master_fact_key,
                   ISNULL(SUM(PartnerTime), 0) / 60 AS PartnerHours,
                   ISNULL(SUM(NonPartnerTime), 0) / 60 AS NonPartnerHours,
                   ISNULL(SUM([Partner/ConsultantTime]), 0) / 60 AS [Partner/ConsultantTime],
                   ISNULL(SUM(AssociateTime), 0) / 60 AS AssociateHours,
                   ISNULL(SUM([Solicitor/LegalExecTime]), 0) / 60 AS [Solicitor/LegalExecTimeHours],
                   ISNULL(SUM(ParalegalTime), 0) / 60 AS ParalegalHours,
                   ISNULL(SUM(TraineeTime), 0) / 60 AS TraineeHours,
                   ISNULL(SUM(OtherTime), 0) / 60 AS OtherHours
            FROM
            (
                SELECT client_code,
                       matter_number,
                       master_fact_key,
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Partner%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS PartnerTime,
                       (CASE
                            WHEN Partners.jobtitle NOT LIKE '%Partner%'
                                 OR jobtitle IS NULL THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS NonPartnerTime,
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Partner%'
                                 OR Partners.jobtitle LIKE '%Consultant%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [Partner/ConsultantTime],
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Associate%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS AssociateTime,
                       (CASE
                            WHEN Partners.jobtitle LIKE 'Solicitor%'
                                 OR Partners.jobtitle LIKE '%Legal Executive%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [Solicitor/LegalExecTime],
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Paralegal%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [ParalegalTime],
                       (CASE
                            WHEN Partners.jobtitle LIKE '%Trainee Solicitor%' THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS [TraineeTime],
                       (CASE
                            WHEN Partners.jobtitle NOT LIKE '%Partner%'
                                 AND Partners.jobtitle NOT LIKE '%Consultant%'
                                 AND Partners.jobtitle NOT LIKE '%Associate%'
                                 AND Partners.jobtitle NOT LIKE '%Solicitor%'
                                 AND Partners.jobtitle NOT LIKE '%Legal Executive%'
                                 AND Partners.jobtitle NOT LIKE '%Paralegal%'
                                 AND Partners.jobtitle NOT LIKE '%Trainee%'
                                 OR jobtitle IS NULL THEN
                                SUM(minutes_recorded)
                            ELSE
                                0
                        END
                       ) AS OtherTime
                FROM red_dw.dbo.fact_chargeable_time_activity
                    LEFT OUTER JOIN
                    (
                        SELECT DISTINCT
                               dim_fed_hierarchy_history_key,
                               jobtitle
                        FROM red_dw.dbo.dim_fed_hierarchy_history
                    ) AS Partners
                        ON Partners.dim_fed_hierarchy_history_key = fact_chargeable_time_activity.dim_fed_hierarchy_history_key
                    LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
                        ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
                WHERE minutes_recorded <> 0
                      AND
                      (
                          dim_matter_header_current.date_closed_case_management >= '20120101'
                          OR dim_matter_header_current.date_closed_case_management IS NULL
                      )
                GROUP BY client_code,
                         matter_number,
                         master_fact_key,
                         Partners.jobtitle
            ) AS AllTime
            GROUP BY AllTime.client_code,
                     AllTime.matter_number,
                     AllTime.master_fact_key
        ) AS [Partner/NonPartnerHoursRecorded]
            ON [Partner/NonPartnerHoursRecorded].master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateClaimConcluded]
            ON CAST(dim_detail_outcome.date_claim_concluded AS DATE) = [DateClaimConcluded].calendar_date
        LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateCostsSettled]
            ON CAST(dim_detail_outcome.date_costs_settled AS DATE) = [DateCostsSettled].calendar_date
        LEFT OUTER JOIN red_dw.dbo.dim_date AS [DateInstructionsReceived]
            ON CAST(dim_detail_core_details.date_instructions_received AS DATE) = [DateInstructionsReceived].calendar_date
        --LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key



        LEFT JOIN
        (
            SELECT fact_dimension_main.master_fact_key [fact_key],
                   LTRIM(RTRIM(dim_client.contact_salutation)) [insurer_contact_salutation],
                   LTRIM(RTRIM(dim_client.addresse)) [insurer_addresse],
                   LTRIM(RTRIM(dim_client.address_line_1)) [insurer_address_line_1],
                   LTRIM(RTRIM(dim_client.address_line_2)) [insurer_address_line_2],
                   LTRIM(RTRIM(dim_client.address_line_3)) [insurer_address_line_3],
                   LTRIM(RTRIM(dim_client.address_line_4)) [insurer_address_line_4],
                   LTRIM(RTRIM(dim_client.postcode)) [insurer_postcode]
            FROM red_dw.dbo.dim_client_involvement WITH (NOLOCK)
                INNER JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK)
                    ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
                INNER JOIN red_dw.dbo.dim_involvement_full WITH (NOLOCK)
                    ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insurerclient_1_key
                INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
                    ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
            WHERE dim_client.dim_client_key != 0
        ) AS billingAddress
            ON fact_dimension_main.master_fact_key = billingAddress.fact_key
        LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS [Insurer Name],
                   assocAddressee AS [Addressee],
                   CASE
                       WHEN assocdefaultaddID IS NOT NULL THEN
                           ISNULL(dbAddress1.addLine1, '') + ' ' + ISNULL(dbAddress1.addLine2, '') + ' '
                           + ISNULL(dbAddress1.addLine3, '') + ' ' + ISNULL(dbAddress1.addLine4, '') + ' '
                           + ISNULL(dbAddress1.addLine5, '') + ' ' + ISNULL(dbAddress1.addPostcode, '')
                       ELSE
                           ISNULL(dbAddress2.addLine1, '') + ' ' + ISNULL(dbAddress2.addLine2, '') + ' '
                           + ISNULL(dbAddress2.addLine3, '') + ' ' + ISNULL(dbAddress2.addLine4, '') + ' '
                           + ISNULL(dbAddress2.addLine5, '') + ' ' + ISNULL(dbAddress2.addPostcode, '')
                   END AS [Insurer Address],
                   dbAssociates.assocRef AS [Insurer Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress1 WITH (NOLOCK)
                    ON assocdefaultaddID = dbAddress1.addID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress2 WITH (NOLOCK)
                    ON contDefaultAddress = dbAddress2.addID
            WHERE assocType = 'INSCLIENT'
        )
        --WHERE assocType='INSURERCLIENT' ) 



        AS MSbillingAddress
            ON dim_matter_header_current.ms_fileid = MSbillingAddress.fileID
               AND MSbillingAddress.XOrder = 1
        LEFT JOIN
        ( --Vat Address
            SELECT fact_dimension_main.master_fact_key [fact_key],
                   LTRIM(RTRIM(dim_client.contact_salutation)) [insured_contact_salutation],
                   LTRIM(RTRIM(dim_client.addresse)) [insured_addresse],
                   LTRIM(RTRIM(dim_client.address_line_1)) [insured_address_line_1],
                   LTRIM(RTRIM(dim_client.address_line_2)) [insured_address_line_2],
                   LTRIM(RTRIM(dim_client.address_line_3)) [insured_address_line_3],
                   LTRIM(RTRIM(dim_client.address_line_4)) [insured_address_line_4],
                   LTRIM(RTRIM(dim_client.postcode)) [insured_postcode]
            FROM red_dw.dbo.dim_client_involvement WITH (NOLOCK)
                INNER JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK)
                    ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
                INNER JOIN red_dw.dbo.dim_involvement_full WITH (NOLOCK)
                    ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insuredclient_1_key
                INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
                    ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
            WHERE dim_client.dim_client_key != 0
        ) AS vatAddress
            ON vatAddress.fact_key = fact_dimension_main.master_fact_key
        LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS [Insured Name],
                   assocAddressee AS [Addressee],
                   CASE
                       WHEN assocdefaultaddID IS NOT NULL THEN
                           ISNULL(dbAddress1.addLine1, '') + ' ' + ISNULL(dbAddress1.addLine2, '') + ' '
                           + ISNULL(dbAddress1.addLine3, '') + ' ' + ISNULL(dbAddress1.addLine4, '') + ' '
                           + ISNULL(dbAddress1.addLine5, '') + ' ' + ISNULL(dbAddress1.addPostcode, '')
                       ELSE
                           ISNULL(dbAddress2.addLine1, '') + ' ' + ISNULL(dbAddress2.addLine2, '') + ' '
                           + ISNULL(dbAddress2.addLine3, '') + ' ' + ISNULL(dbAddress2.addLine4, '') + ' '
                           + ISNULL(dbAddress2.addLine5, '') + ' ' + ISNULL(dbAddress2.addPostcode, '')
                   END AS [Insured Address],
                   dbAssociates.assocRef AS [Insured Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress1 WITH (NOLOCK)
                    ON assocdefaultaddID = dbAddress1.addID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress2 WITH (NOLOCK)
                    ON contDefaultAddress = dbAddress2.addID
            WHERE assocType = 'INSUREDCLIENT'
        ) AS MSvatAddress
            ON dim_matter_header_current.ms_fileid = MSvatAddress.fileID
               AND MSvatAddress.XOrder = 1
        ---- below added per request 8366              
        LEFT OUTER JOIN
        (
            SELECT fact_bill_detail.client_code,
                   fact_bill_detail.matter_number,
                   SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2015/2016],
                   SUM(fact_bill_detail.workhrs) AS [Hours Billed 2015/2016]
            FROM red_dw.dbo.fact_bill_detail
                INNER JOIN red_dw.dbo.dim_bill_date
                    ON fact_bill_detail.dim_bill_date_key = dim_bill_date.dim_bill_date_key
            WHERE dim_bill_date.bill_date
                  BETWEEN '2015-05-01' AND '2016-04-30'
                  AND charge_type = 'time'
            GROUP BY fact_bill_detail.client_code,
                     fact_bill_detail.matter_number
        ) AS Revenue2015
            ON dim_matter_header_current.client_code = Revenue2015.client_code
               AND dim_matter_header_current.matter_number = Revenue2015.matter_number
        LEFT OUTER JOIN
        (
            SELECT fact_bill_detail.client_code,
                   fact_bill_detail.matter_number,
                   SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2016/2017],
                   SUM(fact_bill_detail.workhrs) AS [Hours Billed 2016/2017]
            FROM red_dw.dbo.fact_bill_detail
                INNER JOIN red_dw.dbo.dim_bill_date
                    ON fact_bill_detail.dim_bill_date_key = dim_bill_date.dim_bill_date_key
            WHERE dim_bill_date.bill_date
                  BETWEEN '2016-05-01' AND '2017-04-30'
                  AND charge_type = 'time'
            GROUP BY fact_bill_detail.client_code,
                     fact_bill_detail.matter_number
        ) AS Revenue2016
            ON dim_matter_header_current.client_code = Revenue2016.client_code
               AND dim_matter_header_current.matter_number = Revenue2016.matter_number
        LEFT OUTER JOIN
        (
            SELECT fact_bill_detail.client_code,
                   fact_bill_detail.matter_number,
                   SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2017/2018],
                   SUM(fact_bill_detail.workhrs) AS [Hours Billed 2017/2018]
            FROM red_dw.dbo.fact_bill_detail
                INNER JOIN red_dw.dbo.dim_bill_date
                    ON fact_bill_detail.dim_bill_date_key = dim_bill_date.dim_bill_date_key
            WHERE dim_bill_date.bill_date
                  BETWEEN '2017-05-01' AND '2018-04-30'
                  AND charge_type = 'time'
            GROUP BY fact_bill_detail.client_code,
                     fact_bill_detail.matter_number
        ) AS Revenue2017
            ON dim_matter_header_current.client_code = Revenue2017.client_code
               AND dim_matter_header_current.matter_number = Revenue2017.matter_number
        LEFT OUTER JOIN
        (
            SELECT fact_bill_detail.client_code,
                   fact_bill_detail.matter_number,
                   SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2018/2019],
                   SUM(fact_bill_detail.workhrs) AS [Hours Billed 2018/2019]
            FROM red_dw.dbo.fact_bill_detail
                INNER JOIN red_dw.dbo.dim_bill_date
                    ON fact_bill_detail.dim_bill_date_key = dim_bill_date.dim_bill_date_key
            WHERE dim_bill_date.bill_date
                  BETWEEN '2018-05-01' AND '2019-04-30'
                  AND charge_type = 'time'
            GROUP BY fact_bill_detail.client_code,
                     fact_bill_detail.matter_number
        ) AS Revenue2018
            ON dim_matter_header_current.client_code = Revenue2018.client_code
               AND dim_matter_header_current.matter_number = Revenue2018.matter_number
    WHERE dim_matter_header_current.matter_number <> 'ML'
          AND dim_client.client_code NOT IN ( '00030645', '95000C', '00453737' )
		  AND dim_matter_header_current.client_group_name = 'NHS Resolution'
          AND dim_matter_header_current.reporting_exclusions = 0
          AND
          (
              dim_matter_header_current.date_closed_case_management >= @nDate
              OR dim_matter_header_current.date_closed_case_management IS NULL
          );
--AND dim_matter_header_current.date_opened_case_management >= '2015-01-01'




END;

GO
