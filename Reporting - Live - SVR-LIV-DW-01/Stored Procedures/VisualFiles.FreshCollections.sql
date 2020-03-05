SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [VisualFiles].[FreshCollections]
@ClientName AS VARCHAR(MAX)
   ,@StartDate DATE
  , @EndDate DATE
AS 
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT  ClientName AS ClientName
          , HIM_AccountNumber  AS  AccountNumber
          , RIGHT(AccountInfo.level_fee_earner, 3) + ' / ' + CAST(AccountInfo.MatterCode AS VARCHAR(30)) AS WeightmansRef
          , CASE WHEN [PYR_PaymentTakenByClient] = 'Yes'
                 THEN [PYR_PaymentAmount]
                 ELSE 0
            END AS PaidDirectToEOS
          , CASE WHEN [PYR_PaymentTakenByClient] = 'No'
                      OR [PYR_PaymentTakenByClient] = ''
                 THEN [PYR_PaymentAmount]
                 ELSE 0
            END AS CollectedByWeightmans
          , AccountInfo.OriginalBalance
          , AccountInfo.CurrentBalance
          , Payments.[PYR_PaymentAmount] AS AmountPaid
          , AccountInfo.MilestoneDescription AS Description
          , CASE WHEN Clients.EOS_DedicatedLegal = 'y' THEN 'yes'
                 ELSE 'no'
            END AS Expedited
          , Payments.PYR_PaymentDate AS date_
    FROM    VFile_streamlined.dbo.Payments AS Payments WITH ( NOLOCK )
    INNER JOIN VFile_streamlined.dbo.AccountInformation AS AccountInfo WITH ( NOLOCK )
            ON Payments.mt_int_code = AccountInfo.mt_int_code
    LEFT OUTER JOIN VFile_streamlined.dbo.SOLADM AS SOLADM
            ON Payments.mt_int_code = SOLADM.mt_int_code
    LEFT OUTER JOIN VFile_streamlined.dbo.ClientScreens AS Clients
            ON Payments.mt_int_code = Clients.mt_int_code
    
    
   
    WHERE   AccountInfo.ClientName =@ClientName
           AND Payments.PYR_PaymentDate BETWEEN @StartDate AND @EndDate
GO
