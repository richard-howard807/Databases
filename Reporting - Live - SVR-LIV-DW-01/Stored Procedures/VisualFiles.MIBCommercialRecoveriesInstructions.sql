SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [VisualFiles].[MIBCommercialRecoveriesInstructions] --EXEC [dbo].[MIBCommercialRecoveriesInstructions] 'First Placement','Open'
(
@Placement AS NVARCHAR(100)
,@Status AS NVARCHAR(100)
)
AS
BEGIN

IF OBJECT_ID('tempdb..#Placement') IS NOT NULL DROP TABLE #Placement
IF OBJECT_ID('tempdb..#Status') IS NOT NULL DROP TABLE #Status

    
--DECLARE @Placement AS NVARCHAR(100)
--DECLARE @Status AS NVARCHAR(100)

--SET @Placement='First Placement'
--SET @Status='Open'

SELECT ListValue  INTO #Placement FROM 	dbo.udt_TallySplit(',', @Placement)
SELECT ListValue  INTO #Status FROM 	dbo.udt_TallySplit(',', @Status)



SELECT 
MIB_ClaimNumber
,MatterCode
--,AccountDescription
,DateOpened
--,CLO_ClosedDate
--,CLO_ClosureCode
,[Fee Earner]
--,level_fee_earner
--,MilestoneCode
,MilestoneDescription
,OriginalBalance
,CurrentBalance
,DisbsIncurred
,CostsIncurred
--,DisPaid
--,SOLPaid
,TotalToDate
--,[Amount Paid to Weightmans Exc VAT]
,[Placement]
,ClientName
--,instructedvalue
--,paidtoclient
--,paidtoagent
--,commission
--,disbursements
--,courtfees
--,landreg
,[Last History Item Date]
,[Last History Item Description]
--,PYR_PaymentAmount
,PYR_PaymentDate
,CRD_DateClaimFormIssued
,LitigationType
,SCH_date_inserted
,SCH_date_due
,SCH_desc_awaiting
,LifeCycle
,Debtor
--,DebtorAddress
,PaymentArrangementAmount
,PaymentArrangementFrequency
,PaymentArrangementNextDate
,PaymentArrangementSetupDate
,PaymentArrangementStartDate 
--,FileStatus
,RetentionReason
,CAS08

FROM 
(

SELECT 
a.mt_int_code AS mtintcode
,HIM_AccountNumber
,MIB_ClaimNumber
,MatterCode
,AccountDescription
,DateOpened
,CLO_ClosedDate
,CLO_ClosureCode
,name AS [Fee Earner]
,a.level_fee_earner
,a.MilestoneCode
,MilestoneDescription
,OriginalBalance
,CurrentBalance
,DisbsIncurred
,CostsIncurred
,DisPaid
,SOLPaid
,TotalToDate
,PYR_AmountPaidToWeightmansExcVAT AS [Amount Paid to Weightmans Exc VAT]
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END [Placement]
,ClientName
,Instructed_Value.InstructedValue AS instructedvalue
,paidtoclient
,paidtoagent
,CASE WHEN Commission. MilestoneCode IN ('inst', 'bankstat') THEN 15 ELSE 20 END AS commission
,disbursements
,courtfees
,landreg
,LastHistoryNoteDate AS [Last History Item Date]
,LastHistoryDescription AS [Last History Item Description]
,LastPayment.PYR_PaymentAmount
,LastPayment.PYR_PaymentDate
,CRD_DateClaimFormIssued
,CASE WHEN (CASE WHEN CRD_DateClaimFormIssued='1900-01-01' THEN NULL ELSE CRD_DateClaimFormIssued END ) IS NOT NULL THEN 'Litigated' ELSE 'Pre-Litigated' END AS LitigationType
,SCH_date_inserted
,SCH_date_due
,SCH_desc_awaiting
,DATEDIFF(DAY,DateOpened,COALESCE(CLO_ClosedDate,GETDATE())) AS LifeCycle
,Debtor
,DebtorAddress
,PaymentArrangementAmount
,CASE WHEN PaymentArrangementFrequency='m' THEN 'Monthly'
	  WHEN PaymentArrangementFrequency='w' THEN 'Weekly'
	  WHEN PaymentArrangementFrequency='f' THEN 'Fortnightly'
	  WHEN PaymentArrangementFrequency='q' THEN 'Quarterly'
	   WHEN PaymentArrangementFrequency='y' THEN 'Annually' END  AS PaymentArrangementFrequency
,CASE WHEN PaymentArrangementNextDate='1900-01-01' THEN NULL ELSE PaymentArrangementNextDate END AS PaymentArrangementNextDate
,CASE WHEN PaymentArrangementSetupDate='1900-01-01' THEN NULL ELSE PaymentArrangementSetupDate END AS PaymentArrangementSetupDate
,CASE WHEN PaymentArrangementStartDate='1900-01-01' THEN NULL ELSE PaymentArrangementStartDate END AS PaymentArrangementStartDate
,CASE WHEN FileStatus='COMP' THEN 'Closed' ELSE 'Open' END AS FileStatus
,CAS08
FROM VFile_Streamlined.dbo.AccountInformation AS a
LEFT JOIN (
	SELECT mt_int_code, ud_field##8 AS CAS08 
	FROM [Vfile_streamlined].dbo.uddetail
	WHERE uds_type='CAS'
		) AS CAS ON a.mt_int_code=CAS.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS b
 ON  a.mt_int_code=b.mt_int_code
LEFT OUTER JOIN (SELECT DebtorInformation.mt_int_code,ISNULL(Title,'')  + ' ' + ISNULL(Forename,'')  + ' ' + ISNULL(Surname,'')  AS Debtor
,ISNULL(Address1,'') + ' ' + ISNULL(Address2,'')  + ' ' + ISNULL(Address3,'')  + ' ' + ISNULL(Address4,'')  + ' ' + ISNULL(PostCode,'')  AS [DebtorAddress]
FROM VFile_Streamlined.dbo.DebtorInformation
INNER JOIN VFile_Streamlined.dbo.AccountInformation ON DebtorInformation.mt_int_code=AccountInformation.mt_int_code
WHERE ContactType='Primary Debtor'
AND ClientName LIKE '%MIB%') AS Addresses
 ON A.mt_int_code=Addresses.mt_int_code

LEFT OUTER JOIN ( SELECT   
                   Data.mt_int_code AS mtintCode,
                   PYR_PaymentAmount ,
                   PYR_PaymentDate, 
                   PYR_PaymentType
                
          FROM (      
                 SELECT    Payments.mt_int_code ,
                           PYR_PaymentAmount ,
                           PYR_PaymentDate, 
                           PYR_PaymentType,
                  ROW_NUMBER ( ) OVER (PARTITION BY Payments.mt_int_code  ORDER BY PYR_PaymentDate  DESC) RowId
                 
                    FROM   VFile_Streamlined.dbo.Payments AS Payments
                    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                     ON Payments.mt_int_code=AccountInfo.mt_int_code
                     
                         WHERE PYR_PaymentType <> 'Historical Payment'
                         AND ClientName LIKE '%MIB%'
                        
                 ) AS Data 
                            
                  WHERE Data.RowId = 1     
                
                ) AS  LastPayment 
        ON    a.mt_int_code = LastPayment.mtintCode 
LEFT OUTER JOIN 
(
SELECT   
                   Data.mt_int_code AS mtintCode,
                    SCH_date_inserted,
                           SCH_date_due,
                           SCH_desc_awaiting
                
          FROM (      
                 SELECT    Schedule.mt_int_code ,
                           SCH_date_inserted,
                           SCH_date_due,
                           SCH_desc_awaiting,
                  ROW_NUMBER ( ) OVER (PARTITION BY Schedule.mt_int_code  ORDER BY SCH_date_inserted  DESC) RowId
                 
                    FROM   VFile_Streamlined.dbo.Schedule
                    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                     ON Schedule.mt_int_code=AccountInfo.mt_int_code
                     
                         WHERE ClientName LIKE '%MIB%'
                        
                 ) AS Data 
                            
                  WHERE Data.RowId = 1   
) AS Schedule
 ON a.mt_int_code=Schedule.mtintCode
LEFT OUTER JOIN 
(
SELECT History.mt_int_code,History.HTRY_DateInserted AS LastHistoryNoteDate
,History.HTRY_description AS LastHistoryDescription FROM VFile_Streamlined.dbo.History
INNER JOIN 
(
SELECT History.mt_int_code,MAX(HTRY_HistoryNo) AS HistoryNo FROM VFile_Streamlined.dbo.History AS History
INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
 ON History.mt_int_code=AccountInfo.mt_int_code
WHERE ClientName LIKE '%MIB%'
GROUP BY History.mt_int_code
) AS HistoryNotes
ON History.mt_int_code=HistoryNotes.mt_int_code
AND History.HTRY_HistoryNo=HistoryNotes.HistoryNo

) AS HistoryNotes
ON a.mt_int_code=HistoryNotes.mt_int_code
LEFT OUTER JOIN ( SELECT    ledger.mt_int_code AS ID ,
                                    SUM(ledger.Amount) AS DisbsIncurred
                          FROM      VFile_Streamlined.dbo.DebtLedger AS ledger
                          WHERE     ledger.TransactionType <> 'CR'
                                    AND DebtOrLedger = 'Ledger'
                              --AND PostedDate<@StartDate
                          GROUP BY  ledger.mt_int_code
                        ) AS DisbsIncurred ON a.mt_int_code = DisbsIncurred.ID
        LEFT OUTER JOIN ( SELECT    debt.mt_int_code AS ID ,
                                    SUM(debt.amount) AS CostsIncurred
                          FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                          WHERE     debt.TransactionType = 'COST'
                                    AND DebtOrLedger = 'Debt'
                          GROUP BY  debt.mt_int_code
                        ) AS CostsIncurred ON a.mt_int_code = CostsIncurred.ID
 LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                        SUM(PYR_AmountDisbursementPaid) AS DisPaid ,
                                        SUM(PYR_AmountRecoverableCostsPaid) AS SOLPaid
                              FROM      VFile_Streamlined.dbo.Payments AS SOLPYR
                              GROUP BY  mt_int_code
                            ) AS DISPSOLPAID ON a.mt_int_code = DISPSOLPAID.mt_int_code
                           LEFT OUTER JOIN 
                           (
                           SELECT mt_int_code,SUM(PYR_PaymentAmount) AS TotalToDate
                           ,SUM(PYR_AmountPaidToWeightmansExcVAT) AS PYR_AmountPaidToWeightmansExcVAT
                           FROM VFile_Streamlined.dbo.Payments AS Payments
                           WHERE PYR_PaymentType <> 'Historical Payment'
                           GROUP BY mt_int_code
                           ) AS PaidToDate
                            ON a.mt_int_code=PaidToDate.mt_int_code
                            LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON a.mt_int_code=ADA.mt_int_code
			LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON 
			--RTRIM(REPLACE(level_fee_earner,'LIT/DEBT/MIB/',''))
			
			RIGHT(level_fee_earner,3)=fee_earner
  LEFT OUTER  JOIN (
              SELECT  ----- Instructed value
                        mt_int_code
                      , SUM(Amount) AS InstructedValue
              FROM      Vfile_Streamlined.dbo.DebtLedger
              WHERE     DebtOrLedger = 'Debt'
                        AND TransactionType = 'invo'
              GROUP BY  mt_int_code
              
            ) AS Instructed_Value
        ON a.mt_int_code  = Instructed_Value.mt_int_code
        LEFT OUTER JOIN (
                   SELECT --- Payments to client and the other one
                            mt_int_code
                          , SUM(paidtoclient) AS paidtoclient
                          , SUM(paidtoagent) AS paidtoagent
                   FROM     (
                              SELECT    a.[mt_int_code]
                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'yes'
                                             THEN SUM(PYR_PaymentAmount)
                                             ELSE 0
                                        END AS paidtoclient
                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'No'
                                             THEN SUM(PYR_PaymentAmount)
                                             ELSE 0
                                        END AS paidtoagent
                              FROM      VFile_Streamlined.dbo.Payments AS payment
                              INNER JOIN VFile_Streamlined.dbo.AccountInformation AS a
                               ON payment.mt_int_code=a.mt_int_code
                              WHERE ClientName LIKE '%MIB%'
                      
                              GROUP BY  a.[mt_int_code]
                                      , PYR_PaymentTakenByClient
                            ) AllPayments
                   GROUP BY mt_int_code
                 ) AS AggregatePayments
        ON a.mt_int_code  = AggregatePayments.mt_int_code
        LEFT OUTER JOIN
(
SELECT AccountInfo.mt_int_code
,CASE WHEN FileStatus='COMP' THEN xPenultimateMilestone ELSE MilestoneCode END AS MilestoneCode

FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
LEFT OUTER JOIN (
                      SELECT    mt_int_code
                              , [MS_HTRY_MstoneCode] AS xPenultimateMilestone
                      FROM      (
                                  SELECT    mstone_history.[mt_int_code]
                                          , mstone_history.[MS_HTRY_MstoneCode]
                                          , ROW_NUMBER() OVER ( PARTITION BY mstone_history.[mt_int_code] ORDER BY mstone_history.[PROGRESS_RECID_IDENT_] DESC ) AS ranking
                                  FROM      [VFile_Streamlined].dbo.[Mstone_History] mstone_history
                                  INNER JOIN [VFile_Streamlined].dbo.[matdb]
                                            ON mstone_history.[mt_int_code] = matdb.[mt_int_code]
                                               AND matdb.[mstone_code] = 'comp'
                                  GROUP BY  mstone_history.[mt_int_code]
                                          , mstone_history.[MS_HTRY_MstoneCode]
                                          , mstone_history.[progress_recid_ident_]
                                ) AS Milestone
                      WHERE     ranking = 1
                    ) AS PenultimateMilestone
            ON AccountInfo.mt_int_code = PenultimateMilestone.mt_int_code
            ) AS Commission  
            ON a.mt_int_code=Commission.mt_int_code
      LEFT OUTER JOIN (
                   SELECT --Court fees 
       --needs to be a left join  because there is no guarantee of any court costs for a meter
                            mt_int_code
                          , SUM([ledger].[Amount]) AS courtfees
                   FROM     Vfile_Streamlined.dbo.DebtLedger AS ledger WITH ( NOLOCK )
                   WHERE    [TransactionType] = 'op'
                            AND DebtorLedger = 'Ledger'
                            AND ItemCode IN ( 'aeof', 'affa', 'allo', 'ccbi',
                                              'ccbw', 'ccif', 'choc', 'ci10',
                                              'ci11', 'ci20', 'ci23', 'ci24',
                                              'ci31', 'ci43', 'ci50', 'ci73',
                                              'hcif', 'oeif', 'rcif', 'rhif',
                                              'wcif' )
                     
                   GROUP BY mt_int_code
                 ) AS LedgerFees
        ON a.mt_int_code  = LedgerFees.mt_int_code
        LEFT OUTER JOIN (  
                  SELECT
                   mt_int_code
                 ,SUM(Ledger.[Amount]) AS landreg
   
    FROM [VFile_Streamlined].dbo.[DebtLedger] AS Ledger  WITH ( NOLOCK )
    WHERE
        [TransactionType] = 'op'
        AND DebtOrLedger = 'Ledger'
        AND ItemCode IN ('cauf', 'coaf', 'roic', 'rorf')

    GROUP BY
        mt_int_code  ) AS LandRegDisbursements
     ON  a.mt_int_code = LandRegDisbursements. mt_int_code 
     LEFT OUTER JOIN (
        SELECT
         mt_int_code
        ,SUM([ledger].[Amount]) AS disbursements
   
    FROM
        [VFile_streamlined].dbo.[DebtLedger] AS Ledger WITH (NOLOCK)
    WHERE
       TransactionType = 'op'
       AND DebtOrLedger = 'Ledger'
       AND ItemCode NOT IN ('aeof', 'affa', 'allo', 'ccbi', 'ccbw', 'ccif',
                            'choc', 'ci10', 'ci11', 'ci20', 'ci23', 'ci24',
                            'ci31', 'ci43', 'ci50', 'ci73', 'hcif', 'oeif',
                            'rcif', 'rhif', 'wcif', 'cauf', 'coaf', 'roic',
                            'rorf')
  
    GROUP BY
        [ledger].mt_int_code     
     ) AS AllDisbursements_
     ON a.mt_int_code =  AllDisbursements_. mt_int_code
     
     WHERE ClientName LIKE '%MIB%'
      --AND MIB_ClaimNumber='1703637'
) AS AllData
INNER JOIN #Placement AS Placement ON Placement.ListValue COLLATE DATABASE_DEFAULT = AllData.Placement COLLATE DATABASE_DEFAULT
INNER JOIN #Status AS [Status] ON [Status].ListValue COLLATE DATABASE_DEFAULT = AllData.FileStatus COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN ( SELECT mt_int_code AS mt_int_code ,
                            RTRIM(ud_field##2) AS RetentionReason,
                            CONVERT(DATE,RTRIM(ud_field##3),103) AS DateRetained
                     FROM   VFile_Streamlined.dbo.uddetail
                     WHERE  uds_type = 'MIR'
                            AND ud_field##1 = 'Yes'
                   ) AS Retention ON AllData.mtintcode = Retention.mt_int_code 

END
GO
