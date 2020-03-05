SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[OFACSanctionsListings]
AS
BEGIN
SELECT  DISTINCT  MainData.[SanctionNam]
,MainData.[MatchedClientName]
,MainData.[ClientNumber]
,MainData.[Matches]
,MainData.[No Possible Matches]
,MainData.[Number]
,MainData.[ClientName]
,MainData.[Capacity]
,MainData.[Systems]
,MainData.[Weightmans Ref]
,MainData.[Address1]
,MainData.[Address2]
,MainData.[Address3]
,MainData.[Address4]
,MainData.[Postcode]
,MainData.[uid]
,MainData.[Last Updated]
,MainData.[DateClosed]
,MainData.[Client Balance]
,MainData.[SourceID]
,MainData.[CaseID]
,MainData.[Is this a Linked File]
,MainData.[Linked Case]
,MainData.[Date of birth]
,MainData.[Was DoB obtained?]
,MainData.[Reviewed file against Sanctions list]
,MainData.[Date Sanctions list reviewed]
,CASE WHEN b.HASHVal IS NULL THEN 1
	  WHEN MainData.HASHVal<>b.HASHVal THEN 1 ELSE 0 END AS [Re-Check Needed]

,MainData.[AmberCheck]
,MainData.[ExtraRed]
,MainData.[Sanction Name]
,MainData.[OFACDOB]
,MainData.[SDN DOB]
,MainData.[InsertDate]
,CASE WHEN b.HASHVal IS NULL THEN 'Newly Added'
	  WHEN MainData.HASHVal<>b.HASHVal THEN 'Change Data' ELSE 'No Change' END [Type check]
,COALESCE(b.OFACDOB,b.[SDN DOB]) AS PreviousRunDOB
 FROM 
(
SELECT   DISTINCT [SanctionNam]
,[MatchedClientName]
,[ClientNumber]
,[Matches]
,[No Possible Matches]
,[Number]
,[ClientName]
,[Capacity]
,[Systems]
,[Weightmans Ref]
,[Address1]
,[Address2]
,[Address3]
,[Address4]
,[Postcode]
,[uid]
,[Last Updated]
,[DateClosed]
,[Client Balance]
,[SourceID]
,[CaseID]
,[Is this a Linked File]
,[Linked Case]
,[Date of birth]
,[Was DoB obtained?]
,[Reviewed file against Sanctions list]
,[Date Sanctions list reviewed]
,[Re-Check Needed]
,[AmberCheck]
,[ExtraRed]
,[Sanction Name]
,[OFACDOB]
,[SDN DOB]
,[InsertDate]
,HASHBYTES('SHA2_256',ISNULL(SanctionNam,'') + ISNULL(OFACDOB,'') + ISNULL([SDN DOB],'') + ISNULL(CAST(SourceID  AS NVARCHAR(1)),'')) AS HASHVal
 FROM  dbo.OFASanctions AS a
 WHERE MatchedClientName NOT IN ('IPCC') --excluded email from Angie Shepard 220118
AND ClientName NOT IN ('Claimant''s medical expert','Medical expert') --excluded email from Angie Shepard 220118
) AS MainData
LEFT OUTER JOIN 
(
SELECT   DISTINCT SanctionNam,OFACDOB,[SDN DOB],[Sanction Name],uid,SourceID,
HASHBYTES('SHA2_256',ISNULL(SanctionNam,'') + ISNULL(OFACDOB,'') + ISNULL([SDN DOB],'')+ ISNULL(CAST(SourceID AS NVARCHAR(1)),''))AS HASHVal
FROM  dbo.OFASanctionsPrevious AS a
 WHERE MatchedClientName NOT IN ('IPCC') --excluded email from Angie Shepard 220118
AND ClientName NOT IN ('Claimant''s medical expert','Medical expert') --excluded email from Angie Shepard 220118
) AS b
 ON  MainData.[Sanction Name]=b.[Sanction Name]
  AND MainData.SanctionNam=b.SanctionNam
  AND MainData.uid=b.uid
  AND MainData.SourceID=b.SourceID

END
GO
