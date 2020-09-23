SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create PROC [dbo].[CaseDetailStageCreateTables]
AS

IF EXISTS (SELECT * FROM tempdb..SYSOBJECTS WHERE NAME LIKE '#TablesThatNeedCreating%')
BEGIN

--DROP TABLE #TablesThatNeedChanging 
PRINT  ''

END

DECLARE @SQL varchar(max)


;WITH CTERequiredTables
AS
(
--Get the required tables
SELECT
DISTINCT MSTable AS TABLE_NAME
FROM dbo.CaseDetailsStage
WHERE MSTable IS NOT NULL
)
--,CTEExistingTables AS
--(
----Get the tables that exist already
--SELECT
--TABLE_NAME 
--FROM INFORMATION_SCHEMA.TABLES
--WHERE TABLE_SCHEMA = 'dbo'
--)
SELECT 
CRT.TABLE_NAME
INTO #TablesThatNeedCreating
FROM CTERequiredTables CRT



DECLARE TABLEAdditions CURSOR
FOR
SELECT TABLE_NAME FROM #TablesThatNeedCreating

OPEN TABLEAdditions

FETCH NEXT FROM TABLEAdditions INTO @SQL
WHILE @@FETCH_STATUS = 0
BEGIN

EXEC [dbo].[MatterSphereStageTableCreate] @SQL

FETCH NEXT FROM TABLEAdditions INTO @SQL
END
CLOSE TABLEAdditions
DEALLOCATE TABLEAdditions
GO
