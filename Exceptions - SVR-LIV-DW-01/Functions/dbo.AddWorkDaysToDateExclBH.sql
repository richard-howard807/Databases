SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[AddWorkDaysToDateExclBH]
(   
@fromDate       datetime,
@daysToAdd      int
)
RETURNS datetime
AS
BEGIN   
DECLARE @toDate datetime
DECLARE @daysAdded INTEGER
DECLARE @bh_check AS NVARCHAR(1) 

-- return null if inputted date is out of dim_date scope - function won't work due to bank holiday check 
IF @fromDate > (SELECT MAX(dim_date.calendar_date) FROM red_dw.dbo.dim_date)
	BEGIN	
		RETURN NULL
	END  

-- add the days, ignoring weekends and bank holidays (i.e. add working days)
set @daysAdded = 1
set @toDate = @fromDate

while @daysAdded <= @daysToAdd
begin
    -- add a day to the to date
    set @toDate = DateAdd(day, 1, @toDate)

	--Is @toDate flagged as a bank holiday 
	SET @bh_check = (SELECT dim_date.holiday_flag FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = @toDate)

    -- only move on a day if we've hit a week day
    if (DatePart(dw, @toDate) != 1) and (DatePart(dw, @toDate) != 7) AND (@bh_check != 'Y' )
    begin
        set @daysAdded = @daysAdded + 1
    end
end

RETURN @toDate

END
GO
