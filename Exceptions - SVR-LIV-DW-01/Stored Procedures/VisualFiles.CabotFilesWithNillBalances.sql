SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [VisualFiles].[CabotFilesWithNillBalances]

AS 
BEGIN
    SELECT  CDE02ClientAccountNo AS ClientAccountNo ,
            HIM_AccountNumber AS OriginalAccountNo ,
            ARR_agreementnumber AS ArrowKey,
            SubClient AS SubClient ,
            MatterCode AS MatterNumber ,
            CASE WHEN PIT_MatterOnHoldYesNo = 1 THEN 'Y'
                 ELSE 'N'
            END AS MatterOnHold ,
            CASE WHEN PIT_MatterOnHoldYesNo = 1 THEN PIT_ReasonAccountOnHold ELSE NULL END AS ReasonOnHold,
            Short_name AS Debtor ,
            PostCode AS PostalCode ,
            DateOpened AS AccountOpenDate ,
            OriginalBalance AS OriginalBalance ,
            CurrentBalance AS CurrentBalance,
            MilestoneCode AS Milestone ,
            CLO_ClosedDate AS ClosureDate ,
            CLO_ClosureReason AS ClosureReason ,
            CAS_BatchNumber AS BatchNo ,
            CASE WHEN CLO_ClosedDate IS NULL THEN 1
                 ELSE 0
            END AS Status ,
            CASE WHEN FileStatus = 'COMP' THEN 'Closed'
                 ELSE 'Active'
            END AS filestatus ,
            CASE WHEN AllPayments.Payments IS NULL
                      OR AllPayments.Payments = 0.00 THEN 'N'
                 ELSE 'Y'
            END AS Paying ,
            AllPayments.Payments AS [Total Payments Received1]
            ,Amount AS LastPaymentAmount -- added by peter A
            ,_date AS LastPaymentDate
            ,_Method AS PaymentMethod
            ,CASE WHEN CRD_DateJudgmentGranted = ''  THEN  NULL ELSE 
              CRD_DateJudgmentGranted END AS [Judgment Date]
            
    FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS ClientScreens ON AccountInfo.mt_int_code = ClientScreens.mt_int_code
            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                        PostCode
                              FROM      VFile_Streamlined.dbo.DebtorInformation
                                        AS Debtor
                              WHERE     ContactType = 'Primary Debtor'
                            ) AS Debtor ON AccountInfo.mt_int_code = Debtor.mt_int_code
            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                        SUM(PYR_PaymentAmount) AS Payments
                              FROM      VFile_Streamlined.dbo.Payments AS Payments
                              WHERE     PYR_PaymentType NOT IN (
                                        'Historical Payment', 'SAR',
                                        'CCA Request Fee' )
                              GROUP BY  mt_int_code
                            ) AS AllPayments ON AccountInfo.mt_int_code = AllPayments.mt_int_code
            LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                        CAST(ud_field##2 AS VARCHAR(50)) AS CDE02ClientAccountNo
                              FROM      VFile_Streamlined.dbo.uddetail
                              WHERE     uds_type = 'CDE'
                            ) AS CDE ON AccountInfo.mt_int_code = CDE.mt_int_code
            LEFT OUTER JOIN ( -- bit added by peter asemota
                            SELECT   mt_int_code
                            , COUNT(mt_int_code) AS Number
                            ,  SUM(SubTotal) AS Amount
                            ,  [Payment Date12] AS _date
                            ,  PaymentMethodUsed AS _Method
                        FROM
                              (
                           SELECT      mt_int_code
                                       ,SubTotal
                                       ,[Payment Date12]
                                       , PaymentMethodUsed
                                       , ROW_NUMBER() OVER(PARTITION BY mt_int_code ORDER BY [Payment Date12] DESC) AS OrderID
                         FROM  (
                                  SELECT      SOLPYR.mt_int_code
                                             ,SUM(PYR_PaymentAmount) AS SubTotal
                                             ,PYR_PaymentDate AS [Payment Date12]
                                             , [PYR_PaymentType] AS PaymentMethodUsed
                        FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                        INNER JOIN VFile_Streamlined.dbo.Payments AS SOLPYR
                         ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
                        WHERE PYR_PaymentType <> 'Historical Payment'
                        
                        GROUP BY SOLPYR.mt_int_code,PYR_PaymentDate,[PYR_PaymentType]                     
                        )     subq1
                            )     subq2
                       WHERE OrderID = 1 

              GROUP BY [Payment Date12],mt_int_code,PaymentMethodUsed
              --order by mt_int_code
              ) AS LastPayment
ON AccountInfo.mt_int_code = LastPayment.mt_int_code     
WHERE ClientName='Marlin'
AND SubClient IN(
'Cabot Financial (Europe) Limited'
,'Cabot Financial (Europe) Ltd'
,'Cabot Financial (UK) Limited'
)
AND CurrentBalance <0
END
GO
