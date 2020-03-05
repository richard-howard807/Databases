SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- SELECT dbo.getBusinessMinutesBetween(CAST('2013-09-05 19:12:00.000' AS datetime),CAST('2013-09-06 09:32:00.000' AS datetime), '09:00', '17:00')

CREATE FUNCTION [dbo].[getBusinessMinutesBetween](
	  @FromDate DATETIME
	, @ToDate DATETIME
	, @BusinessHoursFrom TIME
	, @BusinessHoursTo TIME
)
RETURNS BIGINT 
AS
BEGIN
	DECLARE @Diff BIGINT; 
	DECLARE @FromDateDay DATETIME; 
	DECLARE @ToDateDay DATETIME;
	DECLARE @FromDateTime TIME; 
	DECLARE @ToDateTime TIME;
	
	SET @FromDateDay = CAST(@FromDate AS DATE)
	SET @FromDateTime = CAST(@FromDate AS TIME)
	SET @ToDateDay = CAST(@ToDate AS DATE)
	SET @ToDateTime = CAST(@ToDate AS TIME)

	IF @FromDateTime < @BusinessHoursFrom SET @FromDateTime = @BusinessHoursFrom -- If start time is before 9am, set it to 9am
	IF @FromDateTime > @BusinessHoursTo SET @FromDateTime = @BusinessHoursTo -- If start time is after 5pm, set it to 5pm
	IF @ToDateTime < @BusinessHoursFrom SET @ToDateTime = @BusinessHoursFrom -- If end time is before 9am, set it to 9am
	IF @ToDateTime > @BusinessHoursTo SET @ToDateTime = @BusinessHoursTo -- If end time is after 5pm, set it to 5pm
	
	IF DATEPART(WEEKDAY, @FromDateDay) = 7 -- If start date is a saturday, set it to next monday 9am
	BEGIN
		SET @FromDateDay = DATEADD(DAY, 2, @FromDateDay)
		SET @FromDateTime = @BusinessHoursFrom
	END
	
	IF DATEPART(WEEKDAY, @FromDateDay) = 1 -- If start date is a sunday, set it to next monday 9am
	BEGIN
		SET @FromDateDay = DATEADD(DAY, 1, @FromDateDay)
		SET @FromDateTime = @BusinessHoursFrom
	END
	
	IF DATEPART(WEEKDAY, @ToDateDay) = 7 -- If end date is a saturday, set it to next monday 9am
	BEGIN
		SET @ToDateDay = DATEADD(DAY, 2, @ToDateDay)
		SET @ToDateTime = @BusinessHoursFrom
	END
	
	IF DATEPART(WEEKDAY, @ToDateDay) = 1 -- If end date is a sunday, set it to next monday 9am
	BEGIN
		SET @ToDateDay = DATEADD(DAY, 1, @ToDateDay)
		SET @ToDateTime = @BusinessHoursFrom
	END
	
	SET @Diff = DATEDIFF(MINUTE, @FromDateDay + @FromDateTime, @ToDateDay + @ToDateTime)												-- difference = total minutes from start to finish...
	SET @Diff = @Diff - (dbo.getWeekdays(@FromDateDay, @ToDateDay) * (1440 - (DATEDIFF(MINUTE, @BusinessHoursFrom, @BusinessHoursTo)))) -- minus (number of weekdays between start and end dates * minutes between 9-5)...
	SET @Diff = @Diff - ((DATEDIFF(DAY, @FromDateDay, @ToDateDay) - dbo.getWeekdays(@FromDateDay, @ToDateDay)) * 1440)					-- minus (number of weekend days between start and end dates * minutes in a day)
	
	RETURN @Diff
END
GO
