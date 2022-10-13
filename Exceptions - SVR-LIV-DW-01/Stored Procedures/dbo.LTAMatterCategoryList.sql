SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LTAMatterCategoryList]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 

BEGIN
SELECT clNo,fileNo
,fileDesc AS [Matter Description]
,usrAlias AS [PayrollID]
,usrFullName AS [Matter Manager]
,fileType,dbCodeLookup.cdDesc AS [File Type Description]
,cboCategory AS [Matter Category]
,Cat.cdDesc AS [Matter Category Description]
,MSCode AS [Assigned Taskflow]
,MSStage1Achieved
,MSStage2Achieved
,MSStage3Achieved
,MSStage4Achieved
,MSStage5Achieved
,MSStage6Achieved
,MSStage7Achieved
,MSStage8Achieved
,MSStage9Achieved
,MSStage10Achieved
,MSStage11Achieved
,MSStage12Achieved
,MSStage13Achieved
,MSStage14Achieved
,MSStage15Achieved
,MSStage16Achieved
,MSStage17Achieved
,MSStage18Achieved
,MSStage19Achieved
,MSStage20Achieved
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,CONVERT(DATE,red_dw.dbo.datetimelocal(dbFile.Created),103) AS [Date Opened]
FROM MS_PROD.config.dbfile
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON ms_fileid=dbFile.fileID
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN MS_PROD.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup ON fileType=dbCodeLookup.cdCode AND dbCodeLookup.cdType='FILETYPE'
LEFT OUTER JOIN MS_PROD.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup AS Cat
 ON cboCategory=Cat.cdCode AND Cat.cdType='UFILECATEGORY' 
LEFT OUTER JOIN MS_PROD.dbo.dbMSData_OMS2K
 ON dbMSData_OMS2K.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.dbUser
 ON filePrincipleID=usrID

WHERE CONVERT(DATE,red_dw.dbo.datetimelocal(dbFile.Created),103) BETWEEN @StartDate AND @EndDate
AND fileNo<>'0'
AND hierarchylevel2hist='Legal Ops - LTA'

END 
GO
