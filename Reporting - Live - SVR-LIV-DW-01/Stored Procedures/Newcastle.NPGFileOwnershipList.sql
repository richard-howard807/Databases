SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO














CREATE PROCEDURE [Newcastle].[NPGFileOwnershipList] -- [Newcastle].[NPGFileOwnershipList] 'All' 
(
@Filter AS NVARCHAR(100)
)
AS 
BEGIN


IF @Filter='All'

BEGIN

--SELECT ISNULL(REPLACE(CRSystemSourceID,'-','.'),clNo+ '.'+fileNo) AS Matter_Code
SELECT clNo+ '.'+fileNo  AS Matter_Code -- David T asked to remove the old reference
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS [date Opened]
,YEAR([red_dw].[dbo].[datetimelocal](dbFile.Created)) AS [Year_Opened]
,CASE WHEN MatStat.cdDesc IS NOT NULL THEN MatStat.cdDesc
WHEN [red_dw].[dbo].[datetimelocal](fileClosed) IS NULL THEN 'O' ELSE 'C' END  AS matter_status
,Insttype.cdDesc AS Case_Type
,txtJobNumber AS [Job Number]
,usrFullName AS [fe_code]
,fileDesc AS [matter_desc]
,contname AS WayleaOfficer
,curInitEstNPG AS [Initial Estimate]
,curRevEstimate AS [Total_Estimate]
,Warehouse.WIP AS [Current WIP]
,Financials.FeesBilledToDate AS [fees_billed]
,Warehouse.DisbursementBalance AS [DISB_BAL]
,Warehouse.ClientBalance AS [CLI_BAL]
,ISNULL(fileExternalNotes,txtNPGNote)  AS [NPG Notes]
,NULL AS [Date_Last_Notes]
,fileNotes AS [Caseload_Note]
,Warehouse.LastTime AS [Last_time_recorded]
,LastBillDate AS [date_last_billed]
,clNo
,fileNo
,clName
,CASE WHEN cboNPGFileType='PROPERTY' THEN 'Property'
WHEN cboNPGFileType='WAYLEAVE' THEN 'Wayleave'
WHEN cboNPGFileType='COMLIT' THEN 'Com-Lit' END AS Team
,contChristianNames
,contSurname
FROM MS_PROD.config.dbFile
INNER JOIN MS_PROD.dbo.dbUser
 ON filePrincipleID=usrID
INNER JOIN MS_PROD.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_PROD.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMIInitialReserves
 ON udMIInitialReserves.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID AND assocType='WAYLEA' AND dbassociates.assocActive=1
LEFT OUTER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbContactIndividual
 ON dbContactIndividual.contID = dbAssociates.contID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,MAX(InvDate) AS LastBillDate
FROM TE_3E_Prod.dbo.InvMaster WITH(NOLOCK)
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS Insttype
ON cboInsTypeNPG=Insttype.cdCode AND Insttype.cdType='INSTYPENPG'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS MatStat
ON cboMatterStat=MatStat.cdCode AND MatStat.cdType='STATUSNPG'
LEFT OUTER JOIN
(
SELECT ms_fileid,fact_finance_summary.client_account_balance_of_matter AS ClientBalance
,fact_finance_summary.disbursement_balance AS [DisbursementBalance]
,wip AS [WIP]
,last_time_transaction_date AS [LastTime]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.matter_number = dim_matter_header_current.matter_number
 AND fact_finance_summary.client_code = dim_matter_header_current.client_code
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
 AND fact_matter_summary_current.client_code = dim_matter_header_current.client_code
WHERE dim_matter_header_current.client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
) AS Warehouse
 ON dbFile.fileID=Warehouse.ms_fileid
WHERE  fileNo<>'0'
AND fileStatus='LIVE'
AND clNo IN 
(
'WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103'
)

ORDER BY CRSystemSourceID

END 


ELSE

BEGIN

SELECT clNo+ '.'+fileNo  AS Matter_Code -- David T asked to remove the old reference
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS [date Opened]
,YEAR([red_dw].[dbo].[datetimelocal](dbFile.Created)) AS [Year_Opened]
,CASE WHEN MatStat.cdDesc IS NOT NULL THEN MatStat.cdDesc
WHEN [red_dw].[dbo].[datetimelocal](fileClosed) IS NULL THEN 'O' ELSE 'C' END  AS matter_status
,Insttype.cdDesc AS Case_Type
,txtJobNumber AS [Job Number]
,usrFullName AS [fe_code]
,fileDesc AS [matter_desc]
,contname AS WayleaOfficer
,curInitEstNPG AS [Initial Estimate]
,curRevEstimate AS [Total_Estimate]
,Warehouse.WIP AS [Current WIP]
,Financials.FeesBilledToDate AS [fees_billed]
,Warehouse.DisbursementBalance AS [DISB_BAL]
,Warehouse.ClientBalance AS [CLI_BAL]
,ISNULL(fileExternalNotes,txtNPGNote)  AS [NPG Notes]
,NULL AS [Date_Last_Notes]
,fileNotes AS [Caseload_Note]
,Warehouse.LastTime AS [Last_time_recorded]
,LastBillDate AS [date_last_billed]
,clNo
,fileNo
,clName
,CASE WHEN cboNPGFileType='PROPERTY' THEN 'Property'
WHEN cboNPGFileType='WAYLEAVE' THEN 'Wayleave'
WHEN cboNPGFileType='COMLIT' THEN 'Com-Lit' END AS Team
,contChristianNames
,contSurname
FROM MS_PROD.config.dbFile
INNER JOIN MS_PROD.dbo.dbUser
 ON filePrincipleID=usrID
INNER JOIN MS_PROD.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_PROD.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMIInitialReserves
 ON udMIInitialReserves.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMIClientNPG
 ON udMIClientNPG.fileID = udExtFile.fileID
LEFT OUTER JOIN MS_PROD.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID AND assocType='WAYLEA' AND dbassociates.assocActive=1
LEFT OUTER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbContactIndividual
 ON dbContactIndividual.contID = dbAssociates.contID
LEFT OUTER JOIN (SELECT MattIndex,SUM(OrgFee) AS FeesBilledToDate
,MAX(InvDate) AS LastBillDate
FROM TE_3E_Prod.dbo.InvMaster WITH(NOLOCK)
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
 ON LeadMatter=MattIndex
 GROUP BY MattIndex) AS Financials
  ON fileExtLinkID=MattIndex
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS Insttype
ON cboInsTypeNPG=Insttype.cdCode AND Insttype.cdType='INSTYPENPG'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS MatStat
ON cboMatterStat=MatStat.cdCode AND MatStat.cdType='STATUSNPG'
LEFT OUTER JOIN
(
SELECT ms_fileid,fact_finance_summary.client_account_balance_of_matter AS ClientBalance
,fact_finance_summary.disbursement_balance AS [DisbursementBalance]
,wip AS [WIP]
,last_time_transaction_date AS [LastTime]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.matter_number = dim_matter_header_current.matter_number
 AND fact_finance_summary.client_code = dim_matter_header_current.client_code
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
 AND fact_matter_summary_current.client_code = dim_matter_header_current.client_code
WHERE dim_matter_header_current.client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
) AS Warehouse
 ON dbFile.fileID=Warehouse.ms_fileid
WHERE  fileNo<>'0'
AND fileStatus='LIVE'
AND clNo IN 
(
'WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103'
)
AND (CASE WHEN cboNPGFileType='PROPERTY' THEN 'NPG Property'
WHEN cboNPGFileType='WAYLEAVE' THEN 'NPG Wayleave'
WHEN cboNPGFileType='COMLIT' THEN 'NPG Com-Lit' END) =@Filter
ORDER BY CRSystemSourceID

END 



END

GO
