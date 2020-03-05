SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [VisualFiles].[AllPayments] -- EXEC [VisualFiles].[AllPayments] '2014-03-26','2014-03-26','Neopost Limited','Neopost Limited'
    @StartDate DATE
  , @EndDate DATE
  , @Client VARCHAR(50)
  ,@SubClient VARCHAR(50)
AS 
    set nocount on
    set transaction isolation level read uncommitted
    


    IF @Client = 'All'  AND @SubClient='All'
        BEGIN
            
 
            SELECT  AccountInfo.mt_int_code
                  , MatterCode AS matter_code
                  , HIM_AccountNumber   AS accountno
                  ,CDE_ClientAccountNumber AS ClientAccountNumber
                  , Short_name AS debtor
                  ,DebtorName.FullName AS DebtorName
                  , DateOpened AS OpenDate
                  , PaymentArrangementAmount AS PaymentArrangementAmount
                  , PYR_PaymentAmount AS [Payment Amount2]
                  , PYR_PaymentAmount - PaymentArrangementAmount AS PaymentToArrangementDifference
                  , PYR_PaymentType AS [Payment Type3]
                  , PDE_PaymentMethod AS WorldPay
                  , PYR_ChequeNumber AS [Chequeno4]
                  , PYR_PaymentTakenByClient AS [Payment Taken By Client5]
                  , PYR_AmountPaidToClient AS [Amount Paid to Client6]
                  , PYR_AmountDisbursementPaid AS [Amount Disbursements Paid7]
                  , PYR_AmountRecoverableCostsPaid AS [Amount of Recoverable Cost Paid8]
                  , PYR_AmountPaidToWeightmansExcVAT AS [Amount paid to weightmans EXC VAT]
                  , PYR_VAT AS [VAT10]
                  , PYR_TotalPaidToWeightmans AS [Total Paid to Weightmans11]
                  , PYR_PaymentDate AS [Payment Date12]
                  , PYR_AmountNonRecoverableCostsPaid AS [Amount of non Recoverable Cost Paid13]
                  , CASE WHEN PYR_PaymentType = 'Direct Payment'
                              OR PYR_PaymentTakenByClient = 'Yes' THEN 'NOP'
                         ELSE 'Weightmans'
                    END AS ClientPayment
                  , [ClientName] AS Client
                  , CAS_BatchNumber AS BatchNo
                  , CDE_ClientAccountNumber AS CDE01
                  , Closures.[Reason] AS Reason
                  , CASE WHEN SubClient = 'Aktiv Kapital First Investment Limited' THEN 'FI'
                         WHEN SubClient = 'Aktiv Kapital Asset Investments Limited' THEN 'AI'
                         WHEN ClientName = 'Aktiv' THEN SubClient
                         WHEN ClientName IN ( 'Aktiv Kapital', 'Arrow' ) THEN ClientName
                         ELSE SubClient
                    END AS SubClient
                  , MilestoneCode AS Milestone
                  , PDE_WorldPayID AS WorldPayID
            FROM    VFile_Streamlined.dbo.Payments AS Payment
            LEFT OUTER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                    ON Payment.mt_int_code = AccountInfo.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS ClientScreens
                    ON Payment.mt_int_code = ClientScreens.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLADM AS SOLADM
                    ON Payment.mt_int_code = SOLADM.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
                    ON Payment.mt_int_code = SOLCDE.mt_int_code
            LEFT OUTER JOIN (
                              SELECT    AccountInfo.mt_int_code
                                      , CLO_ClosureReason AS Reason
                              FROM      VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo
                              WHERE     CLO_ClosureReason IN ( 'Paid In Full', 'Short Settled' )
                                        AND ClientName = 'Equidebt'
                            ) AS Closures
                    ON AccountInfo.mt_int_code = Closures.[mt_int_code]
            LEFT OUTER JOIN ( SELECT [mt_int_code]
                                     ,[Title] + ' ' + [Forename] +' '+ [Surname]  AS FullName 
                                  FROM [VFile_Streamlined].[dbo].[DebtorInformation]
                             WHERE [ContactType] = 'Primary Debtor'  
                             ) DebtorName
                             ON   AccountInfo.mt_int_code = DebtorName.[mt_int_code]       
                    
            WHERE   PYR_PaymentAmount <> 0
                    AND PYR_PaymentDeletedSameDay <> 'Yes'
                    AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                 
                                                
        END
       IF @Client = 'All'  AND @SubClient <>'All'
        BEGIN
            
 
            SELECT  AccountInfo.mt_int_code
                  , MatterCode AS matter_code
                  , HIM_AccountNumber   AS accountno
                  ,CDE_ClientAccountNumber AS ClientAccountNumber
                  , Short_name AS debtor
                  ,DebtorName.FullName AS DebtorName
                  , DateOpened AS OpenDate
                  , PaymentArrangementAmount AS PaymentArrangementAmount
                  , PYR_PaymentAmount AS [Payment Amount2]
                  , PYR_PaymentAmount - PaymentArrangementAmount AS PaymentToArrangementDifference
                  , PYR_PaymentType AS [Payment Type3]
                  , PDE_PaymentMethod AS WorldPay
                  , PYR_ChequeNumber AS [Chequeno4]
                  , PYR_PaymentTakenByClient AS [Payment Taken By Client5]
                  , PYR_AmountPaidToClient AS [Amount Paid to Client6]
                  , PYR_AmountDisbursementPaid AS [Amount Disbursements Paid7]
                  , PYR_AmountRecoverableCostsPaid AS [Amount of Recoverable Cost Paid8]
                  , PYR_AmountPaidToWeightmansExcVAT AS [Amount paid to weightmans EXC VAT]
                  , PYR_VAT AS [VAT10]
                  , PYR_TotalPaidToWeightmans AS [Total Paid to Weightmans11]
                  , PYR_PaymentDate AS [Payment Date12]
                  , PYR_AmountNonRecoverableCostsPaid AS [Amount of non Recoverable Cost Paid13]
                  , CASE WHEN PYR_PaymentType = 'Direct Payment'
                              OR PYR_PaymentTakenByClient = 'Yes' THEN 'NOP'
                         ELSE 'Weightmans'
                    END AS ClientPayment
                  , [ClientName] AS Client
                  , CAS_BatchNumber AS BatchNo
                  , CDE_ClientAccountNumber AS CDE01
                  , Closures.[Reason] AS Reason
                  , CASE WHEN SubClient = 'Aktiv Kapital First Investment Limited'
                         THEN 'FI'
                         WHEN SubClient = 'Aktiv Kapital Asset Investments Limited'
                         THEN 'AI'
                         WHEN ClientName = 'Aktiv' THEN SubClient
                         WHEN ClientName IN ( 'Aktiv Kapital', 'Arrow' )
                         THEN SubClient
                         ELSE SubClient
                    END AS SubClient
                  , MilestoneCode AS Milestone
                  , PDE_WorldPayID AS WorldPayID
            FROM    VFile_Streamlined.dbo.Payments AS Payment
            LEFT OUTER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                    ON Payment.mt_int_code = AccountInfo.mt_int_code
            LEFT OUTER  JOIN VFile_Streamlined.dbo.ClientScreens AS ClientScreens
                    ON Payment.mt_int_code = ClientScreens.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLADM AS SOLADM
                    ON Payment.mt_int_code = SOLADM.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
                    ON Payment.mt_int_code = SOLCDE.mt_int_code
            LEFT OUTER JOIN (
                              SELECT    AccountInfo.mt_int_code
                                      , CLO_ClosureReason AS Reason
                              FROM      VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo
                              WHERE     CLO_ClosureReason IN ( 'Paid In Full', 'Short Settled' )
                                        AND ClientName = 'Equidebt'
                            ) AS Closures
                    ON AccountInfo.mt_int_code = Closures.[mt_int_code]
            LEFT OUTER JOIN ( SELECT [mt_int_code]
                                     ,[Title] + ' ' + [Forename] +' '+ [Surname]  AS FullName 
                                  FROM [VFile_Streamlined].[dbo].[DebtorInformation]
                             WHERE [ContactType] = 'Primary Debtor'  
                             ) DebtorName
                             ON   AccountInfo.mt_int_code = DebtorName.[mt_int_code]         
            WHERE   PYR_PaymentAmount <> 0
                    AND PYR_PaymentDeletedSameDay <> 'Yes'
                    AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                    AND AccountInfo.SubClient=@SubClient
                                                
        END
    IF @Client <> 'All' AND  @SubClient ='All' 
        BEGIN

            
 
            SELECT  AccountInfo.mt_int_code
                  , MatterCode AS matter_code
                  , HIM_AccountNumber   AS accountno
                  ,CDE_ClientAccountNumber AS ClientAccountNumber
                  , Short_name AS debtor
                  ,DebtorName.FullName AS DebtorName
                  , DateOpened AS OpenDate
                  , PaymentArrangementAmount AS PaymentArrangementAmount
                  , PYR_PaymentAmount AS [Payment Amount2]
                  , PYR_PaymentAmount - PaymentArrangementAmount AS PaymentToArrangementDifference
                  , PYR_PaymentType AS [Payment Type3]
                  , PDE_PaymentMethod AS WorldPay
                  , PYR_ChequeNumber AS [Chequeno4]
                  , PYR_PaymentTakenByClient AS [Payment Taken By Client5]
                  , PYR_AmountPaidToClient AS [Amount Paid to Client6]
                  , PYR_AmountDisbursementPaid AS [Amount Disbursements Paid7]
                  , PYR_AmountRecoverableCostsPaid AS [Amount of Recoverable Cost Paid8]
                  , PYR_AmountPaidToWeightmansExcVAT AS [Amount paid to weightmans EXC VAT]
                  , PYR_VAT AS [VAT10]
                  , PYR_TotalPaidToWeightmans AS [Total Paid to Weightmans11]
                  , PYR_PaymentDate AS [Payment Date12]
                  , PYR_AmountNonRecoverableCostsPaid AS [Amount of non Recoverable Cost Paid13]
                  , CASE WHEN PYR_PaymentType = 'Direct Payment'
                              OR PYR_PaymentTakenByClient = 'Yes' THEN 'NOP'
                         ELSE 'Weightmans'
                    END AS ClientPayment
                  , [ClientName] AS Client
                  , CAS_BatchNumber AS BatchNo
                  , CDE_ClientAccountNumber AS CDE01
                  , Closures.[Reason] AS Reason
                  , CASE WHEN SubClient = 'Aktiv Kapital First Investment Limited'
                         THEN 'FI'
                         WHEN SubClient = 'Aktiv Kapital Asset Investments Limited'
                         THEN 'AI'
                         WHEN ClientName = 'Aktiv' THEN SubClient
                         WHEN ClientName IN ( 'Aktiv Kapital', 'Arrow' )
                         THEN SubClient
                         ELSE SubClient
                    END AS SubClient
                  , MilestoneCode AS Milestone
                  , PDE_WorldPayID AS WorldPayID
            FROM    VFile_Streamlined.dbo.Payments AS Payment
            LEFT OUTER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                    ON Payment.mt_int_code = AccountInfo.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS ClientScreens
                    ON Payment.mt_int_code = ClientScreens.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLADM AS SOLADM
                    ON Payment.mt_int_code = SOLADM.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
                    ON Payment.mt_int_code = SOLCDE.mt_int_code
            LEFT OUTER JOIN (
                              SELECT    AccountInfo.mt_int_code
                                      , CLO_ClosureReason AS Reason
                              FROM      VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo
                              WHERE     CLO_ClosureReason IN ( 'Paid In Full', 'Short Settled' )
                                        AND ClientName = 'Equidebt'
                            ) AS Closures
                    ON AccountInfo.mt_int_code = Closures.[mt_int_code]
                    
            LEFT OUTER JOIN ( SELECT [mt_int_code]
                                     ,[Title] + ' ' + [Forename] +' '+ [Surname]  AS FullName 
                                  FROM [VFile_Streamlined].[dbo].[DebtorInformation]
                             WHERE [ContactType] = 'Primary Debtor'  
                             ) DebtorName
                             ON   AccountInfo.mt_int_code = DebtorName.[mt_int_code]  
            WHERE   PYR_PaymentAmount <> 0
                    AND PYR_PaymentDeletedSameDay <> 'Yes'
                    AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                    AND AccountInfo.ClientName = @Client

        END
ELSE
 BEGIN

            
 
            SELECT  AccountInfo.mt_int_code
                  , MatterCode AS matter_code
                  , HIM_AccountNumber   AS accountno
                  ,CDE_ClientAccountNumber AS ClientAccountNumber
                  , Short_name AS debtor
                  ,DebtorName.FullName AS DebtorName
                  , DateOpened AS OpenDate
                  , PaymentArrangementAmount AS PaymentArrangementAmount
                  , PYR_PaymentAmount AS [Payment Amount2]
                  , PYR_PaymentAmount - PaymentArrangementAmount AS PaymentToArrangementDifference
                  , PYR_PaymentType AS [Payment Type3]
                  , PDE_PaymentMethod AS WorldPay
                  , PYR_ChequeNumber AS [Chequeno4]
                  , PYR_PaymentTakenByClient AS [Payment Taken By Client5]
                  , PYR_AmountPaidToClient AS [Amount Paid to Client6]
                  , PYR_AmountDisbursementPaid AS [Amount Disbursements Paid7]
                  , PYR_AmountRecoverableCostsPaid AS [Amount of Recoverable Cost Paid8]
                  , PYR_AmountPaidToWeightmansExcVAT AS [Amount paid to weightmans EXC VAT]
                  , PYR_VAT AS [VAT10]
                  , PYR_TotalPaidToWeightmans AS [Total Paid to Weightmans11]
                  , PYR_PaymentDate AS [Payment Date12]
                  , PYR_AmountNonRecoverableCostsPaid AS [Amount of non Recoverable Cost Paid13]
                  , CASE WHEN PYR_PaymentType = 'Direct Payment'
                              OR PYR_PaymentTakenByClient = 'Yes' THEN 'NOP'
                         ELSE 'Weightmans'
                    END AS ClientPayment
                  , [ClientName] AS Client
                  , CAS_BatchNumber AS BatchNo
                  , CDE_ClientAccountNumber AS CDE01
                  , Closures.[Reason] AS Reason
                  , CASE WHEN SubClient = 'Aktiv Kapital First Investment Limited'
                         THEN 'FI'
                         WHEN SubClient = 'Aktiv Kapital Asset Investments Limited'
                         THEN 'AI'
                         WHEN ClientName = 'Aktiv' THEN SubClient
                         WHEN ClientName IN ( 'Aktiv Kapital', 'Arrow' )
                         THEN SubClient
                         ELSE SubClient
                    END AS SubClient
                  , MilestoneCode AS Milestone
                  , PDE_WorldPayID AS WorldPayID
            FROM    VFile_Streamlined.dbo.Payments AS Payment
            LEFT OUTER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                    ON Payment.mt_int_code = AccountInfo.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS ClientScreens
                    ON Payment.mt_int_code = ClientScreens.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLADM AS SOLADM
                    ON Payment.mt_int_code = SOLADM.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
                    ON Payment.mt_int_code = SOLCDE.mt_int_code
            LEFT OUTER JOIN (
                              SELECT    AccountInfo.mt_int_code
                                      , CLO_ClosureReason AS Reason
                              FROM      VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo
                              WHERE     CLO_ClosureReason IN ( 'Paid In Full', 'Short Settled' )
                                        AND ClientName = 'Equidebt'
                            ) AS Closures
                    ON AccountInfo.mt_int_code = Closures.[mt_int_code]
                    
             LEFT OUTER JOIN ( SELECT [mt_int_code]
                                     ,[Title] + ' ' + [Forename] +' '+ [Surname]  AS FullName 
                                  FROM [VFile_Streamlined].[dbo].[DebtorInformation]
                             WHERE [ContactType] = 'Primary Debtor'  
                             ) DebtorName
                             ON   AccountInfo.mt_int_code = DebtorName.[mt_int_code]        
            WHERE   PYR_PaymentAmount <> 0
                    AND PYR_PaymentDeletedSameDay <> 'Yes'
                    AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                    AND AccountInfo.ClientName = @Client
                    AND AccountInfo.SubClient = @SubClient
           
        END






GO
