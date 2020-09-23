SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ValidateVFileContacts]
AS
BEGIN
UPDATE a
SET a.StatusID=6,a.errormsg='Contact Already created in MS'
FROM dbo.VFContactStage AS a
INNER JOIN dbo.VFContactSuccess AS b
 ON a.VFileEntityCode=b.VFileEntityCode
END
GO
