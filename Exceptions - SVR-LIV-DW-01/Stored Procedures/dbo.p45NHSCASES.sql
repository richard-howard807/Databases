SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[p45NHSCASES]

AS
BEGIN

SET NOCOUNT ON
IF OBJECT_ID(N'tempdb..#panel_avg') IS NOT NULL DROP TABLE #panel_avg;

SELECT CONVERT(NVARCHAR, REPLACE(RTRIM(LTRIM([tranche])), 'Â', ''), 120) AS [tranche]
      ,SUM(convert(float, [average]) * convert(int, [no_cases]))/SUM(convert(int, [no_cases])) AS [average]
      ,[scheme]
      ,[type]
      ,dateadd(month,datediff(month,0,[date]), 0) AS [date]
  INTO #panel_avg
  FROM [DataScience].[dbo].[p45_NHSR_data]
  GROUP BY
	   CONVERT(NVARCHAR, REPLACE(RTRIM(LTRIM([tranche])), 'Â', ''), 120)
	  ,scheme
	  ,[type]
	  ,[date]
  HAVING SUM(convert(int, [no_cases])) > 0

DECLARE @lf CHAR(1) SET @lf = CHAR(10);
DECLARE @cr CHAR(1) SET @cr = CHAR(13);
DECLARE @tab CHAR(1) SET @tab = CHAR(9);

IF OBJECT_ID(N'tempdb..#cases') IS NOT NULL DROP TABLE #cases;

SELECT
	RTRIM(red_dw.dbo.fact_dimension_main.master_client_code) + '-' + RTRIM(master_matter_number) AS panel_ref
	,convert(float, DATEDIFF(DAY, date_opened_case_management, date_claim_concluded))/365 AS settlement_time
	,REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CASE WHEN nhs_scheme IN ('CNST','ELS','DH CL','ELSGP','CNSGP') THEN 'CNST' 
	WHEN nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'LTPS' ELSE 'Unknown' END)), @cr, N''), @lf, N''), @tab, N'') AS nhs_scheme
	,fact_finance_summary.defence_costs_billed 
	,CASE WHEN date_closed_case_management IS NULL THEN 'Live' ELSE 'Closed' END AS file_status
    ,dateadd(month,datediff(month,0,LEFT(CONVERT(VARCHAR, dim_detail_outcome.[date_claim_concluded], 120), 10)), 0) AS date_claim_concluded
    ,fact_finance_summary.[damages_paid]
	,fact_finance_summary.[claimants_costs_paid]
	,CASE WHEN damages_paid = 0 THEN '£0'
	 WHEN damages_paid > 0 AND damages_paid <= 50000 AND nhs_scheme IN ('CNST','ELS','DH CL','ELSGP','CNSGP') THEN '£1-£50,000'
	 WHEN damages_paid > 50000 AND damages_paid <= 250000 AND nhs_scheme IN ('CNST','ELS','DH CL','ELSGP','CNSGP') THEN '£50,000-£250,000'
	 WHEN damages_paid > 250000 AND damages_paid <= 500000 AND nhs_scheme IN ('CNST','ELS','DH CL','ELSGP','CNSGP') THEN '£250,000-£500,000'
	 WHEN damages_paid > 500000 AND damages_paid <= 1000000 AND nhs_scheme IN ('CNST','ELS','DH CL','ELSGP','CNSGP') THEN '£500,000-£1,000,000'
	 WHEN damages_paid > 1000000 AND nhs_scheme IN ('CNST','ELS','DH CL','ELSGP','CNSGP') THEN '£1,000,000+'
	 WHEN damages_paid > 0 AND damages_paid <= 5000 AND nhs_scheme IN ('DH Liab','LTPS','PES') THEN '£1-£5,000'
	 WHEN damages_paid > 5000 AND damages_paid <= 10000 AND nhs_scheme IN ('DH Liab','LTPS','PES') THEN '£5,000-£10,000'
	 WHEN damages_paid > 10000 AND damages_paid <= 25000 AND nhs_scheme IN ('DH Liab','LTPS','PES') THEN '£10,000-£25,000'
	 WHEN damages_paid > 25000 AND damages_paid <= 50000 AND nhs_scheme IN ('DH Liab','LTPS','PES') THEN '£25,000-£50,000'
	 WHEN damages_paid > 50000 AND nhs_scheme IN ('DH Liab','LTPS','PES') THEN '£50,000+' END AS [tranche]
INTO #cases
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current       ON red_dw.dbo.dim_matter_header_current.dim_matter_header_curr_key = red_dw.dbo.fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
    ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
       AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
       AND GETDATE()
       BETWEEN dss_start_date AND dss_end_date
LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary                     ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details                       ON dim_detail_core_details.client_code = dim_matter_header_current.client_code AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_bill_matter                                                ON red_dw.dbo.fact_dimension_main.master_fact_key = red_dw.dbo.fact_bill_matter.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome                            ON dim_detail_outcome.client_code = dim_matter_header_current.client_code AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number  
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement                       ON dim_client_involvement.client_code = dim_matter_header_current.client_code AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim                                              ON dim_detail_claim.client_code = dim_matter_header_current.client_code AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number 
LEFT JOIN [red_dw].[dbo].[fact_detail_reserve_detail]  ON red_dw.dbo.fact_dimension_main.master_fact_key = [red_dw].[dbo].[fact_detail_reserve_detail].master_fact_key
LEFT JOIN [red_dw].[dbo].[dim_detail_critical_mi]                   ON red_dw.dbo.fact_dimension_main.dim_detail_critical_mi_key = [red_dw].[dbo].[dim_detail_critical_mi].dim_detail_critical_mi_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health                                ON dim_detail_health.client_code = dim_matter_header_current.client_code AND dim_detail_health.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary                                     ON fact_finance_summary.client_code = dim_matter_header_current.client_code AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_employee					ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype					ON red_dw.dbo.dim_matter_header_current.dim_matter_worktype_key = red_dw.dbo.dim_matter_worktype.dim_matter_worktype_key

WHERE 
	red_dw.dbo.fact_dimension_main.master_client_code = N'N1001'
	AND reporting_exclusions=0
    AND ISNULL(outcome_of_case,'') <> N'Exclude from reports'
	--AND CASE WHEN date_closed_case_management IS NULL THEN 'Live' ELSE 'Closed' END = 'Closed'
	AND LEFT(CONVERT(VARCHAR, dim_detail_outcome.[date_claim_concluded], 120), 10) IS NOT NULL
	--AND nhs_scheme IN ('LTPS', 'CNST', 'ELS')
    
--SELECT * FROM #panel_avg
--SELECT * FROM #cases WHERE nhs_scheme = 'ELS'

IF OBJECT_ID(N'tempdb..#panel_avg_wide') IS NOT NULL DROP TABLE #panel_avg_wide;

CREATE TABLE #panel_avg_wide (
    [tranche] VARCHAR(MAX),
    [settlement_time_av] FLOAT,
	[scheme] VARCHAR(MAX),
	[date] DATE,
	[defence_costs_av] FLOAT,
	[damages_av] FLOAT,
	[claimant_costs_av] FLOAT
)
INSERT INTO #panel_avg_wide
EXEC sp_execute_external_script @language = N'R',
@script = N'

library(tibble)
library(dplyr)
library(tidyr)

def_costs <- InputDataSet %>%
	filter(type == "defence costs") %>%
	rename(defence_costs = average) %>%
	select(-type)

set_time <- InputDataSet %>%
	filter(type == "settlement time") %>%
	rename(settlement_time = average) %>%
	select(-type)


dam <- InputDataSet %>%
	filter(type == "damages") %>%
	rename(damages = average) %>%
	select(-type)

claim <- InputDataSet %>%
	filter(type == "claimant costs") %>%
	rename(claimant_costs = average) %>%
	select(-type)

OutputDataSet <- set_time %>%
	full_join(def_costs, by = c("tranche", "scheme", "date")) %>%
	full_join(dam, by = c("tranche", "scheme", "date")) %>%
	full_join(claim, by = c("tranche", "scheme", "date"))

	print(head(set_time))
	print(head(dam))
',
@input_data_1 = N'SELECT * FROM #panel_avg'

--SELECT * FROM #panel_avg_wide WHERE scheme = 'ELS'

--SELECT * FROM #cases WHERE nhs_scheme = 'ELS'

SELECT panel_ref
	  ,[date] AS [date_closed]
	  ,scheme
	  ,#cases.tranche
      ,settlement_time
	  ,defence_costs_billed
	  ,claimants_costs_paid
	  ,damages_paid
	  ,CASE WHEN settlement_time > settlement_time_av THEN 'over' ELSE 'under' END AS [settle_over]
	  ,CASE WHEN defence_costs_billed > defence_costs_av THEN 'over' ELSE 'under' END AS [def_over]
	  ,CASE WHEN damages_paid > ISNULL(damages_av, 0 ) THEN 'over' ELSE 'under' END AS [dam_over]
	  ,CASE WHEN claimants_costs_paid > ISNULL(claimant_costs_av, 0 ) THEN 'over' ELSE 'under' END AS [claimant_costs_over]
	  ,settlement_time_av
	  ,defence_costs_av
	  ,damages_av
	  ,claimant_costs_av
FROM #cases
FULL OUTER JOIN #panel_avg_wide
ON #cases.tranche = #panel_avg_wide.tranche
AND #cases.nhs_scheme = #panel_avg_wide.scheme COLLATE SQL_Latin1_General_CP1_CI_AS
AND #cases.date_claim_concluded = #panel_avg_wide.[date]
WHERE #panel_avg_wide.tranche IS NOT NULL
--AND (CASE WHEN settlement_time > settlement_time_av THEN 1 ELSE 0 END +
--	 CASE WHEN defence_costs_billed > defence_costs_av THEN 1 ELSE 0 END +
--	 CASE WHEN damages_paid > ISNULL(damages_av, 0 ) THEN 1 ELSE 0 END > 0)
ORDER BY
	 CASE WHEN settlement_time > settlement_time_av THEN 1 ELSE 0 END +
	 CASE WHEN defence_costs_billed > defence_costs_av THEN 1 ELSE 0 END +
	 CASE WHEN damages_paid > ISNULL(damages_av, 0 ) THEN 1 ELSE 0 END +
	 CASE WHEN claimants_costs_paid > ISNULL(claimant_costs_av, 0 ) THEN 1 ELSE 0 END DESC

END
GO
