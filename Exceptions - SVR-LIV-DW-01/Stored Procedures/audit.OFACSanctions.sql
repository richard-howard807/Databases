SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [audit].[OFACSanctions] 

AS
BEGIN


DECLARE @Update AS DATETIME
SET @Update= (SELECT MAX(CONVERT(DATE,CAST(Publish_date AS DATE),103)) AS DAtes FROM SanctionsList.dbo.PublishData  WITH (NOLOCK)  )

DECLARE @Update1 AS DATETIME
SET @Update1= (SELECT MAX(CONVERT(DATE,CAST(Publish_date AS DATE),103)) AS DAtes FROM SanctionsList.dbo.publishdata_sdn  WITH (NOLOCK)  )


IF OBJECT_ID (N'dbo.OFACSanctionsIndi', N'U') IS NOT NULL  
DROP TABLE dbo.OFACSanctionsIndi  

 
CREATE TABLE dbo.OFACSanctionsIndi 
(
sdnEntry_Id BIGINT NULL
,uid INT NULL
,Name NVARCHAR(MAX) NULL
,FirstName NVARCHAR(MAX)  NULL
,Lastname NVARCHAR(MAX) NULL
,AliasName NVARCHAR(MAX) NULL
,AliasFirstName NVARCHAR(MAX)  NULL
,AliasLastname NVARCHAR(MAX) NULL
,[Last Updated] DATETIME
,ListName NVARCHAR(MAX) NULL
,OFACDOB NVARCHAR(MAX) NULL
,[SDN DOB] NVARCHAR(MAX) NULL
)

INSERT INTO dbo.OFACSanctionsIndi
(
sdnEntry_Id,uid ,Name ,FirstName ,Lastname ,AliasName 
,AliasFirstName,AliasLastname,[Last Updated],ListName,OFACDOB 
,[SDN DOB] 
)
SELECT 
sdnEntry.sdnEntry_Id
,sdnListsdnEntry.uid 
,LOWER(CASE WHEN firstname IS NOT NULL  AND lastName IS NOT NULL  THEN RTRIM(ISNULL(firstname,'')) + ' ' + RTRIM(ISNULL(Lastname,'')) ELSE Lastname  END)  AS Name
,FirstName
,Lastname 
,LOWER(CASE WHEN FirstNameAlias IS NOT NULL  AND LastNameAlias IS NOT NULL  THEN RTRIM(ISNULL(FirstNameAlias,'')) + ' ' + RTRIM(ISNULL(LastNameAlias,'')) ELSE LastNameAlias  END) AS AliasName
,FirstNameAlias  
,LastNameAlias 
,@Update AS [Last Updated]
,'OFA Sanctions' AS ListName
,OFACDOB
,NULL AS [SDN DOB]

FROM SanctionsList.[dbo].[sdnEntry] AS sdnEntry  WITH (NOLOCK) 
LEFT OUTER  JOIN  SanctionsList.[dbo].[sdnListsdnEntry] AS sdnListsdnEntry  WITH (NOLOCK) 
 ON sdnEntry.sdnEntry_Id=sdnListsdnEntry.sdnEntry_id
LEFT OUTER JOIN SanctionsList.[dbo].firstName  WITH (NOLOCK)  ON sdnEntry.sdnEntry_Id=firstName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].lastName  WITH (NOLOCK)  ON sdnEntry.sdnEntry_Id=lastName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].title  WITH (NOLOCK)  ON sdnEntry.sdnEntry_Id=title.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry_Id,firstName AS FirstNameAlias,lastName AS LastNameAlias
FROM SanctionsList.dbo.akaList  WITH (NOLOCK)  
INNER JOIN SanctionsList.dbo.aka  WITH (NOLOCK)  ON akaList.akaList_Id=aka.akaList_Id) AS Alias
 ON sdnEntry.sdnEntry_Id=Alias.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry.sdnEntry_Id AS sdnEntry_Id
,sdnListsdnEntry.uid AS uid
,dateofBirth AS OFACDOB
FROM SanctionsList.[dbo].[sdnEntry] AS sdnEntry
INNER JOIN  SanctionsList.[dbo].[sdnListsdnEntry] AS sdnListsdnEntry
 ON sdnEntry.sdnEntry_Id=sdnListsdnEntry.sdnEntry_id
LEFT OUTER JOIN (SELECT sdnEntry_Id,dateOfBirthitem.dateofBirth
FROM SanctionsList.dbo.dateOfBirthList
INNER JOIN SanctionsList.dbo.dateOfBirthitem ON dateOfBirthList.dateOfBirthList_Id=dateOfBirthitem.dateOfBirthList_Id) AS DateOfBirth
 ON sdnEntry.sdnEntry_Id=dateofBirth.sdnEntry_Id) AS B
  ON sdnListsdnEntry.uid=b.uid
UNION
SELECT 
sdnEntry.sdnEntry_Id
,uid_sdn.uid 
,LOWER(CASE WHEN firstname IS NOT NULL  AND lastName IS NOT NULL  THEN RTRIM(ISNULL(firstname,'')) + ' ' + RTRIM(ISNULL(Lastname,'')) ELSE Lastname  END)  AS Name
,FirstName
,Lastname 
,LOWER(CASE WHEN FirstNameAlias IS NOT NULL  AND LastNameAlias IS NOT NULL  THEN RTRIM(ISNULL(FirstNameAlias,'')) + ' ' + RTRIM(ISNULL(LastNameAlias,'')) ELSE LastNameAlias  END) AS AliasName
,FirstNameAlias  
,LastNameAlias 
,@Update1 AS [Last Updated]
,'SDN Sanction' AS ListName
,NULL AS OFACDOB
,[SDN DOB]
FROM SanctionsList.[dbo].[sdnEntry_sdn] AS sdnEntry  WITH (NOLOCK)
LEFT OUTER JOIN SanctionsList.dbo.uid_sdn ON sdnEntry.sdnEntry_Id=uid_sdn.sdnEntry_Id 
LEFT OUTER JOIN SanctionsList.[dbo].firstName_sdn  WITH (NOLOCK)  ON sdnEntry.sdnEntry_Id=firstName_sdn.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].lastName_sdn  WITH (NOLOCK)  ON sdnEntry.sdnEntry_Id=lastName_sdn.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].title_sdn  WITH (NOLOCK)  ON sdnEntry.sdnEntry_Id=title_sdn.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry_Id,firstName AS FirstNameAlias,lastName AS LastNameAlias,uid
FROM SanctionsList.dbo.akaList  WITH (NOLOCK) 
INNER JOIN SanctionsList.dbo.aka  WITH (NOLOCK)  ON akaList.akaList_Id=aka.akaList_Id) AS Alias
 ON sdnEntry.sdnEntry_Id=Alias.sdnEntry_Id
LEFT OUTER JOIN (SELECT uid_sd.uid AS uid
,DOB AS [SDN DOB]

FROM SanctionsList.[dbo].[sdnEntry_sdn] AS sdnEntry
LEFT OUTER JOIN SanctionsList.dbo.uid_sdn AS uid_sd
 ON sdnEntry.sdnEntry_Id=uid_sd.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].firstName_sdn AS firstName ON sdnEntry.sdnEntry_Id=firstName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].lastName_sdn AS lastName ON sdnEntry.sdnEntry_Id=lastName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].title_sdn AS title ON sdnEntry.sdnEntry_Id=title.sdnEntry_Id
LEFT OUTER JOIN (select sdnEntry_Id
,CAST(STUFF((   SELECT ',' + RTRIM(dateOfBirth)
				FROM (SELECT sdnEntry_Id,b.dateOfBirth
						FROM SanctionsList.dbo.dateOfBirthList_sdn AS a
						INNER JOIN SanctionsList.dbo.dateOfBirthitem_sdn AS b
						ON b.dateOfBirthList_Id=a.dateOfBirthList_Id) te
				WHERE a.sdnEntry_Id = te.sdnEntry_Id 
				
				FOR XML PATH ('')  ),1,1,'')  AS VARCHAR(MAX))as [DOB]
    
     FROM (SELECT sdnEntry_Id  
						FROM SanctionsList.dbo.dateOfBirthList_sdn AS a
						INNER JOIN SanctionsList.dbo.dateOfBirthitem_sdn AS b
						ON b.dateOfBirthList_Id=a.dateOfBirthList_Id) AS a
  GROUP BY a.sdnEntry_Id) AS DOB
   ON sdnEntry.sdnEntry_Id=DOB.sdnEntry_Id) AS C
    ON uid_sdn.uid=C.uid
 
  



IF OBJECT_ID (N'dbo.OFASanctionsPrevious', N'U') IS NOT NULL  
DROP TABLE dbo.OFASanctionsPrevious


SELECT DISTINCT SanctionNam
,MatchedClientName
,ClientNumber
,Matches
,[No Possible Matches]
,Number
,ClientName
,Capacity
,[Systems]
,[Weightmans Ref]
,Address1
,Address2
,Address3
,Address4
,Postcode
,uid
,[Last Updated]
,DateClosed
,[Client Balance]
,SourceID
,CaseID
,[Is this a Linked File]
,[Linked Case]
,[Date of birth]
,[Was DoB obtained?]
,[Reviewed file against Sanctions list]
,[Date Sanctions list reviewed]
,[Re-Check Needed]
,AmberCheck
,ExtraRed
,[Sanction Name]
,OFACDOB
,[SDN DOB]
,InsertDate
INTO dbo.OFASanctionsPrevious
FROM dbo.OFASanctions





IF OBJECT_ID (N'dbo.OFASanctions', N'U') IS NOT NULL  
DROP TABLE dbo.OFASanctions



SELECT DISTINCT SanctionNam
,MatchedClientName
,ClientNumber
,Matches
,[No Possible Matches]
,Number
,ClientName
,Capacity
,[Systems]
,[Weightmans Ref]
,Address1
,Address2
,Address3
,Address4
,Postcode
,uid
,[Last Updated]
,DateClosed
,[Client Balance]
,SourceID
,CaseID
,COALESCE(NMI418.case_text,NMI418_b.case_text) AS [Is this a Linked File]
,COALESCE(NMI419.case_text,NMI419_b.case_text) AS [Linked Case]
,COALESCE(dteDateofBirth,AUD211.case_date,AUD211_b.case_date)  AS [Date of birth]
,COALESCE(cboDoBObtain,AUD212.case_text,AUD212_b.case_text ) COLLATE DATABASE_DEFAULT AS [Was DoB obtained?]
,COALESCE(cboRevFileSanLi,AUD213.case_text,AUD213_b.case_text )COLLATE DATABASE_DEFAULT  AS [Reviewed file against Sanctions list]
,COALESCE(dteDateSanRev,AUD214.case_date,AUD214_b.case_date ) AS [Date Sanctions list reviewed]
,CASE WHEN DateClosed IS NULL AND COALESCE(dteDateSanRev,AUD214.case_date,AUD214_b.case_date ) IS NULL OR CONVERT(DATE,[Last Updated],103) > CONVERT(DATE,COALESCE(dteDateSanRev,AUD214.case_date,AUD214_b.case_date ),103) THEN 1 ELSE 0 END [Re-Check Needed]
,CASE WHEN DateClosed IS NULL AND COALESCE(cboRevFileSanLi,AUD213.case_text,AUD213_b.case_text) COLLATE DATABASE_DEFAULT LIKE '%temporary reviewed%' THEN 1 ELSE 0 END  AS AmberCheck
,CASE WHEN DateClosed IS NOT NULL AND  CONVERT(DATE,[Last Updated],103) BETWEEN DATEADD(M,-3,GETDATE()) AND GETDATE() THEN 1 ELSE 0 END ExtraRed
,ListName AS [Sanction Name]
,OFACDOB
,[SDN DOB]
,GETDATE() AS InsertDate
INTO dbo.OFASanctions
FROM 
(
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
,uid
,[Last Updated],ListName
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,CaseID
,OFACDOB
,[SDN DOB]
FROM (
SELECT Sanctions.Name
,uid
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
,[Last Updated],ListName
,ConflictSearch.SourceID AS SourceID
,OFACDOB
,[SDN DOB]
FROM dbo.OFACSanctionsIndi AS Sanctions
INNER JOIN ConflictSearch.dbo.ConflictSearch WITH (NOLOCK) 
 ON LOWER(Sanctions.Name)= LOWER(CleanName) 
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown WITH (NOLOCK)
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER  JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary  WITH (NOLOCK)  
WHERE client_account_balance_of_matter <> 0) AS ClientBalance 
 ON Drilldown.client=ClientBalance.client_code COLLATE DATABASE_DEFAULT  AND Drilldown.matter=matter_number COLLATE DATABASE_DEFAULT
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile  WITH (NOLOCK)    WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT client_code AS mg_client,matter_number AS mg_matter, date_closed_practice_management AS mg_datcls, 1 AS SourceID FROM red_dw.dbo.dim_matter_header_current ) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client COLLATE DATABASE_DEFAULT AND MainData.Matter=FEDClosures.mg_matter COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses  WITH (NOLOCK) 
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
 WHERE matter <>'0' 
 UNION
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
,uid
,[Last Updated],ListName
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,CaseID
,OFACDOB
,[SDN DOB]
FROM (
SELECT Sanctions.Name
,uid
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
,[Last Updated],ListName
,ConflictSearch.SourceID AS SourceID
,OFACDOB
,[SDN DOB]
FROM dbo.OFACSanctionsIndi AS Sanctions  WITH (NOLOCK) 
INNER JOIN ConflictSearch.dbo.ConflictSearch WITH (NOLOCK) 
ON LOWER(Sanctions.FirstName)= LOWER(CleanName)
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown WITH (NOLOCK)
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER  JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary  WITH (NOLOCK) 
WHERE client_account_balance_of_matter <> 0) AS ClientBalance 
 ON Drilldown.client=ClientBalance.client_code COLLATE DATABASE_DEFAULT  AND Drilldown.matter=matter_number COLLATE DATABASE_DEFAULT
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile  WITH (NOLOCK)   WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT client_code AS mg_client,matter_number AS mg_matter, date_closed_practice_management AS mg_datcls, 1 AS SourceID FROM red_dw.dbo.dim_matter_header_current ) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client COLLATE DATABASE_DEFAULT AND MainData.Matter=FEDClosures.mg_matter COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses  WITH (NOLOCK) 
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
 WHERE matter <>'0' 
 UNION
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
,uid
,[Last Updated],ListName
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,CaseID
,OFACDOB
,[SDN DOB]
FROM (
SELECT Sanctions.Name
,uid
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
,[Last Updated],ListName
,ConflictSearch.SourceID AS SourceID
,OFACDOB
,[SDN DOB]
FROM dbo.OFACSanctionsIndi AS Sanctions  WITH (NOLOCK) 
INNER JOIN ConflictSearch.dbo.ConflictSearch WITH (NOLOCK) 
ON LOWER(Sanctions.Lastname)= LOWER(CleanName) 
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown WITH (NOLOCK)
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER  JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary  WITH (NOLOCK) 
WHERE client_account_balance_of_matter <> 0) AS ClientBalance 
 ON Drilldown.client=ClientBalance.client_code COLLATE DATABASE_DEFAULT  AND Drilldown.matter=matter_number COLLATE DATABASE_DEFAULT
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile  WITH (NOLOCK)   WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT client_code AS mg_client,matter_number AS mg_matter, date_closed_practice_management AS mg_datcls, 1 AS SourceID FROM red_dw.dbo.dim_matter_header_current ) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client COLLATE DATABASE_DEFAULT AND MainData.Matter=FEDClosures.mg_matter COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses  WITH (NOLOCK) 
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
 WHERE matter <>'0'

UNION 

----------------Alias

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
,uid
,[Last Updated],ListName
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,CaseID
,OFACDOB
,[SDN DOB]
FROM (
SELECT Sanctions.Name
,uid
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
,[Last Updated],ListName
,ConflictSearch.SourceID AS SourceID
,OFACDOB
,[SDN DOB]
FROM dbo.OFACSanctionsIndi AS Sanctions  WITH (NOLOCK)  
INNER JOIN ConflictSearch.dbo.ConflictSearch WITH (NOLOCK) 
 ON LOWER(Sanctions.AliasName)= LOWER(CleanName) 
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown WITH (NOLOCK)
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER  JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary  WITH (NOLOCK)  
WHERE client_account_balance_of_matter <> 0) AS ClientBalance 
 ON Drilldown.client=ClientBalance.client_code COLLATE DATABASE_DEFAULT  AND Drilldown.matter=matter_number COLLATE DATABASE_DEFAULT
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile   WITH (NOLOCK)   WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT client_code AS mg_client,matter_number AS mg_matter, date_closed_practice_management AS mg_datcls, 1 AS SourceID FROM red_dw.dbo.dim_matter_header_current  WITH (NOLOCK)  ) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client COLLATE DATABASE_DEFAULT AND MainData.Matter=FEDClosures.mg_matter COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses  WITH (NOLOCK) 
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
 WHERE matter <>'0' 
 UNION
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
,uid
,[Last Updated],ListName
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,CaseID
,OFACDOB
,[SDN DOB]
FROM (
SELECT Sanctions.Name
,uid
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
,[Last Updated],ListName
,ConflictSearch.SourceID AS SourceID
,OFACDOB
,[SDN DOB]
FROM dbo.OFACSanctionsIndi AS Sanctions  WITH (NOLOCK)  
INNER JOIN ConflictSearch.dbo.ConflictSearch WITH (NOLOCK) 
ON LOWER(Sanctions.AliasFirstName)= LOWER(CleanName)
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown WITH (NOLOCK)
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER  JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary  WITH (NOLOCK)  
WHERE client_account_balance_of_matter <> 0) AS ClientBalance 
 ON Drilldown.client=ClientBalance.client_code COLLATE DATABASE_DEFAULT  AND Drilldown.matter=matter_number COLLATE DATABASE_DEFAULT
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile  WITH (NOLOCK)   WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT client_code AS mg_client,matter_number AS mg_matter, date_closed_practice_management AS mg_datcls, 1 AS SourceID FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)  ) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client COLLATE DATABASE_DEFAULT AND MainData.Matter=FEDClosures.mg_matter COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses  WITH (NOLOCK) 
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
 WHERE matter <>'0' 
 UNION
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
,uid
,[Last Updated],ListName
,COALESCE(DateClosed,mg_datcls) AS DateClosed
,ISNULL([Client Balance],0) AS [Client Balance]
,MainData.SourceID
,CaseID
,OFACDOB
,[SDN DOB]
FROM (
SELECT Sanctions.Name
,uid
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
,[Last Updated],ListName
,ConflictSearch.SourceID AS SourceID
,OFACDOB
,[SDN DOB]
FROM dbo.OFACSanctionsIndi AS Sanctions  WITH (NOLOCK)  
INNER JOIN ConflictSearch.dbo.ConflictSearch WITH (NOLOCK) 
ON LOWER(Sanctions.AliasLastname)= LOWER(CleanName) 
INNER JOIN ConflictSearch.dbo.ConflictSearchDrillDownDetailsTable AS Drilldown WITH (NOLOCK)
  ON ConflictSearch.EntityCode=Drilldown.code AND ConflictSearch.SourceID=Drilldown.SourceID
LEFT OUTER  JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary  WITH (NOLOCK) 
WHERE client_account_balance_of_matter <> 0) AS ClientBalance 
 ON Drilldown.client=ClientBalance.client_code COLLATE DATABASE_DEFAULT  AND Drilldown.matter=matter_number COLLATE DATABASE_DEFAULT
WHERE ConflictSearch.[Type] NOT IN ('Matter','Address')
) AS MainData
LEFT OUTER JOIN (SELECT fileID,fileClosed AS DateClosed FROM MS_Prod.config.dbFile  WITH (NOLOCK)    WHERE fileClosed IS NOT NULL) AS MSClosure
 ON MainData.CaseID=MSClosure.fileID 
LEFT OUTER JOIN (SELECT client_code AS mg_client,matter_number AS mg_matter, date_closed_practice_management AS mg_datcls, 1 AS SourceID FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)  ) AS FEDClosures
 ON MainData.Client=FEDClosures.mg_client COLLATE DATABASE_DEFAULT AND MainData.Matter=FEDClosures.mg_matter COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT EntityCode,Address1,Address2,Address3,Address4,Postcode,SourceID FROM ConflictSearch.dbo.ConflictSearch AS Addresses
 WHERE Type='Address') AS Addresses
  ON MainData.EntityCode=Addresses.EntityCode AND MainData.SourceID=Addresses.SourceID
 WHERE matter <>'0'
 ) AS AllData
LEFT OUTER JOIN(SELECT fileID,case_id AS FEDCaseID FROM MS_Prod.dbo.udExtFile  WITH (NOLOCK)  
INNER JOIN axxia01.dbo.cashdr  WITH (NOLOCK)  
 ON udExtFile.FEDCode=RTRIM(client) + '-'+ RTRIM(matter) COLLATE DATABASE_DEFAULT
WHERE FEDCode IS NOT NULL) AS MSToFED
 ON AllData.CaseID=MSToFED.fileID

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
 ON AllData.CaseID=MSDetails.fileID 

LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet  WITH (NOLOCK)   WHERE case_detail_code='NMI418') AS NMI418
	   ON AllData.CaseID=NMI418.case_id AND AllData.SourceID=1
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet  WITH (NOLOCK)   WHERE case_detail_code='AUD212') AS AUD212
	   ON AllData.CaseID=AUD212.case_id AND AllData.SourceID=1	   
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet  WITH (NOLOCK)   WHERE case_detail_code='AUD213') AS AUD213
	   ON AllData.CaseID=AUD213.case_id AND AllData.SourceID=1	 
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet  WITH (NOLOCK)   WHERE case_detail_code='AUD211') AS AUD211
	   ON AllData.CaseID=AUD211.case_id AND AllData.SourceID=1	 	  
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet  WITH (NOLOCK)  WHERE case_detail_code='AUD214') AS AUD214
	   ON AllData.CaseID=AUD214.case_id AND AllData.SourceID=1			  
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet  WITH (NOLOCK)  WHERE case_detail_code='NMI419') AS NMI419
	   ON AllData.CaseID=NMI419.case_id AND AllData.SourceID=1	



LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet  WITH (NOLOCK)  WHERE case_detail_code='NMI418') AS NMI418_b
	   ON MSToFED.FEDCaseID=NMI418_b.case_id AND AllData.SourceID=2
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet  WITH (NOLOCK)   WHERE case_detail_code='AUD212') AS AUD212_b
	   ON MSToFED.FEDCaseID=AUD212_b.case_id AND AllData.SourceID=2 
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet  WITH (NOLOCK)   WHERE case_detail_code='AUD213') AS AUD213_b
	   ON MSToFED.FEDCaseID=AUD213_b.case_id AND AllData.SourceID=2
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WITH (NOLOCK)   WHERE case_detail_code='AUD211') AS AUD211_b
	   ON MSToFED.FEDCaseID=AUD211_b.case_id AND AllData.SourceID=2	  
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WITH (NOLOCK)   WHERE case_detail_code='AUD214') AS AUD214_b
	   ON MSToFED.FEDCaseID=AUD214_b.case_id AND AllData.SourceID=2		  
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WITH (NOLOCK)   WHERE case_detail_code='NMI419') AS NMI419_b
	   ON MSToFED.FEDCaseID=NMI419_b.case_id AND AllData.SourceID=2





END

--SELECT * FROM MS_Prod.dbo.dbCodeLookup
--WHERE cdCode='NOACP'
GO
