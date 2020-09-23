SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: 18.10.16
-- Description:	Validates SearchListDetailStage in regards to all data
-- =============================================
CREATE  PROCEDURE [dbo].[RunSearchListValidation]

AS
BEGIN

DECLARE @DatabaseName AS nvarchar(100)
SET @DatabaseName=(SELECT Value FROM dbo.controlTable WHERE [Description]='envDb')

DECLARE @SQL AS NVARCHAR(MAX)
SET @SQL='UPDATE a
SET a.StatusID=6
,a.errormsg=''Invalid column '' + a.[MScode]
,a.error=''403''
FROM  MattersphereStaging.dbo.SearchListDetailStage AS a
LEFT OUTER JOIN (
SELECT TABLE_NAME,COLUMN_NAME FROM  '+ @DatabaseName  + '.INFORMATION_SCHEMA.COLUMNS
) AS ProdTable
 ON UPPER(RTRIM(a.[MSTable]))=UPPER(TABLE_NAME )
 AND UPPER(RTRIM(a.[MScode]))=UPPER(COLUMN_NAME)
WHERE TABLE_NAME IS NULL AND a.StatusID=0'


EXEC (@SQL)


UPDATE MattersphereStaging.dbo.SearchListDetailStage
SET StatusID=7
WHERE StatusID= 0


UPDATE  MattersphereStaging.dbo.SearchListDetailStage
SET StatusID=7
WHERE StatusID <>0 AND FEDCaseDate IS NULL AND FEDCaseText IS NULL AND FEDCaseValue IS NULL 


END 
GO
