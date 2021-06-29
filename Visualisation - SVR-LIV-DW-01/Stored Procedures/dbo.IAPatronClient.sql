SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[IAPatronClient]

AS 

BEGIN 

DECLARE @Period AS NVARCHAR(MAX)
SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date
WHERE bill_date =DATEADD(MONTH,0,CONVERT(DATE,GETDATE(),103)))

DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

DECLARE @MinDate AS DATE
SET @MinDate=(SELECT MIN(bill_date) AS MinDate FROM red_dw.dbo.dim_bill_date WHERE bill_fin_period=@Period)


PRINT @FinYear
PRINT @FinMonth

DECLARE @PreFinYear AS INT
SET @PreFinYear=@FinYear-1

PRINT @PreFinYear


SELECT ISNULL(dim_client.client_group_name,dim_client.client_name) AS [Client]
,SUM(ClientRevenueYTD) AS YTDRevenue
,SUM(ClientRevenuePrevYTD) AS LastYTDRevenue
,SUM(CurrentWIP.WIPCurrent) AS CurrentWIP
,SUM(WIPLast) AS LastYRWIP
,SUM(DebtCurrent) AS CurrentDebt
,SUM(LastYRDebt) AS LastYRDebt

FROM red_dw.dbo.dim_client

LEFT OUTER JOIN
(
SELECT dim_client.dim_client_key,SUM(bill_amount) AS ClientRevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no<=@FinMonth
GROUP BY dim_client.dim_client_key
) AS RevenueCurrent
 ON RevenueCurrent.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN
(
SELECT dim_client.dim_client_key,SUM(bill_amount) AS ClientRevenuePrevYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year= @PreFinYear
AND bill_fin_month_no<=@FinMonth
GROUP BY dim_client.dim_client_key
) AS RevenuePrev
 ON RevenuePrev.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN 
(
SELECT dim_client_key,SUM(wip_value) AS WIPCurrent FROM red_dw.dbo.fact_wip_daily
WHERE CONVERT(DATE,wip_date,103)=CONVERT(DATE,GETDATE()-1,103)
GROUP BY dim_client_key
) AS CurrentWIP
 ON CurrentWIP.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN 
(
SELECT dim_client_key,SUM(wip_value) AS WIPLast FROM red_dw.dbo.fact_wip_daily
WHERE CONVERT(DATE,wip_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,GETDATE()-1),103)
GROUP BY dim_client_key
) AS LastYearWIP
 ON LastYearWIP.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN
(
SELECT dim_client_key,SUM(outstanding_total_bill) AS DebtCurrent FROM red_dw.dbo.fact_debt_daily
WHERE CONVERT(DATE,debt_date,103)=CONVERT(DATE,GETDATE()-1,103)
GROUP BY dim_client_key
) AS CurrentDebt
 ON CurrentDebt.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN 
(
SELECT dim_client_key,SUM(outstanding_total_bill) AS LastYRDebt FROM red_dw.dbo.fact_debt_daily
WHERE CONVERT(DATE,debt_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,GETDATE()-1),103)
GROUP BY dim_client_key
) AS LastYRDebt
 ON LastYRDebt.dim_client_key = dim_client.dim_client_key
WHERE dim_client.client_group_code IN
      (
          SELECT DISTINCT
                 client_group_code
          FROM red_dw.dbo.dim_ia_lists
              INNER JOIN red_dw.dbo.dim_ia_contact_lists
                  ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
              INNER JOIN red_dw.dbo.dim_client
                  ON dim_client.dim_client_key = dim_ia_contact_lists.dim_client_key
          WHERE dim_ia_lists.list_name IN ( 'Clients (Active)', 'Clients (Lapsed)', 'Non client', 'Patron', 'Star' )
                AND dim_ia_contact_lists.dim_client_key <> 0
                AND list_type_desc = 'Status'
                AND list_name = 'Patron'
      )
      OR dim_client.client_code IN
         (
             SELECT DISTINCT
                    client_code
             FROM red_dw.dbo.dim_ia_lists
                 INNER JOIN red_dw.dbo.dim_ia_contact_lists
                     ON dim_ia_contact_lists.dim_lists_key = dim_ia_lists.dim_lists_key
                 INNER JOIN red_dw.dbo.dim_client
                     ON dim_client.dim_client_key = dim_ia_contact_lists.dim_client_key
             WHERE dim_ia_lists.list_name IN ( 'Clients (Active)', 'Clients (Lapsed)', 'Non client', 'Patron', 'Star' )
                   AND dim_ia_contact_lists.dim_client_key <> 0
                   AND list_type_desc = 'Status'
                   AND list_name = 'Patron'
                   AND client_group_code IS NULL
         )
GROUP BY ISNULL(dim_client.client_group_name,dim_client.client_name)
ORDER BY ISNULL(dim_client.client_group_name,dim_client.client_name)

END 
GO
