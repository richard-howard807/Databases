SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[ufnCleanseClientMatterString] (
	@ClientMatter varchar(50)
)
RETURNS varchar(50)
AS
BEGIN
	DECLARE @ClientCode varchar(50)
		  , @MatterCode varchar(50)
		  , @result varchar(50)
		  
	SET @ClientMatter = LTRIM(RTRIM(ISNULL(@ClientMatter, '')))
	
	IF LEN(@ClientMatter) < 3 RETURN ''
	
	IF CHARINDEX('/', @ClientMatter) > 0
	BEGIN
		SET @ClientCode = RTRIM(LTRIM(LEFT(@ClientMatter, CHARINDEX('/', @ClientMatter) - 1)))
		SET @MatterCode = RTRIM(LTRIM(RIGHT(@ClientMatter, LEN(@ClientMatter) - CHARINDEX('/', @ClientMatter))))
	END
	ELSE IF CHARINDEX('\', @ClientMatter) > 0
	BEGIN
		SET @ClientCode = RTRIM(LTRIM(LEFT(@ClientMatter, CHARINDEX('\', @ClientMatter) - 1)))
		SET @MatterCode = RTRIM(LTRIM(RIGHT(@ClientMatter, LEN(@ClientMatter) - CHARINDEX('\', @ClientMatter))))
	END
	ELSE IF CHARINDEX('.', @ClientMatter) > 0
	BEGIN
		SET @ClientCode = RTRIM(LTRIM(LEFT(@ClientMatter, CHARINDEX('.', @ClientMatter) - 1)))
		SET @MatterCode = RTRIM(LTRIM(RIGHT(@ClientMatter, LEN(@ClientMatter) - CHARINDEX('.', @ClientMatter))))
	END
	ELSE IF CHARINDEX(' ', @ClientMatter) > 0
	BEGIN
		SET @ClientCode = RTRIM(LTRIM(LEFT(@ClientMatter, CHARINDEX(' ', @ClientMatter) - 1)))
		SET @MatterCode = RTRIM(LTRIM(RIGHT(@ClientMatter, LEN(@ClientMatter) - CHARINDEX(' ', @ClientMatter))))
	END
	ELSE IF CHARINDEX(CHAR(9), @ClientMatter) > 0
	BEGIN
		SET @ClientCode = RTRIM(LTRIM(LEFT(@ClientMatter, CHARINDEX(CHAR(9), @ClientMatter) - 1)))
		SET @MatterCode = RTRIM(LTRIM(RIGHT(@ClientMatter, LEN(@ClientMatter) - CHARINDEX(CHAR(9), @ClientMatter))))
	END
	ELSE 
	BEGIN
		SET @ClientCode = ''
		SET @MatterCode = ''
	END
	
	IF ISNUMERIC(LEFT(@ClientCode, 1)) = 1 SET @ClientCode = REPLICATE('0', 8 - LEN(@ClientCode)) + @ClientCode
	IF ISNUMERIC(LEFT(@MatterCode, 1)) = 1 SET @MatterCode = REPLICATE('0', 8 - LEN(@MatterCode)) + @MatterCode
	
	SET @result = @ClientCode + '_' + @MatterCode
	
	SET @result = REPLACE(@result, CHAR(0), '')
	SET @result = REPLACE(@result, CHAR(9), '')
	SET @result = REPLACE(@result, CHAR(10), '')
	SET @result = REPLACE(@result, CHAR(13), '')
	SET @result = REPLACE(@result, ' ', '')
	SET @result = REPLACE(@result, '.', '')
	SET @result = REPLACE(@result, '/', '')
	SET @result = REPLACE(@result, '\', '')
	
	RETURN @result
END
GO
