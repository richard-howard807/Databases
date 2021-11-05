SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE FUNCTION [dbo].[remove_carriage_return]
	(  
		@INPUT_STRING nvarchar(max)
	)
RETURNS nVARCHAR(max)
AS


BEGIN
	SET @INPUT_STRING = replace(replace(replace(REPLACE(REPLACE(@INPUT_STRING, Char (13), ' '), char (10), ': '), Char (9), '  '),'Â ', ''), 'Â','')
	RETURN @INPUT_STRING
END
GO
GRANT EXECUTE ON  [dbo].[remove_carriage_return] TO [SBC\DWH_SSASAdmin]
GO
