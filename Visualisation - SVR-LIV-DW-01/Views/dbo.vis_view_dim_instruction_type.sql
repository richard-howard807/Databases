SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_instruction_type]
AS 

SELECT  [dim_instruction_type_key]
      ,[instruction_type]
      --,[dss_create_time]
      --,[dss_update_time]
  FROM [red_dw].[dbo].[dim_instruction_type] WITH (NOLOCK)



GO
