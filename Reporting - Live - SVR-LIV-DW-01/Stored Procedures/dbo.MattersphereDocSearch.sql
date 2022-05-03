SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[MattersphereDocSearch]
(
@Client AS NVARCHAR(50)
,@Matter AS NVARCHAR(50)
)
AS 
BEGIN
SELECT 
clNo AS [Client]
,fileNo AS [Matter]
,fileDesc AS [Matter Descripiton]
,dbDocument.docID AS [MS Document Number]
,docIDOld AS [FED Document Number]
,docDesc AS [Document Title]
,docStyleDesc AS [Doc Alternative Description]
,dbDocument.Created AS [Created Date]
,dbUser.usrFullName AS [Created By]
,dbDocument.Updated AS [Last modified date]
,dbuser2.usrFullName AS [Last modified by]
,docExtension
--,MS_PROD.dbo.dbDocumentEmail.docFrom AS [From]
--,docTo AS [To]
,docWallet AS [Document Type/Category]
,docFileName AS [File Name]
,dirPath +'\' + docFileName AS [Document Path]
--,CASE WHEN docDeleted=1 THEN 'Yes' ELSE 'No' END  AS [Document Deleted?]

FROM ms_prod.config.dbDocument
INNER JOIN MS_PROD.config.dbFile
 ON dbFile.fileID = dbDocument.fileID
INNER JOIN MS_PROD.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN ms_prod.dbo.dbUser
  ON dbDocument.Createdby=dbuser.usrID
  LEFT OUTER JOIN ms_prod.dbo.dbUser AS dbuser2
  ON dbDocument.updatedby=dbuser2.usrID
--LEFT OUTER JOIN MS_PROD.dbo.dbDocumentEmail
-- ON dbDocumentEmail.docID = dbDocument.docID
LEFT OUTER JOIN MS_PROD.dbo.dbDirectory
 ON dbDirectory.dirID = dbDocument.docdirID

 WHERE clNo=@Client AND fileNo=@Matter
AND ISNULL(docDeleted,0)=0
ORDER BY dbFile.fileID,dbdocument.created ASC

END
GO
