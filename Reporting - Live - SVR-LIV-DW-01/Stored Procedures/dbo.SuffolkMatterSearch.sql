SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SuffolkMatterSearch]
(
@BillingGroup AS NVARCHAR(MAX)
)
AS 
BEGIN 
SELECT
						dim_matter_header_current.[dim_matter_header_curr_key]
						,red_dw.dbo.dim_matter_header_current.client_code AS [client_code]
						,client_name AS [client_name]
						,dim_matter_header_current.[matter_number]
						,dim_matter_header_current.[matter_description]
						,branch_code AS [branch_code]
						,[matter_partner_full_name]
						,name AS [matter_owner_displayname]
						,hierarchylevel4hist AS [matter_owner_team]
						,[work_type_name]
						,dim_matter_header_current.date_opened_practice_management AS [matter_opened_practice_management_calendar_date]
						,dim_matter_header_current.date_closed_practice_management AS [matter_closed_practice_management_calendar_date]
						,last_bill_date AS  [last_bill_calendar_date]
						,last_time_transaction_date AS [last_time_calendar_date]
						,fact_detail_elapsed_days.[elapsed_days]
						,fact_finance_summary.[client_account_balance_of_matter]
						,fact_finance_summary.[disbursement_balance]
						,fact_finance_summary.[unpaid_bill_balance]
						,fact_finance_summary.[wip]
						,fact_finance_summary.[defence_costs_billed]
						,fact_finance_summary.[time_billed]
						,[matter_group_name]
						,CASE WHEN cboBillGroup='INDIVIDUAL' THEN 'Individual'
						WHEN cboBillGroup='Composite' THEN 'COMPOSITE' ELSE cboBillGroup END AS  [billing_group]
						FROM red_dw.dbo.dim_matter_header_current
						INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
						 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_group
 ON dim_matter_group.dim_matter_group_key = dim_matter_header_current.dim_matter_group_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN ms_prod.dbo.udMIClientSuffolkPolice
 ON ms_fileid=udMIClientSuffolkPolice.fileID
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
 ON fact_detail_elapsed_days.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number

WHERE master_client_code='817395'
AND ISNULL(cboBillGroup,'Missing')=@BillingGroup
AND dim_matter_header_current.date_closed_case_management IS NULL

END
GO
