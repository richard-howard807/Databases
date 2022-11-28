SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[HealthcareCaseloadsforAuditSelection]

AS 

BEGIN 
SELECT 
 RTRIM(master_client_code) AS [Client]
,RTRIM(client_name) AS [Client Name]
,master_client_code + '-'+master_matter_number AS [MatterSphere Ref]
,name AS [Case Manager]
,hierarchylevel4hist AS [Case Manager Team]
,matter_description AS [Matter Description]
,work_type_name AS [Matter Type]
,dim_detail_core_details.[referral_reason] AS [Referral reason]
,dim_detail_core_details.[present_position] AS [Present Position]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued]
,AuditData.AuditDate AS [Audit Date(s)]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,last_time_transaction_date AS [Date of Last Time Posting]
,last_bill_date AS [Date of Last Bill]
,CASE WHEN master_client_code='N1001' THEN 1 ELSE 0 END AS NHSRCases
,1 AS NumberMatters
,Auditor.usrFullName
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN (SELECT FileID,STRING_AGG(CAST(AuditDate AS NVARCHAR(MAX)),'|') AuditDate
FROM (
										SELECT fileID,CONVERT(VARCHAR, CAST(red_dw.dbo.datetimelocal(dteAudit) AS DATETIME), 103)  AS AuditDate
FROM ms_prod.dbo.udMIAuditNHSSearchList
WHERE bitActive=1
) AS Audits
GROUP BY Audits.fileID) AS AuditData
ON AuditData.fileID=ms_fileid
LEFT OUTER JOIN (SELECT FileID,STRING_AGG(CAST(usrFullName AS NVARCHAR(MAX)),'|') usrFullName
FROM (
										SELECT fileID,usrFullName
										FROM ms_prod.dbo.udMIAuditNHSSearchList
INNER JOIN ms_prod.dbo.dbUser
 ON cboAuditee1=usrID
WHERE bitActive=1
) AS Auditor
GROUP BY Auditor.fileID
) AS Auditor
 ON Auditor.fileID = ms_fileid

 WHERE hierarchylevel3hist='Healthcare'
 AND ms_only=1
 AND dim_matter_header_current.date_closed_case_management IS NULL
 AND UPPER(matter_description) NOT LIKE '%GENERAL FILE%'
END 

GO
