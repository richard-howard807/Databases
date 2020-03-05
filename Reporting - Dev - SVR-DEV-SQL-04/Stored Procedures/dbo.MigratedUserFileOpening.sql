SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MigratedUserFileOpening] -- 'Real Estate','Real Estate Liverpool 1','1499','1046'
(
@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
,@FeeEarner AS NVARCHAR(MAX)
,@Worktype  AS NVARCHAR(MAX)
)
AS 
BEGIN

SELECT ListValue  INTO #Department FROM Reporting.dbo.[udt_TallySplit](',', @Department)
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit](',', @Team)
SELECT ListValue  INTO #FeeEarner FROM Reporting.dbo.[udt_TallySplit](',', @FeeEarner)
SELECT ListValue  INTO #Worktype FROM Reporting.dbo.[udt_TallySplit](',', @Worktype)

SELECT b.name,display_name As [Migrated User]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,display_name As [Fee Earner Name]
,a.DateFirstfileMigrated As [Date First file Migrated]
,CASE WHEN date_opened_practice_management > a.DateFirstfileMigrated THEN 1 ELSE 0 END [New File After Migration]
,CAST(CASE WHEN dim_matter_header_current.ms_only=1 THEN 1 ELSE 0 END AS INT)  AS [MS Only File]
,CAST(CASE WHEN dim_matter_header_current.ms_only=1 THEN 0 ELSE 1 END AS INT)  AS [MSAND FED]
,client_code AS [Client]
,matter_number As [Matter]
,matter_description AS [Matter Description]
,work_type_name AS [WorkType]
,work_type_code AS [WorkTypeCode]
,date_opened_case_management AS [Date Opened]
,1 AS NumberFiles
FROM MigrationDatesByUser AS a WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS b WITH(NOLOCK)
 ON a.FeeEarner=b.fed_code collate database_default AND dss_current_flag='Y'
INNER JOIN #Department AS Department  ON Department.ListValue COLLATE database_default = hierarchylevel3hist COLLATE database_default
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE database_default = hierarchylevel4hist COLLATE database_default
INNER JOIN #FeeEarner AS FeeEarner  ON FeeEarner.ListValue COLLATE database_default = fed_code COLLATE database_default
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON b.fed_code=dim_matter_header_current.fee_earner_code 
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK)  
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
INNER JOIN #Worktype AS Worktype WITH(NOLOCK)  ON Worktype.ListValue COLLATE database_default = work_type_code  COLLATE database_default

WHERE date_closed_practice_management IS NULL
AND client_code NOT IN ('00030645','00453737','95000C','P00016')
END
GO
