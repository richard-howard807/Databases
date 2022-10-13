SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AMLPSCDiscrepancies]

AS
BEGIN 

SELECT clNo AS [Client No]
,clname AS [Client Name]
,Matter1Details.matter_partner_full_name AS [Client Partner]
,name AS [Fee Earner Name]
,Matter1Details.hierarchylevel4hist AS Team
,Matter1Details.matter_description AS [Matter Description]
,Matter1Details.date_opened_case_management AS [Date Opened]
,dteRepComDis AS [Date Reported]
,Matter1Details.date_closed_case_management AS [Date Closed]
,NULL AS [Comments]
FROM ms_prod.dbo.udExtFile 
INNER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = udExtFile.fileID
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN ms_prod.dbo.udAMLProcess
 ON udAMLProcess.fileID = dbFile.fileID
LEFT OUTER JOIN (
SELECT ms_fileid,master_client_code,matter_description,matter_partner_full_name,matter_owner_full_name,date_opened_case_management,date_closed_case_management,name
,hierarchylevel4hist
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
WHERE master_matter_number='1') AS Matter1Details
 ON clNo=master_client_code COLLATE DATABASE_DEFAULT
WHERE dteRepComDis IS NOT NULL

ORDER BY clNo

END
GO
