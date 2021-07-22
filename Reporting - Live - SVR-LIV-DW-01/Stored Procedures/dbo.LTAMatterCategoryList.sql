SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[LTAMatterCategoryList]

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
FROM MS_PROD.config.dbfile
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
WHERE CONVERT(DATE,dbFile.Created,103) BETWEEN '2020-05-01' AND '2021-04-27'
AND fileNo<>'0'

END 
GO
