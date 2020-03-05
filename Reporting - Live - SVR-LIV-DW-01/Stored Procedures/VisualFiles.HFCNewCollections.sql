SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




--Exec  [VisualFiles].[HFCNewCollections]'2009-06-01','2012-06-19','HFC New Contract'



CREATE  PROCEDURE [VisualFiles].[HFCNewCollections]
    @StartDate DATE ,
    @EndDate DATE ,
    @ClientName VARCHAR(50)
AS 
 

    SET nocount ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

         SELECT  MatterCode AS MatterNo ,
            HIM_AccountType AS CliDiv ,
            HIM_AccountNumber AS AccountNo ,
            short_name AS OppoName ,
            CurrentBalance AS CurrBal ,
            CurrentBalance + LastPayment.Payment AS OpeningBalance,
            CASE WHEN ( CASE WHEN PYR_PaymentTakenByClient <> 'Yes'
                             THEN PYR_PaymentAmount
                        END ) IS NULL THEN 0
                 ELSE ( CASE WHEN PYR_PaymentTakenByClient <> 'Yes'
                             THEN PYR_PaymentAmount
                        END )
            END AS Payment ,
            CASE WHEN ( CASE WHEN PYR_PaymentTakenByClient = 'Yes' AND ISNULL(PYR_PaymentType,'') <> 'Balance Adjustment' -- added by PA on #1363
                             THEN PYR_PaymentAmount
                        END ) IS NULL THEN 0
                 ELSE ( CASE WHEN PYR_PaymentTakenByClient = 'Yes' AND ISNULL(PYR_PaymentType,'') <> 'Balance Adjustment' -- added by PA on #1363
                             THEN PYR_PaymentAmount
                        END )
            END AS DirectPayments ,
            PYR_PaymentDate AS PaymentDate ,

            CASE WHEN ClientName = 'HFC Low Balance'
                      OR ClientName = 'HFC New Contract' THEN 0
                 ELSE ( CASE WHEN ( CASE WHEN DisbsIncurred.DisbsIncurred = 0
                                         THEN 0
                                         ELSE DisbsIncurred.DisbsIncurred
                                    END )
                                  - ( CASE WHEN DISPSOLPAID.DisPaid IS NULL
                                           THEN 0
                                           ELSE DISPSOLPAID.DisPaid
                                      END ) < 0 THEN 0
                             ELSE ( CASE WHEN DisbsIncurred.DisbsIncurred = 0
                                         THEN 0
                                         ELSE DisbsIncurred.DisbsIncurred
                                    END )
                                  - ( CASE WHEN DISPSOLPAID.DisPaid IS NULL
                                           THEN 0
                                           ELSE DISPSOLPAID.DisPaid
                                      END )
                        END )
            END AS OpeningDisp ,
            CASE WHEN DisbsIncurredcm.DisbsIncurred IS NULL THEN 0
                 ELSE DisbsIncurredcm.DisbsIncurred
            END AS DispIncurredcm ,
            CASE WHEN ClientName = 'HFC Low Balance'
                      OR ClientName = 'HFC New Contract'
                 THEN ( CASE WHEN DisbsIncurredcm.DisbsIncurred IS NULL THEN 0
                             ELSE DisbsIncurredcm.DisbsIncurred
                        END )
                 ELSE ( CASE WHEN (CASE WHEN NonRecoverable='Y' THEN SOLPYR.PYR_AmountDisbursementPaid + SOLPYR.PYR_AmountNonRecoverableCostsPaid ELSE SOLPYR.PYR_AmountDisbursementPaid  END ) IS NULL
                             THEN 0
                             ELSE (CASE WHEN NonRecoverable='Y' THEN SOLPYR.PYR_AmountDisbursementPaid + SOLPYR.PYR_AmountNonRecoverableCostsPaid ELSE SOLPYR.PYR_AmountDisbursementPaid  END)
                        END )
            END AS DispInvoicedThisMonth ,
            CASE WHEN ClientName = 'HFC Low Balance'
                      OR ClientName = 'HFC New Contract' THEN 0
                 ELSE ( CASE WHEN ( CASE WHEN CostsIncurred.costsIncurred = 0
                                         THEN 0
                                         ELSE CostsIncurred.costsIncurred
                                    END )
                                  - ( CASE WHEN DISPSOLPAID.SOLPaid IS NULL
                                           THEN 0
                                           ELSE DISPSOLPAID.SOLPaid
                                      END ) < 0 THEN 0
                             ELSE ( CASE WHEN CostsIncurred.costsIncurred = 0
                                         THEN 0
                                         ELSE CostsIncurred.costsIncurred
                                    END )
                                  - ( CASE WHEN DISPSOLPAID.SOLPaid IS NULL
                                           THEN 0
                                           ELSE DISPSOLPAID.SOLPaid
                                      END )
                        END )
            END AS OpeningSolCosts ,
            CASE WHEN CostsIncurredcm.CostsIncurredcm IS NULL THEN 0
                 ELSE CostsIncurredcm.CostsIncurredcm
            END AS SolCostscm ,
            CASE WHEN ClientName = 'HFC Low Balance'
                      OR ClientName = 'HFC New Contract'
                 THEN ( CASE WHEN CostsIncurredcm.CostsIncurredcm IS NULL
                             THEN 0
                             ELSE CostsIncurredcm.CostsIncurredcm
                        END )
                 ELSE ( CASE WHEN SOLPYR.PYR_AmountRecoverableCostsPaid IS NULL
                             THEN 0
                             ELSE SOLPYR.PYR_AmountRecoverableCostsPaid
                        END )
            END AS SolCostsThisMonth ,
            CASE WHEN ClientName = 'HFC'
                      AND PDE_MilestonePaymentReceviedIn <> 'COMP' THEN 0.14
                 WHEN ClientName = 'HFC Low Balance'
                      AND PDE_MilestonePaymentReceviedIn ='INST' THEN 0.10
                 WHEN ClientName = 'HFC Low Balance'
                      AND PDE_MilestonePaymentReceviedIn <> 'INST' THEN 0.00
                 WHEN ClientName = 'HFC New Contract'
                      AND PDE_MilestonePaymentReceviedIn = 'INST' THEN 0.10
                 WHEN ClientName = 'HFC New Contract'
                      AND PDE_MilestonePaymentReceviedIn <> 'INST'
                       THEN 0.075
                 WHEN PDE_MilestonePaymentReceviedIn = 'COMP' THEN 0.02
            END AS Commission ,
    
            CASE WHEN ClientName = 'HFC Low Balance'
                      AND PDE_MilestonePaymentReceviedIn <> 'INST' THEN 0.00
                 WHEN ClientName = 'HFC'
                 THEN ( PYR_PaymentAmount
                        - ( (CASE WHEN NonRecoverable='Y' THEN SOLPYR.PYR_AmountDisbursementPaid + SOLPYR.PYR_AmountNonRecoverableCostsPaid ELSE SOLPYR.PYR_AmountDisbursementPaid  END )
                            + PYR_AmountRecoverableCostsPaid ) )
                      * (  CASE WHEN ClientName = 'HFC'
                      AND PDE_MilestonePaymentReceviedIn <> 'COMP' THEN 0.14
                 WHEN ClientName = 'HFC Low Balance'
                      AND PDE_MilestonePaymentReceviedIn ='INST' THEN 0.10
                 WHEN ClientName = 'HFC Low Balance'
                      AND PDE_MilestonePaymentReceviedIn <> 'INST' THEN 0.00
                 WHEN ClientName = 'HFC New Contract'
                      AND PDE_MilestonePaymentReceviedIn = 'INST' THEN 0.10
                 WHEN ClientName = 'HFC New Contract'
                      AND PDE_MilestonePaymentReceviedIn <> 'INST'
                       THEN 0.075
                 WHEN PDE_MilestonePaymentReceviedIn = 'COMP' THEN 0.02
            END )
                 ELSE PYR_PaymentAmount
                      * ( CASE WHEN ClientName = 'HFC'
                                    AND PDE_MilestonePaymentReceviedIn <> 'COMP' THEN 0.14
                               WHEN ClientName = 'HFC Low Balance'
                                    AND PDE_MilestonePaymentReceviedIn <> 'COMP' THEN 0.10
                               WHEN ClientName = 'HFC Low Balance'
                                    AND PDE_MilestonePaymentReceviedIn = 'INST' THEN 0.00
                               WHEN ClientName = 'HFC New Contract'
                                    AND PDE_MilestonePaymentReceviedIn = 'INST' THEN 0.10
                               WHEN ClientName = 'HFC New Contract'
                                    AND PDE_MilestonePaymentReceviedIn <> 'INST'
                                     THEN 0.075
                               WHEN PDE_MilestonePaymentReceviedIn = 'COMP' THEN 0.02
                          END )
            END AS CommissionAmount,
            'WEIGHTMAI' + dbo.FormatDateTime(PYR_PaymentDate, 'YYYYMMDD') AS AccountPayDate
            --CASE WHEN SolCostIncurred.SolCost IS NULL THEN 0
            --     ELSE SolCostIncurred.SolCost
            --END AS SolFixedCost
             ,NonRecoverable
    FROM VFile_Streamlined.dbo.Payments AS SOLPYR
    
            INNER JOIN VFile_Streamlined.dbo.AccountInformation AS matdb 
            ON SOLPYR.mt_int_code = matdb.mt_int_code AND ClientName = @ClientName
            LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS SOLHIM 
            ON matdb.mt_int_code = SOLHIM.mt_int_code
            LEFT OUTER JOIN ( SELECT    ledger.mt_int_code AS ID ,
                                        SUM(ledger.Amount) AS DisbsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
                              WHERE     ledger.TransactionType = 'OP'
                              AND DebtOrLedger='Ledger'
                              AND PostedDate<@StartDate
                              GROUP BY  ledger.mt_int_code
                            ) AS DisbsIncurred ON matdb.mt_int_code = DisbsIncurred.ID
            LEFT OUTER JOIN ( SELECT    ledger.mt_int_code AS ID ,
                                        SUM(ledger.Amount) AS DisbsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
                              WHERE     ledger.TransactionType = 'OP'
                              AND DebtOrLedger='Ledger'
                                        AND ledger.PostedDate BETWEEN @StartDate
                                                              AND
                                                              @EndDate
                              GROUP BY  ledger.mt_int_code
                            ) AS DisbsIncurredcm ON matdb.mt_int_code = DisbsIncurredcm.ID
            LEFT OUTER JOIN ( SELECT    debt.mt_int_code AS ID ,
                                        SUM(debt.amount) AS CostsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                              WHERE     debt.TransactionType = 'COST'
                              AND DebtOrLedger='Debt'
                              AND PostedDate<@StartDate
                              GROUP BY  debt.mt_int_code
                            ) AS CostsIncurred ON matdb.mt_int_code = CostsIncurred.ID
              --LEFT OUTER JOIN ( SELECT    debt.mt_int_code AS ID ,
              --                          SUM(debt.amount) AS SolCost
              --                FROM      VFile_Streamlined.dbo.DebtLedger AS debt
              --                WHERE     debt.TransactionType = 'COST'
              --                AND DebtOrLedger='Debt'
              --                GROUP BY  debt.mt_int_code
              --              ) AS SolCostIncurred ON matdb.mt_int_code = SolCostIncurred.ID               
                            
            LEFT OUTER JOIN ( SELECT    debt.mt_int_code AS ID ,
                                        SUM(debt.amount) AS CostsIncurredcm
                              FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                              WHERE     debt.TransactionType = 'COST'
                              AND DebtOrLedger='Debt'
                                        AND PostedDate BETWEEN @StartDate AND @EndDate
                              GROUP BY  debt.mt_int_code
                            ) AS CostsIncurredcm ON matdb.mt_int_code = CostsIncurredcm.ID
            LEFT OUTER JOIN ( SELECT    SOLPYR.mt_int_code ,
                                        SUM(PYR_AmountDisbursementPaid)--+ (CASE WHEN NonRecDisbs.NonRecoverable='Y' THEN SUM(PYR_AmountNonRecoverableCostsPaid) ELSE 0 END) 
                                        AS DisPaid ,
                                        SUM(PYR_AmountRecoverableCostsPaid) AS SOLPaid
                              FROM      VFile_Streamlined.dbo.Payments AS SOLPYR
                              WHERE PYR_PaymentDate <@StartDate --ADDED KH (MAY NEED TAKEN OUT)
                              GROUP BY  SOLPYR.mt_int_code
                            ) AS DISPSOLPAID 
                            ON matdb.mt_int_code = DISPSOLPAID.mt_int_code
                            
            LEFT OUTER JOIN 
                             ( 
                                SELECT DISTINCT mt_int_code,'Y' AS NonRecoverable
								FROM VFile_Streamlined.dbo.DebtLedger
								WHERE DebtOrLedger='Ledger'
								AND ItemCode='ZLRO'
								AND PostedDate<@EndDate
								) AS NoRecDisbursements
								 ON matdb.mt_int_code=NoRecDisbursements.mt_int_code
			
			LEFT JOIN (    -- added by PA on OTRS request  Ref: 1023252               
          SELECT   Data.mt_int_code AS mtintCode,
                   Data.PYR_PaymentAmount AS Payment
                
          FROM (      
                 SELECT    mt_int_code ,
                           PYR_PaymentAmount ,
                           PYR_PaymentDate, 
                  ROW_NUMBER ( ) OVER (PARTITION BY mt_int_code  ORDER BY PYR_PaymentDate  DESC) RowId
                 
                    FROM   VFile_Streamlined.dbo.Payments AS Payments
                         WHERE PYR_PaymentType <> 'Historical Payment'
                          AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate 
                                   
                 ) AS Data 
                            
                  WHERE Data.RowId = 1     
                
                ) AS  LastPayment 
        ON    matdb.mt_int_code = LastPayment.mtintCode 					
								
			WHERE   SOLPYR.PYR_PaymentDate BETWEEN @StartDate AND @EndDate
            AND  SOLPYR.PYR_PaymentDeletedSameDay<> 'Yes'
            AND  SOLPYR.PYR_PaymentAmount<> 0
            AND  SOLPYR.PYR_PaymentType <> 'SAR'
            


GO
