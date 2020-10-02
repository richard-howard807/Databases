SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[GetTotalWorkingDays_withbankhols]
(
    @StartDate Date,
    @EndDate Date
)
RETURNS INT
AS
BEGIN


   SET @StartDate = DATEADD(dd, DATEDIFF(dd, 0, @StartDate), 0) 
     SET @EndDate = DATEADD(dd, DATEDIFF(dd, 0, @EndDate), 0) 
          
     DECLARE @WORKDAYS INT = 0
			SELECT @WORKDAYS = (DATEDIFF(dd, @StartDate, @EndDate) + 1)
	               -(DATEDIFF(wk, @StartDate, @EndDate) * 2)
   		       -(CASE WHEN DATENAME(dw, @StartDate) = 'Sunday' THEN 1 ELSE 0 END)
		       -(CASE WHEN DATENAME(dw, @EndDate) = 'Saturday' THEN 1 ELSE 0 END)
  
	 DECLARE @BankHolidays INT = 0

		 SELECT @BankHolidays = COUNT(load_dw_bank_holidays.calendar_date)
		 FROM load_dw_bank_holidays
		 WHERE calendar_date BETWEEN @StartDate AND @EndDate
		  

 
	   RETURN @WORKDAYS - @BankHolidays - 1
	
   --  RETURN IIF( @WORKDAYS - @BankHolidays - 1 < 0, 0,  @WORKDAYS - @BankHolidays - 1)

   	 
END

GO
