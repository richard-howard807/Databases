SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [CommercialRecoveries].[MIBChargingOrders]				
--	EXEC [CommercialRecoveries].[MIBChargingOrders] 'MIB'
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
			,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END  AS [ADA28]
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
	AND Accountinfo.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMattersSuccess)
      
UNION

    SELECT 
        
        txtClaimRef AS MIBRef
      ,   txtNameonDeb AS Defendant
      ,   [red_dw].[dbo].[datetimelocal](dteFinalOrder) AS Orderdate
      ,   curOriginalBal AS OriginalDebt
      ,   curCostAtHear AS ChargeValue
      ,   curCurrentBal AS BalanceOutstanding
      ,   txtPriorityChrg AS PriorityOfCharge
      ,   PaymentsMade.PaymentAmount AS PaymentsReceived
    ,COALESCE([red_dw].[dbo].[datetimelocal](dteChrgNotDebt),[red_dw].[dbo].[datetimelocal](dteFinalOrder)) AS DateChargeNotifiedToDebtor
    ,CASE WHEN fileClosed  IS NOT NULL THEN 'Closed' ELSE 'Open' END AS FileStatus
			,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END  AS [ADA28]
,txtClaNum2 AS ClaimNumber
,txtClaNum9 AS ClaimNumberOld
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRChangingOrders
 ON udCRChangingOrders.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRSOLADM
 ON udCRSOLADM.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRIssueDetails
 ON udCRIssueDetails.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curClient)  AS PaymentAmount  FROM [MS_PROD].dbo.udCRLedgerSL WHERE cboCatDesc='5'
GROUP BY fileID) AS PaymentsMade
 ON PaymentsMade.fileID = dbFile.fileID
WHERE clNo='M1001'
AND fileType='2038'
AND txtClaimRef <> ''
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dteFinalOrder),103) <> '1900-01-01'

       
       
       
     





GO
