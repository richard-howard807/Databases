SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[DocumentCopied]

(
@ID INT, @auditID int
)
AS
UPDATE dbo.DocumentStage
SET StatusID = 8, AuditIdFileMove = @auditID
WHERE ID = @ID
GO
