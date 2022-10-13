SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [CIS].[CoopMIUSLAOutcomes] --EXEC [CIS].[CoopMIUSLAOutcomes] '2014-11-01','2014-11-30'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN



SELECT *,CASE WHEN Outcome LIKE 'Settled%' THEN 1 ELSE 0 END AS [Settled]
,CASE WHEN Outcome ='Lost at trial' THEN 1 ELSE 0 END AS Lost           
FROM CIS.MIUSLAONOutcomes
WHERE [Year Period]=YEAR(@StartDate)
AND CAST(Period AS VARCHAR(2)) + ' ' + CAST([Year Period] AS VARCHAR(4)) <> 'P8 2014'
AND  InsertedDate <=@EndDate
END

GO
