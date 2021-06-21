SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2018-07-10
Description:		General Data MI to drive the Tableau Dashboards
Current Version:	Initial Create
====================================================
-- ES 03-02-2020 added revenue and hours per financial year, 45432
-- ES 05-10-2020 #74471
-- ES 06-01-2020 #73408 added stw details
-- JL 17-01-2020 Added in involvement table v 1.1
-- JL 08-12-2020 Its been advised that the face_dimention_main key for history needs to be fixed by Richard. Have removed the join and replaced untill its fixed. v 1.2
-- ES 11/02/2021 #88316, added dim_detail_core_details.[do_clients_require_an_initial_report]
-- ES 18/06/2021 added dim_detail_core_details[will_total_gross_reserve_on_the_claim_exceed_500000] for EJ
====================================================

*/
CREATE PROCEDURE [dbo].[Create_Vis_GeneralData]
AS
BEGIN

IF OBJECT_ID('dbo.Vis_GeneralData', 'U') IS NOT NULL
DROP TABLE dbo.Vis_GeneralData

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT 

RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_matter_header_current.[matter_description] AS [Matter Description]
		, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
		, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
		, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Open/Closed Case Status]
		, dim_instruction_type.instruction_type AS [Instruction Type]
		, dim_detail_core_details.date_instructions_received AS [Date Instructions Received]
		, dim_detail_outcome.date_costs_settled AS [Date Costs Settled]
		, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
		, dim_fed_hierarchy_history.[name] AS [Case Manager]
		, dim_employee.locationidud AS [Office]
		, dim_fed_hierarchy_history.[hierarchylevel2hist] [Division]
		, dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department]
		, dim_matter_header_current.department_code [Department Code]
		, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
		, dim_fed_hierarchy_history.[worksforname] AS [Team Manager]
		, dim_detail_practice_area.[bcm_name] AS [BCM Name]
		, dim_fed_hierarchy_history.[reportingbcmname] AS [BCM]
		, dim_department.department_name AS [Matter Category]
		, dim_department.department_code AS [Matter Category Code]
		, dim_detail_core_details.[do_clients_require_an_initial_report] AS [Do Clients Require an Initial Report?]
		, dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
		, dim_detail_core_details.status_on_instruction AS [Status On Instruction]
		, dim_detail_core_details.[is_there_an_issue_on_liability] AS [Issue On Liability]
		, dim_detail_core_details.delegated AS Delegated
		, fact_finance_summary.[fixed_fee_amount] AS [Fixed Fee Amount]
		, dim_detail_finance.[output_wip_fee_arrangement] AS [Output WIP Fee Arrangement]
		, dim_detail_finance.[output_wip_percentage_complete] AS [Output WIP % Complete]
		, dim_detail_core_details.is_this_a_linked_file AS [Linked File]
		, dim_detail_core_details.lead_file_matter_number_client_matter_number [Lead File Client Matter Number]
		, dim_detail_core_details.[associated_matter_numbers] [Associated Matter Number]
		, dim_detail_core_details.clients_claims_handler_surname_forename AS [Clients Claim Handler Full Name]
		, dim_matter_worktype.[work_type_code] AS [Work Type Code]
		, dim_matter_worktype.[work_type_name] AS [Work Type]
		, dim_matter_worktype.[work_type_group] AS [Work Type Group]
		, dim_client.client_group_code AS [Client Group Code]
		, dim_client.client_group_name AS [Client Group Name]
		, dim_client.client_name AS [Client Name]
		, dim_client.segment AS [Client Segment]
		, dim_client.[sector] AS [Client Sector]
		, dim_client.sub_sector AS [Client Sub-sector]
		, CASE WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'access legal%' THEN 'Access Legal'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'aegis%' THEN 'Aegis Legal'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'agea law%' THEN 'Ageas Law'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'alyson france%' THEN 'Alyson France and Co'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'andrew and %' THEN 'Andrew and Co LLP Solicitors'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'antony gold%' THEN 'Anthony Gold Solicitors'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'armstrong%' THEN 'Armstrong Solicitors'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'ashton%' THEN 'Ashton KCJ'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'aspire law%' THEN 'Aspire Law'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'barlow robbins%' THEN 'Barlow Robbins LLP'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'barr ellison%' THEN 'Barr Ellison LLP'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'slater and gordon%' THEN 'Slater and Gordon'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'slater gordon%' THEN 'Slater and Gordon'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'thompsons%' THEN 'Thompsons'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'thompson sol%' THEN 'Thompsons'
			WHEN LOWER(dim_claimant_thirdparty_involvement.[claimantsols_name]) LIKE 'irwin mitchell%' THEN 'Irwin Mitchell LLP'
		ELSE dim_claimant_thirdparty_involvement.[claimantsols_name] END AS [Claimant's Solicitor]
		, dim_detail_claim.dst_claimant_solicitor_firm  AS[Claimant's Solicitor (Data Service)]
		, CAST(CAST([Claimant_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [Claimant Postcode Latitude]
		, CAST(CAST([Claimant_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [Claimant Postcode Longitude]
		, CAST(CAST([TP_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [TP Postcode Latitude]
		, CAST(CAST([TP_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [TP Postcode Longitude]
		, CAST(CAST([Insured_Department_Depot_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [Insured Department Depot Latitude]
		, CAST(CAST([Insured_Department_Depot_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [Insured Department Depot Longitude]
		, dim_client_involvement.client_reference AS [Client Reference]
		, dim_client_involvement.[insurerclient_name] AS [Insurer Client Name]
		, dim_client_involvement.[insuredclient_name] AS [Insured Client Name]
		, dim_client_involvement.insurerclient_reference AS [Insurer Client Reference]
		, dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference]
		, dim_detail_core_details.insured_sector AS [Insured Sector]
		, dim_detail_core_details.present_position AS [Present Position]
		, dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
		, dim_detail_core_details.track AS [Track]
		, dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?]
		, dim_detail_core_details.referral_reason AS [Referral Reason]
		, dim_detail_core_details.[fixed_fee] AS [Fixed Fee]
		, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_core_details.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_claim.accident_location AS [Accident Location]
		, CAST(CAST([Incident_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [Incident Postcode Latitude]
		, CAST(CAST([Incident_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [Incident Postcode Longitude]
		, dim_detail_core_details.incident_date AS [Incident Date]
		, dim_detail_core_details.[brief_description_of_injury] AS [Description of Injury]
		, TimeRecorded.HoursRecorded AS [Hours Recorded]
		, fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting]
		, fact_matter_summary_current.last_bill_date AS [Last Bill Date]
		, fact_bill_matter.last_bill_date [Last Bill Date Composite]
		, dim_matter_header_current.[final_bill_date] AS [Date of Final Bill]
		, dim_detail_claim.[cfa_entered_into_before_1_april_2013] AS [CFA Entered before 1st April 2013]
		, dim_detail_core_details.aig_reason_for_service_of_proceedings AS [AIG Reason for Service of Proceedings]
		, dim_detail_outcome.exclude_from_reports AS [Exclude from Reports]
		, fact_finance_summary.total_reserve AS [Total Reserve]
		, fact_finance_summary.[total_reserve_net] AS [Total Reserve (Net)]
		, fact_finance_summary.damages_reserve AS [Damages Reserve]
		, fact_finance_summary.tp_costs_reserve AS [TP Costs Reserve]
		, fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
		, fact_finance_summary.[other_defendants_costs_reserve] AS [Other Defendants Costs Reserve]
		, fact_finance_summary.damages_paid AS [Damages Paid]
		, fact_finance_summary.defence_costs_reserve_initial AS [Defence Costs Reserve Initial]
		, fact_finance_summary.disbursement_balance AS [Disbursement Balance]
		, fact_finance_summary.other_defendants_costs_paid AS [Other Defendants Costs Paid]
		, fact_finance_summary.other_defendants_costs_reserve_initial AS [Other Defendants Cost Reserve Initial]
		, fact_finance_summary.output_wip_balance AS [Output WIP Balance]
		, dim_detail_outcome.date_referral_to_costs_unit AS [Date Referral to Costs Unit]
		, fact_finance_summary.claimants_costs_paid AS [Claimant's Costs Paid]
		, fact_detail_claim.[claimant_sols_total_costs_sols_claimed] AS [Total third party costs claimed]
		, fact_finance_summary.[total_tp_costs_paid] AS [Total third party costs paid]
		, fact_finance_summary.[detailed_assessment_costs_claimed_by_claimant] AS [Detailed Assessment Costs Claimed by Claimant]
		, fact_finance_summary.detailed_assessment_costs_paid AS [Detailed Assessment Costs Paid]
		, fact_finance_summary.[costs_claimed_by_another_defendant] AS [Costs Claimed by another Defendant]
		, fact_finance_summary.damages_reserve_initial AS [Damages Reserve Initial]
		, fact_detail_cost_budgeting.[costs_paid_to_another_defendant] AS [Costs Paid to Another Defendant]
		, fact_finance_summary.[total_recovery] AS [Total Recovery]
		, fact_finance_summary.[total_paid] AS [Total Paid]
		, fact_finance_summary.total_amount_bill_non_comp AS [Total Amount Billed]
		, fact_finance_summary.vat_non_comp AS [VAT Non-comp]
		, fact_finance_summary.[defence_costs_billed] AS [Revenue]
		, fact_finance_summary.[disbursements_billed] AS [Disbursements Billed]
		, fact_finance_summary.wip AS [WIP]
		, fact_finance_summary.vat_billed AS [VAT]
		--, fact_finance_summary.commercial_costs_estimate AS [Commercial Costs Estimate]
		,ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) AS [Commercial Costs Estimate]
		
		, fact_matter_summary_current.[client_account_balance_of_matter] AS [Client Account Balance of Matter]
		, fact_finance_summary.total_costs_claimed AS [Total Costs Claimed]
		, fact_finance_summary.total_costs_paid AS [Total Costs Paid]
		, fact_finance_summary.total_reserve_initial AS [Total Reserve Initial]
		, fact_finance_summary.total_settlement_value_of_the_claim_paid_by_all_the_parties AS [Total Settlement Value of the Claim Paid by all the Parties]
		, fact_finance_summary.tp_costs_reserve_initial AS [TP Costs Reserve Initial]
		, fact_finance_summary.unpaid_disbursements AS [Unpaid Disbursements]
		, CASE WHEN dim_detail_critical_mi.[litigated]='Yes' OR dim_detail_core_details.[proceedings_issued]='Yes' THEN 'Litigated' ELSE 'Pre-Litigated' END AS [Litigated/Proceedings Issued]
		, fact_finance_summary.damages_reserve_net
		, fact_finance_summary.tp_costs_reserve_net
		, fact_finance_summary.defence_costs_reserve_net
		, fact_finance_summary.other_defendants_costs_reserve_net
		, dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report]
		, fact_detail_elapsed_days.[elapsed_days_live_files] AS [Elapsed Days Live Files]
		, DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,dim_detail_outcome.date_claim_concluded) AS [Elapsed Days to Outcome]
		, fact_detail_elapsed_days.[elapsed_days_conclusion] AS [Elapsed Days Conclusion]
		, dim_detail_outcome.[repudiation_outcome] [Repudiation - outcome]
		, CASE  WHEN dim_fed_hierarchy_history.[leaver]=1 THEN 'Yes' ELSE 'No' END AS [Leaver?]
		, fact_matter_summary_current.time_billed/60 AS [Time Billed]
		, PartnerHours [Total Partner Hours] 
		, NonPartnerHours [Total Non Partner Hours]
		, [Partner/ConsultantTime] AS [Total Partner/Consultant Hours Recorded]
	    , AssociateHours AS [Total Associate Hours Recorded]
	    , [Solicitor/LegalExecTimeHours] AS [Total Solicitor/LegalExec Hours Recorded]
		, ParalegalHours AS [Total Paralegal Hours Recorded]
		, TraineeHours AS [Total Trainee Hours Recorded]
        , OtherHours AS  [Total Other Hours Recorded]
		
		

		--Hire Deatils
		, dim_detail_core_details.credit_hire AS [Credit Hire]
		, dim_detail_core_details.[are_we_dealing_with_the_credit_hire] AS [Are we Dealing with the Credit Hire?]
		, dim_detail_hire_details.[claim_for_hire] AS [Claim for Hire]
		, dim_agents_involvement.cho_name AS [Credit Hire Organisation]
		, dim_detail_hire_details.[cho] AS [Credit Hire Organisation Detail]
		, dim_detail_hire_details.cho_hire_start_date AS [Hire Start Date]
		, dim_detail_hire_details.chp_hire_end_date AS [Hire End Date]
		, dim_detail_hire_details.chv_date_hire_paid AS [CHV Date Hire Paid]
		, fact_detail_paid_detail.[amount_hire_paid] AS [Hire Paid]
		, fact_detail_paid_detail.[hire_claimed] AS [Hire Claimed]
		, dim_detail_hire_details.[hire_paid_rolling] AS [Hire Paid Rolling]
		, dim_detail_hire_details.[cho_postcode] AS [CHO Postcode]
		, CAST(CAST([CHO_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [CHO Postcode Latitude]
		, CAST(CAST([CHO_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [CHO Postcode Longitude]
		, dim_detail_hire_details.[chb_date_engineer_instructed] AS [Date Engineer Instructed]

		--Property Details
		, fact_detail_property.car_spaces_inc AS [Car Spaces Inc]
		, fact_detail_property.client_paying AS [Client Paying]
		, fact_detail_property.contribution AS [Contribution]
		, fact_detail_property.contribution_percent AS [Contribution Percent]
		, fact_detail_property.current_rent AS [Current Rent]
		, fact_detail_property.disbursements_estimate AS [Disbursements Estimate]
		, fact_detail_property.fee_estimate AS [Fee Estimate]
		, fact_detail_paid_detail.[fee_estimate] AS [Fee Estimates]
		, fact_detail_property.floor_area_square_foot AS [Floor Area Square Foot]
		, fact_detail_property.full_price AS [Full Price]
		, fact_detail_property.gifa_as_let_sq_feet AS [Gifa as let sq feet]
		, fact_detail_property.mezz_sq_feet AS [Mezz sq feet]
		, fact_detail_property.next_rent_amount AS [Next Rent Amount]
		, fact_detail_property.no_of_bedrooms AS [No of Bedrooms]
		, fact_detail_property.original_rent AS [Original Rent]
		, fact_detail_property.passing_rent AS [Passing Rent]
		, fact_detail_property.proposed_rent AS [Proposed Rent]
		, fact_detail_property.ps_purchase_price AS [PS Purchase Price]
		, fact_detail_property.purchase_price AS [Purchase Price]
		, fact_detail_property.reduced_purchase_price AS [Reduced Purchase Price]
		, fact_detail_property.rent_arrears AS [Rent Arrears]
		, fact_detail_property.sales_admin_sq_ft AS [Sales Admin sq ft]
		, fact_detail_property.service_charge AS [Service Charge]
		, fact_detail_property.size_square_foot AS [Size square foot]
		, fact_detail_property.store_sq_ft AS [Store sq ft]
		, fact_detail_property.third_party_pay AS [Third Party Pay]
		, fact_detail_property.total_sq_ft AS [Total sq ft]
		, dim_detail_property.address AS [Address]
		, dim_detail_property.agent AS [Agent]
		, dim_detail_property.be_name AS [BE Name]
		, dim_detail_property.be_number AS [BE Number]
		, dim_detail_property.break_clause_notice_required AS [Break Clause Notice Required]
		, dim_detail_property.break_date AS [Break Date]
		, dim_detail_property.[break_1] AS [Break]
		, dim_detail_property.campus AS [Campus]
		, COALESCE(dim_detail_property.[property_type_1], dim_detail_property.[property_type_2]) AS [Property Type]
		, dim_detail_property.[university_lead] AS  [University Lead]
		, dim_detail_property.[responsibilty_budget] AS [Responsibilty/Budget]
		, dim_detail_property.[payable] AS Payable
		, dim_detail_property.case_classification AS [Case Classification]
		, dim_detail_property.date_of_lease AS [Date of Lease]
		, dim_detail_property.date_of_transfer AS [Date of Transfer]
		, dim_detail_property.estate_manager AS [Estate Manager]
		, dim_detail_property.external_surveyor AS [External Surveyor]
		, dim_detail_property.first_rent_review AS [First Rent Review]
		, dim_detail_property.second_rent_review AS [Second Rent Review]
		, dim_detail_property.third_rent_review AS [Third Rent Review]
		, dim_detail_property.fourth_rent_review AS [Fourth Rent Review]
		, dim_detail_property.fifth_rent_review AS [Fifth Rent Review]
		, dim_detail_property.fixed_feehourly_rate AS [Fixed Feehourly Rate]
		, dim_detail_property.[fixed_fee_hourly_rate] AS [Fixed Fee or Hourly Rate?]
		, dim_detail_property.freehold_leasehold AS [Freehold/Leasehold]
		, dim_detail_property.insurance_premium AS [Insurance Premium]
		, dim_detail_property.key_date_name AS [Key Date Name]
		, dim_detail_property.landlord AS [Landlord]
		, dim_detail_property.landlord_address AS [Landlord Address]
		, dim_detail_property.landlord_break_date AS [Landlord Break Date]
		, dim_detail_property.lease_end_date AS [Lease End Date]
		, dim_detail_property.lease_start_date AS [Lease Start Date]
		, dim_detail_property.lease_expiry_date AS [Lease Expiry Date]
		, dim_detail_property.lease_term AS [Lease Term]
		, dim_detail_property.next_key_date AS [Next Key Date]
		, dim_detail_property.option_to_break AS [Option to Break]
		, dim_detail_property.option_to_purchase AS [Option to Purchase]
		, dim_detail_property.[brand] AS [Pentland Brand]
		, dim_detail_property.pentland_brand_contact AS [Pentland Brand Contact]
		, dim_detail_property.pentland_reference AS [Pentland Reference]
		, dim_detail_property.postcode AS [Property Postcode]
		, CAST(CAST([Property_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [Property Postcode Latitude]
		, CAST(CAST([Property_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [Property Postcode Longitude]
		, dim_detail_property.property_address AS [Property Address]
		, dim_detail_property.property_ref AS [Property Ref]
		, dim_detail_property.rateable_value AS [Rateable Value]
		, dim_detail_property.rates_payable AS [Rates Payable]
		, dim_detail_property.rates_payable_to AS [Rates payable to]
		, dim_detail_property.registered_proprietor AS [Registered Proprietor]
		, dim_detail_property.rent_commencement_date AS [Rent Commencement Date]
		, dim_detail_property.rent_review_dates AS [Rent Review Dates]
		, dim_detail_property.restrictions_on_register AS [Restrictions on Register]
		, dim_detail_property.service_charges AS [Service Charges]
		, dim_detail_property.starting_rent AS [Starting Rent]
		, dim_detail_property.tenant_break AS [Tenant Break]
		, dim_detail_property.tenant_name AS [Tenant Name]
		, dim_detail_property.tenure AS [Tenure]
		, dim_detail_property.term_start_date AS [Term Start Date]
		, dim_detail_property.term_end_date AS [Term End Date]
		, dim_detail_property.title_number AS [Title Number]
		, dim_detail_property.tenant_rolling_break_notice AS [Tenant Rolling Break Notice]
		, dim_detail_property.landlord_rolling_break_notice AS [Landlord Rolling Break Notice]
		, CASE WHEN LEN(latitude)>=1 AND latitude <>'53058411' THEN CAST(CAST(REPLACE(latitude,',','') AS FLOAT) AS DECIMAL(8,6))  
			ELSE NULL END AS [Property Latitude]
		, CAST(CAST(dim_detail_property.[longitude] AS FLOAT) AS DECIMAL(9,6)) AS [Property Longitude]
		, dim_detail_property.[op_co] AS [Operation Company]
		, dim_detail_property.[lease_id] AS [Lease ID]
		, dim_detail_property.[dp_number] AS [DP Number]
		, dim_detail_property.[dp_location] AS [DP Location]
		, dim_detail_property.[region] AS [Property Region]
		, dim_detail_property.[branch_code] AS [Property Branch Code]
		, dim_detail_property.[m3_code] AS [M3 Code]
		, dim_detail_property.[area] AS [Property Area]
		, dim_detail_property.[branch] AS [Property Branch]
	    , dim_detail_property.[start] AS [Property Start Date]
		, dim_detail_property.[end_date] AS [Property End Date]
		, dim_detail_property.[case_status] AS [Property Case Status]
		, dim_detail_property.[break_date2] AS [Break Date 2]
		--ASW
		, dim_detail_property.[date_lease_agreed] AS [Date Lease Agreed]
		, dim_detail_property.[store_name] AS [Store Name]
		, dim_detail_property.[present_position_desc] AS [Property Present Position]
		, dim_detail_property.[property_contact] AS [Property Contact]
		, CASE WHEN dim_client.client_code='00787558' THEN dim_client.client_name
				WHEN dim_client.client_code='00787559' THEN dim_client.client_name
				WHEN dim_client.client_code='00787560' THEN dim_client.client_name 
				WHEN dim_client.client_code='00787561' THEN dim_client.client_name ELSE NULL END AS [Fascia]
		, dim_detail_property.[case_type_asw_desc] AS [Case Type]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays] ([LeaseAgreedTasks].[DateTaskCreated],GETDATE()) AS [Days from Lease In]
		, dim_detail_property.[status_asw] AS [Status ASW]
		, [LeaseAgreedTasks].[DateTaskCreated] AS [Date Lease In]
		, dim_detail_property.completion_date AS [Property Completion Date]
		, dim_file_notes.external_file_notes AS [Matter Notes]
		, dim_detail_property.[exchange_date] AS [Property Exchange Date]

		--Archibald Bathgate
		, CASE WHEN fact_dimension_main.client_code='00872166' THEN 'https://oneview.weightmans.com/overview/property-overview?matterid='+RTRIM(fact_dimension_main.client_code)+'-'+fact_dimension_main.matter_number+'&gridId=7387' 
				ELSE NULL END AS [Archibald Bathgate Document Link]
		, dim_detail_property.position_within_quarry AS [Position within Quarry]
		, dim_detail_property.asset_number AS [Asset Number]
		, dim_detail_property.parties AS [Parties]
		, dim_detail_property.date_of_acquisition AS [Date of Acquisition]
		, fact_detail_property.costs_of_acquisition AS [Costs of Acquisition]
		, dim_detail_property.size_of_title AS [Size of Title]
		, dim_detail_property.restrictive_covenants AS [Restrictive Covenants]
		, dim_detail_property.rights AS [Rights]
		, dim_detail_property.footpaths AS [Footpaths]
		, dim_detail_property.which_planning_application_is_the_property_subject_to AS [Which Planning application is the property subject to]

		, dim_detail_plot_details.barratt_manchester_developments AS [Barratt Manchester Developments]
		, dim_detail_plot_details.date_of_acknowledgement AS [Date of Acknowledgement]
	    , dim_detail_plot_details.date_of_exchange AS [Date of Exchange]
	    , dim_detail_plot_details.date_of_search_results AS [Date of Search Results]
	    , dim_detail_plot_details.david_wilson_homes_limited_developments AS [David Wilson Homes Limited Developments]
	    , dim_detail_plot_details.deposit_money_received AS [Deposit Money Received]
	    , dim_detail_plot_details.developer AS [Developer]
	    , dim_detail_plot_details.development AS [Development]
	    , dim_detail_plot_details.eccleston_homes_ltd AS [Eccleston Homes Ltd]
	    , dim_detail_plot_details.exchange_date AS [Exchange Date]
	    , dim_detail_plot_details.greenfields_place_development_company_limited_developments AS [Greenfields Place Development Company Limited Developments]
	    , dim_detail_plot_details.lender AS [Lender]
	    , dim_detail_plot_details.manchester_ship_canal_developments_advent_limited AS [Manchester Ship Canal Developments Advent Limited]
	    , dim_detail_plot_details.mortgage_offer_received AS [Mortgage Offer Received]
	    , dim_detail_plot_details.p_sols_anticipate_exchange_of_contracts AS [P Sols Anticipate Exchange of Contracts]
	    , dim_detail_plot_details.p_sols_received_contract AS [P Sols Received Contract]
	    , dim_detail_plot_details.persimmon_homes_limited_development AS [Persimmon Homes Limited Development]
	    , dim_detail_plot_details.psplot_number AS [PS Plot Number]
	    , dim_detail_plot_details.purelake_new_homes_limited AS [Purelake New Homes Limited]
	    , dim_detail_plot_details.reservation_received AS [Reservation Received]
	    , dim_detail_plot_details.thomas_jones_sons_limited_development AS [Thomas Jones Sons Limited Development]
	    , dim_detail_plot_details.type_of_lease AS [Type of Lease]
	    , dim_detail_plot_details.type_of_scheme AS [Type of Scheme]
		, dim_detail_plot_details.[pscompletion_date] AS [Completion Date]
		, dim_detail_plot_details.[exchange_date_combined] AS [Exchange Date Combined]
		, dim_client_involvement.purchasersols_name  AS [Purchaser solicitors]
		, dim_detail_plot_details.[all_info_received] AS [Information Received]
		, dim_detail_plot_details.[reason_for_info_not_received] AS [Reason for Info not Received]
		, dim_detail_plot_details.[date_info_received] AS [Date Info Received]
		, dim_detail_plot_details.[contractual_docs_sent_to_p_sols] AS [Contractual Documents Sent to P_Sols]
		, dim_detail_plot_details.[p_sols_ack_receipt_of_docs] AS [P Sols Acknowledge Receipt of Documents]
		, dim_detail_plot_details.[reservation_signed] AS [Reservation Signed]
		, dim_detail_plot_details.[psexpiry_of_reservation_period] AS [Expiry of Reservation Period]

		--advice details
		, dim_detail_advice.client AS [Client]
        , dim_detail_advice.issue AS [Issue]
        , REPLACE(dim_detail_advice.job_title_of_caller_tgipe,'Do not use - ','') AS [Job Title of Caller]
        , REPLACE(dim_detail_advice.job_title_of_employee,'Do not use - ','') AS [Job Title of Employee]
		, dim_detail_advice.job_title_of_caller_pizza_hut [Job Title of Caller PH]
        , dim_detail_advice.name_of_caller AS [Name of Caller]
        , dim_detail_advice.name_of_employee AS [Name of Employee]
        , dim_detail_advice.risk AS [Risk]

        , dim_detail_advice.secondary_issue AS [Secondary Issue]
		, dim_detail_advice.region AS [Region]
        , REPLACE(dim_detail_advice.[site],'Do not use - ','') AS [Site]
        , dim_detail_advice.[status] AS [Status]
        , dim_detail_advice.employment_start_date  AS [Employment Start Date]
        , REPLACE(dim_detail_advice.[tgif_classification],'Do not use - ','') AS [TGIF Classifications]
        , dim_detail_advice.[outcome] AS [Advice Outcome] 
        , dim_detail_advice.issue_hr AS [Issue HR]
        , dim_detail_advice.job_title_of_caller_hr  AS [Job Title of Caller HR]
        , dim_detail_advice.secondary_issue_hr AS [Secondary Issue HR]
        , dim_detail_advice.site_hr AS [Site HR]
        , dim_detail_advice.status_hr AS [Status HR]
		, [TGIPostcodes].Branch AS [TGIF Branch]
		, [TGIPostcodes].Postcode AS [TGIF Postcode]
		, [TGIPostcodes].Region AS [TGIF Region]
		, [TGIPostcodes].Team AS [TGIF Team]
		, CAST(CAST([TGIF_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [TGIF Postcode Latitude]
		, CAST(CAST([TGIF_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [TGIF Postcode Longitude]
		, dim_detail_advice.[emph_primary_issue] AS [Emp Primary Issue]
		, dim_detail_advice.[emph_secondary_issue] AS [Emp Secondary Issue]
		, dim_detail_advice.[workplace_postcode] AS [Workplace Postcode]
		, dim_detail_advice.[category_of_advice] AS [Category of Advice]
		, dim_detail_advice.[policy_issue] AS [Policy Issue]
		, dim_detail_advice.[diversity_issue] AS [Diversity Issue]
		, dim_detail_advice.[summary_of_advice] AS [Summary of Advice]
		, dim_detail_advice.[knowledge_gap] AS [Knowledge Gap]

		--DVPO
		, dim_detail_advice.dvpo_victim_postcode AS [DVPO Victim Postcode]
		, CAST(CAST([DVPO_Victim_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [DVPO Victim Postcode Latitude]
		, CAST(CAST([DVPO_Victim_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [DVPO Victim Postcode Longitude]
		, dim_detail_advice.dvpo_number_of_children AS [DVPO Number of Children]
		, dim_detail_advice.dvpo_division AS [DVPO Division]
		, dim_detail_advice.dvpo_granted AS [DVPO Granted?]
		, dim_detail_advice.dvpo_contested AS [DVPO Contested?]
		, dim_detail_advice.dvpo_breached AS [DVPO Breached?]
		, dim_detail_advice.dvpo_is_first_breach AS [DVPO is First Breach?]
		, dim_detail_advice.dvpo_breach_admitted AS [DVPO Breach Admitted]
		, dim_detail_advice.dvpo_breach_proved AS [DVPO Breach Proved?]
		, dim_detail_advice.dvpo_breach_sentence AS [DVPO Breach Sentence]
		, dim_detail_advice.dvpo_breach_sentence_length AS [DVPO Breach Sentence Length]
		, dim_detail_advice.dvpo_legal_costs_sought AS [DVPO Legal Costs Sought?]
		, dim_detail_advice.dvpo_court_fee_awarded AS [DVPO Court Fee Awarded?]
		, dim_detail_advice.dvpo_own_fees_awarded AS [DVPO Own Fees Awarded?]

		--employment
		, dim_detail_core_details.[emp_litigatednonlitigated] AS [Emp Litigated/Non-Litigated]
		, dim_detail_practice_area.[emp_outcome] AS [Outcome - Employment]
		, dim_detail_practice_area.[emp_present_position] AS [Present Position - Employment]
		, dim_detail_practice_area.[emp_stage_of_outcome] AS [Stage of Outcome]
		, dim_detail_client.whitbread_brand AS [Whitbread Brand]
		, fact_finance_summary.commercial_costs_estimate AS [Current Costs Estimate]
		, fact_detail_reserve_detail.[potential_compensation] AS [Potential Compensation/Pension Loss]
		, fact_detail_paid_detail.[actual_compensation] AS [Actual Compensation]
		, fact_detail_paid_detail.admin_charges_total AS [Admin Charges Total]

		, dim_detail_property.[group_company] AS [Group Company]
		, dim_detail_property.[city] AS [City]
		, dim_detail_property.[bruntwood_case_status] AS [Bruntwood Case Status]

		--disease
		, CASE WHEN fact_finance_summary.[damages_paid] IS NULL  AND fact_detail_paid_detail.[general_damages_paid] IS NULL AND fact_detail_paid_detail.[special_damages_paid] IS NULL AND fact_detail_paid_detail.[cru_paid] IS NULL THEN NULL
			ELSE  (CASE WHEN fact_finance_summary.[damages_paid] IS NULL THEN (ISNULL(fact_detail_paid_detail.[general_damages_paid],0)+ISNULL(fact_detail_paid_detail.[special_damages_paid],0)+ ISNULL(fact_detail_paid_detail.[cru_paid],0)) ELSE fact_finance_summary.[damages_paid] END) END AS [Damages Paid by Client - Disease]
			
		, CASE WHEN fact_finance_summary.[claimants_costs_paid] IS NULL AND fact_detail_paid_detail.[claimants_costs] IS NULL THEN NULL ELSE COALESCE(fact_finance_summary.[claimants_costs_paid],fact_detail_paid_detail.[claimants_costs]) END AS [Claimant's Costs Paid by Client - Disease]
			
		, CASE WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL  AND fact_detail_paid_detail.[total_nil_settlements] IS NULL THEN NULL
				ELSE (CASE WHEN fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] IS NULL THEN (CASE WHEN ISNULL(dim_detail_claim.[our_proportion_percent_of_damages],0)=0 THEN NULL ELSE (ISNULL(fact_detail_paid_detail.[general_damages_paid],0)+ISNULL(fact_detail_paid_detail.[special_damages_paid],0)+ ISNULL(fact_detail_paid_detail.[cru_paid],0))/dim_detail_claim.[our_proportion_percent_of_damages] END) 
				ELSE fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] END) END AS [Damages Paid (all parties) - Disease]
		
		, CASE WHEN fact_finance_summary.[claimants_total_costs_paid_by_all_parties] IS NULL AND fact_detail_paid_detail.[claimants_costs] IS NULL THEN NULL
				ELSE (CASE WHEN fact_finance_summary.[claimants_total_costs_paid_by_all_parties] IS NULL THEN 
			(CASE WHEN ISNULL(fact_detail_paid_detail.[our_proportion_costs ],0)=0 THEN NULL ELSE ISNULL(fact_detail_paid_detail.[claimants_costs],0)/fact_detail_paid_detail.[our_proportion_costs ] END) 
				ELSE fact_finance_summary.[claimants_total_costs_paid_by_all_parties] END)  END AS [Claimant's Total Costs Paid (all parties) - Disease]
		
		, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed'
				WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL AND (dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL) THEN 'Damages Only Settled'
				WHEN dim_detail_outcome.[date_claim_concluded] IS NULL AND dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL THEN 'Live'
				ELSE NULL END AS [Status - Disease]
		, COALESCE(dim_detail_core_details.[track],dim_detail_core_details.[zurich_track]) AS [Track - Disease]

		, GETDATE() AS dss_update_time
		
		
		--Health 
		,CASE WHEN ISNULL(dim_detail_client.financial_risk,'') LIKE 'High%' OR ISNULL(dim_detail_client.reputational_risk,'') LIKE 'High%' OR ISNULL(dim_detail_client.case_prospects,'') LIKE 'High%' THEN 'High'
				WHEN ISNULL(dim_detail_client.financial_risk,'') LIKE 'Medium%' OR ISNULL(dim_detail_client.reputational_risk,'') LIKE 'Medium%' OR ISNULL(dim_detail_client.case_prospects,'') LIKE 'Medium%' THEN 'Medium'
				WHEN ISNULL(dim_detail_client.financial_risk,'') LIKE 'Low%' OR ISNULL(dim_detail_client.reputational_risk,'') LIKE 'Low%' OR ISNULL(dim_detail_client.case_prospects,'') LIKE 'Low%' THEN 'Low'
				ELSE NULL END [Risk category health]
		, dim_detail_health.[nhs_sabre_date_claimants_costs_paid] AS [NHSR Date costs Paid]
	
		, dim_detail_client.financial_risk [Financial Risk ]
		, dim_detail_client.reputational_risk [Repitational Risk]
		, dim_detail_client.case_prospects [Case Prospects ]  
		, dim_detail_core_details.emp_litigatednonlitigated [emp_litigatednonlitigated]

		
		--Employment
		, dim_detail_advice.[outcome_combined] AS [Outcome - Pizza Express]
		, dim_detail_client.[whitbread_employee_business_line] AS [Whitbread Employee Business Line]
		, dim_detail_client.pizza_express_strategy AS [Pizza Express Strategy]
		, dim_detail_client.[pizza_express_region] AS [Pizza Express Region]
		, fact_detail_paid_detail.[value_of_instruction] AS [Value of Instruction]
		, dim_detail_client.whitbread_managed_business_rom AS [Whitbread Managed Business ROM]
		, dim_detail_client.[whitbread_employee_business_line] AS [Whitbread Employee Business Line_orig]
		, dim_detail_client.case_type_classification AS [Client Case Classification]
		, dim_detail_claim.[capita_stage_of_settlement] AS [Capita Stage of Settlement]
		, COALESCE(dim_detail_claim.[claimants_solicitors_firm_name ], dim_claimant_thirdparty_involvement.claimantsols_name) AS [Claimant's Solicitors Firm]
		,dim_detail_outcome.claim_status [Claim Concluded Status]
		,dim_site_address.area [Area]
		-- LD Added below tribunal name
		,dim_court_involvement.[tribunal_name] AS [Tribunal Name]

	--Police
		, dim_detail_core_details.met_police_work_designation
		, dim_detail_core_details.police_offence_giving_rise_to_claim
		, dim_detail_claim.borough AS [Borough]
		, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
		, fact_detail_paid_detail.[dvpo_breach_fine_amount] AS [DVPO - Amount of Fine]
		, fact_detail_recovery_detail.[dvpo_court_fee_awarded_amount] AS [DVPO - Amount of Court Fees Awarded]
		
		--Severn Trent
		, dim_detail_claim.stw_reason_for_litigation AS [STW Reason for Litigation]
		, dim_detail_claim.stw_waste_or_water AS [STW Water or Waste]
		, dim_detail_claim.stw_status AS [STW Status]
		, CASE WHEN dim_detail_claim.class_of_business_stw ='Motor' THEN 'Motor' ELSE dim_detail_claim.stw_work_type END AS [STW Report Area]
		, dim_detail_claim.stw_work_type AS [STW Worktype]
		, dim_detail_claim.[class_of_business_stw] AS [STW Class of Business]
		, dim_detail_critical_mi.[date_closed] AS [Critical MI Date Closed]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_detail_core_details.date_instructions_received, dim_detail_core_details.[date_initial_report_sent]) AS [Working Days from Instruction Received to Initial Report]
		, dim_detail_critical_mi.[claim_status] AS [Claim Status]
		, dim_detail_critical_mi.[policy_type] AS [Policy Type]
		, dim_detail_claim.[stw_status_on_instruction] AS [STW Status On Instruction]
		, CASE WHEN dim_detail_client.[effect_description] IS NOT NULL THEN dim_detail_client.[effect_description]  
				 WHEN dim_detail_client.[effect_description] IS NULL THEN dim_detail_client.[effect_description_additional]
				 WHEN dim_detail_client.[effect_description_additional] IS NULL AND dim_detail_client.[effect_description_additional] IS NULL THEN 'Unknown' END AS [Effect Description]
		, CASE WHEN dim_detail_claim.stw_report='Litigated and Recoveries' THEN fact_finance_summary.damages_paid
			ELSE ISNULL(fact_detail_paid_detail.damages_paid_stw,0)+ISNULL(fact_detail_paid_detail.damages_paid_lyra,0)
			END AS [STW Total Damages Paid]
		, fact_detail_paid_detail.damages_paid_lyra AS [STW Damages Paid (Lyra only)]
		--, CASE WHEN fact_detail_paid_detail.tp_costs_paid_stw>0 THEN fact_detail_paid_detail.tp_costs_paid_stw ELSE fact_finance_summary.claimants_costs_paid END AS [STW TP Costs Paid]
		, CASE WHEN dim_detail_claim.stw_report='Litigated and Recoveries' THEN fact_finance_summary.claimants_costs_paid
				ELSE fact_detail_paid_detail.tp_costs_paid_stw 
				END AS [STW TP Costs Paid]
		, COALESCE(fact_detail_paid_detail.defence_costs_paid_stw,fact_finance_summary.[defence_costs_billed]) AS [STW Defence Costs Paid]
		, COALESCE(fact_detail_reserve_detail.[el_stw_damages_reserve],fact_detail_reserve_detail.[mo_stw_damages_reserve], fact_detail_reserve_detail.[pl_stw_damages_reserve], fact_finance_summary.damages_reserve) AS [STW Damages Reserve]
		, COALESCE(fact_detail_reserve_detail.[el_stw_tp_costs_reserve],fact_detail_reserve_detail.[mo_stw_tp_costs_reserve],fact_detail_reserve_detail.[pl_stw_tp_costs_reserve], fact_finance_summary.tp_costs_reserve) AS [STW TP Costs Reserve]
		, COALESCE(fact_detail_reserve_detail.[el_stw_own_costs_reserve],fact_detail_reserve_detail.[mo_stw_own_costs_reserve], fact_detail_reserve_detail.[pl_stw_own_costs_reserve], fact_finance_summary.defence_costs_reserve) AS [STW Defence Costs Reserve]
		, dim_detail_client.stw_date_of_acknowledgment AS [STW Date of Acknowledgment]
		, dim_detail_client.stw_date_of_initial_contact AS [STW Date of Initial Contact]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_detail_core_details.date_instructions_received,dim_detail_client.stw_date_of_initial_contact) AS [Working Days to Initial Contact]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_detail_core_details.date_instructions_received,dim_detail_client.stw_date_of_acknowledgment) AS [Working Days to Acknowledge]
		, ISNULL(fact_detail_reserve_detail.[el_insurer_damages_reserve], 0)
       + ISNULL(fact_detail_reserve_detail.[el_insurer_tp_costs_reserve], 0)
       + ISNULL(fact_detail_reserve_detail.[el_insurer_own_costs_reserve], 0)
       + ISNULL(fact_detail_reserve_detail.[mo_insurer_damages_reserve], 0)
       + ISNULL(fact_detail_reserve_detail.[mo_insurer_tp_costs_reserve], 0)
       + ISNULL(fact_detail_reserve_detail.[mo_insurer_own_costs_reserve], 0) AS [Outstanding Reserve Lyra]
	    , dim_detail_claim.stw_report AS [STW Report]
		, CASE WHEN dim_detail_claim.stw_report IN ('Both','Lyra', 'Litigated and Recoveries') THEN 1
				WHEN dim_client.client_group_code = '00000068'
					AND dim_client.client_code = '00513126'
					AND policy_type IN ( 'Employers Liability', 'Motor') THEN 1
				WHEN (dim_client.client_group_code = '00000068'
					AND dim_client.client_code = '00257248'
					AND dim_matter_header_current.date_opened_case_management >= '2019-02-01'
					AND dim_detail_claim.[stw_status_on_instruction] = 'Pre-Lit'
					AND policy_type IN ( 'Employers Liability', 'Motor' )) THEN 1
				WHEN dim_client.client_code IN  ('00257248','R00016') AND stw_status_on_instruction IS NULL  THEN 1
				WHEN dim_client.client_code IN  ('00257248','R00016') AND stw_report = 'Both' THEN 1
				WHEN dim_client.client_code IN  ('00257248','R00016') AND  stw_report = 'Litigated and Recoveries' THEN 1
				--WHEN (ISNULL(dim_detail_critical_mi.claim_status,'') IN ('Open','Re-opened','Cancelled','Closed',NULL) OR claim_status IS NULL) ) THEN 1
				WHEN dim_client.[client_code]='R00016' AND  dim_matter_header_current.[matter_number] = '00102745' THEN 1
				ELSE 0 END AS [STW Report Filter]
			, stw_recoveries_instructed_by AS [STW Recoveries Instructed By]
			, stw_initial_checklist_result AS [STW Initial Checklist Result]
			, fact_detail_recovery_detail.amount_recovery_sought AS [Amount Recovery Sought]




		--AIG
		, dim_detail_core_details.[aig_current_fee_scale] AS [Current Fee Scale]
		, dim_detail_core_details.[aig_instructing_office] AS [Instructing Office]
		, dim_detail_claim.[dst_claimant_solicitor_firm] AS [DST Claimant Solicitor Firm]
		, dim_detail_claim.[dst_insured_client_name] AS [DST Insured Client Name]
		, dim_detail_core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler] AS [Date Initial Acknowledgment to Claims Handler]
		, [dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_detail_core_details.date_instructions_received, dim_detail_core_details.[aig_grp_date_initial_acknowledgement_to_claims_handler]) AS [Working Days from Instruction Received to Initial Acknowledgment to Claims Handler]

		--Tesco
		, dim_detail_client.[tesco_reason_for_instruction] AS [Tesco Claim Type]
		, dim_detail_client.[tesco_track] AS [Tesco Track]
		, dim_detail_fraud.[fraud_current_fraud_type] AS [Fraud Type]

		, dim_detail_claim.ageas_office AS [Tesco Office]
		, dim_detail_core_details.grpageas_case_handler AS [Tesco Handler]
		, dim_detail_client.settlement_stage AS [Settlement Stage]
		, dim_detail_core_details.grpageas_claim_category AS [Claim Category]
		, dim_detail_claim.ageas_instruction_type AS [Ageas Instruction Type]
		, dim_detail_claim.[name_of_instructing_insurer] AS [Name of Instructing Insurer]
		, dim_detail_core_details.[grpageas_motor_moj_stage] AS [MOJ Stage]

				--Recovery 
		, fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution] AS [Recovery Claimants Damages Third Party]
        , fact_finance_summary.[recovery_defence_costs_via_third_party_contribution] AS [Recovery Defence Cost Third Party]
        , fact_finance_summary.[recovery_defence_costs_from_claimant] AS [Recovery Defence Costs from Claimant]
		, CASE WHEN fact_finance_summary.total_recovery>0 THEN  fact_finance_summary.total_recovery ELSE 
			ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0) END AS [Total Recovered]
		, dim_detail_claim.date_recovery_concluded AS [Date Recovery Concluded]
		, dim_detail_claim.recovery_notes AS [Recovery Stage]

		, fact_finance_summary.[special_damages_miscellaneous_paid] AS [Special Damages]
		, fact_finance_summary.[personal_injury_paid] AS [General Damages]

		--Involvement 
		, dim_experts_involvement.medicalexpert_name AS [Medical Expert Name] /*1.1*/
		, dim_experts_involvement.claimantmedexp_name AS [Claiment Medical Expert Name]

		, dim_detail_claim.number_of_claimants AS [Number of Claimants]
		, dim_detail_outcome.costs_outcome AS [Costs Outcome]
		, dim_detail_core_details.claimants_date_of_birth AS [Claimant's Date of Birth]
		
		,[Revenue 2016/2017]
		,[Revenue 2017/2018]
		,[Revenue 2018/2019]
		,[Revenue 2019/2020]
		,[Hours Billed 2016/2017]
		,[Hours Billed 2017/2018]
		,[Hours Billed 2018/2019]
		,[Hours Billed 2019/2020]
		,[Hours Posted 2016/2017]
		,[Hours Posted 2017/2018]
		,[Hours Posted 2018/2019]
		,[Hours Posted 2019/2020]
		,PartnerHours
        ,NonPartnerHours
        ,[Partner/ConsultantTime]
		,AssociateHours
		,[Solicitor/LegalExecTimeHours]
		,ParalegalHours
		,TraineeHours
        ,OtherHours
		,dim_detail_core_details.[covid_contested_application_made]
,dim_detail_core_details.[covid_counsel_unavailability]
,dim_detail_core_details.[covid_directions_extended]
,dim_detail_core_details.[covid_disclosure_delay_claimant]
,dim_detail_core_details.[covid_disclosure_delay_defendant]
,dim_detail_core_details.[covid_disclosure_delay_obtaining_docs]
,dim_detail_core_details.[covid_expert_unavailability_claimant_third_party]
,dim_detail_core_details.[covid_expert_unavailability_defendant]
,dim_detail_core_details.[covid_hearing_vacated]
,dim_detail_core_details.[covid_limitation_extension_or_moratorium]
,dim_detail_core_details.[covid_medical_exam_postponed]
,dim_detail_core_details.[covid_other]
,dim_detail_core_details.[covid_witness_unavailability_defendant]
,dim_detail_core_details.[covid_witness_unavailablility_claimant]
,dim_detail_core_details.[covid_reason_code]
,dim_detail_core_details.[covid_reason_desc]

--Large Loss
,dim_detail_core_details.[will_total_gross_reserve_on_the_claim_exceed_500000] AS [Will total gross damages reserve exceed £350,000?]

INTO dbo.Vis_GeneralData



FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
--JL 08-12-2020  - This has been moved temporarily untill fact_dimention_main has been fixed. Added join not useing the key
--LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key=fact_dimension_main.dim_fed_hierarchy_history_key --AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND getdate() BETWEEN dss_start_date AND dss_end_date 
--v 1.2 added...
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.fed_code = red_dw.dbo.dim_matter_header_current.fee_earner_code
              AND red_dw.dbo.dim_fed_hierarchy_history.dss_current_flag = 'Y'
              AND GETDATE()
              BETWEEN dss_start_date AND dss_end_date
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON red_dw.dbo.dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.[dbo].[dim_instruction_type] ON [dim_instruction_type].[dim_instruction_type_key]=dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_property ON fact_detail_property.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_plot_details ON dim_detail_plot_details.dim_detail_plot_detail_key = fact_dimension_main.dim_detail_plot_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN Visualisation.[dbo].[TGIPostcodes] ON RTRIM([TGIPostcodes].Branch)=REPLACE(dim_detail_advice.[site],'Do not use - ','') COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key=fact_dimension_main.dim_detail_critical_mi_key 
LEFT OUTER JOIN red_dw.dbo.dim_site_address ON dim_site_address.client_code=dim_detail_client.client_code AND dim_site_address.matter_number=dim_detail_client.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key=fact_dimension_main.dim_detail_fraud_key
LEFT OUTER JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_experts_involvement ON dim_experts_involvement.dim_experts_involvemen_key = fact_dimension_main.dim_experts_involvemen_key /*1.1*/
LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
				  ,SUM(minutes_recorded)/60 AS [HoursRecorded]
				  FROM red_dw.dbo.fact_chargeable_time_activity
				  INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
				  WHERE  minutes_recorded<>0
				  AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE())  OR dim_matter_header_current.date_closed_case_management IS NULL)
				  GROUP BY client_code,matter_number,fact_chargeable_time_activity.master_fact_key
		) AS TimeRecorded ON TimeRecorded.master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key

  
		LEFT OUTER JOIN (		SELECT    client_code
                                          , matter_number
										  , master_fact_key
										  , ISNULL(SUM(PartnerTime),0)/60 AS PartnerHours
                                          , ISNULL(SUM(NonPartnerTime),0)/60 AS NonPartnerHours
                                          , ISNULL(SUM([Partner/ConsultantTime]),0)/60 AS [Partner/ConsultantTime]
										  , ISNULL(SUM(AssociateTime),0)/60 AS AssociateHours
										  , ISNULL(SUM([Solicitor/LegalExecTime]),0)/60 AS [Solicitor/LegalExecTimeHours]
										  , ISNULL(SUM(ParalegalTime),0)/60 AS ParalegalHours
										  , ISNULL(SUM(TraineeTime),0)/60 AS TraineeHours
                                          , ISNULL(SUM(OtherTime),0)/60 AS OtherHours
                                  FROM      ( SELECT    client_code 
                                                        , matter_number 
														, master_fact_key

														, ( CASE WHEN Partners.jobtitle LIKE '%Partner%' THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS PartnerTime 
                                                        , ( CASE WHEN Partners.jobtitle NOT LIKE '%Partner%' OR jobtitle IS NULL THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS NonPartnerTime
                                                        , ( CASE WHEN Partners.jobtitle LIKE '%Partner%' OR Partners.jobtitle LIKE '%Consultant%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS  [Partner/ConsultantTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Associate%' THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS AssociateTime
														, ( CASE WHEN Partners.jobtitle LIKE 'Solicitor%' OR Partners.jobtitle LIKE '%Legal Executive%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [Solicitor/LegalExecTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Paralegal%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [ParalegalTime]
														, ( CASE WHEN Partners.jobtitle LIKE '%Trainee Solicitor%'  THEN SUM(minutes_recorded)
                                                              ELSE 0 END ) AS [TraineeTime]

                                                        , ( CASE WHEN Partners.jobtitle NOT LIKE '%Partner%' 
														AND Partners.jobtitle NOT LIKE '%Consultant%' 
														AND Partners.jobtitle NOT LIKE '%Associate%' 
														AND Partners.jobtitle NOT LIKE '%Solicitor%'
														AND Partners.jobtitle NOT LIKE '%Legal Executive%' 
														AND Partners.jobtitle NOT LIKE '%Paralegal%' 
														AND Partners.jobtitle NOT LIKE '%Trainee%' 
														OR  jobtitle IS NULL THEN SUM(minutes_recorded)
                                                              ELSE 0 END )  AS OtherTime
                                              FROM      red_dw.dbo.fact_chargeable_time_activity
                                              LEFT OUTER JOIN ( SELECT DISTINCT dim_fed_hierarchy_history_key
																			 , jobtitle
																FROM red_dw.dbo.dim_fed_hierarchy_history 
														) AS Partners ON Partners.dim_fed_hierarchy_history_key = fact_chargeable_time_activity.dim_fed_hierarchy_history_key
											  LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key        
                                              WHERE     minutes_recorded<>0
														AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
                                              GROUP BY  client_code, matter_number, master_fact_key, Partners.jobtitle
                                            ) AS AllTime
                                  GROUP BY  AllTime.client_code, AllTime.matter_number, AllTime.master_fact_key)  AS [Partner/NonPartnerHoursRecorded] ON [Partner/NonPartnerHoursRecorded].master_fact_key=red_dw.dbo.fact_dimension_main.master_fact_key

LEFT OUTER JOIN (SELECT fact_dimension_main.master_fact_key, 
						dim_client.contact_salutation [claimant1_contact_salutation],
						dim_client.addresse [claimant1_addresse],
						dim_client.address_line_1 [claimant1_address_line_1],
						dim_client.address_line_2 [claimant1_address_line_2],
						dim_client.address_line_3 [claimant1_address_line_3],
						dim_client.address_line_4 [claimant1_address_line_4],
						dim_client.postcode [claimant1_postcode]
						FROM red_dw.dbo.dim_claimant_thirdparty_involvement WITH (NOLOCK)
						INNER JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK) ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
						INNER JOIN red_dw.dbo.dim_involvement_full WITH (NOLOCK) ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
						INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK) ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
						WHERE dim_client.dim_client_key != 0) AS [Claimant Address] ON [Claimant Address].master_fact_key=fact_dimension_main.master_fact_key

LEFT OUTER JOIN red_dw.dbo.Doogal AS [Property_Postcode] ON [Property_Postcode].Postcode=dim_detail_property.postcode
LEFT OUTER JOIN red_dw.dbo.Doogal AS [Claimant_Postcode] ON [Claimant_Postcode].Postcode=[Claimant Address].[claimant1_postcode]
LEFT OUTER JOIN red_dw.dbo.Doogal AS [Incident_Postcode] ON [Incident_Postcode].Postcode=dim_detail_core_details.incident_location_postcode
LEFT OUTER JOIN red_dw.dbo.Doogal AS [Insured_Department_Depot_Postcode] ON [Insured_Department_Depot_Postcode].Postcode=dim_detail_core_details.insured_departmentdepot_postcode
LEFT OUTER JOIN red_dw.dbo.Doogal AS [TGIF_Postcode] ON [TGIF_Postcode].Postcode=LTRIM([TGIPostcodes].Postcode) COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.Doogal AS [DVPO_Victim_Postcode] ON [DVPO_Victim_Postcode].Postcode=dim_detail_advice.dvpo_victim_postcode
LEFT OUTER JOIN red_dw.dbo.Doogal AS [CHO_Postcode] ON [CHO_Postcode].Postcode=dim_detail_hire_details.[cho_postcode]
LEFT OUTER JOIN red_dw.dbo.Doogal AS [TP_Postcode] ON [TP_Postcode].Postcode=[Claimant Address].[claimant1_postcode]
-- 20180921 LD Added
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health ON dim_detail_health.dim_detail_health_key=fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_file_notes ON dim_file_notes.dim_file_notes_key = fact_dimension_main.dim_file_notes_key 
AND dim_file_notes.client_code IN ('00787558','00787559','00787560','00787561')

LEFT OUTER JOIN (SELECT fileID
					, tskDesc
					, Created AS [DateTaskCreated]
				 FROM MS_Prod.dbo.dbTasks
				WHERE tskDesc='Is the lease agreed'
				AND fileID IN (SELECT ms_fileid FROM red_dw.dbo.dim_matter_header_current
					WHERE client_code IN ('00787558','00787559','00787560','00787561'))) AS [LeaseAgreedTasks] ON [LeaseAgreedTasks].fileID=dim_matter_header_current.ms_fileid

--45432
LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
		,SUM(minutes_recorded)/60 AS [Hours Posted 2016/2017]
FROM red_dw.dbo.fact_chargeable_time_activity
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date_key=dim_transaction_date_key
WHERE calendar_date BETWEEN '2016-05-01' AND '2017-04-30'
AND minutes_recorded<>0
GROUP BY master_fact_key) AS [HoursPosted2016/2017]
ON [HoursPosted2016/2017].master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
		,SUM(minutes_recorded)/60 AS [Hours Posted 2017/2018]
FROM red_dw.dbo.fact_chargeable_time_activity
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date_key=dim_transaction_date_key
WHERE calendar_date BETWEEN '2017-05-01' AND '2018-04-30'
AND minutes_recorded<>0
GROUP BY master_fact_key) AS [HoursPosted2017/2018]
ON [HoursPosted2017/2018].master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
		,SUM(minutes_recorded)/60 AS [Hours Posted 2018/2019]
FROM red_dw.dbo.fact_chargeable_time_activity
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date_key=dim_transaction_date_key
WHERE calendar_date BETWEEN '2018-05-01' AND '2019-04-30'
AND minutes_recorded<>0
GROUP BY master_fact_key) AS [HoursPosted2018/2019]
ON [HoursPosted2018/2019].master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN (SELECT fact_chargeable_time_activity.master_fact_key
		,SUM(minutes_recorded)/60 AS [Hours Posted 2019/2020]
FROM red_dw.dbo.fact_chargeable_time_activity
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date_key=dim_transaction_date_key
WHERE calendar_date BETWEEN '2019-05-01' AND '2020-04-30'
AND minutes_recorded<>0
GROUP BY master_fact_key) AS [HoursPosted2019/2020]
ON [HoursPosted2019/2020].master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2016/2017]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2016/2017]
,SUM(    fact_bill_detail_summary.disbursements_billed_exc_vat) AS [Disbursements Billed 2016/2017]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
  INNER JOIN red_dw.dbo.fact_bill_detail_summary ON fact_bill_detail_summary.master_fact_key = fact_bill_detail.master_fact_key
 WHERE dim_bill_date.bill_date BETWEEN '2016-05-01' AND '2017-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2016
 ON dim_matter_header_current.client_code=Revenue2016.client_code
AND dim_matter_header_current.matter_number=Revenue2016.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2017/2018]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2017/2018]
,SUM(    fact_bill_detail_summary.disbursements_billed_exc_vat) AS [Disbursements Billed 2017/2018]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
  INNER JOIN red_dw.dbo.fact_bill_detail_summary ON fact_bill_detail_summary.master_fact_key = fact_bill_detail.master_fact_key
 WHERE dim_bill_date.bill_date BETWEEN '2017-05-01' AND '2018-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2017
 ON dim_matter_header_current.client_code=Revenue2017.client_code
AND dim_matter_header_current.matter_number=Revenue2017.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2018/2019]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2018/2019]
,SUM(    fact_bill_detail_summary.disbursements_billed_exc_vat) AS [Disbursements Billed 2018/2019]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
  INNER JOIN red_dw.dbo.fact_bill_detail_summary ON fact_bill_detail_summary.master_fact_key = fact_bill_detail.master_fact_key
 WHERE dim_bill_date.bill_date BETWEEN '2018-05-01' AND '2019-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2018
 ON dim_matter_header_current.client_code=Revenue2018.client_code
AND dim_matter_header_current.matter_number=Revenue2018.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2019/2020]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2019/2020]
,SUM(    fact_bill_detail_summary.disbursements_billed_exc_vat) AS [Disbursements Billed 2019/2020]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
  INNER JOIN red_dw.dbo.fact_bill_detail_summary ON fact_bill_detail_summary.master_fact_key = fact_bill_detail.master_fact_key
 WHERE dim_bill_date.bill_date BETWEEN '2019-05-01' AND '2020-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2019
 ON dim_matter_header_current.client_code=Revenue2019.client_code
AND dim_matter_header_current.matter_number=Revenue2019.matter_number



WHERE 
LOWER(ISNULL(dim_detail_outcome.outcome_of_case,'')) <> 'exclude from reports'
--AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND dim_matter_header_current.matter_number <>'ML'
AND dim_client.client_code  NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= DATEADD(YEAR,-3,GETDATE()) OR dim_matter_header_current.date_closed_case_management IS NULL)


END


GO
