SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CredithireDashboard]
AS
BEGIN
SELECT dim_matter_header_current.[client_code]
,dim_matter_header_current.[matter_number]
,dim_fed_hierarchy_history.name As [Matter Owner]
,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
,dim_department.[department_name]
,dim_detail_core_details.[are_we_dealing_with_the_credit_hire]
,dim_detail_hire_details.[cha_are_we_in_reciept_of_payment_pack]
,dim_detail_core_details.[proceedings_issued]
,date_opened_case_management 
,date_closed_case_management 
,dim_detail_core_details.[suspicion_of_fraud]
,dim_detail_core_details.[does_claimant_have_personal_injury_claim]
,dim_detail_fraud.[fraud_current_fraud_type]
,dim_detail_core_details.[track]
,dim_matter_header_current.[matter_description]
,dim_client_involvement.[insurerclient_reference]
,dim_claimant_thirdparty_involvement.[claimantsols_name]
,dim_claimant_address.postcode AS [claimant1_postcode]
,dim_detail_hire_details.[credit_hire_organisation]
,dim_agents_involvement.[cho_name]
,dim_detail_hire_details.[cho]
,fact_detail_paid_detail.[hire_claimed]
,fact_detail_paid_detail.[amount_hire_paid]
,dim_detail_outcome.[date_claim_concluded]
,dim_detail_outcome.[outcome_of_case]
,dim_detail_core_details.[present_position]
,dim_detail_claim.[date_of_accident]
,dim_detail_hire_details.[hire_start_date]
,dim_detail_hire_details.[hire_end_date]
,dim_detail_hire_details.[cho_reference]
,dim_detail_hire_details.[chn_cho_vehicle_registration]
,dim_detail_hire_details.[chq_hire_group_billed]
,fact_detail_recovery_detail.[cht_daily_rate_claimed]
,fact_detail_client.[chy_interim_payment_made]
,fact_detail_client.[chk_how_many_hire_agreements_are_there]
,fact_detail_client.[chg_value_of_pav_repairs]
,fact_detail_paid_detail.[waivers_extras_charged]
,dim_detail_hire_details.[chm_third_party_vehicle_make_and_model]
,fact_detail_recovery_detail.[lowest_reasonable_rate]
,fact_detail_recovery_detail.[intervention_rate_offered]
,fact_detail_recovery_detail.[rate_allowed_by_court]
,fact_detail_recovery_detail.[daily_rate_claimed_gross]
,dim_detail_hire_details.[tpv_abi_group]
,dim_detail_hire_details.[gta_group_like_for_like]
,dim_detail_hire_details.[credit_hire_vehicle_make_and_model]
,dim_detail_hire_details.[date_copley_offer_sent]
,dim_detail_hire_details.[is_the_vehicle_total_loss]
,fact_finance_summary.[claimants_costs_paid]

,DATEDIFF(Day,dim_detail_hire_details.[hire_start_date],dim_detail_hire_details.[hire_end_date]) [Length of Hire]
,DATEDIFF(Day,date_opened_case_management ,dim_detail_outcome.[date_claim_concluded]) [Day to Resolution]
,DATEDIFF(Day,dim_detail_core_details.[incident_date],dim_detail_hire_details.[hire_end_date]) [Elasped Days from Incident]
,ms_only
,Longitude
,Latitude
,ms_fileid
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.fact_dimension_main
 ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON dim_matter_header_current.fee_earner_code=fed_code collate database_default AND dim_fed_hierarchy_history.dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details 
 ON dim_matter_header_current.client_code=dim_detail_core_details.client_code
 AND dim_matter_header_current.matter_number=dim_detail_core_details.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_department
 ON dim_matter_header_current.dim_department_key=dim_department.dim_department_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
 ON dim_matter_header_current.client_code=dim_detail_hire_details.client_code
 AND dim_matter_header_current.matter_number=dim_detail_hire_details.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud 
 ON dim_matter_header_current.client_code=dim_detail_fraud.client_code
 AND dim_matter_header_current.matter_number=dim_detail_fraud.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail 
 ON dim_matter_header_current.client_code=fact_detail_paid_detail.client_code
 AND dim_matter_header_current.matter_number=fact_detail_paid_detail.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome 
 ON dim_matter_header_current.client_code=dim_detail_outcome.client_code
 AND dim_matter_header_current.matter_number=dim_detail_outcome.matter_number   
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_matter_header_current.client_code=dim_detail_claim.client_code
 AND dim_matter_header_current.matter_number=dim_detail_claim.matter_number    
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail 
 ON dim_matter_header_current.client_code=fact_detail_recovery_detail.client_code
 AND dim_matter_header_current.matter_number=fact_detail_recovery_detail.matter_number    
LEFT OUTER JOIN red_dw.dbo.fact_detail_client
 ON dim_matter_header_current.client_code=fact_detail_client.client_code
 AND dim_matter_header_current.matter_number=fact_detail_client.matter_number    
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number  


LEFT OUTER JOIN red_dw.dbo.dim_client_involvement 
 ON dim_matter_header_current.client_code=dim_client_involvement.client_code
 AND dim_matter_header_current.matter_number=dim_client_involvement.matter_number  
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement 
 ON dim_matter_header_current.client_code=dim_claimant_thirdparty_involvement.client_code
 AND dim_matter_header_current.matter_number=dim_claimant_thirdparty_involvement.matter_number   
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement 
 ON dim_matter_header_current.client_code=dim_agents_involvement.client_code
 AND dim_matter_header_current.matter_number=dim_agents_involvement.matter_number    
LEFT OUTER JOIN red_dw.dbo.dim_claimant_address ON dim_claimant_address.master_fact_key=fact_dimension_main.master_fact_key
 LEFT OUTER JOIN red_dw.dbo.Doogal AS [Claimant_Postcode] ON [Claimant_Postcode].Postcode=dim_claimant_address.postcode
WHERE date_opened_case_management > '2016-01-01'
AND dim_matter_header_current.[reporting_exclusions] = 0 
AND dim_detail_core_details.[credit_hire] = 'Yes'
END
GO
