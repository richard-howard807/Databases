SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ReportInventoryMain]
(
@ReportID AS BIGINT
)
AS
BEGIN
SELECT * FROM ReportInventory.dbo.Inventory
WHERE ReportID=@ReportID
END
GO
