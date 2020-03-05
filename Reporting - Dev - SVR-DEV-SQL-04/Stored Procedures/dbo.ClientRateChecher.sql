SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ClientRateChecher]
AS
BEGIN

SELECT  
Client.AltNumber
,clNo
,client.DisplayName,clName,NoFiles AS [Number Active Matters]
,RateDateDet.Arrangement
,Timekeeper.DisplayName AS [Partner]
FROM TE_3E_PROD.dbo.Client
INNER JOIN MS_Prod.config.dbClient
 ON Client.ClientIndex=dbClient.clextID

INNER JOIN (SELECT clNo AS [MS Client],'Yes' AS ActiveMatters,COUNT(f.fileid) AS NoFiles
				FROM MS_PROD.config.dbClient c
				INNER JOIN  MS_PROD.config.dbFile f On c.clid = f.clid
			WHERE fileStatus='LIVE'
			AND fileNo<>'0'
			GROUP BY clNo
			) AS ActiveMatters
 ON dbClient.clNo=ActiveMatters.[MS Client]
LEFT JOIN [TE_3E_PROD].dbo.CliDate ON CliDate.ClientLkUp = Client.ClientIndex
LEFT JOIN [TE_3E_PROD].[dbo].[RateDateDet] ON RateDateDet.Arrangement = client.Number
LEFT JOIN [TE_3E_PROD].[dbo].Timekeeper
 ON CliDate.spvtkpr=Timekeeper.TkprIndex

WHERE RateDateDet.Arrangement IS NULL
AND clNo NOT LIKE 'EMP%'

END
GO
