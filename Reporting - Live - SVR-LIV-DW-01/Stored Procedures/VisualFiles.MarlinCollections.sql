SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









--EXEC [VisualFiles].[MarlinCollections]'2013/01/01','2013/10/01','Marlin'


CREATE PROCEDURE [VisualFiles].[MarlinCollections]
(
@StartDate AS DATE
,@EndDate AS DATE
,@ClientName AS VARCHAR(50)

)
AS 

    set nocount on
    set transaction isolation level read uncommitted

   SELECT  CDE_ClientAccountNumber AS MarlinSystemReference ,
            HIM_AccountNumber AS Account ,
            a.SellerName AS OriginalCreditorName,
            Short_name AS DebtorName,
            a.DateOpened AS Dateopened,
            SubClient AS [Sub Client],
           CASE WHEN PYR_PaymentTakenByClient='Yes' THEN PYR_PaymentAmount ELSE 0.00 END AS NotifiedByClient
           ,CASE WHEN PYR_PaymentTakenByClient='No' THEN PYR_PaymentAmount ELSE 0.00 END AS PaymentToWeightmans
          -- ,CASE WHEN a.SellerName='' OR a.SellerName IS NULL THEN (convert(DECIMAL(20,2),ROUND((PYR_PaymentAmount/100)*16.5,2))) ELSE (convert(DECIMAL(20,2),ROUND((PYR_PaymentAmount/100)*15.0,2)))  END AS Commission
           ,CASE WHEN a.SellerName='' OR a.SellerName IS NULL THEN (CONVERT(DECIMAL(20,4),ROUND((PYR_PaymentAmount/100)*16.5,4))) ELSE (CONVERT(DECIMAL(20,4),ROUND((PYR_PaymentAmount/100)*15.0,4)))  END AS Commission   -- changed by PA on Alison request
           ,CONVERT(DECIMAL(20,2),ROUND(PYR_PaymentAmount,2) - (CASE WHEN a.SellerName='' OR a.SellerName IS NULL THEN (CONVERT(DECIMAL(20,2),ROUND((PYR_PaymentAmount/100)*16.5,2))) ELSE (CONVERT(DECIMAL(20,2),ROUND((PYR_PaymentAmount/100)*15.0,2)))  END)) AS PaymentToClient     
           ,PYR_PaymentAmount AS paymenttest
           --,PYR_TotalPaidToWeightmans AS Commission
           --,PYR_AmountPaidToClient AS PaymentToClient	
           ,PYR_PaymentDate AS DateOfPayment	
           ,CurrentBalance AS CurrentBalance
           ,PYR_PaymentType AS PaymentMethod
           ,PYR_PaymentArrangementType AS PaymentArrangementType
           ,CASE WHEN a.SellerName='' OR a.SellerName IS NULL THEN 0.165 ELSE 0.15 END AS ComRate
           ,Title,Surname,Forename
       
      
            
            
            ,
            CASE WHEN ( CASE WHEN DisbsIncurred.DisbsIncurred IS NULL THEN 0
                             ELSE DisbsIncurred.DisbsIncurred
                        END - CASE WHEN PaidDetails.DisbsPaid IS NULL THEN 0
                                   ELSE PaidDetails.DisbsPaid
                              END ) < 0 THEN 0
                 ELSE ( CASE WHEN DisbsIncurred.DisbsIncurred IS NULL THEN 0
                             ELSE DisbsIncurred.DisbsIncurred
                        END - CASE WHEN PaidDetails.DisbsPaid IS NULL THEN 0
                                   ELSE PaidDetails.DisbsPaid
                              END )
            END AS DisbsUnpaid ,
            CASE WHEN ( CASE WHEN CostsIncurred.CostsIncurred IS NULL THEN 0
                             ELSE CostsIncurred.CostsIncurred
                        END - CASE WHEN PaidDetails.CostsPaid IS NULL THEN 0
                                   ELSE PaidDetails.CostsPaid
                              END ) < 0 THEN 0
                 ELSE ( CASE WHEN CostsIncurred.CostsIncurred IS NULL THEN 0
                             ELSE CostsIncurred.CostsIncurred
                        END - CASE WHEN PaidDetails.CostsPaid IS NULL THEN 0
                                   ELSE PaidDetails.CostsPaid
                              END )
            END AS SolicitorsFixedCostsUnpaid
            ,CASE WHEN DisbsIncurred IS NULL THEN 0 ELSE DisbsIncurred END  AS DisbursementsIncurred
            ,CASE WHEN CostsIncurred IS NULL THEN 0 ELSE CostsIncurred END  AS CostsIncurred
    FROM    VFile_Streamlined.dbo.AccountInformation AS a
    INNER JOIN VFile_Streamlined.dbo.Payments AS p
   
     ON a.mt_int_code = p.mt_int_code AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
            LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS c ON a.mt_int_code = c.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON a.mt_int_code = SOLCDE.mt_int_code
            LEFT OUTER JOIN ( SELECT    ledger.mt_int_code ,
                                        SUM(Ledger.Amount) AS DisbsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
                              WHERE     ledger.TransactionType = 'OP'
                                        AND DebtOrLedger = 'Ledger'
                              GROUP BY  Ledger.mt_int_code
                            ) AS DisbsIncurred ON a.mt_int_code = DisbsIncurred.mt_int_code
-- Costs Incurred
            LEFT OUTER JOIN ( SELECT    Debt.mt_int_code ,
                                        SUM(Debt.amount) AS CostsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS Debt
                              WHERE     Debt.TransactionType = 'COST'
                                        AND DebtOrLedger = 'Debt'
                              GROUP BY  Debt.mt_int_code
                            ) AS CostsIncurred ON a.mt_int_code = CostsIncurred.mt_int_code
            LEFT OUTER JOIN ( SELECT    Payments_.mt_int_code ,
                                        SUM(Payments_.[PYR_AmountDisbursementPaid]) AS DisbsPaid ,
                                        SUM(Payments_.[PYR_AmountRecoverableCostsPaid]) AS CostsPaid
                              FROM      VFile_Streamlined.dbo.Payments AS Payments_
                              GROUP BY  Payments_.mt_int_code
                            ) AS PaidDetails ON a.mt_int_code = PaidDetails.mt_int_code
			LEFT OUTER JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType='Primary Debtor') AS Debtor
			 ON a.mt_int_code=Debtor.mt_int_code
    
    
             WHERE   ClientName = @ClientName
            AND p.PYR_PaymentDate BETWEEN @StartDate AND @EndDate
            AND CDE_ClientAccountNumber <> ''
            AND ISNULL(PDE_MilestonePaymentReceviedIn,'') <>'COMP' -- addded from ticket 79927
            ORDER BY HIM_AccountNumber,p.PYR_PaymentDate








GO
