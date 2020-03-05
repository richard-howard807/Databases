SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










-- =========================================================
-- Author:Peter Asemota
-- Date: 2010/11/16
--
-- Description:MIB collections report using Vfile_streamlined
-- =========================================================
CREATE PROCEDURE [VisualFiles].[MIBCollectionsReport] --EXEC [VisualFiles].[MIBCollectionsReport] '2019-01-13','2019-01-19','MIB'
      @StartDate  DATE
    , @EndDate  DATE
    , @ClientName AS VARCHAR(MAX)

AS 

--DECLARE @StartDate  DATE
--DECLARE @EndDate  DATE
--DECLARE @ClientName AS VARCHAR(MAX)

--SET @StartDate='2019-08-30'
--SET @EndDate='2019-09-18'

--SET @ClientName='MIB'


IF OBJECT_ID('tempdb..#Commission') IS NOT NULL DROP TABLE #Commission

SELECT AccountInfo.mt_int_code
,CASE WHEN FileStatus='COMP' THEN xPenultimateMilestone ELSE MilestoneCode END AS MilestoneCode
INTO #Commission
FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
LEFT OUTER JOIN (
                      SELECT    mt_int_code
                              , [MS_HTRY_MstoneCode] AS xPenultimateMilestone
                      FROM      (
                                  SELECT    mstone_history.[mt_int_code]
                                          , mstone_history.[MS_HTRY_MstoneCode]
                                          , ROW_NUMBER() OVER ( PARTITION BY mstone_history.[mt_int_code] ORDER BY mstone_history.[PROGRESS_RECID_IDENT_] DESC ) AS ranking
                                  FROM      [VFile_Streamlined].dbo.[Mstone_History] mstone_history
								  INNER JOIN VFile_Streamlined.dbo.AccountInformation
								   ON AccountInformation.mt_int_code = mstone_history.mt_int_code
                                  INNER JOIN [VFile_Streamlined].dbo.[matdb]
                                            ON mstone_history.[mt_int_code] = matdb.[mt_int_code]
                                               AND matdb.[mstone_code] = 'comp'
								  WHERE ClientName=@ClientName
                                  GROUP BY  mstone_history.[mt_int_code]
                                          , mstone_history.[MS_HTRY_MstoneCode]
                                          , mstone_history.[progress_recid_ident_]
                                ) AS Milestone
                      WHERE     ranking = 1
                    ) AS PenultimateMilestone
            ON AccountInfo.mt_int_code = PenultimateMilestone.mt_int_code
			WHERE AccountInfo.ClientName=@ClientName

 
SELECT 
         LEFT(DATENAME(MONTH, Maindetails.BatchDate), 3) + '-'
        + CAST(YEAR(Maindetails.BatchDate) AS VARCHAR(4)) AS batchdate
     -- , Maindetails.mt_int_code
      , Maindetails.BatchNumber AS batchNo
      --, Maindetails.NameOfDebtorOnLetter As defendant
      , MIB_DefendantSurname AS defendant
      , Maindetails.agentref
      , Maindetails.claimnumber
     -- , Maindetails.BatchDate
      ,CASE WHEN Commission. MilestoneCode IN ('inst', 'bankstat') THEN 15 ELSE 20 END AS commission
      , Instructed_Value.InstructedValue AS instructedvalue
      , Total_InstructedValue.totalinstructedvalue
      , paidtoagent AS paidtoagent
      , paidtoclient AS paidtoclient
      ,CurrentBalance AS CurrentBalance
      ,CASE WHEN LedgerFees.courtfees IS NULL THEN 0 ELSE LedgerFees.courtfees END AS courtfees
      ,CASE WHEN Costs_.costs IS NULL THEN 0 ELSE Costs_.costs END AS Costs
      ,CASE WHEN AllDisbursements_.disbursements IS NULL THEN 0 ELSE AllDisbursements_.disbursements  END AS disbursements
      ,CASE WHEN LandRegDisbursements.landreg IS NULL THEN 0 ELSE LandRegDisbursements.landreg END AS landreg
	  ,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END  AS [ADA28]
	,DateOpened
	,Maindetails.FileStatus
 
FROM  (
              SELECT    Clients.mt_int_code AS mt_int_code
                      , Clients.MIB_BatchNumber AS BatchNumber
                      , SOLADM.ADM_NameOfDebtorOnLetter AS NameOfdebtorOnLetter
                      , RIGHT(AccountInfo.[level_fee_earner], 3) + ' / '
                        + CAST(AccountInfo.MatterCode  AS VARCHAR (30)) AS Agentref
                      , Clients.MIB_ClaimNumber AS ClaimNumber
                      , Clients.MIE_BatchDate AS Batchdate
                      ,CurrentBalance AS CurrentBalance
                      ,MIB_DefendantSurname
					  ,AccountInfo.DateOpened
					  ,AccountInfo.FileStatus
              FROM     [Vfile_streamlined].dbo.AccountInformation AS AccountInfo WITH ( NOLOCK )
              INNER JOIN Vfile_streamlined.dbo.ClientScreens AS Clients WITH ( NOLOCK )
                        ON AccountInfo.mt_int_code = Clients.mt_int_code
              INNER JOIN [Vfile_streamlined].dbo.SOLADM AS SOLADM  
                       ON AccountInfo.mt_int_code = SOLADM.mt_int_code
              WHERE     
              --Clients.MIB_DateOfInstruction <> '01-jan-1900'
              --          AND Clients.MIB_ClaimNumber IS NOT NULL
              --          AND Clients.MIB_ClaimNumber <> ''
              --          AND 
              ClientName =@ClientName
        
            ) AS Maindetails

 LEFT OUTER  JOIN (
              SELECT  ----- Instructed value
                        DebtLedger.mt_int_code
                      , SUM(Amount) AS InstructedValue
              FROM      Vfile_Streamlined.dbo.DebtLedger
			  INNER JOIN VFile_Streamlined.dbo.AccountInformation
			   ON AccountInformation.mt_int_code = DebtLedger.mt_int_code
              WHERE     DebtOrLedger = 'Debt'
                        AND TransactionType = 'invo'
						AND ClientName =@ClientName
              GROUP BY  DebtLedger.mt_int_code
              
            ) AS Instructed_Value
        ON Maindetails.mt_int_code  = Instructed_Value.mt_int_code

LEFT JOIN (
			SELECT uddetail.mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			INNER JOIN VFile_Streamlined.dbo.AccountInformation
			 ON AccountInformation.mt_int_code = uddetail.mt_int_code
			WHERE uds_type='ADA'
			AND ClientName =@ClientName
			) AS ADA ON Maindetails.mt_int_code=ADA.mt_int_code

 LEFT OUTER  JOIN (
              SELECT  --- Total Instructed value
                        DEBT.mt_int_code
                      , SUM(amount) AS totalinstructedvalue
              FROM      Vfile_Streamlined.dbo.DebtLedger DEBT WITH ( NOLOCK )
			  INNER JOIN VFile_Streamlined.dbo.AccountInformation
			   ON AccountInformation.mt_int_code = DEBT.mt_int_code
              WHERE     TransactionType = 'invo'
                        AND DebtOrLedger = 'debt'
						AND ClientName =@ClientName
              GROUP BY  DEBT.mt_int_code
              
            ) AS Total_InstructedValue
        ON Maindetails.mt_int_code = Total_InstructedValue.mt_int_code
 LEFT OUTER JOIN (
                   SELECT --- Payments to client and the other one
                            mt_int_code
                          , SUM(paidtoclient) AS paidtoclient
                          , SUM(paidtoagent) AS paidtoagent
                   FROM     (
                              SELECT    [mt_int_code]
                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'yes'
                                             THEN SUM(PYR_PaymentAmount)
                                             ELSE 0
                                        END AS paidtoclient
                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'No'
                                             THEN SUM(PYR_PaymentAmount)
                                             ELSE 0
                                        END AS paidtoagent
                              FROM      VFile_Streamlined.dbo.Payments AS payment
                                        WITH ( NOLOCK )
                              WHERE     [PYR_PaymentDate] >= @StartDate
                                        AND [PYR_PaymentDate] <= @EndDate
                              GROUP BY  [mt_int_code]
                                      , PYR_PaymentTakenByClient
                            ) AllPayments
                   GROUP BY mt_int_code
                 ) AS AggregatePayments
        ON Maindetails.mt_int_code  = AggregatePayments.mt_int_code
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
                            AND [PostedDate] >= @StartDate
                            AND [PostedDate] <= @EndDate
                   GROUP BY mt_int_code
                 ) AS LedgerFees
        ON Maindetails.mt_int_code  = LedgerFees.mt_int_code
 LEFT OUTER JOIN (
                   SELECT --  costs
--    needs to be a left join because there is no guarantee of any costs for a matter
                            mt_int_code
                          , SUM(Debt.Amount) AS costs
                   FROM     Vfile_Streamlined.dbo.DebtLedger AS Debt WITH ( NOLOCK )
                   WHERE    Debt.TransactionType = 'cost'
                            AND DebtorLedger = 'Debt'
                            AND PostedDate >= @StartDate
                            AND PostedDate <= @EndDate
                   GROUP BY mt_int_code
                 ) AS Costs_

      ON Maindetails.mt_int_code  = Costs_.mt_int_code
LEFT OUTER JOIN (  
                  SELECT
                   mt_int_code
                 ,SUM(Ledger.[Amount]) AS landreg
   
    FROM [VFile_Streamlined].dbo.[DebtLedger] AS Ledger  WITH ( NOLOCK )
    WHERE
        [TransactionType] = 'op'
        AND DebtOrLedger = 'Ledger'
        AND ItemCode IN ('cauf', 'coaf', 'roic', 'rorf')
        AND [PostedDate] >= @StartDate
        AND [PostedDate] <= @EndDate
    GROUP BY
        mt_int_code  ) AS LandRegDisbursements
     ON  Maindetails.mt_int_code = LandRegDisbursements. mt_int_code 

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
        AND PostedDate >= @StartDate
        AND PostedDate <= @EndDate
    GROUP BY
        [ledger].mt_int_code     
     ) AS AllDisbursements_
     ON Maindetails.mt_int_code =  AllDisbursements_. mt_int_code

LEFT OUTER JOIN(SELECT mt_int_code, MilestoneCode FROM #Commission
            ) AS Commission  
            ON maindetails.mt_int_code=Commission.mt_int_code
       WHERE paidtoclient  IS NOT NULL 
       OR paidtoagent IS NOT NULL






--    set nocount on
--    set transaction isolation level read uncommitted

 
--SELECT 
--         LEFT(DATENAME(MONTH, Maindetails.BatchDate), 3) + '-'
--        + CAST(YEAR(Maindetails.BatchDate) AS VARCHAR(4)) AS batchdate
--     -- , Maindetails.mt_int_code
--      , Maindetails.BatchNumber AS batchNo
--      --, Maindetails.NameOfDebtorOnLetter As defendant
--      , MIB_DefendantSurname AS defendant
--      , Maindetails.agentref
--      , Maindetails.claimnumber
--     -- , Maindetails.BatchDate
--      ,CASE WHEN Commission. MilestoneCode IN ('inst', 'bankstat') THEN 15 ELSE 20 END AS commission
--      , Instructed_Value.InstructedValue AS instructedvalue
--      , Total_InstructedValue.totalinstructedvalue
--      , paidtoagent AS paidtoagent
--      , paidtoclient AS paidtoclient
--      ,CurrentBalance AS CurrentBalance
--      ,CASE WHEN LedgerFees.courtfees IS NULL THEN 0 ELSE LedgerFees.courtfees END AS courtfees
--      ,CASE WHEN Costs_.costs IS NULL THEN 0 ELSE Costs_.costs END AS Costs
--      ,CASE WHEN AllDisbursements_.disbursements IS NULL THEN 0 ELSE AllDisbursements_.disbursements  END AS disbursements
--      ,CASE WHEN LandRegDisbursements.landreg IS NULL THEN 0 ELSE LandRegDisbursements.landreg END AS landreg
--	  ,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
--WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
--WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END  AS [ADA28]
--	,DateOpened
 
--FROM  (
--              SELECT    Clients.mt_int_code AS mt_int_code
--                      , Clients.MIB_BatchNumber AS BatchNumber
--                      , SOLADM.ADM_NameOfDebtorOnLetter AS NameOfdebtorOnLetter
--                      , RIGHT(AccountInfo.[level_fee_earner], 3) + ' / '
--                        + CAST(AccountInfo.MatterCode  AS VARCHAR (30)) AS Agentref
--                      , Clients.MIB_ClaimNumber AS ClaimNumber
--                      , Clients.MIE_BatchDate AS Batchdate
--                      ,CurrentBalance AS CurrentBalance
--                      ,MIB_DefendantSurname
--					  ,AccountInfo.DateOpened
--              FROM     [Vfile_streamlined].dbo.AccountInformation AS AccountInfo WITH ( NOLOCK )
--              INNER JOIN Vfile_streamlined.dbo.ClientScreens AS Clients WITH ( NOLOCK )
--                        ON AccountInfo.mt_int_code = Clients.mt_int_code
--              INNER JOIN [Vfile_streamlined].dbo.SOLADM AS SOLADM  
--                       ON AccountInfo.mt_int_code = SOLADM.mt_int_code
--              WHERE     
--              --Clients.MIB_DateOfInstruction <> '01-jan-1900'
--              --          AND Clients.MIB_ClaimNumber IS NOT NULL
--              --          AND Clients.MIB_ClaimNumber <> ''
--              --          AND 
--              ClientName =@ClientName
        
--            ) AS Maindetails

-- LEFT OUTER  JOIN (
--              SELECT  ----- Instructed value
--                        DebtLedger.mt_int_code
--                      , SUM(Amount) AS InstructedValue
--              FROM      Vfile_Streamlined.dbo.DebtLedger
--			  INNER JOIN VFile_Streamlined.dbo.AccountInformation
--			   ON AccountInformation.mt_int_code = DebtLedger.mt_int_code
--              WHERE     DebtOrLedger = 'Debt'
--                        AND TransactionType = 'invo'
--						AND ClientName =@ClientName
--              GROUP BY  DebtLedger.mt_int_code
              
--            ) AS Instructed_Value
--        ON Maindetails.mt_int_code  = Instructed_Value.mt_int_code

--LEFT JOIN (
--			SELECT uddetail.mt_int_code, ud_field##28 AS [ADA28] 
--			FROM [Vfile_streamlined].dbo.uddetail
--			INNER JOIN VFile_Streamlined.dbo.AccountInformation
--			 ON AccountInformation.mt_int_code = uddetail.mt_int_code
--			WHERE uds_type='ADA'
--			AND ClientName =@ClientName
--			) AS ADA ON Maindetails.mt_int_code=ADA.mt_int_code

-- LEFT OUTER  JOIN (
--              SELECT  --- Total Instructed value
--                        DEBT.mt_int_code
--                      , SUM(amount) AS totalinstructedvalue
--              FROM      Vfile_Streamlined.dbo.DebtLedger DEBT WITH ( NOLOCK )
--			  INNER JOIN VFile_Streamlined.dbo.AccountInformation
--			   ON AccountInformation.mt_int_code = DEBT.mt_int_code
--              WHERE     TransactionType = 'invo'
--                        AND DebtOrLedger = 'debt'
--						AND ClientName =@ClientName
--              GROUP BY  DEBT.mt_int_code
              
--            ) AS Total_InstructedValue
--        ON Maindetails.mt_int_code = Total_InstructedValue.mt_int_code
-- LEFT OUTER JOIN (
--                   SELECT --- Payments to client and the other one
--                            mt_int_code
--                          , SUM(paidtoclient) AS paidtoclient
--                          , SUM(paidtoagent) AS paidtoagent
--                   FROM     (
--                              SELECT    [mt_int_code]
--                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'yes'
--                                             THEN SUM(PYR_PaymentAmount)
--                                             ELSE 0
--                                        END AS paidtoclient
--                                      , CASE WHEN [PYR_PaymentTakenByClient] = 'No'
--                                             THEN SUM(PYR_PaymentAmount)
--                                             ELSE 0
--                                        END AS paidtoagent
--                              FROM      VFile_Streamlined.dbo.Payments AS payment
--                                        WITH ( NOLOCK )
--                              WHERE     [PYR_PaymentDate] >= @StartDate
--                                        AND [PYR_PaymentDate] <= @EndDate
--                              GROUP BY  [mt_int_code]
--                                      , PYR_PaymentTakenByClient
--                            ) AllPayments
--                   GROUP BY mt_int_code
--                 ) AS AggregatePayments
--        ON Maindetails.mt_int_code  = AggregatePayments.mt_int_code
-- LEFT OUTER JOIN (
--                   SELECT --Court fees 
--       --needs to be a left join  because there is no guarantee of any court costs for a meter
--                            mt_int_code
--                          , SUM([ledger].[Amount]) AS courtfees
--                   FROM     Vfile_Streamlined.dbo.DebtLedger AS ledger WITH ( NOLOCK )
--                   WHERE    [TransactionType] = 'op'
--                            AND DebtorLedger = 'Ledger'
--                            AND ItemCode IN ( 'aeof', 'affa', 'allo', 'ccbi',
--                                              'ccbw', 'ccif', 'choc', 'ci10',
--                                              'ci11', 'ci20', 'ci23', 'ci24',
--                                              'ci31', 'ci43', 'ci50', 'ci73',
--                                              'hcif', 'oeif', 'rcif', 'rhif',
--                                              'wcif' )
--                            AND [PostedDate] >= @StartDate
--                            AND [PostedDate] <= @EndDate
--                   GROUP BY mt_int_code
--                 ) AS LedgerFees
--        ON Maindetails.mt_int_code  = LedgerFees.mt_int_code
-- LEFT OUTER JOIN (
--                   SELECT --  costs
----    needs to be a left join because there is no guarantee of any costs for a matter
--                            mt_int_code
--                          , SUM(Debt.Amount) AS costs
--                   FROM     Vfile_Streamlined.dbo.DebtLedger AS Debt WITH ( NOLOCK )
--                   WHERE    Debt.TransactionType = 'cost'
--                            AND DebtorLedger = 'Debt'
--                            AND PostedDate >= @StartDate
--                            AND PostedDate <= @EndDate
--                   GROUP BY mt_int_code
--                 ) AS Costs_

--      ON Maindetails.mt_int_code  = Costs_.mt_int_code
--LEFT OUTER JOIN (  
--                  SELECT
--                   mt_int_code
--                 ,SUM(Ledger.[Amount]) AS landreg
   
--    FROM [VFile_Streamlined].dbo.[DebtLedger] AS Ledger  WITH ( NOLOCK )
--    WHERE
--        [TransactionType] = 'op'
--        AND DebtOrLedger = 'Ledger'
--        AND ItemCode IN ('cauf', 'coaf', 'roic', 'rorf')
--        AND [PostedDate] >= @StartDate
--        AND [PostedDate] <= @EndDate
--    GROUP BY
--        mt_int_code  ) AS LandRegDisbursements
--     ON  Maindetails.mt_int_code = LandRegDisbursements. mt_int_code 

--LEFT OUTER JOIN (
--        SELECT
--         mt_int_code
--        ,SUM([ledger].[Amount]) AS disbursements
   
--    FROM
--        [VFile_streamlined].dbo.[DebtLedger] AS Ledger WITH (NOLOCK)
--    WHERE
--       TransactionType = 'op'
--       AND DebtOrLedger = 'Ledger'
--       AND ItemCode NOT IN ('aeof', 'affa', 'allo', 'ccbi', 'ccbw', 'ccif',
--                            'choc', 'ci10', 'ci11', 'ci20', 'ci23', 'ci24',
--                            'ci31', 'ci43', 'ci50', 'ci73', 'hcif', 'oeif',
--                            'rcif', 'rhif', 'wcif', 'cauf', 'coaf', 'roic',
--                            'rorf')
--        AND PostedDate >= @StartDate
--        AND PostedDate <= @EndDate
--    GROUP BY
--        [ledger].mt_int_code     
--     ) AS AllDisbursements_
--     ON Maindetails.mt_int_code =  AllDisbursements_. mt_int_code

--LEFT OUTER JOIN
--(
--SELECT AccountInfo.mt_int_code
--,CASE WHEN FileStatus='COMP' THEN xPenultimateMilestone ELSE MilestoneCode END AS MilestoneCode

--FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
--LEFT OUTER JOIN (
--                      SELECT    mt_int_code
--                              , [MS_HTRY_MstoneCode] AS xPenultimateMilestone
--                      FROM      (
--                                  SELECT    mstone_history.[mt_int_code]
--                                          , mstone_history.[MS_HTRY_MstoneCode]
--                                          , ROW_NUMBER() OVER ( PARTITION BY mstone_history.[mt_int_code] ORDER BY mstone_history.[PROGRESS_RECID_IDENT_] DESC ) AS ranking
--                                  FROM      [VFile_Streamlined].dbo.[Mstone_History] mstone_history
--                                  INNER JOIN [VFile_Streamlined].dbo.[matdb]
--                                            ON mstone_history.[mt_int_code] = matdb.[mt_int_code]
--                                               AND matdb.[mstone_code] = 'comp'
--                                  GROUP BY  mstone_history.[mt_int_code]
--                                          , mstone_history.[MS_HTRY_MstoneCode]
--                                          , mstone_history.[progress_recid_ident_]
--                                ) AS Milestone
--                      WHERE     ranking = 1
--                    ) AS PenultimateMilestone
--            ON AccountInfo.mt_int_code = PenultimateMilestone.mt_int_code
--			WHERE AccountInfo.ClientName=@ClientName
--            ) AS Commission  
--            ON maindetails.mt_int_code=Commission.mt_int_code
--       WHERE paidtoclient  IS NOT NULL 
--       OR paidtoagent IS NOT NULL
       
--    ORDER BY
--        YEAR(Maindetails.BatchDate)
--    ,   MONTH(Maindetails.BatchDate)
--    ,   maindetails.BatchNumber


--	OPTION	(RECOMPILE)

GO
