SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[MatterTypeReportLTAClaims]

AS

BEGIN 
SELECT 
       ISNULL(AllData.[Matter Category],'No Category') AS [Matter Category],
       AllData.[Matter Category Status],
       AllData.[Matter Type],
	   [Taskflow],
       SUM(AllData.[Open files LTA]) AS [Open files LTA],
       MAX(AllData.[Data Last Opened LTA]) AS [Data Last Opened LTA],
       SUM(AllData.[Open Files Claims]) AS [Open Files Claims],
       MAX(AllData.[Data Last Opened Claims]) AS [Data Last Opened Claims]
   
	   FROM 
(SELECT 
RTRIM(master_client_code) + '-' +RTRIM(master_matter_number) AS [Reference]
,matter_description AS [Matter description]
,cdDesc AS [Matter Category]
,CASE WHEN active=1 THEN 'Live' ELSE 'Retired' END   AS [Matter Category Status]
,work_type_name AS [Matter Type]
,CASE WHEN hierarchylevel2hist='Legal Ops - LTA' THEN 1 ELSE 0 END  AS [Open files LTA]
,CASE WHEN hierarchylevel2hist='Legal Ops - LTA' THEN date_opened_case_management ELSE NULL END AS [Data Last Opened LTA]
,CASE WHEN hierarchylevel2hist='Legal Ops - Claims' THEN 1 ELSE 0 END  AS [Open Files Claims]
,CASE WHEN hierarchylevel2hist='Legal Ops - Claims' THEN date_opened_case_management ELSE NULL END AS [Data Last Opened Claims]
,name AS [Matter manager]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,ISNULL(MSCode,'Non Added') AS [Taskflow]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
 LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
  ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_group
 ON dim_matter_group.dim_matter_group_key = dim_matter_header_current.dim_matter_group_key
LEFT OUTER JOIN MS_Prod.dbo.udMatterCategory 
 ON work_type_code=udMatterCategory.matterType COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM ms_prod.dbo.dbCodeLookup WHERE cdType='UFILECATEGORY') AS Category
 ON MatterCategory=Category.cdCode COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN ms_prod.dbo.dbMSData_OMS2K
 ON ms_fileid=fileID
WHERE  date_closed_practice_management IS NULL
AND hierarchylevel2hist IN ('Legal Ops - Claims','Legal Ops - LTA')
AND master_client_code <>'30645'
) AS AllData
GROUP BY AllData.[Matter Category],
         AllData.[Matter Category Status],
         AllData.[Matter Type]
		 ,[Taskflow]
		 ORDER BY 1 ASC
END
GO
