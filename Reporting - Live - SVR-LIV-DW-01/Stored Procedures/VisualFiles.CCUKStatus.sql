SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [VisualFiles].[CCUKStatus] -- VisualFiles.CCUKStatusVersion2 'Cabot'
(
@ClientName AS VARCHAR(MAX)
)
AS

SELECT AccountInfo.mt_int_code
,CASE WHEN [Secondary ClientName] IS NULL THEN CDE18 ELSE [Secondary ClientName] END AS [Client Name]
,SubClient AS [Sub Client]
,CDE_ClientAccountNumber AS [Client Reference (CCUK ID)]
,MatterCode AS [Matter Number (WMANS ID)]
,CASE WHEN ISNULL(DebtorInfo.Title,'') + ' ' + ISNULL(DebtorInfo.Forename,'') + ' ' + ISNULL(DebtorInfo.Surname,'') ='' THEN DebtorName ELSE  ISNULL(DebtorInfo.Title,'') + ' ' + ISNULL(DebtorInfo.Forename,'') + ' ' + ISNULL(DebtorInfo.Surname,'') END AS [Debtor Name]
,CASE WHEN DebtorInfo.PostCode IS NULL THEN DebtorIn.PostCode ELSE DebtorInfo.PostCode END  AS [Post Code]
,CASE WHEN FileStatus='COMP' THEN 'Closed' ELSE 'Open' END  AS [File Status]
,DateOpened AS [Account Open Date]
,OriginalBalance AS [Original Balance]
,CurrentBalance AS [Current Balance]
,MilestoneCode AS [Milestone]
,CASE WHEN PIT_MatterOnHoldYesNo=1 THEN 'Yes' ELSE 'No' END  AS [Matter On Hold]
,PIT_MatterOnHoldYesNo
,CASE WHEN PIT_MatterOnHoldYesNo=1 THEN PIT_ReasonAccountOnHold ELSE NULL END  AS [Reason On Hold]
,CLO_ClosedDate AS [Closure Date]
,CLO_ClosureReason AS [Closure Reason]
,TotalCollections AS [Total Payments Received]
,PYR_PaymentAmount AS [Last Payment Amount]
,PYR_PaymentDate AS [Last Payment Date]
,PYR_PaymentType AS [Payment Method]
,CCT_Claimnumber9 AS [Claim Number]
,DisbsIncurred AS [Recoverable Disbursements]
,UnRecoverableDisb AS [Irrecoverable Disbursements]
,CostsIncurred AS [Recoverable Costs]
,NULL AS [Irrecoverable Costs]
,CASE WHEN CRD_DateLBASent='1900-01-01' THEN NULL ELSE CRD_DateLBASent END  AS [Date LBA Sent]
,CASE WHEN CRD_DateClaimFormIssued='1900-01-01' THEN NULL ELSE CRD_DateClaimFormIssued END  AS [Date Claim Form Issued]
,CASE WHEN CRD_DateClaimSent='1900-01-01' THEN NULL ELSE CRD_DateClaimSent END  AS [Date Claim Form Served]
,CASE WHEN CRD_DateAcknowledgementDue='1900-01-01' THEN NULL ELSE CRD_DateAcknowledgementDue END  AS [Acknowledgement of Service Date]
,CASE WHEN CRD_DateDefenceWasFiled='1900-01-01' THEN NULL ELSE CRD_DateDefenceWasFiled END  AS [Date Defence Received]
,CASE WHEN CRD_DateJudgmentGranted='1900-01-01' THEN NULL ELSE CRD_DateJudgmentGranted END  AS [Judgment Date]
,CCUKJudgmentCosts AS [Judgment Amount]
,LastHistoryNoteDate AS [Last History Item Date]
,LastHistoryDescription AS [Last History Item Description]
,ISNULL(CONVERT(VARCHAR,HistoryNoteDate4,103),'')  + ' ' + ISNULL(HistoryNote4,'') + '|'+
ISNULL(CONVERT(VARCHAR,HistoryNoteDate3,103),'')  + ' ' + ISNULL(HistoryNote3,'') + '|' +
ISNULL(CONVERT(VARCHAR,HistoryNoteDate2,103),'')  + ' ' + ISNULL(HistoryNote2,'') + '|' +
ISNULL(CONVERT(VARCHAR,HistoryNoteDate1,103),'') + ' ' + ISNULL(HistoryNote1,'') + '|' 


 AS HistoryNotes
FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
LEFT OUTER JOIN 
(
SELECT History.mt_int_code,History.HTRY_DateInserted AS LastHistoryNoteDate
,History.HTRY_description AS LastHistoryDescription FROM VFile_Streamlined.dbo.History
INNER JOIN 
(
SELECT History.mt_int_code,MAX(HTRY_HistoryNo) AS HistoryNo FROM VFile_Streamlined.dbo.History AS History
INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON History.mt_int_code=AccountInfo.mt_int_code
WHERE ClientName =@ClientName
GROUP BY History.mt_int_code
) AS HistoryNotes
ON History.mt_int_code=HistoryNotes.mt_int_code
AND History.HTRY_HistoryNo=HistoryNotes.HistoryNo

) AS HistoryNotes
ON AccountInfo.mt_int_code=HistoryNotes.mt_int_code
LEFT OUTER JOIN 
(
SELECT mt_int_code,HistoryNoteDate AS HistoryNoteDate1,HistoryNote AS HistoryNote1 FROM 
(
SELECT History.mt_int_code,HTRY_DateInserted AS HistoryNoteDate,ISNULL(HTRY_description,'') + ' ' + ISNULL(HTRY_ExtraText,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY History.mt_int_code ORDER BY HTRY_HistoryNo DESC ) AS NoteRank
 FROM VFile_Streamlined.dbo.History AS History
 INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON History.mt_int_code=AccountInfo.mt_int_code
WHERE ClientName =@ClientName
) AS HistoryOne
WHERE NoteRank=1
) AS History1
ON AccountInfo.mt_int_code=History1.mt_int_code
LEFT OUTER JOIN 
(
SELECT mt_int_code,HistoryNoteDate AS HistoryNoteDate2,HistoryNote AS HistoryNote2 FROM 
(
SELECT History.mt_int_code,HTRY_DateInserted AS HistoryNoteDate,ISNULL(HTRY_description,'') + ' ' + ISNULL(HTRY_ExtraText,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY History.mt_int_code ORDER BY HTRY_HistoryNo DESC ) AS NoteRank
 FROM VFile_Streamlined.dbo.History AS History
 INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON History.mt_int_code=AccountInfo.mt_int_code
WHERE ClientName =@ClientName
) AS HistoryOne
WHERE NoteRank=2
) AS History2
ON AccountInfo.mt_int_code=History2.mt_int_code
LEFT OUTER JOIN 
(
SELECT mt_int_code,HistoryNoteDate AS HistoryNoteDate3,HistoryNote AS HistoryNote3 FROM 
(
SELECT History.mt_int_code,HTRY_DateInserted AS HistoryNoteDate,ISNULL(HTRY_description,'') + ' ' + ISNULL(HTRY_ExtraText,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY History.mt_int_code ORDER BY HTRY_HistoryNo DESC ) AS NoteRank
 FROM VFile_Streamlined.dbo.History AS History
 INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON History.mt_int_code=AccountInfo.mt_int_code
WHERE ClientName =@ClientName
) AS HistoryOne
WHERE NoteRank=3
) AS History3
ON AccountInfo.mt_int_code=History3.mt_int_code
LEFT OUTER JOIN 
(
SELECT mt_int_code,HistoryNoteDate AS HistoryNoteDate4,HistoryNote AS HistoryNote4 FROM 
(
SELECT History.mt_int_code,HTRY_DateInserted AS HistoryNoteDate,ISNULL(HTRY_description,'') + ' ' + ISNULL(HTRY_ExtraText,'') AS HistoryNote,
ROW_NUMBER() OVER ( PARTITION BY History.mt_int_code ORDER BY HTRY_HistoryNo DESC ) AS NoteRank
 FROM VFile_Streamlined.dbo.History AS History
 INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON History.mt_int_code=AccountInfo.mt_int_code
WHERE ClientName =@ClientName
) AS HistoryOne
WHERE NoteRank=4
) AS History4
ON AccountInfo.mt_int_code=History4.mt_int_code
LEFT OUTER JOIN ( SELECT   
                   Data.mt_int_code AS mtintCode,
                   PYR_PaymentAmount ,
                   PYR_PaymentDate, 
                   PYR_PaymentType
                
          FROM (      
                 SELECT    Payments.mt_int_code ,
                           PYR_PaymentAmount ,
                           PYR_PaymentDate, 
                           PYR_PaymentType,
                  ROW_NUMBER ( ) OVER (PARTITION BY Payments.mt_int_code  ORDER BY PYR_PaymentDate  DESC) RowId
                 
                    FROM   VFile_Streamlined.dbo.Payments AS Payments
                    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                     ON Payments.mt_int_code=AccountInfo.mt_int_code
                     
                         WHERE PYR_PaymentType <> 'Historical Payment'
                         AND ClientName =@ClientName
                        
                 ) AS Data 
                            
                  WHERE Data.RowId = 1     
                
                ) AS  LastPayment 
        ON    AccountInfo.mt_int_code = LastPayment.mtintCode  
LEFT OUTER JOIN  VFile_Streamlined.dbo.SOLIMP AS SOLIMP
ON AccountInfo.mt_int_code=SOLIMP.mt_int_code 
LEFT OUTER JOIN VFile_Streamlined.dbo.[SOLCDE] AS SOLCDE
 ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
LEFT OUTER JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType='Primary Debtor')  DebtorInfo
ON AccountInfo.mt_int_code=DebtorInfo.mt_int_code
LEFT OUTER JOIN (SELECT    mt_int_code ,
                                                            Reporting.dbo.Concatenate(DebtorName,
                                                              ' and ') AS DebtorName ,
                                                            Reporting.dbo.Concatenate(PostCode,
                                                              ',') AS PostCode ,
                                                               SUM(NumberDebtorName) AS NumberDebtorName
                                                  FROM      ( SELECT
                                                              mt_int_code ,
                                                              ISNULL(Title,'') + ' ' + ISNULL(Forename,'') + ' ' + ISNULL(Surname,'')
                                                              AS DebtorName
                                                              ,PostCode AS PostCode,
                                                              1 AS NumberDebtorName
                                                              FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType='Debtor In'
												              --AND mt_int_code=225531
                                                            ) AS AllData
                                                  GROUP BY  AllData.mt_int_code
                                                  )  DebtorIn
ON AccountInfo.mt_int_code=DebtorIn.mt_int_code

LEFT OUTER JOIN VFile_Streamlined.dbo.IssueDetails AS IssueDetails
 ON AccountInfo.mt_int_code=IssueDetails.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.Judgment AS Judgment
 ON AccountInfo.mt_int_code=Judgment.mt_int_code
LEFT OUTER JOIN 
(
SELECT mt_int_code,ud_field##25 AS CCUKJudgmentCosts
FROM VFile_Streamlined.dbo.uddetail WITH (NOLOCK)
WHERE uds_type='JUD'
) AS SOLJUD
 ON AccountInfo.mt_int_code=SOLJUD.mt_int_code
-- Disbursements Incurred 
    LEFT OUTER JOIN (
        --              SELECT    ledger.mt_int_code
        --                      , SUM(Ledger.Amount) AS DisbsIncurred
        --              FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
        --              WHERE     ledger.TransactionType = 'OP'
        --                       AND DebtOrLedger = 'Ledger'
        --                       AND ItemCode NOT IN ('ZLRT', 'ZLRO','ZLPC', 'ZAFF','ZOFC'
								--,'LROC','LRTR','ZLRT','OFCF','ZCON','ZDBV','ZLRO','ZOFC','ZSLC')

        --              GROUP BY  Ledger.mt_int_code
		SELECT    ledger.mt_int_code
         , SUM(Ledger.Amount) AS DisbsIncurred
		 FROM VFile_Streamlined.dbo.DebtLedger AS ledger
		 WHERE ledger.DebtOrLedger='Debt'
		 AND ledger.TransactionType='DISB'
		 GROUP BY ledger.mt_int_code


                    ) AS RecoverableDisb
            ON AccountInfo.mt_int_code = RecoverableDisb.mt_int_code
-- Disbursements Incurred 
    LEFT OUTER JOIN (
                      SELECT    ledger.mt_int_code
                              , SUM(Ledger.Amount) AS UnRecoverableDisb
                      FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
					  LEFT JOIN VFile_Streamlined.dbo.RecoverableORNot ON RecoverableORNot.ItemCode = Ledger.ItemCode
                      WHERE      DebtOrLedger = 'Ledger'
					  AND Ledger.TransactionType NOT IN ('CR','CP')
                               AND (NOT (recoverable=1 OR Ledger.ItemCode IN ('NRCA','LRBI','LRCH')) OR Ledger.ItemCode='') --AND ISNULL(Recoverable,0)=0

                      GROUP BY  Ledger.mt_int_code
                    ) AS UnRecoverableDisb
            ON AccountInfo.mt_int_code = UnRecoverableDisb.mt_int_code
-- Costs Incurred
    LEFT OUTER JOIN (
                      SELECT    Debt.mt_int_code
                              , SUM(Debt.amount) AS CostsIncurred
                      FROM      VFile_Streamlined.dbo.DebtLedger AS Debt
                      WHERE     Debt.TransactionType = 'COST'
                                AND DebtOrLedger = 'Debt'
                      GROUP BY  Debt.mt_int_code
                    ) AS CostsIncurred
            ON AccountInfo.mt_int_code = CostsIncurred.mt_int_code
LEFT OUTER JOIN 
(
SELECT A.mt_int_code,SUM(PYR_PaymentAmount) AS TotalCollections

FROM VFile_Streamlined.dbo.AccountInformation AS A
INNER JOIN VFile_Streamlined.dbo.Payments AS Payments
ON A.mt_int_code=Payments.mt_int_code
WHERE ClientName=@ClientName
AND PYR_PaymentType NOT IN ('Historical Payment','CCA Request','SAR')
GROUP BY A.mt_int_code
) AS Collections
ON AccountInfo.mt_int_code=Collections.mt_int_code
WHERE ClientName=@ClientName AND FileStatus <> 'COMP'
GO
