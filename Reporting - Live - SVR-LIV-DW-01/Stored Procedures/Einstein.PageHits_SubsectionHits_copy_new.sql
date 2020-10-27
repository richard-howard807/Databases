SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
  EXEC [Einstein].[PageHits_SubsectionHits_copy] '2012-06-01','2013-04-15'
  EXEC [Einstein].[PageHits_SubsectionHits_copy_new] '1900-01-01', '9999-01-01','Information Systems,Commercial Dispute Resolution,Transport', 'Information Systems,Staff,Unknown,CDR Birmingham,CDR Liverpool,CDR Manchester'

*/

CREATE PROCEDURE [Einstein].[PageHits_SubsectionHits_copy_new]

  --(
     --@StartDate AS DATETIME
    --,@EndDate AS DATETIME
   -- ,@PracticeArea AS VARCHAR(Max)
   -- ,@Team AS VARCHAR(Max)
  --  )

AS
              
 -- Litigation - done
       SELECT 
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Guide to file handling' AS SubCategory 
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
          INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON CAST(users.EmployeeID AS NVARCHAR(36)) = structure.employeeID AND Structure.rlActive = 1
           -- INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
           -- INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/file_handling'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
        --  AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
        --  AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
           ,  UserName
           ,  Structure.KnownAs + ' ' + Structure.Surname 
           ,  hierarchy.HierarchyLevel3 
           ,  hierarchy.HierarchyLevel4
           , [TIMEStamp]
          
         UNION ALL

         SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Litigation In Person' AS SubCategory 
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
         INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON CAST(users.EmployeeID AS NVARCHAR(36)) = structure.employeeID AND Structure.rlActive = 1
           -- INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
            --INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
        --  AND WebURL LIKE 'litigation/litigation_general/file_handling%'
          AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
        --  AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
         -- AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          GROUP BY SiteUrl,WebURL,DocUrl
                    , UserName
                    ,  Structure.KnownAs + ' ' + Structure.Surname 
                    ,  hierarchy.HierarchyLevel3 
                    ,  hierarchy.HierarchyLevel4 
                    , [TIMEStamp] 
           
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Civil Procedure Rule' AS SubCategory
                ,WebURL AS WebURL
                ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
          INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON CAST(users.EmployeeID AS NVARCHAR(36)) = structure.employeeID AND Structure.rlActive = 1
          --  INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
          --  INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/file_handling/civil_procedure_rules%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
        --  AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
        --  AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          
            UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Pre-action' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON CAST(users.EmployeeID AS NVARCHAR(36)) = structure.employeeID AND Structure.rlActive = 1
           -- INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
           -- INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/Pre-action'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
        --  AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
         -- AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                   ,hierarchy.HierarchyLevel3 
                   ,hierarchy.HierarchyLevel4 
                   , [TIMEStamp] 
          
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Limitation' AS SubCategory
                ,WebURL AS WebURL
                ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
           FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON CAST(users.EmployeeID AS NVARCHAR(36)) = structure.employeeID AND Structure.rlActive = 1
          --  INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
          --  INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/limitation'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
       --   AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4 
                  ,[TIMEStamp] 
          
          UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Case Management' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
          INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON CAST(users.EmployeeID AS NVARCHAR(36)) = structure.employeeID AND Structure.rlActive = 1
          --  INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
          --  INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/case_management/case management%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
       --   AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                    ,Structure.KnownAs + ' ' + Structure.Surname 
                    ,hierarchy.HierarchyLevel3 
                    ,hierarchy.HierarchyLevel4
                    ,[TIMEStamp]  
          
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Services' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
           INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
          --  INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
          --  INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/service'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
       --   AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
        --  AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                   ,hierarchy.HierarchyLevel3 
                   ,hierarchy.HierarchyLevel4 
                   ,[TIMEStamp] 
          
            UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Start Proceedings' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
          --  INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
           -- INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/starting_proceedings'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          
           UNION ALL
   
       
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Responding To A Claim' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
           INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
          --  INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
          --  INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/responding_to_a_claim/responding_to_a_claim%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
       --   AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
       --   AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 , [TIMEStamp]  
          
            UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Admissions' AS SubCategory
                ,WebURL AS WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
             INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
         --   INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/admissions'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 , [TIMEStamp] 
          
          
            UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Defence and Reply' AS SubCategory
                ,WebURL AS WebURL
                ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/defence_and_reply'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Counter Claims' AS SubCategory
                ,WebURL AS WebURL
                ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/counterclaims'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Statement Of Case' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                   INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/statement_of_case'
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp] 
          
            UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Summary Judgment' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                   INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'summary_judgment%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                   ,hierarchy.HierarchyLevel3 
                   ,hierarchy.HierarchyLevel4 
                   ,[TIMEStamp] 
          
            
            UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Allocation' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
               ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                 INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/allocation'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 , [TIMEStamp] 
          
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Disclosure & Inspection' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
               INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/disclosure_and_inspection'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
   --       AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Evidence' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
         --   INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/evidence'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
   --       AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
   --       AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          
          UNION ALL
          
          SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Offers to Settle' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                       INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
         --   INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/Offers_to_Settle'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 , [TIMEStamp]
          
          UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Experts' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                        INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/experts'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
   --       AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
   --       AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          
           UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Discontinuance' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                          INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/discontinuance'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
  --        AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
  --        AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          
          UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Damages and Quantum' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                          INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/damages_and_quantum'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
  --        AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
  --        AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          
          UNION ALL
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Litigation' AS Section
                 ,'Litigation General' AS Category
                 ,'Costs' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                         INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'litigation/litigation_general/costs'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
   --       AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          
          UNION ALL
      /* Practice Area  now know as Insurance*/     
          

          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Insurance' AS Section
                 ,'Disease' AS Category
                 ,'Professional Support' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                ,[TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                     INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12)='default.aspx'
          AND WebURL LIKE 'insurance/disease/professional_support/%'  
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteURL,WebURL,DocUrl
                   ,UserName
                    ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          
          UNION ALL
          
          
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Insurance' AS Section
                 ,'Disease' AS Category
                 ,'Pre-Litigation' AS SubCategory
                 ,WebURL AS WebURL
                 ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl,SiteUrl
                ,COUNT(*) AS [No litigation in person] 
                ,[TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                     INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12)='default.aspx'
          AND WebURL LIKE 'insurance/disease/pre-litigation/%'  
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteURL,WebURL,DocUrl
                   ,UserName
                    ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp] 
          
          UNION ALL
          
          SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Insurance' AS Section
                 ,'Large Loss' AS Category
                 ,'Clients' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                     INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
      --      INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12)='default.aspx'
          --AND DocUrl LIKE '%large_loss/default.aspx'
          AND WebURL LIKE 'insurance/large_loss/clients%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl   
          
     
          UNION ALL
          
          SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Insurance' AS Section
                 ,'Large Loss' AS Category
                 ,'Governance' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                     INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12)='default.aspx'
          --AND DocUrl LIKE '%large_loss/default.aspx'
          AND WebURL LIKE 'insurance/large_loss/governance%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp] 
          --,DocUrl   
          
     
          UNION ALL
          
          SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Insurance' AS Section
                 ,'Large Loss' AS Category
                 ,'Professional Support' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                     INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12)='default.aspx'
          --AND DocUrl LIKE '%large_loss/default.aspx'
          AND WebURL LIKE 'insurance/large_loss/professional_support%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
   --       AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          --,DocUrl   
          
     
          UNION ALL
          
          
          SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Insurance' AS Section
                 ,'Large Loss' AS Category
                 ,'Technical Guidance' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                     INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12)='default.aspx'
          --AND DocUrl LIKE '%large_loss/default.aspx'
          AND WebURL LIKE 'insurance/large_loss/technical_guidance%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp]  
          --,DocUrl   
          
     
          UNION ALL
          
 -- commercial 
 
      SELECT       SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial and Corporate' AS Category
                 ,'Merger and Acquisition' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
               -- ,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                      INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,17) LIKE 'acquisitions.aspx'
          AND WebURL LIKE 'commercial/corporate_and_commercial%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          --,DocUrl
          
         UNION ALL
         
        
      SELECT       SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial and Corporate' AS Category
                 ,'Commercial' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                    INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'default.aspx'
          AND WebURL LIKE 'commercial/corporate_and_commercial/commercial'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
  --        AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
   --       AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          --,DocUrl
          
          UNION ALL 
          
          SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial and Corporate' AS Category
                 ,'Glossaries' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
               -- ,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                        INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,15) LIKE 'glossaries.aspx'
          AND WebURL LIKE 'commercial/corporate_and_commercial/commercialglossaries'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                   ,hierarchy.HierarchyLevel3 
                   ,hierarchy.HierarchyLevel4
                   ,[TIMEStamp]  
          --,DocUrl
          
          UNION ALL 
          
           SELECT SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial and Corporate' AS Category
                 ,'Training' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                      INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'default.aspx'
          AND WebURL LIKE 'commercial/corporate_and_commercial/training'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          --,DocUrl 
         
      UNION ALL
         
             SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Protocol Letters For Action' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                -- ,DocUrl
                ,COUNT(*) AS [No litigation in person] 
                ,[TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                    INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,18) LIKE 'before action.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                    ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp] 
          --,DocUrl 
         
        UNION ALL
         
             SELECT  SiteUrl AS SiteURL
                    ,SUBSTRING(WebURL, 1, 15) AS URL
                    ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                     ,'Einstein' AS Website
                     ,'Commercial' AS Section
                     ,'Commercial Dispute Regulation' AS Category
                     ,'Intellectual Letters  Before For Action' AS SubCategory
                     ,WebURL
                     ,UserName AS Username
                     ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                     ,hierarchy.HierarchyLevel3 AS PracticeArea
                     ,hierarchy.HierarchyLevel4 AS Team
                  --, DocUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                 INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,11) LIKE 'client.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl  
         
        UNION ALL
         
             SELECT   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Mediation' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                       INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
    --       INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
     --      INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,14) LIKE 'mediation.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                     ,hierarchy.HierarchyLevel3 
                     ,hierarchy.HierarchyLevel4 
                     , [TIMEStamp] 
          --,DocUrl  
         
          UNION ALL
         
             SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Pre- Action Disclosure' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                         INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,19) LIKE 'correspondence.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl
         
         UNION ALL
         
             SELECT     
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Funding and CFAs' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                           INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,9) LIKE 'cfas.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 , [TIMEStamp] 
          
         UNION ALL
         
             SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Claim Form' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
           FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                          INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,15) LIKE 'claim form.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          --,DocUrl 
          
       UNION ALL
         
             SELECT       
                   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Ordinary Application' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                   ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                              INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,17) LIKE 'applications.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                    ,UserName
                     ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl     
          
      
     UNION ALL
         
             SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Injunctions' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                   ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,16) LIKE 'injunctions.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                     ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp]
          --,DocUrl  
           /* pete stopped here - update continiues from here*/
          UNION ALL
         
             SELECT       
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Disclosure' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,16) LIKE '/disclosure.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4
                  ,[TIMEStamp] 
          --,DocUrl 
          
       UNION ALL
         
             SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Witness Evidence' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,21) LIKE 'witness evidence.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                   ,hierarchy.HierarchyLevel3 
                   ,hierarchy.HierarchyLevel4 
                   ,[TIMEStamp] 
          --,DocUrl 
          
      UNION ALL
         
             SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Commercial Part 36 Letters' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
              INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,28) LIKE 'letters and calderbanks.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
       --   AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                   ,hierarchy.HierarchyLevel3 
                   ,hierarchy.HierarchyLevel4 
                   , [TIMEStamp] 
          --,DocUrl       
         
         UNION ALL
         
             SELECT      
                   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Expert Evidence' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                ,hierarchy.HierarchyLevel3 AS PracticeArea
                ,hierarchy.HierarchyLevel4 AS Team
              --  ,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,21) LIKE '/expert evidence.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
       --   AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl  
          
       UNION ALL
         
             SELECT       
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Settlement Agreement' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                  INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,26) LIKE 'settlement agreements.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
       --   AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
       --   AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                ,hierarchy.HierarchyLevel3 
                ,hierarchy.HierarchyLevel4
                , [TIMEStamp]  
          --,DocUrl    
         
         
        UNION ALL
         
             SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Appeals' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                    INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'appeals.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                   ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4
                  , [TIMEStamp]  
          --,DocUrl 
         
      UNION ALL
         
             SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Commercial Dispute Regulation' AS Category
                 ,'Enforcement' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                   INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,16) LIKE 'enforcement.aspx'
          AND WebURL LIKE 'commercial/commercial_dispute_resolution%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl 
          
        UNION ALL  
          --employment   
              SELECT       
                   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Employment' AS Category
                 ,'Know How' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                  INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,8) LIKE 'how.aspx'
          AND WebURL LIKE 'commercial/employment%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                    ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 , [TIMEStamp] 
          --,DocUrl 
         
         UNION ALL  
          --employment   
              SELECT       
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Employment' AS Category
                 ,'Sector and Sector Leads' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
     --       INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
      --      INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,10) LIKE 'leads.aspx'
          AND WebURL LIKE 'commercial/employment%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp] 
          --,DocUrl
         
       UNION ALL  
          --employment   
              SELECT      
                   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Employment' AS Category
                 ,'Legislation - New' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
               -- ,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                    INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,8) LIKE 'new.aspx'
          AND WebURL LIKE 'commercial/employment/legislation%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp]  
          --,DocUrl 
          
       UNION ALL  
          --employment   
              SELECT      
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Employment' AS Category
                 ,'Legislation - Pipeline' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                    INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'default.aspx'
          AND WebURL LIKE 'commercial/employment/legislation_pipeline%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp] 
          --,DocUrl     
            
    
     UNION ALL  
          --employment   
              SELECT       
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Employment' AS Category
                 ,'Appeal Cases' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                      INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
      --      INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'default.aspx'
          AND WebURL LIKE 'commercial/employment/appeal_cases'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl 
          
       UNION ALL  
          --employment   
              SELECT       
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Employment' AS Category
                 ,'Employment Tribunal' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
               ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                         INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'default.aspx'
          AND WebURL LIKE 'commercial/employment/employment_tribunal'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp]  
          --,DocUrl 
          
           UNION ALL  
          --employment   
              SELECT       
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Employment' AS Category
                 ,'Tenders' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person] 
                ,[TIMEStamp] AS [Timestamp]
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                      INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
    --        INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
     --       INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'default.aspx'
          AND WebURL LIKE 'commercial/employment/tenders'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                    ,UserName
                    ,Structure.KnownAs + ' ' + Structure.Surname 
                    ,hierarchy.HierarchyLevel3 
                    ,hierarchy.HierarchyLevel4 
                    , [TIMEStamp]
          --,DocUrl       
         
         UNION ALL
         
         -- Real Estate
         
           SELECT      
                   SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Real Estate' AS Category
                 ,'' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
               INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
     --       INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,11) LIKE 'estate.aspx'
          AND WebURL LIKE 'commercial/general'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp]  
          --,DocUrl  
          
    -- Restructuring  
         Union ALL    
        
            SELECT  
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Restructuring/Insolvency' AS Category
                 ,'corporate Insolvency' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
               INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,25) LIKE 'corporate insolvency.aspx'
          AND WebURL LIKE 'commercial/restructuring%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
       --   AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                    ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp]  
          --,DocUrl
          
          UNION ALL 
          
            SELECT  
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Restructuring/Insolvency' AS Category
                 ,'Personal Insolvency' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
             INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
      --      INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
      --      INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,25) LIKE 'default.aspx'
          AND WebURL LIKE 'commercial/restructuring/insolvency/personal_insolvency'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 , [TIMEStamp] 
          --,DocUrl    
         
          UNION ALL 
          
           SELECT  
                  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Commercial' AS Section
                 ,'Wills Trust Tax and Probate' AS Category
                 ,'Precedents' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                 --,DocUrl
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
                INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,15) LIKE 'precedents.aspx'
          AND WebURL LIKE 'commercial/wills trusts tax and probate'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                    ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp]  
          --,DocUrl 
         
         UNION ALL
         --Public sector section
         --police
           SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Police' AS Category
                   ,'Clients' AS SubCategory
                  ,WebURL
                  ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
          FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'clients.aspx'
          AND WebURL LIKE 'public_sector/police%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
   --       AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
   --       AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp]  
          --,DocUrl
          
          
          
        UNION ALL
        
        
         SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Police' AS Category
                   ,'Technical Guidance' AS SubCategory
                  ,WebURL
                  ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person]
                ,[TIMEStamp] AS [Timestamp] 
           FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
           INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,13) LIKE 'guidance.aspx'
          AND WebURL LIKE 'public_sector/police%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 , [TIMEStamp] 
          --,DocUrl
          
          UNION ALL 
        
          SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Police' AS Category
                   ,'Professional Support' AS SubCategory
                   ,WebURL
                   ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
           FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
          INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'support.aspx'
          AND WebURL LIKE 'public_sector/police%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4 
                 ,[TIMEStamp] 
          --,DocUrl
        
        UNION ALL
        
        -- Healthcare
        
           SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Healthcare' AS Category
                   ,'Litigation' AS SubCategory
                  ,WebURL
                  ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
           FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
             INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,4) LIKE 'aspx'
          AND WebURL LIKE 'public_sector/healthcare/litigation'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4 
                  ,[TIMEStamp] 
          --,DocUrl
          
          UNION ALL 
          
             SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Healthcare' AS Category
                   ,'Advisory' AS SubCategory
                  ,WebURL
                  ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
            FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,4) LIKE 'aspx'
          AND WebURL LIKE 'public_sector/healthcare/advisory'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                     ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4 
                  ,[TIMEStamp] 
          
          UNION ALL 
          
              SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Healthcare' AS Category
                   ,'Advisory' AS SubCategory
                  ,WebURL
                  ,UserName AS Username
                    ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
                 FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
             INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,4) LIKE 'aspx'
          AND WebURL LIKE 'public_sector/healthcare/advisory'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                    ,UserName
                    ,Structure.KnownAs + ' ' + Structure.Surname 
                    ,hierarchy.HierarchyLevel3 
                    ,hierarchy.HierarchyLevel4 
                    ,[TIMEStamp] 
       
       UNION ALL
       
             
              SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Healthcare' AS Category
                   ,'Professional Support' AS SubCategory
                  ,WebURL
                  ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                  ,COUNT(*) AS [No litigation in person]
                  , [TIMEStamp] AS [Timestamp] 
            FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
             INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'support.aspx'
          AND WebURL LIKE 'public_sector/healthcare%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                      ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4 
                  ,[TIMEStamp] 
          --,DocUrl
          
         UNION ALL
         
             SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Local Government' AS Category
                   ,'Litigation' AS SubCategory
                   ,WebURL
                   ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
            FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
               INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,15) LIKE 'litigation.aspx'
          AND WebURL LIKE 'public_sector/localgovernment%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4 
                  , [TIMEStamp] 
         -- ,DocUrl
          
          
           UNION ALL
         
             SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Local Government' AS Category
                   ,'Professional Support' AS SubCategory
                  ,WebURL
                  ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                  ,COUNT(*) AS [No litigation in person] 
                  , [TIMEStamp] AS [Timestamp]
            FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
               INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
       --     INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'support.aspx'
          AND WebURL LIKE 'public_sector/localgovernment'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                  ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4
                  ,[TIMEStamp] 
         -- ,DocUrl
          
          UNION ALL
          
                 SELECT   SiteUrl AS SiteURL
                   ,SUBSTRING(WebURL, 1, 15) AS URL
                   ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                   ,'Einstein' AS Website
                   ,'Public Sector' AS Section
                   ,'Education' AS Category
                   ,'Professional Support' AS SubCategory
                   ,WebURL
                   ,UserName AS Username
                  ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                  ,hierarchy.HierarchyLevel3 AS PracticeArea
                  ,hierarchy.HierarchyLevel4 AS Team
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
             FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'support.aspx'
          AND WebURL LIKE 'public_sector/localgovernment/education'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4
                  , [TIMEStamp]  
          --,DocUrl
       
        UNION ALL
       
        -- Researchlinks
        
          SELECT  SiteUrl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Research Links' AS Section
                 ,'' AS Category
                 ,'' AS SubCategory
                 ,WebURL 
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team
                ,ISNULL(COUNT(*),0) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
              FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
            INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
         --   INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,10) LIKE 'links.aspx'
          AND WebURL LIKE 'researchlinks%'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
      
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteUrl,WebURL,DocUrl
                   ,UserName
                 ,Structure.KnownAs + ' ' + Structure.Surname
                  ,hierarchy.HierarchyLevel3 
                  ,hierarchy.HierarchyLevel4
                  ,[TIMEStamp]  
          --,DocUrl
          
         UNION ALL
        
        -- Weightmans Legal Learning
        
        
          SELECT  SiteURl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'Weightmans Legal Learning' AS Section
                 ,'' AS Category
                 ,'' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                 ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team 
                ,COUNT(*) AS [No litigation in person] 
                , [TIMEStamp] AS [Timestamp]
                FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
           INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
        --    INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND RIGHT(DocUrl,12) LIKE 'default.aspx'
          AND WebURL LIKE 'Weightmans_Legal_Learning'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
     --     AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
     --     AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
          --AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
          --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteURl,WebURL,DocUrl
            ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 , [TIMEStamp]  
          --,DocUrl  
      --      UNION ALL
      ---- WEUT 
          
      --          SELECT SiteURl AS SiteURL
      --           ,SUBSTRING(WebURL, 1, 15) AS URL
      --           ,'Einstein' AS Website
      --           ,'WEUT' AS Section
      --           ,'' AS Category
      --           ,'' AS SubCategory
      --           ,WebURL
      --          ,ISNULL(COUNT(*),0) AS [No litigation in person] 
      --    FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog
      --    WHERE WebURL <> ''
      --    AND WebURL LIKE 'weut_%'
      --    AND RIGHT(DocUrl,12) LIKE 'default.aspx'
      --    AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
      --    AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
      --   -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
      --   -- AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
      --    --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
      --    GROUP BY SiteURl,WebURL
      --    --,DocUrl
           
        UNION ALL 
           
           SELECT SiteURl AS SiteURL
                 ,SUBSTRING(WebURL, 1, 15) AS URL
                 ,SiteURL + '/' + WebURL + '/' + DocUrl AS FullURL
                 ,'Einstein' AS Website
                 ,'WEUT' AS Section
                 ,'Client Updates' AS Category
                 ,'' AS SubCategory
                 ,WebURL
                 ,UserName AS Username
                ,Structure.KnownAs + ' ' + Structure.Surname AS [Name]
                 ,hierarchy.HierarchyLevel3 AS PracticeArea
                 ,hierarchy.HierarchyLevel4 AS Team 
                ,ISNULL(COUNT(*),0) AS [No litigation in person]
                , [TIMEStamp] AS [Timestamp] 
                FROM [SQL2008SVR_Einstein].[EinsteinTaxonomy].UsageLog.WSSUsageLog AS WSSUsageLog WITH (NOLOCK)
           INNER JOIN [SQL2008SVR].[Cascade].[dbo].[EmployeeLogins_CLIENT] AS RelatedLogin
            ON  SUBSTRING(UserName, 5, 15) COLLATE DATABASE_DEFAULT = RelatedLogin.Loginud COLLATE DATABASE_DEFAULT
                AND RelatedSystemIDud = 'NT Login'
            INNER JOIN [SQL2008SVR].[Cascade].dbo.EmployeeJobs AS Employees
            ON  RelatedLogin.EmployeeID = Employees.EmployeeId AND Employees.sys_ActiveJob = 1
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.ValidHierarchyX  AS hierarchy
            ON Employees.HierarchyNode = hierarchy.hierarchynode 
            LEFT JOIN [SQL2008SVR].[Cascade].dbo.employee AS Users 
            ON Employees.EmployeeId = Users.EmployeeID  --AND Users.Active = 1
            LEFT JOIN Accounts.Structure AS Structure
            ON cast(users.EmployeeID as nvarchar(36)) = structure.employeeID AND Structure.rlActive = 1
       --     INNER JOIN dbo.udt_TallySplit(',', @PracticeArea) AS PracticeArea ON PracticeArea.ListValue COLLATE database_default = hierarchy.HierarchyLevel3 COLLATE database_default
        --    INNER JOIN dbo.udt_TallySplit(',', @Team) AS Team ON Team.ListValue COLLATE database_default = hierarchy.HierarchyLevel4 COLLATE database_default
          WHERE WebURL <> ''
          AND WebURL LIKE 'weut_%'
          AND RIGHT(DocUrl,12) LIKE 'updates.aspx'
          AND UserName NOT IN ('sbc\ssimps','sbc\kslade','sbc\jpeter','sbc\csimps','sbc\sserge','sbc\lsingh','sbc\abaile','sbc\slittl','sbc\kfaulk')
    --      AND [TIMEStamp] >= @StartDate + ' 00:00:00.000'
    --      AND [TIMEStamp] <= @EndDate + ' 23:59:59.999'
         -- AND [TIMEStamp] >= '2012-06-01' + ' 00:00:00.000'
         --AND [TIMEStamp] <= '2013-04-15' + ' 23:59:59.999'
          --AND WebURL LIKE 'litigation/litigation_general/offers_to_settle/offers_to_settle/litigants_in_person%'
          GROUP BY SiteURl,WebURL,DocUrl
                   ,UserName
                  ,Structure.KnownAs + ' ' + Structure.Surname 
                 ,hierarchy.HierarchyLevel3 
                 ,hierarchy.HierarchyLevel4
                 ,[TIMEStamp] 
          --,DocUrl
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       
         
          
          
GO
