SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-04-09
-- Description:	To show the profit costs and aged debt on the same report 
-- =============================================
CREATE PROCEDURE [MIB].[MIB_Profit_Costs_Aged_debt]
AS
BEGIN
SET NOCOUNT ON;
;WITH cte AS (
SELECT 
dim_fed_matter_owner_key,
fin_period,
cal_year,
cal_month_name, 
cal_month_no,
CASE WHEN cal_month_no = 12 THEN 8 
	 WHEN cal_month_no = 1  THEN 9 
	 WHEN cal_month_no = 2  THEN 10
	 WHEN cal_month_no = 3  THEN 11
	 WHEN cal_month_no =  4 THEN 12
	 WHEN cal_month_no = 5  THEN 1
	 WHEN cal_month_no =  6 THEN 2
	 WHEN cal_month_no = 7  THEN 3
	 WHEN cal_month_no = 8 THEN 4
	 WHEN cal_month_no = 9  THEN 5
	 WHEN cal_month_no = 10 THEN 6
	 WHEN cal_month_no = 11  THEN 7
 END cal_month_no_sort,
SUM(profit) profit,
SUM(debt) debt
FROM (
		SELECT 
		a.dim_fed_hierarchy_history_key dim_fed_matter_owner_key,
		fin_period,
		cal_year,
cal_month_name, 
cal_month_no,
		SUM(a.bill_total_excl_vat) profit,
		0 debt
		FROM red_Dw.dbo.fact_bill_detail a
		LEFT JOIN red_Dw.dbo.dim_date ON dim_date_key = a.dim_bill_date_key
		LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = a.dim_client_key
		WHERE a.dim_bill_date_key >= '20160101'  AND UPPER(client_group_name) LIKE '%MIB%'
		GROUP BY fin_period,cal_year,
cal_month_name, 
cal_month_no,dim_fed_hierarchy_history_key
		
UNION ALL
		SELECT 
		dim_fed_matter_owner_key,
		dim_date.fin_period,
		cal_year,
cal_month_name, 
cal_month_no,
		0,
		SUM(a.outstanding_total_bill) 'debt' 
		FROM red_Dw.dbo.fact_debt_monthly a 
		LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = a.dim_client_key
		LEFT JOIN red_Dw.dbo.dim_date ON dim_date.calendar_date = cast(a.debt_date AS DATE)

		WHERE debt_month >= '201609'  AND UPPER(client_group_name) LIKE '%MIB%'  AND a.dim_days_banding_key <> 12 
				GROUP BY 
		dim_fed_matter_owner_key,
		cal_year,
cal_month_name, 
cal_month_no,
		fin_period
		) cte 
		GROUP by
		dim_fed_matter_owner_key,
		fin_period,
		cal_year,
cal_month_name, 
cal_month_no
)

SELECT 
cte.dim_fed_matter_owner_key,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist,
display_name,
cte.fin_period,
cal_year,
cal_month_name, 
cal_month_no,
cal_month_no_sort,
cte.profit,
cte.debt 
FROM cte
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history_key = dim_fed_matter_owner_key
WHERE hierarchylevel2hist NOT IN ('Solving Disputes','Business Services','Client Relationships')
ORDER BY display_name,fin_period
END
GO
