SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_client]
AS 

SELECT [dim_client_key]
--      ,[source_system_id]
--      ,[client_code]
      ,[client_name]
      ,[client_group_name]
--      ,[client_partner_code]
      ,[client_partner_name]
--      ,[contact_salutation]
--      ,[contact_name]
--      ,[address_type]
--      ,[addresse]
--      ,[address_line_1]
--      ,[address_line_2]
--      ,[address_line_3]
--      ,[address_line_4]
--      ,[postcode]
--      ,[phone_number]
--      ,[dss_update_time]
--      ,[open_date]
      ,[sector]
--      ,[audit_alert]
--      ,[aml_failed]
--      ,[client_status]
--      ,[file_alert_message]
--      ,[credit_limit]
--      ,[client_type]
--      ,[aml_client_type]
      ,[client_group_code]
--      ,[email]
--      ,[branch]
--      ,[address_line_5]
--      ,[business_source]
--      ,[referrer_type]
      ,[sub_sector]
      ,[segment]
--      ,[business_source_name]
--      ,[created_by]
--      ,[practice_management_client_status]
--      ,[client_group_partner]
      ,[client_group_partner_name]
  FROM [red_dw].[dbo].[dim_client] WITH (NOLOCK)


GO
