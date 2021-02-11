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
ISNULL(REPLACE(CRSystemSourceID,'-','.'),clNo+ '.'+fileNo)  AS [Matter Number]
,fileDesc AS [Matter Description]
,dbFile.Created AS [Date Opened]
,dteEngrDispatch AS [Engrossment sent to NPG]
,dteCompletionD AS [Completion Date]
,DATEDIFF(DAY,dbFile.Created,dteEngrDispatch) AS [Days opened to Engrossment]
,DATEDIFF(DAY,dbFile.Created,dteCompletionD) AS [Days opened to completion]
,Financials.FeesBilledToDate AS [Fees (net of VAT & disbursements)]
,ISNULL(fileExternalNotes,txtNPGNote) AS [Commentary]
,CASE WHEN cboNPGFileType='COMLIT' THEN 'NPG ComLit Files' 
WHEN cboNPGFileType='PROPERTY' THEN 'NPG Property'
WHEN cboNPGFileType='WAYLEAVE' THEN 'NPG Wayleave' END AS cboNPGFileType

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
AND dteCompletionD BETWEEN @StartDate AND @EndDate
ORDER BY clno,fileno
END
GO
