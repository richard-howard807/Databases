SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-06-28
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Photo_Copying_Report] --'2019-05 (Sep-2018)'
	-- Add the parameters for the stored procedure here
 @period AS nvarchar(20)
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


IF OBJECT_ID ('tempdb..#time') IS NOT NULL
DROP TABLE #time

IF OBJECT_ID ('tempdb..#employees') IS NOT NULL
DROP TABLE #employees

IF OBJECT_ID ('tempdb..#writeoff') IS NOT NULL
DROP TABLE #writeoff

SELECT 
SUM(amount) non_chargeable,
employeeid
INTO #non_chargeable
FROM red_Dw.dbo.fact_eqcas_billing
LEFT JOIN red_Dw.dbo.dim_eqcas_billing ON dim_eqcas_billing.dim_eqcas_billing_key = fact_eqcas_billing.dim_eqcas_billing_key
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = dim_eqcas_billing.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_date ON dim_date.dim_date_key = dim_eqcas_billing.dim_date_key
WHERE  dim_date.fin_month   <=  @fin_month 
AND master_fact_key = 0 AND matter IS NULL
GROUP BY 
employeeid



SELECT 
SUM(bill_total_excl_vat) billed,
employeeid
INTO #billed
FROM red_Dw.dbo.fact_bill_detail
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_detail.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
LEFT JOIN red_Dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
WHERE cost_type_description = 'Photocopies'
AND dim_bill_date.bill_fin_month   <=  @fin_month AND dim_bill_date.bill_fin_year = @fin_year --AND is_reversed <> 1 
AND bill_total_excl_vat <> 0
GROUP BY  
employeeid


select 
employeeid,
sum(CostCard.workamt) WorkAmt
INTO #time
from red_Dw.dbo.ds_sh_3e_costcard  CostCard
left join red_Dw.dbo.ds_sh_3e_invmaster InvMaster on CostCard.invmaster = InvMaster.invindex
left join red_Dw.dbo.ds_sh_3e_matter Matter on CostCard.matter = Matter.mattindex
left join red_Dw.dbo.ds_sh_3e_timekeeper Timekeeper on  Timekeeper.tkprindex = Matter.opentkpr
LEFT JOIN red_Dw.dbo.dim_date ON CAST(dim_date.calendar_date AS DATE)= CAST(workdate AS DATE)
left join red_Dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.fed_code  collate database_default = Timekeeper.number collate database_default  and dim_fed_hierarchy_history.dss_current_flag = 'Y'
where CostCard.costtype = 'CP'  and CostCard.isactive = 1  AND dim_date.fin_month   <=  @fin_month   AND ISNULL(InvMaster.invnumber ,'') = ''
--BETWEEN @start_date AND 
group by 
employeeid





SELECT DISTINCT employeeid INTO #employees FROM (
SELECT DISTINCT employeeid FROM #time
UNION 
SELECT DISTINCT employeeid FROM #billed
UNION 
SELECT DISTINCT employeeid FROM #non_chargeable
) employees

SELECT 
dim_fed_hierarchy_history.hierarchylevel2hist business_line,
dim_fed_hierarchy_history.hierarchylevel3hist department,
dim_fed_hierarchy_history.hierarchylevel4hist team,
name,
#employees.employeeid,
#time.WorkAmt,
billed,
non_chargeable
FROM #employees 
LEFT JOIN #time ON #time.employeeid = #employees.employeeid  
LEFT JOIN #billed ON #billed.employeeid = #employees.employeeid 
LEFT JOIN #non_chargeable ON #employees.employeeid = #non_chargeable.employeeid 
LEFT JOIN (SELECT  hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist,
name ,
employeeid,
ROW_NUMBER() OVER (PARTITION BY employeeid ORDER BY dss_start_date desc) rownumber FROM red_Dw.dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history.hierarchylevel2hist IN ('Legal Ops - Claims','Legal Ops - LTA') )dim_fed_hierarchy_history  ON rownumber =1 and dim_fed_hierarchy_history.employeeid = #employees.employeeid
WHERE (WorkAmt IS NOT NULL OR billed IS NOT NULL or non_chargeable IS NOT NULL)
ORDER BY #billed.employeeid

end
GO
