SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Peter Asemota
-- ALTER date: <ALTER Date,,>
-- Description:	<Einstein Page Hits report detailing number of hits on Einsten>
-- =============================================

/*
  EXEC [Einstein].[PageHits_PA] '2012-06-01', '2013-01-15', 'ALL', 'All'
  EXEC [Einstein].[PageHits_PA_summary] '2012-09-01', '2013-01-15', 'HR&D', 'All'
  EXEC [Einstein].[PageHits_PA_summary_test_Cascade_V2] '2013-08-01', '2013-09-25','Information Systems,Commercial Dispute Resolution', 'Information Systems,Staff,Unknown,CDR Birmingham,CDR Liverpool,CDR Manchester'
*/


CREATE PROCEDURE [Einstein].[PageHits_PA_summary_test_Cascade_V2_new]

    --(
    -- @StartDate AS DATETIME
    --,@EndDate AS DATETIME
    --,@PracticeArea AS VARCHAR(Max)
    --,@Team AS VARCHAR(Max)
    --)
AS 
    
        
BEGIN

SELECT  UserName
       ,[Name]
       ,Team
       ,[PracticeArea]
       ,[TIMEStamp]
      -- ,URL
       ,SUM([Page Hits]) AS [Total Hits]
       --,ROW_NUMBER() OVER(PARTITION BY UserName ORDER BY SUM([Page Hits]) DESC) AS [RowID]
       ,ROW_NUMBER() OVER(ORDER BY SUM([Page Hits]) DESC) AS [RowID]
       FROM (


SELECT  
--[TimeStamp]
 SiteURL + '/' + WebURL + '/' + DocUrl AS URL
,UserName
, RTRIM(REPLACE(UserName,'sbc\','')) AS TrimmeduserName
,Users.KnownAs + '  ' + Users.Surname AS [Name]
,hierarchy.HierarchyLevel2 AS Businessline
,hierarchy.HierarchyLevel3 AS PracticeArea
,hierarchy.HierarchyLevel4 AS Team
, pathsplit.*
, DocUrl
, COUNT(*) AS [Page Hits]
,[TIMEStamp] AS [TIMEStamp]
FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog WITH (NOLOCK)
  OUTER APPLY dbo.udt_TallySplit_Flat('/', WSSUsageLog.WebURL) AS pathsplit
  INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
  INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
        LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode
  LEFT JOIN  [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
  LEFT JOIN Accounts.Structure AS Structure
            ON cast(Users.EmployeeID as nvarchar(36)) = Structure.employeeid
           AND Structure.rlActive = 1 
 --  INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
 --  INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default                   

       
WHERE WebURL <> ''
AND   DocUrl NOT LIKE '%.png'
AND DocUrl NOT LIKE '%.css'
AND DocUrl NOT LIKE '%.gif'
AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
--AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
--AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'

GROUP BY 
 SiteURL
 ,WebURL
,UserName
, RTRIM(REPLACE(UserName,'sbc\',''))  
,Users.KnownAs 
,Users.Surname
,hierarchy.HierarchyLevel2 
,hierarchy.HierarchyLevel3 
,hierarchy.HierarchyLevel4 
,  pathsplit.col1 ,
   pathsplit.col2 ,
   pathsplit.col3 ,
   pathsplit.col4 ,
   pathsplit.col5 ,
   pathsplit.col6
, DocUrl
,[TimeStamp]
) AS Data

GROUP BY UserName
         ,[Name]
         ,Team
         ,[PracticeArea]
         ,[TIMEStamp]
         --,URL
ORDER BY SUM([Page Hits]) DESC

END


GO
