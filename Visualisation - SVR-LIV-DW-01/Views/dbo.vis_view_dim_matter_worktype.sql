SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_matter_worktype]
AS 

SELECT  [dim_matter_worktype_key]
    --,[source_system_id]
      ,[work_type_code]
      ,[work_type_name]
    --,[dss_update_time]
      ,[work_type_group]
  FROM [red_dw].[dbo].[dim_matter_worktype] WITH (NOLOCK)


GO
