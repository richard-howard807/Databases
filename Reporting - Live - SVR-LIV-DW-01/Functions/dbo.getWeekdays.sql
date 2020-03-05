SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- SELECT dbo.getWeekDays(GETDATE(), GETDATE())

CREATE FUNCTION [dbo].[getWeekdays](
	  @StartDate DATETIME
	, @EndDate DATETIME
)
RETURNS INT
AS
BEGIN
	DECLARE @result INT
	SELECT @result = (DATEDIFF(dd, @StartDate, @EndDate))
					-(DATEDIFF(wk, @StartDate, @EndDate) * 2)
					-(CASE WHEN DATENAME(dw, @StartDate) = 'Sunday' THEN 1 ELSE 0 END)
					-(CASE WHEN DATENAME(dw, @EndDate) = 'Saturday' THEN 1 ELSE 0 END)
	RETURN @result
END
GO
