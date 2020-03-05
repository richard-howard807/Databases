SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2017-12-12
-- Description:	New report requested by Paul for CRM 
-- =============================================
CREATE PROCEDURE [dbo].[CRM_Financials] 

	(@Client AS varchar(10),
	@Matter AS varchar (10),
	@TranDate AS date
	)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT client_code
	, matter_number
	, transaction_calendar_date
	, wip
	, defence_costs_billed
	, disbursements_billed
	, total_amount_billed
	, time_billed
	, damages_reserve
	, tp_costs_reserve
	, defence_costs_reserve
	, total_reserve
	, claimants_costs_paid
	, damages_paid
	, paid_disbursements
	, total_costs_paid
	, total_paid
	
FROM red_dw.dbo.fact_finance_summary_daily
LEFT OUTER JOIN  red_dw.dbo.dim_transaction_date ON dim_transaction_date.dim_transaction_date_key = fact_finance_summary_daily.dim_transaction_date_key

WHERE client_code = @Client 
	AND matter_number = @Matter
	AND transaction_calendar_date = @TranDate

ORDER BY fact_finance_summary_daily.dim_transaction_date_key DESC 

END

GO
