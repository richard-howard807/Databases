SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_fact_detail_elapsed_days]
AS 

SELECT  [master_fact_key]
--      ,[source_system_id]
--      ,[client_code]
--      ,[matter_number]
--      ,[closure_time]
--      ,[days_elapsed_since_notification]
--      ,[days_to_closure_report]
--      ,[days_to_file_opened]
--      ,[days_to_report_outstanding]
--      ,[days_to_resolution]
--      ,[zurich_sub_to_sub]
--      ,[zurich_days_to_send_intitial_report]
--      ,[zurich_days_to_send_update_report]
--      ,[days_to_subsequent_report]
--      ,[elapsed_days_closed]
--      ,[elapsed_days_conclusion]
--      ,[elapsed_days_damages]
--      ,[elapsed_days_costs]
--      ,[elapsed_days_costs_received_to_settle]
--      ,[elapsed_days_costs_to_settle]
      ,[elapsed_days_live_files]
--      ,[elapsed_days]
--      ,[lifecycle_of_claim]
--      ,[num_days_to_resolution]
--      ,[target_settlement_days]
--      ,[updated_target_settlement_days]
--      ,[weeks_to_resolution]
--      ,[elapsed_days_aig]
--      ,[elapsed_days_date_concluded]
--      ,[elapsed_days_open_to_closed_case_management_system]
--      ,[elapsed_days_open_to_closed_practice_management_system]
--      ,[elapsed_days_live_case_management_system]
--      ,[elapsed_days_irf_requested_returned]
--      ,[dss_create_time]
--      ,[dss_update_time]
--      ,[turnaround_time]
--      ,[time_to_settle]
--      ,[loss_of_earnings_weeks_off]
--      ,[days_outstanding]
--      ,[days_to_send_report]
--      ,[days_to_settle]
--      ,[elapsed_days_base_investigations_completed]
--      ,[elapsed_days_bill]
--      ,[elapsed_days_live_practice_management_system]
  FROM [red_dw].[dbo].[fact_detail_elapsed_days] WITH (NOLOCK)



GO
