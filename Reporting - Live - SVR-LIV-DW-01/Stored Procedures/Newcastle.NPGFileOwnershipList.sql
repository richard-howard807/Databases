SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [Newcastle].[NPGFileOwnershipList] 

AS 
BEGIN

SELECT ISNULL(CRSystemSourceID,clNo+ '-'+fileNo) AS Matter_Code
,dbFile.Created AS [date Opened]
,YEAR(dbFile.Created) AS [Year_Opened]
,CASE WHEN fileClosed IS NULL THEN 'O' ELSE 'C' END  AS matter_status
,NULL AS Case_Type
,txtJobNumber AS [Job Number]
,usrFullName AS [fe_code]
,fileDesc AS [matter_desc]
,contname AS WayleaOfficer
,curInitEstNPG AS [Initial Estimate]
,curCurrCostsEst AS [Total_Estimate]
,WIP AS [Current WIP]
,Financials.FeesBilledToDate AS [fees_billed]
,NULL AS [DISB_BAL]
,NULL AS [CLI_BAL]
,txtNPGNote  AS [NPG Notes]
,NULL AS [Date_Last_Notes]
,fileNotes AS [Caseload_Note]
,NULL AS [Last_time_recorded]
,LastBillDate AS [date_last_billed]



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
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,MAX(InvDate) AS LastBillDate
FROM [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.InvMaster WITH(NOLOCK)
INNER JOIN [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
WHERE  fileNo<>'0'
AND fileStatus='LIVE'
AND cboNPGFileType IS NOT NULL
AND CRSystemSourceID IN 
(
'164103-02331'
,'164107-03517'
,'164107-03543'
)
AND cboNPGFileType IS NOT NULL
ORDER BY CRSystemSourceID


END

GO
