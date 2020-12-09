SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Newcastle].[AcronBidco] 

AS 
BEGIN

SELECT  ISNULL(CRSystemSourceID,clNo+ '-'+fileNo) AS [File Number]
,fileDesc AS [Matter Description]
,curCurrCostsEst AS [Agreed Fee]
,Financials.FeesBilledToDate AS [Fees Billed to Date]
,Financials.MonthFees AS [Monthly Fees]
,ISNULL(curCurrCostsEst,0) - Financials.FeesBilledToDate AS [Fees to be Billed]
FROM [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbFile
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,SUM(CASE WHEN InvDate BETWEEN '2020-10-01' AND '2020-10-31' THEN OrgFee ELSE NULL END) AS MonthFees
FROM [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.InvMaster WITH(NOLOCK)
INNER JOIN [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
WHERE clNo='WB172526'
AND fileNo<>'1'
AND fileNo<>'0'
ORDER BY fileNo ASC

END
GO
