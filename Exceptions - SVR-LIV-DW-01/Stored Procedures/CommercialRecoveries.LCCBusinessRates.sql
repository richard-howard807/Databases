SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [CommercialRecoveries].[LCCBusinessRates]
AS
BEGIN
SELECT dbFile.fileID 
,clNo
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS [Date Inst Rcvd]
,txtCliRef AS [GK Account No]
,NULL AS [In/Out]
,clNo +'-' + fileNo AS [F&W Ref]
,txtPubName AS [Pub Name]
,ISNULL(Defendant.Defendant,fileDesc) AS [Tenants Name]
,curOriginalBal AS [Original Debt]
,txtCurentAction AS [Current Action]
,ISNULL(DisbsCosts.FWBills,0) + ISNULL(DisbsCosts.DisbsIncurred,0) + ISNULL(UnRecoverableDisb,0) AS [Costs to Date]
,[red_dw].[dbo].[datetimelocal](dteStatDate) AS [Statutory Demand Served]
,[red_dw].[dbo].[datetimelocal](dteBnkrupAvail) AS [Bankruptcy Available date]
,[red_dw].[dbo].[datetimelocal](dteHearDate) AS [Bankruptcy Hearing date]
,txtCurenStatNot AS [Current Status]
,Reminders.tskDesc AS [Next Action]
,[red_dw].[dbo].[datetimelocal](Reminders.tskDue) AS [Action Date]
,TotalCollections AS [Amount Recovd]
,NULL AS [Anticipated Costs]
,NULL AS [Anticipated Disbs]
,DisbsCosts.FWBills AS [Costs to Date 2]
,ISNULL(DisbsCosts.DisbsIncurred,0) + ISNULL(UnRecoverableDisb,0) AS [Disbs to Date]
,Interest AS [Total Interest]
,txtCredControl AS [Credit Controller]
,txtBranchNum AS [Branch Number]
,curLatePayCost AS [Late Payment Costs]
,DisbsCosts.LatePaymentLedger
,curCurrentBal AS [Balance]

FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore
 ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRInsolvency 
 ON udCRInsolvency.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,tskDesc,tskDue
,ROW_NUMBER() OVER ( PARTITION BY fileID ORDER BY tskID DESC ) AS NoteRank FROM [MS_PROD].dbo.dbTasks
WHERE tskActive=1
AND tskType='GENERAL') AS Reminders
 ON Reminders.fileID = dbFile.fileID AND Reminders.NoteRank=1
LEFT OUTER JOIN (SELECT fileID,SUM(curClient) AS TotalCollections
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='5'
GROUP BY fileID) AS TotalPayments
 ON TotalPayments.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN cboCatDesc='2' THEN curOffice ELSE NULL END) AS CostsIncurred
,SUM(CASE WHEN cboCatDesc IN ('1') THEN curOffice ELSE NULL END) AS DisbsIncurred
,SUM(CASE WHEN cboCatDesc='0' THEN curOffice ELSE NULL END) AS UnRecoverableDisb
,SUM(CASE WHEN cboCatDesc='7' THEN curOffice ELSE NULL END) AS FWBills
,SUM(CASE WHEN cboCatDesc='4' THEN curOffice ELSE NULL END) AS Interest
,SUM(CASE WHEN txtItemDesc LIKE '%Late Payment Costs%' THEN curOffice ELSE NULL END) AS LatePaymentLedger
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE cboCatDesc IN ('2','1','0','7','4')
GROUP BY fileID
) AS DisbsCosts
 ON DisbsCosts.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
WHERE (CRSystemSourceID  LIKE '33832-%' OR cboLeedsCC='LC1' --OR clNo='W15471' --Need fules applying
)
AND fileType='2038'
AND ISNULL(CRSystemSourceID,'') NOT IN ('33832-5','33832-6')


ORDER BY dbFile.fileNo




END
GO
