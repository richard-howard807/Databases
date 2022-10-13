SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [VisualFiles].[MIBBatchSpecificMINew]
    (
      @StartDate AS DATETIME
      ,@EndDate AS DATETIME
    )
AS 
    BEGIN
        SELECT  DISTINCT DateOpened AS DateofImport ,
                MIB_DefendantTitle + ' ' + MIB_DefendantForeName + ' '
                + MIB_DefendantMiddleName + ' ' + MIB_DefendantSurname AS NameofDefendant ,
                MIB_ClaimNumber AS AccountNumber ,
                OriginalBalance AS OpeningBalance ,
                CurrentBalance AS CurrentBalance ,
                TotalPaid AS TotalPaymentstoDate ,
                CASE WHEN LastDate='1900-01-01' THEN NULL ELSE LastDate END  AS LastPaymentDate,
                Retained AS DoWeRetainSelected ,
                ReferedToCDR AS MatterReferredToCDR ,
                courtfees AS CourtIssueFee ,
                Results AS LandRegistrySearchResult ,
                HistoryInfo.TraceInfo AS TRACEREQUIREDTODAY ,
                MIB_BatchNumber AS BatchNumber,
                RetainedReason AS RetainedReason,
				PaymentArrangementAmount AS PaymentArrangementAmount,
				Clients.MIE_BatchDate
				,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END [Placement]
				,name AS [Fee Earner]
        FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            SUM(PYR_PaymentAmount) AS TotalPaid
                                  FROM      VFile_Streamlined.dbo.Payments AS Payments
                                  WHERE     PYR_PaymentType <> 'Historical Payment'
                                  GROUP BY  mt_int_code
                                ) AS Payments ON AccountInfo.mt_int_code = Payments.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            MAX(PYR_PaymentDate) AS LastDate
                                  FROM      VFile_Streamlined.dbo.Payments AS Payments
                                  WHERE     PYR_PaymentType <> 'Historical Payment'
                                  GROUP BY  mt_int_code
                                ) AS PaymentDate ON AccountInfo.mt_int_code = PaymentDate.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON  RIGHT(level_fee_earner,3)=fee_earner	
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            SUM([ledger].[Amount]) AS courtfees
                                  FROM      Vfile_Streamlined.dbo.DebtLedger
                                            AS ledger WITH ( NOLOCK )
                                  WHERE     [TransactionType] = 'op'
                                            AND DebtorLedger = 'Ledger'
                                            AND ItemCode IN ( 'aeof', 'affa',
                                                              'allo', 'ccbi',
                                                              'ccbw', 'ccif',
                                                              'choc', 'ci10',
                                                              'ci11', 'ci20',
                                                              'ci23', 'ci24',
                                                              'ci31', 'ci43',
                                                              'ci50', 'ci73',
                                                              'hcif', 'oeif',
                                                              'rcif', 'rhif',
                                                              'wcif' )
                                  GROUP BY  mt_int_code
                                ) AS LedgerFees ON AccountInfo.mt_int_code = LedgerFees.mt_int_code
                 LEFT JOIN (
					SELECT mt_int_code, ud_field##28 AS [ADA28] 
					FROM [Vfile_streamlined].dbo.uddetail
					WHERE uds_type='ADA'
							) AS ADA ON Accountinfo.mt_int_code=ADA.mt_int_code
			LEFT OUTER JOIN ( SELECT    mt_int_code AS mt_int_code ,
                                            RTRIM(ud_field##1) AS Retained,
                                            RTRIM(ud_field##2) AS RetainedReason
                                  FROM      VFile_Streamlined.dbo.uddetail
                                  WHERE     uds_type = 'MIR'
                                ) AS FileRetention ON AccountInfo.mt_int_code = FileRetention.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            'Yes' AS ReferedToCDR
                                  FROM      VFile_Streamlined.dbo.History
                                  WHERE     HTRY_description LIKE '%Matter Referred to CDR%'
                                ) AS CDR ON AccountInfo.mt_int_code = CDR.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            HTRY_DateInserted ,
                                            'Yes' AS TraceInfo
                                  FROM      VFile_Streamlined.dbo.History
                                  WHERE     HTRY_description LIKE 'TRACE REQUIRED%'
                                ) AS HistoryInfo ON AccountInfo.mt_int_code = HistoryInfo.mt_int_code
                LEFT OUTER JOIN ( SELECT    AccountInfo.mt_int_code ,
                                            Reporting.dbo.Concatenate(CONVERT(VARCHAR, HTRY_description, 103),
                                                              ', ') AS Results
                                  FROM      VFile_Streamlined.dbo.History AS History
                                            INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                            AS AccountInfo ON History.mt_int_code = AccountInfo.mt_int_code
                                                              AND ClientName = 'MIB'
                                  WHERE     HTRY_description LIKE '%LRS NEG%'
                                            OR HTRY_description LIKE '%LAND REG SURNAME MATCH%'
                                            OR HTRY_description LIKE '%No Title Number%'
                                            OR HTRY_description LIKE '%LRS NO RESULT%'
                                            OR HTRY_description LIKE '%LRS POS%'
                                            OR HTRY_description LIKE '%LRS POS - OC%'
                                  GROUP BY  AccountInfo.mt_int_code
                                ) AS LandReg ON AccountInfo.mt_int_code = LandReg.mt_int_code
        WHERE   ClientName LIKE '%MIB%'
                AND FileStatus <> 'COMP'
                AND Clients.MIE_BatchDate BETWEEN @StartDate AND @EndDate
   
    END



GO
