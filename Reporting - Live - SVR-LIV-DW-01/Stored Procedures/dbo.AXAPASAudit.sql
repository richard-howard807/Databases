SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AXAPASAudit]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 

BEGIN

SELECT dim_matter_header_current.client_code AS Client
,dim_matter_header_current.matter_number AS Matter
,name AS [Weightmans FE]
,dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
,dim_matter_header_current.master_client_code +'-' + dim_matter_header_current.master_matter_number AS [Weightmans Ref]
,dim_matter_header_current.matter_description AS [Matter Description]

,dim_detail_audit.[axa_date_of_audit] AS [axa_date_of_audit]
,dim_detail_audit.[axa_was_an_extension_requested] AS [axa_was_an_extension_requested]
,dim_detail_audit.[axa_trial_date_entered_on_ms] AS [axa_trial_date_entered_on_ms]
,dim_detail_audit.[axa_reserve_reviewed_every_3_months] AS [axa_reserve_reviewed_every_3_months]
,dim_detail_audit.[axa_reason_complete_if_fallen_outside_pas] AS [axa_reason_complete_if_fallen_outside_pas]
,dim_detail_audit.[axa_part_36_offer_recorded_on_system] AS [axa_part_36_offer_recorded_on_system]
,dim_detail_audit.[axa_outcome_mi_completed_accurately_and_timely] AS [axa_outcome_mi_completed_accurately_and_timely]
,dim_detail_audit.[axa_mi_completed] AS [axa_mi_completed]
,dim_detail_audit.[axa_list_of_documents_sent_to_insured_client_for_approval] AS [axa_list_of_documents_sent_to_insured_client_for_approval]
,dim_detail_audit.[axa_initial_advice_sent_within_10_working_days] AS [axa_initial_advice_sent_within_10_working_days]
,dim_detail_audit.[axa_does_the_acknowledgment_contain_all_necessary_information] AS [axa_does_the_acknowledgment_contain_all_necessary_information]
,dim_detail_audit.[axa_disbs_over_1k_approved_by_axa_handler] AS [axa_disbs_over_1k_approved_by_axa_handler]
,dim_detail_audit.[axa_disbs_incurred_are_reasonable_and_proportionate] AS [axa_disbs_incurred_are_reasonable_and_proportionate]
,dim_detail_audit.[axa_defence_sent_to_insured_client_for_approval] AS [axa_defence_sent_to_insured_client_for_approval]
,dim_detail_audit.[axa_costs_strategy_document_completed] AS [axa_costs_strategy_document_completed]
,dim_detail_audit.[axa_correct_pas_status] AS [axa_correct_pas_status]
,dim_detail_audit.[axa_closure_document_sent_with_all_details_provided] AS [axa_closure_document_sent_with_all_details_provided]
,dim_detail_audit.[axa_claim_registered_with_cru] AS [axa_claim_registered_with_cru]
,dim_detail_audit.[axa_are_reserves_recorded_accurately_or_updated] AS [axa_are_reserves_recorded_accurately_or_updated]
,dim_detail_audit.[axa_any_applications_made_agreed_with_axa_handler] AS [axa_any_applications_made_agreed_with_axa_handler]
,dim_detail_audit.[axa_acknowledgment_sent_within_24_hours] AS [axa_acknowledgment_sent_within_24_hours]


FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=dim_matter_header_current.fee_earner_code COLLATE DATABASE_DEFAULT  AND dss_current_flag='Y'
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

        LEFT OUTER JOIN red_dw.dbo.dim_detail_audit
         ON dim_detail_audit.client_code = dim_matter_header_current.client_code
		 AND dim_detail_audit.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
       
        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
         ON dim_detail_client.client_code = dim_matter_header_current.client_code
		 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
           
    WHERE ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
          AND dim_matter_header_current.matter_number <> 'ML'
          AND dim_matter_header_current.master_client_code = 'A1001'
          AND dim_matter_header_current.reporting_exclusions = 0
          AND dim_matter_header_current.date_opened_case_management >= '20200701'
		  AND [axa_instruction_type]='PAS'
		  AND dim_detail_audit.[axa_date_of_audit] BETWEEN @StartDate AND @EndDate
 END  
GO
