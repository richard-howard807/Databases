SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[udf_GetStringArray] (
	@CSVString varchar(MAX)
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @StringArray varchar(MAX)

	SELECT @StringArray = (
		SELECT '''' + ListValue + ''',' AS [text()]
		FROM dbo.udt_TallySplit(',', @CSVString)
		FOR XML PATH ('')
	)
	
	SET @StringArray = LEFT(@StringArray, LEN(@StringArray) - 1)
	
	RETURN @StringArray
END
GO
