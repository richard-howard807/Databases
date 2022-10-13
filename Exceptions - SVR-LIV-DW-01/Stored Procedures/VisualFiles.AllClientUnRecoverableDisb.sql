SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- exec [VisualFiles].[AllClientUnRecoverableDisb] '20140301','20140501','All'

CREATE PROCEDURE [VisualFiles].[AllClientUnRecoverableDisb]
    @StartDate	DATE
,   @EndDate	DATE
,   @ClientName	VARCHAR(50)
AS 
    set nocount on
    set transaction isolation level read uncommitted
IF @ClientName='All'
BEGIN
    SELECT  HIM_AccountNumber AS AccountNo1
    ,       RIGHT(level_fee_earner, 3) + ' / ' + CAST(MatterCode AS VARCHAR(10)) AS WeightmansRef
    ,       OriginalBalance AS OriginalBalance
    ,       CASE WHEN amountpaid.AmountPaid IS NULL THEN 0
                 ELSE AmountPaid.AmountPaid
            END AS Paid
    ,       CASE WHEN RecoverableCosts.RecoverableCosts IS NULL THEN 0
                 ELSE RecoverableCosts.RecoverableCosts
            END AS Recoverable
    ,       CASE WHEN Disbursements.Disbursements IS NULL THEN 0
                 ELSE Disbursements.Disbursements
            END AS Disbursements
    ,
		--CurrentBalance.Balance, 
            ledger.ItemDescription AS narrative
    ,       ledger.Amount AS gross_value
    ,       trdef.description AS Description
    ,       ledger.PostedDate AS posted_date
    ,       CAS_BatchNumber AS CAS01
    , CDE_ClientAccountNumber
    , CASE WHEN DebtorName IS NULL OR DebtorName='' THEN Short_name ELSE DebtorName END AS DebtorName
    , AccountInfo.ClientName as [Client Name]
    , AccountInfo.SubClient as [Sub Client Name]
    
    FROM    VFile_Streamlined.dbo.DebtLedger AS Ledger
    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
     ON ledger.mt_int_code = AccountInfo.mt_int_code AND DebtOrLedger='Ledger'
    INNER JOIN VFile_Streamlined.dbo.trdef 
            ON ledger.ItemCode = trdef.tr_code
               AND Recoverable = 0
    LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
     ON ledger.mt_int_code=Clients.mt_int_code
    LEFT OUTER JOIN  VFile_Streamlined.dbo.SOLCDE AS SOLCDE 
     ON ledger.mt_int_code=SOLCDE.mt_int_code 
         LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(ISNULL(Title,'')) + RTRIM(ISNULL(Forename,'')) + ' ' + RTRIM(ISNULL(Surname,'')) AS DebtorName
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Primary Debtor') AS Debtor
	ON Ledger.mt_int_code=Debtor.mt_int_code
            LEFT  OUTER JOIN ( SELECT   SOLPYR.mt_int_code ,
                                    SUM(PYR_PaymentAmount) AS amountpaid
                           FROM     VFile_Streamlined.dbo.Payments AS SOLPYR
                           WHERE    PYR_PaymentType NOT IN (
                                    'Historical Payment' )
                           GROUP BY SOLPYR.mt_int_code
                         ) amountpaid ON AccountInfo.mt_int_code = amountpaid.mt_int_code
        LEFT OUTER JOIN ( SELECT    debt.mt_int_code ,
                                    SUM(debt.amount) AS RecoverableCosts
                          FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                          WHERE     debt.TransactionType = 'COST'
                                    AND DebtOrLedger = 'Debt'
                          GROUP BY  debt.mt_int_code
                        ) recoverablecosts ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
        LEFT OUTER JOIN ( SELECT    Ledger.mt_int_code ,
                                    SUM(Ledger.Amount) AS Disbursements
                          FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
                          WHERE     Ledger.TransactionType IN ( 'OP', 'OPVU' )
                                    AND DebtOrLedger = 'Ledger'
                          GROUP BY  Ledger.mt_int_code
                        ) disbursements ON AccountInfo.mt_int_code = disbursements.mt_int_code
    WHERE   ledger.PostedDate >= @StartDate
            AND ledger.PostedDate <= @EndDate

END
ELSE
BEGIN
    SELECT  HIM_AccountNumber AS AccountNo1
    ,       RIGHT(level_fee_earner, 3) + ' / ' + CAST(MatterCode AS VARCHAR(10)) AS WeightmansRef
    ,       OriginalBalance AS OriginalBalance
    ,       CASE WHEN amountpaid.AmountPaid IS NULL THEN 0
                 ELSE AmountPaid.AmountPaid
            END AS Paid
    ,       CASE WHEN RecoverableCosts.RecoverableCosts IS NULL THEN 0
                 ELSE RecoverableCosts.RecoverableCosts
            END AS Recoverable
    ,       CASE WHEN Disbursements.Disbursements IS NULL THEN 0
                 ELSE Disbursements.Disbursements
            END AS Disbursements
    ,
		--CurrentBalance.Balance, 
            ledger.ItemDescription AS narrative
    ,       ledger.Amount AS gross_value
    ,       trdef.description AS Description
    ,       ledger.PostedDate AS posted_date
    ,       CAS_BatchNumber AS CAS01
    , CDE_ClientAccountNumber
    , CASE WHEN DebtorName IS NULL OR DebtorName='' THEN Short_name ELSE DebtorName END AS DebtorName
    , AccountInfo.ClientName AS [Client Name]
          , AccountInfo.SubClient AS [Sub Client Name]
    FROM    VFile_Streamlined.dbo.DebtLedger AS Ledger
    INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInfo
     ON ledger.mt_int_code = AccountInfo.mt_int_code AND DebtOrLedger='Ledger'
    INNER JOIN VFile_Streamlined.dbo.trdef 
            ON ledger.ItemCode = trdef.tr_code
               AND Recoverable = 0
        LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE 
     ON ledger.mt_int_code=SOLCDE.mt_int_code 
     LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
     ON ledger.mt_int_code=Clients.mt_int_code
        LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(ISNULL(Title,'')) + RTRIM(ISNULL(Forename,'')) + ' ' + RTRIM(ISNULL(Surname,'')) AS DebtorName
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Primary Debtor') AS Debtor
	ON Ledger.mt_int_code=Debtor.mt_int_code
            LEFT  OUTER JOIN ( SELECT   SOLPYR.mt_int_code ,
                                    SUM(PYR_PaymentAmount) AS amountpaid
                           FROM     VFile_Streamlined.dbo.Payments AS SOLPYR
                           WHERE    PYR_PaymentType NOT IN (
                                    'Historical Payment' )
                           GROUP BY SOLPYR.mt_int_code
                         ) amountpaid ON AccountInfo.mt_int_code = amountpaid.mt_int_code
        LEFT OUTER JOIN ( SELECT    debt.mt_int_code ,
                                    SUM(debt.amount) AS RecoverableCosts
                          FROM      VFile_Streamlined.dbo.DebtLedger AS debt
                          WHERE     debt.TransactionType = 'COST'
                                    AND DebtOrLedger = 'Debt'
                          GROUP BY  debt.mt_int_code
                        ) recoverablecosts ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
        LEFT OUTER JOIN ( SELECT    Ledger.mt_int_code ,
                                    SUM(Ledger.Amount) AS Disbursements
                          FROM      VFile_Streamlined.dbo.DebtLedger AS Ledger
                          WHERE     Ledger.TransactionType IN ( 'OP', 'OPVU' )
                                    AND DebtOrLedger = 'Ledger'
                          GROUP BY  Ledger.mt_int_code
                        ) disbursements ON AccountInfo.mt_int_code = disbursements.mt_int_code
    WHERE   ledger.PostedDate >= @StartDate
            AND ledger.PostedDate <= @EndDate
AND ClientName=@ClientName
END


GO
