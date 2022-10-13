SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fn_StripCharacters] (     @String NVARCHAR(MAX),      @MatchExpression VARCHAR(255) ) RETURNS NVARCHAR(MAX) AS BEGIN     SET @MatchExpression =  '%['+@MatchExpression+']%'      WHILE PATINDEX(@MatchExpression, @String) > 0         SET @String = STUFF(@String, PATINDEX(@MatchExpression, @String), 1, '')      RETURN @String  END 
GO
