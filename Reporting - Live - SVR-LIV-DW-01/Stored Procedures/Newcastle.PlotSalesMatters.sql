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
,ISNULL(CRSystemSourceID,clNo+ '-'+fileNo) AS Matter_Code
,fileDesc AS [Trans]
,usrFullName AS [Fee Earner]
,contName AS [Purchaser Solicitor]
,BStatus.cdDesc AS [Status]
,txtBellwayNotes AS [Notes]
,ISNULL(MatterType.cdDesc,'') AS Mattype
,dbFile.Created AS [Date Opened]
,dteExpResPrd AS [Reserve Deadline]
,CAST(dteExpResPrd - getdate() AS INT)
,case
	when BStatus.cdDesc = 'Contracts not yet exchanged' and dteExpResPrd > '2000-01-01 00:00:00.000' AND dteExpResPrd - GETDATE() < 0 then 'Expired'
when BStatus.cdDesc = '' and dteExpResPrd > '2000-01-01 00:00:00.000' and dteExpResPrd - getdate() < 0 then 'Expired'
when BStatus.cdDesc is null and dteExpResPrd > '2000-01-01 00:00:00.000' and dteExpResPrd - getdate() < 0 then 'Expired'
when BStatus.cdDesc = 'Contracts not yet exchanged' and dteExpResPrd > '2000-01-01 00:00:00.000' then cast(cast(dteExpResPrd - getdate() as int) as char(5))
when BStatus.cdDesc = '' and dteExpResPrd > '2000-01-01 00:00:00.000' then cast(cast(dteExpResPrd - getdate() as int) as char(5))
when BStatus.cdDesc IS null and dteExpResPrd > '2000-01-01 00:00:00.000' then cast(cast(dteExpResPrd - getdate() as int) as char(5))
else ''	END AS [Expired Exchange]
,dteEstCompDate AS [Anticipated Completion Date]
,NULL AS [action exchage]
,NULL AS [action completion]
,'N' AS [Issue]

FROM [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbFile
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,SUM(CASE WHEN InvDate BETWEEN '2019-11-01' AND '2019-11-30' THEN OrgFee ELSE NULL END) AS MonthFees
FROM [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.InvMaster
INNER JOIN [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.Matter
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMIInitialReserves
 ON udMIInitialReserves.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMIClientBellway
 ON udMIClientBellway.fileID = dbFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID AND assocType='OTHERSIDESOLS'
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbCodeLookup AS Division
 ON Division.cdCode=cboDivisionBW AND Division.cdType='DIVISIONBELL'
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbCodeLookup AS BStatus
 ON BStatus.cdCode=cboStatusBW AND BStatus.cdType='STATUSBELL'
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udPlotSalesFileOpeningTF
 ON udPlotSalesFileOpeningTF.fileID = dbfile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbCodeLookup AS Tenure
 ON Tenure.cdCode=cboTenure AND Tenure.cdType='TENURE'
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbCodeLookup AS MatterType
 ON MatterType.cdCode=cboMatterTypeBW AND MatterType.cdType='TYPEBELL'


 LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udPlotSalesExchange
 ON udPlotSalesExchange.fileID = dbfile.fileID

WHERE  fileNo<>'0'
AND fileStatus='LIVE'
AND usrFullName IN 
('Jonathon Dimmock','Lauren Coleman','LaurenLangthorne','SharonPannu')
AND clName LIKE '%Bellway%'
ORDER BY Matter_Code
END 
GO
