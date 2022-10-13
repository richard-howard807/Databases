SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [VisualFiles].[HFCMonthlyCollection]
    @startdate DATETIME
,   @enddate DATETIME
,   @ClientName AS VARCHAR(50)
AS 
   IF @ClientName = 'HFC Closed Payments' 
    BEGIN
  
        SELECT  RIGHT(level_fee_earner, 3) + ' / '
                + CAST(MatterCode AS VARCHAR(30)) AS ourref ,
                HIM_AccountNumber AS yourref ,
                CASE WHEN (PYR_PaymentTakenByClient = 'Yes' AND ISNULL(PYR_PaymentType,'') <> 'Balance Adjustment') -- added by PA on #1363
                     THEN PYR_PaymentAmount
                     ELSE 0
                END AS recoveriespaidclient ,
                CASE WHEN PYR_PaymentTakenByClient = 'No'
                          OR PYR_PaymentTakenByClient = ''
                     THEN PYR_PaymentAmount
                     ELSE 0
                END AS recoveriespaidsolicitor ,
                CASE WHEN [recoverablecosts].[recoverablecosts] IS NULL THEN 0
                     ELSE [recoverablecosts].[recoverablecosts]
                END AS recoverablecosts ,
                CASE WHEN [recoverablefees].[recoverablefees] IS NULL THEN 0
                     ELSE [recoverablefees].[recoverablefees]
                END AS recoverablefees ,
                PYR_AmountDisbursementPaid AS fees ,
                PYR_AmountRecoverableCostsPaid AS costs ,
                PYR_TotalPaidToWeightmans AS commission ,
                PYR_AmountDisbursementPaid + PYR_AmountRecoverableCostsPaid
                + PYR_TotalPaidToWeightmans AS billamount ,
                PYR_TotalPaidToWeightmans * 0.20 AS vat ,
                PYR_PaymentAmount - ( PYR_AmountDisbursementPaid
                                      + PYR_AmountRecoverableCostsPaid
                                      + PYR_TotalPaidToWeightmans ) AS nettoclient ,
                PYR_PaymentDate ,
                HIM_AccountType ,
                CRD_DateClaimFormIssued ,
                CASE WHEN CRD_DateClaimFormIssued = '1900-01-01' THEN 'PRELIT'
                     WHEN DATEDIFF(DAY, PYR_PaymentDate,
                                   CRD_DateClaimFormIssued) <= 0
                     THEN 'POSTLIT'
                     ELSE 'PRELIT'
                END AS PREPOST ,
                'WEIGHTMAI' + dbo.FormatDateTime(PYR_PaymentDate, 'YYYYMMDD') AS AccountPayDate ,
                CLO_ClosedDate AS ClosureDate ,
                ClientName
        FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                INNER JOIN VFile_Streamlined.dbo.Payments AS Payments ON AccountInfo.mt_int_code = Payments.mt_int_code
                INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            SUM(Amount) AS recoverablefees
                                  FROM      VFile_Streamlined.dbo.DebtLedger
                                  WHERE     DebtOrLedger = 'Ledger'
                                            AND TransactionType = 'OP'
                                  GROUP BY  mt_int_code
                                ) AS recoverablefees ON AccountInfo.mt_int_code = recoverablefees.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            SUM(Amount) AS recoverablecosts
                                  FROM      VFile_Streamlined.dbo.DebtLedger
                                  WHERE     DebtOrLedger = 'Debt'
                                            AND TransactionType = 'COST'
                                  GROUP BY  mt_int_code
                                ) AS recoverablecosts ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
        WHERE   PYR_PaymentDeletedSameDay <> 'Yes'
                AND PYR_PaymentAmount <> 0
                AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                AND PDE_MilestonePaymentReceviedIn = 'COMP'
                AND ClientName LIKE 'HFC%' --@ClientName
    END
  ELSE 
    BEGIN
  
        SELECT  RIGHT(level_fee_earner, 3) + ' / '
                + CAST(MatterCode AS VARCHAR(30)) AS ourref ,
                HIM_AccountNumber AS yourref ,
                CASE WHEN (PYR_PaymentTakenByClient = 'Yes' AND ISNULL(PYR_PaymentType,'') <> 'Balance Adjustment')
                     THEN PYR_PaymentAmount
                     ELSE 0
                END AS recoveriespaidclient ,
                CASE WHEN PYR_PaymentTakenByClient = 'No'
                          OR PYR_PaymentTakenByClient = ''
                     THEN PYR_PaymentAmount
                     ELSE 0
                END AS recoveriespaidsolicitor ,
                CASE WHEN [recoverablecosts].[recoverablecosts] IS NULL THEN 0
                     ELSE [recoverablecosts].[recoverablecosts]
                END AS recoverablecosts ,
                CASE WHEN [recoverablefees].[recoverablefees] IS NULL THEN 0
                     ELSE [recoverablefees].[recoverablefees]
                END AS recoverablefees ,
                PYR_AmountDisbursementPaid AS fees ,
                PYR_AmountRecoverableCostsPaid AS costs ,
                PYR_TotalPaidToWeightmans AS commission ,
                PYR_AmountDisbursementPaid + PYR_AmountRecoverableCostsPaid
                + PYR_TotalPaidToWeightmans AS billamount ,
                PYR_TotalPaidToWeightmans * 0.15 AS vat ,
                PYR_PaymentAmount - ( PYR_AmountDisbursementPaid
                                      + PYR_AmountRecoverableCostsPaid
                                      + PYR_TotalPaidToWeightmans ) AS nettoclient ,
                PYR_PaymentDate ,
                HIM_AccountType ,
                CRD_DateClaimFormIssued ,
                CASE WHEN CRD_DateClaimFormIssued = '1900-01-01' THEN 'PRELIT'
                     WHEN DATEDIFF(DAY, PYR_PaymentDate,
                                   CRD_DateClaimFormIssued) <= 0
                     THEN 'POSTLIT'
                     ELSE 'PRELIT'
                END AS PREPOST ,
                'WEIGHTMAI' + dbo.FormatDateTime(PYR_PaymentDate, 'YYYYMMDD') AS AccountPayDate ,
                CLO_ClosedDate AS ClosureDate ,
                ClientName
        FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                INNER JOIN VFile_Streamlined.dbo.Payments AS Payments ON AccountInfo.mt_int_code = Payments.mt_int_code
                INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            SUM(Amount) AS recoverablefees
                                  FROM      VFile_Streamlined.dbo.DebtLedger
                                  WHERE     DebtOrLedger = 'Ledger'
                                            AND TransactionType = 'OP'
                                  GROUP BY  mt_int_code
                                ) AS recoverablefees ON AccountInfo.mt_int_code = recoverablefees.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            SUM(Amount) AS recoverablecosts
                                  FROM      VFile_Streamlined.dbo.DebtLedger
                                  WHERE     DebtOrLedger = 'Debt'
                                            AND TransactionType = 'COST'
                                  GROUP BY  mt_int_code
                                ) AS recoverablecosts ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
        WHERE   PYR_PaymentDeletedSameDay <> 'Yes'
                AND PYR_PaymentAmount <> 0
                AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                AND PDE_MilestonePaymentReceviedIn <> 'COMP'
                AND ClientName = @ClientName
                AND  PYR_PaymentType <> 'SAR'
    END 
GO
