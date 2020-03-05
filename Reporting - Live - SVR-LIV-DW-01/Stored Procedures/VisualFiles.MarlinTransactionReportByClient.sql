SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Peter Asemota>
-- Create date: <26-09-2012>
-- Description:	<Transaction report for Marlin>
-- Exec [VisualFiles].[MarlinTransactionReport]'2012/11/05','2012/11/05'
-- =============================================

	CREATE PROCEDURE [VisualFiles].[MarlinTransactionReportByClient]

	(@StartDate AS DATETIME
	 , @EndDate AS DATETIME
	 ,@Clientname AS VARCHAR(MAX)
	   )
	   
	AS 
		SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	    
	   


	DECLARE @VStartDate AS DATETIME
	DECLARE @VEndDate AS DATETIME


	SET @VStartDate = @StartDate
	SET @VEndDate = @EndDate   
	   
		BEGIN
	    
			SELECT  
					AccountInfo.mt_int_code ,
					CDE_ClientAccountNumber AS SupplierRef ,
					CDE_ClientAccountNumber AS ClientRef ,
					HIM_AccountNumber AS OriginalCreditorRef,
					AccountInfo.SellerName AS OriginalCreditorName,
					SubClient AS [Sub Client],
					Debtor.Title AS DebtorTitle ,
					Debtor.ForeName AS DebtorForename ,
					Debtor.Surname AS DebtorSurname ,
					LastPayment.[_date]  AS DateOfTransaction,
					CurrentBalance + LastPayment.Amount AS PreTransactionBalance,
					LastPayment.Amount AS Payment,
					Payment_VF.payment AS PaidToDate,
					LastPayment.PaymentsDeletedSameDay AS PaymentsDeletedSameDay,
					LastPayment.PaymentMethod AS PaymentMethod,
					TotalDisbursements + TotalNonRecoverableCosts AS FeesToDate ,
					RecoverableCostsPaid_TD AS CostsToDate ,
					LastPayment.DisbursementPaid + LastPayment.NonRecoverableCostsPaid AS Fees ,
					CostsIncurred.CostsIncurred,
					LastPayment.RecoverableCostsPaid AS Costs ,
					'' AS Interest,
					AdjustmentsToDate AS AdjustmentsToDate,
					LastAdjustments.LastAdjustmentValue AS CurrentAdjustment,
					--NewCurrentBalance.Balance AS CurrentPrincipalBalance, -- excludingcost
					CurrentBalance - ((LastPayment.DisbursementPaid + LastPayment.NonRecoverableCostsPaid) + LastPayment.RecoverableCostsPaid) AS CurrentPrincipalBalance, -- excludingcost
					CurrentBalance AS CurrentTotalBalance,
					(OriginalBalance +(TotalDisbursements + TotalNonRecoverableCosts + RecoverableCostsPaid_TD)) - (Payment_VF.payment) AS CBV2,
					OriginalBalance AS OriginalBalance,
					NewCurrentBalance.Balance AS NewCurrentBalance,
					CASE WHEN PaymentArrangementAmount > 0 THEN 'Y'
						 ELSE 'N'
					END AS PaymentArrangementYN ,
					PaymentArrangementAmount AS ArrangementValuePerMonth ,
					PaymentArrangementNextDate AS NextArrangementReviewDate

	                
	                
			FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
					LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON AccountInfo.mt_int_code = SOLCDE.mt_int_code
					LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS c ON AccountInfo.mt_int_code = c.mt_int_code
					LEFT OUTER JOIN ( SELECT    Debtor.mt_int_code ,
												Title ,
												Forename ,
												Name ,
												Surname ,
												Address1 ,
												Address2 ,
												Address3 ,
												Address4 ,
												PostCode ,
												HomeTelephone ,
												WorkTelephone ,
												Mobile ,
												DateofBirth
									  FROM      VFile_Streamlined.dbo.DebtorInformation
												AS Debtor
												INNER JOIN VFile_Streamlined.dbo.AccountInformation
												AS AccountInfo ON Debtor.mt_int_code = AccountInfo.mt_int_code
									  WHERE     ContactType = 'Primary Debtor'
												AND ClientName =@Clientname
									) AS Debtor ON AccountInfo.mt_int_code = Debtor.mt_int_code
	               
					LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
												SUM(PYR_PaymentAmount) AS TotalPaid ,
												SUM(PYR_AmountDisbursementPaid) AS TotalDisbursements ,
												SUM(PYR_AmountNonRecoverableCostsPaid) AS TotalNonRecoverableCosts ,
												SUM(PYR_AmountRecoverableCostsPaid) AS RecoverableCostsPaid_TD
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  WHERE  ISNULL(PDE_MilestonePaymentReceviedIn,'') <>'COMP' -- addded from ticket 79927
									  GROUP BY  mt_int_code
									) AS Payments ON AccountInfo.mt_int_code = Payments.mt_int_code
					LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
												SUM(PYR_PaymentAmount) AS AdjustmentsToDate
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  WHERE     PYR_PaymentAmount < 0
									  AND ISNULL(PDE_MilestonePaymentReceviedIn,'') <>'COMP' -- addded from ticket 79927
									  GROUP BY  mt_int_code
									) AS Adjustments ON AccountInfo.mt_int_code = Adjustments.mt_int_code
	             
							   LEFT OUTER JOIN (SELECT Data_.mt_int_code AS Mt_int_code,
													   Data_.LastAdjustment AS LastAdjustmentValue
	                                            
	                                            
										 FROM   ( SELECT    mt_int_code ,
															PYR_PaymentAmount AS LastAdjustment,
															PYR_PaymentDate AS PaymentDate,
												ROW_NUMBER ( ) OVER (PARTITION BY mt_int_code  ORDER BY PYR_PaymentDate  DESC) RowId
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  WHERE ISNULL(PDE_MilestonePaymentReceviedIn,'') <>'COMP' -- addded from ticket 79927
									--  WHERE     PYR_PaymentAmount < 0 
	                                   
										) As Data_  
										WHERE    Data_.LastAdjustment < 0 
												AND Data_.PaymentDate BETWEEN @StartDate AND  @EndDate
	                                        
									 --WHERE Data_.RowId = 1  
	                                  
									) AS LastAdjustments ON AccountInfo.mt_int_code = LastAdjustments.Mt_int_code
	                
	                  
				   LEFT OUTER JOIN ( SELECT   
											Data.mt_int_code AS mtintCode,
											Data.PYR_PaymentAmount AS Amount,
											Data.PYR_PaymentDate AS _date,
											Data.PYR_PaymentType AS PaymentMethod,
											Data.PYR_AmountDisbursementPaid AS DisbursementPaid,
											Data.PYR_AmountNonRecoverableCostsPaid AS NonRecoverableCostsPaid,
											Data.PYR_AmountRecoverableCostsPaid AS RecoverableCostsPaid,
											Data.PYR_PaymentDeletedSameDay AS PaymentsDeletedSameDay,
											Data.PYR_PaymentTakenByClient AS PaymentTakenByClient
					   FROM (      
					 SELECT    mt_int_code ,
							   PYR_PaymentAmount ,
							   PYR_PaymentDate,
							   PYR_PaymentType,
							   PYR_AmountDisbursementPaid,
							   PYR_AmountNonRecoverableCostsPaid,
							   PYR_AmountRecoverableCostsPaid,
							   PYR_PaymentDeletedSameDay,
							   PYR_PaymentTakenByClient,
					  ROW_NUMBER ( ) OVER (PARTITION BY mt_int_code  ORDER BY PYR_PaymentDate  DESC) RowId
	                 
						FROM   VFile_Streamlined.dbo.Payments AS Payments
							 WHERE PYR_PaymentType NOT IN ('Historical Payment','CCA Request Fee')
							 AND ISNULL(PDE_MilestonePaymentReceviedIn,'') <>'COMP' -- addded from ticket 79927
	                                  
					 ) AS Data 
						WHERE Data.PYR_PaymentDate BETWEEN @VStartDate AND  @VEndDate        
					  --WHERE Data.RowId = 1     
	                
					) AS  LastPayment 
			ON    AccountInfo.mt_int_code = LastPayment.mtintCode                 
	                                
			 LEFT OUTER JOIN (SELECT     TOP 100 PERCENT mt_int_code
								, SUM(Amount - AmountPaid) AS Balance
							FROM  [VFile_Streamlined].dbo.DebtLedger    WITH (NOLOCK)
							 WHERE     DebtOrLedger = 'Debt'
							   GROUP BY mt_int_code
							   ORDER BY mt_int_code    
					  ) As NewCurrentBalance  
			   ON  AccountInfo.[mt_int_code] = NewCurrentBalance.mt_int_code      
	   
				LEFT OUTER JOIN  (SELECT    mt_int_code ,
								  SUM(amount) AS payment
								 FROM  VFileReplicated.dbo.payment   AS Payments
							   --   WHERE mt_int_code ='3044' 
							   
								  GROUP BY mt_int_code  
								  ) AS Payment_VF  
					   ON  AccountInfo.[mt_int_code] = Payment_VF.mt_int_code 
		        
			   LEFT OUTER JOIN ( SELECT    ledger.mt_int_code AS ID ,
											SUM(ledger.Amount) AS DisbsIncurred
								  FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
								  WHERE     ledger.TransactionType = 'OP'
								  AND DebtOrLedger='Ledger'
											AND ledger.PostedDate BETWEEN @VStartDate
																  AND
																  @VEndDate
								  GROUP BY  ledger.mt_int_code
								) AS DisbsIncurredcm ON AccountInfo.mt_int_code = DisbsIncurredcm.ID
				LEFT OUTER JOIN 
	            
				( SELECT    debt.mt_int_code AS ID ,
											debt.amount AS CostsIncurred
								  FROM      VFile_Streamlined.dbo.DebtLedger AS debt
								  WHERE     debt.TransactionType = 'COST'
								  AND DebtOrLedger='Debt'
								  --AND debt.mt_int_code = '209304'
								  AND PostedDate BETWEEN @VStartDate AND @VEndDate
								 -- GROUP BY  debt.mt_int_code
								) AS CostsIncurred ON AccountInfo.mt_int_code = CostsIncurred.ID                        
			WHERE   ClientName =@Clientname
					AND  LOWER(LastPayment.PaymentsDeletedSameDay)= 'no'
					AND  LOWER(LastPayment.PaymentTakenByClient) =  'yes'
					AND  LastPayment.[_date] BETWEEN @VStartDate
											 AND     @VEndDate
	    
	    
	    
		END



GO
