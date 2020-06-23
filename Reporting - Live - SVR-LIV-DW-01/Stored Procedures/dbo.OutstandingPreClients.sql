SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [dbo].[OutstandingPreClients] -- EXEC [dbo].[OutstandingPreClients]'Corp-Comm'	,'Wills, Trusts and Estates '
(
@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)

)
AS 
BEGIN

SELECT ListValue  INTO #Department FROM Reporting.dbo.[udt_TallySplit]('|', @Department)
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)


SELECT dim_client.[client_code]
,dim_client.[client_name]
,dim_client.[client_partner_name]
,dim_client.[open_date]
,dim_client.[client_status]
,dim_client.[file_alert_message]
,dim_client.[client_partner_code]

,CASE WHEN file_alert_message LIKE '%Awaiting Grant of Probate%' THEN 1 ELSE 0 END AS Exclusions
,DATEDIFF(DAY,dim_client.[open_date],GETDATE()) AS [Days OverDue]
,CASE WHEN DATEDIFF(DAY,dim_client.[open_date],GETDATE()) >=28 THEN 'Red' 
WHEN DATEDIFF(DAY,dim_client.[open_date],GETDATE())>=14 THEN 'Orange'
ELSE 'Green' END AS Colour
,Exclude.HideFlag
,[division]
,[department]
,[Team]
,MatterOne.matter_owner_full_name AS [fee_earner_name]
,CASE WHEN Exclude. client_code IS NULL THEN 'Kev' ELSE NULL END AS Test
,WIP

 FROM red_dw.dbo.dim_client
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history ON dim_client.client_partner_code=dim_fed_hierarchy_history.fed_code COLLATE DATABASE_DEFAULT AND dim_fed_hierarchy_history.dss_current_flag='Y'
LEFT OUTER JOIN (SELECT dim_matter_header_current.client_code,SUM(wip) AS WIP 

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
 GROUP BY dim_matter_header_current.client_code) AS WIP
  ON WIP.client_code = dim_client.client_code
LEFT OUTER JOIN  
(
SELECT DISTINCT client_code,cboBilling FROM MS_Prod.dbo.udAMLProcess
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON fileID=ms_fileid
 
WHERE cboBilling ='Y'
) AS udAMLProcess
ON udAMLProcess.client_code = dim_client.client_code
LEFT OUTER JOIN 
(
SELECT dim_client.client_code,CASE WHEN COUNT(dim_client.client_code) -SUM(CASE WHEN date_closed_case_management IS NOT NULL OR fileStatus='PENDCLOSE' THEN 1 ELSE 0 END)>=1 THEN 'Include' ELSE 'Exclude' END    AS HideFlag -- date changed to closed in MS not Closed in 3E
--SELECT * 
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_client
 ON dim_matter_header_current.client_code=dim_client.client_code
LEFT OUTER JOIN  MS_Prod.dbo.udAMLProcess
 ON fileID=ms_fileid
LEFT OUTER JOIN ms_prod.config.dbFile
 ON dbFile.fileID=ms_fileid
WHERE (client_status='PENDING' OR cboBilling='Y')
AND matter_number NOT IN ('ML','00000000')
--AND dim_matter_header_current.client_code='00432030'
GROUP BY dim_client.client_code
) AS Exclude
 ON dim_client.client_code=Exclude.client_code
LEFT OUTER JOIN (SELECT dim_client.client_code
,name
,matter_owner_full_name
,hierarchylevel2hist AS [division]
,hierarchylevel3hist AS [department]
,hierarchylevel4hist AS [Team]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_client
 ON dim_matter_header_current.client_code=dim_client.client_code
LEFT OUTER JOIN  MS_Prod.dbo.udAMLProcess
 ON fileID=ms_fileid
LEFT OUTER JOIN  red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
WHERE matter_number ='00000001') AS MatterOne
 ON MatterOne.client_code = dim_client.client_code
INNER JOIN #Department AS Department  ON Department.ListValue COLLATE DATABASE_DEFAULT = MatterOne.department COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = MatterOne.Team COLLATE DATABASE_DEFAULT

WHERE (client_status='PENDING' OR cboBilling='Y')
AND dim_client.[aml_client_type] <>'ERROR'
AND dim_client.[aml_client_type] <>'TEST'
AND UPPER(dim_client.client_name) NOT LIKE '%TEST%'
AND UPPER(dim_client.client_name) NOT LIKE '%ERROR%'
AND dim_client.client_code NOT IN 
(
'W16436','W15681','W15678','W15685','W15683','W156793'
,'W16437','W16342','W15959','W15648','W15969','W16429'
,'W16442','W16430','W16432','W16433','W16125','W16264'
,'W15751','W16126','W20760','W19754','W21170','W20834'
,'FW34830','W19767','W19754','W20834'
)
AND (CASE WHEN file_alert_message LIKE '%Awaiting Grant of Probate%' THEN 1 ELSE 0 END)=0
AND ISNULL(CASE WHEN cboBilling='Y' THEN 'Include' WHEN Exclude.client_code IS NULL THEN 'Exclude' ELSE HideFlag END,'Include')='Include'


--SELECT dim_client.[client_code]
--,dim_client.[client_name]
--,dim_client.[client_partner_name]
--,dim_client.[open_date]
--,dim_client.[client_status]
--,dim_client.[file_alert_message]
--,dim_client.[client_partner_code]

--,CASE WHEN file_alert_message LIKE '%Awaiting Grant of Probate%' THEN 1 ELSE 0 END AS Exclusions
--,DATEDIFF(DAY,dim_client.[open_date],GETDATE()) AS [Days OverDue]
--,CASE WHEN DATEDIFF(DAY,dim_client.[open_date],GETDATE()) >=28 THEN 'Red' 
--WHEN DATEDIFF(DAY,dim_client.[open_date],GETDATE())>=14 THEN 'Orange'
--ELSE 'Green' END AS Colour
--,Exclude.HideFlag
--,hierarchylevel2hist AS [division]
--,hierarchylevel3hist AS [department]
--,hierarchylevel4hist AS [Team]
--,matter_owner_full_name AS [fee_earner_name]
--,CASE WHEN Exclude. client_code IS NULL THEN 'Kev' ELSE NULL END AS Test
--,WIP

-- FROM red_dw.dbo.dim_client
--INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history ON dim_client.client_partner_code=dim_fed_hierarchy_history.fed_code COLLATE DATABASE_DEFAULT AND dim_fed_hierarchy_history.dss_current_flag='Y'
--INNER JOIN #Department AS Department  ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
--INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
--LEFT OUTER JOIN (SELECT dim_matter_header_current.client_code,SUM(wip) AS WIP 

--FROM red_dw.dbo.dim_matter_header_current
--INNER JOIN red_dw.dbo.fact_finance_summary
-- ON fact_finance_summary.client_code = dim_matter_header_current.client_code
-- AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
-- GROUP BY dim_matter_header_current.client_code) AS WIP
--  ON WIP.client_code = dim_client.client_code
--LEFT OUTER JOIN  
--(
--SELECT DISTINCT client_code,cboBilling FROM MS_Prod.dbo.udAMLProcess
--INNER JOIN red_dw.dbo.dim_matter_header_current
-- ON fileID=ms_fileid
 
--WHERE cboBilling ='Y'
--) AS udAMLProcess
--ON udAMLProcess.client_code = dim_client.client_code
--LEFT OUTER JOIN 
--(
--SELECT dim_client.client_code,CASE WHEN COUNT(dim_client.client_code) -SUM(CASE WHEN date_closed_practice_management IS NOT NULL THEN 1 ELSE 0 END)>=1 THEN 'Include' ELSE 'Exclude' END    AS HideFlag
----SELECT * 
--FROM red_dw.dbo.dim_matter_header_current
--INNER JOIN red_dw.dbo.dim_client
-- ON dim_matter_header_current.client_code=dim_client.client_code
--LEFT OUTER JOIN  MS_Prod.dbo.udAMLProcess
-- ON fileID=ms_fileid
--WHERE (client_status='PENDING' OR cboBilling='Y')
--AND matter_number NOT IN ('ML','00000000')
----AND dim_matter_header_current.client_code='00432030'
--GROUP BY dim_client.client_code
--) AS Exclude
-- ON dim_client.client_code=Exclude.client_code
--LEFT OUTER JOIN (SELECT dim_client.client_code,matter_owner_full_name
--FROM red_dw.dbo.dim_matter_header_current
--INNER JOIN red_dw.dbo.dim_client
-- ON dim_matter_header_current.client_code=dim_client.client_code
--LEFT OUTER JOIN  MS_Prod.dbo.udAMLProcess
-- ON fileID=ms_fileid
--WHERE matter_number ='00000001') AS MatterOne
-- ON MatterOne.client_code = dim_client.client_code
--WHERE (client_status='PENDING' OR cboBilling='Y')
--AND dim_client.[aml_client_type] <>'ERROR'
--AND dim_client.[aml_client_type] <>'TEST'
--AND UPPER(dim_client.client_name) NOT LIKE '%TEST%'
--AND UPPER(dim_client.client_name) NOT LIKE '%ERROR%'
--AND dim_client.client_code NOT IN 
--(
--'W16436','W15681','W15678','W15685','W15683','W156793'
--,'W16437','W16342','W15959','W15648','W15969','W16429'
--,'W16442','W16430','W16432','W16433','W16125','W16264'
--,'W15751','W16126','W20760','W19754','W21170','W20834'
--,'FW34830','W19767','W19754','W20834'
--)
--AND (CASE WHEN file_alert_message LIKE '%Awaiting Grant of Probate%' THEN 1 ELSE 0 END)=0
--AND ISNULL(CASE WHEN cboBilling='Y' THEN 'Include' WHEN Exclude.client_code IS NULL THEN 'Exclude' ELSE HideFlag END,'Include')='Include'
	
	
END 

GO
