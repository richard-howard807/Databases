SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW [dbo].[vis_view_fact_matter_summary_current]
AS 

SELECT  [dim_fed_hierarchy_history_key]
      ,[dim_matter_header_history_key]
      ,[dim_matter_header_curr_key]
      ,[dim_client_key]
      ,[dim_date_key]
      ,[dim_open_practice_management_date_key]
      ,[dim_closed_practice_management_date_key]
      ,[dim_open_case_management_date_key]
      ,[dim_closed_case_management_date_key]
--      ,[client_code]
--      ,[matter_number]
--      ,[fee_earner_fed_code]
--      ,[date_opened_practice_management]
--      ,[date_closed_practice_management]
--      ,[date_opened_case_management]
--      ,[date_closed_case_management]
--      ,[disbursement_balance]
      ,[client_account_balance_of_matter]
--      ,[number_unpaid_bills]
--      ,[number_bills_matter]
--      ,[unpaid_bill_balance]
--      ,[deposit_account_balance]
--      ,[wip_balance]
--      ,[costs_to_date]
      ,[time_billed]
--      ,[unbilled_time]
--      ,[fin_month]
--      ,[closed_practice_management]
--      ,[closed_case_management]
--      ,[matter_count]
--      ,[open_practice_management]
--      ,[open_case_management]
--      ,[closed_practice_management_month]
--      ,[closed_case_management_month]
--      ,[open_case_management_month]
--      ,[open_practice_management_month]
--      ,[closed_practice_management_fin_ytd]
--      ,[closed_case_management_fin_ytd]
--      ,[open_case_management_fin_ytd]
--      ,[open_practice_management_fin_ytd]
--      ,[fact_matter_summary_key]
--      ,[dss_update_time]
      ,[last_bill_date]
--      ,[dim_last_bill_date_key]
--      ,[dim_last_transaction_date_key]
      ,[master_fact_key]
--      ,[no_future_tasks]
--      ,[overdue_tasks]
--      ,[number_of_exceptions]
--      ,[critical_exceptions]
      ,[last_time_transaction_date]
--      ,[last_bill_total]
--      ,[number_of_exceptions_mi]
--      ,[critical_exceptions_mi]
--      ,[client_account_last_posting_date]
--      ,[disbursements_only_flag]
--      ,[dim_last_posting_date_key]
  FROM [red_dw].[dbo].[fact_matter_summary_current] WITH (NOLOCK)
  


GO
