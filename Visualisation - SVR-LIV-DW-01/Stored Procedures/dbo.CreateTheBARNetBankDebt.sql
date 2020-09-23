SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 11-02-2019
-- Description:	Net bank debt for the BAR
-- =============================================
CREATE PROCEDURE [dbo].[CreateTheBARNetBankDebt]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


Truncate TABLE TheBARNetBankDebt

INSERT INTO  TheBARNetBankDebt

select 
	 [Loan Borrowed]-total_balance [Net Bank Debt]
	, [Total Loan Arranged] as [Total Loan Agreed]
	, 17000000-([Loan Borrowed]-total_balance) as [Headroom]
	, Date
	, GETDATE() as [dss_insert_date]
	--into TheBARNetBankDebt
 from 

(SELECT (SUM(FirmDR)+SUM(FirmCR))*-1 as [Loan Borrowed]
	, 17000000-((SUM(FirmDR)+SUM(FirmCR))*-1) as [Loan Still Available]
	, 17000000 as [Total Loan Arranged]
	, Getdate() as [Date]
FROM [red_dw].[dbo].[GLDetail_3ESQ-01]) loan --GLAcct = 15504
inner join

(SELECT [total_balance]
  FROM [red_dw].[dbo].[GLBankBalance_3ESQ-01]) balance
  on 1=1

END
GO
