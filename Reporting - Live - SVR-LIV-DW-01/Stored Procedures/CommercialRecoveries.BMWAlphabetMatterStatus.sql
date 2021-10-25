SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO














--EXEC CommercialRecoveries.BMWAlphabetMatterStatus 'Alphabet','Open' 
CREATE PROCEDURE [CommercialRecoveries].[BMWAlphabetMatterStatus]
(
 @Client AS NVARCHAR(50)
 ,@FileStatus AS NVARCHAR(50)
)
AS

BEGIN


IF OBJECT_ID(N'tempdb..#HistoryNotes') IS NOT NULL BEGIN DROP TABLE #HistoryNotes END

SELECT udCRHistoryNotesSL.fileID,MAX(dteInserted) AS LastHistoryNote
INTO #HistoryNotes
FROM ms_prod.dbo.udCRHistoryNotesSL
GROUP BY udCRHistoryNotesSL.fileID

IF OBJECT_ID(N'tempdb..#LastDoc') IS NOT NULL BEGIN DROP TABLE #LastDoc END

SELECT dbDocument.fileID,MAX(dbDocument.Created) AS LastDoc
INTO #LastDoc
FROM ms_prod.config.dbDocument
INNER JOIN ms_prod.config.dbFile
 ON  dbFile.fileID = dbDocument.fileID
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
WHERE docDeleted=0
AND clNo IN('FW30085','FW22135','341077','FW22352' ,'FW22135','FW22135','FW22613' ,'W15335' ,'W20110','FW23557')
GROUP BY dbDocument.fileID

SELECT CASE WHEN ISNULL(ClientRef.ClientRef,'')=''THEN txtCliRef ELSE ClientRef END  AS [Account Number]
,clNo +'-' + fileNo  AS [Weightmans Reference]
,dbFile.Created AS [Date Instructred]
,Defendant.Defendant AS [Customer's Name]
,InstType.cdDesc AS [Instruction Type]
,txtCurenStatNot AS [Status of instruction]
,cboVehRecovered AS [Vehicle recovered]
,curPayArrAmoun AS [Payment arrangement agreed]
,curOriginalBal AS [Balance for recovery on instruction]
,TotalCollections AS [Total payments collected to date]
,Interest.Interest
,RecoverableCosts.[Recoverable Costs]
,RecoverableDisbursements.[Recoverable Disbursements]
,unrecoverableCosts.unrecoverableCosts
,defence_costs_billed_composite
,red_dw.dbo.datetimelocal(dteClaimForm) AS [Claim Form Issued]
,red_dw.dbo.datetimelocal(LastHistoryNote) AS LastHistoryNote
,red_dw.dbo.datetimelocal(LastDoc) AS LastDoc
,CASE WHEN red_dw.dbo.datetimelocal(LastHistoryNote)>red_dw.dbo.datetimelocal(LastDoc) THEN red_dw.dbo.datetimelocal(LastHistoryNote) ELSE red_dw.dbo.datetimelocal(LastDoc) END AS LastAction
,cboStatus
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.udCRBMWAlphabet
 ON udCRBMWAlphabet.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.udCRIssueDetails
 ON udCRIssueDetails.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.dbCodeLookup AS InstType
 ON cboInstructType=InstType.cdCode AND InstType.cdType='INSTRUCTTYPE'
 LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curClient) AS TotalCollections
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='5'
GROUP BY fileID) AS TotalPayments
 ON TotalPayments.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS Interest
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='4'
GROUP BY fileID) AS Interest
 ON Interest.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS [Recoverable Costs]
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='2'
GROUP BY fileID) AS RecoverableCosts
 ON RecoverableCosts.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS [Recoverable Disbursements]
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='1'
GROUP BY fileID) AS RecoverableDisbursements
 ON RecoverableDisbursements.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS unrecoverableCosts
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE   cboCatDesc='7'
GROUP BY fileID) AS unrecoverableCosts
 ON unrecoverableCosts.fileID = dbFile.fileID

LEFT OUTER JOIN (SELECT fileID,assocRef AS ClientRef FROM ms_prod.config.dbAssociates
WHERE assocType='CLIENT'
AND assocRef IS NOT NULL) AS ClientRef
 ON ClientRef.fileID = dbFile.fileID
LEFT OUTER JOIN 
(
SELECT ms_fileid,defence_costs_billed_composite FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code IN 
(
'FW30085','FW22135','341077','FW22352' ,'FW22135','FW22135','FW22613' ,'W15335' ,'W20110','FW23557'
) 
) AS Bills
 ON dbFile.fileID=Bills.ms_fileid
LEFT OUTER JOIN MS_Prod.dbo.udCRPaymentArrangement
 ON udCRPaymentArrangement.fileid = dbFile.fileID
LEFT OUTER JOIN #HistoryNotes ON #HistoryNotes.fileID = dbFile.fileID
LEFT OUTER JOIN #LastDoc ON #LastDoc.fileID = dbFile.fileID
WHERE (CASE WHEN clNo IN ('FW30085','FW22135') THEN 'BMW' 
WHEN clNo='341077' THEN 'Land Rover'
WHEN clNo='FW22352' THEN 'Rover'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22275%' THEN 'MG'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22222%' THEN 'R&B'
WHEN clNo='FW22613' THEN 'Mini'
WHEN clNo='W15335' THEN 'Alphera'
WHEN clNo IN ('W20110','FW23557') THEN 'Alphabet' 
END)=@Client
AND (CASE WHEN fileClosed IS NULL THEN 'Open' ELSE 'Closed' END)=@FileStatus


END 
GO
