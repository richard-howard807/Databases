SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Newcastle].[CameronBrewery]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 
BEGIN

SELECT  clNo+ '.'+fileNo AS [File Number]
,fileDesc AS [Matter Description]
,curRevEstimate AS [Agreed Fee]
,Financials.FeesBilledToDate AS [Fees Billed to Date]
,Financials.MonthFees AS [Monthly Fees]
,ISNULL(curRevEstimate,0) - Financials.FeesBilledToDate AS [Fees to be Billed]
FROM MS_PROD.config.dbFile WITH(NOLOCK)
INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK)
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_PROD.dbo.udExtFile WITH(NOLOCK)
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,SUM(CASE WHEN InvDate BETWEEN @StartDate AND @EndDate THEN OrgFee ELSE NULL END) AS MonthFees
FROM TE_3E_Prod.dbo.InvMaster WITH(NOLOCK)
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN MS_PROD.dbo.udMICoreGeneral WITH(NOLOCK)
 ON udMICoreGeneral.fileID = udExtFile.fileID
WHERE clNo IN ('W22555','W24107')
--AND fileNo<>'1'
AND fileNo<>'0'
ORDER BY fileNo ASC

END
GO
