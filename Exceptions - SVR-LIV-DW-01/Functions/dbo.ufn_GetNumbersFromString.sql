SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-09-05
-- Description:	added for Macro dashboard
-- =============================================
CREATE FUNCTION [dbo].[ufn_GetNumbersFromString]
(
	@string VARCHAR(100)
)
RETURNS INT
AS
BEGIN
	DECLARE @str VARCHAR(20)

	SET @str = ''
	WHILE @string LIKE '%[0-9]%' AND LEN(@string) > 0
	BEGIN
		IF LEFT(@string,1) LIKE '[0-9]' SET @str = @str + LEFT(@string,1)
		SET @string = RIGHT(@string,LEN(@string)-1)
	END

	RETURN CONVERT(INT,@str)

END
GO
