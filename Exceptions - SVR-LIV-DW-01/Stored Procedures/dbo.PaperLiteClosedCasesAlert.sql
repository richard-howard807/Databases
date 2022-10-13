SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PaperLiteClosedCasesAlert] -- EXEC [dbo].[PaperLiteClosedCasesAlert]'2019-03-26','2019-03-26','All'
(
@StartDate AS DATE
,@EndDate AS DATE
,@Filter AS NVARCHAR(MAX)

)
AS 
BEGIN


IF @Filter='All'

BEGIN 

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
,CASE WHEN red_dw.dbo.dim_fed_hierarchy_history.leaver=1 THEN worksforemail ELSE workemail END AS EmailAddress
FROM MS_Prod.dbo.dbTasks
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dbTasks.fileID=ms_fileid
INNER JOIN MS_Prod.config.dbFile
 ON dbFile.fileID = dbTasks.fileID
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN MS_Prod.dbo.dbUser ON dbTasks.CreatedBy=dbUser.usrID
WHERE date_closed_case_management IS NOT  NULL
AND tskType='PAPERLITE'
AND client_code <> '00030645'
AND CONVERT(DATE,dbTasks.Created,103) >=CONVERT(DATE,date_closed_case_management,103)
AND CONVERT(DATE,dbTasks.Created,103) BETWEEN @StartDate AND @EndDate

END 

ELSE 

BEGIN

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
,CASE WHEN red_dw.dbo.dim_fed_hierarchy_history.leaver=1 THEN worksforemail ELSE workemail END AS EmailAddress
FROM MS_Prod.dbo.dbTasks
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dbTasks.fileID=ms_fileid
INNER JOIN MS_Prod.config.dbFile
 ON dbFile.fileID = dbTasks.fileID
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN MS_Prod.dbo.dbUser ON dbTasks.CreatedBy=dbUser.usrID
WHERE date_closed_case_management IS NOT  NULL
AND tskType='PAPERLITE'
AND client_code <> '00030645'
AND CONVERT(DATE,dbTasks.Created,103) >=CONVERT(DATE,date_closed_case_management,103)
AND CONVERT(DATE,dbTasks.Created,103) BETWEEN @StartDate AND @EndDate
AND CASE WHEN red_dw.dbo.dim_fed_hierarchy_history.leaver=1 THEN worksforemail ELSE workemail END =@Filter

END 





END 
GO
