SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE PROCEDURE [VisualFiles].[VoluntaryChargeAnalysis]
    (
      @StartDate AS DATETIME ,
      @EndDate AS DATETIME ,
      @ClientName AS VARCHAR(50)
    )
AS 
  
   
   IF @ClientName = 'All' 
    BEGIN
        SELECT  ClientName ,
                Dateofvoluntarychargeregistration ,
                Balance ,
                Name ,
                AccountNo ,
                ClientAccountNumber ,
                ReferedBalance ,
                Lastpaymentamount ,
                Lastpaymentdate, NumberofPaymentsInPeriod ,
                AmountPaidInPeriod
               
        FROM    ( SELECT    HIM_AccountNumber AS AccountNo ,
                            short_name AS Name ,
                            CurrentBalance AS Balance ,
                            CASE WHEN ADAScreen.AutoDate = '1900-01-01'
                                 THEN VCO_DateRestrictionRegistered
                                 ELSE ADAScreen.AutoDate
                            END AS Dateofvoluntarychargeregistration ,
                            ClientName AS ClientName ,
                            CDE_ClientAccountNumber AS ClientAccountNumber ,
                            OriginalBalance AS ReferedBalance ,
                            Amount AS Lastpaymentamount ,
                            _date AS Lastpaymentdate ,
                            NumberOfPayments AS NumberofPaymentsInPeriod ,
                            PaidInPeriod AS AmountPaidInPeriod
                  FROM      VFile_Streamlined.dbo.Charges AS Charges
                            INNER JOIN VFile_Streamlined.dbo.AccountInformation
                            AS AccountInfo ON Charges.mt_int_code = AccountInfo.mt_int_code
                            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON Charges.mt_int_code = SOLCDE.mt_int_code
                            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        COUNT(mt_int_code) AS NumberOfPayments ,
                                                        SUM(PYR_PaymentAmount) AS PaidInPeriod
                                              FROM      VFile_Streamlined.dbo.Payments
                                              WHERE     PYR_PaymentType <> 'Historical Payment'
                                                        AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                                              GROUP BY  mt_int_code
                                            ) AS PaidInPeriod ON Charges.mt_int_code = PaidInPeriod.mt_int_code
                            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        COUNT(mt_int_code) AS Number ,
                                                        SUM(SubTotal) AS Amount ,
                                                        [Payment Date12] AS _date
                                              FROM      ( SELECT
                                                              mt_int_code ,
                                                              SubTotal ,
                                                              [Payment Date12] ,
                                                              ROW_NUMBER() OVER ( PARTITION BY mt_int_code ORDER BY [Payment Date12] DESC ) AS OrderID
                                                          FROM
                                                              ( SELECT
                                                              SOLPYR.mt_int_code ,
                                                              SUM(PYR_PaymentAmount) AS SubTotal ,
                                                              PYR_PaymentDate AS [Payment Date12]
                                                              FROM
                                                              VFile_Streamlined.dbo.AccountInformation
                                                              AS AccountInfo
                                                              INNER JOIN VFile_Streamlined.dbo.Payments
                                                              AS SOLPYR ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
                                                              WHERE
                                                              PYR_PaymentType <> 'Historical Payment'
                                                              GROUP BY SOLPYR.mt_int_code ,
                                                              PYR_PaymentDate
                                                              ) subq1
                                                        ) subq2
                                              WHERE     OrderID = 1
                                              GROUP BY  [Payment Date12] ,
                                                        mt_int_code
                                            ) AS LastPayment ON Charges.mt_int_code = LastPayment.mt_int_code
                            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        CONVERT(DATE, VFile_Streamlined.dbo.VarcharToDate(ud_field##1), 103) AS AutoDate
                                              FROM      VFile_Streamlined.dbo.uddetail
                                                        AS ADA
                                              WHERE     uds_type = 'ADA'
                                            ) AS ADAScreen ON Charges.mt_int_code = ADAScreen.mt_int_code
                            LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens
                            AS Clients ON Charges.mt_int_code = Clients.mt_int_code
                ) AS AllVCO
        WHERE   Dateofvoluntarychargeregistration IS NOT NULL
    END
   ELSE 
    BEGIN
    
        SELECT  ClientName ,
                Dateofvoluntarychargeregistration ,
                Balance ,
                Name ,
                AccountNo ,
                ClientAccountNumber ,
                ReferedBalance ,
                Lastpaymentamount ,
                Lastpaymentdate, NumberofPaymentsInPeriod ,
                AmountPaidInPeriod
        FROM    ( SELECT    HIM_AccountNumber AS AccountNo ,
                            short_name AS Name ,
                            CurrentBalance AS Balance ,
                            CASE WHEN ADAScreen.AutoDate = '1900-01-01'
                                 THEN VCO_DateRestrictionRegistered
                                 ELSE ADAScreen.AutoDate
                            END AS Dateofvoluntarychargeregistration ,
                            ClientName AS ClientName ,
                            CDE_ClientAccountNumber AS ClientAccountNumber ,
                            OriginalBalance AS ReferedBalance ,
                            Amount AS Lastpaymentamount ,
                            _date AS Lastpaymentdate ,
                            NumberOfPayments AS NumberofPaymentsInPeriod ,
                            PaidInPeriod AS AmountPaidInPeriod
                  FROM      VFile_Streamlined.dbo.Charges AS Charges
                            INNER JOIN VFile_Streamlined.dbo.AccountInformation
                            AS AccountInfo ON Charges.mt_int_code = AccountInfo.mt_int_code
                                              AND ClientName = @ClientName
                            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON Charges.mt_int_code = SOLCDE.mt_int_code
                            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        COUNT(mt_int_code) AS NumberOfPayments ,
                                                        SUM(PYR_PaymentAmount) AS PaidInPeriod
                                              FROM      VFile_Streamlined.dbo.Payments
                                              WHERE     PYR_PaymentType <> 'Historical Payment'
                                                        AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                                              GROUP BY  mt_int_code
                                            ) AS PaidInPeriod ON Charges.mt_int_code = PaidInPeriod.mt_int_code
                            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        COUNT(mt_int_code) AS Number ,
                                                        SUM(SubTotal) AS Amount ,
                                                        [Payment Date12] AS _date
                                              FROM      ( SELECT
                                                              mt_int_code ,
                                                              SubTotal ,
                                                              [Payment Date12] ,
                                                              ROW_NUMBER() OVER ( PARTITION BY mt_int_code ORDER BY [Payment Date12] DESC ) AS OrderID
                                                          FROM
                                                              ( SELECT
                                                              SOLPYR.mt_int_code ,
                                                              SUM(PYR_PaymentAmount) AS SubTotal ,
                                                              PYR_PaymentDate AS [Payment Date12]
                                                              FROM
                                                              VFile_Streamlined.dbo.AccountInformation
                                                              AS AccountInfo
                                                              INNER JOIN VFile_Streamlined.dbo.Payments
                                                              AS SOLPYR ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
                                                              WHERE
                                                              PYR_PaymentType <> 'Historical Payment'
                                                              GROUP BY SOLPYR.mt_int_code ,
                                                              PYR_PaymentDate
                                                              ) subq1
                                                        ) subq2
                                              WHERE     OrderID = 1
                                              GROUP BY  [Payment Date12] ,
                                                        mt_int_code
                                            ) AS LastPayment ON Charges.mt_int_code = LastPayment.mt_int_code
                            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        CONVERT(DATE, VFile_Streamlined.dbo.VarcharToDate(ud_field##1), 103) AS AutoDate
                                              FROM      VFile_Streamlined.dbo.uddetail
                                                        AS ADA
                                              WHERE     uds_type = 'ADA'
                                            ) AS ADAScreen ON Charges.mt_int_code = ADAScreen.mt_int_code
                            LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens
                            AS Clients ON Charges.mt_int_code = Clients.mt_int_code
                ) AS AllVCO
        WHERE   Dateofvoluntarychargeregistration IS NOT NULL
                    
    END 
GO
