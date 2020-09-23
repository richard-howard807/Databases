SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_detail_claim]
AS 

SELECT [dim_detail_claim_key]
--      ,[source_system_id]
--      ,[client_code]
--      ,[matter_number]
--      ,[ageas_claim_type]
--      ,[ageas_insurer]
--      ,[ageas_office]
--      ,[nhs_claimants_costs_info]
--      ,[archiveddate]
--      ,[date_complaint_reported_to_insurer]
--      ,[date_of_repeat_audiogram]
--      ,[date_repeat_audiogram_requested]
--      ,[amount_of_additional_payment_date_1]
--      ,[amount_of_additional_payment_date_2]
--      ,[date_final_offer_accepted]
--      ,[date_final_offer_advised]
--      ,[date_final_offer_no_response]
--      ,[date_final_offer_rejected]
--      ,[date_litigation_advised]
--      ,[date_of_authorisation]
--      ,[date_of_final_offer]
--      ,[referral_date]
--      ,[claimant_identifier]
--      ,[ll01_claimants_medical_experts_name]
--      ,[other_items]
--      ,[participant_details]
--      ,[participant_role]
--      ,[participants_to_add]
--      ,[participants_to_add_date]
--      ,[portal_reference]
      ,[referral_reason]
--      ,[destructiondate]
      ,[cfa_entered_into_before_1_april_2013]
--      ,[claim_stage]
--      ,[claimant_medical_expert]
--      ,[division_name]
--      ,[fraudreferraltype]
--      ,[has_a_repeat_audiogram_been_requested]
--      ,[has_the_repeat_audiogram_been_agreed_to]
--      ,[holder]
--      ,[live_case_status]
--      ,[our_calculation_of_noise_level_db_claimant_audiogram]
--      ,[our_calculation_of_overall_db_claimant_audiogram]
--      ,[overall_db_loss_repeat_audiogram]
--      ,[panel_firm]
--      ,[quality_of_response_score]
--      ,[signed_off_by]
--      ,[worktype]
--      ,[ni_number_1st_claimant]
--      ,[reason_for_abandonment]
--      ,[cnf_acknowledgement_date]
--      ,[cnf_received_date]
--      ,[date_complaint_received]
--      ,[date_damages_paid]
--      ,[our_proportion_percent_of_costs]
--      ,[our_proportion_percent_of_damages]
--      ,[date_of_audit]
--      ,[date_of_infant_approval_hearing]
--      ,[date_of_referral]
--      ,[date_of_witness_statement_exchange]
--      ,[cancelled_or_current_risk]
--      ,[cit_claim]
--      ,[contract_terms]
--      ,[fic_score]
--      ,[first_only_claimant_registered_cru]
--      ,[is_this_a_work_referral]
--      ,[location_of_claimant_solicitors]
--      ,[location_of_claimants_workplace]
--      ,[mfu]
--      ,[national_insurance_number]
--      ,[outsource_instruction]
--      ,[policyholder_name_of_insured]
--      ,[reason_for_reopening_request]
--      ,[total_culpable_exposure_period]
--      ,[work_referral_recipient]
--      ,[work_referrer_identity]
--      ,[work_referrer_type]
--      ,[wp_type]
--      ,[date_pad_issued]
--      ,[date_pirc_completed]
--      ,[date_recovery_concluded]
--      ,[notification_to_zurich_date_old]
--      ,[part_eight_proceedings_date]
--      ,[portal_exit_date]
--      ,[region]
--      ,[status]
--      ,[summary_of_claim]
--      ,[time_of_accident]
--      ,[claimants_solicitors_consent_to_setting_aside_judgment]
--      ,[claimants_medical_experts_name]
--      ,[ageas_claim_track]
--      ,[ageas_dispute_type]
--      ,[ageas_instruction_type]
--      ,[ageas_original_fee_handling_basis]
--      ,[ageas_settlement_stage]
--      ,[audiologist_name]
--      ,[claimant_audiogram_coles_compliant]
--      ,[comments]
--      ,[defendant_trust]
--      ,[divisional_codes]
--      ,[insurance_cause_codes]
--      ,[location_of_audiogram]
--      ,[location_of_examination]
--      ,[manner_of_dispute_resolution]
--      ,[date_of_audiogram]
--      ,[date_of_disposal_hearing]
--      ,[date_of_medical_appointment]
--      ,[date_of_report]
--      ,[examination_date]
--      ,[name_of_instructing_insurer]
--      ,[original_fee_handling_basis]
--      ,[repeat_audiogram_coles_compliant]
--      ,[repeat_audiogram_requested]
--      ,[claimants_non_medical_experts_name]
--      ,[date_claimants_costs_agreed]
--      ,[date_q_to_nonmedical_experts_due]
--      ,[number_of_claimants]
--      ,[borough]
--      ,[prelit_score]
--      ,[district]
--      ,[source_of_instruction]
      ,[accident_location]
--      ,[age_at_accident]
--      ,[age_at_accident_banding]
--      ,[date_of_accident]
--      ,[filter_date]
--      ,[liability]
--      ,[litigated_claims]
--      ,[settlement_date_over_ninety_days]
--      ,[tier_1_3_case]
--      ,[date_opened_instructions_received]
--      ,[dss_create_time]
--      ,[dss_update_time]
--      ,[date_initial_offer]
--      ,[percentage_completion_change_date]
--      ,[insured_client_name]
--      ,[days_to_file_opened]
--      ,[claim_type]
--      ,[claimant_age]
      ,[date_final_bill]
--      ,[date_letter_of_claim]
--      ,[delivery_address_cheque]
--      ,[loc_periods]
--      ,[month_letter_of_claim]
--      ,[negotiator_claimant_costs]
--      ,[notification_to_zurich_date]
      ,[settlement_basis]
--      ,[tinnitus]
--      ,[trial_yes_no]
--      ,[type_of_injury]
--      ,[year_letter_of_claim]
--      ,[zurich_claimants_name]
--      ,[rsa_motor_costs_payment_date]
--      ,[rsa_motor_damages_payment_date]
--      ,[rsa_motor_costs_payment_notes]
--      ,[rsa_motor_damages_payment_notes]
--      ,[claimant_sols_firm]
--      ,[source_of_policy]
--      ,[cfa_date]
      ,[reason_for_settlement]
--      ,[cnf_loc_date]
--      ,[date_final_offer_no_response_processed]
--      ,[aig_litigation_stage_of_mediation]
--      ,[aig_type_damages_claimed]
--      ,[aig_weightmans_costs_apportioned]
--      ,[endsleigh_complaint_upheld]
--      ,[endsleigh_src_sent]
--      ,[endsleigh_action_resolve]
--      ,[endsleigh_root_cause_analysis]
--      ,[endsleigh_complaint_category]
--      ,[capita_claimant_audiologist_name]
--      ,[capita_claimant_engineer_name]
--      ,[capita_claimant_medical_expert_name]
--      ,[capita_defence_counsel_name]
--      ,[capita_defendant_audiologist_name]
--      ,[capita_defendant_engineer_name]
--      ,[capita_settlement_basis]
--      ,[capita_stage_of_settlement]
--      ,[capita_date_prelitigation_claimant_medical_report]
--      ,[capita_reason_for_litigation]
--      ,[date_last_strategy_note_update]
--      ,[capita_defendant_medical_expert_name]
--      ,[date_last_contact_capita_handler]
--      ,[closed]
--      ,[remove_legal_x]
--      ,[aig_highest_valuation_status]
--      ,[date_of_charging_order]
--      ,[ll02_claimants_non_medical_experts_name]
--      ,[lldb_case_number]
--      ,[notes_on_recovery]
--      ,[zurich_data_admin_claimant_name]
--      ,[claimants_solicitors_firm_name]
--      ,[date_authorised]
--      ,[rsa_date_requested]
--      ,[rsa_first_date]
--      ,[rsa_second_date]
--      ,[authorised_by]
--      ,[case_handler_review]
--      ,[cheque_received]
--      ,[lead_follow]
--      ,[payment_request]
--      ,[payment_to_whom]
--      ,[rsa_payment_notes]
--      ,[rsa_payment_type]
--      ,[rsa_requested_by]
--      ,[rsa_second_comments]
--      ,[rsa_tinnitus]
--      ,[supervisor_review]
--      ,[recovery_abandoned]
--      ,[stw_class_of_business]
--      ,[stw_exceptional]
--      ,[stw_reason_for_litigation]
--      ,[stw_status]
--      ,[stw_waste_or_water]
--      ,[bucket]
--      ,[deliveroo_contract]
--      ,[cfc_notification_date]
--      ,[epos_ipad_agreement]
--      ,[market_tech_brand]
--      ,[capital_contribution]
--      ,[are_we_making_a_pre_action_application]
--      ,[advocacy]
--      ,[advocacy_insource_advocate]
--      ,[advocacy_outcome]
--      ,[stw_work_type]
--      ,[stw_hafren_dyfrdwy_claim]
--      ,[co_op_origin_of_claim]
--      ,[stw_status_date]
--      ,[class_of_business_stw]
--      ,[cabinet_office_batch_number]
      ,[dst_claimant_solicitor_firm]
      ,[dst_insured_client_name]
  FROM [red_dw].[dbo].[dim_detail_claim] WITH (NOLOCK)


GO
