SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [Newcastle].[PlotSalesMatters]

AS

BEGIN
SELECT
clName
,Division.cdDesc AS [Division]
,ISNULL(REPLACE(CRSystemSourceID,'-','.'),clNo+ '.'+fileNo) AS Matter_Code
,fileDesc AS [Trans]
,usrFullName AS [Fee Earner]
,contName AS [Purchaser Solicitor]
,BStatus.cdDesc AS [Status]
,txtBellwayNotes AS [Notes]
,ISNULL(MatterType.cdDesc,'') AS Mattype
,red_dw.dbo.datetimelocal(dbFile.Created) AS [Date Opened]
,dteExpResPrd AS [Reserve Deadline]
,CAST(dteExpResPrd - GETDATE() AS INT)
,CASE
	WHEN BStatus.cdDesc = 'Contracts not yet exchanged' AND red_dw.dbo.datetimelocal(dteExpResPrd) > '2000-01-01 00:00:00.000' AND red_dw.dbo.datetimelocal(dteExpResPrd) - GETDATE() < 0 THEN 'Expired'
WHEN BStatus.cdDesc = '' AND red_dw.dbo.datetimelocal(dteExpResPrd) > '2000-01-01 00:00:00.000' AND red_dw.dbo.datetimelocal(dteExpResPrd) - GETDATE() < 0 THEN 'Expired'
WHEN BStatus.cdDesc IS NULL AND red_dw.dbo.datetimelocal(dteExpResPrd) > '2000-01-01 00:00:00.000' AND red_dw.dbo.datetimelocal(dteExpResPrd) - GETDATE() < 0 THEN 'Expired'
WHEN BStatus.cdDesc = 'Contracts not yet exchanged' AND red_dw.dbo.datetimelocal(dteExpResPrd) > '2000-01-01 00:00:00.000' THEN CAST(CAST(red_dw.dbo.datetimelocal(dteExpResPrd) - GETDATE() AS INT) AS CHAR(5))
WHEN BStatus.cdDesc = '' AND red_dw.dbo.datetimelocal(dteExpResPrd) > '2000-01-01 00:00:00.000' THEN CAST(CAST(red_dw.dbo.datetimelocal(dteExpResPrd) - GETDATE() AS INT) AS CHAR(5))
WHEN BStatus.cdDesc IS NULL AND red_dw.dbo.datetimelocal(dteExpResPrd) > '2000-01-01 00:00:00.000' THEN CAST(CAST(red_dw.dbo.datetimelocal(dteExpResPrd) - GETDATE() AS INT) AS CHAR(5))
ELSE ''	END AS [Expired Exchange]
,red_dw.dbo.datetimelocal(dteEstCompDate) AS [Anticipated Completion Date]
,NULL AS [action exchage]
,NULL AS [action completion]
,'N' AS [Issue]

FROM MS_PROD.config.dbFile
INNER JOIN MS_PROD.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_PROD.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,SUM(CASE WHEN InvDate BETWEEN '2019-11-01' AND '2019-11-30' THEN OrgFee ELSE NULL END) AS MonthFees
FROM TE_3E_Prod.dbo.InvMaster
INNER JOIN TE_3E_Prod.dbo.Matter
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN MS_PROD.dbo.udMIInitialReserves
 ON udMIInitialReserves.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMIClientBellway
 ON udMIClientBellway.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID AND assocType='OTHERSIDESOLS'
LEFT OUTER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup AS Division
 ON Division.cdCode=cboDivisionBW AND Division.cdType='DIVISIONBELL'
LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup AS BStatus
 ON BStatus.cdCode=cboStatusBW AND BStatus.cdType='STATUSBELL'
LEFT OUTER JOIN MS_PROD.dbo.udPlotSalesFileOpeningTF
 ON udPlotSalesFileOpeningTF.fileID = dbfile.fileID
LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup AS Tenure
 ON Tenure.cdCode=cboTenure AND Tenure.cdType='TENURE'
LEFT OUTER JOIN MS_PROD.dbo.dbCodeLookup AS MatterType
 ON MatterType.cdCode=cboMatterTypeBW AND MatterType.cdType='TYPEBELL'


 LEFT OUTER JOIN MS_PROD.dbo.udPlotSalesExchange
 ON udPlotSalesExchange.fileID = dbfile.fileID

WHERE  fileNo<>'0'
AND fileStatus='LIVE'
AND usrFullName IN 
('Jonathon Dimmock','Lauren Coleman','LaurenLangthorne','SharonPannu')
AND clName LIKE '%Bellway%'
ORDER BY Matter_Code
END 
GO
