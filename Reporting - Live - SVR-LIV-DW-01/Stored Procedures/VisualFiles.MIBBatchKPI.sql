SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MIBBatchKPI] 
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT 
MIB_ClaimNumber AS [MIB reference]
,Debtor AS [Defendant name]
,MatterCode AS [Our reference]
,fee.name AS [Case handler name]
,OriginalBalance AS [Original Balance]
,CurrentBalance AS [Current Balance]
,DateOpened AS [Date imported]
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END AS [Placement]
,FirstLetter.HTRY_DateInserted AS [Date of 1st letter]
,SecondLetter.HTRY_DateInserted AS [Date of 2nd letter]
,LastLetter.HTRY_DateInserted AS [Date of Last Chance letter]
,MilestoneDescription AS [Current Milestone]
,TotalToDate AS [Payments received]
,DisbsIncurred AS [Disbursements incurred]
,CASE WHEN AgencyFee >0 THEN 'Yes' ELSE 'No' END  AS [Trace performed]
,MIE_BatchDate
,MIB_BatchNumber
FROM VFile_Streamlined.dbo.AccountInformation AS a
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS b
 ON  a.mt_int_code=b.mt_int_code
LEFT OUTER JOIN (SELECT DebtorInformation.mt_int_code,ISNULL(Title,'')  + ' ' + ISNULL(Forename,'')  + ' ' + ISNULL(Surname,'')  AS Debtor
,ISNULL(Address1,'') + ' ' + ISNULL(Address2,'')  + ' ' + ISNULL(Address3,'')  + ' ' + ISNULL(Address4,'')  + ' ' + ISNULL(PostCode,'')  AS [DebtorAddress]
FROM VFile_Streamlined.dbo.DebtorInformation
INNER JOIN VFile_Streamlined.dbo.AccountInformation ON DebtorInformation.mt_int_code=AccountInformation.mt_int_code
WHERE ContactType='Primary Debtor'
AND ClientName LIKE '%MIB%') AS Addresses
 ON A.mt_int_code=Addresses.mt_int_code
LEFT OUTER JOIN ( SELECT    ledger.mt_int_code AS ID ,
                                    SUM(ledger.Amount) AS DisbsIncurred
                          FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
                          WHERE     ledger.TransactionType = 'OP'
                                    AND DebtOrLedger = 'Ledger'
                              --AND PostedDate<@StartDate
                          GROUP BY  ledger.mt_int_code
                        ) AS DisbsIncurred ON a.mt_int_code = DisbsIncurred.ID

 LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON a.mt_int_code=ADA.mt_int_code
			LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON 
			--RTRIM(REPLACE(level_fee_earner,'LIT/DEBT/MIB/',''))
			
			RIGHT(level_fee_earner,3)=fee_earner
LEFT OUTER JOIN (
                   SELECT --- Payments to client and the other one
                            mt_int_code
                          , SUM(paidtoclient) AS paidtoclient
                          , SUM(paidtoagent) AS paidtoagent
                   FROM     (
                              SELECT    a.[mt_int_code]
                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'yes'
                                             THEN SUM(PYR_PaymentAmount)
                                             ELSE 0
                                        END AS paidtoclient
                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'No'
                                             THEN SUM(PYR_PaymentAmount)
                                             ELSE 0
                                        END AS paidtoagent
                              FROM      VFile_Streamlined.dbo.Payments AS payment
                              INNER JOIN VFile_Streamlined.dbo.AccountInformation AS a
                               ON payment.mt_int_code=a.mt_int_code
                              WHERE ClientName LIKE '%MIB%'
                      
                              GROUP BY  a.[mt_int_code]
                                      , PYR_PaymentTakenByClient
                            ) AllPayments
                   GROUP BY mt_int_code
                 ) AS AggregatePayments
        ON a.mt_int_code  = AggregatePayments.mt_int_code
        LEFT OUTER JOIN 
                           (
                           SELECT mt_int_code,SUM(PYR_PaymentAmount) AS TotalToDate
                           ,SUM(PYR_AmountPaidToWeightmansExcVAT) AS PYR_AmountPaidToWeightmansExcVAT
                           FROM VFile_Streamlined.dbo.Payments AS Payments
                           WHERE PYR_PaymentType <> 'Historical Payment'
                           GROUP BY mt_int_code
                           ) AS PaidToDate
                            ON a.mt_int_code=PaidToDate.mt_int_code
        LEFT OUTER JOIN 
        (
        SELECT a.mt_int_code,SUM(DebtLedger.Amount) AS AgencyFee
		FROM VFile_Streamlined.dbo.AccountInformation AS a
		INNER JOIN VFile_Streamlined.dbo.DebtLedger
		 ON a.mt_int_code=DebtLedger.mt_int_code
		WHERE ItemCode='LPC1'
		AND ClientName LIKE '%MIB%'
		GROUP BY a.mt_int_code
        ) AS AgencyFee
         ON a.mt_int_code=AgencyFee.mt_int_code

LEFT OUTER JOIN (
SELECT History.mt_int_code
,HTRY_DateInserted
,History.HTRY_description
,ROW_NUMBER() OVER (PARTITION BY a.mt_int_code ORDER BY HTRY_DateInserted ASC ) AS DocxOrder
FROM VFile_Streamlined.dbo.AccountInformation AS a
INNER JOIN VFile_Streamlined.dbo.History
 ON a.mt_int_code=History.mt_int_code
WHERE ClientName LIKE '%MIB%'
AND ISNULL(History.HTRY_DocumentName,'') <>''
AND (
UPPER(History.HTRY_description) ='Letter to Debtor - MIB LBA' OR 
UPPER(History.HTRY_description) ='Letter to Debtor - MIB 2nd Placement LBA'
)

) AS FirstLetter
 ON a.mt_int_code=FirstLetter.mt_int_code AND FirstLetter.DocxOrder=1
LEFT OUTER JOIN (
SELECT History.mt_int_code
,HTRY_DateInserted
,History.HTRY_description
,ROW_NUMBER() OVER (PARTITION BY a.mt_int_code ORDER BY HTRY_DateInserted ASC ) AS DocxOrder
FROM VFile_Streamlined.dbo.AccountInformation AS a
INNER JOIN VFile_Streamlined.dbo.History
 ON a.mt_int_code=History.mt_int_code
WHERE ClientName LIKE '%MIB%'
AND ISNULL(History.HTRY_DocumentName,'') <>''
AND UPPER(History.HTRY_description) ='Letter to Debtor - MIB Second Letter'

) AS SecondLetter
 ON a.mt_int_code=SecondLetter.mt_int_code AND SecondLetter.DocxOrder=1

LEFT OUTER JOIN (
SELECT History.mt_int_code
,HTRY_DateInserted
,History.HTRY_description
,ROW_NUMBER() OVER (PARTITION BY a.mt_int_code ORDER BY HTRY_DateInserted ASC ) AS DocxOrder
FROM VFile_Streamlined.dbo.AccountInformation AS a
INNER JOIN VFile_Streamlined.dbo.History
 ON a.mt_int_code=History.mt_int_code
WHERE ClientName LIKE '%MIB%'
AND ISNULL(History.HTRY_DocumentName,'') <>''
AND UPPER(History.HTRY_description) ='Letter to Debtor - MIB Third - Last Chance - Letter'

) AS LastLetter
 ON a.mt_int_code=LastLetter.mt_int_code AND LastLetter.DocxOrder=1  
WHERE ClientName LIKE '%MIB%'
AND DateOpened BETWEEN @StartDate AND @EndDate
END
GO
