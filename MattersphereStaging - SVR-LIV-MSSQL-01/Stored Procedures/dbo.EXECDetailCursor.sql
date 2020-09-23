SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[EXECDetailCursor]
AS
BEGIN

SET NOCOUNT ON

DECLARE @@CaseDetailTables AS TABLE
(MSTable nvarchar(255)
,TableType nvarchar(255)
, RowID INT, Processed INT)

DECLARE @@CaseDetailTables1 AS TABLE
(MSTable nvarchar(255)
,TableType nvarchar(255)
)

INSERT INTO @@CaseDetailTables1
SELECT DISTINCT MSTable,CASE WHEN DataType='uCodeLookup:nvarchar(15)' THEN 'text'
							 WHEN DataType='nvarchar(50)' THEN 'text'
							 WHEN DataType='nvarchar(60)' THEN 'text'
							 WHEN DataType='nvarchar(250)' THEN 'text'
							 WHEN DataType='money' THEN 'value'
							 WHEN DataType='datetime' then 'date' 
							 WHEN MScode LIKE 'dte%' THEN 'date'
							 WHEN MScode LIKE 'cur%' THEN 'value'
							 WHEN MScode LIKE 'cbo%' THEN 'text'
							 WHEN MScode LIKE 'txt%' THEN 'text'
							 END AS [Type]
FROM [MattersphereStaging].[dbo].CaseDetailsStage


INSERT INTO @@CaseDetailTables
SELECT  MSTable,TableType, ROW_NUMBER()OVER(ORDER BY MSTable) ,0 AS Processed
FROM @@CaseDetailTables1


DECLARE @RowID AS INT
	SET @RowID = 0

	WHILE	EXISTS ( 
				 SELECT TOP 1
                        1
                 FROM   @@CaseDetailTables
                 WHERE Processed = 0
                 ORDER BY MSTAble
                 )
                 
BEGIN 
DECLARE @TableType nvarchar(255)
DECLARE @TableName nvarchar(255)

SELECT TOP 1 @TableName = MSTable
,@TableType=TableType
,@RowID = RowId

FROM @@CaseDetailTables
WHERE RowID > @RowID
AND Processed = 0


EXEC dbo.MatterSphereDynamicPivot @TableType,@TableName

UPDATE @@CaseDetailTables
SET Processed = 1
WHERE RowID = @RowID

END


END
GO
