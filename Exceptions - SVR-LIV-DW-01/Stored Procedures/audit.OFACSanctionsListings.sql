SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [audit].[OFACSanctionsListings]
AS
BEGIN

IF OBJECT_ID('tempdb..#AllData') IS NOT NULL DROP TABLE #AllData

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
INTO #AllData
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




SELECT [SanctionNam]
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
,COALESCE(cboDoBObtain,[Was DoB obtained?]) AS  [Was DoB obtained?]
,COALESCE(cboRevFileSanLi,[Reviewed file against Sanctions list]) AS  [Reviewed file against Sanctions list] 
,COALESCE(dteDateSanRev,[Date Sanctions list reviewed]) AS [Date Sanctions list reviewed]
,[Re-Check Needed]
,[AmberCheck]
,[ExtraRed]
,[Sanction Name]
,[OFACDOB]
,[SDN DOB]
,[InsertDate]
,[Type check]
,[PreviousRunDOB]
,COALESCE(MSRef1,MSRef2)  AS MSReference
,txtAMLComments 
FROM #AllData AS AllData

LEFT OUTER JOIN (SELECT case_id,clNo+'.'+ fileNo AS MSRef1 FROM red_dw.dbo.dim_matter_header_current 
INNER JOIN MS_Prod.config.dbFile ON ms_fileid=fileID
INNER JOIN MS_Prod.config.dbClient ON dbFile.clID=dbClient.clID) AS MSRef1
 ON AllData.[CaseID]=MSRef1.case_id AND AllData.SourceID=1

LEFT OUTER JOIN (SELECT ms_fileid,clNo+'.'+ fileNo AS MSRef2 FROM red_dw.dbo.dim_matter_header_current 
INNER JOIN MS_Prod.config.dbFile ON ms_fileid=fileID
INNER JOIN MS_Prod.config.dbClient ON dbFile.clID=dbClient.clID) AS MSRef2
 ON AllData.[CaseID]=MSRef2.ms_fileid AND AllData.SourceID=2

LEFT OUTER JOIN (SELECT case_id,dbfile.fileID,dteDateSanRev
,CASE WHEN cboRevFileSanLi='NO' THEN 'No' 
	  WHEN cboRevFileSanLi='YES' THEN 'Yes'
	  WHEN cboRevFileSanLi='YTR' THEN 'Yes - temporary reviewed'
	  WHEN cboRevFileSanLi='YRS' THEN 'Yes - reviewed sanctions' END AS cboRevFileSanLi
,CASE WHEN cboDoBObtain='NO' THEN 'No' 
	  WHEN cboDoBObtain='YES' THEN 'Yes'
	  WHEN cboDoBObtain='NOACP' THEN 'No - DOB appears in case plan' END AS cboDoBObtain 
,dteDateofBirth 
,udAMLProcess.txtAMLComments 
FROM MS_Prod.config.dbFile
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dbFile.fileID=ms_fileid
INNER JOIN MS_Prod.config.dbClient
 ON dbFile.clID=dbClient.clID
INNER JOIN MS_Prod.dbo.udExtFile
 ON dbFile.fileID=udExtFile.fileID
INNER JOIN MS_Prod.dbo.udAMLProcess 
 ON dbFile.fileID=udAMLProcess.fileID
) AS SanctionReviewed
 ON MSRef2.ms_fileid=SanctionReviewed.fileID
WHERE AllData.[Weightmans Ref] + AllData.[Systems] NOT IN 
(
'Z1001.00078213FED' 
,'00046018.00002739FED'
,'Z00011.00000803FED'
,'00093688.00000056FED'
,'A00002.00006729FED'
,'W15624.00000251FED'
,'GRP001.00001089FED'
)-- Asked remove as it is included in the MS record - requested by Angela Shepard 24.05.21 & 27.07.21

END
GO
