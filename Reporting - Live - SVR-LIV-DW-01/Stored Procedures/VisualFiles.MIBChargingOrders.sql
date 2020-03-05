SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =========================================================
-- Exec [DebtRecovery].[MIBChargingOrders_Vfile_streamlined] 
-- Peter Asemota 
-- =========================================================
CREATE PROCEDURE [VisualFiles].[MIBChargingOrders]				--	EXEC [VisualFiles].[MIBChargingOrders] 'MIB'
(
@ClientName AS VARCHAR(MAX)
)
    
AS

    SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT 
        
        Clients.MIB_ClaimNumber AS MIBRef
    ,   SOLADM.ADM_NameOfDebtorOnLetter AS Defendant
    ,   charges.CHO_Finalorderdated AS Orderdate
    ,   Accountinfo.OriginalBalance AS OriginalDebt
    ,   charges.CHO_Costsawardedathearing AS ChargeValue
    ,   Accountinfo.CurrentBalance AS BalanceOutstanding
    ,   Charges.CHO_PriorityOfCharge AS PriorityOfCharge
    ,   PaymentsMade.PaymentAmount AS PaymentsReceived
    ,CASE WHEN cho_DateChargeNotifiedToDebtor='1900-01-01' THEN CHO_Finalorderdated ELSE cho_DateChargeNotifiedToDebtor END   AS DateChargeNotifiedToDebtor
    ,CASE WHEN FileStatus='COMP' THEN 'Closed' ELSE 'Open' END AS FileStatus
			,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END  AS [ADA28]
,ClaimNumber
,ClaimNumberOld
 
   
    FROM
         [VFile_Streamlined].dbo.AccountInformation AS Accountinfo
    INNER JOIN [VFile_Streamlined].dbo.ClientScreens AS Clients  
    ON Accountinfo.mt_int_code = Clients.mt_int_code
    INNER JOIN [VFile_Streamlined].dbo.Charges AS Charges
    ON Accountinfo.mt_int_code = Charges.mt_int_code
    INNER JOIN [VFile_streamlined].dbo.SOLADM AS SOLADM
    ON   AccountInfo.mt_int_code = SOLADM.mt_int_code
    LEFT OUTER JOIN (
                        SELECT   mt_int_code 
                                ,SUM([PYR_PaymentAmount]) AS PaymentAmount
                  FROM [VFile_Streamlined].dbo.Payments
                  GROUP BY mt_int_code
                  ) AS PaymentsMade
      ON Accountinfo.mt_int_code = PaymentsMade.mt_int_code           

	LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON Accountinfo.mt_int_code=ADA.mt_int_code
		LEFT OUTER JOIN (SELECT mt_int_code,ud_field##20 ClaimNumber,ud_field##9 AS ClaimNumberOld
FROM VFile_Streamlined.dbo.uddetail AS Issue
WHERE uds_type='CCT') AS CCT
 ON Accountinfo.mt_int_code=CCT.mt_int_code

    WHERE
        Clients.[MIB_ClaimNumber] <> ''
        AND charges.CHO_Finalorderdated <> '1900-01-01'
    AND ClientName=@ClientName
      
       ORDER BY Clients.MIB_ClaimNumber 


       
       
       
     





GO
