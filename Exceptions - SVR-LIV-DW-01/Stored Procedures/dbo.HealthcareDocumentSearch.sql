SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[HealthcareDocumentSearch] @Client VARCHAR(8), @Matter VARCHAR(8) 
AS

--select 
--upper(wp_code) as 'document_type',
--document_no,
--rtrim(title) as title,
--creation_date,
--author

--from
--axxia01.dbo.documt
--inner join axxia01.dbo.cashdr on cashdr.case_id = documt.case_id

--where 
--client = @Client and matter = @Matter
--and ISNULL(webreportable, 'n') <> 'y'

--UNION 

SELECT clNo,fileNo,
UPPER(docType) COLLATE DATABASE_DEFAULT 'document_type' ,
docID AS [Mattersphere DocID],
docIDOld AS [Fed DocID],

LTRIM(RTRIM(docDesc)) COLLATE DATABASE_DEFAULT title,
dbDocument.Created  creation_date,
dbUser.usrFullName COLLATE DATABASE_DEFAULT author
,docFileName
,dirPath +'\'+ docFileName AS DocumentLink
,CASE WHEN docIDOld IS NOT NULL THEN 'Imported from FED' ELSE 'Created In Mattersphere' END [System]
 FROM  ms_prod.config.dbDocument 
 LEFT JOIN ms_prod.dbo.dbUser  ON dbUser.usrID = dbDocument.Createdby
 LEFT JOIN ms_prod.config.dbFile ON dbFile.fileID = dbDocument.fileID
 LEFT JOIN ms_prod.config.dbClient ON dbClient.clID = dbFile.clID
 LEFT OUTER JOIN ms_prod.dbo.dbDirectory
  ON docdirID=dirID
 WHERE clNo COLLATE DATABASE_DEFAULT = @Client AND fileNo  COLLATE DATABASE_DEFAULT  = @Matter

 ORDER BY 
creation_date
GO
