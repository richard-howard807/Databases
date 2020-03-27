SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [audit].[PEPClients]
AS

BEGIN
SELECT clNo,clName
,CASE WHEN cboHighRskJuris='Y' THEN 'Yes' 
	  WHEN cboHighRskJuris='N' THEN 'No' END  AS cboHighRskJuris
,CASE WHEN cboPEP='Y' THEN 'Yes' 
	  WHEN cboPEP='N' THEN 'No' END  AS cboPEP
,CASE WHEN cboRisk='H' THEN 'High' 
	  WHEN cboRisk='M' THEN 'Medium'
	  WHEN cboRisk='L' THEN 'Low' END AS cboRisk
	  ,fileDesc,fileclosed
	  ,txtAMLComments
	  ,brName AS Office
FROM MS_Prod.dbo.udExtClient 
INNER JOIN MS_Prod.config.dbClient
 ON udExtClient.clID=dbClient.clID   
LEFT OUTER JOIN (SELECT clid,fileDesc,fileclosed FROM MS_PROD.config.dbfile WHERE fileno='1') AS files
 ON dbclient.clid=files.clid  
LEFT OUTER JOIN ms_prod.dbo.dbBranch
 ON dbBranch.brID = dbClient.brID
WHERE (cboPEP='Y' OR cboHighRskJuris='Y' OR cboRisk='H' OR txtAMLComments IS NOT NULL)
AND clName NOT LIKE '%ERROR%'
AND clName NOT LIKE '%TEST%'
AND cboPEP='Y' 

END
GO
