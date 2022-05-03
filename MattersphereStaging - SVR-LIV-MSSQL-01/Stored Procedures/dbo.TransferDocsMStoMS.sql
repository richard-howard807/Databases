SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE PROCEDURE [dbo].[TransferDocsMStoMS] --EXEC  [dbo].[TransferDocsMStoMS] 4987369,5010941
(
@OldID  BIGINT
,@NewID  BIGINT
)
AS
BEGIN

DECLARE @dirPath AS NVARCHAR(1000)

--SET @OldID=4963674
--SET @NewID=4040553




TRUNCATE TABLE dbo.ThirdPartyDocumentStage
INSERT INTO dbo.ThirdPartyDocumentStage
([FileID],[DocumentTitle],[AlternateDocDescription],[DocumentExtension],[DocWallet]
,[CreationDate],[ModifiedDate],[ShowOnExtranet],[DocumentSource],[MSassocID])
SELECT 
@NewID AS [FileID]
,docDesc AS [DocumentTitle]
,CASE WHEN docStyleDesc=''  OR docStyleDesc IS NULL THEN LEFT(docDesc,100) ELSE docStyleDesc END  AS[AlternateDocDescription]
,REPLACE(docExtension,'.','') AS[DocumentExtension]
,ISNULL(cdDesc,'Internal') AS[DocWallet]
,dbDocument.Created AS[CreationDate]
,dbDocument.Updated AS[ModifiedDate]
,CASE WHEN dbDocument.SecurityOptions=2 THEN 'Yes' ELSE 'No' END  AS[ShowOnExtranet]
,dirPath +'\'+docFileName AS[DocumentSource]
,NULL AS[MSassocID] --More Development Needed
 FROM MS_PROD.config.dbDocument
 INNER JOIN MS_PROD.config.dbFile
  ON dbDocument.fileID=dbFile.fileID
LEFT OUTER JOIN (SELECT dirID,dirPath FROM  MS_PROD.dbo.dbDirectory) AS Directory
 ON Directory.dirID = dbDocument.docdirID
 LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM MS_PROD.dbo.dbCodeLookup
WHERE cdType='WALLET') AS Wallets
 ON docWallet=cdCode
WHERE dbDocument.fileID=@OldID
AND docDeleted <>1
--AND CONVERT(DATE,dbDocument.Created,103)>='2020-12-16'
--AND CONVERT(DATE,dbDocument.Created,103)<='2021-03-17'
ORDER BY docID

EXEC [dbo].[CUR_RunThirdPartyDocs]



SELECT
DocumentSource,
DocumentLocation  AS Documentdestination,
REVERSE(SUBSTRING(REVERSE(DocumentLocation), CHARINDEX('\',REVERSE(DocumentLocation),0),999 )) AS DestinationFolder,
REVERSE(SUBSTRING(REVERSE(DocumentLocation), 0, CHARINDEX('\',REVERSE(DocumentLocation),0))) AS Document,
DocID AS CreationDate
FROM  dbo.ThirdPartyDocumentStage  AS a


END
GO
