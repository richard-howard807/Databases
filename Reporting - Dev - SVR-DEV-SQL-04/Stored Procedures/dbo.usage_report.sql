SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usage_report]
	-- Add the parameters for the stored procedure here
AS
BEGIN


;with allreports as ( 
 
 SELECT  c.Name,
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
allreports.Name ,
replace(replace(replace(path,'/Live/',''),'/LIVE/',''),'/'+allreports.Name,'') path, 
dim_employee.name,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist,
sum([no_of_runs]) [no_of_runs]
--[no_of_runs]
from allreports
left join  (select * from (
select 
distinct
name, 
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist,
Ltrim(rtrim(windowsusername)) windowsusername,
rank() over (partition by employeeid,windowsusername order by dss_update_time desc,activeud) [rank],
activeud
from red_Dw.dbo.dim_fed_hierarchy_history  
) dim_employee where [rank] =1 and windowsusername is not null  ) dim_employee on  allreports.UserName collate database_default = dim_employee.windowsusername collate database_default 

group by 
allreports.Name, 
path,
dim_employee.name,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist



END
GO
