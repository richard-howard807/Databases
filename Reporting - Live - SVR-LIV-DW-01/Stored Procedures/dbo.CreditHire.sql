SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-13
-- Description:	#67669, data for credit hire dashboard, same logic as the credit hire report which is in DAX
-- =============================================
CREATE PROCEDURE [dbo].[CreditHire]
	
AS
BEGIN

	SET NOCOUNT ON;


SELECT dim_matter_header_current.[client_code] AS [Client Code],
		dim_matter_header_current.[matter_number] AS [Matter Number],
		RTRIM(dim_matter_header_current.[client_code])+'-'+dim_matter_header_current.[matter_number] AS [Weightmans Reference],
		dim_matter_header_current.matter_owner_full_name AS [Matter Owner],
		dim_fed_hierarchy_history.hierarchylevel4hist AS [Team],
		dim_department.[department_name] AS [Matter Department],
		dim_detail_core_details.[are_we_dealing_with_the_credit_hire] AS [Are we dealing with the credit hire?],
		dim_detail_hire_details.[cha_are_we_in_reciept_of_payment_pack] AS [Are we in receipt of payment pack?],
		dim_detail_core_details.[proceedings_issued] AS [Litigated],
		dim_matter_header_current.date_opened_case_management AS [Date Opened],
		dim_matter_header_current.date_closed_case_management AS [Date Closed],
		dim_detail_core_details.[suspicion_of_fraud] AS [Suspicion of Fraud],
		dim_detail_core_details.[does_claimant_have_personal_injury_claim] AS [Claim for PI?],
		dim_detail_fraud.[fraud_current_fraud_type] AS [Fraud Type],
		dim_detail_core_details.[track] AS [Track],
		dim_matter_header_current.[matter_description] AS [Matter Description],
		dim_client_involvement.[insurerclient_reference] AS [Client Reference],
		dim_claimant_thirdparty_involvement.[claimantsols_name] AS [Claimant Solicitors],
		dim_claimant_address.postcode AS [Claimant Postcode],
		COALESCE(dim_detail_hire_details.[credit_hire_organisation_cho],dim_detail_hire_details.[other],dim_agents_involvement.cho_name)  AS [Credit Hire Organisation],
		fact_detail_paid_detail.[hire_claimed] AS [Amount of Hire Claimed],
		fact_detail_paid_detail.[amount_hire_paid] AS [Amount of Hire Paid],
		dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded],
		dim_detail_outcome.[outcome_of_case] AS [Outcome of Case],
		ISNULL(fact_detail_paid_detail.[hire_claimed],0)-ISNULL(fact_detail_paid_detail.[amount_hire_paid],0) AS [Amount Saved £],
		CASE WHEN (fact_detail_paid_detail.[amount_hire_paid] IS NULL OR fact_detail_paid_detail.[hire_claimed] IS NULL OR fact_detail_paid_detail.[amount_hire_paid]=0 OR fact_detail_paid_detail.[hire_claimed]=0) THEN NULL 
		ELSE ISNULL(fact_detail_paid_detail.[hire_claimed],0)/ISNULL(fact_detail_paid_detail.[amount_hire_paid],0) END  AS [Amount Saved %],
		dim_detail_core_details.[present_position] AS [Present Poistion],
		dim_detail_claim.[date_of_accident] AS [Date of Accident],
		ISNULL(dim_detail_hire_details.[cho_hire_start_date], dim_detail_hire_details.[hire_start_date]) AS [Hire Start Date],
		dim_detail_hire_details.[hire_end_date] AS [Hire End Date],
		DATEDIFF(DAY, ISNULL(dim_detail_hire_details.[cho_hire_start_date], dim_detail_hire_details.[hire_start_date]),ISNULL(dim_detail_hire_details.[hire_end_date], GETDATE())) AS [Days in Hire],
		dim_detail_hire_details.[cho_reference] AS [CHO Reference],
		dim_detail_hire_details.[chn_cho_vehicle_registration] AS [CHO Vehicle Reg],
		dim_detail_hire_details.[chq_hire_group_billed] AS [Hire Group Billed],
		dim_detail_hire_details.[tpv_abi_group] AS [TBV ABI Group],
		dim_detail_hire_details.[gta_group_like_for_like] AS [GTA Group (like for like)],
		dim_detail_hire_details.[is_the_vehicle_total_loss] AS [Is the vehicle a total loss?],
		fact_detail_recovery_detail.[daily_rate_claimed_gross] AS [Daily Rate Claimed Gross],
		fact_detail_recovery_detail.[cht_daily_rate_claimed] AS [Daily Rate Claimed (Net)],
		fact_detail_client.[chy_interim_payment_made] AS [Interim payments made by client],
		fact_detail_recovery_detail.[intervention_rate_offered] AS [Intervention Rate Offered],
		fact_detail_recovery_detail.[lowest_reasonable_rate] AS [Lowest Reasonable Rate],
		fact_detail_client.[chk_how_many_hire_agreements_are_there] AS [How many hire agreements are there?],
		fact_detail_recovery_detail.[rate_allowed_by_court] AS [Rate Allowed by Court],
		fact_detail_client.[chg_value_of_pav_repairs] AS [Value of PAV/ Repairs],
		fact_detail_paid_detail.[waivers_extras_charged] AS [One off Extra's (£)],
		dim_detail_hire_details.[date_copley_offer_sent] AS [Date of Copley Offer Sent],
		dim_detail_hire_details.[chm_third_party_vehicle_make_and_model] AS [Third Party Vehicle (make, model],
		dim_detail_hire_details.[credit_hire_vehicle_make_and_model] AS [Credit Hire Vehicle (make, model],
		CASE WHEN chv_date_hire_paid IS NULL OR date_claim_concluded IS NULL THEN 'Open' ELSE 'Concluded' END AS [Status],
		DATEDIFF(DAY, date_of_accident, ISNULL(dim_detail_hire_details.[cho_hire_start_date], dim_detail_hire_details.[hire_start_date])) AS [Days til Hire]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_department
ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud
ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement
ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client
ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_address
ON dim_claimant_address.master_fact_key = fact_dimension_main.master_fact_key

WHERE date_opened_case_management>='20150101'
AND reporting_exclusions=0
AND dim_detail_core_details.credit_hire='Yes'

END
GO
