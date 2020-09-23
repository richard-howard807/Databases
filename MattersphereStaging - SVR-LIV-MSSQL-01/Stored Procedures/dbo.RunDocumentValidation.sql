SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[RunDocumentValidation]

AS

--Update the document author
UPDATE DocumentStage
SET [MSDocAuthor]=usrlookup.usrID
FROM [MattersphereStaging].[dbo].[DocumentStage] Doc
LEFT OUTER JOIN (SELECT  usrID,usrAlias FROM MSUsers) AS usrlookup
  ON Doc.FEDAuthor=usrlookup.usrAlias

--Set the destination
DECLARE @SharePath NVARCHAR(255)
SELECT @SharePath = dir.dirPath 
FROM MSDirectory dir		--SYNONYM
WHERE dircode = 'OMDOCUMENTS'

UPDATE DocumentStage
SET DocumentDestination =CONCAT(@SharePath,'\',Doc.MSClientID,'\',Doc.MSFileID,'\','In','\',CASE WHEN DocumentNumber IS NULL THEN 1 ELSE Doc.DocumentNumber END,'.',Doc.DocumentExtension)
FROM [MattersphereStaging].[dbo].[DocumentStage] Doc


UPDATE DocumentStage
SET StatusID=8
,error=11
,errormsg=ISNULL(errormsg,'') + 'User Doesnt Exist,'
FROM [MattersphereStaging].[dbo].DocumentStage 
WHERE  MSDocAuthor IS NULL 


UPDATE DocumentStage
SET StatusID=8
,error=11
,errormsg=ISNULL(errormsg,'') + 'Created By Doesnt Exist,'
FROM [MattersphereStaging].[dbo].DocumentStage 
WHERE  MSDocAuthor IS NULL
GO
