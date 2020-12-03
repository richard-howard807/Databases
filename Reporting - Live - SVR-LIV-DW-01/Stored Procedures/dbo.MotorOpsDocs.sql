SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MotorOpsDocs] --EXEC dbo.MotorOpsDocs 'Ageas'
(
@Client AS NVARCHAR(MAX)
) 
AS
BEGIN 
SELECT master_client_code +'-'+master_matter_number AS [MattersphereRef]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,name AS [Case Handler]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,LEFT(DATENAME(MONTH,date_instructions_received),3) + ' ' + CAST(YEAR(date_instructions_received) AS NVARCHAR(5)) AS ReceivedPeriod
,date_instructions_received AS [Date Instructions Recevied]
,LEFT(DATENAME(MONTH,date_claim_concluded),3) + ' '  + CAST(YEAR(date_claim_concluded) AS NVARCHAR(5)) AS ConcludedPeriod
,date_claim_concluded AS [Date Claim Concluded]
,CASE WHEN date_claim_concluded BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1) + 1 AND   DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1 THEN 1 ELSE 0 END AS ConcludedNo
,CASE WHEN date_instructions_received BETWEEN DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1) + 1 AND   DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) - 1 THEN 1 ELSE 0 END AS ReceviedNo
,dim_detail_core_details.present_position AS [Present Position]
,dim_detail_core_details.[date_initial_report_sent] 
,outcome_of_case AS Outcome
,[TrialDate]
,CASE WHEN Trial.TrialDate BETWEEN CONVERT(DATE,GETDATE(),103) AND DATEADD(DAY,90,CONVERT(DATE,GETDATE(),103)) THEN 1 ELSE 0 END AS UpcomingTrials
,CASE WHEN master_client_code='W15564' THEN 'Sabre' 
WHEN master_client_code='A1001' THEN 'AXA XL'
WHEN master_client_code='T3003' THEN 'Tesco'
WHEN master_client_code='A3003'  AND dim_detail_claim.[name_of_instructing_insurer]='Tesco Underwriting (TU)' THEN 'Tesco'
WHEN master_client_code='A3003' THEN 'Ageas' END AS ClientFilter
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.client_code = dim_matter_header_current.client_code
 AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT fileID AS fileid,MIN(tskDue) AS [TrialDate] FROM ms_prod.dbo.dbTasks WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON fileID=ms_fileid
WHERE tskDesc LIKE '%Trial date - today%'
AND tskType='KEYDATE'
AND master_client_code IN ('A3003','T3003','W15564','A1001')
GROUP BY fileID
) AS Trial
 ON ms_fileid=Trial.fileid


WHERE master_client_code IN ('A3003','T3003','W15564','A1001')
AND reporting_exclusions=0
AND (date_closed_case_management IS NULL OR date_closed_case_management>='2018-01-01')
AND (CASE WHEN master_client_code='W15564' THEN 'Sabre' 
WHEN master_client_code='A1001' THEN 'AXA XL'
WHEN master_client_code='T3003' THEN 'Tesco'
WHEN master_client_code='A3003'  AND dim_detail_claim.[name_of_instructing_insurer]='Tesco Underwriting (TU)' THEN 'Tesco'
WHEN master_client_code='A3003' THEN 'Ageas' END)=@Client
AND hierarchylevel3hist='Motor'

END 
GO
