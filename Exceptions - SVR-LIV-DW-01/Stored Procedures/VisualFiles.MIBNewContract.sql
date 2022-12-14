SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [VisualFiles].[MIBNewContract] -- '2019-01-01','2019-01-31'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN

SELECT 
MatterCode AS [Supplier Ref]
,fee.name AS [Fee Earner] 
, MIB_ClaimNumber AS [MIB Ref]
,CONVERT(DATE,DateOpened,103)   AS [Date Instruction Received]
, Insurer AS [Insurer identified?]
, [DateIdentified] AS [Date insuerer case returned to MIB]
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END AS [Type of insruction -1st Placement or 2nd Placement]
,CAST(CASE WHEN (CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END)
='Defendant' THEN 
DATEADD(DAY,180,DateOpened) ELSE DATEADD(DAY,360,DateOpened) END AS DATE) AS [Deadline for instruction (180 days 1st placement 365 days 2nd placement]
,DATEDIFF(DAY,DateOpened,ISNULL(CLO_ClosedDate,GETDATE())) AS [Elapsed Days]
,CONVERT(DATE,DateRetained,103) AS [Date Retained]
,RetentionReason AS RetentionReason
,CONVERT(DATE,CLO_ClosedDate,103) [Date Closed]


, OriginalBalance AS [Potential value to be recovered]
, RecoveredMonth AS [Value Recovered this month]
, CONVERT(DATE,PaymentDate,103) AS [Date reocvery payment made this month]
, TotalRecovered AS [Value Recovered to date]
, RecoverableCosts AS [Costs Charged this month]
, RecoverableCostsDate AS [Date costs were invoiced this month]
, RecoverableCostsToDate AS [Costs charged to date]
--, CASE WHEN ISNULL(TotalRecovered,0) = 0 THEN 0  ELSE ISNULL(TotalRecovered,0) / ISNULL(OriginalBalance,0) END 
,ISNULL(OriginalBalance,0) - ISNULL(TotalRecovered,0) AS [Measure 1 - Potential recovery value v value recovered to date]
, CASE WHEN ISNULL(RecoverableCostsToDate,0)=0 THEN 0 ELSE  ISNULL(OriginalBalance,0) - ISNULL(RecoverableCostsToDate,0)  END AS [Measure  2 - Value recovered to date v Costs charged to date]
,CurrentBalance
,NULL AS [Measure2a]
,FirstPaymentDate AS FirstPaymentDate
,DATEDIFF(DAY,DateOpened,FirstPaymentDate) AS Measure3
,CASE WHEN CCT.ClaimNumber1 IS NULL AND CCT.ClaimNumber2 IS NULL THEN 'Pre Litigation'  
WHEN RIGHT(level_fee_earner,3)='JAL' THEN 'Defended' --'6138
WHEN CHO.CHO_Interimdate IS NOT NULL OR CHO.CHO_Finalorderdated IS NOT NULL 
OR Warrant.CWA_WarrantNumber IS NOT NULL OR AOE.ATT_AttachmentOfEarningsNO IS NOT NULL THEN 'Enforcement'
WHEN CCT.ClaimNumber1 IS NOT NULL OR CCT.ClaimNumber2 IS NOT NULL THEN 'Litigated'
END AS NewStatusType
 FROM VFile_Streamlined.dbo.AccountInformation
 LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens
  ON AccountInformation.mt_int_code=ClientScreens.mt_int_code
 LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON AccountInformation.mt_int_code=ADA.mt_int_code
LEFT OUTER JOIN (SELECT Payments.mt_int_code,SUM(PYR_PaymentAmount) AS TotalRecovered
,MIN(PYR_PaymentDate) AS FirstPaymentDate
FROM VFile_Streamlined.dbo.Payments
INNER JOIN VFile_Streamlined.dbo.AccountInformation
 ON Payments.mt_int_code=AccountInformation.mt_int_code
WHERE ClientName='MIB'
GROUP BY Payments.mt_int_code) AS PaymentsAll
 ON AccountInformation.mt_int_code=PaymentsAll.mt_int_code
LEFT OUTER JOIN (
SELECT Payments.mt_int_code,SUM(PYR_PaymentAmount) AS RecoveredMonth
,MIN(PYR_PaymentDate) AS PaymentDate
FROM VFile_Streamlined.dbo.Payments
INNER JOIN VFile_Streamlined.dbo.AccountInformation
 ON Payments.mt_int_code=AccountInformation.mt_int_code
WHERE ClientName='MIB'
AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
GROUP BY Payments.mt_int_code) AS Payments
 ON AccountInformation.mt_int_code=Payments.mt_int_code
    LEFT OUTER JOIN (
                      SELECT    debt.mt_int_code
                              , SUM(debt.amount) AS RecoverableCosts
                              ,MIN(PostedDate) AS RecoverableCostsDate
                      FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                      WHERE     debt.TransactionType = 'COST'
                                AND DebtOrLedger = 'Debt'
                                AND debt.PostedDate BETWEEN @StartDate AND @EndDate
                      GROUP BY  debt.mt_int_code
                    ) recoverablecosts
            ON AccountInformation.mt_int_code = recoverablecosts.mt_int_code
    LEFT OUTER JOIN (
                      SELECT    debt.mt_int_code
                              , SUM(debt.amount) AS RecoverableCostsToDate
                      FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                      WHERE     debt.TransactionType = 'COST'
                                AND DebtOrLedger = 'Debt'
                      
                      GROUP BY  debt.mt_int_code
                    ) recoverablecoststoDate
            ON AccountInformation.mt_int_code = recoverablecoststoDate.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON 
			--RTRIM(REPLACE(level_fee_earner,'LIT/DEBT/MIB/',''))
			
			RIGHT(level_fee_earner,3)=fee_earner        
			
			LEFT OUTER  JOIN ( SELECT mt_int_code AS mt_int_code ,
                            RTRIM(ud_field##2) AS RetentionReason,
                            CONVERT(DATE,RTRIM(ud_field##3),103) AS DateRetained
                     FROM   VFile_Streamlined.dbo.uddetail
                     WHERE  uds_type = 'MIR'
                            AND ud_field##1 = 'Yes'
                   ) AS Retention ON AccountInformation.mt_int_code = Retention.mt_int_code
	LEFT OUTER JOIN (SELECT mt_int_code AS mt_int_code ,
                            ud_field##6 AS[Insurer],
							CONVERT(DATE,RTRIM(ud_field##7),103) AS [DateIdentified]
                     FROM   VFile_Streamlined.dbo.uddetail
                     WHERE  uds_type = 'MIL'
                        ) AS MIL
						 ON AccountInformation.mt_int_code=MIL.mt_int_code  
LEFT OUTER JOIN (SELECT mt_int_code
,CASE WHEN ISNULL(ud_field##9,'')='' THEN NULL ELSE ud_field##9 END AS ClaimNumber1
,CASE WHEN ISNULL(ud_field##20,'')='' THEN NULL ELSE ud_field##20 END AS ClaimNumber2
FROM VFile_Streamlined.dbo.uddetail WHERE uds_type='CCT') AS CCT
 ON CCT.mt_int_code = AccountInformation.mt_int_code
LEFT OUTER JOIN (SELECT mt_int_code,ATT_AttachmentOfEarningsNO FROM VFile_Streamlined.dbo.AttachmentOfEarnings
WHERE ISNULL(ATT_AttachmentOfEarningsNO,'')<>''	) AS AOE
 ON AOE.mt_int_code = AccountInformation.mt_int_code
LEFT OUTER JOIN 
(
SELECT mt_int_code,CASE WHEN CHO_Interimdate='1900-01-01' THEN NULL ELSE CHO_Interimdate END AS CHO_Interimdate
,CASE WHEN CHO_Finalorderdated='1900-01-01' THEN NULL ELSE CHO_Finalorderdated END AS CHO_Finalorderdated
FROM VFile_Streamlined.dbo.Charges
) AS CHO
 ON CHO.mt_int_code = AccountInformation.mt_int_code
LEFT OUTER JOIN 
(
SELECT mt_int_code,CWA_WarrantNumber FROM VFile_Streamlined.dbo.Warrant
WHERE ISNULL(CWA_WarrantNumber,'')<>''	
) AS Warrant
 ON Warrant.mt_int_code = AccountInformation.mt_int_code
 WHERE ClientName='MIB'
--AND AccountInformation.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMatters)
AND  (DateOpened>='2019-02-01' AND  [ADA28] <>'Recovery from Claimant' OR [ADA28]='Recovery from Claimant') 



--SELECT 
--MatterCode AS [Supplier Ref]
--,fee.name AS [Fee Earner] 
--, MIB_ClaimNumber AS [MIB Ref]
--, DateOpened AS [Date Instruction Received]
--, Insurer AS [Insurer identified?]
--, [DateIdentified] AS [Date insuerer case returned to MIB]
--,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
--WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
--WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END AS [Type of insruction -1st Placement or 2nd Placement]
--,CAST(CASE WHEN (CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
--WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
--WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END)
--='First Placement' THEN 
--DATEADD(DAY,180,DateOpened) ELSE DATEADD(DAY,360,DateOpened) END AS DATE) AS [Deadline for instruction (180 days 1st placement 365 days 2nd placement]
--,DATEDIFF(DAY,DateOpened,ISNULL(CLO_ClosedDate,GETDATE())) AS [Elapsed Days]
--,DateRetained AS [Date Retained]
--,RetentionReason AS RetentionReason
--,CLO_ClosedDate [Date Closed]


--, OriginalBalance AS [Potential value to be recovered]
--, RecoveredMonth AS [Value Recovered this month]
--, PaymentDate AS [Date reocvery payment made this month]
--, TotalRecovered AS [Value Recovered to date]
--, RecoverableCosts AS [Costs Charged this month]
--, RecoverableCostsDate AS [Date costs were invoiced this month]
--, RecoverableCostsToDate AS [Costs charged to date]
----, CASE WHEN ISNULL(TotalRecovered,0) = 0 THEN 0  ELSE ISNULL(TotalRecovered,0) / ISNULL(OriginalBalance,0) END 
--,ISNULL(OriginalBalance,0) - ISNULL(TotalRecovered,0) AS [Measure 1 - Potential recovery value v value recovered to date]
--, CASE WHEN ISNULL(RecoverableCostsToDate,0)=0 THEN 0 ELSE  ISNULL(OriginalBalance,0) - ISNULL(RecoverableCostsToDate,0)  END AS [Measure  2 - Value recovered to date v Costs charged to date]
--,CurrentBalance
--,NULL AS [Measure2a]
-- FROM VFile_Streamlined.dbo.AccountInformation
-- LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens
--  ON AccountInformation.mt_int_code=ClientScreens.mt_int_code
-- LEFT JOIN (
--			SELECT mt_int_code, ud_field##28 AS [ADA28] 
--			FROM [Vfile_streamlined].dbo.uddetail
--			WHERE uds_type='ADA'
--			) AS ADA ON AccountInformation.mt_int_code=ADA.mt_int_code
--LEFT OUTER JOIN (SELECT Payments.mt_int_code,SUM(PYR_PaymentAmount) AS TotalRecovered
--FROM VFile_Streamlined.dbo.Payments
--INNER JOIN VFile_Streamlined.dbo.AccountInformation
-- ON Payments.mt_int_code=AccountInformation.mt_int_code
--WHERE ClientName='MIB'
--GROUP BY Payments.mt_int_code) AS PaymentsAll
-- ON AccountInformation.mt_int_code=PaymentsAll.mt_int_code
--LEFT OUTER JOIN (
--SELECT Payments.mt_int_code,SUM(PYR_PaymentAmount) AS RecoveredMonth
--,MIN(PYR_PaymentDate) AS PaymentDate
--FROM VFile_Streamlined.dbo.Payments
--INNER JOIN VFile_Streamlined.dbo.AccountInformation
-- ON Payments.mt_int_code=AccountInformation.mt_int_code
--WHERE ClientName='MIB'
--AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
--GROUP BY Payments.mt_int_code) AS Payments
-- ON AccountInformation.mt_int_code=Payments.mt_int_code
--    LEFT OUTER JOIN (
--                      SELECT    debt.mt_int_code
--                              , SUM(debt.amount) AS RecoverableCosts
--                              ,MIN(PostedDate) AS RecoverableCostsDate
--                      FROM      VFile_Streamlined.dbo.DebtLedger AS debt
--                      WHERE     debt.TransactionType = 'COST'
--                                AND DebtOrLedger = 'Debt'
--                                AND debt.PostedDate BETWEEN @StartDate AND @EndDate
--                      GROUP BY  debt.mt_int_code
--                    ) recoverablecosts
--            ON AccountInformation.mt_int_code = recoverablecosts.mt_int_code
--    LEFT OUTER JOIN (
--                      SELECT    debt.mt_int_code
--                              , SUM(debt.amount) AS RecoverableCostsToDate
--                      FROM      VFile_Streamlined.dbo.DebtLedger AS debt
--                      WHERE     debt.TransactionType = 'COST'
--                                AND DebtOrLedger = 'Debt'
                      
--                      GROUP BY  debt.mt_int_code
--                    ) recoverablecoststoDate
--            ON AccountInformation.mt_int_code = recoverablecoststoDate.mt_int_code
--LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON 
--			--RTRIM(REPLACE(level_fee_earner,'LIT/DEBT/MIB/',''))
			
--			RIGHT(level_fee_earner,3)=fee_earner        
			
--			LEFT OUTER  JOIN ( SELECT mt_int_code AS mt_int_code ,
--                            RTRIM(ud_field##2) AS RetentionReason,
--                            CONVERT(DATE,RTRIM(ud_field##3),103) AS DateRetained
--                     FROM   VFile_Streamlined.dbo.uddetail
--                     WHERE  uds_type = 'MIR'
--                            AND ud_field##1 = 'Yes'
--                   ) AS Retention ON AccountInformation.mt_int_code = Retention.mt_int_code
--	LEFT OUTER JOIN (SELECT mt_int_code AS mt_int_code ,
--                            ud_field##6 AS[Insurer],
--							CONVERT(DATE,RTRIM(ud_field##7),103) AS [DateIdentified]
--                     FROM   VFile_Streamlined.dbo.uddetail
--                     WHERE  uds_type = 'MIL'
--                        ) AS MIL
--						 ON AccountInformation.mt_int_code=MIL.mt_int_code   
-- WHERE ClientName='MIB'
--AND  (DateOpened>='2019-02-01' AND  [ADA28] <>'Recovery from Claimant' OR [ADA28]='Recovery from Claimant') 
END
GO
