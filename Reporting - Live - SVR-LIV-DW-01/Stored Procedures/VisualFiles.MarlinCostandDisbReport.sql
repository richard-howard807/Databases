SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




	-- =============================================
	-- Author:		<Peter Asemota>
	-- Create date: <26-09-2012>
	-- Description:	<Transaction report for Marlin>
	-- Exec [VisualFiles].[MarlinCostandDisbReport_test]'2013/08/01','2013/09/18','Marlin Europe I Limited'
	-- =============================================

	CREATE PROCEDURE [VisualFiles].[MarlinCostandDisbReport] -- [VisualFiles].[MarlinCostandDisbReport]'2015-04-30','2015-05-04','Marlin'
	( @StartDate AS DATETIME
	 ,@EndDate AS DATETIME
	 ,@ClientName AS VARCHAR(50)
	   )
	WITH RECOMPILE   
	AS 
	
		SET NOCOUNT ON
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   
		--DECLARE @VStartDate AS DATETIME
		--DECLARE @VEndDate AS DATETIME

		--SET @VStartDate = @StartDate
		--SET @VEndDate = @EndDate
		
		--DECLARE @StartDate AS DATE
		--DECLARE @EndDate AS DATE
		--SET @StartDate='2015-04-30'
		--SET @EndDate='2015-05-04'
		
		
	   
		BEGIN
	    
			SELECT DISTINCT 
			
					AccountInfo.mt_int_code ,
					AccountInfo.ClientName,
					--CDE_ClientAccountNumber AS SupplierRef ,
					CDE_ClientAccountNumber AS ClientRef ,
					HIM_AccountNumber AS OriginalCreditorRef,
					AccountInfo.SellerName AS OriginalCreditorName,
					Debtor.Title AS DebtorTitle ,
					Debtor.ForeName AS DebtorForename ,
					Debtor.Surname AS DebtorSurname ,
					SubClient AS [Sub Client],
					--LastPayment.[_date]  AS DateOfTransaction,
					Disb_CostsIncurredcm.Postdate AS  DateOfTransaction,
					CASE WHEN Disb_CostsIncurredcm.Postdate > @StartDate THEN 1 ELSE 0 END AS TransactionAggregate,
					ISNULL(CurrentBalance,0) AS currentBalance,
					ISNULL(CurrentBalance,0) + ISNULL(LastPayment.Amount,0)  AS PreTransactionBalance,
					LastPayment.Amount AS Payment,
					Payment_VF.payment AS PaidToDate,
					LastPayment.PaymentsDeletedSameDay AS PaymentsDeletedSameDay,
					LastPayment.PaymentMethod AS PaymentMethod,
					TotalDisbursements + TotalNonRecoverableCosts AS FeesToDate ,
					RecoverableCostsPaid_TD AS CostsToDate ,
					LastPayment.DisbursementPaid + LastPayment.NonRecoverableCostsPaid AS Fees ,
					Disb_CostsIncurredcm.DisbsIncurredcm AS [DisbsIncurredcm],
					Disb_CostsIncurredcm.CostsIncurredcm AS [CostIncurredcm],
					Disb_CostsIncurredcm.DisbsCostsTotal AS [DisbsCostsTotal],
					Disb_CostsIncurredcm.DisbsCostsTotal_V2 AS [DisbCoststotal_excUnreconfees],
					LastPayment.RecoverableCostsPaid AS Costs ,
					'' AS Interest,
					AdjustmentsToDate AS AdjustmentsToDate,
					LastAdjustments.LastAdjustmentValue AS CurrentAdjustment,
					--NewCurrentBalance.Balance AS CurrentPrincipalBalance, -- excludingcost
					ISNULL(CurrentBalance,0) - ((ISNULL(LastPayment.DisbursementPaid,0) + ISNULL(LastPayment.NonRecoverableCostsPaid,0)) + ISNULL(LastPayment.RecoverableCostsPaid,0)) AS CurrentPrincipalBalance, -- excludingcost
					CurrentBalance AS CurrentTotalBalance,
					(OriginalBalance +(TotalDisbursements + TotalNonRecoverableCosts + RecoverableCostsPaid_TD)) - (Payment_VF.payment) AS CBV2,
					OriginalBalance AS OriginalBalance,
					NewCurrentBalance.Balance AS NewCurrentBalance,
					CASE WHEN PaymentArrangementAmount > 0 THEN 'Y'
						 ELSE 'N'
					END AS PaymentArrangementYN ,
					PaymentArrangementAmount AS ArrangementValuePerMonth ,
					PaymentArrangementNextDate AS NextArrangementReviewDate
					--Disb_CostsIncurredcm.ItemDesc AS ItemDesc
					
	                

	                
	                
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
												AND ClientName = 'Marlin'
									) AS Debtor ON AccountInfo.mt_int_code = Debtor.mt_int_code
	               
					LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
												SUM(PYR_PaymentAmount) AS TotalPaid ,
												SUM(PYR_AmountDisbursementPaid) AS TotalDisbursements ,
												SUM(PYR_AmountNonRecoverableCostsPaid) AS TotalNonRecoverableCosts ,
												SUM(PYR_AmountRecoverableCostsPaid) AS RecoverableCostsPaid_TD
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account
									   ON Payments.mt_int_code=Account.mt_int_code
									  WHERE ClientName='Marlin'
									  GROUP BY  Payments.mt_int_code
									) AS Payments ON AccountInfo.mt_int_code = Payments.mt_int_code
					LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
												SUM(PYR_PaymentAmount) AS AdjustmentsToDate
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account
									   ON Payments.mt_int_code=Account.mt_int_code
									   
									  WHERE     PYR_PaymentAmount < 0
									  AND ClientName='Marlin'
									  GROUP BY  Payments.mt_int_code
									  
									) AS Adjustments ON AccountInfo.mt_int_code = Adjustments.mt_int_code
	             
							   LEFT OUTER JOIN (SELECT Data_.mt_int_code AS Mt_int_code,
													   Data_.LastAdjustment AS LastAdjustmentValue
	                                            
	                                            
										 FROM   ( SELECT   Payments.mt_int_code ,
															PYR_PaymentAmount AS LastAdjustment,
															PYR_PaymentDate AS PaymentDate,
												ROW_NUMBER ( ) OVER (PARTITION BY Payments.mt_int_code  ORDER BY PYR_PaymentDate  DESC) RowId
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account
									   ON Payments.mt_int_code=Account.mt_int_code AND ClientName='Marlin'
									--  WHERE     PYR_PaymentAmount < 0 
	                                   
										) AS Data_  
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
											Data.PYR_PaymentDeletedSameDay AS PaymentsDeletedSameDay
					   FROM (      
					 SELECT    Payments.mt_int_code ,
							   PYR_PaymentAmount ,
							   PYR_PaymentDate,
							   PYR_PaymentType,
							   PYR_AmountDisbursementPaid,
							   PYR_AmountNonRecoverableCostsPaid,
							   PYR_AmountRecoverableCostsPaid,
							   PYR_PaymentDeletedSameDay,
					  ROW_NUMBER ( ) OVER (PARTITION BY Payments.mt_int_code  ORDER BY PYR_PaymentDate  DESC) RowId
	                 
						FROM   VFile_Streamlined.dbo.Payments AS Payments
						INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account
									   ON Payments.mt_int_code=Account.mt_int_code 
							 WHERE PYR_PaymentType <> 'Historical Payment'
							 AND ClientName='Marlin'
	                                  
					 ) AS Data 
						WHERE Data.PYR_PaymentDate BETWEEN @StartDate AND  @EndDate        
					  --WHERE Data.RowId = 1     
	                
					) AS  LastPayment 
			ON    AccountInfo.mt_int_code = LastPayment.mtintCode                 
	                                
			 LEFT OUTER JOIN (SELECT     TOP 100 PERCENT DebtLedger.mt_int_code
								, SUM(Amount - AmountPaid) AS Balance
							FROM  [VFile_Streamlined].dbo.DebtLedger    WITH (NOLOCK)
							INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account
									   ON DebtLedger.mt_int_code=Account.mt_int_code
							 WHERE     DebtOrLedger = 'Debt'
							   GROUP BY DebtLedger.mt_int_code
							   ORDER BY DebtLedger.mt_int_code    
					  ) AS NewCurrentBalance  
			   ON  AccountInfo.[mt_int_code] = NewCurrentBalance.mt_int_code      
	   
				LEFT OUTER JOIN  (SELECT    mt_int_code ,
								  SUM(amount) AS payment
								 FROM  VFileReplicated.dbo.payment   AS Payments
							     -- WHERE mt_int_code ='219792' 
								  GROUP BY mt_int_code  
								  ) AS Payment_VF  
					   ON  AccountInfo.[mt_int_code] = Payment_VF.mt_int_code 
		        
								
			LEFT OUTER JOIN (SELECT  
			                  ID ,
	                         DisbsIncurred AS DisbsIncurredcm,
	                         CostsIncurred AS CostsIncurredcm ,
	                         DisbsIncurred + CostsIncurred AS DisbsCostsTotal,
	                         CASE WHEN DisbsIncurred IN (3,3.6) THEN (0 + CostsIncurred) ELSE (DisbsIncurred + CostsIncurred) END AS DisbsCostsTotal_V2 -- excluding unreconcilable fees (3) -- or (3.60 - EW 29/09/2015 Webby 117979)
	                         ,Postdate
	                         --ItemCode,
							 --ItemDesc 
							FROM
							 ( SELECT    ledger.mt_int_code AS ID ,
											(CASE WHEN ledger.TransactionType = 'OP' AND DebtOrLedger='Ledger' THEN ledger.Amount ELSE 0 END) AS DisbsIncurred,
											(CASE WHEN ledger.TransactionType = 'COST' AND DebtOrLedger='Debt' THEN ledger.Amount ELSE 0 END) AS CostsIncurred,
											--ledger.ItemCode AS ItemCode,
											--ledger.ItemDescription AS ItemDesc,
											ledger.PostedDate AS Postdate
								  FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
								  INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account
									   ON ledger.mt_int_code=Account.mt_int_code
								  WHERE    ( (ledger.TransactionType = 'OP' AND DebtOrLedger='Ledger')
											OR (ledger.TransactionType = 'COST' AND DebtOrLedger='Debt'))
								 -- AND ledger.mt_int_code = '219792'
											AND ledger.PostedDate BETWEEN @StartDate AND @EndDate
									  
					
								 ) 	AS data	
								 --GROUP BY data.Postdate,data.ID
								 --,data.ItemCode,data.ItemDesc						
								)  AS  Disb_CostsIncurredcm 
								ON AccountInfo.mt_int_code = Disb_CostsIncurredcm.ID                    
			WHERE   ClientName = 'Marlin'
				   -- AND  LastPayment.PaymentsDeletedSameDay <> 'Yes'
				   --   AND AccountInfo.mt_int_code = '219792'
					-- AND LastPayment.[_date] IS NULL
					 AND Disb_CostsIncurredcm.Postdate BETWEEN @StartDate AND @EndDate
					AND  (Disb_CostsIncurredcm.DisbsIncurredcm  IS NOT  NULL OR Disb_CostsIncurredcm.CostsIncurredcm  IS NOT NULL)
	                
	                
					ORDER BY AccountInfo.mt_int_code,DateOfTransaction 
                 
    
    OPTION (FAST 1)
    
    END



GO
