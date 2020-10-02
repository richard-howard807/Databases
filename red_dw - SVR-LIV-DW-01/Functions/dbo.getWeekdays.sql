SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[getWeekdays] (@StartDate datetime, @EndDate datetime)
RETURNS int
AS
BEGIN
     
     SET @StartDate = DATEADD(dd, DATEDIFF(dd, 0, @StartDate), 0) 
     SET @EndDate = DATEADD(dd, DATEDIFF(dd, 0, @EndDate), 0) 
          
     DECLARE @WORKDAYS INT
     SELECT @WORKDAYS = (DATEDIFF(dd, @StartDate, @EndDate) + 1)
	               -(DATEDIFF(wk, @StartDate, @EndDate) * 2)
   		       -(CASE WHEN DATENAME(dw, @StartDate) = 'Sunday' THEN 1 ELSE 0 END)
		       -(CASE WHEN DATENAME(dw, @EndDate) = 'Saturday' THEN 1 ELSE 0 END)
  
     RETURN @WORKDAYS
END
GO
