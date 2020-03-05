SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MIBCommRecAudit]
AS
BEGIN
SELECT  MIB_ClaimNumber AS [MIB Claim Number]
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END AS [Placement]
,MatterCode AS [Matter Code]
,Short_name AS[Account Description]
,Debtor AS [Debtor]
,fee.name AS [Fee Earner] 
,a.DateOpened AS [Date Opened] 
,CASE WHEN CLO_ClosedDate='1900-01-01' THEN NULL ELSE CLO_ClosedDate END  AS [Date Closed] 
,FirstLetter.HTRY_DateInserted AS [Date of 1st Letter]
,FirstLetter.HTRY_description AS [Desc of 1st Letter]
,     CASE	WHEN FirstLetter.HTRY_DateInserted IS NULL  THEN NULL
        			ELSE (DATEDIFF(dd, DateOpened, FirstLetter.HTRY_DateInserted) )--+ 1)
						-(DATEDIFF(wk, DateOpened, FirstLetter.HTRY_DateInserted) * 2)
						-(CASE WHEN DATENAME(dw, DateOpened) = 'Sunday' THEN 1 ELSE 0 END)
						-(CASE WHEN DATENAME(dw, FirstLetter.HTRY_DateInserted) = 'Saturday' THEN 1 ELSE 0 END)
			END	 AS [Elaspsed 1st Letter]
,SecondLetter.HTRY_DateInserted AS [Date of 2nd Letter]
,SecondLetter.HTRY_description AS [Desc of 2nd Letter]
,     CASE	WHEN SecondLetter.HTRY_DateInserted IS NULL  THEN NULL
        			ELSE (DATEDIFF(dd, DateOpened, SecondLetter.HTRY_DateInserted) )--+ 1)
						-(DATEDIFF(wk, DateOpened, SecondLetter.HTRY_DateInserted) * 2)
						-(CASE WHEN DATENAME(dw, DateOpened) = 'Sunday' THEN 1 ELSE 0 END)
						-(CASE WHEN DATENAME(dw, SecondLetter.HTRY_DateInserted) = 'Saturday' THEN 1 ELSE 0 END)
			END	 AS [Elaspsed 2nd Letter]
,LastLetter.HTRY_DateInserted AS [Date of Final Letter]
,LastLetter.HTRY_description AS [Desc of Final Letter]
,     CASE	WHEN LastLetter.HTRY_DateInserted IS NULL  THEN NULL
        			ELSE (DATEDIFF(dd, DateOpened, LastLetter.HTRY_DateInserted) )--+ 1)
						-(DATEDIFF(wk, DateOpened, LastLetter.HTRY_DateInserted) * 2)
						-(CASE WHEN DATENAME(dw, DateOpened) = 'Sunday' THEN 1 ELSE 0 END)
						-(CASE WHEN DATENAME(dw, LastLetter.HTRY_DateInserted) = 'Saturday' THEN 1 ELSE 0 END)
			END	 AS [Elaspsed Final Letter]
,CASE WHEN (CASE WHEN CRD_DateClaimFormIssued='1900-01-01' THEN NULL ELSE CRD_DateClaimFormIssued END) IS NULL THEN 'No' ELSE 'Yes' END  AS [Proceedings Issued?]
,AgencyFee AS [Tracing Agent Fee]
,OriginalBalance AS [Original Balance]
,CurrentBalance AS [Current Balance]
,CASE WHEN OriginalBalance=0 THEN NULL ELSE 
CAST(ISNULL(paidtoagent,0) AS DECIMAL(10,2)) /  CAST(OriginalBalance AS DECIMAL(10,2)) END  AS [% Paid to Agent]
,CASE WHEN OriginalBalance=0 THEN NULL ELSE 
CAST(ISNULL(paidtoclient,0)AS DECIMAL(10,2)) / CAST(OriginalBalance AS DECIMAL(10,2)) END AS [% Paid to Client] 
,CASE WHEN OriginalBalance=0 THEN NULL ELSE 
 CAST(ISNULL(TotalToDate,0)AS DECIMAL(10,2)) /CAST(OriginalBalance AS DECIMAL(10,2))  END AS [Total % Paid] 
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
--LEFT OUTER JOIN (
--SELECT History.mt_int_code
--,HTRY_DateInserted
--,History.HTRY_description
--,ROW_NUMBER() OVER (PARTITION BY a.mt_int_code ORDER BY HTRY_DateInserted ASC ) AS DocxOrder
--FROM VFile_Streamlined.dbo.AccountInformation AS a
--INNER JOIN VFile_Streamlined.dbo.History
-- ON a.mt_int_code=History.mt_int_code
--WHERE ClientName LIKE '%MIB%'
--AND ISNULL(History.HTRY_DocumentName,'') <>''
--AND UPPER(History.HTRY_description) LIKE '%LETTER%'

--) AS FirstLetter
-- ON a.mt_int_code=FirstLetter.mt_int_code AND FirstLetter.DocxOrder=1
-- LEFT OUTER JOIN (
--SELECT History.mt_int_code
--,HTRY_DateInserted
--,History.HTRY_description
--,ROW_NUMBER() OVER (PARTITION BY a.mt_int_code ORDER BY HTRY_DateInserted ASC ) AS DocxOrder
--FROM VFile_Streamlined.dbo.AccountInformation AS a
--INNER JOIN VFile_Streamlined.dbo.History
-- ON a.mt_int_code=History.mt_int_code
--WHERE ClientName LIKE '%MIB%'
--AND ISNULL(History.HTRY_DocumentName,'') <>''
--AND UPPER(History.HTRY_description) LIKE '%LETTER%'

--) AS SecondLetter
-- ON a.mt_int_code=SecondLetter.mt_int_code AND SecondLetter.DocxOrder=2
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
AND DateOpened BETWEEN '2016-10-10' AND '2017-12-31'
--AND MIB_ClaimNumber='1582702'
END
GO
