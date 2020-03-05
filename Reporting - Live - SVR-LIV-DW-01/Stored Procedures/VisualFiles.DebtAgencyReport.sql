SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [VisualFiles].[DebtAgencyReport]
AS 
    BEGIN
        SELECT  Short_name DebtorName ,
                HIM_AccountNumber AS AccountNumber ,
                arr_agreementnumber AS ArrowKey,
                CDE_ClientAccountNumber AS ClientAccountNumber,
                CurrentBalance AS CurrentBalance ,
                ClientName AS Client ,
                MilestoneCode AS Milestone ,
                PaymentArrangementAmount AS MonthlyPaymentAmount ,
                PaymentMethod AS PaymentMethod ,
                Surname AS DebtAgency,
                LastPaymentDate AS [LastPaymentDate],
                LastPayment.Amount AS [LastPaymentAmount]
        FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                INNER JOIN ( SELECT DISTINCT
                                    mt_int_code ,
                                    Surname
                             FROM   VFile_Streamlined.dbo.DebtorInformation
                             WHERE  ContactType = 'Debt Agency'
                           ) AS DebtAgency ON AccountInfo.mt_int_code = DebtAgency.mt_int_code
                INNER JOIN VFile_Streamlined.dbo.ClientScreens AS C ON AccountInfo.mt_int_code = C.mt_int_code
                LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
                 ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                            PYR_PaymentType AS PaymentMethod
                                  FROM      ( SELECT    mt_int_code ,
                                                        PYR_PaymentType ,
                                                        Number ,
                                                        ROW_NUMBER() OVER ( PARTITION BY mt_int_code ORDER BY Number DESC ) AS OrderID
                                              FROM      ( SELECT
                                                              mt_int_code ,
                                                              PYR_PaymentType ,
                                                              COUNT(PYR_PaymentType) AS Number
                                                          FROM
                                                              VFile_Streamlined.dbo.Payments
                                                          WHERE
                                                              PYR_PaymentType NOT IN (
                                                              '',
                                                              'Historical Payment',
                                                              'Payment Deletion - Entered in Error',
                                                              'Payment Deletion - Bounced Payment',
                                                              'Balance Adjustment',
                                                              'TT' )
                                                          GROUP BY mt_int_code ,
                                                              PYR_PaymentType
                                                        ) AS AllPaymentTypes
                                            ) AS Filtered
                                  WHERE     OrderID = 1
                                ) AS PaymentMethod ON AccountInfo.mt_int_code = PaymentMethod.mt_int_code 
                                LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                        COUNT(mt_int_code) AS Number ,
                                                        SUM(SubTotal) AS Amount ,
                                                        [Payment Date12] AS LastPaymentDate
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
                                                              PYR_PaymentType NOT IN ('Historical Payment','CCA Request Fee')
                                                              GROUP BY SOLPYR.mt_int_code ,
                                                              PYR_PaymentDate
                                                              ) subq1
                                                        ) subq2
                                              WHERE     OrderID = 1
                                              GROUP BY  [Payment Date12] ,
                                                        mt_int_code
                                            ) AS LastPayment ON   AccountInfo.mt_int_code= LastPayment.mt_int_code





    END
GO
