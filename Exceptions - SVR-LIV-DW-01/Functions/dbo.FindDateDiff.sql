SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[FindDateDiff](@Date1 DATE,@Date2 DATE, @IncludeTheEnDate BIT)
RETURNS VARCHAR(255)
AS
BEGIN 

DECLARE @ret AS VARCHAR(255)

SET @ret=(
    SELECT
        --CALC.Years,CALC.Months,D.Days,
        Duration = RTRIM(CASE WHEN CALC.Years > 0 THEN CONCAT(CALC.Years, ' year(s) ') ELSE '' END
                       + CASE WHEN CALC.Months > 0 THEN CONCAT(CALC.Months, ' month(s) ') ELSE '' END
                       + CASE WHEN D.Days > 0 OR (CALC.Years=0 AND CALC.Months=0) THEN CONCAT(D.Days, ' day(s)') ELSE '' END)
    FROM (VALUES(IIF(@Date1<@Date2,@Date1,@Date2),DATEADD(DAY, IIF(@IncludeTheEnDate=0,0,1), IIF(@Date1<@Date2,@Date2,@Date1)))) T(StartDate, EndDate)
    CROSS APPLY(SELECT
        TempEndYear = CASE WHEN ISDATE(CONCAT(YEAR(T.EndDate), FORMAT(T.StartDate,'-MM-dd')))=1 THEN CONCAT(YEAR(T.EndDate), FORMAT(T.StartDate,'-MM-dd'))
                        ELSE CONCAT(YEAR(T.EndDate),'-02-28') END
    ) TEY
    CROSS APPLY(SELECT EndYear = CASE WHEN TEY.TempEndYear > T.EndDate THEN DATEADD(YEAR, -1, TEY.TempEndYear) ELSE TEY.TempEndYear END) EY
    CROSS APPLY(SELECT
        Years = DATEDIFF(YEAR,T.StartDate,EY.EndYear),
        Months = DATEDIFF(MONTH,EY.EndYear,T.EndDate)-IIF(DAY(EY.EndYear)>DAY(T.EndDate),1,0)
    ) CALC
    CROSS APPLY(SELECT Days =  DATEDIFF(DAY,DATEADD(MONTH,CALC.Months,DATEADD(YEAR,CALC.Years,T.StartDate)),T.EndDate)) D
) 

RETURN @ret
	END 


GO
