SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Max Taylor
-- Create date: 2022 - 02 - 03
-- Description:	Initial Create
-- =============================================

-- =============================================
CREATE PROCEDURE [dbo].[BAI_BAIMonthlyReport]

AS		 
		 
		 SELECT   
		    [BAICS ref] = COALESCE(dim_client_involvement.[insurerclient_reference],dim_client_involvement.client_reference,dim_client_involvement.insurerclient_reference),
            [Weightmans ref] = dim_client.client_code + ' ' + dim_matter_header_current.matter_number,
			[Disease Type] = CASE  
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='NIHL' THEN 'Deafness'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Living Mesothelioma' THEN 'Mesothelioma'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Fatal Mesothelioma' THEN 'Mesothelioma'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Lung cancer with asbestosis' THEN 'Lung cancer'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Lung cancer without asbestosis' THEN 'Lung cancer'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Asbestos Related Cancer' THEN 'Lung cancer with asbestosis'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Asbestos/Mesothelioma'  THEN  'Mesothelioma'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease – Asbestosis' THEN 'Asbestosis'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Industrial Deafness' THEN 'Deafness'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Pleural Thickening' THEN 'Pleural thickening'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Pleural Plaques' THEN 'Pleural plaques'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - VWF/Reynauds Phenomemon' THEN 'HAVS/VWF'
			ELSE dim_detail_core_details.capita_disease_type END,
			[Fee Earner] = name,
			[Date Instructed] = date_opened_case_management,
			[Claimant] = dim_claimant_thirdparty_involvement.claimant_name,
			[Policyholder] = COALESCE(insuredclient_name, dim_defendant_involvement.[defendant_name]),
			[Claimant Solicitor] = COALESCE(dim_detail_claim.dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name),
			[Gross Reserve] = fact_detail_reserve_detail.[total_current_reserve],
		    [FSCS Protected] = CASE 
			                WHEN ISNULL(dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank], '') ='' THEN 'No' 
			                ELSE dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank] END,
            [Cause of Litigation] = dim_detail_core_details.[referral_reason],
			[Damages Reserve] = fact_finance_summary.[damages_reserve],
			[Damages Agreed] = fact_finance_summary.[damages_paid],
			[Costs Reserve] = fact_detail_reserve_detail.[claimant_costs_reserve_current],
			[Costs Agreed] =  fact_finance_summary.[claimants_costs_paid] ,
			[Defence Costs Reserve] = fact_finance_summary.[defence_costs_reserve],
			[Defence Cost] = defence_costs_billed,
			
			    [Status] = CASE 
			 WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL AND UPPER(TRIM(dim_detail_outcome.[outcome_of_case])) IN ( 'DISCONTINUED','DISCONTINUED  - PRE-LIT','DISCONTINUED - INDEMNIFIED BY 3RD PARTY', 'DISCONTINUED - INDEMNIFIED BY THIRD PARTY', 'DISCONTINUED - POST LIT WITH NO COSTS ORDER', 'DISCONTINUED - POST-LIT WITH COSTS ORDER', 'DISCONTINUED - POST-LIT WITH NO COSTS ORDER', 'DISCONTINUED - PRE LIT NO COSTS ORDER', 'DISCONTINUED - PRE-LIT', 'STRUCK OUT', 'WON', 'WON AT TRIAL' ) THEN 'Closed – Repudiated'
             WHEN dim_matter_header_current.date_closed_case_management IS NULL AND UPPER(TRIM(dim_detail_outcome.[outcome_of_case])) IN ( 'DISCONTINUED','DISCONTINUED  - PRE-LIT','DISCONTINUED - INDEMNIFIED BY 3RD PARTY', 'DISCONTINUED - INDEMNIFIED BY THIRD PARTY', 'DISCONTINUED - POST LIT WITH NO COSTS ORDER', 'DISCONTINUED - POST-LIT WITH COSTS ORDER', 'DISCONTINUED - POST-LIT WITH NO COSTS ORDER', 'DISCONTINUED - PRE LIT NO COSTS ORDER', 'DISCONTINUED - PRE-LIT', 'STRUCK OUT', 'WON', 'WON AT TRIAL' ) THEN 'Repudiated'
			 WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL AND UPPER(TRIM(dim_detail_claim.[capita_settlement_basis])) IN ('CLAIM DISCONTINUED - QOCS','CLAIM DISCONTINUED - RECOVERED DEFENDANT COSTS','CLAIM DISCONTINUED - RECOVERING DEFENDANT COSTS','DROP HANDS','WON AT TRIAL' ) THEN 'Closed – Repudiated'
             WHEN dim_matter_header_current.date_closed_case_management IS NULL AND UPPER(TRIM(dim_detail_claim.[capita_settlement_basis])) IN ('CLAIM DISCONTINUED - QOCS','CLAIM DISCONTINUED - RECOVERED DEFENDANT COSTS','CLAIM DISCONTINUED - RECOVERING DEFENDANT COSTS','DROP HANDS','WON AT TRIAL' ) THEN 'Repudiated'
			 WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed'
             WHEN dim_detail_core_details.[capita_category_position_code] = '15' THEN 'Recovery'
             WHEN dim_detail_core_details.[capita_category_position_code] = '14' AND ISNULL(fact_detail_client.[nhsla_spend], 0) = 0 THEN  'Repudiated'
             WHEN dim_detail_core_details.[capita_category_position_code] = '13' OR fact_finance_summary.[claimants_total_costs_paid_by_all_parties] > 0 or fact_finance_summary.[claimants_costs_paid] > 0 or dim_detail_outcome.[date_costs_settled] IS NOT NULL THEN 'Costs Settled'
             WHEN dim_detail_core_details.[capita_category_position_code] = '12' OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL  OR  dim_detail_outcome.[date_claim_concluded] IS NOT null OR  fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] > 0 OR fact_finance_summary.[damages_paid] > 0 THEN  'Damages Paid'
			   ELSE 'Live' END,
			   dim_detail_core_details.present_position,

			   date_closed_case_management ,

			Open_closed = CASE WHEN date_closed_case_management IS NOT NULL  AND final_bill_date >= '2022-01-01'  THEN 'Closed' 
			                   WHEN (dim_detail_core_details.present_position  LIKE '%Final bill sent%' or dim_detail_core_details.present_position LIKE '%To be closed%') AND final_bill_date >= '2022-01-01' THEN 'Closed'
							   WHEN date_closed_case_management IS NULL AND CAST(date_opened_case_management AS DATE) >='2022-01-01' THEN 'Open'
			                   WHEN date_closed_case_management IS NULL AND (dim_detail_core_details.present_position NOT LIKE '%Final bill sent%' AND  dim_detail_core_details.present_position NOT LIKE '%To be closed%') THEN  'Current caseload' 
							   END
			,final_bill_date
			,dim_detail_core_details.capita_category_position_code
		
		--00516705 00000696
		FROM  red_dw.dbo.fact_dimension_main
		JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT JOIN red_dw..dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
		LEFT JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
		LEFT JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
		LEFT JOIN red_dw.dbo.dim_detail_practice_area
		ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
		LEFT JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
		LEFT JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
		LEFT JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
		LEFT JOIN red_dw.dbo.fact_detail_claim
		ON fact_detail_claim.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_detail_elapsed_days
		ON fact_detail_elapsed_days.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		LEFT JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
		LEFT JOIN red_dw.dbo.dim_defendant_involvement
		ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
		LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_detail_client
		ON fact_detail_client.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		
		WHERE 1 =1
		AND dim_matter_header_current.[reporting_exclusions] = 0
        AND dim_matter_header_current.[master_client_code] = 'W15349'
        AND 
		CASE WHEN date_closed_case_management IS NOT NULL  AND final_bill_date >= '2022-01-01'  THEN 'Closed' 
			                   WHEN (dim_detail_core_details.present_position  LIKE '%Final bill sent%' or dim_detail_core_details.present_position LIKE '%To be closed%') AND final_bill_date >= '2022-01-01' THEN 'Closed'
							   WHEN date_closed_case_management IS NULL AND CAST(date_opened_case_management AS DATE) >='2022-01-01' THEN 'Open'
			                   WHEN date_closed_case_management IS NULL AND (dim_detail_core_details.present_position NOT LIKE '%Final bill sent%' AND  dim_detail_core_details.present_position NOT LIKE '%To be closed%') THEN  'Current caseload' 
							   END IS NOT NULL
		
		-- // search("Insurance/Costs*", dim_matter_worktype[work_type_name], 1, 0) = 0,
          --//  search("PIP*",  dim_client_involvement[insurerclient_reference], 1, 0) = 0
          --//,dim_matter_header_current[master_client_matter_combined]="W15373-1089"

ORDER BY
    dim_client.[client_code],
    dim_matter_header_current.[matter_number]

		--dim_client_involvement.[insurerclient_reference],
   --         dim_client_involvement.[client_reference],
   --         dim_client.[client_code],
   --         dim_matter_header_current.[matter_number],
   --         dim_matter_header_current.[master_client_matter_combined],
   --         dim_matter_header_current.[matter_description],
   --         dim_insurance_involvement.[insurancecomp_name],
   --         dim_defendant_involvement.[defendant_reference],
   --         dim_detail_core_details.[clients_claims_handler_surname_forename],
   --         dim_claimant_thirdparty_involvement.[claimant_name],
   --         dim_defendant_involvement.[defendant_name],
   --         dim_client_involvement.[insuredclient_name],
   --         dim_fed_hierarchy_history_matter_owner.[matter_owner_name],
   --         dim_date_matter_opened_case_management.[matter_opened_case_management_calendar_date],
   --         dim_claimant_thirdparty_involvement.[claimantsols_name],
   --         dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank],
   --         dim_detail_core_details.[capita_dti_yes_enter_percent_no_leave_blank],
   --         dim_detail_core_details.[capita_disease_type],
   --         dim_detail_outcome.[capita_interim_payment_made],
   --         dim_detail_health.[nhs_capita_date_claimant_part_36_offer_received],
   --         dim_detail_court.[date_of_trial],
   --         dim_detail_court.[date_of_first_day_of_trial_window],
   --         dim_detail_core_details.[capita_category_position_code],
   --         dim_detail_core_details.[capita_proposed_strategy],
   --         dim_detail_core_details.[ll05_capita_likely_settlement_date],
   --         dim_detail_outcome.[capita_date_final_fee_paid],
   --         fact_detail_elapsed_days.[elapsed_days_live_case_management_system],
   --         dim_detail_health.[tinnitus],
   --         dim_detail_claim.[rsa_tinnitus],
   --         dim_detail_core_details.[moj_apply],
   --         dim_detail_practice_area.[did_claim_conclude_in_moj_portal],
   --         dim_detail_core_details.[is_there_an_issue_on_liability],
   --         dim_detail_core_details.[track],
   --         dim_detail_claim.[capita_reason_for_litigation],
   --         dim_detail_claim.[capita_stage_of_settlement],
   --         dim_detail_claim.[capita_settlement_basis],
   --         dim_detail_claim.[capita_date_prelitigation_claimant_medical_report],
   --         dim_detail_claim.[capita_claimant_medical_expert_name],
   --         dim_detail_claim.[date_last_strategy_note_update],
   --         dim_detail_claim.[capita_claimant_audiologist_name],
   --         dim_detail_claim.[capita_defendant_audiologist_name],
   --         dim_detail_claim.[capita_claimant_engineer_name],
   --         dim_detail_claim.[capita_defendant_engineer_name],
   --         dim_detail_claim.[capita_defence_counsel_name],
   --         fact_detail_claim.[capita_defendant_audiometry_repeat_cost],
   --         fact_detail_claim.[capita_defendant_engineers_report_costs],
   --         fact_detail_claim.[capita_defendant_medical_report_costs],
   --         fact_detail_claim.[capita_defence_counsels_fees],
   --         fact_finance_summary.[total_amount_billed],
   --         fact_finance_summary.[unpaid_bill_balance],
   --         fact_finance_summary.[defence_costs_reserve],
   --         fact_finance_summary.[chargeable_minutes_recorded],
   --         dim_detail_outcome.[are_we_pursuing_a_recovery],
   --         fact_finance_summary.[total_costs_recovery],
   --         dim_detail_outcome.[date_claim_concluded],
   --         fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties],
   --         fact_detail_future_care.[disease_total_estimated_settlement_value],
   --         fact_finance_summary.[claimants_total_costs_paid_by_all_parties],
   --         fact_detail_claim.[disease_total_estimated_settlement],
   --         dim_date_matter_closed_case_management.[matter_closed_case_management_calendar_date],
   --         dim_detail_court.[date_proceedings_issued],
   --         dim_detail_claim.[cfa_entered_into_before_1_april_2013],
   --         dim_detail_claim.[capita_defendant_medical_expert_name],
   --         dim_date_matter_closed_case_management.[dim_date_key],
   --         dim_detail_outcome.[date_costs_settled],
   --         dim_detail_claim.[date_last_contact_capita_handler],
   --         fact_finance_summary.[defence_costs_billed],
   --         fact_detail_paid_detail.[cru_paid_by_all_parties],
   --         fact_detail_client.[nhs_charges_paid_by_all_parties],
   --         fact_detail_cost_budgeting.[total_estimated_profit_costs],
   --         dim_detail_outcome.[outcome_of_case],
   --         fact_finance_summary.[damages_paid], -- TRA070
   --         fact_finance_summary.[claimants_costs_paid], -- TRA072
   --         fact_detail_client.[nhsla_spend],  -- TRA072+TRA070+NMI616+NMI128 
   --         dim_client.[client_code_trimmed],
   --         dim_matter_header_current.[matter_number_trimmed],
   --         dim_matter_worktype.[work_type_name],
   --         dim_detail_core_details.[present_position],
		 --   dim_detail_claim.[dst_claimant_solicitor_firm],
   --  	    dim_detail_core_details.[referral_reason],
		 --   dim_detail_core_details.[proceedings_issued],
		 --   fact_finance_summary.[wip],
		 --   dim_detail_practice_area.[tinnitus],
		 --   dim_detail_core_details.[date_of_cfa],
		 --   dim_detail_core_details.[has_the_claimant_got_a_cfa],
		 --   dim_detail_core_details.[jcb_rolls_royce_date_of_letter_of_claim],
		 --   dim_detail_health.[date_of_service_of_proceedings],
		 --   fact_finance_summary.[damages_reserve],
		 --   fact_detail_reserve_detail.[claimant_costs_reserve_current],
		   
		 --   [Date of CFA (colour)], CASE WHEN ISNULL(dim_detail_core_details.[date_of_cfa], '') = '' AND  dim_detail_core_details.[has_the_claimant_got_a_cfa]='Yes' THEN 'Red' ELSE 'White' END,
		 --   [Date of CFA], CASE WHEN ISNULL(dim_detail_core_details.[date_of_cfa],'') = '' AND  ISNULL(dim_detail_core_details.[has_the_claimant_got_a_cfa], '')<>'Yes' THEN 'N/A' ELSE dim_detail_core_details.[date_of_cfa] END,
		 --   [Date of Letter of Claim (colour)] = CASE WHEN ISNULL(dim_detail_core_details.[jcb_rolls_royce_date_of_letter_of_claim], '') = '' THEN 'Red' ELSE 'White' END,
		 --   [Date of Issue (colour)] = CASE WHEN ISNULL(dim_detail_court.[date_proceedings_issued], '')='' AND dim_detail_core_details.[proceedings_issued]='Yes' THEN 'Red' ELSE 'White' END,
		 --   [Date of Issue] = CASE WHEN ISNULL(dim_detail_court.[date_proceedings_issued], '') = '' AND  ISNULL(dim_detail_core_details.[proceedings_issued], '')<>'Yes' THEN 'N/A' ELSE dim_detail_court.[date_proceedings_issued] END,
		 --   [Date of Service (colour)] = CASE WHEN ISNULL(dim_detail_health.[date_of_service_of_proceedings], '') = '' AND  dim_detail_core_details.[proceedings_issued]='Yes' THEN 'Red' ELSE 'White' END,
		 --   [Date of Service]=  CASE WHEN ISNULL(dim_detail_health.[date_of_service_of_proceedings], '') = '' AND ISNULL(dim_detail_core_details.[proceedings_issued], '')<>'Yes' THEN 'N/A' ELSE dim_detail_health.[date_of_service_of_proceedings] END,
		 --   [Liability Admitted] =  CASE WHEN ISNULL(dim_detail_core_details.[is_there_an_issue_on_liability], '')='No' THEN 'Yes' ELSE 'No' END,
		 --   -- AM logic for defence costs reserve
		 --   [New Defence Costs Reserve] =  CASE WHEN dim_matter_header_current.date_closed_case_management  IS NOT NULL THEN  0.00 ELSE ISNULL(fact_detail_cost_budgeting.[total_estimated_profit_costs], 0) - ISNULL(fact_finance_summary.[defence_costs_billed], 0) END,
	       
		 --  	[QOCS] =  CASE WHEN dim_detail_court.[date_proceedings_issued] < '2013-04-01' 
			--OR 	dim_detail_claim.[cfa_entered_into_before_1_april_2013] = 'Yes' 
			--OR lower(dim_detail_core_details.[capita_disease_type]) = 'mesothelioma' THEN 'No' ELSE 'Yes' END,
 		--   	--// Addition LD 2017/12/13 webby 281355
       
		
			
   --         [Portal Claim] = CASE
   --         				WHEN ISNULL(dim_detail_core_details.[moj_apply], '') = '' AND LEFT(dim_client_involvement.[insurerclient_reference], 1) =  'P'  THEN 'Yes'
   --         				WHEN ISNULL(dim_detail_core_details.[moj_apply], '') = '' AND LEFT(ISNULL(dim_client_involvement.[insurerclient_reference], ''), 1) <> 'P' THEN 'No' END,
            				
   --         [Settled in Portal] = CASE 
			--                WHEN dim_detail_practice_area.[did_claim_conclude_in_moj_portal] = 'No' THEN 'N/A' 
			--				ELSE dim_detail_practice_area.[did_claim_conclude_in_moj_portal] END,
   --         [FSCS Protected] = CASE 
			--                WHEN ISNULL(dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank], '') ='' THEN 'No' 
			--                ELSE dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank] END,

   --         [Trial Date] = CASE WHEN CAST(dim_detail_court.[date_of_trial] AS DATE) > GETDATE() THEN dim_detail_court.[date_of_trial] END,
            
   --        [Capita reference (colour)] = CASE WHEN ISNULL(dim_client_involvement.[insurerclient_reference], '')= '' THEN 'Red' ELSE 'White' END,
   --        [Employee (colour)] = CASE WHEN ISNULL(dim_claimant_thirdparty_involvement.[claimant_name], '') = '' THEN 'Red' ELSE 'White' END,
   --        [Policyholder (colour)] = CASE WHEN ISNULL(dim_defendant_involvement.[defendant_name], '') = '' AND ISNULL(dim_client_involvement.[insuredclient_name], '') = '' THEN 'Red' ELSE 'White' END,
   --        [Claim type (colour)] = CASE WHEN ISNULL(dim_detail_core_details.[capita_disease_type], '') = '' THEN 'Red' ELSE 'White' END,
   --        [Claimant solicitor (colour)], CASE WHEN ISNULL(dim_claimant_thirdparty_involvement.[claimantsols_name], '') = '' THEN 'Red' ELSE 'White' END,
   --        [Track (colour)] = CASE WHEN ISNULL(dim_detail_core_details.[track], '') = '' THEN 'Red' ELSE 'White' END,
   --        [Reason for litigation (colour)] = CASE WHEN ISNULL(dim_detail_claim.[capita_reason_for_litigation], '') = '' THEN 'Red' ELSE 'White' END
           
		 --[Date of pre-lit claimant med report (colour)], IF(ISBLANK(dim_detail_claim[capita_date_prelitigation_claimant_medical_report]) = true, "Red", "White"),
   --        [Claimant medical expert (colour)], IF(ISBLANK(dim_detail_claim[capita_claimant_medical_expert_name]) = true, "Red", "White"),
   --         [Likely Settlement Date (colour)], IF(ISBLANK(dim_detail_core_details[ll05_capita_likely_settlement_date]) = true || 
   --         										IF(dim_detail_core_details[ll05_capita_likely_settlement_date] < TODAY() && 
   --         											ISBLANK(dim_detail_outcome[date_claim_concluded]) =true, true, false) = true, "Red", "White"),
            
   --         [Defendant Medical Expert (colour)], if(isblank(dim_detail_claim[capita_defendant_medical_expert_name]) = true && isblank(fact_detail_claim[capita_defendant_medical_report_costs]) = false, "Red", "White"),
   --         [Defendant Audiologist (colour)], if(isblank(dim_detail_claim[capita_defendant_audiologist_name]) = true && isblank(fact_detail_claim[capita_defendant_audiometry_repeat_cost]) = false, "Red", "White"),
   --         [Defendant Engineer (colour)], if(isblank(dim_detail_claim[capita_defendant_engineer_name]) = true && isblank(fact_detail_claim[capita_defendant_engineers_report_costs]) = false, "Red", "White"),
   --         [Defence Counsel Name (colour)], if(isblank(dim_detail_claim[capita_defence_counsel_name]) = true && isblank(fact_detail_claim[capita_defence_counsels_fees]) = false, "Red", "White"),
            
   --        -- // (2nd if statement) 1st entry in pathcontains() takes into account the blanks that arent picked up by the isblank() check
   --        	[Repeat Audiometry Cost (colour)], if(isblank(fact_detail_claim[capita_defendant_audiometry_repeat_cost]) = true  && 
   --       											IF(isblank(dim_detail_claim[capita_defendant_audiologist_name]) = false && 
   --       												PATHCONTAINS("|N/A|N/a|N.A|n/a|N.a", dim_detail_claim[capita_defendant_audiologist_name]) = FALSE(), TRUE, false) = true, "Red", "White"),
            
   --       --  // (2nd if statement) 1st entry in pathcontains() takes into account the blanks that aren't picked up by the isblank() check
   --         [Engineers Report Cost (colour)], if(isblank(fact_detail_claim[capita_defendant_engineers_report_costs]) = true && 
   --         										IF(isblank(dim_detail_claim[capita_defendant_engineer_name]) = false &&
   --         											PATHCONTAINS("|N/A|N/a|N.A|n/a|N.a", dim_detail_claim[capita_defendant_engineer_name]) = FALSE(), TRUE, false) = true, "Red", "White"),
                                               
   --       --  // (2nd if statement) 1st entry in pathcontains() takes into account the blanks that aren't picked up by the isblank() check            
   --         [Defendant Medical Report Cost (colour)], if(isblank(fact_detail_claim[capita_defendant_medical_report_costs]) = true && 
   --         												IF(isblank(dim_detail_claim[capita_defendant_medical_expert_name]) = false &&
   --         													PATHCONTAINS("|N/A|N/a|N.A|n/a|N.a", dim_detail_claim[capita_defendant_medical_expert_name]) = FALSE(), TRUE, false) = true, "Red", "White"),
            
   --        -- // (2nd if statement) 1st entry in pathcontains() takes into account the blanks that aren't picked up by the isblank() check
   --         [Counsels fees (colour)], if(isblank(fact_detail_claim[capita_defence_counsels_fees]) = true && 
   --         								IF(isblank(dim_detail_claim[capita_defence_counsel_name]) = false &&
   --         									PATHCONTAINS("|N/A|N/a|N.A|n/a|N.a", dim_detail_claim[capita_defence_counsel_name]) = FALSE(), TRUE, false) = true, "Red", "White"),
            
            
   --         [Recover defence costs (colour)], IF(ISBLANK(dim_detail_outcome[are_we_pursuing_a_recovery]) = true && 
   --         										IF(PATHCONTAINS("Recovery", dim_detail_core_details[referral_reason]) = TRUE() || 
   --         											PATHCONTAINS("Recovery", dim_detail_core_details[capita_category_position_code]) = TRUE(), true, false), "Red", "White"),
                       
            
            
   --         [Defence Costs Reserve],  if(dim_date_matter_closed_case_management[dim_date_key] <> 0, 0, fact_finance_summary[defence_costs_reserve] - fact_finance_summary[total_amount_billed]),
   --         [Damages Reserve], if(isblank(dim_detail_outcome[date_claim_concluded]) = FALSE() || isblank(dim_detail_outcome[date_costs_settled]) = FALSE() || dim_date_matter_closed_case_management[dim_date_key] <> 0, 0, fact_detail_future_care[disease_total_estimated_settlement_value]),
   --         [Claimant Solicitor Costs Reserve], if(isblank(dim_detail_outcome[date_costs_settled]) = FALSE() || dim_date_matter_closed_case_management[dim_date_key] = 0,  fact_detail_claim[disease_total_estimated_settlement], 0),
   --         [Paid Damages], fact_detail_paid_detail[total_settlement_value_of_the_claim_paid_by_all_the_parties] - fact_detail_paid_detail[cru_paid_by_all_parties] - fact_detail_client[nhs_charges_paid_by_all_parties],
   --         [Tinnitus2],IF(ISBLANK(dim_detail_practice_area[tinnitus]) || dim_detail_practice_area[tinnitus]= "",
   --         				IF(ISBLANK(dim_detail_claim[rsa_tinnitus]) || dim_detail_claim[rsa_tinnitus]  = "",
   --         				iF(ISBLANK(dim_detail_health[tinnitus]) || dim_detail_health[tinnitus] = "","",dim_detail_health[tinnitus]),dim_detail_claim[rsa_tinnitus]),dim_detail_practice_area[tinnitus])
   
        
GO
