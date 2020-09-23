SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CheckDetailInsertsNew]
AS
BEGIN



DECLARE @DetailTable AS TABLE
(
[PK] INT IDENTITY(1,1) ,
MScode  NVARCHAR(MAX),
Completed  INT
)
INSERT INTO @DetailTable
SELECT DISTINCT MScode,0 As Processed FROM MSDetailSuccess
WHERE  CONVERT(DATE,InsertDate,103)=CONVERT(DATE,GETDATE(),103)
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



DECLARE @SQL1 AS NVARCHAR(MAX)
DECLARE @SQL2 AS NVARCHAR(MAX)
DECLARE @SQL3 AS NVARCHAR(MAX)


SET @SQL1 =(
SELECT DISTINCT 
'SELECT a.fileID,MSCaseDate,'+ MScode +' AS '+ MScode +' FROM MSDetailSuccess AS a
LEFT OUTER JOIN MS_Prod.dbo.' + MSTable + ' AS b
 ON a.fileID=b.fileID
WHERE a.StatusID=7 
AND a.MSTable= ''' +MSTable +'''
AND a.MSCode = ''' +MSCode +'''
AND CONVERT(DATE,InsertDate,103)=CONVERT(DATE,GETDATE(),103)
AND DataType=''datetime''
AND MSCaseDate <> '+ MScode +'
'FROM MSDetailSuccess
WHERE MScode=@MScode
AND CONVERT(DATE,InsertDate,103)=CONVERT(DATE,GETDATE(),103)
AND DataType='datetime'
)

SET @SQL2 =(
SELECT DISTINCT 
'SELECT a.fileID,MSCaseValue,'+ MScode +' AS '+ MScode +' FROM MSDetailSuccess AS a
LEFT OUTER JOIN MS_Prod.dbo.' + MSTable + ' AS b
 ON a.fileID=b.fileID
WHERE a.StatusID=7 
AND a.MSTable= ''' +MSTable +'''
AND a.MSCode = ''' +MSCode +'''
AND CONVERT(DATE,InsertDate,103)=CONVERT(DATE,GETDATE(),103)
AND DataType=''money''
AND MSCaseValue <> '+ MScode +'
'FROM MSDetailSuccess
WHERE MScode=@MScode
AND CONVERT(DATE,InsertDate,103)=CONVERT(DATE,GETDATE(),103)
AND DataType='money'
)

SET @SQL3 =(
SELECT DISTINCT 
'SELECT a.fileID,MSCaseText,'+ MScode +' AS '+ MScode +' FROM MSDetailSuccess AS a
LEFT OUTER JOIN MS_Prod.dbo.' + MSTable + ' AS b
 ON a.fileID=b.fileID
WHERE a.StatusID=7 
AND a.MSTable= ''' +MSTable +'''
AND a.MSCode = ''' +MSCode +'''
AND CONVERT(DATE,InsertDate,103)=CONVERT(DATE,GETDATE(),103)
AND DataType NOT IN (''money'',''datetime'')
AND MSCaseText <> '+ MScode +'
'FROM MSDetailSuccess
WHERE MScode=@MScode
AND CONVERT(DATE,InsertDate,103)=CONVERT(DATE,GETDATE(),103)
AND DataType NOT IN ('money','datetime')
)

PRINT @SQL1
EXECUTE sp_executesql @SQL1
PRINT @SQL2
EXECUTE sp_executesql @SQL2
PRINT @SQL3
EXECUTE sp_executesql @SQL3



    UPDATE @DetailTable
	SET  Completed =   2  WHERE PK = @PK		

END 
END

GO
