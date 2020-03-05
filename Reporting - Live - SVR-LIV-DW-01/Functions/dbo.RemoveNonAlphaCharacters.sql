SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[RemoveNonAlphaCharacters] ( @Temp VARCHAR(1000) )
RETURNS VARCHAR(1000)
AS 
    BEGIN
        WHILE PATINDEX('%[^a-z]%', @Temp) > 0 
            SET @Temp = STUFF(@Temp, PATINDEX('%[^a-z]%', @Temp), 1, '')
        RETURN @TEmp
    END 
GO
