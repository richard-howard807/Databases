SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Emily Smith 
-- Create date: 14-09-16
-- Description:	Function to return the number of elapsed days from start and end date excluding bankholidays
-- =============================================


CREATE FUNCTION [dbo].[ReturnElapsedDaysExcludingBankHolidays]
(
	@StartDate DATETIME
	,@EndDate DATETIME
)
RETURNS DECIMAL(20,2)
AS

BEGIN


DECLARE @BankHolidays AS INT
DECLARE @Weekends AS INT
SET @BankHolidays=(SELECT COUNT(bank_holidays) FROM uk_bank_holidays.dbo.uk_bank_holidays
WHERE [bank_holidays] BETWEEN @StartDate AND @EndDate)


SET @Weekends=(SELECT COUNT(week_end_flag)FROM red_dw.dbo.dim_date WHERE week_end_flag='Y' AND calendar_date BETWEEN @StartDate AND @EndDate)


DECLARE @NumberDays AS INT
SET @NumberDays=(SELECT DATEDIFF(DAY,@StartDate,@EndDate)) -  ( @BankHolidays + @Weekends)


RETURN @NumberDays
END

GO
