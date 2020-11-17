SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [Newcastle].[NPGClientReport]

AS 

BEGIN
SELECT 
dbFile.Created AS [Date opened]
,clName
,ISNULL(CRSystemSourceID,clNo+ '-'+fileNo) AS [Client and matter ref]
,usrFullName AS [Weightmans Handler]
,fileDesc AS [Matter Description]
,dteCompletionD AS [Date of completion]
,Financials.FeesBilledToDate AS [Revenue Billed]
,Disbursements AS [Disbursments Billed]
FROM [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbFile
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbUser
 ON filePrincipleID=usrID
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,SUM(OrgHCo) + SUM(OrgSCo) AS Disbursements
,SUM(CASE WHEN InvDate BETWEEN '2019-11-01' AND '2019-11-30' THEN OrgFee ELSE NULL END) AS MonthFees
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
ORDER BY clno,fileno
END
GO
