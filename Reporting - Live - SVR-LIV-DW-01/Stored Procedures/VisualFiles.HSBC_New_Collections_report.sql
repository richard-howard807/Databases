SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [VisualFiles].[HSBC_New_Collections_report]
	-- Add the parameters for the stored procedure here
	@startdate DATE,
	@enddate DATE
AS
BEGIN
 SELECT  
 HIM_AccountNumber AS AccountNo
 ,Debtor.Title + ' ' + Debtor.Forename +' '+ Debtor.Surname AS [Contact Name]
 ,payments.PYR_PaymentDate
 ,payments.PYR_PaymentTakenByClient client_payment
 ,CASE WHEN UPPER(payments.PYR_PaymentTakenByClient) = 'YES' THEN payments.PYR_PaymentAmount ELSE 0 END AS [client_payment_amount]
 ,CASE WHEN UPPER(payments.PYR_PaymentTakenByClient) = 'NO' THEN payments.PYR_PaymentAmount ELSE 0 END AS [weightmans_payment_amount]
 ,CASE WHEN UPPER(clients.HIM_AccountType) = 'D' THEN 'Divisionalised' ELSE 'Non Divisionalised' END [Client Contract]
 ,accounts.ClientName
 FROM VFile_Streamlined.dbo.AccountInformation AS accounts
 INNER JOIN VFile_Streamlined.dbo.ClientScreens AS clients ON clients.mt_int_code = accounts.mt_int_code
 INNER JOIN VFile_Streamlined.dbo.Payments AS payments ON payments.mt_int_code = accounts.mt_int_code
 LEFT JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType = 'Primary Debtor') AS Debtor
 ON  accounts.mt_int_code=Debtor.mt_int_code
 WHERE accounts.ClientName LIKE '%HFC%' AND payments.PYR_PaymentDate BETWEEN @startdate AND @enddate
END
GO
