SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Property Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[PropertyDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
 RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_matter_header_current.[matter_description] AS [Matter Description]
		, dim_client_involvement.[purchaser_name] AS [Purchaser Name]
		, dim_detail_client.cumbria_faculty AS [Cumbria Faculty]
		, dim_detail_client.cumbria_location AS [Cumbria Location]
		, dim_detail_client.cumbria_services AS [Cumbria Services]
		, dim_detail_plot_details.pscompletion_date AS [Completion Date]
		, dim_detail_plot_details.[condition_date] AS [Condition Date]
		, dim_detail_plot_details.[reservation_received] AS [Reservation Received]
		, dim_detail_plot_details.[psexpiry_of_reservation_period] AS [Expiry of Reservation Period]
		, dim_detail_plot_details.[type_of_lease] AS [Type of Lease]
		, dim_detail_plot_details.cumbria_lot AS [Cumbria Lot]
		, dim_detail_plot_details.[contracts_exchanged] AS [Contracts Exchanged]
		, dim_detail_plot_details.[car_parking_lease] AS [Car Parking Lease]
		, dim_detail_plot_details.[psplot_number] AS [Plot Number]
		, dim_detail_plot_details.[agency] AS Agency
		, dim_detail_plot_details.[purchasers_full_address] AS [Purchasers Full Address]
		, dim_detail_plot_details.[purchasers_2_full_address] AS [Purchasers 2 Full Address]
		, dim_detail_plot_details.[purchasers_3_full_address] AS [Purchasers 3 Full Address]
		, dim_detail_plot_details.[purchasers_4_full_address] AS [Purchasers 4 Full Address]
		, dim_detail_plot_details.[leasehold_freehold] AS [Leasehold Freehold]
		, dim_detail_plot_details.[david_wilson_homes_limited_developments] AS [David Wilson Homes Limited Developments]
		, dim_detail_plot_details.[barratt_manchester_developments] AS [Barratt Manchester Developments]
		, dim_detail_plot_details.[thomas_jones_sons_limited_development] AS [Thomas Jones Sons Limited Development]
		, dim_detail_plot_details.[persimmon_homes_limited_development] AS [Persimmon Homes Limited Development]
		, dim_detail_plot_details.[purelake_new_homes_limited] AS [Purelake New Homes Limited]
		, dim_detail_plot_details.[greenfields_place_development_company_limited_developments] AS [Greenfields Place Development Company Limited Developments]
		, dim_detail_plot_details.[address_of_part_exchange] AS [Address of Part Exchange]
		, dim_detail_plot_details.[type_of_scheme] AS [Type of Scheme]
		, dim_detail_plot_details.[type_of_transfer] AS [Type of Transfer]
		, dim_detail_plot_details.[have_we_received_atp] AS [Received ATP]
		, dim_detail_plot_details.[anticipated_legal_completion_date] AS [Anticipated Legal Completion Date]
		, dim_detail_property.[exchange_date] AS [Exchange Date]
		, dim_detail_plot_details.[lender] AS Lender
		, dim_detail_plot_details.[reservation_signed] AS [Reservation Signed]
		, dim_detail_plot_details.[all_info_received] AS [information Received]
		, dim_detail_plot_details.[reason_for_info_not_received] AS [Reason for Info not Received]
		, dim_detail_plot_details.[contractual_docs_sent_to_p_sols] AS [Contractual Documents Sent to P_Sols]
		, dim_detail_plot_details.[p_sols_ack_receipt_of_docs] AS [P Sols Acknowledge Receipt of Documents]
		, dim_detail_plot_details.[date_of_acknowledgement] AS [Date of Acknowledgement]
		, dim_detail_plot_details.[p_sols_received_formal_instruction] AS [P Sols Received Formal Instruction]
		, dim_detail_plot_details.[formal_instruction_received] AS [Formal Instruction Received]
		, dim_detail_plot_details.[p_sols_received_search_fees_money] AS [P Sols Received Search Fees Money]
		, dim_detail_plot_details.[search_fee_money_received] AS [Search Fee Money Received]
		, dim_detail_plot_details.[p_sols_applied_for_searches] AS [P Sols Applied for Searches]
		, dim_detail_plot_details.[searches_applied] AS [Searches Applied]
		, dim_detail_plot_details.[date_of_search_results] AS [Date of Search Results]
		, dim_detail_plot_details.[p_sols_confirmed_anticipated_date_of_mortgage_offer] AS [P Sols Confirmed Anticipated Date of Mortgage Offer]
		, dim_detail_plot_details.[anticipated_date_confirmed] AS [Anticipated Date Confirmed]
		, dim_detail_plot_details.[anticipated_date_of_mortgage_offer] AS [Anticipated Date of Mortgage Offer]
		, dim_detail_plot_details.[p_sols_received_search_results] AS [P Sols Received Search Results]
		, dim_detail_plot_details.[p_sols_raised_enquires] AS [P Sols Raised Enquires]
		, dim_detail_plot_details.[enquires_raised] AS [Enquires Raised]
		, dim_detail_plot_details.[have_enquires_been_satisfied] AS [Enquires Satisfied]
		, dim_detail_plot_details.[p_sols_received_mortgage_offer] AS [P Sols Received Mortgage Offer]
		, dim_detail_plot_details.[mortgage_offer_received] AS [Mortgage Offer Received]
		, dim_detail_plot_details.[p_sols_received_signed_contract_from_client] AS [Sols Received Signed Contract From Client]
		, dim_detail_plot_details.[p_sols_received_contract] AS [P Sols Received Contract]
		, dim_detail_plot_details.[reason_contract_not_received] AS [Reason Contract not Received]
		, dim_detail_plot_details.[p_sols_received_deposit_money] AS [P Sols Received Deposit Money]
		, dim_detail_plot_details.[deposit_money_received] AS [Date Deposit Money Received]
		, dim_detail_plot_details.[reason_for_deposit_money_delay] AS [Reason for Deposit Money Delay]
		, dim_detail_plot_details.[p_sols_confirmed_ready_to_exchange] AS [P Sols Confirmed Ready to Exchange]
		, dim_detail_plot_details.[confirmation_of_readiness_to_exchange] AS [Confirmation of Readiness to Exchange]
		, dim_detail_plot_details.[p_sols_requested_formal_reservation_extension] AS [P Sols Requested Formal Reservation Extension]
		, dim_detail_plot_details.[reservation_extension_requested] AS [Reservation Extension Requested]
		, dim_detail_plot_details.[reason_for_delay_in_exchange] AS [Reason for Delay in Exchange]
		, dim_detail_plot_details.[p_sols_anticipate_exchange_of_contracts] AS [P Sols Anticipate Exchange of Contracts]
		, dim_detail_plot_details.[date_info_received] AS [Date Info Received]
		, dim_detail_plot_details.[atp_received_from_homebuy_agent] AS [ATP Received From Homebuy Agent]
		, dim_detail_plot_details.[atp_received] AS [ATP Received]
		, dim_detail_plot_details.[documents_sent_to_p_sols] AS [Documents Sent to P Sols]
		, dim_detail_plot_details.[signed_docs_received] AS [Date Signed Docs Received]
		, dim_detail_plot_details.[p_sols_prepared_and_submitted_htb_undertakings] AS [P Sols Prepared and Submitted HTB Undertakings]
		, dim_detail_plot_details.[received_all_correct_and_relevent_htb_undertakings] AS [Received all Correct and Relevent HTB Undertakings]
		, dim_detail_plot_details.[htb_undertakings_received] AS [HTB Undertakings Received]
		, dim_detail_plot_details.[received_ate_from_homebuy_agent] AS [Received ATE from Homebuy Agent]
		, dim_detail_plot_details.[ate_received] AS [ATE Received]
		, dim_detail_property.[repairing_liability] AS [Repairing Liability]
		, dim_detail_property.next_key_date AS [Next Key Date]
		, dim_detail_property.key_date_name AS [Key Date Name]
		, dim_detail_property.[be_number] [BE Number]
		, dim_detail_property.[be_name] [BE Name]
		, dim_detail_property.[property_address] AS [Property Address]
		, dim_detail_property.[case_classification] AS [Case Classification]
		, dim_detail_property.[fixed_feehourly_rate] AS [Fixed Fee/Hourly Rate]
		, dim_detail_property.[fixed_fee_hourly_rate] AS [Fixed Fee or Hourly Rate?]
		, dim_detail_property.[freehold_leasehold] AS [Freehold or Leasehold]
		, dim_detail_property.[hsbc_charge] AS [HSBC Charge]
		, dim_detail_property.[restrictions_on_register] AS [Restrictions on Register]
		, dim_detail_property.[landlord] AS Landlord
		, dim_detail_property.[option_to_break] AS [Option to Break]
		, dim_detail_property.[option_to_purchase] AS [Option to Purchase]
		, dim_detail_property.option_to_renew AS [Option to Purchase]
		, dim_detail_property.[date_of_lease] AS [Date of Lease]
		, dim_detail_property.[date_of_transfer]  AS [Date of Transfer]
		, dim_detail_property.[rent_review_dates] AS [Rent Review Date]
		, dim_detail_property.[first_rent_review] AS [First Rent Review Date]
		, CASE WHEN dim_detail_property.[first_rent_review] >GETDATE() THEN dim_detail_property.[first_rent_review] END AS [1_rent_review greater than today]
		, dim_detail_property.[second_rent_review] AS [Second Rent Review]
		, CASE WHEN dim_detail_property.[second_rent_review] >GETDATE() THEN dim_detail_property.[second_rent_review] END AS [2_rent_review greater than today]
		, dim_detail_property.[third_rent_review] AS [Third Rent Review]
		, CASE WHEN dim_detail_property.[third_rent_review] >GETDATE() THEN dim_detail_property.[third_rent_review] END AS [3_rent_review greater than today]
		, dim_detail_property.[fourth_rent_review] AS [Fourth Rent Review]
		, CASE WHEN dim_detail_property.[fourth_rent_review] >GETDATE() THEN dim_detail_property.[fourth_rent_review] END AS [4_rent_review greater than today]
		, dim_detail_property.[fifth_rent_review] AS [Fifth Rent Review]
		, CASE WHEN dim_detail_property.[fifth_rent_review] >GETDATE() THEN dim_detail_property.[fifth_rent_review] END AS [5_rent_review greater than today]
		, dim_detail_property.[miscellaneous_issues] AS [Miscellaneous Issues]
		, dim_detail_property.[lease_term] AS [Lease Term]
		, dim_detail_property.[starting_rent] AS [Starting Rent]
		, dim_detail_property.[title_number] AS [Title Number]
		, dim_detail_property.[lease_start_date] AS [Lease Start Date]
		, dim_detail_property.[lease_end_date] AS [Lease End Date]
		, dim_detail_property.[first_notice_served] AS [First Notice Served]
		, dim_detail_property.[received_proposed_completion_date__docs] AS [Received Proposed Completion Date Docs]
		, dim_detail_property.[tenant_name] AS [Tenant Name]
		, dim_detail_property.[mortgage_offer_received] AS [Mortgage Offer Received]
		, dim_detail_property.[campus] AS [Campus]
		, dim_detail_property.[address] AS [Address]
		, dim_detail_property.[tenure] AS [Tenure] 
		, dim_detail_property.registered_proprietor AS [Registered Proprietor]
		, dim_detail_property.[term_start_date] AS [Term Start Date]
		, dim_detail_property.[term_end_date] AS [Term End Date]
		, dim_detail_property.landlord_break_date AS [Landlord Break Date]
		, dim_detail_property.[tenant_break] AS [Tenant Break Date]
		, dim_detail_property.[postcode] AS [Postcode]
		, dim_detail_property.[property_ref] AS [Property Reference]
		, dim_detail_property.[landlord] AS Landlord
		, dim_detail_property.[landlord_address] AS [Landlord Address]
		, dim_detail_property.[agent] AS Agent
		, dim_detail_property.[main_operator_customer] AS [Main Operator Customer]
		, dim_detail_property.[break_clause_notice_required] AS [Break Clause Notice Required]
		, dim_detail_property.[rent_commencement_date] AS [Rent Commencement Date]
		, dim_detail_property.[repairing_liability] AS [Repairing Liability]
		, dim_detail_property.[rateable_value] AS [Rateable Value]
		, dim_detail_property.[rates_payable] AS [Rates Payable]
		, dim_detail_property.[rates_payable_to] AS [Rates Payable To]
		, dim_detail_property.service_charges AS [Service Charges] --
		, dim_detail_property.[service_charge_payable_to] AS [Service Charge Payable To]
		, dim_detail_property.[insurance_premium] AS [Insurance Premium]
		, dim_detail_property.[insurance_dates] AS [Insurance Dates]
		, dim_detail_property.[claim_from_bibbys_landlord] AS [Claim From Bibby's Landlord]
		, dim_detail_property.[bibbys_landlord] AS [Bibbys Landlord]
		, dim_detail_property.[bibbys_landlord_agent] AS [Bibby's Landlord Agent]
		, dim_detail_property.[bibbys_landlord_agents_address] AS [Bibby's Landlord Agents Address] 
		, dim_detail_property.[bibbys_tenant] AS [Bibby's Tenant]
		, dim_detail_property.[bibbys_tenant_contact_details] AS [Bibby's Tenant Contact Details]
		, dim_detail_property.[bibby_contact] AS [Bibby Contact]
		--, fact_detail_property.[amount_of_claim_from_bibbys_landlord] AS [Amount of Claim from Bibby's Landlord]
		, fact_detail_property.[bibbys_agent_estimate] AS [Bibby's Agent Estimate]
		, dim_detail_property.[comments] AS Comments
		, dim_detail_property.[lease_expired] AS [Lease Expired]
		, dim_detail_property.[settled] AS Settled
		, dim_detail_property.[search_area] AS [Search Area]
		, dim_detail_property.[current_situation] AS [Current Situation]
		, dim_detail_property.tab_on_property_schedule AS [Tab on Property Schedule]
		, dim_detail_property.mortgages AS [Mortages]
		, dim_detail_property.car_parking AS [Car Parking?]
		, dim_detail_property.[rexel_reference] AS [Rexel Reference]
		, dim_detail_property.[client_contact] AS [Client Contact]
		, dim_detail_property.[lmh_current_position] AS [LMH Current Position]
		, dim_detail_property.[group_company] AS [Group Company]
		, dim_detail_property.[city] AS City
		, dim_detail_property.[property_address] AS [Property Address]
		, dim_detail_property.[bruntwood_case_status] AS [Bruntwood Case Status]
		, dim_detail_property.[estate_manager] AS [Estate Manager]
		, dim_detail_property.[store_number] AS [Store Number]
		, COALESCE(dim_detail_property.[property_type_1], dim_detail_property.[property_type_2]) AS [Property Type]
		, dim_detail_property.[case_classification] AS [Case Classification]
		, dim_detail_property.case_type_asw AS [Case Type]
		, dim_detail_property.[next_action] AS [Bruntwood Next Action]
		, dim_detail_property.[university_lead] AS  [University Lead]
		, dim_detail_property.[responsibilty_budget] AS [Responsibilty/Budget]
		, dim_detail_property.[payable] AS Payable
		, dim_detail_property.[team] AS Team
		, dim_detail_property.[store_name] AS [Store Name]
		, dim_detail_property.[external_surveyor] AS [External Surveyor]
		, dim_detail_property.[capital_contribution_received] AS [Capital Contribution Received]
		, dim_detail_property.[hk_approval] AS [HK Approval]
		, dim_detail_property.term AS [Term]
		, dim_detail_property.[break_1] AS [Break]
		, dim_detail_property.[incentives] AS [Incentives]
		, dim_detail_property.[lease_expiry_date] AS [Lease Expiry Date]
		, dim_detail_property.[court_application_made] AS [Court Application]
		, dim_detail_property.[last_date_for_court_application] AS [Last Date for Court Application]
		, dim_detail_property.[s26_notice_date] AS [S.26 Notice Date]
		, dim_detail_property.[s25_notice_date] AS [S.25 Notice Date]
		, dim_detail_property.[expiry_of_section_26_notice] AS [Expiry of Section 26 Notice]
	    , dim_detail_property.[expiry_of_section_25_notice] AS [Expiry of Section 25 Notice]
		, dim_detail_property.[status] AS [Property Status]
		, dim_detail_property.[priority] AS [Priority]
 		, dim_detail_property.[years_left_on_lease] AS [Years Left on Lease]
		, dim_detail_property.[management_company] AS [Management Company]
		, dim_detail_property.[enfield_case_status] AS [Enfield Case Status]
		, dim_detail_property.[enfield_next_action] AS [Enfield Next Action]
		, dim_detail_property.[upcoming_works] AS [Upcoming works]
		, dim_detail_property.[transaction_1] AS [Transaction Type]
		, dim_detail_property.[vendor] AS [Vendor]
		, dim_detail_property.[freeholder_if_applicable] AS [Freeholder (if applicable)]
		, dim_detail_property.[additional_info_re__major_works] AS [Additional Info re  major works]
		, dim_detail_property.licence_to_occupy AS [Licence to Occupy?]
		, dim_detail_property.scanned AS [Scanned?]
		, dim_detail_property.[tenure] AS Tenure
		, dim_detail_property.landlord_rolling_break_notice AS [Landlord Rolling Break Notice]
		, dim_detail_property.tenant_rolling_break_notice AS [Tenant Rolling Break Notice]
		, dim_detail_property.[brand] AS Brand
		, dim_detail_property.[pentland_brand_contact] AS [Pentland Brand Contact]
		, dim_detail_property.[pentland_reference] AS [Pentland Ref]
		, dim_detail_property.[break_date] AS [Break Date]
		, dim_detail_property.[file_type] AS [Break Date]
		, dim_detail_property.[coop_purchase_order_1] AS [Co-op PO Ref]
		, dim_detail_property.[location] AS Location
		, dim_detail_property.[country] AS Country
		, dim_detail_property.[guarantor] AS Guarantor
		, dim_detail_property.[lease_date] AS [Lease Date] 
		, dim_detail_property.[l_ta_protected] AS [L&TA Protected?]
		, dim_detail_property.[actual_break_date] AS [ Break Notice Date]
		, dim_detail_property.[currency] AS [Currency]
		, dim_detail_property.[longitude] AS [Longitude]
		, dim_detail_property.[latitude] AS [Latitude]
		, dim_detail_property.[target_completion_date] AS [Target Completion Date]
		, dim_detail_property.[completion_date] AS [Completion Date]
		, dim_detail_property.[exchange_date] AS [Exchange Date]
		, dim_detail_plot_details.[exchange_date_combined] AS [Exchange Date Combined]
		, dim_detail_property.[lease_id] AS [Lease ID]
		, dim_detail_property.[dp_number] AS [DP Number]
		, dim_detail_property.[dp_location] AS [DP Location]
		, dim_detail_property.[region] AS Region
		, dim_detail_property.[branch_code] AS [Branch Code]
		, dim_detail_property.[m3_code] AS [M3 Code]
		, dim_detail_property.[area] AS Area
		, dim_detail_property.[branch] AS Branch
		, dim_detail_property.[op_co] AS [Operation Company]
		, dim_detail_property.[tenure] AS Tenure
		, dim_detail_property.[review_pattern] AS [Review Pattern]
		, dim_detail_property.[protected] AS Protected
		, dim_detail_property.[updated] AS Updated
		, dim_detail_property.[vat] AS VAT
		, dim_detail_property.[client_listing_code] AS [Client Listing Code]
		, dim_detail_property.[property_contact] AS [Property Contact]
		, dim_detail_property.[property_name_] AS [Property Name]
		, dim_detail_property.[property_address_1] AS [Property Address 1] 
		, dim_detail_property.[property_address_2] AS [Property Address 2]
		, dim_detail_property.[postcode] AS [Post Code]
		, dim_detail_property.[weightmans_po_reference] AS [Weightmans PO Reference]
		, dim_detail_property.[cg_legal_services_file_number] AS [CG Legal Services File Number]
		, dim_detail_property.[cg_legal_services_contact] AS [CG Legal Services Contact]
		, dim_detail_property.[matter] AS [Nature of Transaction]
		, dim_detail_property.[surveyor_dealing] AS [Surveyor Dealing]
		, dim_detail_property.[deeds_held] AS [Deeds Held]
		, dim_detail_property.[client_report] AS [Client Report]
		, dim_detail_property.[priority] AS [Priority]
		, dim_detail_property.[documents_under_negotiation_01] AS [Documents Under Negotiation] 
		, dim_detail_property.[present_position] AS [Present Position]
		, dim_detail_property.[commercial_bl_status] AS [Reservation Status]
		--duplicate of above
		--, dim_detail_property.[reservation_status] AS [Reservation Status]
		, dim_detail_property.[start] AS [Start Date]
		, dim_detail_property.[end_date] AS [End Date]
		, CASE WHEN dim_detail_property.[end_date] >=GETDATE() THEN dim_detail_property.[end_date] END AS [End Date greater than today]
		, dim_detail_property.[pspurchaser_1_full_name] AS [Purchasers 1 Full Name] 
		, dim_detail_property.[pspurchaser_2_full_name] AS [Purchasers 2 Full Name] 
		, dim_detail_property.[pspurchaser_3_full_name] AS [Purchasers 3 Full Name] 
		, dim_detail_property.[pspurchaser_4_full_name] AS [Purchasers 4 Full Name] 
		, fact_detail_property.[purchase_price] AS [Purchase Price]
		, fact_detail_property.[fee_estimate] AS [Fee Estimate]
		, fact_detail_property.[rent_arrears] AS [Amount of Rent Arrears]
		, fact_detail_property.[disbursements_estimate] AS [Disbursements Estimate]
		, fact_detail_property.[full_price] AS [Full Price]
		, fact_detail_property.[floor_area_square_foot] AS [Floor Area Square Foot]
		, fact_detail_property.[current_rent] AS [Current Rent]
		, fact_detail_property.[service_charge] AS [Service Charge] --
		, fact_detail_property.[size_square_foot] AS [Size Square Foot] 
		, fact_detail_property.original_rent AS [Original Rent]
		, fact_detail_property.[proposed_rent] AS [Proposed Rent]
		, fact_detail_property.[passing_rent] AS [Passing Rent]
		, fact_detail_property.[no_of_bedrooms] AS [No of Bedrooms]
		, fact_detail_property.[next_rent_amount] AS [Next Rent Amount]
		, fact_detail_property.[car_spaces_inc] AS [Car Spaces included]
		, fact_detail_property.[gifa_as_let_sq_feet] AS [GIFA "as let" Sq Feet]
		, fact_detail_property.[mezz_sq_feet] AS [Mezz Sq Feet]
		, fact_detail_property.[sales_admin_sq_ft ] AS [Sales / Admin Sq Ft]
		, fact_detail_property.[total_sq_ft] AS [Total Sq Ft]
		, fact_detail_property.[store_sq_ft] AS [Store Sq Ft]
		, fact_detail_property.[client_paying] AS [Client Paying?]
		, fact_detail_property.[third_party_pay] AS [How much will a Third Party Pay?]
		, fact_detail_property.[contribution] AS [Contribution]
		, fact_detail_property.[contribution_percent] AS [Contribution %]
		, fact_detail_property.[ps_purchase_price] AS [PS_Purchase Price]
		, fact_detail_property.[reduced_purchase_price] AS [Reduced Purchase Price]
		, dim_detail_property.next_key_date AS [Next Key Date]
		, dim_detail_property.key_date_name AS [Key Date Name]
		, dim_detail_plot_details.exchange_date AS [Plot Exchange Date]
		, dim_client_involvement.purchasersols_name  AS [Purchaser solicitors]
		, dim_detail_client.present_position AS [Present Position Description]
		, fact_finance_summary.client_account_balance_of_matter AS [Client Balance]
		, dim_detail_property.address_property AS [Address Property]
		, dim_detail_property.contact_property AS [Contact Property]
		, CASE WHEN fact_dimension_main.client_code='00787558'THEN 'Superdrug' 
             WHEN fact_dimension_main.client_code='00787559' THEN 'Perfume Shop'
             WHEN fact_dimension_main.client_code='00787560' THEN 'Three Mobile'
             WHEN fact_dimension_main.client_code='00787561' THEN 'Savers'
		  END AS [Fascia]
		, CASE WHEN  dim_detail_property.term_end_date >GETDATE() THEN min(dim_detail_property.term_end_date) END AS TermDate --this is the min term date after getdate
		, CASE WHEN dim_detail_property.rent_review_dates >GETDATE() THEN min(dim_detail_property.rent_review_dates) END AS RentDate ----this is the min rent review date after getdate
		, CASE WHEN dim_detail_property.tenant_break >GETDATE() THEN min(dim_detail_property.tenant_break) END AS TenantBreakDate -- --this is the min tenant break date after getdate
		, CASE WHEN dim_detail_property.tenant_break >GETDATE() THEN min(dim_detail_property.landlord_break_date ) END AS landlordBreakDate --this is the min Landlord Break date after getdate
		, CASE WHEN fact_dimension_main.client_code = '177450B' THEN 'Barratt Manchester Developments'
			WHEN fact_dimension_main.client_code = '177451B' THEN 'David Wilson Homes Limited Developments'
			WHEN fact_dimension_main.client_code = '190593P' THEN 'Persimmon Homes Limited Development'
			WHEN fact_dimension_main.client_code = '00451167' THEN 'Purelake New Homes Limited'
			WHEN fact_dimension_main.client_code = '00648125' THEN 'Greenfield Place Development Company Limited Developments'
			WHEN fact_dimension_main.client_code = '117776T' THEN 'Thomas Jones & Sons Limited Developments'
			WHEN fact_dimension_main.client_code = '00848629' THEN 'Eccleston Homes Limited'
			ELSE 'Other' END AS [Developments]
		, CASE WHEN fact_dimension_main.client_code = '177450B' THEN dim_detail_plot_details.barratt_manchester_developments
			WHEN fact_dimension_main.client_code = '177451B' THEN  dim_detail_plot_details.david_wilson_homes_limited_developments
			WHEN fact_dimension_main.client_code = '190593P' THEN  dim_detail_plot_details.persimmon_homes_limited_development
			WHEN fact_dimension_main.client_code = '00451167' THEN dim_detail_plot_details.purelake_new_homes_limited
			WHEN fact_dimension_main.client_code = '00648125' THEN dim_detail_plot_details.greenfields_place_development_company_limited_developments
			WHEN fact_dimension_main.client_code = '117776T' THEN dim_detail_plot_details.thomas_jones_sons_limited_development
			WHEN fact_dimension_main.client_code = '00848629' THEN 'Missing Field PSL121'
			ELSE '' END AS [Development Name]
		, CASE WHEN dim_detail_plot_details.type_of_scheme='Part Exchange' THEN 'Yes' ELSE 'No' END AS [Part exchange?]
		, CASE WHEN dim_detail_plot_details.[pscompletion_date] IS NOT NULL THEN 'Completion'
				WHEN dim_detail_plot_details.[exchange_date_combined] IS NOT NULL THEN 'Exchange'
				WHEN dim_detail_plot_details.[reservation_received] IS NOT NULL THEN 'Reserved'
				ELSE 'Unreserved' END AS [Property Status]
		, CASE WHEN dim_detail_property.[tab_on_property_schedule] IS NULL THEN 'N/A' 
               ELSE ISNULL(dim_detail_property.[company_reference],'Company Reference Missing') END  AS [Company Reference]


		, CASE WHEN dim_department.[department_name]  = 'Commercial Dispute Resolution' THEN 'Contentious'
		   ELSE 'Non-Contentious' END AS [Property View File Type]
		 , COALESCE(dim_detail_court.[date_determination_of_papers],dim_detail_property.[expiry_of_section_26_notice],dim_detail_property.[expiry_of_section_25_notice]) [Next Key Date - Property View]
		 , CASE WHEN dim_detail_court.[date_determination_of_papers] is not null THEN 'Date of Determination'
               WHEN dim_detail_property.[expiry_of_section_26_notice] is not null THEN 'Expiry of Section 26'
               WHEN dim_detail_property.[expiry_of_section_25_notice] is not null THEN 'Expiry of Section 25'
			   ELSE 'N/A'
          END [Key Date Name - Property View]
		, CASE WHEN dim_detail_property.[case_type_rmg] = 'RE/SAL/FH' THEN 'Freehold Sale' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/SAL/AL' THEN 'Assignment of Lease' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/SAL/SURO' THEN 'Surrender Out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/PUR/FH' THEN 'Freehold Purchase' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/PUR/LH' THEN 'Leasehold Purchase' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/PUR/SURI' THEN 'Surrender in' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/IN' THEN 'Lease in' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/OUT' THEN 'Lease out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/UNDI' THEN 'Underletting in' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/UNDO' THEN 'Underletting out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/TENC' THEN 'Tenancy Agreement' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/OLIC' THEN 'Occupation Licence' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/XMAS' THEN 'Christmas Licence' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/L&T/LTNI' THEN '1954 Act Notice In' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/L&T/LTNO' THEN '1954 Act Notice Out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/L&T/LTP' THEN '1954 Act Proceedings' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/AS' THEN 'Licence to Assign' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/UL' THEN 'Licence to Underlet' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/AL' THEN 'Licence for alterations' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/OTH' THEN 'Licence Other' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/ADV' THEN 'Advice' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/TR' THEN 'Title Report' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/DVAR' THEN 'Deed of Variation' 
              ELSE NULL
            END AS [RMG Case Type]

			,dim_matter_header_current.reporting_exclusions
			,case when dim_detail_property.status_rm <> dim_detail_previous_details.status_rm then 'RMStatusChanged'
			else 'NotChanged' end as RMStatusChange
			


 
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_plot_details ON dim_detail_plot_details.dim_detail_plot_detail_key = fact_dimension_main.dim_detail_plot_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_property ON fact_detail_property.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome AS detail_outcome ON detail_outcome.dim_detail_outcome_key=fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON red_dw.dbo.dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court ON red_dw.dbo.dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details ON dim_detail_previous_details.dim_detail_previous_details_key = fact_dimension_main.dim_detail_property_key
 
WHERE 
ISNULL(detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.matter_number<>'ML'
AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= '20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)


 GROUP BY
	 RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number 
		, fact_dimension_main.client_code 
		, fact_dimension_main.matter_number 
		, dim_matter_header_current.[matter_description]
		, dim_client_involvement.[purchaser_name] 
		, dim_detail_client.cumbria_faculty 
		, dim_detail_client.cumbria_location 
		, dim_detail_client.cumbria_services 
		, dim_detail_plot_details.pscompletion_date 
		, dim_detail_plot_details.[condition_date] 
		, dim_detail_plot_details.[reservation_received]
		, dim_detail_plot_details.[psexpiry_of_reservation_period] 
		, dim_detail_plot_details.[type_of_lease] 
		, dim_detail_plot_details.cumbria_lot 
		, dim_detail_plot_details.[contracts_exchanged] 
		, dim_detail_plot_details.[car_parking_lease] 
		, dim_detail_plot_details.[psplot_number] 
		, dim_detail_plot_details.[agency] 
		, dim_detail_plot_details.[purchasers_full_address] 
		, dim_detail_plot_details.[purchasers_2_full_address] 
		, dim_detail_plot_details.[purchasers_3_full_address] 
		, dim_detail_plot_details.[purchasers_4_full_address] 
		, dim_detail_plot_details.[leasehold_freehold] 
		, dim_detail_plot_details.[david_wilson_homes_limited_developments] 
		, dim_detail_plot_details.[barratt_manchester_developments] 
		, dim_detail_plot_details.[thomas_jones_sons_limited_development] 
		, dim_detail_plot_details.[persimmon_homes_limited_development] 
		, dim_detail_plot_details.[purelake_new_homes_limited] 
		, dim_detail_plot_details.[greenfields_place_development_company_limited_developments] 
		, dim_detail_plot_details.[address_of_part_exchange] 
		, dim_detail_plot_details.[type_of_scheme] 
		, dim_detail_plot_details.[type_of_transfer] 
		, dim_detail_plot_details.[have_we_received_atp] 
		, dim_detail_plot_details.[anticipated_legal_completion_date] 
		, dim_detail_property.[exchange_date] 
		, dim_detail_plot_details.[exchange_date_combined]
		, dim_detail_plot_details.[lender] 
		, dim_detail_plot_details.[reservation_signed] 
		, dim_detail_plot_details.[all_info_received] 
		, dim_detail_plot_details.[reason_for_info_not_received] 
		, dim_detail_plot_details.[contractual_docs_sent_to_p_sols] 
		, dim_detail_plot_details.[p_sols_ack_receipt_of_docs] 
		, dim_detail_plot_details.[date_of_acknowledgement] 
		, dim_detail_plot_details.[p_sols_received_formal_instruction] 
		, dim_detail_plot_details.[formal_instruction_received] 
		, dim_detail_plot_details.[p_sols_received_search_fees_money] 
		, dim_detail_plot_details.[search_fee_money_received] 
		, dim_detail_plot_details.[p_sols_applied_for_searches] 
		, dim_detail_plot_details.[searches_applied] 
		, dim_detail_plot_details.[date_of_search_results]
		, dim_detail_plot_details.[p_sols_confirmed_anticipated_date_of_mortgage_offer]
		, dim_detail_plot_details.[anticipated_date_confirmed] 
		, dim_detail_plot_details.[anticipated_date_of_mortgage_offer] 
		, dim_detail_plot_details.[p_sols_received_search_results] 
		, dim_detail_plot_details.[p_sols_raised_enquires] 
		, dim_detail_plot_details.[enquires_raised] 
		, dim_detail_plot_details.[have_enquires_been_satisfied] 
		, dim_detail_plot_details.[p_sols_received_mortgage_offer] 
		, dim_detail_plot_details.[mortgage_offer_received] 
		, dim_detail_plot_details.[p_sols_received_signed_contract_from_client] 
		, dim_detail_plot_details.[p_sols_received_contract] 
		, dim_detail_plot_details.[reason_contract_not_received]
		, dim_detail_plot_details.[p_sols_received_deposit_money] 
		, dim_detail_plot_details.[deposit_money_received]
		, dim_detail_plot_details.[reason_for_deposit_money_delay] 
		, dim_detail_plot_details.[p_sols_confirmed_ready_to_exchange] 
		, dim_detail_plot_details.[confirmation_of_readiness_to_exchange] 
		, dim_detail_plot_details.[p_sols_requested_formal_reservation_extension] 
		, dim_detail_plot_details.[reservation_extension_requested] 
		, dim_detail_plot_details.[reason_for_delay_in_exchange] 
		, dim_detail_plot_details.[p_sols_anticipate_exchange_of_contracts] 
		, dim_detail_plot_details.[date_info_received] 
		, dim_detail_plot_details.[atp_received_from_homebuy_agent] 
		, dim_detail_plot_details.[atp_received] 
		, dim_detail_plot_details.[documents_sent_to_p_sols] 
		, dim_detail_plot_details.[signed_docs_received] 
		, dim_detail_plot_details.[p_sols_prepared_and_submitted_htb_undertakings] 
		, dim_detail_plot_details.[received_all_correct_and_relevent_htb_undertakings] 
		, dim_detail_plot_details.[htb_undertakings_received] 
		, dim_detail_plot_details.[received_ate_from_homebuy_agent] 
		, dim_detail_plot_details.[ate_received] 
		, dim_detail_property.[repairing_liability] 
		, dim_detail_property.next_key_date 
		, dim_detail_property.key_date_name 
		, dim_detail_property.[be_number] 
		, dim_detail_property.[be_name] 
		, dim_detail_property.[property_address] 
		, dim_detail_property.[case_classification] 
		, dim_detail_property.[fixed_feehourly_rate] 
		, dim_detail_property.[fixed_fee_hourly_rate]
		, dim_detail_property.[freehold_leasehold] 
		, dim_detail_property.[hsbc_charge] 
		, dim_detail_property.[restrictions_on_register] 
		, dim_detail_property.[landlord] 
		, dim_detail_property.[option_to_break] 
		, dim_detail_property.[option_to_purchase] 
		, dim_detail_property.option_to_renew
		, dim_detail_property.[date_of_lease] 
		, dim_detail_property.[date_of_transfer]  
		, dim_detail_property.[rent_review_dates] 
		, dim_detail_property.[first_rent_review] 
		, dim_detail_property.[second_rent_review] 
		, dim_detail_property.[third_rent_review] 
		, dim_detail_property.[fourth_rent_review] 
		, dim_detail_property.[fifth_rent_review]
		, dim_detail_property.[miscellaneous_issues] 
		, dim_detail_property.[lease_term] 
		, dim_detail_property.[starting_rent] 
		, dim_detail_property.[title_number] 
		, dim_detail_property.[lease_start_date] 
		, dim_detail_property.[lease_end_date] 
		, dim_detail_property.[first_notice_served] 
		, dim_detail_property.[received_proposed_completion_date__docs] 
		, dim_detail_property.[tenant_name] 
		, dim_detail_property.[mortgage_offer_received] 
		, dim_detail_property.[campus] 
		, dim_detail_property.[address] 
		, dim_detail_property.[tenure] 
		, dim_detail_property.registered_proprietor 
		, dim_detail_property.[term_start_date] 
		, dim_detail_property.[term_end_date] 
		, dim_detail_property.landlord_break_date 
		, dim_detail_property.[tenant_break] -- date
		, dim_detail_property.[postcode] 
		, dim_detail_property.[property_ref] 
		, dim_detail_property.[landlord] 
		, dim_detail_property.[landlord_address]
		, dim_detail_property.[agent] 
		, dim_detail_property.[main_operator_customer] 
		, dim_detail_property.[break_clause_notice_required] 
		, dim_detail_property.[rent_commencement_date] 
		, dim_detail_property.[repairing_liability] 
		, dim_detail_property.[rateable_value] 
		, dim_detail_property.[rates_payable] 
		, dim_detail_property.[rates_payable_to] 
		, dim_detail_property.service_charges 
		, dim_detail_property.[service_charge_payable_to] 
		, dim_detail_property.[insurance_premium] 
		, dim_detail_property.[insurance_dates] 
		, dim_detail_property.[claim_from_bibbys_landlord] 
		, dim_detail_property.[bibbys_landlord] 
		, dim_detail_property.[bibbys_landlord_agent] 
		, dim_detail_property.[bibbys_landlord_agents_address] 
		, dim_detail_property.[bibbys_tenant]
		, dim_detail_property.[bibbys_tenant_contact_details] 
		, dim_detail_property.[bibby_contact] 
		--, fact_detail_property.[amount_of_claim_from_bibbys_landlord] AS [Amount of Claim from Bibby's Landlord]
		, fact_detail_property.[bibbys_agent_estimate] 
		, dim_detail_property.[comments] 
		, dim_detail_property.[lease_expired] 
		, dim_detail_property.[settled] 
		, dim_detail_property.[search_area]
		, dim_detail_property.[current_situation]
		, dim_detail_property.tab_on_property_schedule 
		, dim_detail_property.mortgages 
		, dim_detail_property.car_parking 
		, dim_detail_property.[rexel_reference] 
		, dim_detail_property.[client_contact] 
		, dim_detail_property.[lmh_current_position] 
		, dim_detail_property.[group_company] 
		, dim_detail_property.[city] 
		, dim_detail_property.[property_address] 
		, dim_detail_property.[bruntwood_case_status]
		, dim_detail_property.[estate_manager] 
		, dim_detail_property.[store_number] 
		, COALESCE(dim_detail_property.[property_type_1], dim_detail_property.[property_type_2])
		, dim_detail_property.[case_classification] 
		, dim_detail_property.case_type_asw 
		, dim_detail_property.[next_action] 
		, dim_detail_property.[university_lead] 
		, dim_detail_property.[responsibilty_budget] 
		, dim_detail_property.[payable]
		, dim_detail_property.[team]
		, dim_detail_property.[store_name]
		, dim_detail_property.[external_surveyor] 
		, dim_detail_property.[capital_contribution_received] 
		, dim_detail_property.[hk_approval] 
		, dim_detail_property.term 
		, dim_detail_property.[break_1] 
		, dim_detail_property.[incentives] 
		, dim_detail_property.[lease_expiry_date] 
		, dim_detail_property.[court_application_made] 
		, dim_detail_property.[last_date_for_court_application] 
		, dim_detail_property.[s26_notice_date] 
		, dim_detail_property.[s25_notice_date] 
		, dim_detail_property.[expiry_of_section_26_notice] 
	    , dim_detail_property.[expiry_of_section_25_notice]
		, dim_detail_property.[status] 
		, dim_detail_property.[priority] 
 		, dim_detail_property.[years_left_on_lease] 
		, dim_detail_property.[management_company] 
		, dim_detail_property.[enfield_case_status] 
		, dim_detail_property.[enfield_next_action] 
		, dim_detail_property.[upcoming_works]
		, dim_detail_property.[transaction_1] 
		, dim_detail_property.[vendor] 
		, dim_detail_property.[freeholder_if_applicable] 
		, dim_detail_property.[additional_info_re__major_works] 
		, dim_detail_property.licence_to_occupy 
		, dim_detail_property.scanned 
		, dim_detail_property.[tenure] 
		, dim_detail_property.landlord_rolling_break_notice 
		, dim_detail_property.tenant_rolling_break_notice 
		, dim_detail_property.[brand] 
		, dim_detail_property.[pentland_brand_contact] 
		, dim_detail_property.[pentland_reference] 
		, dim_detail_property.[break_date] 
		, dim_detail_property.[file_type] 
		, dim_detail_property.[coop_purchase_order_1] 
		, dim_detail_property.[location] 
		, dim_detail_property.[country] 
		, dim_detail_property.[guarantor] 
		, dim_detail_property.[lease_date] 
		, dim_detail_property.[l_ta_protected] 
		, dim_detail_property.[actual_break_date] 
		, dim_detail_property.[currency] 
		, dim_detail_property.[longitude] 
		, dim_detail_property.[latitude] 
		, dim_detail_property.[target_completion_date] 
		, dim_detail_property.[completion_date] 
		, dim_detail_property.[exchange_date] 
		, dim_detail_property.[lease_id] 
		, dim_detail_property.[dp_number] 
		, dim_detail_property.[dp_location] 
		, dim_detail_property.[region] 
		, dim_detail_property.[branch_code] 
		, dim_detail_property.[m3_code]
		, dim_detail_property.[area] 
		, dim_detail_property.[branch] 
		, dim_detail_property.[op_co] 
		, dim_detail_property.[tenure] 
		, dim_detail_property.[review_pattern] 
		, dim_detail_property.[protected] 
		, dim_detail_property.[updated] 
		, dim_detail_property.[vat] 
		, dim_detail_property.[client_listing_code] 
		, dim_detail_property.[property_contact] 
		, dim_detail_property.[property_name_] 
		, dim_detail_property.[property_address_1] 
		, dim_detail_property.[property_address_2] 
		, dim_detail_property.[postcode] 
		, dim_detail_property.[weightmans_po_reference]
		, dim_detail_property.[cg_legal_services_file_number] 
		, dim_detail_property.[cg_legal_services_contact] 
		, dim_detail_property.[matter]
		, dim_detail_property.[surveyor_dealing] 
		, dim_detail_property.[deeds_held] 
		, dim_detail_property.[client_report] 
		, dim_detail_property.[priority] 
		, dim_detail_property.[documents_under_negotiation_01] 
		, dim_detail_property.[present_position] 
		, dim_detail_property.[commercial_bl_status] 
		, dim_detail_property.[reservation_status] 
		, dim_detail_property.[start] 
		, dim_detail_property.[end_date] 
		, dim_detail_property.[pspurchaser_1_full_name]
		, dim_detail_property.[pspurchaser_2_full_name]
		, dim_detail_property.[pspurchaser_3_full_name] 
		, dim_detail_property.[pspurchaser_4_full_name] 
		, fact_detail_property.[purchase_price] 
		, fact_detail_property.[fee_estimate] 
		, fact_detail_property.[rent_arrears] 
		, fact_detail_property.[disbursements_estimate]
		, fact_detail_property.[full_price]
		, fact_detail_property.[floor_area_square_foot] 
		, fact_detail_property.[current_rent] 
		, fact_detail_property.[service_charge] 
		, fact_detail_property.[size_square_foot]
		, fact_detail_property.original_rent 
		, fact_detail_property.[proposed_rent] 
		, fact_detail_property.[passing_rent] 
		, fact_detail_property.[no_of_bedrooms] 
		, fact_detail_property.[next_rent_amount] 
		, fact_detail_property.[car_spaces_inc] 
		, fact_detail_property.[gifa_as_let_sq_feet] 
		, fact_detail_property.[mezz_sq_feet] 
		, fact_detail_property.[sales_admin_sq_ft ] 
		, fact_detail_property.[total_sq_ft] 
		, fact_detail_property.[store_sq_ft] 
		, fact_detail_property.[client_paying] 
		, fact_detail_property.[third_party_pay] 
		, fact_detail_property.[contribution] 
		, fact_detail_property.[contribution_percent] 
		, fact_detail_property.[ps_purchase_price] 
		, fact_detail_property.[reduced_purchase_price] 
		, dim_detail_property.next_key_date 
		, dim_detail_property.key_date_name
		, dim_detail_plot_details.exchange_date 
		, dim_client_involvement.purchasersols_name 
		, dim_detail_client.present_position
		, fact_finance_summary.client_account_balance_of_matter 
		, dim_detail_property.address_property
		, dim_detail_property.contact_property
		, CASE WHEN fact_dimension_main.client_code='00787558'THEN 'Superdrug' 
             WHEN fact_dimension_main.client_code='00787559' THEN 'Perfume Shop'
             WHEN fact_dimension_main.client_code='00787560' THEN 'Three Mobile'
             WHEN fact_dimension_main.client_code='00787561' THEN 'Savers'
		  END
		, CASE WHEN fact_dimension_main.client_code = '177450B' THEN 'Barratt Manchester Developments'
		WHEN fact_dimension_main.client_code = '177451B' THEN 'David Wilson Homes Limited Developments'
		WHEN fact_dimension_main.client_code = '190593P' THEN 'Persimmon Homes Limited Development'
		WHEN fact_dimension_main.client_code = '00451167' THEN 'Purelake New Homes Limited'
		WHEN fact_dimension_main.client_code = '00648125' THEN 'Greenfield Place Development Company Limited Developments'
		WHEN fact_dimension_main.client_code = '117776T' THEN 'Thomas Jones & Sons Limited Developments'
		WHEN fact_dimension_main.client_code = '00848629' THEN 'Eccleston Homes Limited'
		ELSE 'Other' END
		, CASE WHEN fact_dimension_main.client_code = '177450B' THEN dim_detail_plot_details.barratt_manchester_developments
		WHEN fact_dimension_main.client_code = '177451B' THEN  dim_detail_plot_details.david_wilson_homes_limited_developments
		WHEN fact_dimension_main.client_code = '190593P' THEN  dim_detail_plot_details.persimmon_homes_limited_development
		WHEN fact_dimension_main.client_code = '00451167' THEN dim_detail_plot_details.purelake_new_homes_limited
		WHEN fact_dimension_main.client_code = '00648125' THEN dim_detail_plot_details.greenfields_place_development_company_limited_developments
		WHEN fact_dimension_main.client_code = '117776T' THEN dim_detail_plot_details.thomas_jones_sons_limited_development
		WHEN fact_dimension_main.client_code = '00848629' THEN 'Missing Field PSL121'
		ELSE '' END
		, CASE WHEN dim_detail_plot_details.type_of_scheme='Part Exchange' THEN 'Yes' ELSE 'No' END
		, CASE WHEN dim_detail_plot_details.[pscompletion_date] IS NOT NULL THEN 'Completion'
				WHEN dim_detail_plot_details.[exchange_date_combined] IS NOT NULL THEN 'Exchange'
				WHEN dim_detail_plot_details.[reservation_received] IS NOT NULL THEN 'Reserved'
				ELSE 'Unreserved' END
		, CASE WHEN dim_detail_property.[tab_on_property_schedule] IS NULL THEN 'N/A' 
               ELSE ISNULL(dim_detail_property.[company_reference],'Company Reference Missing') END 
		, CASE WHEN dim_department.[department_name]  = 'Commercial Dispute Resolution' THEN 'Contentious'
		   ELSE 'Non-Contentious' END 
		 , COALESCE(dim_detail_court.[date_determination_of_papers],dim_detail_property.[expiry_of_section_26_notice],dim_detail_property.[expiry_of_section_25_notice])
		 , CASE WHEN dim_detail_court.[date_determination_of_papers] is not null THEN 'Date of Determination'
               WHEN dim_detail_property.[expiry_of_section_26_notice] is not null THEN 'Expiry of Section 26'
               WHEN dim_detail_property.[expiry_of_section_25_notice] is not null THEN 'Expiry of Section 25'
			   ELSE 'N/A'
          END 
		, CASE WHEN dim_detail_property.[case_type_rmg] = 'RE/SAL/FH' THEN 'Freehold Sale' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/SAL/AL' THEN 'Assignment of Lease' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/SAL/SURO' THEN 'Surrender Out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/PUR/FH' THEN 'Freehold Purchase' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/PUR/LH' THEN 'Leasehold Purchase' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/PUR/SURI' THEN 'Surrender in' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/IN' THEN 'Lease in' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/OUT' THEN 'Lease out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/UNDI' THEN 'Underletting in' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/UNDO' THEN 'Underletting out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/TENC' THEN 'Tenancy Agreement' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/OLIC' THEN 'Occupation Licence' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LS/XMAS' THEN 'Christmas Licence' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/L&T/LTNI' THEN '1954 Act Notice In' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/L&T/LTNO' THEN '1954 Act Notice Out' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/L&T/LTP' THEN '1954 Act Proceedings' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/AS' THEN 'Licence to Assign' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/UL' THEN 'Licence to Underlet' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/AL' THEN 'Licence for alterations' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/LIC/OTH' THEN 'Licence Other' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/ADV' THEN 'Advice' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/TR' THEN 'Title Report' 
               WHEN dim_detail_property.[case_type_rmg] = 'RE/DVAR' THEN 'Deed of Variation' 
              ELSE NULL
            END
	,dim_matter_header_current.reporting_exclusions
,case when dim_detail_property.status_rm <> dim_detail_previous_details.status_rm then 'RMStatusChanged'
			else 'NotChanged' end 
	
	END
GO
