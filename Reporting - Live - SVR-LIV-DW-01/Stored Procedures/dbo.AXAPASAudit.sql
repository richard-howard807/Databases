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

SELECT AllData.Client,
       AllData.Matter,
       AllData.[Weightmans FE],
       AllData.[Date Case Opened],
       AllData.[Weightmans Ref],
       AllData.[Matter Description],
       AllData.axa_date_of_audit,
       AllData.axa_was_an_extension_requested,
       AllData.axa_trial_date_entered_on_ms,
       AllData.axa_reserve_reviewed_every_3_months,
       AllData.axa_reason_complete_if_fallen_outside_pas,
       AllData.axa_part_36_offer_recorded_on_system,
       AllData.axa_outcome_mi_completed_accurately_and_timely,
       AllData.axa_mi_completed,
       AllData.axa_list_of_documents_sent_to_insured_client_for_approval,
       AllData.axa_initial_advice_sent_within_10_working_days,
       AllData.axa_does_the_acknowledgment_contain_all_necessary_information,
       AllData.axa_disbs_over_1k_approved_by_axa_handler,
       AllData.axa_disbs_incurred_are_reasonable_and_proportionate,
       AllData.axa_defence_sent_to_insured_client_for_approval,
       AllData.axa_costs_strategy_document_completed,
       AllData.axa_correct_pas_status,
       AllData.axa_closure_document_sent_with_all_details_provided,
       AllData.axa_claim_registered_with_cru,
       AllData.axa_are_reserves_recorded_accurately_or_updated,
       AllData.axa_any_applications_made_agreed_with_axa_handler,
       AllData.axa_acknowledgment_sent_within_24_hours
	,CASE WHEN  AllData.axa_was_an_extension_requested IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_trial_date_entered_on_ms IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_reserve_reviewed_every_3_months IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_part_36_offer_recorded_on_system IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_outcome_mi_completed_accurately_and_timely IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_mi_completed IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_list_of_documents_sent_to_insured_client_for_approval IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_initial_advice_sent_within_10_working_days IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_does_the_acknowledgment_contain_all_necessary_information IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_disbs_over_1k_approved_by_axa_handler IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_disbs_incurred_are_reasonable_and_proportionate IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_defence_sent_to_insured_client_for_approval IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_costs_strategy_document_completed IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_correct_pas_status IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_closure_document_sent_with_all_details_provided IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_claim_registered_with_cru IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_are_reserves_recorded_accurately_or_updated IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_any_applications_made_agreed_with_axa_handler IN ('Yes','N/A') THEN 1 ELSE 0 END +
    CASE WHEN   AllData.axa_acknowledgment_sent_within_24_hours IN ('Yes','N/A') THEN 1 ELSE 0 END AS NoGreen
	
	   
	   FROM (
SELECT dim_matter_header_current.client_code AS Client
,dim_matter_header_current.matter_number AS Matter
,name AS [Weightmans FE]
,dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
,dim_matter_header_current.master_client_code +'-' + dim_matter_header_current.master_matter_number AS [Weightmans Ref]
,dim_matter_header_current.matter_description AS [Matter Description]

,ms_prod..udAXAAudit.dteAXAAudit AS [axa_date_of_audit]
,CASE WHEN cboExtReq='YES' THEN 'Yes' WHEN cboExtReq='NO' THEN 'No' WHEN cboExtReq='NA' THEN 'N/A' ELSE cboExtReq END  AS [axa_was_an_extension_requested]
,CASE WHEN cboTrialDate='YES' THEN 'Yes' WHEN cboTrialDate='NO' THEN 'No' WHEN cboTrialDate='NA' THEN 'N/A' ELSE cboTrialDate END  AS [axa_trial_date_entered_on_ms]
,CASE WHEN cboRes3='YES' THEN 'Yes' WHEN cboRes3='NO' THEN 'No' WHEN cboRes3='NA' THEN 'N/A' ELSE cboRes3 END  AS [axa_reserve_reviewed_every_3_months]
,CASE WHEN cboReasonPAS='YES' THEN 'Yes' WHEN cboReasonPAS='NO' THEN 'No' WHEN cboReasonPAS='NA' THEN 'N/A' ELSE cboReasonPAS END  AS [axa_reason_complete_if_fallen_outside_pas]
,CASE WHEN cboPart36Off='YES' THEN 'Yes' WHEN cboPart36Off='NO' THEN 'No' WHEN cboPart36Off='NA' THEN 'N/A' ELSE cboPart36Off END  AS [axa_part_36_offer_recorded_on_system]
,CASE WHEN cboOutcomeMI='YES' THEN 'Yes' WHEN cboOutcomeMI='NO' THEN 'No' WHEN cboOutcomeMI='NA' THEN 'N/A' ELSE cboOutcomeMI END  AS [axa_outcome_mi_completed_accurately_and_timely]
,CASE WHEN cboMIComp='YES' THEN 'Yes' WHEN cboMIComp='NO' THEN 'No' WHEN cboMIComp='NA' THEN 'N/A' ELSE cboMIComp END  AS [axa_mi_completed]
,CASE WHEN cboCliApprove='YES' THEN 'Yes' WHEN cboCliApprove='NO' THEN 'No' WHEN cboCliApprove='NA' THEN 'N/A' ELSE cboCliApprove END  AS [axa_list_of_documents_sent_to_insured_client_for_approval]
,CASE WHEN cboInit10='YES' THEN 'Yes' WHEN cboInit10='NO' THEN 'No' WHEN cboInit10='NA' THEN 'N/A' ELSE cboInit10 END  AS [axa_initial_advice_sent_within_10_working_days]
,CASE WHEN cboAckInfo='YES' THEN 'Yes' WHEN cboAckInfo='NO' THEN 'No' WHEN cboAckInfo='NA' THEN 'N/A' ELSE cboAckInfo END  AS [axa_does_the_acknowledgment_contain_all_necessary_information]
,CASE WHEN cboDisbsAXA='YES' THEN 'Yes' WHEN cboDisbsAXA='NO' THEN 'No' WHEN cboDisbsAXA='NA' THEN 'N/A' ELSE cboDisbsAXA END  AS [axa_disbs_over_1k_approved_by_axa_handler]
,CASE WHEN cboDisbsProp='YES' THEN 'Yes' WHEN cboDisbsProp='NO' THEN 'No' WHEN cboDisbsProp='NA' THEN 'N/A' ELSE cboDisbsProp END   AS [axa_disbs_incurred_are_reasonable_and_proportionate]
,CASE WHEN cboDefSent='YES' THEN 'Yes' WHEN cboDefSent='NO' THEN 'No' WHEN cboDefSent='NA' THEN 'N/A' ELSE cboDefSent END  AS [axa_defence_sent_to_insured_client_for_approval]
,CASE WHEN cboCostStrat='YES' THEN 'Yes' WHEN cboCostStrat='NO' THEN 'No' WHEN cboCostStrat='NA' THEN 'N/A' ELSE cboCostStrat END  AS [axa_costs_strategy_document_completed]
,CASE WHEN cboCorrectPAS='YES' THEN 'Yes' WHEN cboCorrectPAS='NO' THEN 'No' WHEN cboCorrectPAS='NA' THEN 'N/A' ELSE cboCorrectPAS END  AS [axa_correct_pas_status]
,CASE WHEN cboCloseDoc='YES' THEN 'Yes' WHEN cboCloseDoc='NO' THEN 'No' WHEN cboCloseDoc='NA' THEN 'N/A' ELSE cboCloseDoc END  AS [axa_closure_document_sent_with_all_details_provided]
,CASE WHEN cboRegCRU='YES' THEN 'Yes' WHEN cboRegCRU='NO' THEN 'No' WHEN cboRegCRU='NA' THEN 'N/A' ELSE cboRegCRU END  AS [axa_claim_registered_with_cru]
,CASE WHEN cboResUpdated='YES' THEN 'Yes' WHEN cboResUpdated='NO' THEN 'No' WHEN cboResUpdated='NA' THEN 'N/A' ELSE cboResUpdated END  AS [axa_are_reserves_recorded_accurately_or_updated]
,CASE WHEN cboAppAXA='YES' THEN 'Yes' WHEN cboAppAXA='NO' THEN 'No' WHEN cboAppAXA='NA' THEN 'N/A' ELSE cboAppAXA END  AS [axa_any_applications_made_agreed_with_axa_handler]
,CASE WHEN cboAck24='YES' THEN 'Yes' WHEN cboAck24='NO' THEN 'No' WHEN cboAck24='NA' THEN 'N/A' ELSE cboAck24 END  AS [axa_acknowledgment_sent_within_24_hours]


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
        LEFT OUTER JOIN ms_prod..udAXAAudit
		 ON dim_matter_header_current.ms_fileid=fileID
    WHERE ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
          AND dim_matter_header_current.matter_number <> 'ML'
          AND dim_matter_header_current.master_client_code = 'A1001'
          AND dim_matter_header_current.reporting_exclusions = 0
          AND dim_matter_header_current.date_opened_case_management >= '20200701'
		  AND [axa_instruction_type]='PAS'
		  AND ms_prod..udAXAAudit.dteAXAAudit BETWEEN @StartDate AND @EndDate
 ) AS AllData
 END  
GO
