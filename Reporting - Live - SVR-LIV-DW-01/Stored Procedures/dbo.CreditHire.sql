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
		CASE WHEN dim_detail_core_details.proceedings_issued ='Yes' THEN 'Litigated' ELSE 'Non-Litigated' END AS [Proceedings Issued],
		dim_detail_outcome.[repudiation_outcome] [Repudiation - outcome],
		dim_matter_header_current.[matter_description] AS [Matter Description],
		dim_client_involvement.[insurerclient_reference] AS [Client Reference],
		ISNULL(dim_detail_claim.[dst_claimant_solicitor_firm],dim_claimant_thirdparty_involvement.[claimantsols_name]) AS [Claimant Solicitors],
		dim_claimant_address.postcode AS [Claimant Postcode],
		COALESCE(IIF(dim_detail_hire_details.[credit_hire_organisation_cho] = 'Other', NULL, dim_detail_hire_details.[credit_hire_organisation_cho]), dim_detail_hire_details.[other], dim_agents_involvement.cho_name)  AS [Credit Hire Organisation],
		fact_detail_paid_detail.[hire_claimed] AS [Amount of Hire Claimed],
		fact_detail_paid_detail.[amount_hire_paid] AS [Amount of Hire Paid],
		dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded],
		dim_detail_outcome.[outcome_of_case] AS [Outcome of Case],
		ISNULL(fact_detail_paid_detail.[hire_claimed],0)-ISNULL(fact_detail_paid_detail.[amount_hire_paid],0) AS [Amount Saved £],
		CASE WHEN (fact_detail_paid_detail.[amount_hire_paid] IS NULL OR fact_detail_paid_detail.[hire_claimed] IS NULL OR fact_detail_paid_detail.[amount_hire_paid]=0 OR fact_detail_paid_detail.[hire_claimed]=0) THEN NULL 
		ELSE (ISNULL(fact_detail_paid_detail.[hire_claimed],0)-ISNULL(fact_detail_paid_detail.[amount_hire_paid],0))/ISNULL(fact_detail_paid_detail.[hire_claimed],0) END  AS [Amount Saved %],
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
		CASE WHEN date_closed_case_management IS NULL OR date_claim_concluded IS NULL OR fact_detail_paid_detail.[amount_hire_paid] IS null THEN 'Open' ELSE 'Concluded' END AS [Status],
		DATEDIFF(DAY, date_of_accident, ISNULL(dim_detail_hire_details.[cho_hire_start_date], dim_detail_hire_details.[hire_start_date])) AS [Days til Hire],
		CASE WHEN dim_detail_hire_details.[credit_hire_organisation_cho]='ClaimsFast' THEN 'Claims Fast'
			WHEN dim_detail_hire_details.[credit_hire_organisation_cho] LIKE 'Enterprise Rent%' THEN 'Enterprise Rent-a-Car'
			WHEN dim_detail_hire_details.[credit_hire_organisation_cho] LIKE 'Kindertons%' THEN 'Kindertons'
			WHEN dim_detail_hire_details.[credit_hire_organisation_cho] LIKE 'OnHire%' THEN 'On Hire'
			ELSE dim_detail_hire_details.[credit_hire_organisation_cho] end
			AS [CHO],
		CAST(CAST([Claimant_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [Claimant Postcode Latitude],
		CAST(CAST([Claimant_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [Claimant Postcode Longitude],
		fact_finance_summary.[damages_paid_to_date]  AS [Damages Paid],
		fact_finance_summary.[damages_reserve] AS [Damages Reserve],
		CASE WHEN fact_detail_paid_detail.hire_claimed >=0 AND fact_detail_paid_detail.hire_claimed<=10000 THEN '£0-£10,000'
			WHEN fact_detail_paid_detail.hire_claimed >10000 AND fact_detail_paid_detail.hire_claimed<=25000 THEN '£10,001-£25,000'
			WHEN fact_detail_paid_detail.hire_claimed >25000 AND fact_detail_paid_detail.hire_claimed<=50000 THEN '£25,001-£50,000'
			WHEN fact_detail_paid_detail.hire_claimed >50000 AND fact_detail_paid_detail.hire_claimed<=100000 THEN '£50,001-£100,000'
			WHEN fact_detail_paid_detail.hire_claimed >100000  THEN '£100,001+' ELSE NULL END AS [Value Banding],
		CASE WHEN Claimant_Postcode.Postcode LIKE 'E%'
					OR Claimant_Postcode.Postcode LIKE 'EC%'
					OR Claimant_Postcode.Postcode LIKE 'N%'
					OR Claimant_Postcode.Postcode LIKE 'NW%'
					OR Claimant_Postcode.Postcode LIKE 'SE%'
					OR Claimant_Postcode.Postcode LIKE 'SW%'
					OR Claimant_Postcode.Postcode LIKE 'W%'
					OR Claimant_Postcode.Postcode LIKE 'WC%' THEN 'London' ELSE 'Other' END AS [Area],	
		dim_court_involvement.court_name AS [Court],
		dim_detail_hire_details.[cho_postcode] AS [CHO Postcode],
		CHO_Postcode.Latitude AS [CHO Latitude],
		CHO_Postcode.Longitude AS [CHO Longitude],
		dim_detail_hire_details.[chx_is_the_claimant_impecunious] AS [Is the Client Impecunious?],
		dim_detail_fraud.fraud_type_motor AS [Motor Fraud Type],
		CASE WHEN dim_detail_core_details.suspicion_of_fraud='Yes' THEN 'Fraud'
		WHEN dim_detail_core_details.suspicion_of_fraud='No' AND dim_detail_core_details.does_claimant_have_personal_injury_claim='No' THEN 'TPPD only'
		WHEN dim_detail_core_details.suspicion_of_fraud='No' AND dim_detail_core_details.does_claimant_have_personal_injury_claim='Yes' THEN 'BI and TPD'
		ELSE NULL END AS [Claim Types]


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
LEFT OUTER JOIN red_dw.dbo.Doogal AS [Claimant_Postcode] ON [Claimant_Postcode].Postcode=dim_claimant_address.postcode 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.Doogal AS [CHO_Postcode] ON [CHO_Postcode].Postcode=dim_detail_hire_details.[cho_postcode]
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key

WHERE date_opened_case_management>='20150101'
AND reporting_exclusions=0
AND dim_detail_core_details.credit_hire='Yes'
AND dim_detail_core_details.are_we_dealing_with_the_credit_hire='Yes'
AND dim_fed_hierarchy_history.hierarchylevel3hist='Motor'
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports' 
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Returned to Client'

END
GO
