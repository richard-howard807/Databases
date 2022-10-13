SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[UpdateDisbsIntoMatterPlans]
(@ID  INT
,@Status INT 
)
AS
BEGIN

 UPDATE dbo.DisbsIntoMatterPlans
 SET [Does Doc Exist]=@Status
 WHERE ID=@ID
 
 
 
END



GO
