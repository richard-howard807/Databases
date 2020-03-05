SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[SanctionsV2] -- EXEC [Audit].[SanctionsPossibleMatches] '00398695','2010-01-01','2014-03-20'
--(
--@Client AS VARCHAR(MAX)
--)
AS
BEGIN

--SELECT ListValue  INTO #Client FROM dbo.udt_TallySplit(',', @Client)

SELECT REPLACE(Name,'  ',' ') AS Name
,GroupID 
,[Last Updated]
INTO #Sanctions
FROM 
(
SELECT 
CASE WHEN [Group Type]='Individual' THEN RTRIM(ISNULL([Name 1],'')) + ' ' + RTRIM(ISNULL([Name 2],''))  + ' ' + RTRIM(ISNULL([Name 6],''))
WHEN [Group Type]='Entity' THEN RTRIM([Name 6])  END AS Name
,[Group ID] AS GroupID
,[Last Updated]
FROM SanctionsList.dbo.SanctionList as a
--WHERE [Listed On] BETWEEN @StartDate AND @EndDate OR [Last Updated] BETWEEN @StartDate AND @EndDate
) AS AllData



SELECT DISTINCT  Name AS SanctionNam,ClientName AS MatchedClientName
,cl_accode AS ClientNumber
,CASE WHEN cl_accode IS NULL THEN 'No Match' ELSE 'Possible Match' END AS Matches
,CASE WHEN cl_accode IS NULL THEN 0 ELSE 1 END AS [No Possible Matches]
,1 AS Number
,ClientName
,Capacity
,[Weightmans Ref]
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
,DateClosed
,CASE WHEN DateClosed IS NULL AND [Date Sanctions list reviewed] IS NULL OR CONVERT(Date,[Last Updated],103) > CONVERT(Date,[Date Sanctions list reviewed],103) THEN 1 ELSE 0 END [Re-Check Needed]
,CASE WHEN DateClosed IS NULL AND [Reviewed file against Sanctions list] LIKE '%temporary reviewed%' THEN 1 ELSE 0 END AS AmberCheck
,CASE WHEN DateClosed IS NOT NULL AND  CONVERT(Date,[Last Updated],103) BETWEEN DATEADD(M,-3,GETDATE()) AND GETDATE() THEN 1 ELSE 0 END ExtraRed
,ISNULL([Client Balance],0) AS [Client Balance]
FROM #Sanctions AS a
INNER JOIN 
(SELECT cl_accode,cl_clname AS ClientName
,fm_addli1 AS Address1
,fm_addli2 AS Address2
,fm_addli3 AS Address3
,fm_addli4 AS Address4
,fm_poscod AS Postcode
,Capacity
,[Weightmans Ref]
,DateClosed
,WeightmansClient
,[Is this a Linked File]
,[Linked Case]
,[Date of birth]
,[Was DoB obtained?]
,[Reviewed file against Sanctions list]
,[Date Sanctions list reviewed]
,[Client Balance]
FROM (SELECT caclient.cl_accode 
	  ,REPLACE(RTRIM(ISNULL(kdclicon.kc_fornam,'')) + ' ' + RTRIM(ISNULL(caclient.cl_clname,'')),'  ','') AS cl_clname
	  ,capacity_desc AS Capacity
	  ,RTRIM(client) + '.' + RTRIM(matter) AS [Weightmans Ref]
	  ,date_closed As DateClosed
	  ,RefClientName.cl_clname AS WeightmansClient
	  ,NMI418.case_text AS [Is this a Linked File]
	  ,NMI419.case_text AS [Linked Case]
	  ,AUD211.case_date AS [Date of birth]
	  ,AUD212.case_text AS [Was DoB obtained?]
	  ,AUD213.case_text AS [Reviewed file against Sanctions list]
	  ,AUD214.case_date AS [Date Sanctions list reviewed]
	  ,client_account_balance_of_matter AS [Client Balance]
	  FROM axxia01.dbo.caclient
	  LEFT OUTER JOIN axxia01.dbo.invol AS Invol 
	   On caclient.cl_accode=Invol.entity_code
	  LEFT OUTER JOIN axxia01.dbo.cashdr AS cashdr
	   On Invol.case_id=cashdr.case_id
	  LEFT OUTER JOIN axxia01.dbo.capac AS capac
	   ON Invol.capacity_code=capac.capacity_code
	  LEFT OUTER JOIN axxia01.dbo.kdclicon AS kdclicon
	  ON caclient.cl_accode = kdclicon.kc_client
	  LEFT OUTER JOIN axxia01.dbo.caclient AS RefClientName
	   ON cashdr.client=RefClientName.cl_accode
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='NMI418') AS NMI418
	   ON cashdr.case_id=NMI418.case_id
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD212') AS AUD212
	   ON cashdr.case_id=AUD212.case_id	   
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD213') AS AUD213
	   ON cashdr.case_id=AUD213.case_id	
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD211') AS AUD211
	   ON cashdr.case_id=AUD211.case_id		  
	  LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD214') AS AUD214
	   ON cashdr.case_id=AUD214.case_id			  
	  LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='NMI419') AS NMI419
	   ON cashdr.case_id=NMI419.case_id	
	  LEFT OUTER JOIN (SELECT client_code,matter_number,client_account_balance_of_matter FROM red_dw.dbo.fact_finance_summary
WHERE client_account_balance_of_matter <> 0) AS ClientBalance
 ON cashdr.client=ClientBalance.client_code collate database_default  AND cashdr.matter=matter_number collate database_default
       WHERE entity_code <> '00764267'
	  	   --WHERE cashdr.date_closed IS NULL
	 
) AS caclient 
--INNER JOIN #Client AS Client ON Client.ListValue COLLATE database_default = cl_accode COLLATE database_default
 LEFT OUTER JOIN axxia01.dbo.fmsaddr AS AddressList
  ON caclient.cl_accode=AddressList.fm_clinum
) AS b
ON UPPER(b.ClientName) =UPPER(a.Name)  collate database_default
--ON b.cl_clname LIKE '%'+ a.Name +'%' collate database_default
WHERE cl_accode NOT IN ('00232022','00161056','00598998','00598998','00631494','00740375','00230691','00740000','00032075')
--AND [Weightmans Ref]='N00034.00000312'
DROP TABLE #Sanctions
END
GO
