SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [audit].[MLSearchs]
(
@StartDate AS DATE
,@EndDate AS DATE
,@Exception AS NVARCHAR(40)
)
AS
BEGIN


SELECT ListValue  INTO #Exception FROM Reporting.dbo.udt_TallySplit(',', @Exception)


SELECT 
AllData.fileID
,[Client]
,[Client Name]
,[Status]
,[File No]
,[Date Opened]
,[Date Closed]
,[was there an Individual search fee]
,[How many Individual searches were required]
,[How much was the Individual search fee]
,[was_there a Company search fee]
,[How much was the Company search fee]
,[How many UK Company searches were completed]
,[How many European searches were completed]
,[How many American searches were completed]
,[How many Rest of World searches were completed]
,[Total Fees]
,[Exception] 
FROM 
(
SELECT 
dbFile.fileID
,clNo AS [Client]
,clName AS [Client Name]
,clStatus AS [Status]
,fileNo AS [File No]
,dbFile.Created AS [Date Opened]
,dbFile.fileClosed AS [Date Closed]
,CASE WHEN cboIndSearch='Y' THEN 'Yes' WHEN cboIndSearch='N' THEN 'No' ELSE cboIndSearch END  AS [was there an Individual search fee]
,CAST(cboIndSearchNo  AS INT) AS [How many Individual searches were required]
,CAST([How much was the Individual search fee] AS DECIMAL(10,2)) AS [How much was the Individual search fee]
,CASE WHEN cboComSeaFee='Y' THEN 'Yes' WHEN cboComSeaFee='N' THEN 'No' ELSE cboComSeaFee END  AS [was_there a Company search fee]
,CAST([How much was the Company search fee] AS DECIMAL(10,2)) AS [How much was the Company search fee]
,CAST(cboUKCoSear  AS INT)AS [How many UK Company searches were completed]
,CAST(cboEuroCoSear  AS INT)AS [How many European searches were completed]
,CAST(cboUSASear  AS INT)AS [How many American searches were completed]
,CAST(cboWorldSear  AS INT) AS [How many Rest of World searches were completed]
,ISNULL(CAST(curTotalSearch AS DECIMAL(10,2)),0.00) AS [Total Fees]
,CASE WHEN cboCallML='EXEM' 
AND CAST([How much was the Individual search fee] AS DECIMAL(10,2))=0.00 
AND CAST([How much was the Company search fee] AS DECIMAL(10,2))=0.00
THEN 'Exempt' 
	  WHEN cboIndSearch IS NULL AND  cboComSeaFee IS NULL THEN 'Missing' 
	  ELSE 'Completed' END AS [Exception]
FROM MS_PROD.config.dbFile
INNER JOIN MS_PROD.config.dbClient
 ON dbFile.clID=dbClient.clID
LEFT OUTER JOIN MS_PROD.dbo.udAMLProcess
 ON dbFile.fileID=udAMLProcess.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curIndSearch) AS [How much was the Individual search fee]
,SUM(curCompSearch)  AS [How much was the Company search fee]
 FROM MS_PROD.dbo.udAMLSearchList
WHERE Active=1
GROUP BY fileID) AS Fees
 ON udAMLProcess.fileID=Fees.fileID
LEFT OUTER JOIN (SELECT fileid,udAMLSearchList.cboCallML
 FROM MS_PROD.dbo.udAMLSearchList
 WHERE Active=1) AS Excep
  ON dbFile.fileID=Excep.fileID
WHERE fileNo='0'
AND clName NOT LIKE '%error%'
AND clName NOT LIKE '%ERROR%'
AND clName NOT LIKE '%do not%'
AND clName NOT LIKE '%DO NOT%'
AND UPPER(clName) NOT LIKE '%TEST%'
AND CONVERT(DATE,dbfile.created,103) BETWEEN @StartDate AND @EndDate
) AS AllData
INNER JOIN #Exception AS Exception ON Exception.ListValue COLLATE database_default = [Exception] COLLATE database_default



END 
GO
