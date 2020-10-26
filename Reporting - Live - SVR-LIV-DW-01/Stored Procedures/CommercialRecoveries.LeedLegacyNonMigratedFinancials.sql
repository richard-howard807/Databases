SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [CommercialRecoveries].[LeedLegacyNonMigratedFinancials]
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
SELECT clsern AS [Item]
,RTRIM(CAST(clclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(clmatn AS NVARCHAR(20))) AS SourceSystemID
,cldate AS [Date]
,cldes1 AS [Description 1]
,cldes2 AS [Description 2]
,cltype AS [Type]
,cloffa AS [Office]
,clclia AS [Client]
,clbill AS [Bill]
FROM [SVR-LIV-SQL-04\LEGACYREADONLY].[fwact].[dbo].[clfile]
WHERE RTRIM(CAST(clclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(clmatn AS NVARCHAR(20)))=@SourceSystemID
 ORDER BY clsern ASC


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
