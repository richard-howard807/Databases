SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Insurance Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[InsurancehDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT
				 RTRIM(dimmain.client_code)+'/'+dimmain.matter_number AS [Weightmans Reference]
				,dimmain.client_code AS [Client Code]
				,dimmain.matter_number AS [Matter Number]
				,core_details.[jaguar_nature_of_claim] AS [Nature of Claim]
				,core_details.[grpageas_claim_category] AS [Claim Category]
				,core_details.[mib_grp_type_of_injury] AS [Type of Injury]
				,core_details.does_claimant_have_personal_injury_claim AS [Does Claimant Have Personal Injury Claim?]
				,core_details.[zurich_grp_rmg_was_litigation_avoidable] AS [Litigation Avoidable]
				,core_details.[clients_claims_handler_surname_forename] AS [Clients Claim Handler]
				,core_details.[incident_location_postcode] AS [Incident Location Postcode]
				,core_details.[has_the_claimant_got_a_cfa] AS [Has Claimant got a CFA?]
				,core_details.coop_guid_reference_number AS [Co-op Guid Ref Number]
				,COALESCE(core_details.[moj_apply],dim_detail_critical_mi.[portal_claim]) AS [MOJ Apply]
				,core_details.claimant_in_person AS [Claimant in Person]
				,core_details.delegated AS Delegated
				,core_details.insured_sector AS [Insured Sector]
				,core_details.ll01_sex AS Gender
				,core_details.ll02_legal_status AS [Legal Status]
				,core_details.ll09_initial_glasgow_coma_scale AS [Initial Glasgow Coma Scale]
				,core_details.ll11_frontal_lobe_damage AS [Frontal Lobe Damage]
				,core_details.ll13_level_of_spinal_cord_injury AS [Level of Spinal Cord Injury]
				,core_details.ll17_marital_status AS [Marital Status]
				,core_details.mib_grp_type_of_injury AS [Type Of Injury]
				,core_details.motor_status AS [Motor Status]
				,core_details.will_total_gross_reserve_on_the_claim_exceed_500000 AS [Total Gross Reserve on Claim > £500,000?]
				,core_details.zurich_branch AS [Zurich Branch]
				,core_details.zurich_line_of_business AS [Zurich Line of Business]
				,Client_Involv.[insurerclient_reference] AS [Insurer Client Ref]
				,detail_fraud.[fraud_current_fraud_type] AS [Current Fraud Type]
				,detail_fraud.[fraud_initial_fraud_type] AS [Initial Fraud Type]
				,detail_fraud.[potential_recovery] AS [Potential Recovery]
				,detail_hire_details.[cha_are_we_in_reciept_of_payment_pack] AS [In Reciept of Payment Pack]
				,detail_hire_details.[chb_date_engineer_instructed] AS [Date Engineer Instructed]
				,detail_hire_details.[chc_date_vehicle_inspected] AS [Date Vehicle Inspected]
				,detail_hire_details.[chd_date_of_engineers_report] AS [Date of Engineers Report]
				,detail_hire_details.[che_date_repairs_commenced] AS [Date Repairs Commenced]
				,detail_hire_details.[chf_date_satisfaction_note_signed] AS [Date Satisfaction Note Signed]
				,detail_hire_details.[chh_is_the_vehicle_a_total_loss] AS [Vehicle a Total loss]
				,detail_hire_details.[chj_date_payment_pack_received] AS [Date Payment Pack Received]
				,detail_hire_details.[chn_cho_vehicle_registration] AS [CHO Vehicle Registration]
				,detail_hire_details.[cho_postcode] AS [CHO Postcode]
				,detail_hire_details.[chq_hire_group_billed] AS [Hire Group Billed]
				,detail_hire_details.[chs_hire_invoice_date] AS [Hire Invoice Date]
				,detail_hire_details.[chx_is_the_claimant_impecunious] AS [Claimant Impecunious?]
				,core_details.[are_we_dealing_with_the_credit_hire] AS [Are we Dealing with the Credit Hire?]
				,detail_hire_details.[claim_for_hire] AS [Claim for Hire]
				,detail_hire_details.[coopch_applicable_rate] AS [Penalties Paid]
				,detail_hire_details.[coopch_claim_type] AS [Claim Type]
				,detail_hire_details.[coopch_gta] AS GTA
				,detail_hire_details.[coopch_protocol] AS Protocol
				,detail_hire_details.[coopch_savings_area] AS [Savings Area]
				,detail_hire_details.[coopch_spot_enquiry_made] AS [Spot Enquiry Made]
				,detail_hire_details.[date_vehicle_written_off] AS [Date Vehicle Written Off]
				,detail_hire_details.chv_date_hire_paid AS [CHV Date Hire Paid]
				,detail_hire_details.claim_for_hire AS [Claim for Hire]
				,detail_outcome.[mib_grp_costs_negotiators_used] AS [Costs Negotiators Used]
				,detail_outcome.are_we_pursuing_a_recovery AS [Are we Pursuing a Recovery?]
				,dim_detail_claim.[date_recovery_concluded] AS [Date Recovery Concluded]
				,detail_outcome.date_referral_to_costs_unit AS [Date Referral to Costs Unit]
				,detail_outcome.recovery_claimants_our_client_damages AS [Recovery Claimants Our Client Damages]
				,detail_outcome.sabre_admin_closure_date AS [Sabre Closure Date]
				,fact_client.[chg_value_of_pav_repairs] AS [Value of PAV/Repairs]
				,fact_client.[chy_interim_payment_made] AS [Interim Payments?]
				,fact_client.[commercial_rate] AS [Commercial Rate]
				,fact_client.[coop_current_estimate] AS [Current Estimate]
				,fact_client.[coopch_30_day_sum] AS [30-day sum]
				,fact_client.[coopch_60_day_sum] AS [60-day sum]
				,fact_client.[coopch_90_day_sum] AS [90-day sum]
				,fact_client.[zurich_general_damages_psla_only] AS [General Damages Paid]
				,fact_client.[zurich_special_damages] AS [Special Damages Paid]
				,fact_client.claimants_solicitors_hours_claimed AS [Claimants Solicitors Hours Claimed]
				,fact_client.number_of_claimants AS [Number of Claimants]
				,fact_client.number_of_defendants AS [Number of Defendants]
				,fact_client.percent_of_clients_liability_agreed_prior_to_instruction AS [% of Client's Liability Agreed Prior to Instruction]
				,fact_client.percent_of_clients_liability_awarded_agreed_post_insts_applied as [% of Client's Liability Awarded/Agreed Post insts/applied]
				,fact_client.percent_of_contributory_negligence_agreed AS [% of Contributory Negligence Agreed]
				,fact_future_care.annual_periodic_hundred_percent AS [Annual Periodic - 100%]
				,fact_future_care.annual_pp_net_amount AS [Annual Periodic Net]
				,fact_future_care.final_total_costs AS [Final Total Costs]
				,fact_future_care.global_settlement AS [Global Settlement]
				,fact_future_care.liability_initial_advice AS [Liability Initial Advice]
				,fact_future_care.liability_updated_advice AS [Liability Updated Advice]
				,fact_future_care.pct_annual_contribution_period_1 AS [PCT annual contribution (period 1)]
				,fact_future_care.pct_annual_contribution_period_2 AS [PCT annual contribution (period 2)]
				,fact_future_care.pct_annual_contribution_period_3 AS [PCT annual contribution (period 3)]
				,fact_future_care.pct_annual_contribution_period_4 AS [PCT annual contribution (period 4)]
				,fact_reserve_detail.[amount_of_debt] AS [Amount of Debt]
				,fact_reserve_detail.[hire_reserve] AS [Hire Reserve]
				,fact_reserve_detail.[general_damages_reserve_current] AS [General Damages Reserve Current]
				,fact_reserve_detail.[general_damages_reserve_initial] AS [General Damages Reserve Initial]
				,fact_reserve_detail.[special_damages_reserve_current] AS [Special Damages Reserve Current] 
				,fact_reserve_detail.[special_damages_reserve_initial] AS [Special Damages Reserve Initial]
				,fact_reserve_detail.converge_disease_reserve AS [Converge Disease Reserve]
				--,fact_reserve_detail.aids_and_equipment_reserve_initial_hundred_percent AS [Aids and equipment reserve (initial) 100%]
				--,fact_reserve_detail.care_cost_reserve_initial_hundred_percent AS [Care cost reserve (initial) 100%]
				--,fact_reserve_detail.court_of_protection_reserve_initial_hundred_percent AS [Court of protection reserve (initial) 100%]
				--,fact_reserve_detail.domestic_diy_reserve_initial_hundred_percent AS [Domestic DIY reserve (initial) 100%]
				--,fact_reserve_detail.future_aids_equipment_reserve_initial_hundred_percent AS [Future aids & equipment reserve (initial) 100%]
				--,fact_reserve_detail.future_care_reserve_initial_hundred_percent AS [Future Care Reserve (Initial) 100%]
				--,fact_reserve_detail.future_case_manager_reserve_initial_hundred_percent AS [Future case manager reserve (initial) 100%]
				--,fact_reserve_detail.future_loss_of_wages_reserve_initial_hundred_percent AS [Future loss of wages reserve (initial) 100%]
				--,fact_reserve_detail.general_damages_reserve_initial AS [General Damages Reserve Initial]
				--,fact_reserve_detail.holidays_reserve_initial_hundred_percent AS [Holidays Reserve Initial Hundred Percent]
				--,fact_reserve_detail.hospital_charges_reserve_initial AS [Hospital Charges Reserve Initial]
				--,fact_reserve_detail.housing_alterations_reserve_initial_hundred_percent AS [Housing alterations reserve (initial) 100%]
				--,fact_reserve_detail.housing_reserve_initial_hundred_percent AS [Housing reserve (initial) 100%]
				--,fact_reserve_detail.interest_on_general_damages_reserve_initial_hundred_percent AS [Interest on general damages reserve (initial) 100%]
				--,fact_reserve_detail.interest_on_special_reserve_initial_hundred_percent AS [ Interest on special reserve (initial) 100%]
				--,fact_reserve_detail.ll29_own_legal_costs_disbs_reserve_initial AS [Own legal costs disbs reserve (initial) 100%]
				--,fact_reserve_detail.medical_physio_reserve_initial_hundred_percent AS [Medical physio reserve (initial) 100%]
				--,fact_reserve_detail.misc_specials_reserve_initial_hundred_percent AS [Misc specials reserve (initial) 100%]
				--,fact_reserve_detail.net_wage_loss_reserve_initial_hundred_percent AS [Net wage loss reserve (initial) 100%]
				--,fact_reserve_detail.other_housing_etc_reserve_initial_hundred_percent AS [Other, housing, etc reserve (initial) 100%]
				--,fact_reserve_detail.pension_loss_reserve_initial_hundred_percent AS [Pension loss reserve (initial) 100%]
				--,fact_reserve_detail.rehab_ina_reserve_initial_hundred_percent AS [Rehab INA reserve (initial) 100%]
				--,fact_reserve_detail.s_v_m_award_reserve_initial_hundred_percent AS [S v M award reserve (initial) 100%]
				--,fact_reserve_detail.transport_reserve_initial_hundred_percent AS [Transport reserve (initial) 100%]
				--,fact_reserve_detail.[nhs_charges_reserve_current] AS [NHS Charges Reserve (Current)]
				--,fact_reserve_detail.future_loss_misc_reserve_current AS [Future Loss - Misc Reserve (Current)]
				--,fact_reserve_detail.future_loss_of_earnings_reserve_current AS [Future Loss of Earnings Reserve (current)]
				--,fact_reserve_detail.past_care_reserve_current AS [Past Care Reserve (Current)]
				--,fact_reserve_detail.past_loss_of_earnings_reserve_current AS [Past Loss of Earnings Reserve (Current)]
				--,fact_reserve_detail.general_damages_non_pi_misc_reserve_current AS [General Damages Non PI  Misc Reserve (Current)]
				--,fact_reserve_detail.future_care_reserve_current AS [Future Care Reserve (Current)]
				--,ISNULL(fact_detail_cost_budgeting.[personal_injury_reserve_current],0)+ISNULL(fact_reserve_detail.general_damages_non_pi_misc_reserve_current,0) AS [General Damages]
				--,ISNULL(fact_reserve_detail.past_care_reserve_current,0)+ISNULL(fact_reserve_detail.[past_loss_of_earnings_reserve_current],0)+ISNULL(fact_finance_summary.[special_damages_miscellaneous_reserve],0) AS [Special Damages]
				--,ISNULL(fact_finance_summary.[defence_costs_reserve],0)+ISNULL(fact_finance_summary.[other_defendants_costs_reserve],0) AS [Defence Costs]
				--,ISNULL(fact_detail_cost_budgeting.[personal_injury_reserve_current],0)+ISNULL(fact_reserve_detail.general_damages_non_pi_misc_reserve_current,0) + --General Damages
				-- ISNULL(fact_reserve_detail.[nhs_charges_reserve_current],0) + --NHS Charges Reserve Current
				-- ISNULL(fact_reserve_detail.future_loss_of_earnings_reserve_current,0) + --Future Loss of Earnings Reserve (current)
				-- ISNULL(fact_reserve_detail.future_care_reserve_current,0) + --Future Care Reserve (Current)
				-- ISNULL(fact_finance_summary.[tp_costs_reserve],0) + --Claimant's Cost Reserve Current
				-- ISNULL(fact_finance_summary.[defence_costs_reserve],0)+ISNULL(fact_finance_summary.[other_defendants_costs_reserve],0) +  --Defence Costs
				-- ISNULL(fact_reserve_detail.future_loss_misc_reserve_current,0) + --Future Loss - Misc Reserve (Current)
				-- ISNULL(fact_reserve_detail.past_care_reserve_current,0)+ISNULL(fact_reserve_detail.[past_loss_of_earnings_reserve_current],0)+ISNULL(fact_finance_summary.[special_damages_miscellaneous_reserve],0) --Special Damages
				-- AS [Total Live Reserve]
				--,coalesce(core_details.[ll08_liability_updated_advice_percent],core_details.[ll07_liability_initial_advice_percent],100) AS [Liability Percentage Reserve]
				,dim_detail_claim.claimant_medical_expert AS [Claimant Medical Expert]
				,dim_detail_claim.division_name AS [Division Name]
				,core_details.[grpageas_case_handler] AS [Ageas Case Handler]
				,dim_detail_claim.ageas_instruction_type AS [Ageas Instruction Type]
				,dim_detail_client.zurich_claimants_sols_firm AS [Zurich Claimant's Solicitors]
				,dim_detail_client.zurich_claimants_name AS [Zurich Claimant]
				,dim_detail_practice_area.[zurichrsa_claim_number] AS [Zurich Claim Number]
				,core_details.zurich_policy_holdername_of_insured AS [Zurich Policy Holder Name]
				,dim_detail_claim.location_of_claimants_workplace AS [Location of Claimant's Workplace]
				,dim_detail_claim.location_of_claimant_solicitors AS [Location of Claimant's Solicitors]
				,dim_detail_practice_area.supervisor_review_date AS [Supervisor Review Date]
				,dim_detail_practice_area.supervisor_comment AS [Supervisor Comment]
				,dim_detail_health.case_handler_review_comment AS [Case Manager Review Comment]
				,dim_detail_client.date_settlement_form_sent_to_zurich AS [Date Settlement Form sent to Zurich]
				,dim_detail_litigation.reason_for_litigation AS [Reason for Litigation]
				,dim_detail_litigation.sub_reason_litigation AS [Sub Reason Litigation]
				,'' AS [LIT0601 Planned Date]
				,detail_outcome.[repudiated] AS [Repudiated - Insurance]
				,detail_outcome.[status_historic] AS [Historic Status]
				,fact_detail_paid_detail.[amount_hire_paid] AS [Hire Paid]
				,fact_detail_paid_detail.[hire_claimed] AS [Hire Claimed]
				,detail_hire_details.[hire_paid_rolling] AS [Hire Paid Rolling]
				,dim_detail_claim.tier_1_3_case
				,core_details.[grpageas_reason_for_instruction] AS [Reason for Instruction]
				,dim_detail_litigation.[reason_litigation_not_avoided] AS [Reason Litigation not Avoided]
				,dim_detail_claim.[reason_for_reopening_request] AS [Reason for Re-opening Request]
				,core_details.[aig_aig_department] AS [AIG Department]
				,core_details.[aig_instructing_office] AS [AIG Instructing Office]
				,core_details.[aig_current_fee_scale] AS [AIG Current Fee Scale]
				,dim_detail_client.hide_flag AS [AIG Hide Flag]
				,dim_detail_client.[aig_litigation_number] AS [AIG Litigation Number]
				,core_details.[aig_line_of_business] AS [AIG Line of Business]
				,dim_detail_claim.[cfa_entered_into_before_1_april_2013] AS [CFA entered into before 1 April 2013]
				,dim_detail_claim.[cnf_received_date] AS [Date CNF sent]
				,dim_detail_practice_area.[who_dropped_the_claim_out_of_portal] AS [Who Dropped the Claim out of Portal?]
				,core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler] AS [Date Initial Acknowledgement sent to Claims Handler]
				,detail_outcome.[date_indemnity_settled] AS [Date Indemnity Settled]
				,detail_outcome.[mib_name_of_costs_negotiators] AS [Name of Costs Negotiators]
				,dim_detail_claim.[capita_stage_of_settlement] AS [Capita Stage of Settlement]
				,dim_detail_advice.ioint_settlement_meeting AS [Joint Settlement Meeting]
				,core_details.[motor_date_of_instructions_being_reopened] AS [Date Re-opened]
				,dim_detail_claim.[ageas_office] as [Ageas/Tesco Office]
				,dim_detail_claim.[name_of_instructing_insurer] AS [Name of Instructing Insurer]
				,CASE WHEN dim_client.client_code IN ('Q00001', 'Q00002','00703645')  THEN 'Tab1'
									 ELSE 'Tab2' END AS ReportTab
				,DATEPART(YY,detail_outcome.mib_grp_zurich_pizza_hut_date_of_final_bill) AS YearFinalBill_Zurich 
				,CASE WHEN core_details.grpageas_motor_moj_stage IS NULL THEN core_details.track 
					  ELSE core_details.grpageas_motor_moj_stage 
					  END AS [Ageas Track]
				,CASE WHEN dim_client.client_code IN ('00162925','GRP001')  THEN 'Client 1'
					  WHEN dim_client.client_code='00046018' THEN 'Client 2'
					  WHEN dim_client.client_code='S00016' THEN 'Client 3'
					  WHEN dim_client.client_code IN('00006868','00006866') THEN 'Client 4'
					  WHEN dim_client.client_code IN ('Q00001', 'Q00002') THEN 'Quinn Direct'
					  ELSE dim_client.client_name
					  END AS [Client Name - Quinn Direct]
				,(CASE WHEN detail_outcome.outcome_of_case IN ('Won at trial','Won') THEN 'Won at Trial' 
					  WHEN detail_outcome.outcome_of_case IN ('Lost at trial','Lost') THEN 'Lost at Trial' 
					  WHEN detail_outcome.outcome_of_case IN ('Settled','Settled - mediation','Settled - infant approval') THEN 'Settled' 
					  WHEN detail_outcome.outcome_of_case  IN ('Discontinued','Discontinued - no costs order','Discontinued - post-lit with costs order','Discontinued - post-lit with no costs order','Discontinued - pre-lit') THEN 'Discontinued' 
					  WHEN detail_outcome.outcome_of_case = 'Struck out' THEN  'Struck out'  WHEN detail_outcome.outcome_of_case in ( 'Assessment of damages','Damages assessed') THEN  'Assessment of damages'  
					  WHEN  ISNULL(detail_outcome.outcome_of_case,'')  = '' THEN  'Other'  Else 'Other' END) AS GroupamaOutcome 
				, CASE WHEN RTRIM(ISNULL(core_details.present_position,'')) IN ('','Claim and costs outstanding','Claim and costs concluded but recovery outstanding') AND (dim_client.client_group_name = 'Ageas')THEN 1 
					  ELSE 0 
					  END AS [Live Claim Ageas]
				, CASE WHEN RTRIM(ISNULL(core_details.present_position,'')) IN ('','Claim and costs outstanding','Claim and costs concluded but recovery outstanding') AND (ISNULL(dim_client.client_group_name,'') <> 'Ageas') THEN 1 
					  ELSE 0 
					  END AS [Live Claim - Other Clients]
				, CASE WHEN dim_matter_worktype.[work_type_name] LIKE 'EL%'  OR dim_matter_worktype.[work_type_name] LIKE 'PL%' THEN 'EL/PL'
					WHEN dim_matter_worktype.[work_type_name] LIKE 'Disease%'  THEN 'Disease'
					WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] IN('Motor Investigation Unit Liverpool','Motor Fraud','Organised Fraud') THEN 'Motor Fraud'
					WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE '%Large Loss%' THEN 'Large Loss'
					WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE '%Multi Track%' THEN 'Multi Track'
					WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE '%Fast Track%' THEN 'Fast Track'
					ELSE 'Other' END AS [Claim Type - Insurance]
				, CASE WHEN (CASE WHEN detail_hire_details.[credit_hire_organisation_cho] = 'Other' or detail_hire_details.[credit_hire_organisation_cho] is null THEN detail_hire_details.[new_existing] ELSE detail_hire_details.[credit_hire_organisation_cho] END) IS NULL THEN
					COALESCE(dim_agents_involvement.[cho_name],dim_claimant_thirdparty_involvement.[tpaccmancomp_name]) ELSE
					(CASE WHEN detail_hire_details.[credit_hire_organisation_cho] = 'Other' or detail_hire_details.[credit_hire_organisation_cho] is null THEN detail_hire_details.[new_existing] ELSE detail_hire_details.[credit_hire_organisation_cho] END)
					END [Credit Hire Organisation]
				, CASE WHEN detail_outcome.[outcome_of_case] LIKE '%Settled' OR detail_outcome.[outcome_of_case] LIKE '%Assessment' OR detail_outcome.[outcome_of_case] LIKE '%Lost' THEN 'Settled'
					WHEN detail_outcome.[outcome_of_case] LIKE '%Struck' OR detail_outcome.[outcome_of_case] LIKE '%Won' OR detail_outcome.[outcome_of_case] LIKE '%Discontinued' THEN 'Repudiated'
					ELSE '' END AS [Repudiated/Settled]

				, CASE WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%tetrapleg%' then 'Tetraplegic' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%chronic pain syndrome%' then 'Chronic Pain Syndrome' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%paraplegi%' then 'Paraplegic' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%amputation%' then 'Amputation' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%head%' or lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%brain%' then 'TBI' 
					WHEN coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type]) is NULL then NULL else 'Other' end  AS [Injury Type Group]
				, dim_detail_claim.[settlement_basis] AS [Settlement Basis]
				, case when lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%liverpool%' then 'Liverpool' 
					WHEN lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%london%' then 'London' 
					WHEN lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%birmingham%' then 'Birmingham' 
					WHEN lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%midlands%' then 'Birmingham' 
					when lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%leicester%' then 'Leicester' 
					when lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%manchester%' then 'Manchester' 
					when lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%leeds%' then 'Leeds' 
					when lower(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%glasgow%' then 'Glasgow' 
					else dim_fed_hierarchy_history.[hierarchylevel4hist] end AS [Team Location]
				, cast(case when detail_outcome.[date_claim_concluded] is null and (detail_outcome.[outcome_of_case] is null or rtrim(detail_outcome.[outcome_of_case]) = 'matter ongoing') then DATEDIFF(d, case when core_details.[date_instructions_received] < dim_matter_header_current.date_opened_case_management then core_details.[date_instructions_received] when dim_matter_header_current.date_opened_case_management  >=  core_details.[date_instructions_received] then dim_matter_header_current.date_opened_case_management  else isnull(dim_matter_header_current.date_opened_case_management , core_details.[date_instructions_received]) end ,getdate()) else NULL end as int) AS [Elapsed Days Live]
				, CASE WHEN --(MaxFinalBillPaidDate >= MaxInterimBillDate AND MaxInterimBillDate IS NOT NULL) OR
							dim_matter_header_current.date_closed_case_management IS NOT NULL 
							OR (ISNULL(detail_outcome.[outcome_of_case],'') = 'Exclude from reports' AND dim_detail_client.[europcartransferred_file]='Yes')
                     THEN ( CASE WHEN detail_outcome.[aig_outcome_of_instruction] IS NULL
                                 THEN ( CASE WHEN detail_outcome.[outcome_of_case] LIKE '%Settled%' OR ISNULL(core_details.[referral_reason], '') = 'Pre-action disclosure' THEN 'Settled'
                                             WHEN detail_outcome.[outcome_of_case] LIKE '%Discontinued%' OR detail_outcome.[outcome_of_case] LIKE '%Struck%' THEN 'Successfully defended (no indemnity payment)'
                                             WHEN detail_outcome.[outcome_of_case] LIKE '%Lost%' OR detail_outcome.[outcome_of_case] = 'Assessment of damages' THEN 'Trial (lost)'
                                             WHEN detail_outcome.[outcome_of_case] = 'Won at trial' THEN 'Trial (Won - no indemnity payment)'
                                             WHEN detail_outcome.[outcome_of_case] = 'Assessment of damages (claimant fails to beat Part 36 offer)' THEN 'Trial (Won - successful Part 36 offer)'
                                             ELSE detail_outcome.[outcome_of_case]
                                        END )
                                 ELSE detail_outcome.[aig_outcome_of_instruction]
                            END )
                     ELSE NULL
                END AS [Outcome of Instruction]

				, CASE WHEN core_details.[motor_date_of_instructions_being_reopened] IS NULL THEN DATEDIFF(DAY, COALESCE(core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management),detail_outcome.[date_claim_concluded]) 
					WHEN core_details.[motor_date_of_instructions_being_reopened] IS NOT NULL THEN DATEDIFF(DAY, COALESCE(core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management),detail_outcome.[date_claim_concluded]) + DATEDIFF(DAY, core_details.[motor_date_of_instructions_being_reopened],detail_outcome.[date_claim_concluded]) END  [Elapsed Days to Conclusion]
				, CASE WHEN core_details.[motor_date_of_instructions_being_reopened] IS NULL THEN DATEDIFF(DAY, COALESCE(core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management),detail_outcome.[date_costs_settled]) 
					WHEN core_details.[motor_date_of_instructions_being_reopened] IS NOT NULL THEN DATEDIFF(DAY, COALESCE(core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management),detail_outcome.[date_claim_concluded]) + DATEDIFF(DAY, core_details.[motor_date_of_instructions_being_reopened],detail_outcome.[date_costs_settled]) END [Elapsed Days to Costs Conclusion]

				, CASE WHEN dim_client.client_code IN ('00006864','00046383','00054852') AND dim_department.[department_name]<>'Disease' AND (dim_fed_hierarchy_history.[hierarchylevel4hist] NOT LIKE ('%Costs%') OR  (dim_fed_hierarchy_history.[hierarchylevel4hist] <> 'Disease Fraud')) THEN 'Casualty non disease'
					WHEN dim_client.client_code='00006864' AND dim_department.[department_name] IN ('Disease', 'Fraud') AND dim_fed_hierarchy_history.[hierarchylevel4hist]<>'Casualty Fraud' THEN 'Casualty disease'
					WHEN dim_client.client_code='00006865' THEN 'Major Loss'
					WHEN dim_fed_hierarchy_history.[hierarchylevel4hist] ='Motor Fraud' THEN 'Motor Fraud'
					WHEN dim_client.client_code IN ('00006861', '00006866', '00006868', '00006876') AND dim_fed_hierarchy_history.[hierarchylevel4hist] NOT LIKE '%Costs%' THEN 'Motor'
					WHEN dim_department.[department_name]='Costs' AND dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE '%Costs%' THEN 'Costs'
					WHEN dim_client.client_code='00006864' AND dim_department.[department_name] IN ('Weightmans One','Large loss/Catastrophic','Commercial Insurance','NHS') AND dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE '%Costs%' THEN 'Casualty non disease'
					WHEN dim_client.client_code ='00006861' AND dim_department.[department_name]='Fraud' AND dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE '%Costs%' THEN 'Motor'
					WHEN dim_client.client_code='00006876' AND dim_department.[department_name]='Motor' AND dim_fed_hierarchy_history.[hierarchylevel4hist] LIKE '%Costs%' THEN 'Motor'
				ELSE NULL END AS [AIG Weightmans Department]
			  , [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management) AS [Days from Instructed to Opened]
			  , [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler]) AS [Days from Instructed to Acknowledgement]
			  , [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[date_initial_report_sent]) AS [Days from Instructed to Intial Report Sent]
			  , [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],detail_outcome.[date_indemnity_settled]) AS [Elapsed Days from Instructed to Indemnity Settled]
			  , [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],detail_outcome.[date_costs_settled]) AS [Elapsed Days from Instructed to Costs Settled]
			  , [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],dim_matter_header_current.date_closed_case_management) AS [Elapsed Days from Instructed to Closed]
			  , CASE WHEN detail_outcome.[date_claim_concluded] IS NULL THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],GETDATE()) 
                ELSE [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],detail_outcome.[date_claim_concluded])
                END  AS [Live Elapsed Days from Date Instructed]
			, CASE WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received], GETDATE())<=2 THEN 'Not yet due'
					WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management) <=2 THEN 'Within 2 days'
					WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management) >2 THEN 'More than 2 days'
					ELSE NULL END AS [File Opened]
			  , CASE WHEN core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler] IS NULL AND
						 [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received], GETDATE())<=2 THEN 'Not yet due'
					WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler]) <=2 THEN 'Within 2 days'
					WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler]) >2 THEN 'More than 2 days'
					ELSE NULL END AS [Acknowledgement]
			  , CASE WHEN core_details.[date_initial_report_sent] IS NULL AND
						[dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received], GETDATE())<=10 THEN 'Not yet due'
					WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[date_initial_report_sent]) <=10 THEN 'Within 10 days'
					WHEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](core_details.[date_instructions_received],core_details.[date_initial_report_sent]) >10 THEN 'More than 10 days'
					ELSE NULL END AS [Initial Report Sent]
			  --, CASE WHEN core_details.[motor_status]= 'Cancelled' THEN 'Closed'
     --                WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL 
     --                OR (dim_detail_client.[europcartransferred_file]='Yes') THEN 'Closed'
     --                ELSE 'Open' END AS [AIG Filestatus]
			 , CASE WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL  THEN 'Closed'
					WHEN core_details.present_position IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') THEN 'Closed'
					WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open'
					WHEN core_details.present_position <> 'Final bill sent - unpaid' OR core_details.present_position <>'To be closed/minor balances to be clear' THEN 'Open' END AS [AIG Filestatus]
			 , CASE WHEN detail_outcome.[final_bill_date_grp] IS NULL THEN 'Outstanding' ELSE 'Concluded' END AS [Ageas Claim Status]
			 , DATEDIFF(dd,core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management) AS [Days to Open File]

		FROM 
		red_dw.dbo.fact_dimension_main AS dimmain
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details AS core_details ON core_details.dim_detail_core_detail_key = dimmain.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_client_involvement AS Client_Involv ON Client_Involv.dim_client_involvement_key = dimmain.dim_client_involvement_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud AS detail_fraud ON detail_fraud.dim_detail_fraud_key=dimmain.dim_detail_fraud_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details AS detail_hire_details ON detail_hire_details.dim_detail_hire_detail_key= dimmain.dim_detail_hire_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome AS detail_outcome ON detail_outcome.dim_detail_outcome_key=dimmain.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_client AS fact_client ON fact_client.master_fact_key= dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_future_care AS fact_future_care ON fact_future_care.master_fact_key=dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail AS fact_reserve_detail ON fact_reserve_detail.master_fact_key=dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_claim AS dim_detail_claim ON dim_detail_claim.dim_detail_claim_key=dimmain.dim_detail_claim_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=dimmain.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client ON dim_client.dim_client_key = dimmain.dim_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_client AS dim_detail_client ON dim_detail_client.dim_detail_client_key = dimmain.dim_detail_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_litigation AS dim_detail_litigation ON dim_detail_litigation.dim_detail_litigation_key = dimmain.dim_detail_litigation_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_health AS dim_detail_health ON dim_detail_health.dim_detail_health_key = dimmain.dim_detail_health_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area AS dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = dimmain.dim_detail_practice_ar_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND getdate() BETWEEN dss_start_date AND dss_end_date 
		LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement ON dim_agents_involvement.dim_agents_involvement_key = dimmain.dim_agents_involvement_key
		LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = dimmain.dim_claimant_thirdpart_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_future_care ON dim_detail_future_care.dim_detail_future_care_key=dimmain.dim_detail_future_care_key
		--LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting ON fact_detail_cost_budgeting.master_fact_key = dimmain.master_fact_key
		--LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_department ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = dimmain.dim_detail_critical_mi_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = dimmain.dim_detail_advice_key

		WHERE 
		ISNULL(detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
		AND dim_matter_header_current.reporting_exclusions=0
		AND (dim_matter_header_current.date_closed_case_management >= '20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)



		--ORDER BY dimmain.matter_number

END

GO
