SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--select dbo.VarcharToDecimal('     ')
--select dbo.VarcharToDateNEW('13/04/04')
--SELECT ISDate('03/03/2005')

CREATE  FUNCTION [dbo].[VarcharToDate]
    (
      @varcharDate VARCHAR(100)
    )
RETURNS VARCHAR(100)
AS 
    BEGIN
        DECLARE @convertResult VARCHAR(1000)
        DECLARE @TempDate VARCHAR(100)
        SET @varcharDate = LTRIM(RTRIM(@varcharDate))
	
        IF @varcharDate = ''
            OR @varcharDate IS NULL
            OR ( LEN(@varcharDate) < 8 ) 
            BEGIN
                SET @convertResult = '01/01/1900'
            END 	
        IF LEN(RTRIM(@varcharDate)) = 8 
            BEGIN
    
   
                SET @TempDate = CONVERT(DATE,CAST(SUBSTRING(@varcharDate, 4, 2) + '/'
                    + SUBSTRING(@varcharDate, 1, 2) + '/'
                    + SUBSTRING(@varcharDate, 7, 4) AS DATE),103)
                 IF ISDATE(@TempDate) = 1 
                    SET @ConvertResult = @TempDate
                ELSE 
                    SET @ConvertResult = '01/01/1900'
            END 
    
        ELSE 
            BEGIN
                SET @TempDate = SUBSTRING(@varcharDate, 4, 2) + '/'
                    + SUBSTRING(@varcharDate, 1, 2) + '/'
                    + SUBSTRING(@varcharDate, 7, 4)
                IF ISDATE(@TempDate) = 1 
                    SET @ConvertResult = ISNULL(@varcharDate, '01/01/1900')	
                ELSE 
                    SET @ConvertResult = '01/01/1900'
            END

        RETURN @convertResult
    END





GO
