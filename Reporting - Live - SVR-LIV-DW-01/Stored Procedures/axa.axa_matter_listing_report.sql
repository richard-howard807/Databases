SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 16/02/2018
-- Ticket Number: 294178 & 294219
-- Description:	New datasource for the new AXA Listing report and accompanying Dashboard
-- Changes 05/12/2018 Added joins and isnulls for following tables dbo.dim_involvement_full clsol, dbo.dim_involvement_full insrref, dim_involvement_full insdref
-- ES 20/05/2019 - Amended claimant solicitors to include claimant's represtative in the coalesce, 19878 
-- ES 29/07/2019 - added reserve details, 27736
-- ES 20/02/2020 - added additional fields, 48695
-- ES 22/04/2020 - added Does the claimant have a PI claim? and Date of Last Bill and Date Last Worked, 56563
-- JL 13/05/2020 - removed date_instructions_received is not null as per ticket 58054
-- ES 16/07/2020 - #64836 added client code 220044, amended tp costs paid  detail, added date costs settled, unbilled disbs and unpaid bill balance
-- JL 22/09/2020 - #72988 added in axa instruction type as per Helen Fox
---------- =============================================
CREATE PROCEDURE [axa].[axa_matter_listing_report]
AS
BEGIN


    SELECT [Date instructions received] = dim_detail_core_details.date_instructions_received,
           [Line of Business] = dim_matter_worktype.work_type_name,
           [Weightmans FE] = fee_earner.name,
           [Weightmans Reference ] = RTRIM(fact_dimension_main.client_code) + '-' + fact_dimension_main.matter_number,
           [AXA CS Handler] = dim_detail_core_details.clients_claims_handler_surname_forename,
           [AXA CS Reference] = ISNULL(client_ref.insurerclient_reference,insrref.reference),
           [Date of Accident] = dim_detail_core_details.incident_date,
           [Claimant Solicitors] = COALESCE(tp_ref.claimantsols_name,clsol.name,tp_ref.claimantrep_name),
           [Injury Type ] = dim_detail_core_details.brief_description_of_injury,
          -- [Injury Type ] = dim_detail_core_details.injury_type,
           [Matter Description] = dim_matter_header_current.matter_description,
           [Present Position] = dim_detail_core_details.present_position,
           [Referral reason] = dim_detail_core_details.referral_reason,
           [Track] = dim_detail_core_details.track,
           [Proceedings issued] = dim_detail_core_details.proceedings_issued,
           [Suspicion of Fraud] = dim_detail_core_details.suspicion_of_fraud,
           [Damages Reserve Current] = fact_finance_summary.damages_reserve,
           [TP Costs Reserve Current] = fact_finance_summary.tp_costs_reserve,
           [Defence Costs Reserve Current] = fact_finance_summary.defence_costs_reserve,
           [Date Claim Concluded] = dim_detail_outcome.date_claim_concluded,
           [Outcome] = dim_detail_outcome.outcome_of_case,
           [Damages Paid] = fact_finance_summary.damages_paid,
           --,[Total Settlement value]=fact_finance_summary.total_settlement_value_of_the_claim_paid_by_all_the_parties //// incorrect field for damages paid 
           fact_finance_summary.damages_paid [Total Settlement value],
           [Profit Costs Billed] = defence_costs_billed,
           [Disbs Billed] = fact_finance_summary.disbursements_billed,
		   [Unbilled Disbursements] = fact_finance_summary.disbursement_balance,
		   [Unpaid Bill Balance] = fact_finance_summary.unpaid_bill_balance,
           [WIP] = fact_finance_summary.wip,
           [Date Case Closed] = dim_matter_header_current.date_closed_case_management,
           [Date Case Opened] = dim_matter_header_current.date_opened_case_management,
           [Work Type Group] = CASE
                                   WHEN dim_matter_worktype.work_type_name LIKE 'EL%' THEN
                                       'EL'
                                   WHEN dim_matter_worktype.work_type_name LIKE 'PL%' THEN
                                       'PL'
                                   WHEN dim_matter_worktype.work_type_name LIKE 'Motor%' THEN
                                       'Motor'
                                   WHEN dim_matter_worktype.work_type_name LIKE 'Disease%' THEN
                                       'Disease'
                                   ELSE
                                       'Other'
                               END,
           -- Extra fields for the dashboard
           [Date initial report sent] = dim_detail_core_details.date_initial_report_sent,
           [Indemnity Saving] = ISNULL(fact_finance_summary.total_reserve, 0)
                                - ISNULL(fact_detail_paid_detail.damages_paid, 0)
                                + ISNULL(fact_finance_summary.total_tp_costs_paid, 0)
                                + ISNULL(fact_finance_summary.defence_costs_billed, 0),
           [Status] = CASE
                          WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN
                              'Open'
                          ELSE
                              'Closed'
                      END,
           [Total Reserve] = fact_detail_reserve.total_reserve,
           [Repudiated] = [dim_detail_outcome].[repudiated],
           [AXA Reason For Referal] = axa_reason_for_instruction,
           dim_matter_worktype.work_type_name,
           COALESCE(dim_detail_claim.dst_insured_client_name, client_ref.insuredclient_name) [Insured Name],
           tp_ref.claimant_name [Claimant Name],
           ISNULL(client_ref.[insuredclient_reference],insdref.reference) AS [Insured Client NEW Reference],
           -- damages claimed
           fact_finance_summary.total_reserve [Total Reserve (Current)],
           fact_finance_summary.damages_reserve_initial [Initial Reserve],
           --,fact_finance_summary.defence_costs_reserve_initial [Initial Defence Costs Reserve]
           fact_finance_summary.total_costs_paid [Total Costs Paid],
           fact_finance_summary.total_amount_billed [Total Defence Costs Charged ],
           fact_finance_summary.damages_reserve_net [Damages Reserve NET],
           tp_ref.claimant_reference,
           dim_defendant_involvement.defendant_name [Defendant Name ],
           fact_finance_summary.tp_costs_reserve_net [TPCost Reserve Net],
           fact_finance_summary.defence_costs_reserve_net [Defence costs reserve net ],
           fact_finance_summary.damages_reserve [Damages Reserve N],
           client_ref.insuredclient_name [Insured Name1 ],
           --,dim_client_involvement.insured_client_name AS 
           tp_ref.claimant_name [Claimant Name1 ],
           fact_finance_summary.damages_reserve [Damages Reserve 1],
           fact_finance_summary.damages_reserve_initial [Damages Reserve initial 1],
           fact_finance_summary.tp_costs_reserve_initial [initial Cost reserve 1],
           fact_finance_summary.total_reserve [Total Reserve 1],
           --[TP Costs Paid] = fact_finance_summary.total_tp_costs_paid,
		   [TP Costs Paid] = fact_finance_summary.claimants_costs_paid,
           fact_finance_summary.defence_costs_reserve_initial [defence_costs_reserve_initial1],
		   red_dw.dbo.fact_detail_reserve_initial.damages_reserve_init [init- damages reserve], 
		   red_dw.dbo.fact_detail_reserve_initial.claimant_costs_reserve_current_init [init- Claimant Cost Reserve ], 
		   fact_detail_reserve_initial.defence_costs_reserve_init [init defence cost reserve],



           --, fact_detail_paid_detail.personal_injury_paid [Personal Injury Paid] --MIB009
           --, fact_finance_summary.special_damages_miscellaneous_paid [Special Damages micellaneous] --NML118
           --,fact_detail_paid_detail.general_damages_paid [General damages ] --WPS278
		   fact_finance_summary.[damages_paid]  AS   [Damages Paid1]

		   , fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Claimant Costs Reserve Current]
		   , fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve]
		   , fact_finance_summary.[other_defendants_costs_reserve] AS [Other Defendants Costs Reserve]

		   , dim_detail_claim.[dst_claimant_solicitor_firm] AS [DST Claimant Solicitor Firm]
		   , dim_detail_claim.[dst_insured_client_name] AS [DST Insured Client Name]
		   , dim_detail_core_details.[do_clients_require_an_initial_report] AS [Initial Report Required?]
		   , dim_detail_core_details.[date_initial_report_due] AS [Date Initial Report Due]
		   , dim_detail_core_details.[does_claimant_have_personal_injury_claim] AS [Does the claimant have a PI claim?]
		   , last_bill_date AS [Date of Last Bill]
		   , last_time_transaction_date AS [Date Last Worked]
		   , dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
		   , CASE WHEN clients_claims_handler_surname_forename IN ('Spinks, Stephen','Lockheart, Steven','Bokhari, Iram','Rogers, Elizabeth','Nicolaou, Andy','Tuer, Robert') THEN 1 ELSE 0 END AS [London Casualty Team Matters]
		   , dim_detail_client.axa_instruction_type
		   ,fact_detail_elapsed_days.[elapsed_days_damages]
		   , fact_detail_elapsed_days.[elapsed_days_costs]


    FROM red_dw.dbo.fact_dimension_main
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
        INNER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client
            ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_client AS fact_client
            ON fact_client.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail AS fact_detail_reserve
            ON fact_detail_reserve.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.client_code = dim_matter_header_current.client_code
               AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner
            ON fee_earner.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement client_ref
            ON client_ref.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement tp_ref
            ON tp_ref.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail fact_detail_paid_detail
            ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
            ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
            ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
            ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
	 LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_initial 
			ON fact_detail_reserve_initial.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
			
			LEFT JOIN red_dw.dbo.dim_involvement_full clsol 
			ON clsol.dim_involvement_full_key = tp_ref.claimantsols_1_key

			LEFT JOIN red_dw.dbo.dim_involvement_full insrref
			ON insrref.dim_involvement_full_key = client_ref.insurerclient_1_key

			LEFT JOIN red_dw.dbo.dim_involvement_full insdref
			ON insdref.dim_involvement_full_key = client_ref.insuredclient_1_key

			LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
			ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

		 LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
            ON fact_detail_elapsed_days.client_code = dim_matter_header_current.client_code
			AND  fact_detail_elapsed_days.matter_number = dim_matter_header_current.matter_number
		



    WHERE ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
          AND dim_matter_header_current.matter_number <> 'ML'
          AND (dim_matter_header_current.master_client_code = 'A1001' OR dim_matter_header_current.master_client_code='220044')
          AND dim_matter_header_current.reporting_exclusions = 0
          AND dim_matter_header_current.date_opened_case_management >= '20170101'
          --AND dim_detail_core_details.date_instructions_received IS NOT NULL
		  --AND dim_matter_header_current.client_code='A1001' AND dim_matter_header_current.matter_number='00010136'

		  
    
    ORDER BY dim_matter_header_current.date_opened_case_management;



END;

GO
