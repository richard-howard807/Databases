SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- exec [VisualFiles].[AllClientFixedSolicitorsCosts] '20140101','20140401','All'

CREATE PROCEDURE [VisualFiles].[AllClientFixedSolicitorsCosts]
    @StartDate DATE ,
    @EndDate DATE ,
    @ClientName VARCHAR(50)
AS 
    SET nocount ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    IF @ClientName = 'All' 
        BEGIN
            SELECT  ClientName AS clientname ,
					SubClient as subclient ,
                    HIM_AccountNumber AS AccountNo ,
                    CDE_ClientAccountNumber AS ClientAccountNumber ,
                    RIGHT(level_fee_earner, 3) + ' / '
                    + CAST(MatterCode AS VARCHAR(10)) AS weightmansref ,
                    OriginalBalance AS originalbalance ,
                    CASE WHEN amountpaid.Total IS NULL THEN 0
                         ELSE amountpaid.Total
                    END AS paid ,
                    CASE WHEN recoverablecosts.Total IS NULL THEN 0
                         ELSE recoverablecosts.Total
                    END AS recoverable ,
                    CASE WHEN disbursements.disbursements IS NULL THEN 0
                         ELSE disbursements.disbursements
                    END AS disbursements ,
                    debt.Amount ,
                    CASE WHEN debt.ItemCode IN ( 'circ', 'rirc' ) THEN 'issue'
						 when Debt.ItemCode in ('XCIR') then 'reversal issue'
                         WHEN debt.ItemCode IN ( 'cjca', 'cjcd', 'cjcr',
                                                 'cjmc', 'jc22', 'jc25',
                                                 'jc30', 'jc40', 'jc55',
                                                 'jc70', 'rjca', 'rjcd',
                                                 'rjcr', 'rjmc' )
                         THEN 'judgment'
                         WHEN debt.ItemCode IN ( 'corc', 'SC10' )
                         THEN 'charging order'
                         WHEN debt.ItemCode IN ( 'WARC' ) THEN 'warrant'
                         WHEN debt.ItemCode IN ( 'XWCO' ) THEN 'reversal warrant'
                    END AS awardedfor ,
                    PostedDate AS Dateof,CASE WHEN DebtorName='' OR DebtorName IS NULL THEN Short_name ELSE DebtorName END AS DebtorName
                    ,DebtorIn
            FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                    
                    INNER JOIN VFile_Streamlined.dbo.DebtLedger AS Debt ON AccountInfo.mt_int_code = debt.mt_int_code
                                                              AND DebtOrLedger = 'Debt'
                    LEFT OUTER  JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
                    LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON AccountInfo.mt_int_code = SOLCDE.mt_int_code
                             LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(ISNULL(Title,'')) + RTRIM(ISNULL(Forename,'')) + ' ' + RTRIM(ISNULL(Surname,'')) AS DebtorName
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Primary Debtor') AS Debtor
	ON AccountInfo.mt_int_code=Debtor.mt_int_code
                    LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                SUM(PYR_PaymentAmount) AS Total
                                      FROM      VFile_Streamlined.dbo.Payments
                                      WHERE     PYR_PaymentType NOT IN (
                                                'CCA Request Fee',
                                                'Historical Payment', 'SAR' )
                                      GROUP BY  mt_int_code
                                    ) AS amountpaid ON Clients.mt_int_code = amountpaid.mt_int_code
                    LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                SUM(amount) AS Total
                                      FROM      VFile_Streamlined.dbo.DebtLedger
                                                AS debt
                                      WHERE     TransactionType = 'Cost'
                                      GROUP BY  mt_int_code
                                    ) AS recoverablecosts ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
                    LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(Name) AS DebtorIn
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Debtor in') AS DebtorIn
	ON AccountInfo.mt_int_code=DebtorIn.mt_int_code	
	LEFT OUTER JOIN ( SELECT    ledger.mt_int_code ,
                                                SUM(amount) AS Disbursements
                                      FROM      VFile_Streamlined.dbo.DebtLedger
                                                AS Ledger
                                      WHERE     Ledger.TransactionType IN (
                                                'OP', 'OPVU' )
                                                AND Ledger.DebtOrLedger = 'Ledger'
                                      GROUP BY  ledger.mt_int_code
                                    ) disbursements ON AccountInfo.mt_int_code = disbursements.mt_int_code
            WHERE   PostedDate BETWEEN @startdate AND @enddate
                    AND debt.TransactionType = 'cost'
                    AND debt.ItemCode IN ( 'circ', 'rirc', 'cjca', 'cjcd',
                                           'cjcr', 'cjmc', 'jc22', 'jc25',
                                           'jc30', 'jc40', 'jc55', 'jc70',
                                           'rjca', 'rjcd', 'rjcr', 'rjmc',
                                           'corc', 'SC10','WARC','XCIR','XWCO')
            
        END
   
    ELSE 
        BEGIN
            SELECT  ClientName AS clientname ,
                    SubClient AS subclient ,
                    HIM_AccountNumber AS AccountNo ,
                    CDE_ClientAccountNumber AS ClientAccountNumber ,
                    RIGHT(level_fee_earner, 3) + ' / '
                    + CAST(MatterCode AS VARCHAR(10)) AS weightmansref ,
                    OriginalBalance AS originalbalance ,
                    CASE WHEN amountpaid.Total IS NULL THEN 0
                         ELSE amountpaid.Total
                    END AS paid ,
                    CASE WHEN recoverablecosts.Total IS NULL THEN 0
                         ELSE recoverablecosts.Total
                    END AS recoverable ,
                    CASE WHEN disbursements.disbursements IS NULL THEN 0
                         ELSE disbursements.disbursements
                    END AS disbursements ,
                    debt.Amount ,
                    CASE WHEN debt.ItemCode IN ( 'circ', 'rirc' ) THEN 'issue'
                         WHEN Debt.ItemCode IN ('XCIR') THEN 'reversal issue'
                         WHEN debt.ItemCode IN ( 'cjca', 'cjcd', 'cjcr',
                                                 'cjmc', 'jc22', 'jc25',
                                                 'jc30', 'jc40', 'jc55',
                                                 'jc70', 'rjca', 'rjcd',
                                                 'rjcr', 'rjmc')
                         THEN 'judgment'
                         WHEN debt.ItemCode IN ( 'corc', 'SC10' )
                         THEN 'charging order'
                         WHEN debt.ItemCode IN ( 'WARC' ) THEN 'warrant'
                         WHEN debt.ItemCode IN ( 'XWCO' ) THEN 'reversal warrant'
                    END AS awardedfor ,
                    PostedDate AS Dateof
                    ,CASE WHEN DebtorName='' OR DebtorName IS NULL THEN Short_name ELSE DebtorName END AS DebtorName
                    ,DebtorIn
            FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                    --INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
                    INNER JOIN VFile_Streamlined.dbo.DebtLedger AS Debt ON AccountInfo.mt_int_code = debt.mt_int_code
                                                              AND DebtOrLedger = 'Debt'
                    LEFT OUTER  JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
                    LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE ON AccountInfo.mt_int_code = SOLCDE.mt_int_code
                                                 LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(ISNULL(Title,'')) + RTRIM(ISNULL(Forename,'')) + ' ' + RTRIM(ISNULL(Surname,'')) AS DebtorName
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Primary Debtor') AS Debtor
	ON AccountInfo.mt_int_code=Debtor.mt_int_code
                    LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                SUM(PYR_PaymentAmount) AS Total
                                      FROM      VFile_Streamlined.dbo.Payments
                                      WHERE     PYR_PaymentType NOT IN (
                                                'CCA Request Fee',
                                                'Historical Payment', 'SAR' )
                                      GROUP BY  mt_int_code
                                    ) AS amountpaid ON Clients.mt_int_code = amountpaid.mt_int_code
                    LEFT OUTER JOIN (
    SELECT mt_int_code,RTRIM(Name) AS DebtorIn
    FROM VFile_Streamlined.dbo.DebtorInformation
	WHERE ContactType='Debtor in') AS DebtorIn
	ON AccountInfo.mt_int_code=DebtorIn.mt_int_code	
	LEFT OUTER JOIN ( SELECT    mt_int_code ,
                                                SUM(amount) AS Total
                                      FROM      VFile_Streamlined.dbo.DebtLedger
                                                AS debt
                                      WHERE     TransactionType = 'Cost'
                                      GROUP BY  mt_int_code
                                    ) AS recoverablecosts ON AccountInfo.mt_int_code = recoverablecosts.mt_int_code
                    LEFT OUTER JOIN ( SELECT    ledger.mt_int_code ,
                                                SUM(amount) AS Disbursements
                                      FROM      VFile_Streamlined.dbo.DebtLedger
                                                AS Ledger
                                      WHERE     Ledger.TransactionType IN (
                                                'OP', 'OPVU' )
                                                AND Ledger.DebtOrLedger = 'Ledger'
                                      GROUP BY  ledger.mt_int_code
                                    ) disbursements ON AccountInfo.mt_int_code = disbursements.mt_int_code
            WHERE   PostedDate BETWEEN @startdate AND @enddate
                    AND debt.TransactionType = 'cost'
                    AND debt.ItemCode IN ( 'circ', 'rirc', 'cjca', 'cjcd',
                                           'cjcr', 'cjmc', 'jc22', 'jc25',
                                           'jc30', 'jc40', 'jc55', 'jc70',
                                           'rjca', 'rjcd', 'rjcr', 'rjmc',
                                           'corc', 'SC10','WARC','XCIR','XWCO')
                    AND ClientName = @ClientName
        END

GO
