SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Litigation_SpecialityBilling_ds]
AS


SELECT 
dim_fed_hierarchy_history.hierarchylevel4hist as [matter_owner_team],
dim_detail_outcome.[outcome_of_case],
dim_matter_header_current.[branch_code],
branch_name,
dim_matter_header_current.[reporting_exclusions],
dim_client.[client_code],
dim_matter_header_current.[matter_number],
dim_client.[client_name],
dim_matter_header_current.[matter_description],
dim_matter_header_current.[matter_partner_full_name],
dim_fed_hierarchy_history.name [matter_owner_name],
dim_client_involvement.[personnel_name],
dim_matter_header_current.date_opened_case_management AS [matter_opened_case_management_calendar_date],
dim_matter_header_current.date_closed_case_management AS [matter_closed_case_management_calendar_date],
dim_detail_client.[status_present_postition],
dim_detail_core_details.[referral_reason],
fact_matter_summary_current.last_time_transaction_date AS [last_time_calendar_date],
fact_matter_summary_current.last_bill_date  AS [last_bill_calendar_date],
fact_finance_summary.[wip],
fact_finance_summary.[disbursements_billed],
fact_finance_summary.[disbursement_balance],
fact_finance_summary.[defence_costs_reserve],
fact_finance_summary.[vat_billed],
fact_finance_summary.[total_amount_billed],
fact_finance_summary.[damages_reserve],
fact_detail_reserve_detail.[claimant_costs_reserve_current],
fact_finance_summary.[total_reserve],
fact_finance_summary.[defence_costs_billed],
dim_matter_header_current.[ms_fileid],
dim_detail_outcome.[outcome],
[LiveClosed] = CASE WHEN fileStatus =  'LIVE' THEN 'Live'
                     WHEN fileStatus =  'DEAD' THEN 'Closed'
					 WHEN fileStatus = 'PENDCLOSE' THEN 'Pending Close' END

--, "Live",
--IF(dim_detail_outcome[outcome] = "ongoing", "Pending Close"

--, "Closed"))

 

FROM red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
JOIN red_dw.dbo.dim_detail_outcome
on dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.dim_matter_header_curr_key = fact_matter_summary_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN MS_Prod.config.dbFile ON dbFile.fileID=dim_matter_header_current.ms_fileid




WHERE 

dim_matter_header_current.[reporting_exclusions] = 0 
AND dim_matter_header_current.date_opened_case_management >= '2008-01-01'
AND (hierarchylevel4hist =  'Litigation Specialty'OR name = 'Amy Nesbitt')

order by dim_client.[client_code],
dim_matter_header_current.[matter_number]
GO
