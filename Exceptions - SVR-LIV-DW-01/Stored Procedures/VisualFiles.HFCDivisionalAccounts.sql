SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[HFCDivisionalAccounts]
AS
BEGIN
SELECT  HIM_AccountNumber AS AccountNo ,
        Short_name AS Debtor ,
        CurrentBalance AS Balance ,
        DisbsIncurred.DisbsIncurred ,
        PaidDetails.DisbsPaid ,
        CASE WHEN DisbsIncurred.DisbsIncurred IS NULL THEN 0
             ELSE DisbsIncurred.DisbsIncurred
        END - CASE WHEN PaidDetails.DisbsPaid IS NULL THEN 0
                   ELSE PaidDetails.DisbsPaid
              END AS DisbsOutstanding ,
        CostsIncurred.CostsIncurred ,
        PaidDetails.CostsPaid ,
        CASE WHEN CostsIncurred.CostsIncurred IS NULL THEN 0
             ELSE CostsIncurred.CostsIncurred
        END - CASE WHEN PaidDetails.CostsPaid IS NULL THEN 0
                   ELSE PaidDetails.CostsPaid
              END AS CostsOutstanding ,
        CurrentBalance - ( CASE WHEN DisbsIncurred IS NULL THEN 0
                                ELSE DisbsIncurred
                           END + CASE WHEN CostsIncurred IS NULL THEN 0
                                      ELSE CostsIncurred
                                 END ) AS BalanceExcludingcosts ,
        LastPaymentDate AS LastPaymentDate ,
        Amount AS AmountofLastPayment ,
        CLO_ClosureReason AS ReasonforClosure ,
        CLO_ClosedDate AS DateofClosure ,
        HIM_AccountType,ClientName
FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
        INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
 -- Disbursements Paid and Costs Paid
        LEFT OUTER JOIN ( SELECT    SOLPYR.mt_int_code ,
                                    SUM(SOLPYR.PYR_AmountDisbursementPaid) AS DisbsPaid ,
                                    SUM(PYR_AmountRecoverableCostsPaid) AS CostsPaid
                          FROM      VFile_Streamlined.dbo.Payments AS SOLPYR
                          GROUP BY  SOLPYR.mt_int_code
                        ) AS PaidDetails ON AccountInfo.mt_int_code = PaidDetails.mt_int_code
 -- Disbursements Incurred
        LEFT OUTER JOIN ( SELECT    ledger.mt_int_code ,
                                    SUM(ledger.Amount) AS DisbsIncurred
                          FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
                          WHERE     ledger.TransactionType = 'OP'
                                    AND DebtOrLedger = 'Ledger'
                          GROUP BY  ledger.mt_int_code
                        ) AS DisbsIncurred ON AccountInfo.mt_int_code = DisbsIncurred.mt_int_code
-- Costs Incurred
        LEFT OUTER JOIN ( SELECT    debt.mt_int_code ,
                                    SUM(debt.amount) AS CostsIncurred
                          FROM      VFile_Streamlined.dbo.DebtLedger AS Debt
                          WHERE     debt.TransactionType = 'COST'
                                    AND DebtOrLedger = 'Debt'
                          GROUP BY  debt.mt_int_code
                        ) AS CostsIncurred ON AccountInfo.mt_int_code = CostsIncurred.mt_int_code
        LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                    COUNT(mt_int_code) AS Number ,
                                    SUM(SubTotal) AS Amount ,
                                    [Payment Date12] AS LastPaymentDate
                          FROM      ( SELECT    mt_int_code ,
                                                SubTotal ,
                                                [Payment Date12] ,
                                                ROW_NUMBER() OVER ( PARTITION BY mt_int_code ORDER BY [Payment Date12] DESC ) AS OrderID
                                      FROM      ( SELECT    SOLPYR.mt_int_code ,
                                                            SUM(PYR_PaymentAmount) AS SubTotal ,
                                                            PYR_PaymentDate AS [Payment Date12]
                                                  FROM      VFile_Streamlined.dbo.AccountInformation
                                                            AS AccountInfo
                                                            INNER JOIN VFile_Streamlined.dbo.Payments
                                                            AS SOLPYR ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
                                                  WHERE     PYR_PaymentType <> 'Historical Payment'
                                                  GROUP BY  SOLPYR.mt_int_code ,
                                                            PYR_PaymentDate
                                                ) subq1
                                    ) subq2
                          WHERE     OrderID = 1
                          GROUP BY  [Payment Date12] ,
                                    mt_int_code
                        ) AS LastPayment ON AccountInfo.mt_int_code = LastPayment.mt_int_code
        LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                    Amount AS DebtExclusion
                          FROM      VFile_Streamlined.dbo.DebtLedger
                          WHERE     DebtOrLedger = 'Debt'
                                    AND TransactionType = 'INVO'
                                    AND ItemDescription = 'LBA without debt details'
                        ) AS Exclude ON AccountInfo.mt_int_code = Exclude.mt_int_code
WHERE   ClientName = 'HFC'
        AND HIM_AccountType = 'D'


END
GO
