SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PaperLiteClosedCases] -- EXEC [dbo].[PaperLiteClosedCases]'Motor'
(
@StartDate AS DATE
,@EndDate AS DATE
,@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
,@FeeEarner NVARCHAR(MAX)

)
AS 
BEGIN

SELECT ListValue  INTO #Department FROM Reporting.dbo.udt_TallySplitPipe('|', @Department)
SELECT ListValue  INTO #Team FROM Reporting.dbo.udt_TallySplitPipe('|', @Team)
SELECT ListValue  INTO #FeeEarner FROM Reporting.dbo.udt_TallySplitPipe('|', @FeeEarner)



SELECT client_code AS [Client]
,matter_number AS [Matter]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_practice_management AS [Date Closed]
,fileStatus AS [File Status]
,tskDesc AS [Paperlite Task Description]
,LTRIM(REPLACE(tskDesc,'REM: ','')) AS [DocumentDescription]
,dbTasks.Created AS [Created]
,dbUser.usrFullName AS [Created By]
,matter_owner_full_name AS [Matter Owner]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,workemail AS [Fee Earner Email]
,worksforemail AS [TM Email]
FROM MS_Prod.dbo.dbTasks
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dbTasks.fileID=ms_fileid
INNER JOIN MS_Prod.config.dbFile
 ON dbFile.fileID = dbTasks.fileID
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN #Department AS Department  ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue   COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN MS_Prod.dbo.dbUser ON dbTasks.CreatedBy=dbUser.usrID
WHERE date_closed_case_management IS NOT  NULL
AND tskType='PAPERLITE'
AND CONVERT(DATE,dbTasks.Created,103) >=CONVERT(DATE,date_closed_case_management,103)
AND CONVERT(DATE,dbTasks.Created,103) BETWEEN @StartDate AND @EndDate


END 
GO
