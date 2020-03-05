SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[CalculatePeriod] ( @year INT, @month INT )
RETURNS @PeriodTable TABLE
    (
      YearStart INT
    , YearEnd INT
    , Period INT
    )
AS BEGIN

    DECLARE @period INT
      , @yearstart INT
      , @yearend INT

    IF @month > 4 
        BEGIN
            SET @year = @year + 1
            SET @month = @month - 4
        END
    ELSE 
        BEGIN
            SET @month = @month + 8
        END

    SET @yearstart = CONVERT(INT, CONVERT(CHAR(4), @year) + '01')

    SET @yearend = CONVERT(INT, CONVERT(CHAR(4), @year) + '12')

    SET @period = CONVERT(INT, CONVERT(CHAR(4), @year) + CASE WHEN @month < 10 THEN '0' + CONVERT(CHAR(1), @month)
                                                              ELSE CONVERT(CHAR(2), @month)
                                                         END)
    INSERT  @PeriodTable
            SELECT  @yearstart AS YearStart
                  , @yearend AS YearEnd
                  , @period AS Period
    RETURN

   END












GO
