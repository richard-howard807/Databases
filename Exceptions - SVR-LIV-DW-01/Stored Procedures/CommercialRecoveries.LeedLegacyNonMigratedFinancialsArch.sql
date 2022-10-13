SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [CommercialRecoveries].[LeedLegacyNonMigratedFinancialsArch]
(
@SourceSystemID AS NVARCHAR(100)
)
AS 
BEGIN
--DECLARE @SourceSystemID AS NVARCHAR(100)
--SET @SourceSystemID='13509-4246'

IF OBJECT_ID('tempdb..#FWFinanceLedgerRaw') IS NOT NULL   DROP TABLE #FWFinanceLedgerRaw

CREATE TABLE #FWFinanceLedgerRaw
(
	[Item] [NUMERIC](9, 0) NULL,
	[SourceSystemID] [NCHAR](50) NULL,
	[Date] [DATETIME] NULL,
	[Description 1] [CHAR](30) NULL,
	[Description 2] [CHAR](30) NULL,
	[Type] [CHAR](4) NULL,
	[Office] [NUMERIC](12, 2) NULL,
	[Client] [NUMERIC](12, 2) NULL,
	[Bill] [NUMERIC](7, 0) NULL
)
INSERT INTO #FWFinanceLedgerRaw
(
    Item,
    SourceSystemID,
    Date,
    [Description 1],
    [Description 2],
    Type,
    Office,
    Client,
    Bill
)
SELECT alsern AS [Item]
,RTRIM(CAST(alclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(almatn AS NVARCHAR(20))) AS SourceSystemID
,aldate AS [Date]
,aldes1 AS [Description 1]
,aldes2 AS [Description 2]
,altype AS [Type]
,aloffa AS [Office]
,alclia AS [Client]
,albill AS [Bill]
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[alfile]
--WHERE RTRIM(CAST(alclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(almatn AS NVARCHAR(20)))=@SourceSystemID
WHERE alclin=(SUBSTRING(@SourceSystemID,0,CHARINDEX('-',@SourceSystemID,0)))
AND almatn=(SUBSTRING(@SourceSystemID,CHARINDEX('-',@SourceSystemID)+1,LEN(@SourceSystemID)) )

ORDER BY alsern ASC


SELECT [Item]
,SourceSystemID
,[Date]
,[Description 1]
,[Description 2]
,[Type]
,[Office]
,SUM (Office) OVER (PARTITION BY SourceSystemID ORDER BY Item)  [Office Balance]
,[Client]
,SUM (Client) OVER (PARTITION BY SourceSystemID ORDER BY Item) AS [Client Balance]
,[Bill] FROM #FWFinanceLedgerRaw

ORDER BY Item


END
GO
