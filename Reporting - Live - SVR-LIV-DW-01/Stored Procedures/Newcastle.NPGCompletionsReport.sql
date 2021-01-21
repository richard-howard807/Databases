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
ISNULL(CRSystemSourceID,clNo+ '-'+fileNo)  AS [Matter Number]
,fileDesc AS [Matter Description]
,dbFile.Created AS [Date Opened]
,dteEngrDispatch AS [Engrossment sent to NPG]
,dteCompletionD AS [Completion Date]
,DATEDIFF(DAY,dbFile.Created,dteEngrDispatch) AS [Days opened to Engrossment]
,DATEDIFF(DAY,dbFile.Created,dteCompletionD) AS [Days opened to completion]
,Financials.FeesBilledToDate AS [Fees (net of VAT & disbursements)]
,txtNPGNote AS [Commentary]
,CASE WHEN cboNPGFileType='COMLIT' THEN 'NPG ComLit Files' 
WHEN cboNPGFileType='PROPERTY' THEN 'NPG Property'
WHEN cboNPGFileType='WAYLEAVE' THEN 'NPG Wayleave' END AS cboNPGFileType

FROM [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbFile
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbUser
 ON filePrincipleID=usrID
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
FROM [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.InvMaster WITH(NOLOCK)
INNER JOIN [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMIInitialReserves
 ON udMIInitialReserves.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udPlotSalesExchange
 ON udPlotSalesExchange.fileID = dbFile.fileID
WHERE clName LIKE '%Northern Powergrid%'
AND fileNo <>'0'
AND dteCompletionD>='2021-02-01'
AND dteCompletionD BETWEEN @StartDate AND @EndDate
ORDER BY clno,fileno
END
GO
