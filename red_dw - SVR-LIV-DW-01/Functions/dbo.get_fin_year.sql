SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

Create Function [dbo].[get_fin_year](@date DATETIME)
Returns int
As 

BEGIN

DECLARE @Year INT
 
	SELECT  @Year = dim_date.fin_year
	FROM dbo.dim_date
	WHERE dim_date.calendar_date = CAST(@date AS DATE)

	RETURN	 @Year

END

GO
