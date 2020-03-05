SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[UpdateBillsIntoMatterPlans]
(@ID  INT
,@Status INT 
)
AS
BEGIN

 UPDATE dbo.BillsIntoMatterPlans
 SET [Does Doc Exist]=@Status
 WHERE ID=@ID
 
 
 
END


GO
