SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [Newcastle].[NPGCompletionsReport]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 

BEGIN

SELECT 
--ISNULL(REPLACE(CRSystemSourceID,'-','.'),clNo+ '.'+fileNo)  AS [Matter Number]
clNo+ '.'+fileNo  AS [Matter Number] -- David T asked to remove the old reference
,fileDesc AS [Matter Description]
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS [Date Opened]
,[red_dw].[dbo].[datetimelocal](dteEngrDispatch) AS [Engrossment sent to NPG]
,[red_dw].[dbo].[datetimelocal](dteCompletionD) AS [Completion Date]
,DATEDIFF(DAY,[red_dw].[dbo].[datetimelocal](dbFile.Created),[red_dw].[dbo].[datetimelocal](dteEngrDispatch)) AS [Days opened to Engrossment]
,DATEDIFF(DAY,[red_dw].[dbo].[datetimelocal](dbFile.Created),[red_dw].[dbo].[datetimelocal](dteCompletionD)) AS [Days opened to completion]
,Financials.FeesBilledToDate AS [Fees (net of VAT & disbursements)]
,ISNULL(fileExternalNotes,txtNPGNote) AS [Commentary]
,CASE WHEN cboNPGFileType='COMLIT' THEN 'NPG ComLit Files' 
WHEN cboNPGFileType='PROPERTY' THEN 'NPG Property'
WHEN cboNPGFileType='WAYLEAVE' THEN 'NPG Wayleave' END AS cboNPGFileType
,usrFullName AS [Case Handler]
FROM MS_Prod.config.dbFile
INNER JOIN MS_Prod.dbo.dbUser
 ON filePrincipleID=usrID
INNER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
FROM TE_3E_Prod.dbo.InvMaster WITH(NOLOCK)
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN MS_Prod.dbo.udMIInitialReserves
 ON udMIInitialReserves.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udPlotSalesExchange
 ON udPlotSalesExchange.fileID = dbFile.fileID
WHERE clName LIKE '%Northern Powergrid%'
AND fileNo <>'0'
AND [red_dw].[dbo].[datetimelocal](dteCompletionD) BETWEEN @StartDate AND @EndDate
AND dbFile.fileID<>5197870
ORDER BY clno,fileno
END
GO
