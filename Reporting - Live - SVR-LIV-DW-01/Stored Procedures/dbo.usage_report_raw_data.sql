SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usage_report_raw_data] 

AS
BEGIN
;with allreports as ( 
 
 SELECT  c.Name,
 Description,
               c.[Path],
               l.ReportID,
               Ltrim(Rtrim(replace(UserName,'SBC\' ,'')) ) UserName, 
               l.TimeStart,
               l.TimeEnd,
               l.TimeProcessing,
               l.TimeRendering,
               l.Status,
               l.ByteCount,
			   

			   'SVR-liv-dwh-01' 'server',
case when l.ReportID is null then 0 else 1 end [no_of_runs]
FROM [ReportServer].[dbo].[Catalog](NOLOCK) AS c
left join [ReportServer].[dbo].[ExecutionLog](NOLOCK) AS l ON l.ReportID = C.ItemID and l.TimeStart >= DATEADD(Year,-1,getdate()) and UserName not in ('SBC\WEBAPP-MyWeightmans-','SBC\SQLalert','SBC\sqlservice','SBC\sqlsvcdwh01') and Format <>'EXCELOPENXML'
WHERE c.Type in (2,4) -- Only show reports 1=folder, 2=Report, 3=Resource, 4=Linked Report, 5=Data Source
and lower(path) like '/live/%'

union
SELECT  c.Name,
Description,
               c.[Path],
               l.ReportID,
               Ltrim(Rtrim(replace(UserName,'SBC\' ,'')) ) UserName, 
               l.TimeStart,
               l.TimeEnd,
               l.TimeProcessing,
         l.TimeRendering,
               l.Status,
               l.ByteCount,
			   'SQL2008SVR',
case when l.ReportID is null then 0 else 1 end [no_of_runs]
FROM [SQL2008SVR].[ReportServer].[dbo].[Catalog] AS c
left join [SQL2008SVR].[ReportServer].[dbo].[ExecutionLog] AS l ON l.ReportID = C.ItemID and l.TimeStart >= DATEADD(Year,-1,getdate()) and UserName not in ('SBC\WEBAPP-MyWeightmans-','SBC\SQLalert','SBC\sqlservice','SBC\sqlsvcdwh01') and Format <>'EXCELOPENXML'
WHERE c.Type in (2,4) -- Only show reports 1=folder, 2=Report, 3=Resource, 4=Linked Report, 5=Data Source
and lower(path) like '/live/%'

)
select 
ReportID,
result_fo_user.report,
result_fo_user.user_name,
result_fo_user.no_of_runs_by_user,
[no_of_runs_by_report],
last_time_run_by_user,
last_time_report_ran
from (
select 
Description ReportID,
allreports.Name report,
dim_employee.name user_name,
rank() over (partition by allreports.Name order by  sum([no_of_runs]) desc,max(TimeStart) desc  ) rank_by_user,
sum([no_of_runs]) [no_of_runs_by_user],
max(TimeStart) last_time_run_by_user
from allreports
left join  (select * from (
select 
distinct
name, 
Ltrim(rtrim(windowsusername)) windowsusername,
rank() over (partition by employeeid,windowsusername order by dss_update_time desc,activeud) [rank],
activeud
from red_Dw.dbo.dim_fed_hierarchy_history  
) dim_employee where [rank] =1 and windowsusername is not null  ) dim_employee on  allreports.UserName collate database_default = dim_employee.windowsusername collate database_default 
group by 
allreports.Name,
Description,
dim_employee.name
)  result_fo_user 
left join (select allreports.Name report, sum([no_of_runs]) [no_of_runs_by_report],max(TimeStart) last_time_report_ran from allreports group by allreports.Name ) result_by_report on result_by_report.report = result_fo_user.report 
where result_fo_user.rank_by_user = 1
END
GO
