SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-08-03
Description:		Large Loss Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[LargeLossDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT 
				 RTRIM(dimmain.client_code)+'/'+dimmain.matter_number AS [Weightmans Reference]
				, dimmain.client_code AS [Client Code]
				, dimmain.matter_number AS [Matter Number]
				, dim_matter_header_current.[matter_description] AS [Matter Description]
				, detail_outcome.date_claim_concluded AS [Date Claim Concluded]
				, dim_fed_hierarchy_history.[name] AS [Case Manager]
				, dim_matter_header_current.[matter_partner_full_name] AS [Partner Name]
				, dim_fed_hierarchy_history.[hierarchylevel2hist] [Business Line]
				, dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Practice Area]
				, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
				, dim_department.[department_code] AS [Department Code]
				, dim_department.[department_name] AS [Department]
				--, dim_claimant_address.[claimant_1_forename]+' '+ dim_claimant_thirdparty_involvement.[claimant_name] AS [Claimant Name]
				--, dim_claimant_address.[claimant1_postcode] AS [Claimant's Postcode]
				, core_details.[present_position] AS [Present Position] --TRA125
				, CASE WHEN RTRIM(core_details.[present_position]) = 'To be closed/minor balances to be clear' or RTRIM(core_details.[present_position]) = 'Final bill sent - unpaid' then 'Concluded' else 'Outstanding' end AS [Status]
				, dim_client.client_name AS [Client Name]
				, dim_matter_worktype.[work_type_code] AS [Work Type Code]
				, dim_matter_worktype.[work_type_name] AS [Work Type]
				--[Weightmans Branch]
				, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
				, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
				, dim_claimant_thirdparty_involvement.[claimantsols_name] AS [Claimant's Solicitor]
				, core_details.[name_of_claimants_solicitor_surname_forename] AS [Name of Claimant's Solicitor (individual)] --NMI571
				, core_details.date_instructions_received AS [Date Instructions Received] --TRA094
				, core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an extension for the initial report?] --NMI613
				, core_details.[date_initial_report_due] AS [Date Initial Report Due] --NMI614
				, core_details.[date_initial_report_sent] AS [Date Initial Report Sent] --FTR083
				, core_details.[incident_date] AS [Incident Date] --DOA
				, core_details.[referral_reason] AS [Referral Reason] --NMI411
				, core_details.[does_claimant_have_personal_injury_claim] AS [Does Claimant Have Personal Injury Claim?] --TRA027
				, core_details.[will_total_gross_reserve_on_the_claim_exceed_500000] AS [Will total gross reserve on the claim exceed £500,000?] --NMI572
				, core_details.[brief_description_of_injury] AS [Description of Injury] --WPS027
				, CASE WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%tetrapleg%' then 'Tetraplegic' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%chronic pain syndrome%' then 'Chronic Pain Syndrome' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%paraplegi%' then 'Paraplegic' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%amputation%' then 'Amputation' 
					WHEN lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%head%' or lower(coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type])) like '%brain%' then 'TBI' 
					WHEN coalesce(substring(core_details.[brief_description_of_injury],5,60),dim_detail_future_care.[ll_injury_type]) is NULL then NULL else 'Other' end  AS [Injury Type Group]
				, core_details.[ll18_is_there_a_reduced_life_expectancy] AS [Is there a reduced Life Expectancy?] --NMI867
				, fact_detail_client.[claimants_life_expectancy_estimate] AS [Claimant's Life Expectancy Estimate] --NMI868
				, fact_detail_client.[defendants_life_expectancy_estimate] AS [Defendant's Life Expectancy Estimate] --NMI869
				, fact_detail_client.[agreed_life_expectancy_estimate] AS [Agreed Life Expectancy Estimate] --NMI870
				, core_details.[ll11_frontal_lobe_damage] AS [Frontal Lobe Damage] --NMI333
				, core_details.[ll09_initial_glasgow_coma_scale] AS [Initial Glasgow coma scale] --NMI153
				, core_details.[ll13_level_of_spinal_cord_injury] AS [Level of Spinal Cord Injury] --NMI157
				, core_details.[ll10_period_of_hospitalisation_days] AS [Period of Hospitalisation Days] --NMI154
				, core_details.[ll12_period_of_peg_feeding] AS [Period of Peg Feeding] --NMI156
				, core_details.[ll14_period_of_ventilation_days] AS [Period of Ventilation Days] --NMI158
				, core_details.[claimants_date_of_birth] AS [Date of Birth] --DOB
				, core_details.[ll01_sex] AS [Gender] --NMI150
				, core_details.[ll02_legal_status] AS [Legal Status] --NMI151
				, core_details.[ll17_marital_status] AS [Marital Status] --NMI732
				, dim_detail_claim.[age_at_accident] AS [Age at Accident]
				, dim_detail_claim.[age_at_accident_banding] AS [Age at Accident Banding]
				, core_details.[claimants_age_at_date_of_settlement] AS [Claimant's Age at Date of Settlement]
				, core_details.[ll16_have_we_funded_an_ina] AS [Have we Funded an INA?] --NMI718
				, core_details.[ll03_occupation_of_claimant] AS [Occupation of Claimant] --RMX005
				, core_details.[ll04_assumed_retirement_age] AS [Assumed Retirement Age] --NMI152
				, fact_future_care.liability_initial_advice AS [Liability Initial Advice] --NMI423
				, fact_future_care.liability_updated_advice AS [Liability Updated Advice] --NMI424
				, core_details.[ll05_capita_likely_settlement_date] AS [Likely Settlement Date] --WPS120
				, core_details.[ll15_action_plan_review_completed] AS [Action Plan Review Completed] --NMI573
				--, COALESCE(dim_detail_claim.[ll01_claimants_medical_experts_name], dim_experts_involvement.[claimantmedexp_name]) AS [Claimant's Medical Experts Name] --NMI791
				--, [Claimant's Non-Medical Experts Name] --NMI800
				, dim_experts_involvement.[medicalexpert_name] AS [Defendant's Medical Experts Name]
				, dim_experts_involvement.[expertnonmed_name] AS [Defendant's Non-Medical Experts Name]
				, core_details.[will_the_court_require_a_cost_budget] AS [Will the Court Require a Cost Budget?]
				, fact_detail_cost_budgeting.[total_disbs_budget_agreedrecorded] AS [Total Disbs Budget Agreed/Recorded]
				, fact_detail_cost_budgeting.[total_profit_costs_budget_agreedrecorded] AS [Total Profit Costs Budget Agreed/Recorded]
				, fact_detail_cost_budgeting.[total_disbs_budget_agreedrecorded_other_side] AS [Total Disbs Budget Agreed/Recorded Other Side]
				, fact_detail_cost_budgeting.[total_profit_costs_budget_agreedrecorded_other_side] AS [Total Profit Costs Budget Agreed/Recorded Other Side]
				, fact_reserve_detail.[client_reserve_initial] AS [Client Reserve Initial] --NMI160
				, fact_reserve_detail.[client_commercial_reserve_initial] AS [Client Commercial Reserve Initial] --NMI161
				, fact_reserve_detail.[weightmans_reserve_initial] AS [Weightman's Reserve Initial] --NMI162
				, fact_reserve_detail.[general_damages_reserve_initial] AS [General Damages Reserve Initial] --NMI334
				, fact_reserve_detail.interest_on_general_damages_reserve_initial_hundred_percent AS [Interest on general damages reserve (initial) 100%] --NMI165
				, fact_reserve_detail.net_wage_loss_reserve_initial_hundred_percent AS [Net wage loss reserve (initial) 100%] --NMI166
				, fact_reserve_detail.misc_specials_reserve_initial_hundred_percent AS [Misc specials reserve (initial) 100%] --NMI335
				, fact_reserve_detail.rehab_ina_reserve_initial_hundred_percent AS [Rehab INA reserve (initial) 100%] --NMI167
				, fact_reserve_detail.[care_cost_reserve_initial_hundred_percent] AS [Care Cost Reserve (initial) 100%] --NMI168
				, fact_reserve_detail.aids_and_equipment_reserve_initial_hundred_percent AS [Aids and equipment reserve (initial) 100%] --NMI169
				, fact_reserve_detail.other_housing_etc_reserve_initial_hundred_percent AS [Other, housing, etc reserve (initial) 100%] --NMI170
				, fact_reserve_detail.interest_on_special_reserve_initial_hundred_percent AS [ Interest on special reserve (initial) 100%] --NMI171
				, fact_reserve_detail.future_loss_of_wages_reserve_initial_hundred_percent AS [Future loss of wages reserve (initial) 100%] --NMI172
				, fact_reserve_detail.s_v_m_award_reserve_initial_hundred_percent AS [S v M award reserve (initial) 100%] --NMI173
				, fact_reserve_detail.future_care_reserve_initial_hundred_percent AS [Future Care Reserve (Initial) 100%] --NMI174
				, fact_reserve_detail.future_aids_equipment_reserve_initial_hundred_percent AS [Future aids & equipment reserve (initial) 100%] --NMI175
				, fact_reserve_detail.domestic_diy_reserve_initial_hundred_percent AS [Domestic DIY reserve (initial) 100%] --NMI176
				, fact_reserve_detail.holidays_reserve_initial_hundred_percent AS [Holidays Reserve Initial Hundred Percent] --NMI177
				, fact_reserve_detail.future_case_manager_reserve_initial_hundred_percent AS [Future case manager reserve (initial) 100%] --NMI178
				, fact_reserve_detail.housing_reserve_initial_hundred_percent AS [Housing reserve (initial) 100%] --NMI179
				, fact_reserve_detail.housing_alterations_reserve_initial_hundred_percent AS [Housing alterations reserve (initial) 100%] --NMI180
				, fact_reserve_detail.medical_physio_reserve_initial_hundred_percent AS [Medical physio reserve (initial) 100%] --NMI181
				, fact_reserve_detail.transport_reserve_initial_hundred_percent AS [Transport reserve (initial) 100%] --NMI182
				, fact_reserve_detail.pension_loss_reserve_initial_hundred_percent AS [Pension loss reserve (initial) 100%] --NMI183
				, fact_reserve_detail.court_of_protection_reserve_initial_hundred_percent AS [Court of protection reserve (initial) 100%] --NMI184
				, fact_reserve_detail.hospital_charges_reserve_initial AS [Hospital Charges Reserve Initial] --NMI540
				, fact_reserve_detail.[cru_charges_reserve_initial] AS [CRU Charges Reserve Initial] --NMI541
				, fact_finance_summary.[tp_costs_reserve_initial] AS [Claimant's Legal Costs Reserve Initial] --TRA081
				, fact_finance_summary.[defence_costs_reserve_initial] AS [Own Legal Costs Disbs Reserve Initial] --TRA079
				, fact_reserve_detail.[general_damages_reserve_current_ll] AS [General Damages Reserve Current] --coalesce(NMI189.case_value,NMI334.case_value)
				, fact_reserve_detail.[interest_on_generals_reserve_current] AS [Interest on Generals Reserve Current] --coalesce(NMI190.case_value,NMI165.case_value)
				, fact_reserve_detail.[net_wage_loss_reserve_current] AS [Net Wage Loss Reserve Current] --coalesce(NMI191.case_value,NMI166.case_value)
				, fact_reserve_detail.[misc_specials_reserve_current] AS [Misc Specials Reserve Current] --coalesce(NMI192.case_value,NMI335.case_value)
				, fact_reserve_detail.[rehab_ina_reserve_current] AS [Rehab INA Reserve Current] --coalesce(NMI193.case_value,NMI167.case_value)
				, fact_reserve_detail.[care_costs_reserve_current] AS [Care Costs Reserve Current] --coalesce(NMI194.case_value,NMI168.case_value)
				, fact_reserve_detail.[aids_equipment_reserve_current] AS [Aids/Equipment Reserve Current] --coalesce(NMI195.case_value,NMI169.case_value)
				, fact_reserve_detail.[other_housing_reserve_current] AS [Other Housing Etc Reserve Current] --coalesce(NMI196.case_value,NMI170.case_value)
				, fact_reserve_detail.[interest_on_specials_reserve_current] AS [Interest on Specials Reserve Current] --coalesce(NMI197.case_value,NMI171.case_value)
				, fact_reserve_detail.[future_loss_of_wages_reserve_current] AS [Future Loss of Wages Reserve Current] --coalesce(NMI198.case_value,NMI172.case_value)
				, fact_reserve_detail.[s_v_m_award_reserve_current] AS [SvM Award Reserve Current] --coalesce(NMI199.case_value,NMI173.case_value)
				, fact_reserve_detail.[future_care_reserve_current] AS [Future Care Reserve Current] --coalesce(NMI200.case_value,NMI174.case_value)
				, fact_reserve_detail.[future_aids_equipment_reserve_current] AS [Future Aids/Equipment Reserve Current] --coalesce(NMI201.case_value,NMI175.case_value)
				, fact_reserve_detail.[domestic_diy_reserve_current] AS [Domestic DIY Reserve Current] --coalesce(NMI202.case_value,NMI176.case_value)
				, fact_reserve_detail.[holidays_reserve_current] AS [Holidays Reserve Current] --coalesce(NMI203.case_value,NMI177.case_value)
				, fact_reserve_detail.[future_case_manager_reserve_current] AS [Future Case Manager Reserve Current] --coalesce(NMI204.case_value,NMI178.case_value)
				, fact_reserve_detail.[housing_reserve_current] AS [Housing Reserve Current] --coalesce(NMI205.case_value,NMI179.case_value)
				, fact_reserve_detail.[housing_alterations_reserve_current] AS [Housing Alterations Reserve Current] --coalesce(NMI206.case_value,NMI180.case_value)
				, fact_reserve_detail.[medical_physio_reserve_current] AS [Medical Physio Reserve Current] --coalesce(NMI207.case_value,NMI181.case_value)
				, fact_reserve_detail.[transport_reserve_current] AS [Transport Reserve Current] --coalesce(NMI208.case_value,NMI182.case_value)
				, fact_reserve_detail.[pension_loss_reserve_current] AS [Pension Loss Reserve Current] --coalesce(NMI209.case_value,NMI183.case_value)
				, fact_reserve_detail.[court_protection_reserve_current] AS [Court Protection Reserve Current] --coalesce(NMI210.case_value,NMI184.case_value) 
				, fact_reserve_detail.[hospital_charges_reserve_current] AS [Hospital Charges Reserve Current] --coalesce(NMI212.case_value,NMI540.case_value)
				
				, fact_reserve_detail.[cru_reserve_current] AS [CRU Reserve Current] --coalesce(NMI213.case_value,WPS004.case_value)
				, fact_reserve_detail.[claimant_legal_costs_reserve_12_month] AS [Claimant Legal Costs Reserve - 12 month] --NMI214
				, fact_reserve_detail.[general_damages_non_pi_misc_reserve_current] AS [General damages (non-PI) - misc reserve (current)] --NMI514
				, fact_reserve_detail.[past_care_reserve_current] AS [Past care reserve (current)] --NMI094
				, fact_reserve_detail.[past_loss_of_earnings_reserve_current] AS [Past loss of earnings reserve (current)] --NMI095
				, fact_detail_cost_budgeting.[personal_injury_reserve_current] AS [Personal Injury reserve (current)] --NMI093
				, fact_finance_summary.[special_damages_miscellaneous_reserve] AS [Special damages - misc reserve (current)] --NMI515
				, fact_reserve_detail.[nhs_charges_reserve_current] AS [NHS charges reserve (current)] --NMI097
				, fact_reserve_detail.[future_care_reserve_current] AS [Future care reserve (current)] --NMI098
				, fact_reserve_detail.[future_loss_misc_reserve_current] AS [Future loss - misc reserve (current)] --NMI100
				, fact_reserve_detail.[future_loss_of_earnings_reserve_current] AS [Future loss of earnings reserve (current)] --NMI099

				, fact_finance_summary.[tp_costs_reserve] AS [Claimant's cost reserve (current)] --TRA080 + NMI519
				, fact_finance_summary.[damages_reserve] AS [Damages Reserve] --TRA076
				, fact_finance_summary.[defence_costs_reserve] AS [Defence cost reserve (current)] --TRA078
				, fact_finance_summary.[other_defendants_costs_reserve] AS [Other defendants costs - reserve (current)] --NMI519
				, fact_finance_summary.[total_reserve] AS [Total Reserve Current]
				, fact_reserve_detail.[own_legal_costsdisbs_reserve_12_month] AS [Own Legal Costs/Disbs Reserve - 12 month] --NMI215

				, fact_detail_paid_detail.[general_damages_paid_hundred_percent] AS [General Damages Paid - 100%] --NMI219
				, fact_detail_paid_detail.[interest_on_generals_paid_hundred_percent] AS [Interest on Generals Paid - 100%] --NMI220
				, fact_detail_paid_detail.[net_wage_loss_paid_hundred_percent] AS [Net Wage Loss Paid - 100%] --NMI221
				, fact_detail_paid_detail.[misc_specials_paid_hundred_percent] AS [Misc Specials Paid - 100%] --NMI222
				, fact_detail_paid_detail.[rehab_ina_paid_hundred_percent] AS [Rehab INA Paid - 100%] --NMI223
				, fact_detail_paid_detail.[care_costs_paid_hundred_percent] AS [Care Costs Paid - 100%] --NMI224
				, fact_detail_paid_detail.[aids_equipment_paid_hundred_percent] AS [Aids/Equipment Paid 100%] --NMI225
				, fact_detail_paid_detail.[other_housing_etc_paid_hundred_percent] AS [Other Housing Etc Paid - 100%] --NMI226
				, fact_detail_paid_detail.[interest_on_specials_paid_hundred_percent] AS [Interest on Specials Paid - 100%] --NMI227
				, fact_detail_paid_detail.[future_loss_of_wages_paid_hundred_percent] AS [Future Loss of Wages Paid - 100%] --NMI228
				, fact_detail_paid_detail.[s_v_m_award_paid_hundred_percent] AS [SvM Award Paid - 100%] --NMI229
				, fact_detail_paid_detail.[future_care_paid_hundred_percent] AS [Future Care Paid - 100%] --NMI230
				, fact_detail_paid_detail.[future_aids_equipment_paid_hundred_percent] AS [Future Aids/Equipment Paid - 100%] --NMI231
				, fact_detail_paid_detail.[domestic_diy_paid_hundred_percent] AS [Domestic DIY Paid 100%] --NMI232
				, fact_detail_paid_detail.[holidays_paid_hundred_percent] AS [Holidays Paid - 100%] --NMI233
				, fact_detail_paid_detail.[future_case_manager_paid_hundred_percent] AS [Future Case Manager Paid - 100%] --NMI234
				, fact_detail_paid_detail.[housing_paid_hundred_percent] AS [Housing Paid - 100%] --NMI235
				, fact_detail_paid_detail.[housing_alterations_paid_hundred_percent] AS [Housing Alterations Paid - 100%] --NMI236
				, fact_detail_paid_detail.[medical_physio_paid_hundred_percent] AS [Medical Physio Paid - 100%] --NMI237
				, fact_detail_paid_detail.[transport_paid_hundred_percent] AS [Transport Paid - 100%] --NMI238
				, fact_detail_paid_detail.[pension_loss_paid_hundred_percent] AS [Pension Loss Paid - 100%] --NMI239
				, fact_detail_paid_detail.[court_of_protection_paid_hundred_percent] AS [Court of Protection Paid - 100%] --NMI240
				, fact_detail_paid_detail.[global_paid] AS [Global Paid] --NMI241
				, fact_detail_paid_detail.[hospital_charges_paid] AS [Hospital Charges Paid] --NMI243
				, fact_detail_paid_detail.[ll25_cru_paid] AS [CRU Paid] --NMI244
				, fact_detail_claim.[claimant_legal_costs_paid] AS [Claimant Legal Costs Paid] --coalesce(TRA072.case_value,NMI245.case_value)
				, fact_detail_paid_detail.[own_legal_costsdisbs_paid] AS [Own legal costs/disbs paid] --NMI246
				, detail_outcome.[date_claim_concluded] AS [Date Claim Concluded] --TRA086
				, detail_outcome.[outcome_of_case] AS [Outcome of Case] --TRA068
				, fact_detail_client.percent_of_clients_liability_agreed_prior_to_instruction AS [% of Client's Liability Agreed Prior to Instruction] --NMI060
				, fact_detail_client.percent_of_clients_liability_awarded_agreed_post_insts_applied as [% of Client's Liability Awarded/Agreed Post insts/applied] --NMI064
				, fact_detail_client.percent_of_contributory_negligence_agreed AS [% of Contributory Negligence Agreed] --NMI061
				, detail_outcome.[percent_estimate_of_reduction_for_litigation_risk] AS [% Estimate of Reduction for Litigation Risk] --NMI111
				, fact_detail_paid_detail.[general_damages_misc_paid] AS [General Damages misc paid] --NMI115
				, fact_detail_paid_detail.[past_care_paid] AS [Past Care Paid] --NMI116
				, fact_detail_paid_detail.[past_loss_of_earnings_paid] AS [Past Loss of Earning Paid] --NMI117
				, fact_detail_paid_detail.[personal_injury_paid] AS [Personal Injury Paid]
				, fact_finance_summary.[special_damages_miscellaneous_paid] AS [Special Damages misc Paid] --NMI118
				, fact_detail_paid_detail.[cru_costs_paid] AS [CRU Costs Paid] --WPS038
				, fact_detail_paid_detail.[cru_offset] AS [CRU Offset against Damages] --NMI059
				, fact_detail_paid_detail.[future_care_paid] AS [Future Care Paid] --NMI119
				, fact_detail_paid_detail.[future_loss_of_earnings_paid] AS [Futre Loss of Earnings Paid] --NMI220
				, fact_detail_paid_detail.[future_loss_misc_paid] AS [Future Loss Misc Paid] --NMI221
				, fact_detail_paid_detail.[nhs_charges_paid_by_client] AS [NHS Charges Paid by Client] --WPS039
				, fact_finance_summary.[damages_paid] AS [Damages Paid] --TRA070
				, detail_outcome.[ll00_settlement_basis] AS [Settlement Basis] --NMI604
				, fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] AS [Total Settlement Value of the Claim Paid by all the Parties] --NMI128
				, dim_detail_future_care.[global_settlement] AS [Global Settlement] --NMI595
				, detail_outcome.[settlement_on_litigation_risk_basis] AS [Settlement on Litigation Risk Basis] --NMI110
				, detail_outcome.[date_claimants_costs_received] AS [Date Claimant's Costs Received] --FTR086
				, detail_outcome.[date_referral_to_costs_unit] AS [Date Referral to Costs Unit] --NMI130
				, detail_outcome.[date_costs_settled] AS [Dtae Costs Settled] --FTR087
				, detail_outcome.[percent_success_fee_claimed] AS [% Success Fee Claimed] --WPS184
				, detail_outcome.[percent_success_fee_paid] AS [% Success Fee Paid] --WPS110
				, fact_reserve_detail.[amount_of_success_fee_claimed] AS [Amount of Success Fee Claimed] --COS039
				, fact_detail_paid_detail.[amount_of_success_fee_paid]  AS [Amount of Success Fee Paid] --WPS125
				, fact_finance_summary.[ate_premium_claimed] AS [ATE Premium Claimed] --WPS111
				, fact_finance_summary.[ate_premium_paid] AS [ATE Premium Paid] --WPS112
				, fact_reserve_detail.[claimant_s_solicitor_s_base_costs_claimed_vat] AS [Claimant's Solicitor's Base Costs Claimed VAT] --WPS041
				, fact_detail_paid_detail.[claimant_s_solicitor_s_base_costs_paid_vat] AS [Claimant Profit Costs] --WPS100
				, fact_detail_paid_detail.[claimants_disbursements_claimed] AS [Claimant's Disbursements Claimed] --POL014
				, fact_finance_summary.[claimants_solicitors_disbursements_paid] AS [Claimant's Solicitor's Disbursements Paid] --WPS113
				, fact_finance_summary.[tp_total_costs_claimed] AS [Claimant Sols Total Costs Claimed] --TRA074
				, fact_finance_summary.[claimants_costs_paid] AS [Claimant Sols Total Costs Paid] --TRA072
				, fact_detail_client.[claimants_solicitors_hours_claimed] AS [Claimant Solicitor's Total Hours Claimed] --WPS107
				, fact_detail_paid_detail.[claimants_solicitors_hours_paid] AS [Claimant's Solicitor's Hours Paid] --WPS108
				, fact_future_care.[final_total_costs] AS [Final Total Costs] --NMI324
				, fact_future_care.[number_of_payment_periods_lump_sum] AS [Number Of Payment Periods Lump Sum] --NMI605
				, dim_detail_future_care.[ll01_to_age_period_1] AS [To Age Period 1 A] --NMI248
				, fact_future_care.[annual_fc_period_1] AS [Annual FC Period 1 ] --NMI249
				, fact_future_care.[annual_cm_period_1] AS [Annual CM Period 1 ] --NMI252
				, dim_detail_future_care.[ll04_to_age_period_2] AS [To Age Period 2] --NMI255
				, fact_future_care.[annual_fc_period_2] AS [Annual FC Period 2] --NMI256
				, fact_future_care.[annual_cm_period_2] AS [Annual CM Period 2] --NMI259
				, dim_detail_future_care.[ll07_to_age_period_3] AS [To Age Period 3] --NMI262
				, fact_future_care.[annual_fc_period_3] AS [Annual FC Period 3] --NMI263
				, fact_future_care.[annual_cm_period_3] AS [Annual CM Period 3] --NMI266
				, dim_detail_future_care.[ll10_to_age_period_4] AS [To Age Period 4] --NMI269
				, fact_future_care.[annual_fc_period_4] AS [Annual FC Period 4] --NMI270
				, fact_future_care.[annual_cm_period_4] AS [Annual CM Period 4] --NMI273
				, dim_detail_future_care.[ll13_24_hour_care] AS [24 Hour Care] --NMI278
				, dim_detail_future_care.[ll14_overnight_care] AS [Overnight Care] --NMI279
				, fact_future_care.[double_up_care_hours] AS [Double up Care Hours] --NMI280
				, fact_future_care.[annual_periodic_hundred_percent] AS [Annual Periodic - 100%] --NMI286
				, fact_future_care.[annual_pp_net_amount] AS [Annual Periodic Net] --NMI544 
				, dim_detail_future_care.[ll03_self_funded] AS [Self Funded] --NMI287
				, dim_detail_future_care.[ll04_annuity_provider] AS [Annuity Provider] --NMI288
				, fact_future_care.[cost_of_annuity] AS [Cost of Annuity] --NMI289
				, dim_detail_future_care.[ll06_indexation_basis] AS [Indexation Basis] --NMI290
				, dim_detail_future_care.[ll07_reverse_indemnity] AS [Reverse Indemnity] --NMI291
				, dim_detail_future_care.[ll08_claimant_ifa] AS [Claimant IFA] --NMI292
				, dim_detail_future_care.[ll09_professional_claimant_deputy] AS [Professional Claimant Deputy] --NMI293
				, fact_future_care.[future_care_per_annum_hundred_percent] AS [Future Care per Annum 100%] --NMI281
				, dim_detail_future_care.[ll11_case_management_per_annum_hundred_percent] AS [Case Management per Annum 100%] --NMI282
				, fact_future_care.[aids_equipment_per_annum_hundred_percent] AS [Aids Equipment per Annum 100%] --NMI283
				, fact_future_care.[medical_physio_per_annum_hundred_percent] AS [Medical Physio per Annum 100%] --NMI284
				, fact_future_care.[of_p_deputyship_per_annum_hundred_percent] AS [C of P Deputyship Per Annum 100%] --NMI285
				, fact_future_care.[number_of_payment_periods_periodical] AS [Number of Payment Periods Periodical] --NMI606
				, dim_detail_future_care.[ll15_to_age_period_1] AS [To Age Period 1 B] --NMI294
				, fact_future_care.[annual_fc_hundred_percent_period_1] AS [Annual FC 100% Period 1] --NMI295
				, fact_future_care.[annual_cm_hundred_percent_period_1] AS [Annual CM 100% Period 1] --NMI296
				, fact_future_care.pct_annual_contribution_period_1 AS [PCT annual contribution (period 1)] --NMI300
				, dim_detail_future_care.[ll19_to_age_period_2] AS [To Age Period 2 B] --NMI301
				, fact_future_care.[annual_fc_hundred_percent_period_2] AS [Annual FC 100% Period 2] --NMI302
				, fact_future_care.[annual_cm_hundred_percent_period_2] AS [Annual CM 100% Period 2] --NMI303
				, fact_future_care.pct_annual_contribution_period_2 AS [PCT annual contribution (period 2)] --NMI307
				, dim_detail_future_care.[ll23_to_age_period_3] AS [To Age Period 3 B] --NMI308
				, fact_future_care.[annual_fc_hundred_percent_period_3] AS [Annual FC 100% Period 3] --NMI309
				, fact_future_care.[annual_cm_hundred_percent_period_3] AS [Annual CM 100% Period 3] --NMI310
				, fact_future_care.pct_annual_contribution_period_3 AS [PCT annual contribution (period 3)] --NMI314
				, dim_detail_future_care.[ll27_to_age_period_4] AS [To Age Period 4 B] --NMI315
				, fact_future_care.[annual_fc_hundred_percent_period_4] AS [Annual FC 100% Period 4] --NMI316
				, fact_future_care.[annual_cm_hundred_percent_period_4] AS [Annual CM 100% Period 4] --NMI317
				, fact_future_care.pct_annual_contribution_period_4 AS [PCT annual contribution (period 4)] --NMI321


				, core_details.[fixed_fee] AS [Fixed Fee] --FTR057
				, fact_finance_summary.[total_amount_billed] AS [Total Amount Billed]
				, fact_finance_summary.[defence_costs_billed] AS [Defence Costs Billed]
				, fact_finance_summary.[total_paid] AS [Total Paid]
				, fact_finance_summary.[disbursements_billed] AS [Disbursements Billed]
				, fact_finance_summary.disbursement_balance AS [Disbursements Balance]
				, fact_finance_summary.[unpaid_disbursements] AS [Unpaid Disbursements]
				, fact_finance_summary.[vat_billed] AS [VAT Billed]
				, fact_finance_summary.wip AS WIP

				, cast(datediff(d,case when core_details.date_instructions_received < dim_matter_header_current.date_opened_case_management THEN core_details.date_instructions_received when dim_matter_header_current.date_opened_case_management  >=  core_details.date_instructions_received then dim_matter_header_current.date_opened_case_management  else isnull(dim_matter_header_current.date_opened_case_management , core_details.date_instructions_received) end, detail_outcome.date_claim_concluded) as int) AS [Elapsed Days to Resolution]
				, dim_detail_practice_area.[age_at_accident_flag] [Age at Accident Flag] --TRA086,DOA,DOB
				, fact_detail_paid_detail.[liability_percentage_paid] AS [Liability Percentage Paid] --coalesce(NMI064.case_value,NMI060.case_value,(100-NMI111.case_value),100)
				, fact_reserve_detail.[amount_of_debt] AS [Amount of Debt] --REC008
				, fact_reserve_detail.[hire_reserve] AS [Hire Reserve] --WPS096
				, fact_reserve_detail.[special_damages_reserve_current] AS [Special Damages Reserve Current] --WPS006
				, fact_reserve_detail.[special_damages_reserve_initial] AS [Special Damages Reserve Initial] --WPS002
				, fact_reserve_detail.converge_disease_reserve AS [Converge Disease Reserve] --WPS277
				, fact_reserve_detail.ll29_own_legal_costs_disbs_reserve_initial AS [Own legal costs disbs reserve (initial) 100%] --NMI543
				, ISNULL(fact_detail_cost_budgeting.[personal_injury_reserve_current],0)+ISNULL(fact_reserve_detail.general_damages_non_pi_misc_reserve_current,0) AS [General Damages]
				, ISNULL(fact_reserve_detail.past_care_reserve_current,0)+ISNULL(fact_reserve_detail.[past_loss_of_earnings_reserve_current],0)+ISNULL(fact_finance_summary.[special_damages_miscellaneous_reserve],0) AS [Special Damages]
				, ISNULL(fact_finance_summary.[defence_costs_reserve],0)+ISNULL(fact_finance_summary.[other_defendants_costs_reserve],0) AS [Defence Costs]
				, ISNULL(fact_detail_cost_budgeting.[personal_injury_reserve_current],0)+ISNULL(fact_reserve_detail.general_damages_non_pi_misc_reserve_current,0) + --General Damages
				 ISNULL(fact_reserve_detail.[nhs_charges_reserve_current],0) + --NHS Charges Reserve Current
				 ISNULL(fact_reserve_detail.future_loss_of_earnings_reserve_current,0) + --Future Loss of Earnings Reserve (current)
				 ISNULL(fact_reserve_detail.future_care_reserve_current,0) + --Future Care Reserve (Current)
				 ISNULL(fact_finance_summary.[tp_costs_reserve],0) + --Claimant's Cost Reserve Current
				 ISNULL(fact_finance_summary.[defence_costs_reserve],0)+ISNULL(fact_finance_summary.[other_defendants_costs_reserve],0) +  --Defence Costs
				 ISNULL(fact_reserve_detail.future_loss_misc_reserve_current,0) + --Future Loss - Misc Reserve (Current)
				 ISNULL(fact_reserve_detail.past_care_reserve_current,0)+ISNULL(fact_reserve_detail.[past_loss_of_earnings_reserve_current],0)+ISNULL(fact_finance_summary.[special_damages_miscellaneous_reserve],0) --Special Damages
				 AS [Total Live Reserve]
				, fact_reserve_detail.[liability_percentage_reserve] AS [Liability Percentage Reserve] --coalesce(NMI424.case_value,NMI423.case_value,100)
				,  ISNULL(fact_reserve_detail.[interest_on_generals_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[net_wage_loss_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[misc_specials_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[rehab_ina_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[care_costs_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[aids_equipment_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[other_housing_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[interest_on_specials_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[future_loss_of_wages_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[s_v_m_award_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[future_care_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[future_aids_equipment_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[domestic_diy_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[holidays_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[future_case_manager_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[housing_alterations_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[medical_physio_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[transport_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[pension_loss_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[court_protection_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[hospital_charges_reserve_current],0) as [Damages Reserve]

				, ISNULL(fact_detail_paid_detail.[general_damages_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[interest_on_generals_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[net_wage_loss_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[misc_specials_paid_hundred_percent],0)  
					+ ISNULL(fact_detail_paid_detail.[rehab_ina_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[care_costs_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[aids_equipment_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[other_housing_etc_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[interest_on_specials_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[future_loss_of_wages_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[s_v_m_award_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[future_care_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[future_aids_equipment_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[domestic_diy_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[holidays_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[future_case_manager_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[housing_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[housing_alterations_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[medical_physio_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[transport_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[pension_loss_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[court_of_protection_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[hospital_charges_paid],0) AS [Damages Paid] 


				, fact_reserve_detail.[claimant_legal_costs_reserve_current] AS [Claimant Legal Costs Reserve (Current)] --Case when isnull(NMI214.case_value,0) = 0 then NMI542.case_value else NMI214.case_value end
				, Case when isnull(fact_reserve_detail.[claimant_legal_costs_reserve_12_month],0) = 0 then fact_reserve_detail.[ll28_claimants_legal_costs_reserve_initial] else fact_reserve_detail.[claimant_legal_costs_reserve_12_month] end  AS [Claimant Legal Costs Reserve (Current)]
				, Case when isnull(fact_reserve_detail.[own_legal_costsdisbs_reserve_12_month],0) = 0 then fact_reserve_detail.[ll29_own_legal_costs_disbs_reserve_initial]  else fact_reserve_detail.[own_legal_costsdisbs_reserve_12_month] end  AS [Own Legal Costs/Disbs Reserve (Current)]
				, ISNULL(CASE when isnull(fact_reserve_detail.[claimant_legal_costs_reserve_12_month],0) = 0 then fact_reserve_detail.[ll28_claimants_legal_costs_reserve_initial] else fact_reserve_detail.[claimant_legal_costs_reserve_12_month] END,0)  
				+ ISNULL(CASE when isnull(fact_reserve_detail.[own_legal_costsdisbs_reserve_12_month],0) = 0 then fact_reserve_detail.[ll29_own_legal_costs_disbs_reserve_initial]  else fact_reserve_detail.[own_legal_costsdisbs_reserve_12_month] END,0) AS [Costs Reserve Current]

				, ISNULL(fact_reserve_detail.[future_care_reserve_current_ll],0)+ISNULL(fact_reserve_detail.[care_costs_reserve_current],0) AS [Care (Current)]

				, ISNULL(fact_detail_paid_detail.[general_damages_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[interest_on_generals_paid_hundred_percent],0) AS [General Damages Paid]
				, ISNULL(fact_detail_paid_detail.[net_wage_loss_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[misc_specials_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[rehab_ina_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[care_costs_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[aids_equipment_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[other_housing_etc_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[interest_on_specials_paid_hundred_percent],0) AS [Special Damages Paid]

				, ISNULL(fact_detail_paid_detail.[s_v_m_award_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[domestic_diy_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[holidays_paid_hundred_percent],0) 
					+ ISNULL(fact_detail_paid_detail.[housing_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[housing_alterations_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[medical_physio_paid_hundred_percent],0)
					+ ISNULL(fact_detail_paid_detail.[transport_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[pension_loss_paid_hundred_percent],0) AS [All Other Future Loss Paid]

				, ISNULL(fact_detail_paid_detail.[future_care_paid_hundred_percent],0) + ISNULL(fact_detail_paid_detail.[care_costs_paid_hundred_percent],0) AS [Care Paid] --NMI230+NMI224
				, ISNULL(fact_detail_paid_detail.[claimant_legal_costs_paid],0) + ISNULL(fact_detail_paid_detail.[own_legal_costsdisbs_paid],0) AS [Costs Paid] --NMI245+NMI246

				, ISNULL(fact_reserve_detail.future_care_reserve_current,0) + ISNULL(fact_reserve_detail.[care_costs_reserve_current],0) AS [Care Reserve (Current)]
				, ISNULL(fact_reserve_detail.[claimant_legal_costs_reserve_current],0)+ ISNULL(fact_reserve_detail.[own_legal_costs_disbs_reserve_current],0) AS [Costs Reserve (Current)]

				, ISNULL(fact_reserve_detail.[interest_on_generals_reserve_current],0) + ISNULL(fact_reserve_detail.[general_damages_reserve_current_ll],0) AS [General Damages (Current)]
				, ISNULL(fact_reserve_detail.[net_wage_loss_reserve_current],0) + ISNULL(fact_reserve_detail.[misc_specials_reserve_current],0) + ISNULL(fact_reserve_detail.[rehab_ina_reserve_current],0) + ISNULL(fact_reserve_detail.[care_costs_reserve_current],0)
					+ ISNULL(fact_reserve_detail.[aids_equipment_reserve_current],0) + ISNULL(fact_reserve_detail.[other_housing_reserve_current],0) + ISNULL(fact_reserve_detail.[interest_on_specials_reserve_current],0) AS [Special Damages Reserve (Current)]

				, CASE WHEN detail_outcome.[global_settlement] = 'Yes' THEN (ISNULL(fact_detail_paid_detail.[global_paid],0) 
																			+ ISNULL(fact_detail_paid_detail.[claimant_legal_costs_paid],0) 
																			+ ISNULL(fact_detail_paid_detail.[own_legal_costsdisbs_paid],0) 
																			+ ISNULL(fact_detail_paid_detail.[hospital_charges_paid],0))
					ELSE (ISNULL(fact_detail_paid_detail.[general_damages_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[interest_on_generals_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[net_wage_loss_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[misc_specials_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[care_costs_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[aids_equipment_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[other_housing_etc_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[interest_on_specials_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[future_loss_of_wages_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[s_v_m_award_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[future_care_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[future_aids_equipment_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[domestic_diy_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[holidays_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[future_case_manager_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[housing_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[housing_alterations_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[medical_physio_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[transport_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[pension_loss_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[court_of_protection_paid_hundred_percent],0)
																			+ ISNULL(fact_detail_paid_detail.[hospital_charges_paid],0)
																			+ ISNULL(fact_detail_paid_detail.[claimant_legal_costs_paid],0)
																			+ ISNULL(fact_detail_paid_detail.[own_legal_costsdisbs_paid],0)
																			+ ISNULL(fact_detail_paid_detail.[rehab_ina_paid_hundred_percent],0))
					END AS [Total Paid - Global Settlement]

				
				, CASE WHEN LOWER(detail_outcome.[outcome_of_case]) like '%discontinued%' or LOWER(RTRIM(detail_outcome.[outcome_of_case])) = 'struck out' THEN 'Discontinued' 
					WHEN RTRIM(detail_outcome.[outcome_of_case]) in ('Settled - JSM','Settled - mediation') THEN 'JSM' 
					WHEN LOWER(detail_outcome.[outcome_of_case]) like '%won%' THEN 'Won at Trial' 
					WHEN LOWER(detail_outcome.[outcome_of_case]) like '%lost%' THEN 'Lost at Trial' 
					WHEN LOWER(detail_outcome.[outcome_of_case]) like 'Assessment of damages%' THEN 'Assessment of damages' 
					WHEN RTRIM(detail_outcome.[outcome_of_case]) = 'Settled - infant approval' THEN 'Settled/Approval' 
					WHEN RTRIM(detail_outcome.[outcome_of_case]) = 'Settled' THEN 'Settled/Offer' 
					WHEN RTRIM(detail_outcome.[outcome_of_case]) = 'matter ongoing' THEN NULL 
					ELSE RTRIM(detail_outcome.[outcome_of_case]) END AS [Outcome of Case]

				, fact_future_care.[final_total_costs] AS [Total Spend] --NMI324
				, COALESCE(core_details.[ll08_liability_updated_advice_percent],core_details.[ll07_liability_initial_advice_percent],100) AS [Liability Percentage Reserve] --NMI424,NMI423,100
				, core_details.[zurich_line_of_business] AS [Line of Business] --WPS151
				, core_details.[clients_claims_handler_surname_forename] AS [Client's Claims Handler] --WPS115
				, core_details.[zurich_branch] AS [Branch] --WPS103				
				, detail_outcome.[global_settlement] AS [Global Settlement] --FTR012
			    , core_details.[claimant_in_person] AS [Claimant in Person] --NMI0212 
				, dim_detail_claim.[division_name] AS [Division Name] --VE00578
				, dim_detail_claim.[claimant_medical_expert] AS [Claimant Medical Expert] --NMI786
				, CASE WHEN MONTH(dim_matter_header_current.date_opened_case_management) >3 THEN CAST(YEAR(dim_matter_header_current.date_opened_case_management) as varchar(5)) + '/' + CAST(YEAR(dim_matter_header_current.date_opened_case_management) + 1 as varchar(5)) else cast(year(dim_matter_header_current.date_opened_case_management) - 1 as varchar(5)) + '/' + cast(year(dim_matter_header_current.date_opened_case_management) as varchar(5)) end AS [Years Opened (Apr - Mar)]
				, CASE WHEN MONTH(dim_matter_header_current.date_opened_case_management) <= 3 THEN 'Qtr 4' WHEN MONTH(dim_matter_header_current.date_opened_case_management) <= 6 THEN 'Qtr 1' WHEN MONTH(dim_matter_header_current.date_opened_case_management) <= 9 then 'Qtr 2' else  'Qtr 3' end AS [Quarters Opened (Apr - Mar)]
				, CASE WHEN MONTH(COALESCE(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) >  3 THEN CAST(YEAR(COALESCE(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) as varchar(5)) + '/' + cast(year(coalesce(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) + 1 as varchar(5)) else cast(year(coalesce(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) - 1 as varchar(5)) + '/' + cast(year(coalesce(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) as varchar(5)) end AS [Years Concluded (Apr - Mar)]
				, CASE WHEN MONTH(COALESCE(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) <= 3 THEN 'Qtr 4' WHEN month(coalesce(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) <= 6 then 'Qtr 1' when month(coalesce(dim_matter_header_current.date_closed_case_management,detail_outcome.date_claim_concluded)) <= 9 then 'Qtr 2' else  'Qtr 3' end AS [Quarters Concluded (Apr - Mar)]
				, CASE WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%liverpool%' then 'Liverpool' 
					WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%london%' then 'London' 
					WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%birmingham%' then 'Birmingham' 
					WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%midlands%' then 'Birmingham' 
					WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%leicester%' then 'Leicester' 
					WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%manchester%' then 'Manchester' 
					WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%leeds%' then 'Leeds' 
					WHEN LOWER(dim_fed_hierarchy_history.[hierarchylevel4hist]) like '%glasgow%' then 'Glasgow' 
					ELSE dim_fed_hierarchy_history.[hierarchylevel4hist] END AS [Team Location]
				, CAST(CASE WHEN detail_outcome.[date_claim_concluded] is null and (detail_outcome.[outcome_of_case] is null or RTRIM(detail_outcome.[outcome_of_case]) = 'matter ongoing') THEN DATEDIFF(d, case when core_details.[date_instructions_received] < dim_matter_header_current.date_opened_case_management then core_details.[date_instructions_received] 
						WHEN dim_matter_header_current.date_opened_case_management  >=  core_details.[date_instructions_received] then dim_matter_header_current.date_opened_case_management 
						ELSE isnull(dim_matter_header_current.date_opened_case_management , core_details.[date_instructions_received]) end ,getdate()) else NULL end as int) AS [Elapsed Days Live]
				

		FROM 
		red_dw.dbo.fact_dimension_main AS dimmain
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details AS core_details ON core_details.dim_detail_core_detail_key = dimmain.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_client_involvement AS Client_Involv ON Client_Involv.dim_client_involvement_key = dimmain.dim_client_involvement_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud AS detail_fraud ON detail_fraud.dim_detail_fraud_key=dimmain.dim_detail_fraud_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details AS detail_hire_details ON detail_hire_details.dim_detail_hire_detail_key= dimmain.dim_detail_hire_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome AS detail_outcome ON detail_outcome.dim_detail_outcome_key=dimmain.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_client AS fact_detail_client ON fact_detail_client.master_fact_key= dimmain.master_fact_key
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
		LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting ON fact_detail_cost_budgeting.master_fact_key = dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = dimmain.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_department ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
		LEFT OUTER JOIN red_dw.dbo.dim_experts_involvement ON dim_experts_involvement.dim_experts_involvemen_key = dimmain.dim_experts_involvemen_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_claim ON fact_detail_claim.master_fact_key = fact_reserve_detail.master_fact_key

		WHERE 
		ISNULL(detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
		AND dim_matter_header_current.reporting_exclusions=0
		--AND (dim_matter_header_current.date_closed_case_management >= '20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)

		--Large Loss
		AND dim_fed_hierarchy_history.[hierarchylevel3hist] ='Large Loss'
		AND (dim_matter_header_current.[matter_description] NOT LIKE 'AWC_%')
		AND core_details.[will_total_gross_reserve_on_the_claim_exceed_500000] ='Yes'
		AND (ISNULL(RTRIM(core_details.[referral_reason]),'')  in ('Dispute on liability and quantum','Dispute on quantum','Dispute on liability','Infant Approval'))
		AND (dimmain.client_code not in ('00162924','00162925','K00010','Z00008','Z00003','N12105'))
		AND (not ISNULL(core_details.[does_claimant_have_personal_injury_claim],'') = 'No')
		And ((detail_outcome.[date_claim_concluded] >='20090101' OR detail_outcome.[date_claim_concluded] IS NULL))
		--AND dimmain.client_code='Z1001' 
		--AND dimmain.matter_number = '00068508'
		
		ORDER BY dimmain.client_code, dimmain.matter_number

END

GO
