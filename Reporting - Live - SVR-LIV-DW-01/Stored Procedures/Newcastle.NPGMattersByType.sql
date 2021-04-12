SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [Newcastle].[NPGMattersByType]

AS 

BEGIN

SELECT ISNULL(CRSystemSourceID,clNo+ '-'+fileNo) AS Matter_Code
,dbFile.Created AS [date Opened]
,txtJobNumber AS [Job Number]
,fileDesc AS [Matter Description]
,curInitEstNPG AS [Initial Estimate]
,curCurrCostsEst  AS [Current Estimate]
,WIP AS [Current WIP]
,txtNPGNote  AS [NPG Notes]
,usrFullName
,fileType
,txtJobNumber
,CASE WHEN cboNPGFileType='COMLIT' THEN 'NPG ComLit Files' 
WHEN cboNPGFileType='PROPERTY' THEN 'NPG Property'
WHEN cboNPGFileType='WAYLEAVE' THEN 'NPG Wayleave' END AS NPGFileType
,contname AS WayleaOfficer
FROM [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbFile
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.dbUser
 ON filePrincipleID=usrID
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMIInitialReserves
 ON udMIInitialReserves.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = udExtFile.fileID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID AND assocType='WAYLEA'
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN (SELECT Matter,SUM(WorkAmt) AS WIP FROM [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.Timecard WITH(NOLOCK)
WHERE IsActive=1
AND WIPRemoveDate IS NULL
GROUP BY Matter) AS WIP
 ON fileExtLinkID=WIP.Matter
WHERE  fileNo<>'0'
AND fileStatus='LIVE'
AND cboNPGFileType IS NOT NULL
AND dbFile.fileID<>5197870
ORDER BY CRSystemSourceID

END
GO
