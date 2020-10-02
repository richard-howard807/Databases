SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[getBankHolidays] (@StartDate datetime, @EndDate datetime)
RETURNS int
AS
BEGIN
     
     SET @StartDate = DATEADD(dd, DATEDIFF(dd, 0, @StartDate), 0) 
     SET @EndDate = DATEADD(dd, DATEDIFF(dd, 0, @EndDate), 0) 
          
     DECLARE @BankHolidays INT
		 SELECT @BankHolidays = COUNT(load_dw_bank_holidays.calendar_date)
		 FROM load_dw_bank_holidays
		 WHERE calendar_date BETWEEN @StartDate AND @EndDate
		  

     RETURN @BankHolidays



END
GO
