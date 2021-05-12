SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RealEstateKPIReports]

AS 

BEGIN

SELECT client_name AS [Client Name]
,master_client_code AS [Client Number]
,master_matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,name AS [Matter Owner]
,hierarchylevel4hist AS [Team]
,date_instructions_received AS [Date Instructions Received]
,date_opened_case_management AS [Date File Opened]
,FileOpeningAchieved AS [Date File Opening Process Completed]
,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,FileOpeningAchieved,103)) AS [Elapsed Days to File Opening Process]
,ExchangeDateCompleted AS [Date Exchange Process Completed]
,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,ExchangeDateCompleted,103)) AS [Elapsed Days to Exchange]
,CompletionDateCompleted AS [Date Completion Process Completed]
,DATEDIFF(DAY,CONVERT(DATE,date_instructions_received,103),CONVERT(DATE,CompletionDateCompleted,103))  AS [Elapsed Days to Completion]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT fileID,red_dw.dbo.datetimelocal(MSStage1Achieved) AS FileOpeningAchieved 
FROM ms_prod.dbo.dbMSData_OMS2K 
WHERE MSStage1Achieved IS NOT NULL) AS MilestonePlans
 ON ms_fileid=MilestonePlans.fileID
LEFT OUTER JOIN (SELECT fileID,MAX(red_dw.dbo.datetimelocal(tskCompleted)) AS ExchangeDateCompleted 
FROM MS_Prod.dbo.dbTasks
WHERe tskFilter IN ('tsk_04_010_rem_cont_exch') 
AND tskActive=1 AND tskComplete=1
GROUP BY fileID) AS Excxhange
 ON ms_fileid=Excxhange.fileID
LEFT OUTER JOIN (SELECT fileID,MAX(red_dw.dbo.datetimelocal(tskCompleted)) AS CompletionDateCompleted 
FROM MS_Prod.dbo.dbTasks
WHERe tskFilter IN ('tsk_05_010_est_comp_today') 
AND tskActive=1 AND tskComplete=1
GROUP BY fileID) AS Completion
 ON ms_fileid=Completion.fileID

  
WHERE master_client_code IN ('109593P', '153838M','848629')
AND date_opened_case_management>='2021-01-01'

END 

GO
