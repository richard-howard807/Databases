SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[TaskBridgeInsert]

AS
BEGIN

INSERT INTO [dbo].[MSTaskBridge] (tskID, SourceSytemId, MSFileID, ExtTskID,OriginatingSystemID,OriginatingSequenceID)
SELECT 
db.tskID,
'FED' AS SourceSytemId,
db.fileID AS MSFileID,
db.tskNotes AS ExtTskID,
SUBSTRING(db.tskNotes,0,CHARINDEX('|', db.tskNotes,0)) AS OriginatingSystemID,
SUBSTRING(db.tskNotes,CHARINDEX('|', db.tskNotes,0)+1,1000) AS OriginatingSequenceID
FROM [dbo].[MSTasks] db
INNER JOIN MattersphereStaging.dbo.TaskImportSucess ti ON CAST(db.tskNotes AS NVARCHAR(255))= ti.ExttskID


--Set the note to a NULL 
UPDATE db
SET db.tskNotes = NULL
FROM [dbo].[MSTasks] db
INNER JOIN MattersphereStaging.dbo.TaskImportSucess ti ON CAST(db.tskNotes AS NVARCHAR(255))= ti.ExttskID

END
GO
