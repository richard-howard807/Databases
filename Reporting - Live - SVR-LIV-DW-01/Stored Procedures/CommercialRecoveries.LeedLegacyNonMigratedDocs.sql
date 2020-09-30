SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [CommercialRecoveries].[LeedLegacyNonMigratedDocs]
(
@SourceSystemID AS NVARCHAR(100)
)
AS 
BEGIN
--SET @SourceSystemID='13509-4246'

IF OBJECT_ID('tempdb..#FWDocsUnstructuredReport') IS NOT NULL   DROP TABLE #FWDocsUnstructuredReport

CREATE TABLE #FWDocsUnstructuredReport
(
	[SourceSystemID] [NVARCHAR](50) NULL,
	[Date Added] [DATETIME] NULL,
	[Additional Description] [VARCHAR](MAX) NULL,
	[Client] [BIGINT] NULL,
	[Matter] [BIGINT] NULL
)
INSERT INTO #FWDocsUnstructuredReport
(
    SourceSystemID,
    [Date Added],
    [Additional Description],
    Client,
    Matter
)
SELECT RTRIM(CAST(mhclin AS NVARCHAR(20))) + '-' + RTRIM(CAST(mhmatn AS NVARCHAR(20))) AS SourceSystemID,
mhdate AS [Date Added]
,CAST(mhdesc AS NVARCHAR(MAX))  AS [Additional Description]
,mhclin  AS Client
,mhmatn AS Matter
FROM [SVR-LIV-3PTY-01].fw_webdb.dbo.MHFILE WITH (NOLOCK)
WHERE mhdesc LIKE '%<a href=file://fw1/documents%' 
AND RTRIM(CAST(mhclin AS NVARCHAR(20)))+ '-' + RTRIM(CAST(mhmatn AS NVARCHAR(20)))=@SourceSystemID




SELECT Combined.SourceSystemID
,LEFT([DocumentSource],255) AS [DocumentSource]
,CASE WHEN LEFT([DocumentTitle],10) LIKE '%<a href%'  THEN [DocumentTitle]  WHEN Combined.DocumentTitle LIKE  '%<a href%' THEN SUBSTRING([DocumentTitle],0, CHARINDEX('<a',[DocumentTitle])) ELSE Combined.DocumentTitle END AS [DocumentTitle]
,[DocumentNumber] 
,CAST([DocumentExtension] AS VARCHAR(10)) AS [DocumentExtension] 
,[CreationDate] 
,[ModifiedDate]

FROM 
(SELECT  CAST('\\svr-liv-fs-09\Documents\' + CAST(CAST(REPLACE(Client,'FW','') AS INT) AS VARCHAR(MAX)) + '\' + CAST(CAST(Matter AS INT) AS VARCHAR(MAX)) + '\' 
+ REPLACE(REPLACE(REPLACE((SUBSTRING([Document Source],CHARINDEX('>',[Document Source])+1,LEN([Document Source]))),'See document',''),'<\a>',''),' ','')  AS VARCHAR(1000)) AS [DocumentSource]
,CAST(LEFT([Additional Description],150) AS VARCHAR(150))  AS [DocumentTitle]
,CAST([DocumentNumber] AS VARCHAR(1000))AS [DocumentNumber] 
,CAST(REPLACE(RIGHT(REPLACE(REPLACE(REPLACE((SUBSTRING([Document Source],CHARINDEX('>',[Document Source])+1,LEN([Document Source]))),'See document',''),'<\a>',''),' ',''),4),'.','') AS VARCHAR(1000)) AS [DocumentExtension] 
,'Converted Documents' AS [DocWallet] 
,[Date Added] AS [CreationDate] 
,[Date Added] AS [ModifiedDate]
,SourceSystemID
FROM 
(SELECT 
SourceSystemID
,[Date Added]
,CAST(ROW_NUMBER() OVER(ORDER BY [Additional Description] ASC)  AS VARCHAR(100)) AS [DocumentNumber]
,REPLACE(REPLACE((SUBSTRING([Additional Description],CHARINDEX('<a',[Additional Description])+1,LEN([Additional Description])))
,'a href=file://fw1/Documents/','\\svr-liv-fs-09\Documents'),'/','\') AS [Document Source]
,[Additional Description]
,Client,Matter
 FROM #FWDocsUnstructuredReport
 ) AS AllData
 ) AS Combined
 ORDER BY Combined.SourceSystemID,Combined.CreationDate  ASC

END
GO
