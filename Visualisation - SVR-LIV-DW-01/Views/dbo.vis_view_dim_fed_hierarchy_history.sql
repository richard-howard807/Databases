SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_fed_hierarchy_history]
AS 
SELECT  [dim_fed_hierarchy_history_key]
      ,[dim_employee_key]
--      ,[source_system_id]
      ,[fed_hierarchy_business_key]
      ,[fed_code]
--      ,[employeeid]
--      ,[activeud]
--      ,[fed_code_effective_start_date]
--      ,[jobtitle]
--      ,[fte]
--      ,[linemanageridud]
--      ,[linemanagername]
--      ,[reportingbcmidud]
      ,[reportingbcmname]
--      ,[worksforemployeeid]
      ,[worksforname]
--      ,[display_name]
      ,[name]
--      ,[windowsusername]
--      ,[hierarchynode]
--      ,[hierarchynodehist]
--      ,[hierarchylevel1hist]
      ,[hierarchylevel2hist]
      ,[hierarchylevel3hist]
      ,[hierarchylevel4hist]
--      ,[hierarchylevel5hist]
--      ,[hierarchylevel6hist]
--      ,[hierarchylevel1]
--      ,[hierarchylevel2]
--      ,[hierarchylevel3]
--      ,[hierarchylevel4]
--      ,[hierarchylevel5]
--      ,[hierarchylevel6]
--      ,[hierarchynodehistnorm]
--      ,[hierarchylevel1histnorm]
--      ,[hierarchylevel2histnorm]
--      ,[hierarchylevel3histnorm]
--      ,[hierarchylevel4histnorm]
--      ,[hierarchylevel5histnorm]
--      ,[hierarchylevel6histnorm]
--      ,[level]
--      ,[securitylevel]
--      ,[effective_start_date]
--      ,[leaver]
--      ,[warning_flag]
--      ,[hierarchynodehist_pre_francis]
--      ,[hierarchylevel1hist_pre_francis]
--      ,[hierarchylevel2hist_pre_francis]
--      ,[hierarchylevel3hist_pre_francis]
--      ,[hierarchylevel4hist_pre_francis]
--      ,[hierarchylevel5hist_pre_francis]
--      ,[hierarchylevel6hist_pre_francis]
--      ,[management_role_one]
--      ,[management_role_two]
--      ,[latest_hierarchy_flag]
--      ,[dss_update_time]
--      ,[dss_start_date]
--      ,[dss_end_date]
--      ,[dss_current_flag]
--      ,[dss_version]

  FROM [red_dw].[dbo].[dim_fed_hierarchy_history] WITH (NOLOCK)



GO
