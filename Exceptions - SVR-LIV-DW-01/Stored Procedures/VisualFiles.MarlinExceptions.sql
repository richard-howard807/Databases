SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MarlinExceptions] --EXEC VisualFiles.MarlinPaymentLetterAgreed '2016-09-01','2016-09-21'

AS
BEGIN
SELECT 
CDE_ClientAccountNumber AS [SupplierRef] 
,CDE_ClientAccountNumber AS [ClientRef] 
,Title
,Forename
,NULL AS [Middle Name]
,Surname
,LastHistoryNoteDate AS [Date of Last Item in History]
,LastHistoryDescription AS [Description of Last Item In History]
,CASE WHEN PIT_MatterOnHoldYesNo=1 THEN 'Yes' ELSE 'No' END AS [Matter on Hold]
,PIT_ReasonAccountOnHold AS [Reason for being on hold]

FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens ON AccountInfo.mt_int_code=ClientScreens.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
LEFT OUTER JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE DebtorInformation.ContactType='Primary Debtor') AS Debtor
  ON AccountInfo.mt_int_code=Debtor.mt_int_code
LEFT OUTER JOIN 
(
SELECT History.mt_int_code,History.HTRY_DateInserted AS LastHistoryNoteDate
,History.HTRY_description AS LastHistoryDescription FROM VFile_Streamlined.dbo.History
INNER JOIN 
(
SELECT History.mt_int_code,MAX(HTRY_HistoryNo) AS HistoryNo FROM VFile_Streamlined.dbo.History AS History
INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON History.mt_int_code=AccountInfo.mt_int_code
WHERE ClientName ='Marlin'
GROUP BY History.mt_int_code
) AS HistoryNotes
ON History.mt_int_code=HistoryNotes.mt_int_code
AND History.HTRY_HistoryNo=HistoryNotes.HistoryNo

) AS HistoryNotes
ON AccountInfo.mt_int_code=HistoryNotes.mt_int_code
WHERE ClientName='Marlin'
AND FileStatus <>'COMP'

END
GO
