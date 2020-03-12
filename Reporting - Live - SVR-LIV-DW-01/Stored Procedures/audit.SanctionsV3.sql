SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [audit].[SanctionsV3] 


AS
BEGIN
IF OBJECT_ID('tempdb..#Sanctions') IS NOT NULL
    DROP TABLE #Sanctions
    
    SELECT REPLACE(Name,'  ',' ') AS Name
,GroupID 
,[Last Updated]
,DOB
INTO #Sanctions
FROM 
(
SELECT 
--CASE WHEN [Group Type]='Individual' THEN RTRIM(ISNULL([Name 1],'')) + ' ' + RTRIM(ISNULL([Name 2],''))  + ' ' + RTRIM(ISNULL([Name 6],''))
--WHEN [Group Type]='Entity' THEN RTRIM([Name 6])  END AS Name
CASE WHEN [Group Type]='Individual' THEN RTRIM(ISNULL([Name 1],'')) + ' ' + RTRIM(ISNULL([Name 6],''))
WHEN [Group Type]='Entity' THEN RTRIM([Name 6])  END AS Name
,[Group ID] AS GroupID
,[Last Updated]
,DOB
FROM SanctionsList.dbo.SanctionList as a


) AS AllData
WHERE REPLACE(Name,'  ',' ') <>'MINISTRY OF DEFENCE'


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
,GroupID
,[Is this a Linked File]
,[Linked Case]
,[Date of birth]
,[Was DoB obtained?]
,[Reviewed file against Sanctions list]
,[Date Sanctions list reviewed]
,[Last Updated]
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,CASE WHEN COALESCE(DateClosed,mg_datcls) IS NULL AND [Date Sanctions list reviewed] IS NULL OR CONVERT(DATE,[Last Updated],103) > CONVERT(DATE,[Date Sanctions list reviewed],103) THEN 1 ELSE 0 END [Re-Check Needed]
,CASE WHEN COALESCE(DateClosed,mg_datcls) IS NULL AND [Reviewed file against Sanctions list] LIKE '%temporary reviewed%' THEN 1 ELSE 0 END AS AmberCheck
,CASE WHEN COALESCE(DateClosed,mg_datcls) IS NOT NULL AND  CONVERT(DATE,[Last Updated],103) BETWEEN DATEADD(M,-3,GETDATE()) AND GETDATE() THEN 1 ELSE 0 END ExtraRed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,[SanctionDOB]
,CaseID
FROM (
SELECT Sanctions.Name
,GroupID
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
,COALESCE(cboLinkedFile,NMI418.case_text) AS [Is this a Linked File]
,COALESCE(NMI419MS.txtLeadFileNo,NMI419.case_text) COLLATE DATABASE_DEFAULT AS [Linked Case]
,COALESCE(dteDateofBirth,AUD211.case_date,AUD211b.case_date) AS [Date of birth]
,COALESCE(AUD212.case_text,cboDoBObtain,AUD212b.case_text) AS [Was DoB obtained?]
,COALESCE(cboRevFileSanLi,AUD213.case_text,AUD213b.case_text) AS [Reviewed file against Sanctions list]
,COALESCE(dteDateSanRev,AUD214.case_date,AUD214b.case_date) AS [Date Sanctions list reviewed]
,ConflictSearch.SourceID AS SourceID
,COALESCE(dteDateofBirth,DOB) AS [SanctionDOB]
FROM #Sanctions AS Sanctions
INNER JOIN ConflictSearch.dbo.ConflictSearch
 ON LOWER(Sanctions.Name) = LOWER(CleanName)
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='NMI418') AS NMI418
	   ON Drilldown.CaseID=NMI418.case_id AND Drilldown.SourceID=1
LEFT OUTER JOIN (SELECT fileID,CASE WHEN cboLinkedFile='Y' THEN 'Yes' WHEN cboLinkedFile='N' THEN 'No' END AS cboLinkedFile  FROM MS_PROD.dbo.udMICoreGeneral
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

	  LEFT OUTER JOIN (SELECT ms_fileid AS case_id,case_text FROM axxia01.dbo.casdet INNER JOIN red_dw.dbo.dim_matter_header_current AS b ON casdet.case_id=b.case_id WHERE case_detail_code='AUD212') AS AUD212b
	   ON Drilldown.CaseID=AUD212b.case_id AND Drilldown.SourceID=2	   
	  LEFT OUTER JOIN (SELECT ms_fileid AS  case_id,case_text FROM axxia01.dbo.casdet INNER JOIN red_dw.dbo.dim_matter_header_current AS b ON casdet.case_id=b.case_id WHERE case_detail_code='AUD213') AS AUD213b
	   ON Drilldown.CaseID=AUD213b.case_id AND Drilldown.SourceID=2	 
	  LEFT OUTER JOIN (SELECT ms_fileid AS  case_id,case_date FROM axxia01.dbo.casdet INNER JOIN red_dw.dbo.dim_matter_header_current AS b ON casdet.case_id=b.case_id WHERE case_detail_code='AUD211') AS AUD211b
	   ON Drilldown.CaseID=AUD211b.case_id AND Drilldown.SourceID=2 	  
	  LEFT OUTER JOIN (SELECT ms_fileid AS  case_id,case_date FROM axxia01.dbo.casdet INNER JOIN red_dw.dbo.dim_matter_header_current AS b ON casdet.case_id=b.case_id WHERE case_detail_code='AUD214') AS AUD214b
	   ON Drilldown.CaseID=AUD214b.case_id AND Drilldown.SourceID=2			  
	  LEFT OUTER JOIN (SELECT ms_fileid AS  case_id,case_text FROM axxia01.dbo.casdet INNER JOIN red_dw.dbo.dim_matter_header_current AS b ON casdet.case_id=b.case_id WHERE case_detail_code='NMI419') AS NMI419b
	   ON Drilldown.CaseID=NMI419b.case_id AND Drilldown.SourceID=2	
	
	   LEFT OUTER JOIN (SELECT fileID,txtLeadFileNo  FROM MS_PROD.dbo.udMICoreGeneral
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
 ON Drilldown.client=ClientBalance.client_code COLLATE DATABASE_DEFAULT  AND Drilldown.matter=matter_number COLLATE DATABASE_DEFAULT
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile  WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT client_code AS mg_client,matter_number AS mg_matter, date_closed_practice_management AS mg_datcls, 1 AS SourceID FROM red_dw.dbo.dim_matter_header_current) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client COLLATE DATABASE_DEFAULT AND MainData.Matter=FEDClosures.mg_matter COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
  
 WHERE matter <>'0' 
--AND  (RTRIM(client) + '.' + RTRIM(matter)) ='A2002.14969'

 
END



GO
