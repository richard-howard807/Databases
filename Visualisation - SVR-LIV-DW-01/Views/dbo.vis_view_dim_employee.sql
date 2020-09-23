SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[vis_view_dim_employee]
AS 

SELECT  [dim_employee_key]
--      ,[payrollid]
--      ,[displayemployeeid]
--      ,[employeeid]
--      ,[sequence]
--      ,[forename]
--      ,[surname]
--      ,[othername]
--      ,[initials]
--      ,[knownas]
--      ,[title]
--      ,[workemail]
--      ,[worksforemail]
      ,[locationidud]
--      ,[workphone]
--      ,[windowsusername]
--      ,[fed_login]
--      ,[nt_login]
--      ,[levelidud]
--      ,[postid]
--      ,[leaverlastworkdate]
--      ,[admissiondateud]
--      ,[admissiontypeud]
--      ,[photofilename]
--      ,[dss_create_time]
--      ,[dss_update_time]
--      ,[secretaryud]
--      ,[contracttype]
--      ,[jobtitle]
--      ,[classification]
--      ,[rolematrixlevelud]
--      ,[fte]
  FROM [red_dw].[dbo].[dim_employee] WITH (NOLOCK)


GO
