SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[EXECDetailCursorNonFED]
AS

BEGIN 


DECLARE @DetailTable AS TABLE
(
[PK] INT IDENTITY(1,1) ,
MScode  NVARCHAR(MAX),
Completed  INT
)
INSERT INTO @DetailTable
SELECT DISTINCT MScode,0 As Processed FROM dbo.MSDetailStage
WHERE StatusID=7
ORDER BY MScode



DECLARE @pk INT
DECLARE @MScode  NVARCHAR(max)

SET @pk=0



WHILE	EXISTS ( 
				 SELECT TOP 1
                        1
                 FROM  @DetailTable
				 WHERE  [PK] > @pk
		AND Completed = 0
		ORDER BY pk
                 )
BEGIN

		
		SET	@pk = ''
		SET @MScode = ''

		
		
	SELECT TOP 1	@pk=pk
	,@MScode=MScode
	FROM @DetailTable
	WHERE  [PK] > @pk
    AND Completed = 0
		order by pk

DECLARE @MSTable AS NVARCHAR(MAX)
SET @MSTable=(SELECT DISTINCT MSTable FROM dbo.MSDetailStage WHERE MScode=@MSCode)

DECLARE @DataType AS NVARCHAR(MAX)
SET @DataType=(SELECT DISTINCT DataType FROM dbo.MSDetailStage WHERE MScode=@MSCode)



DECLARE @SQL1 AS NVARCHAR(MAX)

SET @SQL1=('MERGE.[MS_PROD].dbo.' + @MSTable + ' DEST USING (SELECT DISTINCT FileID,MSCaseDate FROM dbo.MSDetailStage AS a WHERE a.StatusID=7 
AND a.MSTable= ''' +@MSTable +'''
AND a.MSCode = ''' +@MSCode +'''
AND DataType=''datetime''
) AS src
ON DEST.fileID = src.fileID
WHEN MATCHED THEN
    UPDATE SET DEST.['+@MSCode +'] = src.[MSCaseDate]
WHEN NOT MATCHED THEN
    INSERT
    (
        fileID,
        ['+@MSCode +']
    )
    VALUES
    (fileID, src.[MSCaseDate]);')


DECLARE @SQL2 AS NVARCHAR(MAX)

SET @SQL2=('MERGE.[MS_PROD].dbo.' + @MSTable + ' DEST USING (SELECT DISTINCT FileID,MSCaseValue FROM dbo.MSDetailStage AS a WHERE a.StatusID=7 
AND a.MSTable= ''' +@MSTable +'''
AND a.MSCode = ''' +@MSCode +'''
AND DataType=''money''
) AS src
ON DEST.fileID = src.fileID
WHEN MATCHED THEN
    UPDATE SET DEST.['+@MSCode +'] = src.[MSCaseValue]
WHEN NOT MATCHED THEN
    INSERT
    (
        fileID,
        ['+@MSCode +']
    )
    VALUES
    (fileID, src.[MSCaseValue]);')



DECLARE @SQL3 AS NVARCHAR(MAX)

SET @SQL3=('MERGE.[MS_PROD].dbo.' + @MSTable + ' DEST USING (SELECT DISTINCT FileID,MSCaseText FROM dbo.MSDetailStage AS a WHERE a.StatusID=7 
AND a.MSTable= ''' +@MSTable +'''
AND a.MSCode = ''' +@MSCode +'''
AND DataType NOT IN (''money'',''datetime'')
) AS src
ON DEST.fileID = src.fileID
WHEN MATCHED THEN
    UPDATE SET DEST.['+@MSCode +'] = src.[MSCaseText]
WHEN NOT MATCHED THEN
    INSERT
    (
        fileID,
        ['+@MSCode +']
    )
    VALUES
    (fileID, src.[MSCaseText]);')

DECLARE @SQLStatement AS NVARCHAR(MAX)

IF @DataType='datetime'

BEGIN

SET @SQLStatement= @SQL1

END 

IF @DataType='money'

BEGIN

SET @SQLStatement= @SQL2

END 

IF @DataType NOT IN ('money','datetime')

BEGIN

SET @SQLStatement= @SQL3

END 



INSERT INTO DetailDynamicSQLOutput
(
DataType ,TableName,SQLStatement
)
SELECT CASE WHEN @DataType NOT IN ('money','datetime') THEN 'text' ELSE @DataType END,@MSTable,@SQLStatement

EXEC (@SQLStatement)

PRINT @SQLStatement


    UPDATE @DetailTable
	SET  Completed =   2  WHERE PK = @PK		

END 
END

GO
