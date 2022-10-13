SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[AddWorkDaysToDate]
(   
@fromDate       datetime,
@daysToAdd      int
)
RETURNS datetime
AS
BEGIN   
DECLARE @toDate datetime
DECLARE @daysAdded integer

-- add the days, ignoring weekends (i.e. add working days)
set @daysAdded = 1
set @toDate = @fromDate

while @daysAdded <= @daysToAdd
begin
    -- add a day to the to date
    set @toDate = DateAdd(day, 1, @toDate)
    -- only move on a day if we've hit a week day
    if (DatePart(dw, @toDate) != 1) and (DatePart(dw, @toDate) != 7)
    begin
        set @daysAdded = @daysAdded + 1
    end
end

RETURN @toDate

END
GO
