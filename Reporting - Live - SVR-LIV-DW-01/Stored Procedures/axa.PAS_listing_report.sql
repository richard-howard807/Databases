SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [axa].[PAS_listing_report]
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
           [TP Costs Paid] = fact_finance_summary.total_tp_costs_paid,
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
		   , dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
		   , dim_detail_core_details.[does_claimant_have_personal_injury_claim] AS [Does the claimant have a PI claim?]
		   , last_bill_date AS [Date of Last Bill]
		   , last_time_transaction_date AS [Date Last Worked]
		   ,dim_detail_client.[axa_instruction_type]
		   ,dim_detail_core_details.[axa_pas_action]
		   ,HrsBilled.HrsBilled
		   ,dim_detail_claim.[axa_claim_stage]
		   ,fact_detail_elapsed_days.[elapsed_days_damages]
		   , fact_detail_elapsed_days.[elapsed_days_costs]
		   ,fee_earner.hierarchylevel4hist AS [Team]
		 ,CASE 		 WHEN dim_detail_core_details.[axa_pas_status] IN ('Outside PAS','Removed from PAS') THEN 'Outside PAS'
		 WHEN dim_detail_core_details.[axa_pas_status]='PAS' AND 
		 (suspicion_of_fraud='Yes' OR fee_earner.hierarchylevel4hist='Motor Fraud' OR fact_finance_summary.[damages_reserve] >= 50000) THEN 'Possible Outside PAS files'
		 WHEN dim_detail_core_details.[date_initial_report_sent] IS NULL THEN 'Initial Report due Tab'
		 WHEN dim_detail_core_details.[date_initial_report_sent] IS NOT NULL THEN 'Initial Report Sent Tab'
		 END AS SLATab
		 , dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report]
		 , dim_detail_practice_area.[date_report_due] 
		 ,CASE 
			WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NOT NULL THEN 
				[dbo].[AddWorkDaysToDate](CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE), 10)
			WHEN dim_detail_core_details.date_initial_report_due IS NULL THEN 
				[dbo].[AddWorkDaysToDate](CAST(dim_matter_header_current.date_opened_practice_management AS date), 10)
			ELSE 
				dim_detail_core_details.date_initial_report_due 
			END						AS [NEW_initial_report_due]
		 ,dim_detail_core_details.[axa_reason_outside_of_pas]
		 ,suspicion_of_fraud
		 ,fact_finance_summary.[damages_reserve]

,CASE  WHEN dim_detail_core_details.[date_initial_report_sent] IS NULL  THEN 
        	(DATEDIFF(dd, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management), GETDATE()))-- + 1)
			-(DATEDIFF(wk, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management), GETDATE()) * 2)
			-(CASE WHEN DATENAME(dw, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management)) = 'Sunday' THEN 1 ELSE 0 END)
			-(CASE WHEN DATENAME(dw, GETDATE()) = 'Saturday' THEN 1 ELSE 0 END)
			 ELSE NULL END AS OpenToNow

,CASE  WHEN dim_detail_core_details.[date_initial_report_sent] IS NOT NULL  THEN 
        	(DATEDIFF(dd, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management), dim_detail_core_details.[date_initial_report_sent]))-- + 1)
			-(DATEDIFF(wk, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management), dim_detail_core_details.[date_initial_report_sent]) * 2)
			-(CASE WHEN DATENAME(dw, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management)) = 'Sunday' THEN 1 ELSE 0 END)
			-(CASE WHEN DATENAME(dw, dim_detail_core_details.[date_initial_report_sent]) = 'Saturday' THEN 1 ELSE 0 END)
			 ELSE NULL END AS OpenToSent

,dbo.ReturnElapsedDaysExcludingBankHolidays(COALESCE(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers, dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_practice_management), dim_detail_core_details.date_initial_report_sent) 	AS [NewOpenToSent]

,CASE  WHEN dim_detail_core_details.[date_initial_report_sent] IS NOT NULL  THEN 
        	(DATEDIFF(dd, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management), dim_detail_practice_area.[date_report_due] ))-- + 1)
			-(DATEDIFF(wk, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management), dim_detail_practice_area.[date_report_due] ) * 2)
			-(CASE WHEN DATENAME(dw, COALESCE(dim_detail_core_details.[date_instructions_received],dim_matter_header_current.date_opened_case_management)) = 'Sunday' THEN 1 ELSE 0 END)
			-(CASE WHEN DATENAME(dw, dim_detail_practice_area.[date_report_due] ) = 'Saturday' THEN 1 ELSE 0 END)
			 ELSE NULL END AS OpenToExtension

--ES #71990
, dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date Papers Received]

, CASE WHEN dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report]='Yes' 
THEN dbo.ReturnElapsedDaysExcludingBankHolidays(GETDATE(),dim_detail_core_details.[date_initial_report_due]) 
ELSE dbo.ReturnElapsedDaysExcludingBankHolidays( COALESCE(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers, dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_practice_management), GETDATE()) END	AS [DaysDue]

,CASE WHEN dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report]='Yes' 
THEN dbo.ReturnElapsedDaysExcludingBankHolidays(dim_detail_core_details.[date_initial_report_due],dim_detail_core_details.[date_initial_report_sent])
ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(COALESCE(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers, dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_practice_management), dim_detail_core_details.date_initial_report_sent) END AS [DaysToSend]


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
        LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
            ON fact_detail_elapsed_days.client_code = dim_matter_header_current.client_code
			AND  fact_detail_elapsed_days.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
            ON dim_detail_practice_area.client_code = dim_matter_header_current.client_code
			AND  dim_detail_practice_area.matter_number = dim_matter_header_current.matter_number

			

			
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
		        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
            ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
        LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
            ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
	 LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_initial 
			ON fact_detail_reserve_initial.master_fact_key = fact_dimension_main.master_fact_key
			
			LEFT JOIN red_dw.dbo.dim_involvement_full clsol 
			ON clsol.dim_involvement_full_key = tp_ref.claimantsols_1_key

			LEFT JOIN red_dw.dbo.dim_involvement_full insrref
			ON insrref.dim_involvement_full_key = client_ref.insurerclient_1_key

			LEFT JOIN red_dw.dbo.dim_involvement_full insdref
			ON insdref.dim_involvement_full_key = client_ref.insuredclient_1_key

			LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
			ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

	LEFT OUTER JOIN 
	(
	SELECT client_code,matter_number
,SUM(BillHrs) AS HrsBilled
FROM  red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_bill
ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
        LEFT OUTER JOIN TE_3E_Prod.dbo.TimeBill
            ON TimeCard = fact_bill_billed_time_activity.transaction_sequence_number
               AND TimeBill.timebillindex = fact_bill_billed_time_activity.timebillindex
WHERE  dim_matter_header_current.master_client_code = 'A1001'
AND dim_matter_header_current.date_opened_case_management >= '20200701'
GROUP BY client_code,matter_number
	) AS HrsBilled
	 ON HrsBilled.client_code = dim_matter_header_current.client_code
	 AND HrsBilled.matter_number = dim_matter_header_current.matter_number



    WHERE ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
          AND dim_matter_header_current.matter_number <> 'ML'
          AND dim_matter_header_current.master_client_code = 'A1001'
          AND dim_matter_header_current.reporting_exclusions = 0
          AND dim_matter_header_current.date_opened_case_management >= '20200701'
		  AND [axa_instruction_type]='PAS'
         
		  
    




END;

GO
