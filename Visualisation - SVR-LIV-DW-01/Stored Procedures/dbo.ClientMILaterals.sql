SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ClientMILaterals]

AS 

BEGIN


DECLARE @Period AS NVARCHAR(500)
SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)),103))

PRINT @Period

DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

DECLARE @MinDate AS DATE
SET @MinDate=(SELECT MIN(bill_date) AS MinDate FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)


SELECT hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,name AS [Name]
,bill_fin_month_name AS [Month]
,bill_fin_month_display
,SUM(bill_amount) AS Revenue
,DATEADD(m,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()), 0)) AS ReportingPeriod
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no<=@FinMonth
AND fed_code IN 
(
'5703','5912','6193','6169','6392','5708','5776','5788','5829','5902','5903','5904','5908'
,'5934','5980','5998','6004','6063','6066','6073','6111','6122','6161','6196','6197'
,'6207','6210','6212','6245','6257','6256','6290','6300','6395','6406','6486','6556'
)
AND hierarchylevel2hist IN ('Legal Ops - Claims','Legal Ops - LTA')
GROUP BY hierarchylevel2hist
,hierarchylevel3hist
,hierarchylevel4hist
,name
,bill_fin_month_name,bill_fin_year,bill_fin_month_display

END
GO
