SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-04-09
-- Description:	To show the profit costs and aged debt on the same report 
-- 2020-02-01 changed to look at only claims for the M1001 files being over to ms 
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
CASE WHEN cal_month_no /*cal_month_no = 12*/  = MONTH(DATEADD(month,-7,GETDATE())) THEN 8 
	 WHEN cal_month_no = MONTH(DATEADD(month,-8,GETDATE()))  THEN 9 
	 WHEN cal_month_no = MONTH(DATEADD(month,-9,GETDATE())) THEN 10
	 WHEN cal_month_no = MONTH(DATEADD(month,-10,GETDATE())) THEN 11
	 WHEN cal_month_no=  MONTH(DATEADD(month,-11,GETDATE()))THEN 12
	 WHEN cal_month_no = MONTH(DATEADD(month,0,GETDATE())) THEN 1
	 WHEN cal_month_no=  MONTH(DATEADD(month,-1,GETDATE())) THEN 2
	 WHEN cal_month_no = MONTH(DATEADD(month,-2,GETDATE()))  THEN 3
	 WHEN cal_month_no = MONTH(DATEADD(month,-3,GETDATE())) THEN 4
	 WHEN cal_month_no = MONTH(DATEADD(month,-4,GETDATE())) THEN 5
	 WHEN cal_month_no = MONTH(DATEADD(month,-5,GETDATE()))THEN 6
	 WHEN cal_month_no =MONTH(DATEADD(month,-6,GETDATE()))  THEN 7
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
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = a.dim_fed_hierarchy_history_key
		WHERE a.dim_bill_date_key >= '20160601'  AND UPPER(client_group_name) LIKE '%MIB%'
		 AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
		GROUP BY fin_period,cal_year,
cal_month_name, 
cal_month_no,a.dim_fed_hierarchy_history_key
		
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

		WHERE debt_month >= '201606' AND calendar_date >= '2016-06-01' AND UPPER(client_group_name) LIKE '%MIB%'  AND a.age_of_debt >= 45 
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
AND hierarchylevel2hist = 'Legal Ops - Claims'
ORDER BY display_name,fin_period
END
GO
