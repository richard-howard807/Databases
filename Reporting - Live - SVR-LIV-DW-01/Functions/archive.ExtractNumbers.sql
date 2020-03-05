SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- SELECT Archive.ExtractNumbers('as4khd0939sdf78')

CREATE FUNCTION [archive].[ExtractNumbers] (
	@inputstring varchar(100)
)
RETURNS bigint
AS
BEGIN
	DECLARE @result varchar(100) = ''

	SELECT  @result = @result + (CASE WHEN number LIKE '[0-9]' THEN number ELSE '' END)
	FROM    (SELECT SUBSTRING(@inputstring, number, 1) AS number
			 FROM   (SELECT number FROM master..spt_values WHERE type= 'p' AND number BETWEEN 1 AND LEN (@inputstring)) AS t) AS t 

	RETURN @result
END
GO
