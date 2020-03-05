SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[Artiion.NameKev]
(
       @forname VARCHAR(1000), 
       @name VARCHAR(1000),
       @title VARCHAR(50),
       @inits VARCHAR(10)
)
RETURNS varchar(255)
AS
BEGIN

DECLARE @ret varchar(255)
DECLARE @added BIT
SET @added = 0
SET  @ret = ''

SET @forname = LTRIM(RTRIM(@forname))
SET @name = LTRIM(RTRIM(@name))
SET @title = LTRIM(RTRIM(@title))
SET @inits = LTRIM(RTRIM(@inits))

IF @forname IS NOT NULL AND @forname != ''
BEGIN
       SET @ret = @forname
       SET @added = 1
END
  
IF @name IS NOT NULL AND @name != ''
BEGIN

       IF  @added = 1
       BEGIN
              SET @ret = @ret + ', '
       END
       ELSE
              SET @added = 1 

       SET @ret = @ret + @name
END

IF @title IS NOT NULL AND @title != ''
BEGIN

       IF  @added = 1
       BEGIN
              SET @ret = @ret + ', '
       END
       ELSE
              SET @added = 1 

       SET @ret = @ret + @title
END

IF @inits IS NOT NULL AND @inits != ''
BEGIN

       IF  @added = 1
       BEGIN
              SET @ret = @ret + ', '
       END
       ELSE
              SET @added = 1 

       SET @ret = @ret + @inits
END

RETURN (@ret)

END

GO
