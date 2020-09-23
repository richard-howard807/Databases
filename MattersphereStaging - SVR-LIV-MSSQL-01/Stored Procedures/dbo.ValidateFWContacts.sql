SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ValidateFWContacts]
AS
BEGIN
UPDATE a
SET a.StatusID=6,a.errormsg='Contact Already created in MS'
FROM dbo.FWContactStage AS a
INNER JOIN dbo.FWContactSuccess AS b
 ON a.SourceSystemID=b.SourceSystemID
 AND a.ContactType=b.ContactType
END
GO
