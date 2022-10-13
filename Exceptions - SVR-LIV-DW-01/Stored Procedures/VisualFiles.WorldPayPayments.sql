SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[WorldPayPayments]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT HIM_AccountNumber AS [Reference] 
,Name[Debtor] 
,PYR_PaymentDate AS  [Payment Date]
,PDE_WorldPayID AS [World Pay ID]
,PYR_PaymentAmount AS [Payment Amount]
,SubClient AS [Sub Client]

FROM VFile_Streamlined.dbo.Payments AS Payments
INNER JOIN VFile_Streamlined.dbo.AccountInformation AS AccountInformation
 ON Payments.mt_int_code=AccountInformation.mt_int_code
LEFT OUTER JOIN (SELECT mt_int_code,Title + ' ' + Forename + ' ' + Surname AS [Name] FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType='Primary Debtor') AS Debtor
 ON Payments.mt_int_code=Debtor.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens AS ClientScreens
 ON Payments.mt_int_code=ClientScreens.mt_int_code
WHERE PYR_PaymentType IN ('Credit Card (World Pay)','Debit Card (World Pay)')
AND PYR_PaymentDate BETWEEN @StartDate AND @EndDate
ORDER BY ClientName,HIM_AccountNumber
END
GO
