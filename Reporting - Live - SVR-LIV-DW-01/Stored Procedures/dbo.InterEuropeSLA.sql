SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-07-13
-- Description:	#63848 New Report for InterEurope Governance by Helen Fox
-- =============================================
CREATE PROCEDURE [dbo].[InterEuropeSLA]

AS
BEGIN
	
	SET NOCOUNT ON;

   SELECT RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number AS [Client and Matter Ref]
	, matter_owner_full_name AS [Weightmans Fee Earner]
	, matter_description AS [Matter Description]
	, date_instructions_received AS [Date Instructions Received]
	, date_opened_case_management AS [Date Opened in MS]
	, CASE WHEN ll00_have_we_had_an_extension_for_the_initial_report='Yes' THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](date_report_due, GETDATE())
		ELSE [dbo].[ReturnElapsedDaysExcludingBankHolidays](ISNULL(date_instructions_received,date_opened_case_management), GETDATE()) END AS [Days file at Weightmans/ days to report due if extension  (working days)]
	, CASE WHEN (CASE WHEN ll00_have_we_had_an_extension_for_the_initial_report='Yes' THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](date_report_due, GETDATE())
		ELSE [dbo].[ReturnElapsedDaysExcludingBankHolidays](ISNULL(date_instructions_received,date_opened_case_management), GETDATE()) END) <=7 THEN 'LimeGreen'
		WHEN (CASE WHEN ll00_have_we_had_an_extension_for_the_initial_report='Yes' THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](date_report_due, GETDATE())
		ELSE [dbo].[ReturnElapsedDaysExcludingBankHolidays](ISNULL(date_instructions_received,date_opened_case_management), GETDATE()) END) <=9 THEN 'Orange'
		WHEN (CASE WHEN ll00_have_we_had_an_extension_for_the_initial_report='Yes' THEN [dbo].[ReturnElapsedDaysExcludingBankHolidays](date_report_due, GETDATE())
		ELSE [dbo].[ReturnElapsedDaysExcludingBankHolidays](ISNULL(date_instructions_received,date_opened_case_management), GETDATE()) END) >=10 THEN 'Red' END AS [Days to Report RAG]
	, ll00_have_we_had_an_extension_for_the_initial_report AS [Extention Requested]
	, date_report_due AS [Date Initial Report Due]
	, date_initial_report_sent AS [Date Intial Report Sent]
	, [dbo].[ReturnElapsedDaysExcludingBankHolidays](ISNULL(date_instructions_received,date_opened_case_management),date_initial_report_sent) AS [Days to send initial report (working days)]
	, date_subsequent_sla_report_sent AS [Date of Last Subsequent Report]
	, AllSubsDates.AllSubsDate AS [Subsequent Report Dates]
	, DATEDIFF(DAY, date_subsequent_sla_report_sent, GETDATE()) AS [Days Since Subsequent Report Sent]
	, CASE WHEN date_claim_concluded IS NULL THEN DATEDIFF(DAY, ISNULL(date_subsequent_sla_report_sent, date_initial_report_sent), GETDATE()) ELSE NULL END AS [Next Report Due]
	, CASE WHEN (CASE WHEN date_claim_concluded IS NULL THEN DATEDIFF(DAY, ISNULL(date_subsequent_sla_report_sent, date_initial_report_sent), GETDATE()) ELSE NULL END) BETWEEN 45 AND 79 THEN 'LimeGreen'
			WHEN (CASE WHEN date_claim_concluded IS NULL THEN DATEDIFF(DAY, ISNULL(date_subsequent_sla_report_sent, date_initial_report_sent), GETDATE()) ELSE NULL END) BETWEEN 80 AND 89 THEN 'Orange'
			WHEN (CASE WHEN date_claim_concluded IS NULL THEN DATEDIFF(DAY, ISNULL(date_subsequent_sla_report_sent, date_initial_report_sent), GETDATE()) ELSE NULL END) >=90 THEN 'Red'
			END AS [Next Report Due RAG]
	, date_claim_concluded AS [Date Claim Concluded]
	, AllTrialDates.[Trial Dates] AS [Date of Trial]
	, NextTrialDate.[Next Trial Date] AS [Date of Next Trial]
	, DATEDIFF(DAY, GETDATE(),NextTrialDate.[Next Trial Date]) AS [Days to Trial]
	, DATEDIFF(DAY, date_subsequent_sla_report_sent, NextTrialDate.[Next Trial Date]) AS [Days since last report to Trial date (SLA 35 days)]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN (SELECT DISTINCT RTRIM(dim_tasks.client_code) client_code
							, dim_tasks.matter_number
							, MIN(CAST(calendar_date AS DATE)) AS [Next Trial Date] 
						FROM red_dw.dbo.dim_tasks
						LEFT OUTER JOIN red_dw.dbo.fact_tasks ON fact_tasks.dim_tasks_key = dim_tasks.dim_tasks_key
						LEFT OUTER JOIN red_dw.dbo.dim_date ON dim_date_key=dim_task_due_date_key
						WHERE task_desccription = 'Trial date - today'
						AND dim_tasks.client_code ='00351402'
						AND calendar_date>GETDATE()
						GROUP BY RTRIM(dim_tasks.client_code), dim_tasks.matter_number) AS [NextTrialDate] 
				ON [NextTrialDate].client_code = fact_dimension_main.client_code
				AND [NextTrialDate].matter_number = fact_dimension_main.matter_number
LEFT OUTER JOIN (SELECT DISTINCT RTRIM(dim_tasks.client_code) client_code
							, dim_tasks.matter_number
							, STRING_AGG(CONVERT(VARCHAR(10),calendar_date,103),', ') WITHIN GROUP( ORDER BY calendar_date ASC) [Trial Dates] 
						FROM red_dw.dbo.dim_tasks
						LEFT OUTER JOIN red_dw.dbo.fact_tasks ON fact_tasks.dim_tasks_key = dim_tasks.dim_tasks_key
						LEFT OUTER JOIN red_dw.dbo.dim_date ON dim_date_key=dim_task_due_date_key
						WHERE task_desccription = 'Trial date - today'
						AND dim_tasks.client_code ='00351402'
						GROUP BY RTRIM(dim_tasks.client_code), dim_tasks.matter_number) AS [AllTrialDates] 
				ON AllTrialDates.client_code = fact_dimension_main.client_code
				AND ALLTrialDates.matter_number = fact_dimension_main.matter_number
LEFT OUTER JOIN (
SELECT fileid
	, STRING_AGG(subdate,', ') WITHIN GROUP( ORDER BY dtesubslarepsen asc) AS [AllSubsDate]
	FROM (SELECT DISTINCT fileid
			, dtesubslarepsen
			, CONVERT(VARCHAR(10),dtesubslarepsen,103) AS subdate
		FROM red_dw.dbo.ds_sh_ms_udmicoregeneral_history 
		WHERE dtesubslarepsen IS NOT NULL 
		) AS t
		GROUP BY t.fileid) AS [AllSubsDates] ON AllSubsDates.fileid=ms_fileid

WHERE dim_matter_header_current.master_client_code='351402'
AND reporting_exclusions=0
AND date_claim_concluded IS NULL
AND date_opened_case_management>='2020-01-01'

END
GO
