SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [VisualFiles].[MIBDisb]
(
@StartDate AS DATE
,@EndDate AS DATE
,@Placement AS NVARCHAR(MAX)
) 
AS
BEGIN
 
 SELECT * FROM (
 
   SELECT  HIM_AccountNumber AS AccountNo1
    ,AccountInfo.MatterCode
    ,CDE_ClientAccountNumber AS ClientAccountNumber
          , RIGHT(level_fee_earner, 3) + ' / '
            + CAST(MatterCode AS VARCHAR(10)) AS WeightmansRef
          , OriginalBalance AS OriginalBalance
          , CASE WHEN amountpaid.AmountPaid IS NULL THEN 0
                 ELSE AmountPaid.AmountPaid
            END AS Paid
          , CASE WHEN RecoverableCosts.RecoverableCosts IS NULL THEN 0
                 ELSE RecoverableCosts.RecoverableCosts
            END AS Recoverable
          , CASE WHEN Disbursements.Disbursements IS NULL THEN 0
                 ELSE Disbursements.Disbursements
            END AS Disbursements
          , ledger.ItemDescription AS narrative
          , ledger.Amount AS gross_value
          , trdef.description AS Description
          , ledger.PostedDate AS posted_date
          , CAS_BatchNumber AS CAS01
          , CASE WHEN DebtorName IS NULL OR DebtorName='' THEN Short_name ELSE DebtorName END AS DebtorName
          , AccountInfo.ClientName AS [Client Name]
          , AccountInfo.SubClient AS [Sub Client Name]
          ,'Recoverable' AS ReportType
          ,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END [Placement]
    FROM    VFile_Streamlined.dbo.DebtLedger AS Ledger
    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            ON ledger.mt_int_code = AccountInfo.mt_int_code
               AND DebtOrLedger = 'Ledger'
    INNER JOIN VFile_Streamlined.dbo.trdef
            ON ledger.ItemCode = trdef.tr_code
               AND Recoverable = 1
    LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
            ON ledger.mt_int_code = Clients.mt_int_code
    LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
     ON Ledger.mt_int_code=SOLCDE.mt_int_code
    LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(ISNULL(Title,'')) + RTRIM(ISNULL(Forename,'')) + ' ' + RTRIM(ISNULL(Surname,'')) AS DebtorName
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Primary Debtor') AS Debtor
	ON Ledger.mt_int_code=Debtor.mt_int_code
    LEFT  OUTER JOIN (
                       SELECT   SOLPYR.mt_int_code
                              , SUM(PYR_PaymentAmount) AS amountpaid
                       FROM     VFile_Streamlined.dbo.Payments AS SOLPYR
                       WHERE    PYR_PaymentType NOT IN ( 'Historical Payment' )
                       GROUP BY SOLPYR.mt_int_code
                     ) amountpaid
            ON AccountInfo.mt_int_code = amountpaid.mt_int_code
    LEFT OUTER JOIN (
                      SELECT    debt.mt_int_code
                              , SUM(debt.amount) AS RecoverableCosts
                      FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                      WHERE     debt.TransactionType = 'COST'
                                AND DebtOrLedger = 'Debt'
                      GROUP BY  debt.mt_int_code
                    ) recoverablecosts
            ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
    LEFT OUTER JOIN (
                      SELECT    Ledger.mt_int_code
                              , SUM(Ledger.Amount) AS Disbursements
                      FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
                      WHERE     Ledger.TransactionType IN ( 'OP', 'OPVU' )
                                AND DebtOrLedger = 'Ledger'
                      GROUP BY  Ledger.mt_int_code
                    ) disbursements
            ON AccountInfo.mt_int_code = disbursements.mt_int_code
             LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON Accountinfo.mt_int_code=ADA.mt_int_code

    WHERE   ledger.PostedDate >= @StartDate
            AND ledger.PostedDate <= @EndDate
            AND ClientName LIKE 'MIB%'
             
             UNION All
             
                 SELECT  HIM_AccountNumber AS AccountNo1
                     ,AccountInfo.MatterCode
    ,CDE_ClientAccountNumber AS ClientAccountNumber
          , RIGHT(level_fee_earner, 3) + ' / '
            + CAST(MatterCode AS VARCHAR(10)) AS WeightmansRef
          , OriginalBalance AS OriginalBalance
          , CASE WHEN amountpaid.AmountPaid IS NULL THEN 0
                 ELSE AmountPaid.AmountPaid
            END AS Paid
          , CASE WHEN RecoverableCosts.RecoverableCosts IS NULL THEN 0
                 ELSE RecoverableCosts.RecoverableCosts
            END AS Recoverable
          , CASE WHEN Disbursements.Disbursements IS NULL THEN 0
                 ELSE Disbursements.Disbursements
            END AS Disbursements
          , ledger.ItemDescription AS narrative
          , ledger.Amount AS gross_value
          , trdef.description AS Description
          , ledger.PostedDate AS posted_date
          , CAS_BatchNumber AS CAS01
          , CASE WHEN DebtorName IS NULL OR DebtorName='' THEN Short_name ELSE DebtorName END AS DebtorName
          , AccountInfo.ClientName AS [Client Name]
          , AccountInfo.SubClient AS [Sub Client Name]
          ,'Unrecoverable' AS ReportType
          ,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END [Placement]
    FROM    VFile_Streamlined.dbo.DebtLedger AS Ledger
    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            ON ledger.mt_int_code = AccountInfo.mt_int_code
               AND DebtOrLedger = 'Ledger'
    INNER JOIN VFile_Streamlined.dbo.trdef
            ON ledger.ItemCode = trdef.tr_code
               AND Recoverable = 0
    LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
            ON ledger.mt_int_code = Clients.mt_int_code
    LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
     ON Ledger.mt_int_code=SOLCDE.mt_int_code
    LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(ISNULL(Title,'')) + RTRIM(ISNULL(Forename,'')) + ' ' + RTRIM(ISNULL(Surname,'')) AS DebtorName
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Primary Debtor') AS Debtor
	ON Ledger.mt_int_code=Debtor.mt_int_code
    LEFT  OUTER JOIN (
                       SELECT   SOLPYR.mt_int_code
                              , SUM(PYR_PaymentAmount) AS amountpaid
                       FROM     VFile_Streamlined.dbo.Payments AS SOLPYR
                       WHERE    PYR_PaymentType NOT IN ( 'Historical Payment' )
                       GROUP BY SOLPYR.mt_int_code
                     ) amountpaid
            ON AccountInfo.mt_int_code = amountpaid.mt_int_code
    LEFT OUTER JOIN (
                      SELECT    debt.mt_int_code
                              , SUM(debt.amount) AS RecoverableCosts
                      FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                      WHERE     debt.TransactionType = 'COST'
                                AND DebtOrLedger = 'Debt'
                      GROUP BY  debt.mt_int_code
                    ) recoverablecosts
            ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
    LEFT OUTER JOIN (
                      SELECT    Ledger.mt_int_code
                              , SUM(Ledger.Amount) AS Disbursements
                      FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
                      WHERE     Ledger.TransactionType IN ( 'OP', 'OPVU' )
                                AND DebtOrLedger = 'Ledger'
                      GROUP BY  Ledger.mt_int_code
                    ) disbursements
            ON AccountInfo.mt_int_code = disbursements.mt_int_code
             LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON Accountinfo.mt_int_code=ADA.mt_int_code

    WHERE   ledger.PostedDate >= @StartDate
            AND ledger.PostedDate <= @EndDate
            AND ClientName LIKE 'MIB%'
           ) AS AllData
           WHERE [Placement]=@Placement
           
END
GO
