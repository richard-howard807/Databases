SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [VisualFiles].[MarlinDebtorContact]  --EXEC [VisualFiles].[MarlinDebtorContact]  '2015-01-01','2015-03-03'
    @StartDate DATE
  , @EndDate DATE
AS 
    set nocount on
    set transaction isolation level read uncommitted

 BEGIN
            SELECT  HIM_AccountNumber AS AccoutNo
			      ,CDE_ClientAccountNumber AS [Client Account Number]
                  , short_name AS Debtor
                  , History.HTRY_description AS Contact
                  , History.HTRY_DateInserted AS [Date Telephone Call]
                  ,_date AS [Date Last Payment]
                  , ClientName AS ClientName
                  ,History.HTRY_LevelFeeEarner
                  ,ISNULL(fee.name,RIGHT(HTRY_LevelFeeEarner,3)) AS fee_earner
            FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
            INNER JOIN VFile_Streamlined.dbo.History AS History
                    ON AccountInfo.mt_int_code = History.mt_int_code
            INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients
                    ON AccountInfo.mt_int_code = Clients.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE AS SOLCDE
             ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
            LEFT OUTER JOIN VFile_Streamlined.dbo.fee AS fee
             ON RIGHT(HTRY_LevelFeeEarner,3)=fee.fee_earner
            LEFT OUTER JOIN 
(  SELECT  mt_int_code 
    ,COUNT(mt_int_code) AS Number
    , SUM(SubTotal) AS Amount
    ,[Payment Date12] AS _date
FROM
(
      SELECT      mt_int_code
                 ,SubTotal
                 ,[Payment Date12]
                 , ROW_NUMBER() OVER(PARTITION BY mt_int_code ORDER BY [Payment Date12] DESC) AS OrderID
      FROM  (
                        SELECT      SOLPYR.mt_int_code
                        ,SUM(PYR_PaymentAmount) AS SubTotal
                        ,PYR_PaymentDate AS [Payment Date12]
                        FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
                        INNER JOIN VFile_Streamlined.dbo.Payments AS SOLPYR
                         ON AccountInfo.mt_int_code = SOLPYR.mt_int_code
                        WHERE PYR_PaymentType <> 'Historical Payment'
                        
                        GROUP BY SOLPYR.mt_int_code,PYR_PaymentDate
                               
            )     subq1
)     subq2
WHERE OrderID = 1

GROUP BY [Payment Date12],mt_int_code
) AS LastPayment
ON AccountInfo.mt_int_code = LastPayment.mt_int_code 


WHERE   HTRY_DateInserted BETWEEN @StartDate AND @EndDate
                    AND (
                     HTRY_description LIKE 'Outgoing Call - Contact%'
                          OR HTRY_description LIKE 'Incoming Call -%'
                        )
                    AND ClientName = 'Marlin'
        END
GO
