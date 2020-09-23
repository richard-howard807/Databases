SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ValidateFWDocs]
AS
BEGIN

UPDATE DocumentStage 
SET StatusID=6
WHERE DocFileName IS NULL

UPDATE a
SET StatusID=6 
FROM DocumentStage AS a
INNER JOIN MS_Prod.config.dbDocument AS b
 ON a.DocumentNumber=b.docIDOld
 AND a.FileID=b.fileID

UPDATE dbo.DocumentStage
SET StatusID=6 
WHERE DocumentExtension NOT IN ('msg','odt','pdf','ods','doc','sdw','rtf','xls','jpg','fxm')



END
GO
