SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [CommercialRecoveries].[MIBInsurerPayments]		
--EXEC [CommercialRecoveries].[MIBInsurerPayments] '2019-01-01','2019-12-06','MIB'
(
@StartDate AS DATE
,@EndDate AS DATE
,@ClientName AS VARCHAR(MAX)
)

AS
BEGIN
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE

--SET @StartDate='2011-01-01'
--SET @EndDate=GETDATE()

SELECT  Commission.mt_int_code ,
        MIB_ClaimNumber AS ClaimNumber ,
        RTRIM(MIB_DefendantForeName) + ' ' + RTRIM(MIB_DefendantSurname) AS Nameofdefendant ,
        Commission.OriginalBalance AS OriginalBalance ,
        NameOfInsurer AS NameofInsurer ,
        PolicyNumber AS InsuranceReferenceNumber ,
        ContactNumber AS ContactNumber-- (Insurer)
        ,
        SettlementAmount AS TotalAmountPaidByInsurer ,
        DateofPayment AS DatePaidByInsurer
        ,CostsIncurred
        ,CASE WHEN Commission.MilestoneCode IN ('inst', 'bankstat') THEN 15 ELSE 20 END AS commission
		,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END AS [ADA28]
FROM    ( SELECT    history.mt_int_code ,
                    HTRY_dateinserted AS DateofPayment ,
                    CAST(REPLACE(REPLACE(HTRY_description,
                                         'MIB Insurance Payment Made of ', ''),
                                 '£', '') AS DECIMAL(10, 2)) AS SettlementAmount
          FROM      VFile_Streamlined.dbo.History AS History
                    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInformation ON History.mt_int_code = AccountInformation.mt_int_code
          WHERE     HTRY_description LIKE 'MIB Insurance Payment Made of %'
        ) AS AllData
        INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Client ON AllData.mt_int_code = Client.mt_int_code
        --INNER JOIN VFile_Streamlined.dbo.AccountInformation AS Account ON Client.mt_int_code = Account.mt_int_code
         LEFT OUTER JOIN ( SELECT    debt.mt_int_code AS ID ,
                                    SUM(debt.amount) AS CostsIncurred
                          FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                          WHERE     debt.TransactionType = 'COST'
                                    AND DebtOrLedger = 'Debt'
                                   
                          GROUP BY  debt.mt_int_code
                        ) AS CostsIncurred ON AllData.mt_int_code = CostsIncurred.ID

		LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON AllData.mt_int_code=ADA.mt_int_code

             LEFT OUTER JOIN ( SELECT    mt_int_code,
									ud_field##1 AS NameOfInsurer ,
                                    ud_field##2 AS PolicyNumber ,
                                    ud_field##3 AS ContactNumber
                          FROM      VFile_Streamlined.dbo.uddetail AS SOLMII
                          WHERE     uds_type = 'MII'
                        ) AS SOLMII ON AllData.mt_int_code = SOLMII.mt_int_code
                        
                        LEFT OUTER JOIN
(
SELECT AccountInfo.mt_int_code, AccountInfo.OriginalBalance, AccountInfo.ClientName
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
            ON AllData.mt_int_code=Commission.mt_int_code
WHERE   ClientName = @ClientName
AND DateofPayment BETWEEN @StartDate AND @EndDate
AND AllData.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMattersSuccess)

UNION ALL


SELECT  dbFile.fileID
,txtClaimRef AS ClaimNumber
,RTRIM(txtDefFor) + ' ' + RTRIM(txtDefSur) AS Nameofdefendant
,curOriginalBal AS OriginalBalance 
, txtNmeOfInsurer AS NameofInsurer 
,txtPolicyNum1 AS InsuranceReferenceNumber 
,txtContactNum AS ContactNumber
,SettlementAmount AS TotalAmountPaidByInsurer
,[red_dw].[dbo].[datetimelocal](DateofPayment) AS DatePaidByInsurer
,CostsIncurred
,NULL AS comission
,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END AS [ADA28]
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN (
              SELECT fileID
               , dteInserted AS DateofPayment 
               , CAST(REPLACE(REPLACE(txtDescription,
                 'MIB Insurance Payment Made of ', ''),
                '£', '') AS DECIMAL(10, 2)) AS SettlementAmount
				FROM [MS_PROD].dbo.udCRHistoryNotesSL
				WHERE txtDescription LIKE 'MIB Insurance Payment Made of %'
              )    AS HistoryInfo
              ON HistoryInfo.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,SUM(curOffice) AS CostsIncurred FROM [MS_PROD].dbo.udCRLedgerSL WHERE cboCatDesc='2' GROUP BY fileID) AS Ledger
 ON Ledger.fileID = dbFile.fileID
WHERE clNo='M1001'
AND fileType='2038'
AND [red_dw].[dbo].[datetimelocal](HistoryInfo.DateofPayment) BETWEEN @StartDate AND @EndDate

END

GO
