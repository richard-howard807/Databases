SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ReportInventoryFields]
(
@ReportID AS BIGINT
)
AS
BEGIN
SELECT * FROM ReportInventory.dbo.InventoryFields
WHERE ReportID=@ReportID
END
GO
