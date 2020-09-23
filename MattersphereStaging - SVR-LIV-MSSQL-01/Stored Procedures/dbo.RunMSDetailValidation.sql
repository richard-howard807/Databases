SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[RunMSDetailValidation]

AS
BEGIN

DECLARE @DatabaseName AS nvarchar(100)
SET @DatabaseName=(SELECT Value FROM dbo.controlTable WHERE [Description]='envDb')

DECLARE @SQL AS NVARCHAR(MAX)
SET @SQL='UPDATE a
SET a.StatusID=6
,a.errormsg=''Invalid column '' + a.[MScode]
,a.error=''403''
FROM  MattersphereStaging.dbo.MSDetailStage AS a
LEFT OUTER JOIN (
SELECT TABLE_NAME,COLUMN_NAME FROM  '+ @DatabaseName  + '.INFORMATION_SCHEMA.COLUMNS
) AS ProdTable
 ON UPPER(RTRIM(a.[MSTable]))=UPPER(TABLE_NAME )
 AND UPPER(RTRIM(a.[MScode]))=UPPER(COLUMN_NAME)
WHERE TABLE_NAME IS NULL AND a.StatusID=0'


EXEC (@SQL)

UPDATE MattersphereStaging.dbo.MSDetailStage
SET StatusID=6,errormsg='File doest exist'
WHERE FileID IS NULL


UPDATE MattersphereStaging.dbo.MSDetailStage
SET MSCaseText=RTRIM(MSCaseText)
WHERE MSCaseText IS NOT NULL


UPDATE MattersphereStaging.dbo.MSDetailStage
SET StatusID=6,errormsg='Record has no data'
WHERE MSCaseText IS NULL AND MSCaseValue IS NULL AND MSCaseDate IS NULL



UPDATE MattersphereStaging.dbo.MSDetailStage
SET StatusID=7
WHERE StatusID= 0


UPDATE MattersphereStaging.dbo.MSDetailStage
SET errormsg='Data does not match lookup'
WHERE StatusID= 9

UPDATE a
SET StatusID=6,errormsg='File not MS Only'
FROM dbo.MSDetailStage AS a
INNER JOIN MS_PROD.dbo.udExtFile AS b WITH(NOLOCK)
 ON a.FileID=b.fileID
WHERE ISNULL(bitMSOnlyMM,0)=0


UPDATE a
SET StatusID=6,errormsg='Duplicate data in spreadsheet remove dups'
FROM dbo.MSDetailStage AS a
INNER JOIN (SELECT DetailStage.fileID,DetailStage.MScode,COUNT(1) AS NoDups
FROM (SELECT DISTINCT  fileID,MScode,MSCaseDate,MSCaseValue,MSCaseText  FROM dbo.MSDetailStage) AS DetailStage
GROUP BY DetailStage.fileID,DetailStage.MScode
HAVING COUNT(1)>1) AS b
 ON a.fileID=b.fileID
 AND a.MScode=b.MScode




END 
GO
