SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_detail_finance]
AS 

SELECT  [dim_detail_finance_key]
--      ,[source_system_id]
--      ,[client_code]
--      ,[matter_number]
      ,[output_wip_fee_arrangement]
      ,[output_wip_percentage_complete]
--      ,[output_wip_percentage_of_completion]
--      ,[output_wip_issues]
--      ,[output_wip_percentage_complete_date_changed]
--      ,[dss_create_time]
--      ,[dss_update_time]
--      ,[colour_flag]
--      ,[adjustment]
--      ,[costs_in_house_outsourced]
--      ,[damages_banding]
--      ,[original_payment_date]
--      ,[payment_code]
--      ,[payment_code_adj]
--      ,[payment_descripiton]
--      ,[repudiated_payment]
--      ,[output_wip_issues_requires_clarification]
--      ,[output_wi_issue_ff]
--      ,[output_wip_issues_not_changed]
--      ,[output_wip_issues_possible_closure]
--      ,[output_wip_issues_ready_closure]
--      ,[output_wip_issues_final_bill_time_recorded]
--      ,[output_wip_issues_wip_exceeds_output_wip]
--      ,[output_wip_issues_wip_exceeds_ff_value]
--      ,[output_wip_issues_thirty_days]
--      ,[output_wip_issues_defence_costs_reserve_wip]
--      ,[output_wip_issues_defence_costs_reserve_fee]
--      ,[output_wip_issues_wip_days]
--      ,[output_wip_issues_billed_exceeds_ff]
--      ,[output_wip_issues_defence_costs_reserve]
--      ,[output_wip_issues_present_position]
  FROM [red_dw].[dbo].[dim_detail_finance] WITH (NOLOCK)


GO
