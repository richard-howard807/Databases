SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




----EXEC [VisualFiles].[MarlinLiveListingsReport_V2PA] 'Marlin'
CREATE PROCEDURE [VisualFiles].[MarlinLiveListingsReport_V2PA]
(
@ClientName AS VARCHAR(MAX)
)
--DECLARE @ClientName AS VARCHAR(MAX)
--SET @ClientName='Marlin'

AS 
    BEGIN
    
    
        IF OBJECT_ID('tempdb..#EmailAddress') IS NOT NULL DROP TABLE #EmailAddress

SELECT uddetail.mt_int_code,REPLACE(right((REPLACE(REPLACE(ud_field##22,'Email:','|'),'Employer:','~')), len((REPLACE(REPLACE(ud_field##22,'Email:','|'),'Employer:','~'))) - charindex('|', (REPLACE(REPLACE(ud_field##22,'Email:','|'),'Employer:','~'))) - 1),'    ','') AS Field22

INTO #EmailAddress
FROM VFile_Streamlined.dbo.uddetail
INNER JOIN VFile_Streamlined.dbo.AccountInformation
 ON uddetail.mt_int_code=AccountInformation.mt_int_code
WHERE uds_type='MSD'
AND ClientName='Marlin'
AND RTRIM(ud_field##22) <>''
AND ud_field##22 IS NOT NULL


		SELECT  DISTINCT
					AccountInfo.mt_int_code ,
					CDE_ClientAccountNumber AS SupplierRef ,
					CDE_ClientAccountNumber AS ClientRef ,
					HIM_AccountNumber AS OriginalCreditorRef ,
					AccountInfo.SellerName AS OriginalCreditorName,
					Debtor.Title AS DebtorTitle ,
					Debtor.ForeName AS DebtorForename ,
					SubClient AS [Sub Client],
					'' AS DebtorMiddleName , -- added by PA
					CASE WHEN FileStatus = 'COMP' THEN 'Closed'
					ELSE 'Open'
					END AS [Open/Closed],
					CLO_ClosedDate AS ClosedDate,
					CASE WHEN CLO_ClosedDate <>'' AND CLO_ClosureReason='' THEN CLO_ClosureCode ELSE CLO_ClosureReason END  AS ClosureReason,
					Debtor.Surname AS DebtorSurname ,
					AccountInfo.DateOpened AS OriginalDateLoaded,
					AccountInfo.DateOpened AS DateLoaded ,
					MilestoneCode AS CurrentStatusCode ,
					MilestoneDescription AS CurrentStatusDescription ,
					CASE WHEN LastPayment.Amount=0.00 THEN NULL ELSE LastPayment.Amount END  AS LastPaymentAmount ,
					LastPayment.[_date] AS LastPaymentDate ,
					CASE WHEN PaymentArrangementAmount > 0 THEN 'Y'
						 ELSE 'N'
					END AS PaymentArrangementYN ,
					CASE WHEN PaymentArrangementAmount=0.00 THEN NULL ELSE PaymentArrangementAmount END  AS ArrangementValuePerMonth ,
					PaymentArrangementNextDate AS NextArrangementReviewDate ,
					CASE WHEN OriginalBalance=0.00 THEN NULL ELSE OriginalBalance END  AS OriginalBalance ,
					CASE WHEN TotalPaid=0.00 THEN NULL ELSE TotalPaid END  AS PaidToDate ,
					--TotalDisbursements + TotalNonRecoverableCosts AS FeesToDate , --Ticket 71089
					CASE WHEN SubClient='Marlin Europe I Limited' AND (SellerName='' OR SellerName IS NULL) THEN ISNULL(DisbsIncurred.DisbsIncurred,0)  + ISNULL(LandReg,0) ELSE 
					DisbsIncurred.DisbsIncurred END  AS FeesToDate,
					--RecoverableCostsPaid AS CostsToDate ,
					CASE WHEN CostsIncurred=0.00 THEN NULL ELSE CostsIncurred END  AS CostsToDate,
					'' AS InterestToDate,
					CASE WHEN AdjustmentsToDate=0.00 THEN NULL ELSE AdjustmentsToDate END  AS AdjustmentsToDate ,
					CASE WHEN CurrentBalance=0.00 THEN NULL ELSE CurrentBalance END  AS CurrentPrincipalBalance ,
					CASE WHEN CurrentBalance=0.00 THEN NULL ELSE CurrentBalance END AS CurrentTotalBalance ,
					Debtor.Address1 AS SuppliedAddress1 ,
					Debtor.Address2 AS SuppliedAddress2 ,
					Debtor.Address3 AS SuppliedAddress3 ,
					Debtor.Address4 AS SuppliedAddress4 ,
					'' AS SuppliedAddress5 ,
					Debtor.PostCode AS SuppliedAddressPostcode ,
					Debtor.HomeTelephone AS SuppliedHomePhone ,
					Debtor.WorkTelephone AS SuppliedWorkPhone ,
					Debtor.Mobile AS SuppliedMobPhone ,
					Email.EmailAddress AS SuppliedEMailAddress ,
					Employer.Name AS SuppliedEmploymentDetails ,
					Employer.Address1 AS CurrentAddress1 ,
					Employer.Address2 AS CurrentAddress2 ,
					Employer.Address3 AS CurrentAddress3 ,
					Employer.Address4 AS CurrentAddress4 ,
					'' AS CurrentAddress5 ,
					Employer.PostCode AS CurrentAddressPostcode,
					'' AS LatestAddressUpToDate,
					Employer.HomeTelephone AS CurrentHomePhone ,
					Employer.WorkTelephone AS CurrentWorkPhone ,
					Employer.Mobile AS CurrentMobPhone ,
					Debtor.DateofBirth AS DebtorDOB ,
					CASE WHEN Employer.NAME IS NOT NULL THEN 'Employed' ELSE 'UnEmployed'
					END AS CurrentEmploymentStatus,
					Employer.NAME AS [Current employer Details],
					'' AS [Intro Letter Issued y/n],
					'' AS [Intro Letter Date],
					
					--CASE WHEN CRD_DateLBASent  <> '1900-01-01' THEN 'Y'
					--	 ELSE 'N'
					--END AS [LBA Letter Issued YN],
					'Y' AS [LBA Letter Issued YN],
					COALESCE((CASE WHEN CRD_DateLBASent = '1900-01-01'  THEN NULL 
					ELSE CRD_DateLBASent END),AccountInfo.DateOpened) AS [LBA Letter Date],
					
					CASE WHEN (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01'  THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) <> '1900-01-01' THEN 'Y'
					ELSE 'N' END AS [Other Pre-Claim Letter Issued YN],
					CASE WHEN (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01'  THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) = '1900-01-01' THEN  NULL 
					ELSE (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01'  THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) END AS [Other Pre-Claim Letter Date],
					--CASE WHEN CRD_DateClaimFormIssued IS NOT NULL THEN 'Y'
					--     WHEN CRD_DateClaimFormIssued = '1900-01-01' THEN 'N'
					--     ELSE 'N'
					--END AS ClaimIssuedYN ,
					CASE WHEN (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01' THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) ='' AND  CRD_DateJudgmentGranted=''  THEN 'N'
					
					WHEN (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01' THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) <> '1900-01-01' THEN 'Y'
					WHEN CCI_TotalAmountClaimed >0 THEN 'Y'	 
					WHEN (CASE WHEN CRD_DateClaimFormIssued = '1900-01-01' THEN NULL ELSE  CRD_DateClaimFormIssued END) IS NOT NULL THEN 'Y'
					WHEN (CASE WHEN CRD_DateJudgmentGranted IS NOT NULL AND CRD_DateJudgmentGranted <>'1900-01-01'  THEN 'Y'
						 WHEN CRD_DateJudgmentGranted = '1900-01-01' THEN 'N'
						 ELSE 'N'
					END)='Y' THEN 'Y'
					WHEN CCT_Claimnumber9 IS NOT NULL OR NewClaimNumber IS NOT NULL OR CCT_Claimnumber9 <>'' OR NewClaimNumber<> ''THEN 'Y'	 
						 ELSE 'N'
					END AS ClaimIssuedYN ,
					CASE WHEN CCI_TotalAmountClaimed=0.00 THEN NULL ELSE CCI_TotalAmountClaimed END  AS ClaimValue ,
					
					CASE WHEN CRD_DateClaimFormIssued = '1900-01-01' AND CCI_DateClaimformProd='' THEN NULL 
					
					ELSE  (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01'  THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) END  AS ClaimIssueDate ,
					
					
					CASE WHEN ISNULL(CCI_TotalAmountClaimed,0)=0  
					AND(CASE WHEN CRD_DateClaimFormIssued = '1900-01-01' THEN NULL ELSE  CRD_DateClaimFormIssued END) IS NULL
					AND(CASE WHEN CRD_DateJudgmentGranted = '1900-01-01' THEN NULL ELSE  CRD_DateJudgmentGranted END) IS NULL
					AND ISNULL(CCJ_JudgmentTotalAmountPayableByDefendant,0)=0 
					
					 
					THEN ''
					WHEN VC_CourtName = 'Northampton County Court Bulk Centre: DX 702885 Northampton 7'
						 THEN 'Northampton County Court'
						 ELSE VC_CourtName
					END AS IssueCourt ,
					CASE WHEN CRD_DateJudgmentGranted IS NOT NULL AND CRD_DateJudgmentGranted <>'1900-01-01'  THEN 'Y'
						 WHEN CRD_DateJudgmentGranted = '1900-01-01' THEN 'N'
						 ELSE 'N'
					END AS CCJYN ,
					CASE WHEN CCJ_JudgmentTotalAmountPayableByDefendant=0.00 THEN NULL ELSE CCJ_JudgmentTotalAmountPayableByDefendant END  AS CCJValue ,
					CRD_DateJudgmentGranted AS CCJDate ,
					CASE WHEN NewClaimNumber ='' THEN CCT_Claimnumber9 ELSE NewClaimNumber END   AS ClaimNumber ,
					CCJ_JudgmentType AS CCJType ,
					CASE WHEN CCJ_JudgmentAmountOfInstallmentsToBePaid=0.00 THEN NULL ELSE CCJ_JudgmentAmountOfInstallmentsToBePaid END  AS InstalmentOrderAmount,
					'' AS InstalmentStatus,
					LEFT(CCJ_JudgmentCourt, CHARINDEX(':', CCJ_JudgmentCourt) )  AS CurrentJudgmentCourt ,
					CASE WHEN AttachmentApplicationDate <> '1900-01-01' THEN 'Y' ELSE 'N' END  AS [AttachmentApplication y/n],
					AttachmentApplicationDate AS AttachmentApplicationDate,
					CASE WHEN ATT.mt_int_code IS NULL THEN 'N'
						 ELSE 'Y'
					END AS AttachmentYN ,
					'' AS AttachmentApplicationFailureReason,
					AttachmentSuspendedorFull AS AttachmentSuspendedorFull ,
					AttachmentValue AS AttachmentValue ,
					AttachmentDate AS AttachmentDate ,
					AttachmentReference AS AttachmentReference ,
					CASE WHEN  ChargingOrderRequestDate.ChargingOrderApplicationDate IS NOT NULL THEN 'Y' 
					ELSE 'N' END AS [ChargingOrderApplication y/n],
					ChargingOrderRequestDate.ChargingOrderApplicationDate AS ChargingOrderApplicationDate,
					ChargingOrderYN AS ChargingOrderYN ,
					'' AS ChargingOrderApplicationFailureReason,
					CASE WHEN ChargingOrderValue=0.00 THEN NULL ELSE ChargingOrderValue END  AS ChargingOrderValue ,
					ChargingOrderInterimDate AS ChargingOrderInterimDate,
					CHO.ChargingOrderFinalHearingDate AS ChargingOrderFinalHearingDate,
					ChargingOrderFinalDate AS ChargingOrderFinalDate ,
					CASE WHEN ChargingOrderCostsAwarded=0.00 THEN NULL ELSE ChargingOrderCostsAwarded END  AS ChargingOrderCostsAwarded ,
					CASE WHEN WarrantDate IS NOT NULL THEN 'Y' ELSE 'N' END  AS [1stWarrantApplication y/n],
					WarrantDate AS [1stWarrantApplicationDate],
					WarrantYN AS WarrantYN ,
					WarrantApplicationFailureReason AS WarrantApplicationFailureReason,
					CASE WHEN WarrantValue=0.00 THEN NULL ELSE WarrantValue END  AS WarrantValue ,
					WarrantDate AS WarrantDate ,
					WarrantReference AS WarrantReference,
					CASE WHEN DateWarrantReissued2 IS NOT NULL THEN 'Y' ELSE 'N' END AS [SubsequentWarrantIssued y/n],
					NoWarrantReissued14 AS NumberOfsubsequentWarrant,
					CASE WHEN STATDemand.DateStatDemandSent IS NULL THEN 'N' ELSE 'Y' END AS [StaDemandIssued y/n],
					STATDemand.DateStatDemandSent AS StatDemandDate,
					 '' AS StatDemandValue,
					 CASE WHEN Bankruptcy.DateStatDemandServed <> '1900-01-01'THEN 'Y'
						 ELSE 'N'
					END AS [BankruptcyPetitionIssued y/n],
					CASE WHEN Bankruptcy.DateStatDemandServed = '1900-01-01' THEN NULL 
					 ELSE Bankruptcy.DateStatDemandServed END AS BankruptcyPetitionDate,
					CASE WHEN Bankruptcy.DateOfHearing <> '1900-01-01' THEN 'Y'  
					 ELSE 'N' END AS [Bankruptcy y/n],
					'' AS [BankruptcyApplicationfailureReason],
					'' AS BankruptcyValue,
					CASE WHEN Bankruptcy.DateOfHearing = '1900-01-01' THEN NULL 
					ELSE Bankruptcy.DateOfHearing END AS BankruptcyDate,
					'' AS PartAdmissionYN ,
					CASE WHEN PIT_OnHoldDefended = 'Defended' THEN 'Y' ELSE 'N' END AS DefendedYN ,
					WarrantCourt AS CurrentWarrantCourt ,
					Contact.FirstContact AS Date1stContact ,
					Contact.LastContact AS DateLastContact ,
					Lettersent.LastLetterDate AS LastLetterDate,
					'' AS LastLetterType,
					Lettersent.description_ AS LastLetterTypeDescription,
					Email.EmailAddress AS  EmailAddress,
					CONVERT(DATE,GETDATE(),103) AS [Current Status Date]
					
					
					
					
					
					
					
					
					,CASE WHEN FileStatus='COMP' THEN 'Closed/Returned to Cabot' -- Added Ticket 217011
					WHEN CurrentBalance<=0 THEN 'Awaiting Closure'
					WHEN COALESCE((CASE WHEN CRD_DateLBASent = '1900-01-01'  THEN NULL 	ELSE CRD_DateLBASent END),AccountInfo.DateOpened) BETWEEN DATEADD(DAY,-7,CONVERT(DATE,GETDATE())) AND CONVERT(DATE,GETDATE()) THEN 'LBA Issued'
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01')='1900-01-01'
					AND ISNULL(AttachmentApplicationDate,'1900-01-01')='1900-01-01'
					AND ISNULL(WarrantDate,'1900-01-01')='1900-01-01'  AND ISNULL(CRD_DateJudgmentGranted,'1900-01-01') <>'1900-01-01'
					
					
					THEN (CASE WHEN CCJ_JudgmentType LIKE '%Default%' THEN 'CCJ Obtained - default' ELSE 'CCJ Entered' END)
					
					WHEN AttachmentApplicationDate <>'1900-01-01' AND AttachmentSuspendedorFull IS NULL THEN 'AE Application'
					WHEN AttachmentApplicationDate <>'1900-01-01' AND AttachmentSuspendedorFull='Full Order' THEN 'AE Obtained - Full'
					WHEN AttachmentApplicationDate <>'1900-01-01' AND AttachmentSuspendedorFull='Suspended Order' THEN 'AE Obtained - Suspended'
					
					
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01') <> '1900-01-01' AND 		
					ISNULL(ChargingOrderInterimDate,'1900-01-01')= '1900-01-01' AND 
					ISNULL(ChargingOrderFinalDate,'1900-01-01')='1900-01-01' THEN 'CO Application'
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01') <> '1900-01-01' AND 		
					ISNULL(ChargingOrderInterimDate,'1900-01-01')<> '1900-01-01' AND 
					ISNULL(ChargingOrderFinalDate,'1900-01-01')='1900-01-01' THEN 'ICO Obtained'					
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01') <> '1900-01-01' AND 		
					ISNULL(ChargingOrderInterimDate,'1900-01-01')<> '1900-01-01' AND 
					ISNULL(ChargingOrderFinalDate,'1900-01-01')<>'1900-01-01' 
					
					THEN 'FCO Obtained'
					
					WHEN ISNULL(WarrantDate,'1900-01-01')<>'1900-01-01' AND ISNULL(WarrantReference,'')='' THEN 'WOC Application'
					WHEN ISNULL(WarrantDate,'1900-01-01')<>'1900-01-01' AND ISNULL(WarrantReference,'')<>'' THEN 'WOC Obtained'
					
					WHEN PaymentArrangementAmount>0 AND LastPayment.[_date] > CONVERT(DATE,DATEADD(WEEK,-7,GETDATE()),103) THEN 'Arrangement'
					WHEN PaymentArrangementAmount>0 AND LastPayment.[_date] < CONVERT(DATE,DATEADD(WEEK,-7,GETDATE()),103) THEN 'Broken Arrangement'
				    WHEN VCO_DateRestrictionRegistered IS NOT NULL THEN 'FCO Obtained'
				    WHEN (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01'  THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) BETWEEN DATEADD(MONTH,-6,CONVERT(DATE,GETDATE()))  AND CONVERT(DATE,GETDATE()) THEN 'Claim Issued'
				    
				   
					
										END AS [Current Status Code]
										
					,CASE 
					
					WHEN FileStatus='COMP' THEN CLO_ClosedDate -- Added Ticket 217011
					WHEN CurrentBalance<=0 THEN NULL
					WHEN COALESCE((CASE WHEN CRD_DateLBASent = '1900-01-01'  THEN NULL 	ELSE CRD_DateLBASent END),AccountInfo.DateOpened) BETWEEN DATEADD(DAY,-7,CONVERT(DATE,GETDATE())) AND CONVERT(DATE,GETDATE()) THEN COALESCE((CASE WHEN CRD_DateLBASent = '1900-01-01'  THEN NULL 	ELSE CRD_DateLBASent END),AccountInfo.DateOpened)
					
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01')='1900-01-01'
					AND ISNULL(AttachmentApplicationDate,'1900-01-01')='1900-01-01'
					AND ISNULL(WarrantDate,'1900-01-01')='1900-01-01'  AND ISNULL(CRD_DateJudgmentGranted,'1900-01-01') <>'1900-01-01'
					
					THEN CRD_DateJudgmentGranted
					
					 
					
					WHEN AttachmentApplicationDate <>'1900-01-01' AND AttachmentSuspendedorFull IS NULL THEN AttachmentApplicationDate
					WHEN AttachmentApplicationDate <>'1900-01-01' AND AttachmentSuspendedorFull='Full Order' THEN ATT_DateFullOrderMade
					WHEN AttachmentApplicationDate <>'1900-01-01' AND AttachmentSuspendedorFull='Suspended Order' THEN ATT_DateSuspendedOrderMade
					
					
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01') <> '1900-01-01' AND 		
					ISNULL(ChargingOrderInterimDate,'1900-01-01')= '1900-01-01' AND 
					ISNULL(ChargingOrderFinalDate,'1900-01-01')='1900-01-01' THEN ChargingOrderRequestDate.ChargingOrderApplicationDate
					
					
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01') <> '1900-01-01' AND 		
					ISNULL(ChargingOrderInterimDate,'1900-01-01')<> '1900-01-01' AND 
					ISNULL(ChargingOrderFinalDate,'1900-01-01')='1900-01-01' THEN ChargingOrderInterimDate					
					WHEN ISNULL(ChargingOrderRequestDate.ChargingOrderApplicationDate,'1900-01-01') <> '1900-01-01' AND 		
					ISNULL(ChargingOrderInterimDate,'1900-01-01')<> '1900-01-01' AND 
					ISNULL(ChargingOrderFinalDate,'1900-01-01')<>'1900-01-01' THEN ChargingOrderFinalDate
					
					WHEN ISNULL(WarrantDate,'1900-01-01')<>'1900-01-01' AND ISNULL(WarrantReference,'')='' THEN WarrantDate
					WHEN ISNULL(WarrantDate,'1900-01-01')<>'1900-01-01' AND ISNULL(WarrantReference,'')<>'' THEN WarrantDate
					
					WHEN PaymentArrangementAmount>0 AND LastPayment.[_date] > CONVERT(DATE,DATEADD(WEEK,-7,GETDATE()),103) THEN AccountInfo.PaymentArrangementStartDate
					WHEN PaymentArrangementAmount>0 AND LastPayment.[_date] < CONVERT(DATE,DATEADD(WEEK,-7,GETDATE()),103) THEN [BrokenArrDate]
				    WHEN VCO_DateRestrictionRegistered IS NOT NULL THEN VCO_DateRestrictionRegistered
				    WHEN (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01'  THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END) BETWEEN DATEADD(MONTH,-6,CONVERT(DATE,GETDATE()))  AND CONVERT(DATE,GETDATE()) THEN (CASE WHEN CRD_DateClaimFormIssued='' OR CRD_DateClaimFormIssued='1900-01-01'  THEN CCI_DateClaimformProd ELSE CRD_DateClaimFormIssued END)
				    
				   
					
										END AS [New Status Date]										
										
										
										
										
					,CASE WHEN PIT_MatterOnHoldYesNo=1 THEN 'Yes' ELSE 'No' END [MatterOnHold]
            ,   PIT_ReasonAccountOnHold AS [ReasonOnHold]
            ,CASE WHEN CLO_ClosedDate IS NULL THEN 1
            WHEN  DATEADD(DAY,30,CLO_ClosedDate) <=CONVERT(DATE,GETDATE(),103) THEN 0
            ELSE 1 END AS KeepStatus
					
					
					
					
					
					
					
					
					
					
					
					
			FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
					LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON AccountInfo.mt_int_code = SOLCDE.mt_int_code
					LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS c ON AccountInfo.mt_int_code = c.mt_int_code
					 LEFT OUTER JOIN (
                      SELECT    ledger.mt_int_code
                              , SUM(Ledger.Amount) AS DisbsIncurred
                      FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
                        LEFT OUTER JOIN VFile_Streamlined.dbo.trdef 
						ON ledger.ItemCode = trdef.tr_code
						AND (Recoverable = 1)
                      WHERE     Ledger.TransactionType IN ( 'OP' )
                               AND DebtOrLedger = 'Ledger'
                               AND ItemCode NOT IN ('ZLRO','ZLRT')
                      GROUP BY  Ledger.mt_int_code
                    ) AS DisbsIncurred
            ON AccountInfo.mt_int_code = DisbsIncurred.mt_int_code
					 LEFT OUTER JOIN (
                      SELECT    ledger.mt_int_code
                              , SUM(Ledger.Amount) AS LandReg
                      FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
                        LEFT OUTER JOIN VFile_Streamlined.dbo.trdef 
						ON ledger.ItemCode = trdef.tr_code
						
						
                      WHERE     Ledger.TransactionType IN ( 'OP' )
                               AND DebtOrLedger = 'Ledger'
                               AND ItemCode IN('LROC','LRCH')
                      GROUP BY  Ledger.mt_int_code
                    ) AS LandReg
            ON AccountInfo.mt_int_code = LandReg.mt_int_code
            -- Costs Incurred
    LEFT OUTER JOIN (SELECT mt_int_code AS mt_int_code
,LEFT(Field22,CHARINDEX('~',Field22 + '~')-1) AS EmailAddress
FROM #EmailAddress
WHERE (LEFT(Field22,CHARINDEX('~',Field22 + '~')-1)) LIKE '%@%') AS Email ON AccountInfo.mt_int_code=Email.mt_int_code
LEFT OUTER JOIN (
                      SELECT    Debt.mt_int_code
                              , SUM(Debt.amount) AS CostsIncurred
                      FROM      VFile_Streamlined.dbo.DebtLedger AS Debt
                      
                      WHERE     Debt.TransactionType = 'COST'
                                AND DebtOrLedger = 'Debt'
                      GROUP BY  Debt.mt_int_code
                    ) AS CostsIncurred
            ON AccountInfo.mt_int_code = CostsIncurred.mt_int_code
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
												AND ClientName = @ClientName
									) AS Debtor ON AccountInfo.mt_int_code = Debtor.mt_int_code
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
									  WHERE     ContactType = 'Primary Debtor Employeer'
												AND ClientName = @ClientName
									) AS Employer ON AccountInfo.mt_int_code = Employer.mt_int_code
					
					
					LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
												SUM(PYR_PaymentAmount) AS TotalPaid ,
												SUM(PYR_AmountDisbursementPaid) AS TotalDisbursements ,
												SUM(PYR_AmountNonRecoverableCostsPaid) AS TotalNonRecoverableCosts ,
												SUM(PYR_AmountRecoverableCostsPaid) AS RecoverableCostsPaid
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  WHERE PYR_PaymentType NOT IN ('Historical Payment','CCA Request Fee','Phoenix Payment')
									  GROUP BY  mt_int_code
									) AS Payments ON AccountInfo.mt_int_code = Payments.mt_int_code
					LEFT OUTER JOIN ( SELECT    Payments.mt_int_code ,
												SUM(PYR_PaymentAmount) AS AdjustmentsToDate
									  FROM      VFile_Streamlined.dbo.Payments AS Payments
									  WHERE     PYR_PaymentAmount < 0
									  GROUP BY  mt_int_code
									) AS Adjustments ON AccountInfo.mt_int_code = Adjustments.mt_int_code
					LEFT OUTER JOIN VFile_Streamlined.dbo.IssueDetails AS Issue ON AccountInfo.mt_int_code = Issue.mt_int_code
					LEFT OUTER JOIN VFile_Streamlined.dbo.Judgment AS Judgment ON AccountInfo.mt_int_code = Judgment.mt_int_code
					LEFT OUTER JOIN ( SELECT    mt_int_code ,
												ATT_DateFullOrderMade ,
												ATT_DateSuspendedOrderMade ,
												'' AS AttachmentYN ,
												CASE WHEN ATT_DateFullOrderMade <> '1900-01-01'
													 THEN 'Full Order'
													 WHEN ATT_DateSuspendedOrderMade <> '1900-01-01'
														  AND ATT_DateFullOrderMade = '1900-01-01'
													 THEN 'Suspended Order'
												END AS AttachmentSuspendedorFull ,
												ATT_TotalAmountowed AS AttachmentValue ,
												CASE WHEN ATT_DateFullOrderMade <> '1900-01-01'
													 THEN ATT_DateFullOrderMade
													 WHEN ATT_DateSuspendedOrderMade <> '1900-01-01'
														  AND ATT_DateFullOrderMade = '1900-01-01'
													 THEN ATT_DateSuspendedOrderMade
												END AS AttachmentDate ,
												ATT_AttachmentOfEarningsNO AS AttachmentReference,
												ATT_DateAttachmentOfEarningsReq AS AttachmentApplicationDate
									  FROM      VFile_Streamlined.dbo.AttachmentOfEarnings
									  WHERE     ATT_DateFullOrderMade <> '1900-01-01'
												OR ATT_DateSuspendedOrderMade <> '1900-01-01'
												OR ATT_DateAttachmentOfEarningsReq <>'1900-01-01'
									) AS ATT ON AccountInfo.mt_int_code = ATT.mt_int_code
					LEFT OUTER JOIN ( SELECT    mt_int_code ,
												ChargingOrderYN ,
												ChargingOrderValue ,
												ChargingOrderInterimDate ,
												ChargingOrderFinalDate ,
												ChargingOrderCostsAwarded ,
												ChargingOrderFinalHearingDate,
												exclusions
									  FROM      ( SELECT    Charges.mt_int_code ,
															'Y' AS ChargingOrderYN ,
															CHO_Totalamountowed AS ChargingOrderValue ,
															CHO_Interimdate AS ChargingOrderInterimDate ,
															CHO_Finalorderdated AS ChargingOrderFinalDate ,
															CHO_Costsawardedathearing AS ChargingOrderCostsAwarded ,
															CHO_Hearingdate AS ChargingOrderFinalHearingDate,
															CASE WHEN Charges.mt_int_code IN (
																  '5080', '11068',
																  '11497', '12731',
																  '16628', '17974',
																  '20914', '23261',
																  '24519', '25652',
																  '26413', '26426',
																  '27569', '27587',
																  '30802', '31481',
																  '36894' )
																  AND CHO_Totalamountowed = 0
																 THEN 'Exclude'
															END AS exclusions
												  FROM      VFile_Streamlined.dbo.Charges
															AS Charges
															INNER JOIN VFile_Streamlined.dbo.AccountInformation
															AS AcountInfo ON Charges.mt_int_code = AcountInfo.mt_int_code
												  WHERE     ClientName = @ClientName
															AND FileStatus <> 'COMP'
															AND ( CHO_Finalorderdated <> '1900-01-01'
																  OR CHO_Interimdate <> '1900-01-01'
																)
												) AS Charges
									  WHERE     exclusions IS NULL
									) AS CHO ON AccountInfo.mt_int_code = CHO.mt_int_code
					LEFT OUTER JOIN (SELECT mt_int_code,VCO_DateRestrictionRegistered
									 FROM VFile_Streamlined.dbo.Charges
									 WHERE ISNULL(VCO_DateRestrictionRegistered,'1900-01-01') <>'1900-01-01'
									) AS VCO
									ON AccountInfo.mt_int_code = VCO.mt_int_code
								
					LEFT OUTER JOIN ( SELECT    mt_int_code ,
												'Y' AS WarrantYN ,
												CWA_Totalamountowed AS WarrantValue ,
												CWA_DatewarrantIssued AS WarrantDate ,
												'' AS PartAdmissionYN ,
												CWA_WarrantCourt AS WarrantCourt,
												CWA_WarrantNumber AS WarrantReference,
												CWA_Reasons4ReIssue AS WarrantApplicationFailureReason,
												CWA_DateWarrantReissued13 AS DateWarrantReissued2,
												CWA_WarrantNumberReissued14 AS NoWarrantReissued14,
												CWA_Notes AS WarrantNotes
									  FROM      VFile_Streamlined.dbo.Warrant
									  WHERE     CWA_DatewarrantIssued <> '1900-01-01'
									) AS Warrant ON AccountInfo.mt_int_code = Warrant.mt_int_code
					LEFT OUTER JOIN ( SELECT    AccountInfo.mt_int_code ,
												MAX(HTRY_DateInserted) AS LastContact ,
												MIN(HTRY_DateInserted) AS FirstContact
									  FROM      VFile_Streamlined.dbo.History AS H
												INNER JOIN VFile_Streamlined.dbo.AccountInformation
												AS AccountInfo ON H.mt_int_code = AccountInfo.mt_int_code
									  WHERE     ClientName = @ClientName
												AND ( H.HTRY_description LIKE 'Outgoing Call%'
													  OR H.HTRY_description LIKE 'Incoming Call%'
													  OR H.HTRY_description LIKE 'Letter%'
													  OR H.HTRY_description LIKE '%Letter'
													)
									  GROUP BY  AccountInfo.mt_int_code
									) AS Contact ON AccountInfo.mt_int_code = Contact.mt_int_code
					LEFT OUTER JOIN ( SELECT    mt_int_code ,
												COUNT(mt_int_code) AS Number ,
												SUM(SubTotal) AS Amount ,
												[Payment Date12] AS _date
									  FROM      ( SELECT    mt_int_code ,
															SubTotal ,
															[Payment Date12] ,
															ROW_NUMBER() OVER ( PARTITION BY mt_int_code ORDER BY [Payment Date12] DESC ) AS OrderID
												  FROM      ( SELECT
																  SOLPYR.mt_int_code ,
																  SUM(PYR_PaymentAmount) AS SubTotal ,
																  PYR_PaymentDate AS [Payment Date12]
															  FROM
																  VFile_Streamlined.dbo.AccountInformation
																  AS AccountInfo
																  INNER JOIN VFile_Streamlined.dbo.Payments
																  AS SOLPYR ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
															  WHERE
																  PYR_PaymentType NOT IN ('Historical Payment','CCA Request Fee')
															  GROUP BY SOLPYR.mt_int_code ,
																  PYR_PaymentDate
															) subq1
												) subq2
									  WHERE     OrderID = 1
									  GROUP BY  [Payment Date12] ,
												mt_int_code
									) AS LastPayment ON AccountInfo.mt_int_code = LastPayment.mt_int_code
							    LEFT OUTER JOIN (SELECT mt_int_code,MAX(HTRY_DateInserted) AS [BrokenArrDate]
FROM VFile_Streamlined.dbo.History
WHERE (HTRY_UserId='RBCHASER' OR HTRY_description LIKE '%chaser letter%')
GROUP BY mt_int_code) AS BrokenDate
 ON AccountInfo.mt_int_code = BrokenDate.mt_int_code
								LEFT OUTER JOIN ( SELECT    Insolvency.mt_int_code ,
															STA_DateStatDemandSent AS DateStatDemandSent,
															BCD_StatDemandServedDate AS DateStatDemandServed,
															BCD_HearingDate AS DateOfHearing,
															STA_StatDemandType AS StatDemandType,
															AccountInfo.OriginalBalance AS SDAmount
									  FROM      VFile_Streamlined.dbo.Insolvency Insolvency
									  INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
									   ON  Insolvency.mt_int_code = AccountInfo.mt_int_code
									  WHERE     STA_DateStatDemandSent <> '1900-01-01'
									) AS STATDemand ON AccountInfo.mt_int_code = STATDemand.mt_int_code               
													LEFT OUTER JOIN ( SELECT    Insolvency.mt_int_code ,
															STA_DateStatDemandSent AS DateStatDemandSent,
															BCD_StatDemandServedDate AS DateStatDemandServed,
															BCD_HearingDate AS DateOfHearing,
															STA_StatDemandType AS StatDemandType,
															AccountInfo.OriginalBalance AS SDAmount
									  FROM      VFile_Streamlined.dbo.Insolvency Insolvency
									  INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
									   ON  Insolvency.mt_int_code = AccountInfo.mt_int_code
									  --WHERE     STA_DateStatDemandSent <> '1900-01-01'
									) AS Bankruptcy ON AccountInfo.mt_int_code = Bankruptcy.mt_int_code 
	            
			   LEFT JOIN  (
								   SELECT * FROM (
												   SELECT   
													AccountInfo.mt_int_code ,
													HTRY_DateInserted AS LastLetterDate 
													,H.HTRY_description AS description_
													,ROW_NUMBER() OVER(PARTITION BY AccountInfo.mt_int_code ORDER BY HTRY_DateInserted DESC) AS Row
									  FROM      VFile_Streamlined.dbo.History AS H
												INNER JOIN VFile_Streamlined.dbo.AccountInformation
												AS AccountInfo ON H.mt_int_code = AccountInfo.mt_int_code
									  WHERE     ClientName = @ClientName 
												AND (LOWER(H.HTRY_description) LIKE 'letter%'
													  OR LOWER(H.HTRY_description) LIKE '%letter')
	        
									 ) AS Data WHERE Row = 1
	            
			  ) AS Lettersent  ON   AccountInfo.mt_int_code = Lettersent.mt_int_code
	          
		  LEFT OUTER JOIN (               
										SELECT * FROM (
												  SELECT   
													AccountInfo.mt_int_code ,
													HTRY_DateInserted AS ChargingOrderApplicationDate 
												   ,H.HTRY_description AS description_
												   ,ROW_NUMBER() OVER(PARTITION BY AccountInfo.mt_int_code ORDER BY HTRY_DateInserted DESC) AS Row
									  FROM      VFile_Streamlined.dbo.History AS H
												INNER JOIN VFile_Streamlined.dbo.AccountInformation
												AS AccountInfo ON H.mt_int_code = AccountInfo.mt_int_code
									  WHERE     ClientName = @ClientName 
												AND (LOWER(H.HTRY_description) LIKE 'application for charging order%')
	                                 
	        
									 ) AS Data WHERE Row = 1
	       
			   ) AS ChargingOrderRequestDate
					  ON   AccountInfo.mt_int_code = ChargingOrderRequestDate.mt_int_code 
	      LEFT OUTER JOIN 
	      (
	      SELECT mt_int_code,ud_field##20 NewClaimNumber
FROM VFile_Streamlined.dbo.uddetail AS Issue
WHERE uds_type='CCT'
	      )  AS NewClaim
	       ON AccountInfo.mt_int_code=NewClaim.mt_int_code
	      --LEFT OUTER JOIN 
       --     ( SELECT mt_int_code
       --             ,MAX(HTRY_DateInserted) AS LBADate 
       --             FROM VFile_Streamlined.dbo.History
       --         WHERE Lower(HTRY_description) LIKE 'letter before action%'
       --        GROUP BY mt_int_code
       --     ) AS LBA
       --    ON AccountInfo.mt_int_code = LBA.[mt_int_code]
  
	                  
			WHERE   ClientName = @ClientName
			        AND CDE_ClientAccountNumber NOT LIKE '%|Marlin Europe 1 Limited'
			        --AND FileStatus <> 'COMP'
			        AND (CASE WHEN CLO_ClosedDate IS NULL THEN 1
            WHEN  DATEADD(DAY,30,CLO_ClosedDate) <=CONVERT(DATE,GETDATE(),103) THEN 0
            ELSE 1 END)=1
            --AND MatterCode=3402
	
				    
    
    END           


GO
