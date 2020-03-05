SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--==============================================================================
-- Description    :    All matters related to Aggregate Industries
-- Generated for  :    Weightmans
-- Generated on   :    Friday, January 31, 2020 at 11:46:20
-- Author         :    Max Taylor
--==============================================================================

/*Ticket #45754 New report - Aggregate Industries
Please include all live matters and matters closed since 1 January 2019 where any of the following appear in "Client Name" or the name in the "Insured Client" Associate:
Aggregate Industries
Camas UK
Manorcrow
English China Clays
Kennedy Asphalt
Ernest Fletcher
Charcon Constructions
E Fletcher Builders
Please can open and closed matters appear on separate tabs. 

Title for open tab - "Aggregate Industries Ltd - Open Matters" 
Title for closed tab - "Aggregate Industries Ltd - Closed since 1 January 2019"*/

CREATE PROCEDURE [dbo].[AggregateIndustries_AllMatters] -- EXEC [dbo].[AggregateIndustries_AllMatters]

AS

BEGIN

SELECT 

dim_matter_header_current.[case_id],
dim_client.[client_code],
dim_matter_header_current.[matter_number],
dim_client_involvement.[insuredclient_name],
dim_client_involvement.[insuredclient_reference],
dim_client_involvement.[insurerclient_name],
dim_detail_core_details.[incident_date],
dim_claimant_thirdparty_involvement.[claimant_name],
dim_matter_header_current.date_opened_case_management  AS [matter_opened_case_management_calendar_date],
dim_detail_core_details.[clients_claims_handler_surname_forename],
dim_detail_incident.[date_claim_notified],
dim_detail_client.[business_unit],
dim_detail_claim.[divisional_codes],
dim_detail_claim.[insurance_cause_codes],
dim_detail_hire_details.[description_of_injury],
dim_detail_incident.[description_of_incident_1],
dim_detail_incident.[description_of_incident_2],
dim_matter_header_current.date_closed_case_management AS [matter_closed_case_management_calendar_date],
dim_detail_core_details.[proceedings_issued],
dim_detail_court.[date_proceedings_issued],
dim_detail_core_details.[is_there_an_issue_on_liability],
dim_detail_outcome.[date_claim_concluded],
dim_detail_outcome.[outcome_of_case],
fact_detail_reserve_detail.[damages_reserve_initial],
fact_finance_summary.[damages_reserve],
fact_finance_summary.[damages_interims],
dim_detail_outcome.[date_costs_settled],
fact_detail_reserve_detail.[claimant_costs_reserve_current],
fact_finance_summary.[other_defendants_costs_reserve],
fact_detail_paid_detail.[interim_costs_payments],
dim_detail_core_details.[present_position],
fact_finance_summary.[defence_costs_reserve],
fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution],
fact_finance_summary.[recovery_defence_costs_from_claimant],
fact_detail_recovery_detail.[recovery_claimants_costs_via_third_party_contribution],
fact_finance_summary.[recovery_defence_costs_via_third_party_contribution],
fact_finance_summary.[damages_paid],
fact_finance_summary.[claimants_costs_paid],
fact_finance_summary.[other_defendants_costs_paid],
fact_finance_summary.[interlocutory_costs_paid_to_claimant],
fact_finance_summary.[detailed_assessment_costs_paid],
fact_detail_paid_detail.[interim_costs_payments_by_client_pre_instruction],
dim_detail_core_details.[incident_location_postcode],
dim_detail_incident.[handler_comments],
dim_fed_hierarchy_history.[name] AS [matter_owner_name],
dim_matter_header_current.[matter_description],
dim_client.[client_name],
dim_matter_worktype.[work_type_name],
fact_finance_summary.[damages_reserve_net],
fact_finance_summary.[tp_costs_reserve_net],
fact_finance_summary.[defence_costs_reserve_net],
fact_detail_reserve_detail.[total_reserve_net],
fact_finance_summary.[total_reserve],
fact_finance_summary.[total_recovery],
fact_finance_summary.[damages_paid_to_date],
fact_finance_summary.[total_amount_billed],
fact_detail_claim.[payments_claimant_costs],
fact_finance_summary.[total_paid],
fact_detail_paid_detail.[total_incurred],
[Weightmans_Ref] = dim_client.[client_code] + '/' + dim_matter_header_current.[matter_number],

/*Applicable Deductible
      IF(dim_detail_core_details[incident_date] <= value("2014-03-31"), 150000,
	--if(dim_detail_core_details[incident_date] <= value("2015-03-31"), 343355,
	--if(dim_detail_core_details[incident_date] > value("2015-03-31"), 349308))),
*/
[Applicable Deductible] = 
       CASE WHEN dim_detail_core_details.[incident_date] <= '2014-03-31' THEN 150000
	        WHEN dim_detail_core_details.[incident_date] <= '2015-03-31' THEN 343355
			WHEN dim_detail_core_details.[incident_date] >  '2015-03-31' THEN 349308
			END 

/*Claim Status
--IF(	dim_date_matter_closed_case_management[matter_closed_case_management_calendar_date] = blank() , "Open","Closed"),
*/
, [Claim Status] = 
        CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open'
		     ELSE 'Closed' END 

/*Policy Type
Show “Public Liability” if Work Type Group is “PL – All”
Show “Employers Liability” if Work Type Group is “EL” OR “Disease”
Show “Motor Liability” is Work Type Group is “Motor”
Show “Other” for all other Work Type Groups

*/
, [Policy Type]  = 
         CASE WHEN dim_matter_worktype.[work_type_group] = 'PL All' THEN 'Public Liability'
		      WHEN dim_matter_worktype.[work_type_group] IN ('EL', 'Disease') THEN 'Employers Liability'
			  WHEN dim_matter_worktype.[work_type_group] = 'Motor' THEN 'Motor Liability'
			  ELSE 'Other' END
/*Description of Incident
--IF(dim_detail_incident[description_of_incident_1] = blank(),
--dim_detail_incident[description_of_incident_2], dim_detail_incident[description_of_incident_1]),
*/
, [Description of Incident] = COALESCE(dim_detail_incident.[description_of_incident_1], dim_detail_incident.[description_of_incident_2] )

/*Liability Position Admitted
          IF(dim_detail_core_details[is_there_an_issue_on_liability] = "Yes","No",
		  if(dim_detail_core_details[is_there_an_issue_on_liability] = "No","Yes")),
*/
, [Liability Position Admitted] = 
        CASE WHEN dim_detail_core_details.[is_there_an_issue_on_liability] = 'Yes' THEN 'No'
		     WHEN dim_detail_core_details.[is_there_an_issue_on_liability] = 'No' THEN 'Yes'
			 END
 
 /* Reason for Descision */
, [Reason for Descision] = ''


FROM red_dw.dbo.fact_dimension_main fdm

	JOIN red_dw.dbo.dim_matter_header_current 
		ON dim_matter_header_current.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key

	LEFT JOIN red_dw.dbo.dim_detail_core_details 
		ON dim_detail_core_details.dim_detail_core_detail_key = fdm.dim_detail_core_detail_key
	
	LEFT JOIN red_dw.dbo.fact_detail_paid_detail 
		ON fact_detail_paid_detail.master_fact_key = fdm.master_fact_key

	LEFT JOIN red_dw.dbo.fact_finance_summary 
		ON fact_finance_summary.master_fact_key = fact_detail_paid_detail.master_fact_key

	LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.master_fact_key = fact_detail_paid_detail.master_fact_key

	LEFT JOIN red_dw.dbo.fact_detail_claim 
		ON fact_detail_claim.master_fact_key = fact_detail_paid_detail.master_fact_key

	LEFT JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fdm.dim_client_key

	LEFT JOIN red_dw.dbo.dim_client_involvement 
		ON dim_client_involvement.dim_client_involvement_key = fdm.dim_client_involvement_key

	LEFT JOIN red_dw.dbo.dim_detail_incident 
		ON dim_detail_incident.dim_detail_incident_key = fdm.dim_detail_incident_key

	LEFT JOIN red_dw.dbo.dim_matter_worktype 
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

	LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key  AND dim_fed_hierarchy_history.dss_current_flag = 'Y'

	LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fdm.dim_claimant_thirdpart_key

    LEFT JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_detail_client_key = fdm.dim_detail_client_key

	LEFT JOIN red_dw.dbo.fact_detail_recovery_detail
		ON fact_detail_recovery_detail.master_fact_key = fact_detail_claim.master_fact_key

	LEFT JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fdm.dim_detail_outcome_key

	LEFT JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fdm.dim_detail_claim_key

	LEFT JOIN red_dw.dbo.dim_detail_hire_details
		ON dim_detail_hire_details.dim_detail_hire_detail_key = fdm.dim_detail_hire_detail_key

	LEFT JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_detail_court_key = fdm.dim_detail_court_key

			WHERE 1 = 1 
			
			/* All matters open and closed since 1st Jan 2019*/
		    AND YEAR(dim_matter_header_current.date_opened_case_management) >= 2019

			AND (
				   dim_client.[client_name] LIKE '%Aggregate Industries%'
				OR dim_client.[client_name] LIKE '%Camas UK%'
				OR dim_client.[client_name] LIKE '%Manorcrow%'
				OR dim_client.[client_name] LIKE '%English China Clays%'
				OR dim_client.[client_name] LIKE '%Kennedy Asphalt%'
				OR dim_client.[client_name] LIKE '%Ernest Fletcher%'
				OR dim_client.[client_name] LIKE '%Charcon Constructions%'
				OR dim_client.[client_name] LIKE '%E%Fletcher Builders%'

				
				OR dim_client_involvement.[insurerclient_name] LIKE '%Aggregate Industries%'
				OR dim_client_involvement.[insurerclient_name] LIKE '%Camas UK%'
				OR dim_client_involvement.[insurerclient_name] LIKE '%Manorcrow%'
				OR dim_client_involvement.[insurerclient_name] LIKE '%English China Clays%'
				OR dim_client_involvement.[insurerclient_name] LIKE '%Kennedy Asphalt%'
				OR dim_client_involvement.[insurerclient_name] LIKE '%Ernest Fletcher%'
				OR dim_client_involvement.[insurerclient_name] LIKE '%Charcon Constructions%'
				OR dim_client_involvement.[insurerclient_name] LIKE '%E%Fletcher Builders%'

				
				OR dim_client_involvement.[insuredclient_name] LIKE '%Aggregate Industries%'
				OR dim_client_involvement.[insuredclient_name] LIKE '%Camas UK%'
				OR dim_client_involvement.[insuredclient_name] LIKE '%Manorcrow%'
				OR dim_client_involvement.[insuredclient_name] LIKE '%English China Clays%'
				OR dim_client_involvement.[insuredclient_name] LIKE '%Kennedy Asphalt%'
				OR dim_client_involvement.[insuredclient_name] LIKE '%Ernest Fletcher%'
				OR dim_client_involvement.[insuredclient_name] LIKE '%Charcon Constructions%'
				OR dim_client_involvement.[insuredclient_name] LIKE '%E%Fletcher Builders%'
				
				OR dim_matter_header_current.matter_description LIKE '%Aggregate Industries%'
				OR dim_matter_header_current.matter_description LIKE '%Camas UK%'
				OR dim_matter_header_current.matter_description LIKE '%Manorcrow%'
				OR dim_matter_header_current.matter_description LIKE '%English China Clays%'
				OR dim_matter_header_current.matter_description LIKE '%Kennedy Asphalt%'
				OR dim_matter_header_current.matter_description LIKE '%Ernest Fletcher%'
				OR dim_matter_header_current.matter_description LIKE '%Charcon Constructions%'
				OR dim_matter_header_current.matter_description LIKE '%E%Fletcher Builders%'

				)

END
--		dim_date_matter_opened_case_management[matter_opened_caseLIKE '%E%Fletcher Builders%'_management_calendar_date] >= value("2015-12-01") &&
--			(
--				search("Aggregate Industries",dim_matter_header_current[matter_description],1,0) > 0 ||
--				search("Aggregate Industries",dim_client[client_name],1,0) > 0 ||
--				search("Aggregate Industries",dim_client_involvement[insurerclient_name],1,0) > 0 ||
--				search("Aggregate Industries",dim_client_involvement[insuredclient_name],1,0) > 0
--			) &&
--			search("PL -",dim_matter_worktype[work_type_name],1,0) > 0
--	) ||
--	PATHCONTAINS("381782|382095|405993|429601|458468|524419|543962|480363|558232|414810|260359|508149|559050|382428|528936|532528|533325|535985|569077|569503|588873|592847|593221|692715|333027",dim_matter_header_current[case_id] )
--)
--)
--order by dim_client[client_code],
--dim_matter_header_current[matter_number]
GO
