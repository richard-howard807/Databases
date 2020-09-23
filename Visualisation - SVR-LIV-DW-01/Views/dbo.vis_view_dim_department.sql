SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[vis_view_dim_department]
AS 

SELECT [dim_department_key]
      --,[source_system_id]
      ,[department_code]
      ,[department_name]
      --,[dss_update_time]
  FROM [red_dw].[dbo].[dim_department] WITH (NOLOCK)


GO
