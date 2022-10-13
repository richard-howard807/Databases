SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [VisualFiles].[MarlinPaymentArrangementChanges]
(
@StartDate AS DATE
,@EndDate AS DATE,
@ClientName AS VARCHAR(MAX)
)

AS 


 
SELECT  CDE_ClientAccountNumber AS MarlinRef ,
        HIM_AccountNumber AS AccountNumber ,
        Short_name AS [Name] ,
        CurrentBalance AS CurrentBalance ,
        SubClient AS [Sub Client],
        _date AS LastPaymentDate ,
        Amount AS Amount ,
        PaymentArrangementUpdate.HTRY_ExtraText AS ArrangementChange ,
        DateAdded AS Dateamended
FROM    VFile_Streamlined.dbo.AccountInformation AS A
        INNER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON A.mt_int_code = SOLCDE.mt_int_code
        INNER JOIN VFile_Streamlined.dbo.ClientScreens AS c ON A.mt_int_code = c.mt_int_code
        INNER JOIN ( SELECT History.mt_int_code ,
                            HTRY_DateInserted AS DateAdded ,
                            HTRY_ExtraText
                     FROM   VFile_Streamlined.dbo.History AS History
                            INNER JOIN VFile_Streamlined.dbo.AccountInformation
                            AS AccountInfo ON History.mt_int_code = AccountInfo.mt_int_code
                     WHERE  HTRY_description LIKE '%Arrangement Payment Alterations%'
                            AND ClientName =@ClientName
                            AND HTRY_DateInserted BETWEEN @StartDate AND @EndDate
                   ) AS PaymentArrangementUpdate ON A.mt_int_code = PaymentArrangementUpdate.mt_int_code
        LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                    COUNT(mt_int_code) AS Number ,
                                    SUM(SubTotal) AS Amount ,
                                    [Payment Date12] AS _date
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
                                                  AND PYR_PaymentDate <=@EndDate
                                                  GROUP BY  SOLPYR.mt_int_code ,
                                                            PYR_PaymentDate
                                                ) subq1
                                    ) subq2
                          WHERE     OrderID = 1
                          GROUP BY  [Payment Date12] ,
                                    mt_int_code
                        ) AS LastPayment ON a.mt_int_code = LastPayment.mt_int_code
WHERE   ClientName =@ClientName

GO
