SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Max Taylor
-- Create date: 06/10/2022
-- Description:	Initial Create #171723 Whitbread Live Listings report
-- =============================================

CREATE PROCEDURE [dbo].[WhitbreadLiveListingsReport]

AS

SELECT 
[Weightmans Ref]                              = dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number
,[Claimant]                                   = matter_description
,[Brand:]                                     = dim_detail_client.[whitbread_brand]
,[Site:]                                      = dim_detail_practice_area.[whitbreadpizza_hut_site_address]
,[Tribunal:]                                  = dim_detail_court.[location_of_hearing]
,[Claims:]                                    = ISNULL(dim_detail_practice_area.[primary_case_classification], '') + ' ' + ISNULL(dim_detail_practice_area.[secondary_case_classification], '') + ' ' + ISNULL(dim_detail_client.[other_claims], '')
,[Date Weightmans instructed:]                = CAST(date_opened_case_management AS DATE)
,[Date of ET3:]                               =  ET3.key_date
,[Solictor Contact:]                          = dim_fed_hierarchy_history.name
,[Case Assistant:]                            = CaseAssistant.CaseAssistant
,[Fee estimate (excluding VAT & disbs):]      = fact_detail_paid_detail.[fee_estimate]
,[Current WIP:]                               = fact_finance_summary.wip
,[Billed Amount To Date exc VAT]              = ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.disbursements_billed, 0) 

,[Prospects of success:]                      = dim_detail_practice_area.[emp_prospects_of_success]
,[Rationale for prospects:]                   = dim_detail_client.[whitbread_reason_for_prospects_of_success]
,[Disclosure due:]                            = Disclosure.key_date
,[Witness statement due:]                     = Witness.key_date
,[Witnesses:]                                 = dim_detail_client.[witnesses]
,[Settlement offers:]                         = fact_detail_client.[whitbread_last_offer_made]
,[Instructions to Settle:]                    = dim_detail_client.[whitbread_do_we_have_instructions_to_settle]
,[Settlement Authority:]                      = fact_detail_client.[whitbread_settlement_authority]
,[Preliminary Hearing:]                       = COALESCE(dim_detail_court.[emp_date_of_preliminary_hearing_jurisdictionprospects],dim_detail_court.[emp_date_of_preliminary_hearing_case_management])
,[Final Hearing:]                             = dim_detail_court.[emp_date_of_final_hearing]
,work_type_group
,work_type_name
FROM red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT JOIN red_dw.dbo.dim_detail_practice_area
ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
LEFT JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_detail_client
ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

/* ET3 due Date*/
LEFT JOIN (
SELECT 
dim_matter_header_curr_key,
MAX(key_date) OVER(PARTITION BY dim_matter_header_curr_key) key_date FROM red_dw.dbo.dim_key_dates
WHERE type ='ET3'
) ET3 ON ET3.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

/* Disclosure due Date*/
LEFT JOIN (
SELECT 
dim_matter_header_curr_key,
MAX(key_date) OVER(PARTITION BY dim_matter_header_curr_key) key_date FROM red_dw.dbo.dim_key_dates
WHERE type ='DISC'
) Disclosure ON Disclosure.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

/*Witness statement due Date*/
LEFT JOIN (
SELECT 
dim_matter_header_curr_key,
MAX(key_date) OVER(PARTITION BY dim_matter_header_curr_key) key_date FROM red_dw.dbo.dim_key_dates
WHERE type IN ('EXCHWITSTAT','WITEVIDENCE')
) Witness ON Witness.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


/* Case Assistant*/
LEFT JOIN (
SELECT 
dim_matter_header_current.dim_matter_header_curr_key
, MAX(TimeRecordedBy.name) CaseAssistant
FROM red_dw.dbo.fact_bill_billed_time_activity 
INNER JOIN red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS TimeRecordedBy
 ON TimeRecordedBy.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
WHERE 1 =1 
AND minutes_recorded > 0 
GROUP BY dim_matter_header_current.dim_matter_header_curr_key

) CaseAssistant ON CaseAssistant.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
AND dim_fed_hierarchy_history.name <> CaseAssistant.CaseAssistant

WHERE 


reporting_exclusions = 0
AND fact_dimension_main.matter_number <> 'ML'
AND ISNULL(LOWER(RTRIM(outcome_of_case)),'') <> 'exclude from reports'
AND dim_matter_header_current.master_client_code = 'W15630'
AND TRIM(work_type_group) = 'EPI'
AND TRIM(dim_detail_core_details.[emp_litigatednonlitigated]) = 'Litigated'
AND dim_detail_outcome.[date_claim_concluded] IS NULL

GO
