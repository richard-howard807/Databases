SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2019-02-13
-- Description:	Tesco_Bdx_disbursements_broken_down
-- =============================================

--EXEC dbo.Tesco_Bdx_disbursements_broken_down '2018-12-01','2019-01-31'
CREATE PROCEDURE  [dbo].[Tesco_Bdx_disbursements_broken_down] 
	-- Add the parameters for the stored procedure here
	@BillDateFrom datetime,
	@BillDateTo datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT bill_sequence,
	fact_bill_detail.client_code,
	fact_bill_detail.matter_number,
	fact_bill_detail.bill_number,
	
SUM(bill_total_excl_vat) amount,
lower(dim_bill_cost_type.cost_type_description) cost_type_description
FROM red_dw.dbo.fact_bill_detail
LEFT JOIN red_Dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_bill_detail.dim_client_key
LEFT JOIN red_Dw.dbo.dim_date ON dim_bill_date_key = dim_date_key
WHERE  client_group_name = 'Ageas' AND charge_type = 'disbursements' and  bill_number <> 'PURGE'
AND calendar_date >=  @BillDateFrom
AND calendar_date <= @BillDateTo 
GROUP BY cost_type_description,fact_bill_detail.client_code,
	fact_bill_detail.matter_number,
	fact_bill_detail.bill_number,
	bill_sequence
	



END
GO
