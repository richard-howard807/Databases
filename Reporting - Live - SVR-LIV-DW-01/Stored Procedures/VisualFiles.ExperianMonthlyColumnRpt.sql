SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [VisualFiles].[ExperianMonthlyColumnRpt]
   ( 
    @StartDate DATE ,
    @EndDate DATE,
    @ClientName AS VARCHAR(100)
    )
AS 
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 
 DECLARE @VStartDate  AS DATE  -- added by pete
 DECLARE @VEndDate   AS DATE
 DECLARE @VClientName AS VARCHAR(100)

SET @VStartDate = @StartDate   
SET @VEndDate = @EndDate
SET @VClientName = @ClientName 
 --DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate = '2011-05-01'
--SET @EndDate = '2011-06-23'

    
    
    SELECT   DISTINCT
            RTRIM(HIM_AccountNumber) AS AccountNumber ,
            CDE_ClientAccountNumber AS MarlinSystemReference ,
            '05' AS AccountType ,
            HIM_AccountOpenDate AS AccountOpenDate ,
            DateOpened AccountClosedDate ,
            CurrentBalance.Balance AS CurrentBalance ,
            '8' AccountStatusCode ,
            monthlypayments.[AmountPaid] AS PaymentAmount ,
            'N' AS PromotionActivityFlag ,
            CASE WHEN CLO_ClosureReason IN ( 'Short Settled', 'IVA',
                                             'Bankrupt' ) THEN 'P'
                 WHEN CLO_ClosureReason = 'Deceased' THEN 'D'
                 WHEN HIM_AccountNumber IN ( '020014949758', '020019235112',
                                             '020020258707' ) THEN 'G'
                 WHEN AccountInfo.MilestoneCode = 'DEFE'
                      AND AccountInfo.FileStatus <> 'COMP' THEN 'Q'
                 ELSE SPACE(1)
            END AS FlagSettings ,
            RTRIM(AccountInfo.Short_name) AS DebtorName ,
            RTRIM(Address1) AS Address1 ,
            RTRIM(Address2) AS Address2 ,
            RTRIM(Address3) AS Address3 ,
            RTRIM(Address4) AS Address4 ,
            RTRIM(PostCode) AS PostCode ,
            DateOfBirth AS DebtorDOB ,
            CASE WHEN CLO_ClosureReason IN ( 'Paid in Full', 'Short Settled' )
                 THEN CLO_ClosedDate
                 ELSE NULL
            END AS DefaultSatisfactionDate ,
            OriginalBalance AS OriginalDefaultBalance
    FROM    ( SELECT    AccountInfo.mt_int_code
              FROM      VFile_Streamlined.dbo.AccountInformation AS AccountInfo
              WHERE     CLO_ClosedDate BETWEEN @StartDate AND @EndDate
                        AND CLO_ClosureReason IN ( 'Short Settled', 'IVA',
                                                   'Bankrupt', 'Deceased',
                                                   'Paid in Full' )
                        AND MatterCode NOT IN ( '10083', '11534' )
                        AND ClientName = @VClientName
              UNION
              SELECT    mstone_history.mt_int_code
              FROM      VFile_Streamlined.dbo.mstone_history AS mstone_history
                        INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo ON mstone_history.mt_int_code = AccountInfo.mt_int_code
              WHERE     mstone_history.MS_HTRY_DateAccountWentIntoMilestone BETWEEN @StartDate
                                                              AND
                                                              @EndDate
                        AND mstone_history.MS_HTRY_MstoneCode = 'DEFE'
                        AND AccountInfo.MatterCode NOT IN ( '10083', '11534' )
                        AND ClientName = @VClientName
              UNION
              SELECT    Payments.mt_int_code
              FROM      VFile_Streamlined.dbo.Payments AS Payments
                        INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo ON Payments.mt_int_code = AccountInfo.mt_int_code
              WHERE     PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                        AND MatterCode NOT IN ( '10083', '11534' )
                        AND ClientName = @VClientName
            ) AS Filter
            INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo ON Filter.mt_int_code = AccountInfo.mt_int_code
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON Filter.mt_int_code = Clients.mt_int_code
            INNER JOIN VFile_Streamlined.dbo.DebtorInformation AS Debtor ON Filter.mt_int_code = Debtor.mt_int_code
                                                              AND ContactType IN (
                                                              'Primary Debtor',
                                                              'Secondary Debtor' )
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON Filter.mt_int_code = SOLCDE.mt_int_code
            LEFT OUTER JOIN ( SELECT    AccountInfo.mt_int_code ,
                                        CASE WHEN CLO_ClosureReason IN (
                                                  'Paid in Full',
                                                  'Short Settled' )
                                                  OR CurrentBalance < 0 THEN 0
                                             ELSE CurrentBalance
                                        END AS Balance
                              FROM      VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo
                            ) AS CurrentBalance ON Filter.[mt_int_code] = CurrentBalance.[mt_int_code]
            LEFT OUTER JOIN ( SELECT    SOLPYR.[mt_int_code] ,
                                        CASE WHEN SUM(PYR_PaymentAmount) IS NULL
                                             THEN 0
                                             ELSE SUM(PYR_PaymentAmount)
                                        END AS AmountPaid
                              FROM      VFile_Streamlined.dbo.Payments AS SOLPYR
                                        INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                        AS AccountInfo ON SOLPYR.mt_int_code = AccountInfo.mt_int_code
                                                          AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
                              WHERE     ClientName = @VClientName
                              GROUP BY  SOLPYR.[mt_int_code]
                            ) AS monthlypayments ON Filter.[mt_int_code] = monthlypayments.mt_int_code
                        
   
   OPTION (OPTIMIZE FOR UNKNOWN)
   
GO
