SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT dbo.ConvertTextToTime('13:15'), dbo.ConvertTextToTime(' 13 15'), dbo.ConvertTextToTime('13.15'), dbo.ConvertTextToTime(' 1315')

CREATE FUNCTION [dbo].[ConvertTextToTime](
	@timestring varchar(MAX)
)
RETURNS TIME
AS
BEGIN
RETURN CASE WHEN ISDATE(RTRIM(LTRIM(@timestring))) = 1 THEN CONVERT(time, @timestring)
			 WHEN ISDATE(REPLACE(REPLACE(RTRIM(LTRIM(@timestring)), ' ', ':'), '.', ':')) = 1 THEN CONVERT(time, REPLACE(REPLACE(RTRIM(LTRIM(@timestring)), ' ', ':'), '.', ':'))
			 WHEN ISNUMERIC(@timestring) = 1 THEN CAST(DATEADD(MINUTE, (@timestring/100 * 60) + (@timestring % 100), 0) AS time) ELSE NULL END
END

GO
