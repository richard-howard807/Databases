SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DebtByClientOver90Days] --EXEC dbo.DebtByClientOver90Days '202306','202206','LTA'
(@Month AS INT
,@PreviousMonth AS INT
,@Division AS NVARCHAR(MAX)
)
AS 

BEGIN

--DECLARE @Month AS INT = 202306

--DECLARE @PreviousMonth AS INT 
--SET @PreviousMonth=202206


IF OBJECT_ID('tempdb..#Division') IS NOT NULL   DROP TABLE #Division
SELECT ListValue  INTO #Division FROM Reporting.dbo.[udt_TallySplit]('|', @Division)


SELECT AllData.Dim_Days_Banding_Key,
       AllData.Days_Banding,
       AllData.debt_month,
       AllData.Display_Name,
       AllData.Team,
       AllData.[Practice Area],
       AllData.[Business Line],
       CASE WHEN AllData.[Client Code] IS NULL THEN 'Unknown' ELSE AllData.[Client Code] END AS [Client Code] ,
       CASE WHEN AllData.ClientName IS NULL THEN 'Unknown' ELSE AllData.ClientName END AS [Client Name],
       AllData.CurrentPeriod,
       AllData.PreviousPeriod
FROM (SELECT  
CASE WHEN daysbanding ='0 - 30 Days' THEN 1 
     WHEN daysbanding = '31 - 90 days' THEN 2
	 WHEN daysbanding  ='Greater than 90 Days' THEN 3 END

AS [Dim_Days_Banding_Key],
daysbanding AS [Days_Banding],
debt_month,
name AS    [Display_Name],
hierarchylevel4hist AS Team,
hierarchylevel3hist AS [Practice Area],
hierarchylevel2hist AS [Business Line],
master_client_code AS [Client Code]
,client_name AS ClientName
,SUM(fact_debt_monthly.outstanding_total_bill) AS CurrentPeriod
,NULL AS PreviousPeriod

 

FROM red_dw.dbo.fact_debt_monthly
LEFT OUTER JOIN  red_dw.dbo.fact_dimension_main
ON fact_debt_monthly.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_days_banding
ON dim_days_banding.dim_days_banding_key = fact_debt_monthly.dim_days_banding_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key


WHERE fact_debt_monthly.outstanding_total_bill <> 0 

AND debt_month =   @Month
AND daysbanding  ='Greater than 90 Days' 

--(SELECT fin_month FROM red_dw.dbo.dim_date WHERE calendar_date = cast(getdate() - 1 as date) )


GROUP BY CASE
         WHEN daysbanding = '0 - 30 Days' THEN
         1
         WHEN daysbanding = '31 - 90 days' THEN
         2
         WHEN daysbanding = 'Greater than 90 Days' THEN
         3
         END,
         daysbanding,
         debt_month,
         name,
         hierarchylevel4hist,
         hierarchylevel3hist,
         hierarchylevel2hist,
         master_client_code,
         client_name
UNION
SELECT  
CASE WHEN daysbanding ='0 - 30 Days' THEN 1 
     WHEN daysbanding = '31 - 90 days' THEN 2
	 WHEN daysbanding  ='Greater than 90 Days' THEN 3 END

AS [Dim_Days_Banding_Key],
daysbanding AS [Days_Banding],
debt_month,
name AS    [Display_Name],
hierarchylevel4hist AS Team,
hierarchylevel3hist AS [Practice Area],
hierarchylevel2hist AS [Business Line],
master_client_code AS [Client Code]
,client_name AS ClientName
,NULL AS CurrentPeriod
,SUM(fact_debt_monthly.outstanding_total_bill) AS PreviousPeriod

 

FROM red_dw.dbo.fact_debt_monthly
LEFT OUTER JOIN  red_dw.dbo.fact_dimension_main
ON fact_debt_monthly.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_days_banding
ON dim_days_banding.dim_days_banding_key = fact_debt_monthly.dim_days_banding_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key


WHERE fact_debt_monthly.outstanding_total_bill <> 0 

AND debt_month =   @PreviousMonth
AND daysbanding  ='Greater than 90 Days' 

--(SELECT fin_month FROM red_dw.dbo.dim_date WHERE calendar_date = cast(getdate() - 1 as date) )


GROUP BY CASE
         WHEN daysbanding = '0 - 30 Days' THEN
         1
         WHEN daysbanding = '31 - 90 days' THEN
         2
         WHEN daysbanding = 'Greater than 90 Days' THEN
         3
         END,
         daysbanding,
         debt_month,
         name,
         hierarchylevel4hist,
         hierarchylevel3hist,
         hierarchylevel2hist,
         master_client_code,
         client_name
		 ) AS AllData
		 INNER JOIN #Division AS Division  ON Division.ListValue COLLATE DATABASE_DEFAULT = [Business Line] COLLATE DATABASE_DEFAULT


		 END 
GO
