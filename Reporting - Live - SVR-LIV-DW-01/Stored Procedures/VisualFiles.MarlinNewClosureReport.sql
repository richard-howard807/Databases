SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- EXEC [VisualFiles].[MarlinNewClosureReport]'2012/09/01','2012/09/27'

CREATE PROCEDURE [VisualFiles].[MarlinNewClosureReport]
(
@StartDate AS DATE
,@EndDate AS DATE
,@ClientName AS VARCHAR(MAX)
)
AS
BEGIN 

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate = '2012-09-01'
--SET @EndDate = GETDATE()



DECLARE @VStartDate AS DATETIME
DECLARE @VEndDate AS DATETIME


SET @VStartDate = @StartDate
SET @VEndDate = @EndDate


SELECT  DISTINCT
        HIM_AccountNumber AS SupplierRef ,
        CDE_ClientAccountNumber AS ClientRef ,
        HIM_AccountNumber AS OriginalCreditorRef ,
        Title AS DebtorTitle ,
        Forename AS DebtorForename ,
        Surname AS DebtorSurname ,
        CLO_ClosedDate AS DateClosed ,
        AccountInfo.SubClient,
         
        CASE 
        WHEN CLO_ClosureReason='Bankruptcy Order or DRO' THEN 'Bankrupt'
		WHEN CLO_ClosureReason='Cabot Recalling Account' THEN 'Client Instructs Closure'
		WHEN CLO_ClosureReason='Deceased' THEN 'Deceased'
		WHEN CLO_ClosureReason='IVA or PTD' THEN 'IVA'
		WHEN CLO_ClosureReason='Serious Health Problems' THEN 'Lack of Ability'
		WHEN CLO_ClosureReason='Unable/Refusal to Pay' THEN 'Lack of Ability'
		WHEN CLO_ClosureReason='Prison' THEN 'Lack of Ability'
		WHEN CLO_ClosureReason='Offer Declined' THEN 'Lack of Ability'
		WHEN CLO_ClosureReason='Paid In Full' THEN 'Paid In full'
		WHEN CLO_ClosureReason='Short Settled (Lump Sum)' THEN 'Short Settled'
		WHEN CLO_ClosureReason='Short Settled (Instalment)' THEN 'Short Settled'
		WHEN CLO_ClosureReason='Unable to Contact' THEN 'Unable to Contact'
		WHEN CLO_ClosureReason='Unable to Trace' THEN 'Unable to Contact'
		WHEN CLO_ClosureReason='Address Confirmed but Unable to Contact' THEN 'Unable to Contact'
		WHEN CLO_ClosureReason='Gone Away' THEN 'No Longer at Address'  
		WHEN CLO_ClosureReason='CCA Request' THEN 'CCA Request'
		WHEN CLO_ClosureReason='Complaint' THEN 'Complaint'
		WHEN CLO_ClosureReason='Agency Dealing' THEN 'Agency Dealing'
		WHEN CLO_ClosureReason='Unresolved Dispute' THEN 'Unresolved Dispute'
		WHEN CLO_ClosureReason='Litigation Recommended' THEN 'Litigation Recommended'
		WHEN CLO_ClosureReason='Retention' THEN 'Retention'
		WHEN CLO_ClosureReason='Statute Barred' THEN 'Statute Barred'
																ELSE CLO_ClosureReason END AS ClosureReason ,
		
        CASE WHEN CLO_ClosureCode IN ('AGBNK','ALERR','AGDEA','AGIVA','AGMEH'
	    ,'AGRPC','AGPRI','AGCOD','AGFST','AGPST','AGPND') THEN '' 
		WHEN CLO_ClosureCode='AGNEG' THEN 'CLONOCON'
		WHEN CLO_ClosureCode='AGNOL' THEN 'CLONOCON'
		WHEN CLO_ClosureCode='AGLAS' THEN 'CLONOCON'
		WHEN CLO_ClosureCode='AGGAW' THEN 'CLOSKIP'
		WHEN CLO_ClosureCode='AGCCA' THEN 'AGCCA'
		WHEN CLO_ClosureCode='AGCOM' THEN 'AGCOM'
		WHEN CLO_ClosureCode='AGDCO' THEN 'AGDCO'
		WHEN CLO_ClosureCode='AGDIS' THEN 'AGDIS'
		WHEN CLO_ClosureCode='AGPLT' THEN 'AGPLT'
		WHEN CLO_ClosureCode='AGRET' THEN 'AGRET'
		WHEN CLO_ClosureCode='AGSTB' THEN 'AGSTB' ELSE CLO_ClosureCode END AS ClosureCode ,
		
        CLO_ClosureNotes AS ClosingNotes ,
        OriginalBalance AS OriginalBalance ,
        TotalPaid AS PaidToDate ,
        Payment_VF.payment AS PaymentTD,
        ISNULL(TotalDisbursements, 0) + ISNULL(TotalNonRecoverableCosts, 0) AS FeesToDate ,
        RecoverableCostsPaid AS CostsToDate ,
        AdjustmentsToDate AS AdjustmentsToDate ,
        CurrentBalance AS ClosingBalance,
        DisbsIncurred.DisbsIncurred AS [DisbIncurredToDate],
        CostsIncurred.CostsIncurred AS [CostIncurredTodate]
                
        
FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
        LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON AccountInfo.mt_int_code = SOLCDE.mt_int_code
        LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS c ON AccountInfo.mt_int_code = c.mt_int_code
        LEFT OUTER JOIN ( SELECT    Debtor.mt_int_code ,
                                    Title ,
                                    Forename ,
                                    Surname ,
                                    DateOpened
                          FROM      VFile_Streamlined.dbo.DebtorInformation AS Debtor
                                    INNER JOIN VFile_Streamlined.dbo.AccountInformation
                                    AS AccountInfo ON Debtor.mt_int_code = AccountInfo.mt_int_code
                          WHERE     ContactType = 'Primary Debtor'
                                    AND ClientName LIKE '%Marlin%'
                        ) AS Debtor ON AccountInfo.mt_int_code = Debtor.mt_int_code
        LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
                                    SUM(PYR_PaymentAmount) AS TotalPaid ,
                                    SUM(PYR_AmountDisbursementPaid) AS TotalDisbursements ,
                                    SUM(PYR_AmountNonRecoverableCostsPaid) AS TotalNonRecoverableCosts ,
                                    SUM(PYR_AmountRecoverableCostsPaid) AS RecoverableCostsPaid
                          FROM      VFile_Streamlined.dbo.Payments AS Payments
                          GROUP BY  mt_int_code
                        ) AS Payments ON AccountInfo.mt_int_code = Payments.mt_int_code
        LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
                                    SUM(PYR_PaymentAmount) AS AdjustmentsToDate
                          FROM      VFile_Streamlined.dbo.Payments AS Payments
                          WHERE     PYR_PaymentAmount < 0
                          GROUP BY  mt_int_code
                        ) AS Adjustments ON AccountInfo.mt_int_code = Adjustments.mt_int_code

        LEFT OUTER JOIN ( SELECT    ledger.mt_int_code AS ID ,
                                        SUM(ledger.Amount) AS DisbsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
                              WHERE     ledger.TransactionType = 'OP'
                              AND DebtOrLedger='Ledger'      
                              GROUP BY  ledger.mt_int_code
                            ) AS DisbsIncurred ON AccountInfo.mt_int_code = DisbsIncurred.ID
         LEFT OUTER JOIN 
            
            ( SELECT    debt.mt_int_code AS ID ,
                                        SUM(debt.amount) AS CostsIncurred
                              FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                              WHERE     debt.TransactionType = 'COST'
                              AND DebtOrLedger='Debt'                     
                              GROUP BY  debt.mt_int_code
                            ) AS CostsIncurred ON AccountInfo.mt_int_code = CostsIncurred.ID 
         LEFT OUTER JOIN  (SELECT    mt_int_code ,
							  SUM(amount) AS payment
							 FROM  VFileReplicated.dbo.payment   AS Payments
						   ----   WHERE mt_int_code ='3044' 
							  GROUP BY mt_int_code  
							  ) AS Payment_VF ON  AccountInfo.[mt_int_code] = Payment_VF.mt_int_code                    
                            
                            
WHERE   ClientName =@ClientName
        AND AccountInfo.CLO_ClosedDate BETWEEN @VStartDate
                                       AND     @VEndDate

END

GO
