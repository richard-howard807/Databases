SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[GovSanctions] -- EXEC  Audit.GovSanctions 'IZZA KUSOMAN'
(
@GroupID AS VARCHAR(MAX)
)
AS
BEGIN
SELECT *
FROM SanctionsList.dbo.SanctionList as a
WHERE [Group ID]=@GroupID
END
GO
