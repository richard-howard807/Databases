SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[AllClientPaymentArrangements]
   @Client	VARCHAR(50)
AS 
    set nocount on
    set transaction isolation level read uncommitted

    IF @Client = 'All' 
        BEGIN
            SELECT  HIM_AccountNumber AS AccountNo
            ,CDE_ClientAccountNumber AS ClientAccountNumber
            ,       [short_name] AS Debtor
            ,       PaymentArrangementAmount AS ArragementAmount
            ,       PaymentArrangementStartDate AS ArragementStartDate
            ,       CASE WHEN PaymentArrangementFrequency = 'f' THEN 'Fortnightly'
                         WHEN PaymentArrangementFrequency = 'w' THEN 'Weekly'
                         WHEN PaymentArrangementFrequency = 'm' THEN 'Monthly'
                         WHEN PaymentArrangementFrequency = 'q' THEN 'Quarterly'
                         WHEN PaymentArrangementFrequency = 'y' THEN 'Yearly'
                         ELSE 'NotEntered'
                    END AS Frequency
            ,       PaymentArrangementNextDate AS NextDate
            ,       ClientName AS ClientName
            ,       CAS_BatchNumber AS BatchNo
            FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
             ON AccountInfo.mt_int_code = Clients.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
             ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
            WHERE   PaymentArrangementAmount <> '0.00'
                    AND FileStatus <> 'COMP'
            ORDER BY ClientName
	
        END

    ELSE 
        BEGIN
                        SELECT  HIM_AccountNumber AS AccountNo
                        ,CDE_ClientAccountNumber AS ClientAccountNumber
            ,       [short_name] AS Debtor
            ,       PaymentArrangementAmount AS ArragementAmount
            ,       PaymentArrangementStartDate AS ArragementStartDate
            ,       CASE WHEN PaymentArrangementFrequency = 'f' THEN 'Fortnightly'
                         WHEN PaymentArrangementFrequency = 'w' THEN 'Weekly'
                         WHEN PaymentArrangementFrequency = 'm' THEN 'Monthly'
                         WHEN PaymentArrangementFrequency = 'q' THEN 'Quarterly'
                         WHEN PaymentArrangementFrequency = 'y' THEN 'Yearly'
                         ELSE 'NotEntered'
                    END AS Frequency
            ,       PaymentArrangementNextDate AS NextDate
            ,       ClientName AS ClientName
            ,       CAS_BatchNumber AS BatchNo
            FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
             ON AccountInfo.mt_int_code = Clients.mt_int_code
        LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
             ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
            WHERE   PaymentArrangementAmount <> '0.00'
                    AND FileStatus <> 'COMP'
                    AND ClientName=@Client
            ORDER BY ClientName

        END

GO
