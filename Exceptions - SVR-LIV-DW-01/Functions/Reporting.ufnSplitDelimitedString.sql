SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- SELECT * FROM [dbo].[ufnSplitDelimitedString]('aaa | bbb | ccc | ', ' | ')
-- SELECT * FROM [dbo].[ufnSplitDelimitedString]('aaa,bbb,ccc,', ',')

CREATE FUNCTION [Reporting].[ufnSplitDelimitedString]
    (
      @InputString VARCHAR(MAX)
    , @Delimiter VARCHAR(10)
    )
RETURNS @tbl TABLE (rownum int, part VARCHAR(MAX))
AS BEGIN
    DECLARE @i INT
      , @j INT
    SELECT  @i = 1
    WHILE @i <= LEN(@InputString) 
        BEGIN
            SELECT  @j = CHARINDEX(@Delimiter, @InputString, @i + 1)
            IF @j = 0 
                BEGIN
					IF @Delimiter = ''
						SELECT  @j = @i + 1
					ELSE
						SELECT  @j = LEN(@InputString) + 1
                END
            INSERT  @tbl
                    SELECT ISNULL((SELECT MAX(rownum) FROM @tbl), 0) + 1, SUBSTRING(@InputString, @i, @j - @i)
            SELECT  @i = @j + DATALENGTH(@Delimiter)
        END
    RETURN
   END



GO
