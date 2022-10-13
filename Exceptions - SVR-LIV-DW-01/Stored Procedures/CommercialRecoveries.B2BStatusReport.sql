SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [CommercialRecoveries].[B2BStatusReport] 
(
@ClientName AS NVARCHAR(100)
)
AS
BEGIN
SELECT dbfile.fileID AS mt_int_code
,usrFullName
,clName
,txtClientName AS [Client Name]
,txtSubClient AS [Sub Client]
,txtClientNum AS [Client Reference (CCUK ID)]
,ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS [Matter Number (WMANS ID)]
,ISNULL(contname,fileDesc) AS [Debtor Name]
,addPostcode  AS [Post Code]
,CASE WHEN COALESCE([red_dw].[dbo].[datetimelocal](dteClosedDate),[red_dw].[dbo].[datetimelocal](fileClosed)) IS NOT  NULL THEN 'Closed' ELSE 'Open' END  AS [File Status]
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS [Account Open Date]
,curOriginalBal AS [Original Balance]
,curCurrentBal AS [Current Balance]
,txtMilestCode AS [Milestone]
,CASE WHEN cboMatOnHold='Y' THEN 'Yes' WHEN cboMatOnHold='N' THEN 'No' END   AS [Matter On Hold]
,cboMatOnHold AS PIT_MatterOnHoldYesNo
,CASE WHEN cboMatOnHold='Y' THEN txtReasAccHold ELSE NULL END  AS [Reason On Hold]
,COALESCE([red_dw].[dbo].[datetimelocal](dteClosedDate),[red_dw].[dbo].[datetimelocal](fileClosed)) AS [Closure Date]
,txtClosureRea AS [Closure Reason]
,TotalCollections AS [Total Payments Received]
,PYR_PaymentAmount AS [Last Payment Amount]
,[red_dw].[dbo].[datetimelocal](PYR_PaymentDate) AS [Last Payment Date]
,PYR_PaymentType AS [Payment Method]
,COALESCE(txtClaNum2,txtClaNum9) AS [Claim Number]
,DisbsIncurred AS [Recoverable Disbursements]
,UnRecoverableDisb AS [Irrecoverable Disbursements]
,CostsIncurred AS [Recoverable Costs]
,NULL AS [Irrecoverable Costs]
,[red_dw].[dbo].[datetimelocal](dteDateLBASent) AS [Date LBA Sent]
,[red_dw].[dbo].[datetimelocal](dteDateClForIss)  AS [Date Claim Form Issued]
,[red_dw].[dbo].[datetimelocal](dteClaimSent) AS [Date Claim Form Served]
,[red_dw].[dbo].[datetimelocal](dteAcknoDue)  AS [Acknowledgement of Service Date]
,[red_dw].[dbo].[datetimelocal](dteDefenceFiled ) AS [Date Defence Received]
,[red_dw].[dbo].[datetimelocal](dteJudgGranted) AS [Judgment Date]
,curJudgeTotal AS [Judgment Amount] 
,[red_dw].[dbo].[datetimelocal](LastHistoryNoteDate) AS [Last History Item Date]
,LastHistoryDescription AS [Last History Item Description]
,ISNULL(CONVERT(VARCHAR,[red_dw].[dbo].[datetimelocal](HistoryNoteDate4),103),'')  + ' ' + ISNULL(HistoryNote4,'') + '|'+
ISNULL(CONVERT(VARCHAR,[red_dw].[dbo].[datetimelocal](HistoryNoteDate3),103),'')  + ' ' + ISNULL(HistoryNote3,'') + '|' +
ISNULL(CONVERT(VARCHAR,[red_dw].[dbo].[datetimelocal](HistoryNoteDate2),103),'')  + ' ' + ISNULL(HistoryNote2,'') + '|' +
ISNULL(CONVERT(VARCHAR,[red_dw].[dbo].[datetimelocal](HistoryNoteDate1),103),'') + ' ' + ISNULL(HistoryNote1,'') + '|' 
 AS HistoryNotes

FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN (SELECT fileID,contName,addPostcode,contTitle,contSurname,contChristianNames FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN MS_PROD.dbo.dbContactIndividual
 ON dbContactIndividual.contID = dbContact.contID
LEFT OUTER JOIN MS_PROD.dbo.dbAddress
 ON contDefaultAddress=addID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore
 ON udCRCore.fileID = dbFile.fileID

 
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRSOLCDE
 ON udCRSOLCDE.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRIssueDetails
 ON udCRIssueDetails.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT   
                   Data.fileID AS fileid,
                   PYR_PaymentAmount ,
                   PYR_PaymentDate, 
                   PYR_PaymentType
                
          FROM (      
                 SELECT    fileID ,
                           curClient AS PYR_PaymentAmount ,
                           [red_dw].[dbo].[datetimelocal](dtePosted) AS PYR_PaymentDate, 
                           cdDesc AS PYR_PaymentType,
                  ROW_NUMBER ( ) OVER (PARTITION BY fileID  ORDER BY [red_dw].[dbo].[datetimelocal](dtePosted)  DESC) RowId
                 FROM   [MS_PROD].dbo.udCRLedgerSL
					LEFT OUTER JOIN [MS_PROD].dbo.dbCodeLookup
					 ON cboPayType=cdCode AND cdType='PAYTYPEALL'
                     
                         WHERE cboPayType <> 'PAY016'
						 AND cboCatDesc='5'
                
                        
                 ) AS Data 
                            
                  WHERE Data.RowId = 1 ) AS LastPayment
				   ON  LastPayment.fileid = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curClient) AS TotalCollections

FROM [MS_PROD].dbo.udCRLedgerSL
WHERE  cboPayType NOT IN ('PAY016','PAY011','PAY012')
AND cboCatDesc='5'
GROUP BY fileID) AS TotalPayments
 ON TotalPayments.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN cboCatDesc='2' THEN curOffice ELSE NULL END) AS CostsIncurred
,SUM(CASE WHEN cboCatDesc='1' THEN curOffice ELSE NULL END) AS DisbsIncurred
,SUM(CASE WHEN cboCatDesc='0' THEN curOffice ELSE NULL END) AS UnRecoverableDisb
FROM [MS_PROD].dbo.udCRLedgerSL
WHERE cboCatDesc IN ('2','1','0')
GROUP BY fileID
) AS DisbsCosts
 ON DisbsCosts.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT History.fileID,[red_dw].[dbo].[datetimelocal](History.dteInserted) AS LastHistoryNoteDate
,History.txtDescription AS LastHistoryDescription FROM [MS_PROD].dbo.udCRHistoryNotesSL AS History
INNER JOIN 
(
SELECT History.fileID,MAX(History.recordid) AS recordid 
FROM [MS_PROD].dbo.udCRHistoryNotesSL AS History
GROUP BY History.fileID
) AS HistoryNotes
ON History.fileID=HistoryNotes.fileID
AND HistoryNotes.recordid = History.recordid) AS LastHistory
 ON LastHistory.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT HistoryOne.fileID,HistoryNoteDate AS HistoryNoteDate1,HistoryNote AS HistoryNote1 FROM 
(
SELECT fileID,[red_dw].[dbo].[datetimelocal](dteInserted) AS HistoryNoteDate,ISNULL(txtDescription,'') + ' ' + ISNULL(txtExtraTxt,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY fileID ORDER BY recordid DESC ) AS NoteRank
 FROM [MS_PROD].dbo.udCRHistoryNotesSL
) AS HistoryOne
WHERE NoteRank=1) AS NoteOne
 ON NoteOne.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT HistoryOne.fileID,HistoryNoteDate AS HistoryNoteDate2,HistoryNote AS HistoryNote2 FROM 
(
SELECT fileID,[red_dw].[dbo].[datetimelocal](dteInserted) AS HistoryNoteDate,ISNULL(txtDescription,'') + ' ' + ISNULL(txtExtraTxt,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY fileID ORDER BY recordid DESC ) AS NoteRank
 FROM [MS_PROD].dbo.udCRHistoryNotesSL
) AS HistoryOne
WHERE NoteRank=2) AS NoteTwo
 ON NoteTwo.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT HistoryOne.fileID,HistoryNoteDate AS HistoryNoteDate3,HistoryNote AS HistoryNote3 FROM 
(
SELECT fileID,[red_dw].[dbo].[datetimelocal](dteInserted) AS HistoryNoteDate,ISNULL(txtDescription,'') + ' ' + ISNULL(txtExtraTxt,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY fileID ORDER BY recordid DESC ) AS NoteRank
 FROM [MS_PROD].dbo.udCRHistoryNotesSL
) AS HistoryOne
WHERE NoteRank=3) AS NoteThree
 ON NoteThree.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT HistoryOne.fileID,HistoryNoteDate AS HistoryNoteDate4,HistoryNote AS HistoryNote4 FROM 
(
SELECT fileID,[red_dw].[dbo].[datetimelocal](dteInserted) AS HistoryNoteDate,ISNULL(txtDescription,'') + ' ' + ISNULL(txtExtraTxt,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY fileID ORDER BY recordid DESC ) AS NoteRank
 FROM [MS_PROD].dbo.udCRHistoryNotesSL
) AS HistoryOne
WHERE NoteRank=4) AS NoteFour
 ON NoteFour.fileID = dbFile.fileID
WHERE fileType='2038'
AND usrFullName='Mark Burch'
AND clNo=@ClientName


--SELECT * FROM [MS_PROD].dbo.dbCodeLookup WHERE cdType='PAYTYPEALL'
END
GO
