SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-06-28
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Photo_Copying_Report_client] --'2019-05 (Sep-2018)','Z1001'
	-- Add the parameters for the stored procedure here
 @period AS nvarchar(20)
 ,@Client AS nvarchar(20)
AS
BEGIN

DECLARE @fin_month INT,
 @fin_year int

SELECT @fin_month = fin_month, @fin_year = fin_year FROM red_Dw.dbo.dim_date
WHERE fin_period = @period

IF OBJECT_ID ('tempdb..#non_chargeable') IS NOT NULL
DROP TABLE #non_chargeable



IF OBJECT_ID ('tempdb..#billed') IS NOT NULL
DROP TABLE #billed



IF OBJECT_ID ('tempdb..#employees') IS NOT NULL
DROP TABLE #employees

IF OBJECT_ID ('tempdb..#writeoff') IS NOT NULL
DROP TABLE #writeoff

SELECT 
SUM(amount) non_chargeable,
master_fact_key
INTO #non_chargeable
FROM red_Dw.dbo.fact_eqcas_billing
LEFT JOIN red_Dw.dbo.dim_eqcas_billing ON dim_eqcas_billing.dim_eqcas_billing_key = fact_eqcas_billing.dim_eqcas_billing_key
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = dim_eqcas_billing.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_date ON dim_date.dim_date_key = dim_eqcas_billing.dim_date_key
WHERE  dim_date.fin_month   <=  @fin_month 
AND master_fact_key <>0
GROUP BY 
master_fact_key



SELECT 
SUM(bill_total_excl_vat) billed,
master_fact_key
INTO #billed
FROM red_Dw.dbo.fact_bill_detail
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_detail.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
LEFT JOIN red_Dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
WHERE cost_type_description = 'Photocopies'
AND dim_bill_date.bill_fin_month   <=  @fin_month AND dim_bill_date.bill_fin_year = @fin_year --AND is_reversed <> 1 
AND bill_total_excl_vat <> 0
GROUP BY  
master_fact_key





SELECT DISTINCT master_fact_key INTO #employees
 FROM (

SELECT DISTINCT master_fact_key FROM #billed
UNION 
SELECT DISTINCT master_fact_key FROM #non_chargeable
) employees

SELECT dim_matter_header_current.client_code AS ClientCode,
SUM(billed) AS Billed,
SUM(non_chargeable) NonChargeable
FROM #employees 
INNER JOIN red_dw.dbo.fact_dimension_main
 ON #employees.master_fact_key=fact_dimension_main.master_fact_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON fact_dimension_main.dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN #billed ON #billed.master_fact_key = #employees.master_fact_key 
LEFT JOIN #non_chargeable ON #employees.master_fact_key = #non_chargeable.master_fact_key 
WHERE (billed IS NOT NULL or non_chargeable IS NOT NULL)
AND dim_matter_header_current.client_code=@Client
GROUP BY dim_matter_header_current.client_code
END 
GO
