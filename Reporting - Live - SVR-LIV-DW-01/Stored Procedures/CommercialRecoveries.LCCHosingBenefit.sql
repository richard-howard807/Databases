SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [CommercialRecoveries].[LCCHosingBenefit]
AS
BEGIN
DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE
SET @StartDate=(SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0))
SET @EndDate =(DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) )

SELECT dbFile.fileID 
,clNo
,ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS [Client/Matter]
,ISNULL(Defendant.Defendant,fileDesc) AS [Debtors Name]
,txtCliRef AS [Invoice Number]
,txtDeptType
,curOriginalBal AS [Debt Amount]
,ISNULL(DisbsCosts.FixedCosts,0) AS [Fixed Costs]
,ISNULL(DisbsCosts.DisbsIncurred,0) + ISNULL(DisbsCosts.UnRecoverableDisb,0)  AS [Disbursements]
,ISNULL(DisbsCosts.Interest,0) AS [Interest]
,ISNULL(TotalPayments.TotalCollections,0) AS Payments
,ISNULL(DisbsPreviousMonth.FixedCosts,0) AS [FixedCostsLastMonth]
,ISNULL(DisbsPreviousMonth.DisbsIncurred,0) + ISNULL(DisbsPreviousMonth.UnRecoverableDisb,0)  AS [DisbursementsLastMonth]
,CASE WHEN CONVERT(DATE,fileClosed,103) BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS ClosedLastMonth
,txtCurenStatNot
,txtFileStatus
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
,SUM(CASE WHEN cboCatDesc='7' THEN curOffice ELSE NULL END) AS FixedCosts
,SUM(CASE WHEN cboCatDesc='4' THEN curOffice ELSE NULL END) AS Interest
,SUM(CASE WHEN txtItemDesc LIKE '%Late Payment Costs%' THEN curOffice ELSE NULL END) AS LatePaymentLedger
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE cboCatDesc IN ('2','1','0','7','4')
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
GROUP BY fileID
) AS DisbsPreviousMonth
 ON DisbsPreviousMonth.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN cboCatDesc='2' THEN curOffice ELSE NULL END) AS CostsIncurred
,SUM(CASE WHEN cboCatDesc IN ('1') THEN curOffice ELSE NULL END) AS DisbsIncurred
,SUM(CASE WHEN cboCatDesc='0' THEN curOffice ELSE NULL END) AS UnRecoverableDisb
,SUM(CASE WHEN cboCatDesc='7' THEN curOffice ELSE NULL END) AS FixedCosts
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
WHERE (CRSystemSourceID  LIKE '3600%' OR cboLeedsCC='LC3' --OR clNo='W15471' OR cboLeedsCC='LC1'
)
AND fileType='2038'



ORDER BY dbFile.Created




END
GO
