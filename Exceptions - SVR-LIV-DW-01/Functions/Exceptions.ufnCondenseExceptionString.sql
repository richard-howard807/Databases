SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT Exceptions.ufnCondenseExceptionString('aaa (1) | aaa (13) | bbb | bbb (5) | ccc', ' | ')

CREATE FUNCTION [Exceptions].[ufnCondenseExceptionString] (
	  @ExceptionString varchar(MAX)
	, @Delimiter varchar(10) = ' | '
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @ret AS varchar(MAX)
	
	SELECT @ret = dbo.Concatenate(part, @Delimiter) + @Delimiter
	FROM (
		SELECT MIN(part) AS part
		FROM [Reporting].[ufnSplitDelimitedString](@ExceptionString, @Delimiter)
		GROUP BY (CASE WHEN patindex('%([0-9][0-9])', part) > 0 THEN LEFT(part, patindex('%([0-9][0-9])', part) - 1)
					   WHEN patindex('%([0-9])', part) > 0 THEN LEFT(part, patindex('%([0-9])', part) - 1)
					   ELSE part END)
	) condensed
	
	RETURN @ret
END
GO
