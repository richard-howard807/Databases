SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- ============================
-- Lucy Dickinson
-- 07/09/2016
-- This supposes that the table reporting.converge.SevernTrentCashbook has been pre-populated by a build process
--  see [converge].[st_cashbook_build] 
-- =========================

CREATE PROCEDURE [converge].[cashbook_ST] 
AS
BEGIN

SELECT [Category]
      ,[case_id]
      ,[transaction_type_code]
      ,[ChequeNumber]
      ,[InstructionID]
      ,[Effect Description Additional]
      ,[InvoiceNumber]
      ,[DateOfLoss]
      ,[Year OF Account]
      ,[PayableToName]
      ,[PaymentNet]
      ,[PaymentVAT]
      ,[PaymentGross]
      ,[CreditAmount]
      ,[DebitAmount]
      ,[Payment Notes]
      ,[Policy Type]
      ,[Business Unit]
      ,[Working Deductible]
      ,[PostingDate]
      ,[NewTotalPaid_Total]
      ,[NewTotalRecovered_Total]
      ,[Peril Description]
      ,[Wholesale OPS Burst Mains]
      ,[District]
	  ,[gl_date]
	  ,[transaction_date]

FROM Reporting.[converge].[cashbook_severntrent]

END


GO
