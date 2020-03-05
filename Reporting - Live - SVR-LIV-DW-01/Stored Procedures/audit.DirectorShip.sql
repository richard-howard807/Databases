SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[DirectorShip] 


AS

BEGIN
IF OBJECT_ID('tempdb..#Directorships') IS NOT NULL
    DROP TABLE #Directorships
    
    SELECT REPLACE(Name,'  ',' ') AS Name
,[Last Updated]
,[Last Reviewed]
,[Name of Partner/employee]
,[Exact Position held]
,[Brief description of functions of the company, committee or inst]
,[Charitable/ non profit making - Yes or No ]
,[Location]
,[Does the company purchase D&O insurance Yes or No]

INTO #Directorships
FROM 
(
SELECT [Name of Company or Committee where position held]   AS Name
,[Last Updated]
,[Last Reviewed]
,[Name of Partner/employee]
,[Exact Position held]
,[Brief description of functions of the company, committee or inst]
,[Charitable/ non profit making - Yes or No ]
,[Location]
,[Does the company purchase D&O insurance Yes or No]

FROM SanctionsList.dbo.Directorships as a


) AS AllData



SELECT DISTINCT  Name AS SanctionNam
,CleanName AS MatchedClientName
,MainData.EntityCode AS ClientNumber
,CASE WHEN MainData.EntityCode IS NULL THEN 'No Match' ELSE 'Possible Match' END AS Matches
,CASE WHEN MainData.EntityCode IS NULL THEN 0 ELSE 1 END AS [No Possible Matches]
,1 AS Number
,[Capacity] AS ClientName
,[Type] AS Capacity
,[Systems]
,RTRIM(client) + '.' + RTRIM(matter) AS [Weightmans Ref]
,Address1
,Address2
,Address3
,Address4
,Postcode
,NULL AS GroupID
,[Is this a Linked File]
,[Linked Case]
,[Date of birth]
,[Was DoB obtained?]
,CASE WHEN [Last Reviewed] IS NULL OR [Last Reviewed] <[Last Updated] THEN 'No' ELSE 'Yes' END [Reviewed file against Sanctions list]
,[Last Reviewed] AS [Last Reviewed]
,[Last Updated]
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,CASE WHEN COALESCE(DateClosed,mg_datcls) IS NULL AND [Last Reviewed] IS NULL OR CONVERT(Date,[Last Updated],103) > CONVERT(Date,[Last Reviewed],103) THEN 1 ELSE 0 END [Re-Check Needed]
,0 AS AmberCheck
,CASE WHEN COALESCE(DateClosed,mg_datcls) IS NOT NULL AND  CONVERT(Date,[Last Updated],103) BETWEEN DATEADD(M,-3,GETDATE()) AND GETDATE() THEN 1 ELSE 0 END ExtraRed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,CaseID
,[Name of Partner/employee]
,[Exact Position held]
,[Brief description of functions of the company, committee or inst]
,[Charitable/ non profit making - Yes or No ]
,[Location]
,[Does the company purchase D&O insurance Yes or No]


FROM (
SELECT Sanctions.Name
,[Capacity]
,CleanName
,ConflictSearch.EntityCode
,ConflictSearch.[Description]
,ConflictSearch.[Text]
,CASE WHEN conflictsearch.SourceID=1 THEN 'FED' ELSE 'MatterSphere' END AS [Systems]
,Drilldown.[Type]
,client_account_balance_of_matter AS [Client Balance]
,Drilldown.Client
,Drilldown.Matter
,Drilldown.CaseID
,[Last Updated]
,[Last Reviewed]
,[Name of Partner/employee]
,[Exact Position held]
,[Brief description of functions of the company, committee or inst]
,[Charitable/ non profit making - Yes or No ]
,[Location]
,[Does the company purchase D&O insurance Yes or No]


,COALESCE(cboLinkedFile,NMI418.case_text) AS [Is this a Linked File]
,COALESCE(NMI419MS.txtLeadFileNo,NMI419.case_text) collate database_default AS [Linked Case]
,COALESCE(dteDateofBirth,AUD211.case_date) AS [Date of birth]
,COALESCE(AUD212.case_text,cboDoBObtain) AS [Was DoB obtained?]
,COALESCE(cboRevFileSanLi,AUD213.case_text) AS [Reviewed file against Sanctions list]
,COALESCE(dteDateSanRev,AUD214.case_date) AS [Date Sanctions list reviewed]
,ConflictSearch.SourceID AS SourceID
FROM #Directorships AS Sanctions
INNER JOIN ConflictSearch.dbo.ConflictSearch
 ON LOWER(Sanctions.Name) = LOWER(CleanName)
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='NMI418') AS NMI418
	   ON Drilldown.CaseID=NMI418.case_id AND Drilldown.SourceID=1
LEFT OUTER JOIN (SELECT fileID,CASE WHEN cboLinkedFile='Y' THEN 'Yes' WHEN cboLinkedFile='N' THEN 'No' END AS cboLinkedFile  FROm MS_PROD.dbo.udMICoreGeneral
	   WHERE cboLinkedFile IS NOT NULL) AS NMI418MS
	   ON Drilldown.CaseID=NMI418MS.fileID AND Drilldown.SourceID=2
	   
   
	   
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD212') AS AUD212
	   ON Drilldown.CaseID=AUD212.case_id AND Drilldown.SourceID=1	   
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD213') AS AUD213
	   ON Drilldown.CaseID=AUD213.case_id AND Drilldown.SourceID=1	 
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD211') AS AUD211
	   ON Drilldown.CaseID=AUD211.case_id AND Drilldown.SourceID=1	 	  
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD214') AS AUD214
	   ON Drilldown.CaseID=AUD214.case_id AND Drilldown.SourceID=1			  
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='NMI419') AS NMI419
	   ON Drilldown.CaseID=NMI419.case_id AND Drilldown.SourceID=1	
	
	   LEFT OUTER JOIN (SELECT fileID,txtLeadFileNo  FROm MS_PROD.dbo.udMICoreGeneral
	   WHERE txtLeadFileNo IS NOT NULL) AS NMI419MS
	   ON Drilldown.CaseID=NMI419MS.fileID AND Drilldown.SourceID=2
	   
LEFT OUTER JOIN (SELECT fileID,dteDateSanRev 
,CASE WHEN cboRevFileSanLi='NO' THEN 'No' 
	  WHEN cboRevFileSanLi='YES' THEN 'Yes'
	  WHEN cboRevFileSanLi='YTR' THEN 'Yes - temporary reviewed'
	  WHEN cboRevFileSanLi='YRS' THEN 'Yes - reviewed sanctions' END AS cboRevFileSanLi
,CASE WHEN cboDoBObtain='NO' THEN 'No' 
	  WHEN cboDoBObtain='YES' THEN 'Yes'
	  WHEN cboDoBObtain='NOACP' THEN 'No - DOB appears in case plan' END AS cboDoBObtain 
,dteDateofBirth 
 FROM MS_Prod.dbo.udAMLProcess  WITH (NOLOCK) 
 WHERE dteDateSanRev IS NOT NULL OR 
cboRevFileSanLi IS NOT NULL OR 
cboDoBObtain  IS NOT NULL OR 
dteDateofBirth  IS NOT NULL  
) AS MSDetails
 ON Drilldown.CaseID=MSDetails.fileID  
	   
LEFT OUTER  JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary
WHERE client_account_balance_of_matter <> 0) AS ClientBalance
 ON Drilldown.client=ClientBalance.client_code collate database_default  AND Drilldown.matter=matter_number collate database_default
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile  WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT mg_client,mg_matter,mg_datcls, 1 AS SourceID FROM axxia01.dbo.camatgrp) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client collate database_default AND MainData.Matter=FEDClosures.mg_matter collate database_default
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
  
 WHERE matter <>'0' 

 
END



GO
