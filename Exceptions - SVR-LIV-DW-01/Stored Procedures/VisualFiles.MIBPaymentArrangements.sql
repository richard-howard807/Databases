SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =========================================================
-- Author:Peter Asemota
-- Date: 2010/11/18
--
-- Description:MIB Trace report using Vfile_streamlined
-- =========================================================
CREATE PROCEDURE [VisualFiles].[MIBPaymentArrangements]
(
@ClientName AS VARCHAR(MAX)
)

      
AS 

    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 

 SELECT     
                      Clients.MIB_ClaimNumber AS ClaimNumber
                  ,   SOLADM.ADM_NameOfDebtorOnLetter AS Defendant
                  ,   AccountInfo.PaymentArrangementAmount AS Amount
                  ,   CASE WHEN AccountInfo.PaymentArrangementFrequency='f' THEN 'Fortnightly'
                  WHEN AccountInfo.PaymentArrangementFrequency='w' THEN 'Weekly' 
                  WHEN AccountInfo.PaymentArrangementFrequency='m' THEN 'Monthly'
                  WHEN AccountInfo.PaymentArrangementFrequency='y' THEN 'Yearly'
                  WHEN AccountInfo.PaymentArrangementFrequency='q' THEN 'Quarterly'
                  ELSE AccountInfo.PaymentArrangementFrequency END  AS Frequency
                  ,  AccountInfo.PaymentArrangementSetupDate AS DateofFirstPayment
                  ,LastPaymentDate
                      
              FROM
                [Vfile_streamlined].dbo.AccountInformation AS AccountInfo  WITH ( NOLOCK )
            INNER JOIN  Vfile_streamlined.dbo.ClientScreens AS Clients WITH ( NOLOCK )  
                ON   AccountInfo.mt_int_code  = Clients.mt_int_code
            INNER JOIN [VFile_streamlined].dbo.SOLADM AS SOLADM
                ON   AccountInfo.mt_int_code = SOLADM.mt_int_code
             LEFT OUTER JOIN 
             (
             SELECT mt_int_code AS mt_int_code,MAX(pyr_PaymentDate) AS LastPaymentDate
             FROM VFile_Streamlined.dbo.Payments
             GROUP BY mt_int_code
             )               AS lastpaydate
              ON AccountInfo.mt_int_code=lastpaydate.mt_int_code
              
               WHERE   Clients.MIB_ClaimNumber <> ''
      --  AND AccountInfo.PaymentArrangementStartDate between @StartDate and @EndDate
        AND  AccountInfo.PaymentArrangementAmount > 0
        AND MilestoneCode <> 'COMP'
        AND ClientName=@ClientName
        



GO
