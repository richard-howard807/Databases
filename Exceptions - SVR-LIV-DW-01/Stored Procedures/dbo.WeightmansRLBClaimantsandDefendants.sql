SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[WeightmansRLBClaimantsandDefendants]
AS
BEGIN 


IF OBJECT_ID(N'tempdb..#Assocites') IS NOT NULL
BEGIN
DROP TABLE #Assocites
END

SELECT AllData.Client,
       AllData.Matter,
       AllData.Capacity,
       AllData.Description,
       AllData.CleanName,
       AllData.SourceID,
       AllData.CaseID
INTO #Assocites
FROM 
(SELECT Client,Matter,Capacity,ConflictSearch.Description,CleanName,ConflictSearch.SourceID,CaseID FROM ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable WITH(NOLOCK)
INNER JOIN ConflictSearch.dbo.ConflictSearch WITH(NOLOCK)
 ON EntityCode=code
WHERE CleanName  LIKE '%Weightmans%'
UNION
SELECT Client,Matter,Capacity,ConflictSearch.Description,CleanName,ConflictSearch.SourceID,CaseID FROM ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable WITH(NOLOCK)
INNER JOIN ConflictSearch.dbo.ConflictSearch
 ON EntityCode=code
WHERE CleanName  LIKE '%LeBrasseur%'
) AS AllData







SELECT Claimant.Client AS [Client],
       Claimant.Matter AS [Matter],
       Claimant.Description AS [Matter Description],
       Claimant.CleanName AS [Claimant],
        Defendant.CleanName AS Defendant
		,CASE WHEN Claimant.Description LIKE '%LeBrasseur%' AND Defendant.Description LIKE '%Weightmans%' THEN 1
		WHEN Defendant.Description LIKE '%LeBrasseur%' AND Claimant.Description LIKE '%Weightmans%' THEN 2 ELSE 0 END 
	   FROM (
SELECT #Assocites.Client,
       #Assocites.Matter,
       #Assocites.Capacity,
       #Assocites.Description,
       #Assocites.CleanName,
       #Assocites.SourceID,
       #Assocites.CaseID FROM #Assocites

WHERE Capacity LIKE '%Claimant%' OR Capacity IN ('CIFF1','CLABAR','CLAEXP','CLAIMINSSOL','CLASOL','CLASOLS')
) AS Claimant
INNER JOIN (SELECT #Assocites.Client,
       #Assocites.Matter,
       #Assocites.Capacity,
       #Assocites.Description,
       #Assocites.CleanName,
       #Assocites.SourceID,
       #Assocites.CaseID FROM #Assocites
	 WHERE   Capacity LIKE '%Defendant%' OR Capacity IN ('CODEF','DEF1INSCO','DEFAUTH1','DEFBAR','DEFBROK1','DEFEXP','DEFINSSOLS','DEFSOL','DEFSOLICITOR','DEFSOLS','DIS')
	   
	   ) AS Defendant
	    ON Defendant.CaseID = Claimant.CaseID
		AND Defendant.SourceID = Claimant.SourceID

END 
GO
