SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[DocumentCopiedFailed]

(
@ID INT, @auditID int
)
AS
UPDATE dbo.DocumentStage
SET StatusID = 11, AuditIdFileMove = @auditID
WHERE ID = @ID
GO
