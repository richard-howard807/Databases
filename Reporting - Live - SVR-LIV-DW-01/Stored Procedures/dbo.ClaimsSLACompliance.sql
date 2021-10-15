SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Emily Smith
-- Create date: 2019-10-28
-- Description:	New report for Claims SLA Compliance
-- =============================================
-- ===========================================================================================================================
-- Changed SP to populate Reporting.dbo.ClaimsSLAComplianceTable instead, to speed up the report rather than running it live
-- ===========================================================================================================================

CREATE PROCEDURE [dbo].[ClaimsSLACompliance] --EXEC [dbo].[ClaimsSLACompliance]

AS

BEGIN

DECLARE @nDate AS DATETIME = (SELECT MIN(dim_date.calendar_date) FROM red_dw..dim_date WHERE dim_date.fin_year = (SELECT fin_year - 3 FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = CAST(GETDATE() AS DATE)))


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('Reporting.dbo.ClaimsSLAComplianceTable') IS NOT NULL DROP TABLE  Reporting.dbo.ClaimsSLAComplianceTable

	IF OBJECT_ID('tempdb..#FICProcess') IS NOT NULL DROP TABLE #FICProcess
	IF OBJECT_ID('tempdb..#nhs_key_dates') IS NOT NULL DROP TABLE #nhs_key_dates
	IF OBJECT_ID('tempdb..#nhs_first_report_lifecycle') IS NOT NULL DROP TABLE #nhs_first_report_lifecycle
	IF OBJECT_ID('tempdb..#ClientReportDates') IS NOT NULL DROP TABLE #ClientReportDates

	SELECT fileID, tskDesc, tskDue, tskCompleted 
	INTO #FICProcess
	FROM MS_Prod.dbo.dbTasks
	WHERE (tskDesc LIKE 'FIC Process'
	OR tskDesc LIKE '%ADM: Complete fraud indicator checklist%')
	AND tskActive=1;

--========================================================================================================================================
-- NHS key dates used in multiple queries
--========================================================================================================================================
--IF OBJECT_ID('tempdb..#nhs_key_dates') IS NOT NULL DROP TABLE #nhs_key_dates
SELECT *
INTO #nhs_key_dates
FROM (
		SELECT 
			dim_key_dates.dim_matter_header_curr_key
			, dim_key_dates.description
			, dim_key_dates.key_date
			, dim_key_dates.days_to_key_date
			, ROW_NUMBER() OVER(PARTITION BY dim_key_dates.dim_matter_header_curr_key ORDER BY dim_key_dates.key_date)	AS rw
		--SELECT dim_key_dates.*
		FROM red_dw.dbo.dim_key_dates
			INNER JOIN red_dw.dbo.dim_matter_header_current
				ON dim_matter_header_current.dim_matter_header_curr_key = dim_key_dates.dim_matter_header_curr_key
			LEFT OUTER JOIN red_dw.dbo.dim_detail_health
				ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		WHERE 1 = 1
			AND dim_matter_header_current.master_client_code = 'N1001'
			AND dim_key_dates.description IN ('Date Letter of response due')
			AND dim_detail_health.nhs_instruction_type IN ('ISS 250', 'ISS 250 Advisory', 'ISS Plus', 'ISS Plus Advisory')
			AND dim_key_dates.is_active = 1
			--AND dim_key_dates.dim_matter_header_curr_key = 1219493

		UNION

		SELECT 
			dim_key_dates.dim_matter_header_curr_key
			, dim_key_dates.description
			, dim_key_dates.key_date
			, dim_key_dates.days_to_key_date
			, ROW_NUMBER() OVER(PARTITION BY dim_key_dates.dim_matter_header_curr_key ORDER BY dim_key_dates.key_date)	AS rw
		FROM red_dw.dbo.dim_key_dates
			INNER JOIN red_dw.dbo.dim_matter_header_current
				ON dim_matter_header_current.dim_matter_header_curr_key = dim_key_dates.dim_matter_header_curr_key
			LEFT OUTER JOIN red_dw.dbo.dim_detail_health
				ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		WHERE 1 = 1
			AND dim_matter_header_current.master_client_code = 'N1001'
			AND dim_key_dates.description IN ('Date Schedule 5 expert summit')
			AND dim_detail_health.nhs_instruction_type IN ('Schedule 4 (ENS)', 'Schedule 5 (ENS)')
			AND dim_key_dates.is_active = 1
	) AS key_dates
WHERE
	key_dates.rw = 1

--==========================================================================================================================================================
-- added #nhs_first_report_lifecycle table as it was slowing the #ClientReportDates table down too much when added as a sub query
--==========================================================================================================================================================
--IF OBJECT_ID('tempdb..#nhs_first_report_lifecycle') IS NOT NULL DROP TABLE #nhs_first_report_lifecycle
SELECT 
	dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_matter_number
	, dim_matter_header_current.dim_matter_header_curr_key
	, #nhs_key_dates.key_date
	, dim_detail_core_details.date_initial_report_sent
	, CASE 
		WHEN #nhs_key_dates.key_date IS NOT NULL THEN
			CASE
				WHEN dim_detail_core_details.do_clients_require_an_initial_report = 'No'  THEN 
					NULL
				WHEN dim_detail_core_details.date_initial_report_sent IS NOT NULL THEN
					DATEDIFF(DAY, dim_detail_core_details.date_initial_report_sent, #nhs_key_dates.key_date)
				ELSE
					DATEDIFF(DAY, GETDATE(), #nhs_key_dates.key_date)
			END
		ELSE
			NULL		
	  END			AS nhs_days_to_lor_schedule5
	, CASE 
		WHEN dim_detail_core_details.do_clients_require_an_initial_report = 'No'  THEN 
			NULL
		WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers > dim_detail_core_details.date_initial_report_sent 
		AND dim_detail_core_details.date_instructions_received < dim_matter_header_current.date_opened_case_management THEN 
			DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, ISNULL(dim_detail_core_details.date_initial_report_sent, GETDATE()))
		WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers > dim_detail_core_details.date_initial_report_sent 
		AND dim_detail_core_details.date_instructions_received >= dim_matter_header_current.date_opened_case_management THEN 
			DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_core_details.date_initial_report_sent, GETDATE()))
		WHEN RTRIM(dim_detail_core_details.referral_reason) = 'Nomination only' THEN
			DATEDIFF(DAY, dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers, ISNULL(dim_detail_core_details.date_initial_report_sent, GETDATE())) 
		WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers >= dim_matter_header_current.date_opened_case_management THEN 
			DATEDIFF(DAY, dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers, ISNULL(dim_detail_core_details.date_initial_report_sent, GETDATE()))
		WHEN dim_detail_core_details.date_instructions_received < dim_matter_header_current.date_opened_case_management THEN 
			DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, ISNULL(dim_detail_core_details.date_initial_report_sent, GETDATE())) 
		ELSE 
			DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_core_details.date_initial_report_sent, GETDATE()))
		END				AS nhs_days_to_first_report_lifecycle
INTO #nhs_first_report_lifecycle
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #nhs_key_dates
		ON #nhs_key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND (dim_matter_header_current.date_closed_case_management IS NULL 
		OR dim_matter_header_current.date_closed_case_management>='2017-01-01')


--=========================================================================================================================================================================================================================================================================
-- table to deal with lengthy client report date logics used multiple times 
-- Ticket #101719 - NHS matters, based on the nhs_instruction_type, have a lot of different SLA rules which are based on days rather than working days
--=========================================================================================================================================================================================================================================================================

SELECT 
	dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_matter_number
	, CASE 
		WHEN dim_matter_header_current.master_client_code = 'N1001' THEN
			dim_detail_health.nhs_instruction_type
		ELSE
			NULL
	  END					AS nhs_instruction_type
	, ClientSLAsNHSR.nhs_instruction_type AS nhs_sla_instruction_type
	, COALESCE(ClientSLAs.initial_report_rule, ClientSLAsNHSR.initial_report_rule)		AS initial_report_rules
	/*
		Rather than checking against master_client_code for 'N1001' matters, 
		we need to look for matters that have an nhs_instruction_type that matches the ClientSLAsNHSR.nhs_instruction_type.
		This is due to not all N1001 matters have an instruction type completed or 1 that matches the SLA table that we have rules for 
		so they will need to use the default SLA rules (which is working days)
	*/
	, ClientSLAsNHSR.inverted_initial_rule
	, CASE
		WHEN ClientSLAsNHSR.inverted_initial_rule = 'Yes' THEN
			#nhs_first_report_lifecycle.nhs_days_to_lor_schedule5
	  END			AS inverted_days_to_first_report_lifecycle
	, CASE
		WHEN ClientSLAsNHSR.inverted_initial_rule = 'Yes' THEN
			NULL
		WHEN ClientSLAsNHSR.nhs_instruction_type IS NOT NULL THEN
			#nhs_first_report_lifecycle.nhs_days_to_first_report_lifecycle
		ELSE 
			fact_detail_elapsed_days.days_to_first_report_lifecycle
	  END					AS days_to_first_report_lifecycle
	, CASE	
		WHEN ClientSLAsNHSR.nhs_instruction_type IS NOT NULL THEN
			ClientSLAsNHSR.initial_report_sla_days
		ELSE
			ClientSLAs.[Initial Report SLA (days)]
	  END							AS initial_report_days
	, CASE
		WHEN ClientSLAsNHSR.nhs_instruction_type IS NOT NULL THEN
			ClientSLAsNHSR.subsequent_report_rule
		ELSE
			ClientSLAs.[Update Report SLA]
	  END											AS update_report_sla	
	, CASE
		WHEN dim_matter_header_current.master_client_code IN ('N1001', '43006') 
		AND dim_detail_core_details.trust_type_of_instruction IN ('In-house: CN', 'In-house: COP', 'In-house: EL/PL', 'In-house: General', 'In-house: INQ', 'In-house: Secondment') THEN
			'No'
		WHEN ISNULL(ClientSLAsNHSR.do_clients_require_initial_report, '') = 'No' THEN
			'No'
		WHEN ISNULL(ClientSLAs.do_clients_require_initial_report, '') = 'No' THEN
			'No'
		ELSE
        	dim_detail_core_details.do_clients_require_an_initial_report
	  END			AS do_clients_require_an_initial_report 
	, CASE
		WHEN dim_matter_header_current.master_client_code = 'N1001' THEN
			IIF(ClientSLAsNHSR.subsequent_report_rule = 'subsequent report not needed', 0, ClientSLAsNHSR.subsequent_report_working_days)
		ELSE
			ClientSLAs.[Update Report SLA (working days)]
	  END				AS update_report_sla_working_days
	/*
	Initial Report due date
	*/
	, CASE 
		WHEN ClientSLAsNHSR.nhs_instruction_type IS NOT NULL THEN 
			CASE
				WHEN ClientSLAsNHSR.do_clients_require_initial_report = 'No' THEN
					NULL
				WHEN ClientSLAsNHSR.inverted_initial_rule = 'Yes' THEN
					NULL --DATEADD(DAY, -ClientSLAsNHSR.initial_report_sla_days, #nhs_key_dates.key_date)		
				WHEN dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report = 'Yes' THEN 
					dim_detail_core_details.date_initial_report_due
				WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NOT NULL THEN 
					DATEADD(DAY, ClientSLAsNHSR.initial_report_sla_days, CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE))
				WHEN date_initial_report_due IS NULL THEN
					DATEADD(DAY, ClientSLAsNHSR.initial_report_sla_days, CAST(date_opened_case_management AS DATE)) 
				WHEN date_initial_report_due IS NOT NULL THEN
					dim_detail_core_details.date_initial_report_due
				ELSE 
					NULL 
			END	
		ELSE
			CASE
				WHEN dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report = 'Yes' THEN
					date_initial_report_due
				WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NOT NULL THEN 
					[dbo].[AddWorkDaysToDate](CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10))
				WHEN date_initial_report_due IS NULL THEN 
					[dbo].[AddWorkDaysToDate](CAST(date_opened_case_management AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10)) 
				ELSE 
					date_initial_report_due 
				END
	  END						AS [initial_report_due]
	, CASE
		WHEN ClientSLAsNHSR.inverted_initial_rule = 'Yes' THEN
			DATEADD(DAY, -ClientSLAsNHSR.initial_report_sla_days, #nhs_key_dates.key_date)
	  END				AS [inverted_initial_report_due]
	/*
	Subsequent report due date
	*/
	, CASE 
		WHEN RTRIM(dim_detail_core_details.present_position) IN (
																	'Final bill due - claim and costs concluded',
																	'Final bill sent - unpaid',
																	'To be closed/minor balances to be clear'            
																) THEN
			NULL
		WHEN dim_detail_core_details.date_initial_report_sent IS NULL AND dim_detail_core_details.date_subsequent_sla_report_sent IS NULL THEN
			NULL
		WHEN dim_matter_header_current.master_client_code IN ('N1001', '43006') 
		AND dim_detail_core_details.trust_type_of_instruction IN ('In-house: CN', 'In-house: COP', 'In-house: EL/PL', 'In-house: General', 'In-house: INQ', 'In-house: Secondment') THEN
			NULL
		WHEN ISNULL(ClientSLAsNHSR.do_clients_require_initial_report, '') = 'No' THEN
			NULL
		WHEN ISNULL(ClientSLAs.do_clients_require_initial_report, '') = 'No' THEN
			NULL
		WHEN dim_detail_core_details.do_clients_require_an_initial_report = 'No' THEN
			NULL
		--SELECT ClientSLAsNHSR.subsequent_report_rule FROM dbo.ClientSLAsNHSR WHERE ClientSLAsNHSR.nhs_instruction_type = 'Schedule 5 (ENS)'
		WHEN ClientSLAsNHSR.nhs_instruction_type = 'Schedule 5 (ENS)' THEN 
			CASE
				--Every 3 months, until summit and every 3 months thereafter
				WHEN dim_detail_core_details.date_subsequent_sla_report_sent >= DATEADD(DAY, 28, ISNULL(#nhs_key_dates.key_date, '1900-01-01')) THEN
					CASE
						WHEN DATENAME(wk, DATEADD(MONTH, ClientSLAsNHSR.subsequent_report_months, dim_detail_core_details.date_subsequent_sla_report_sent))= 'Saturday'THEN 
							DATEADD(MONTH, ClientSLAsNHSR.subsequent_report_months, dim_detail_core_details.date_subsequent_sla_report_sent)+2
						WHEN DATENAME(wk, DATEADD(MONTH, ClientSLAsNHSR.subsequent_report_months, dim_detail_core_details.date_subsequent_sla_report_sent))= 'Sunday'THEN 
							DATEADD(MONTH, ClientSLAsNHSR.subsequent_report_months, dim_detail_core_details.date_subsequent_sla_report_sent)+1
						ELSE 
							DATEADD(MONTH, ClientSLAsNHSR.subsequent_report_months, dim_detail_core_details.date_subsequent_sla_report_sent)
					END			
				--28 days before expert summit
				WHEN ISNULL(dim_detail_core_details.date_subsequent_sla_report_sent, '1900-01-01') < DATEADD(DAY, -28, #nhs_key_dates.key_date) THEN 
					CASE
						WHEN DATENAME(wk, DATEADD(DAY, -28, #nhs_key_dates.key_date))= 'Saturday'THEN 
							DATEADD(DAY, -28, #nhs_key_dates.key_date)+2
						WHEN DATENAME(wk, DATEADD(DAY, -28, #nhs_key_dates.key_date))= 'Sunday'THEN 
							DATEADD(DAY, -28, #nhs_key_dates.key_date)+1
						ELSE 
							DATEADD(DAY, -28, #nhs_key_dates.key_date)
					END	
				--28 days after expert summit
				WHEN ISNULL(dim_detail_core_details.date_subsequent_sla_report_sent, '1900-01-01') NOT BETWEEN #nhs_key_dates.key_date AND DATEADD(DAY, 28, #nhs_key_dates.key_date) THEN
					CASE
						WHEN DATENAME(wk, DATEADD(DAY, 28, #nhs_key_dates.key_date))= 'Saturday'THEN 
							DATEADD(DAY, 28, #nhs_key_dates.key_date)+2
						WHEN DATENAME(wk, DATEADD(DAY, 28, #nhs_key_dates.key_date))= 'Sunday'THEN 
							DATEADD(DAY, 28, #nhs_key_dates.key_date)+1
						ELSE 
							DATEADD(DAY, 28, #nhs_key_dates.key_date)
					END				
				--8 weeks from instructions
				WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL THEN
					CASE
						WHEN DATENAME(wk, DATEADD(WEEK, 8, dim_matter_header_current.date_opened_case_management))= 'Saturday'THEN 
							DATEADD(WEEK, 8, dim_matter_header_current.date_opened_case_management)+2
						WHEN DATENAME(wk, DATEADD(WEEK, 8, dim_matter_header_current.date_opened_case_management))= 'Sunday'THEN 
							DATEADD(WEEK, 8, dim_matter_header_current.date_opened_case_management)+1
						ELSE 
							DATEADD(WEEK, 8, dim_matter_header_current.date_opened_case_management)
					END	
			END	
		WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NOT NULL THEN 
			CASE 
				-- Needing to make sure future date is a weekday
				WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Saturday' THEN
					DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+2
				WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Sunday' THEN
					DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+1
				ELSE 
					DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)
			END
		WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL THEN
			CASE 
				-- Needing to make sure future date is a weekday
				WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Saturday' THEN
					DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_initial_report_sent)+2
				WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Sunday' THEN
					DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_initial_report_sent)+1
				ELSE 
					DATEADD(MONTH, ISNULL(CAST(COALESCE(ClientSLAsNHSR.subsequent_report_months, ClientSLAs.[Update Report SLA (months)]) AS INT), 3), dim_detail_core_details.date_initial_report_sent)
			END
		ELSE 
			NULL
		END									AS [date_subsequent_report_due]
INTO #ClientReportDates
FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
		ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN Reporting.dbo.ClientSLAs 
		ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN Reporting.dbo.ClientSLAsNHSR
		ON ClientSLAsNHSR.master_client_code = dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT
			AND ClientSLAsNHSR.nhs_instruction_type = dim_detail_health.nhs_instruction_type COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN #nhs_key_dates
		ON #nhs_key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #nhs_first_report_lifecycle
		ON #nhs_first_report_lifecycle.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 
	reporting_exclusions = 0
	AND hierarchylevel2hist = 'Legal Ops - Claims'
	AND (date_closed_case_management IS NULL 
		OR date_closed_case_management >= '2017-01-01')
	--AND dim_matter_header_current.master_client_code = 'N1001'
	--AND dim_detail_health.nhs_instruction_type IN ('Schedule 4 (ENS)', 'Schedule 5 (ENS)', 'ISS 250', 'ISS 250 Advisory', 'ISS Plus', 'ISS Plus Advisory')
	--AND ISNULL(RTRIM(dim_detail_core_details.present_position), 'Missing') IN ('Claim and costs outstanding', 'Claim concluded but costs outstanding', 'Claim and costs concluded but recovery outstanding', 'Missing')
					
--=========================================================================================================================================================================================================================================================================
--=========================================================================================================================================================================================================================================================================


SELECT 
	client_name AS [Client Name]
	, dim_matter_header_current.client_group_name
	, dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_matter_number
	, dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, name AS [Matter Owner]
	, dim_fed_hierarchy_history.employeeid
	, dim_matter_header_current.fee_earner_code
	, hierarchylevel4hist AS [Team]
	, hierarchylevel3hist AS [Department]
	, CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Status]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number			 AS [Mattersphere Weightmans Reference]
	, dim_detail_core_details.present_position AS [Present Position]
	, #ClientReportDates.nhs_instruction_type	AS [NHS Instruction Type (N1001 Only)]
	, date_opened_case_management AS [Date Opened]
	, date_closed_case_management AS [Date Closed]
	, date_instructions_received AS [Date Instructions Received]
	, CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END AS [Days to File Opened from Date Instructions Received]
	, date_initial_report_sent AS [Date Initial Report Sent]
	, #ClientReportDates.do_clients_require_an_initial_report AS [Do Clients Require an Initial Report?]
	, dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date Receipt of File Papers]
	, [ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension?]
	, #ClientReportDates.initial_report_due				AS [Date Initial Report Due (if extended)]
	, #ClientReportDates.inverted_initial_report_due	AS [Inverted Date Initial Report Due]
	, #ClientReportDates.initial_report_rules							AS [Initial Report Rules]
	, #ClientReportDates.inverted_initial_rule
	--, dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent) AS [Days to Send Intial Report]
	--, CASE WHEN #ClientReportDates.do_clients_require_an_initial_report = 'No' THEN NULL
	--	WHEN date_initial_report_sent IS NOT NULL THEN NULL
	--	WHEN date_initial_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())
	--	WHEN date_initial_report_sent IS NULL AND dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())<[Initial Report SLA (days)] THEN 'Not yet due'
	--	ELSE NULL END AS [Days without Initial Report]
	, date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]
	, CASE 
		WHEN #ClientReportDates.do_clients_require_an_initial_report = 'No' OR
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN
			NULL
		WHEN ISNULL(#ClientReportDates.update_report_sla, '') = 'subsequent report not needed' THEN
			NULL
		WHEN date_subsequent_sla_report_sent IS NULL THEN 
			dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE())
		WHEN date_subsequent_sla_report_sent IS NOT NULL THEN 
			dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE())
		ELSE
			NULL
	  END				AS [Days without Subsequent Report]
	, 1					AS [Number of Files]
	,CASE WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN NULL ELSE #ClientReportDates.days_to_first_report_lifecycle END AS avglifecycle 
	, CASE 
		WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN 
			NULL 
		WHEN #ClientReportDates.inverted_initial_rule = 'Yes' THEN 
			#ClientReportDates.inverted_days_to_first_report_lifecycle 
		ELSE 
			NULL
	  END AS inverted_avglifecycle 
	, IIF(ISNULL(#ClientReportDates.do_clients_require_an_initial_report, '') ='No', NULL, #ClientReportDates.days_to_first_report_lifecycle)		AS days_to_first_report_lifecycle
	, #ClientReportDates.inverted_days_to_first_report_lifecycle
	,dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?]
	,FICProcess.tskDue
	,FICProcess.tskCompleted
	,FICProcess.tskDesc
	--Client SLA's
	, CASE 
		WHEN dim_matter_header_current.master_client_code = 'N1001' THEN
			1
		ELSE
			[File Opening SLA (days)]
	  END									AS [File Opening SLA (days)]
	, CASE 
		WHEN dim_matter_header_current.master_client_code = 'N1001' THEN
			1
		ELSE	
			ISNULL(ClientSLAs.[File Opening SLA (days)], 2)		
	  END											AS [File Opening SLA hidden on report for highlighting]
	, #ClientReportDates.initial_report_days		AS [Initial Report SLA (days)]
	, CASE
		WHEN #ClientReportDates.do_clients_require_an_initial_report = 'No' THEN
			0
		ELSE
        	ISNULL(#ClientReportDates.initial_report_days, 10)	
	  END														AS [Initial Report SLA hidden on report for highlighting]
	, #ClientReportDates.update_report_sla		AS [Update Report SLA]
	, #ClientReportDates.update_report_sla_working_days											AS [Update Report SLA (working days)]
	, ISNULL(#ClientReportDates.update_report_sla_working_days, 63)		AS [Update Report SLA hidden on report for highlighting]
	, CASE 
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END) <0 THEN 
				'Transparent'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END) <= ISNULL([File Opening SLA (days)], 2) THEN 
				'LimeGreen'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END) > ISNULL([File Opening SLA (days)], 2) THEN 
				'Red'
			ELSE 
				'Transparent' 
	  END					AS [File Opening RAG]
	, #ClientReportDates.nhs_sla_instruction_type
	, CASE 
			WHEN ISNULL(#ClientReportDates.inverted_initial_rule, '') = 'Yes' THEN 
				'Transparent'
			WHEN ISNULL(#ClientReportDates.do_clients_require_an_initial_report, '') = 'No' THEN	
				'Transparent'
			WHEN ISNULL(dim_detail_core_details.referral_reason, '') = 'Nomination only' AND dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NULL THEN
				'Transparent'
			WHEN date_initial_report_sent IS NULL THEN	
				CASE	
					WHEN #ClientReportDates.nhs_sla_instruction_type IS NOT NULL 
					AND DATEDIFF(DAY, CAST(GETDATE() AS DATE), #ClientReportDates.initial_report_due) BETWEEN 0 AND 5 THEN
						'Orange'
					WHEN #ClientReportDates.nhs_sla_instruction_type IS NULL 
					AND dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.initial_report_due) BETWEEN 0 AND 5 THEN
						'Orange'
					WHEN (#ClientReportDates.days_to_first_report_lifecycle) > ISNULL(#ClientReportDates.initial_report_days, 10) THEN 
						'Red'
					WHEN CAST(GETDATE() AS DATE) < #ClientReportDates.initial_report_due THEN
						'LimeGreen'
				END 
			WHEN (#ClientReportDates.days_to_first_report_lifecycle) < 0 THEN 
				'Transparent'
			WHEN (#ClientReportDates.days_to_first_report_lifecycle) <= ISNULL(#ClientReportDates.initial_report_days, 10) THEN 
				'LimeGreen'
			WHEN (#ClientReportDates.days_to_first_report_lifecycle) > ISNULL(#ClientReportDates.initial_report_days, 10) THEN 
				'Red'
			ELSE 
				'Transparent' 
		END					AS [NEW Initial Report RAG]
	, CASE 
			WHEN #ClientReportDates.inverted_initial_rule = 'Yes' THEN 
				CASE
					WHEN #ClientReportDates.do_clients_require_an_initial_report = 'No' THEN
						'Transparent'
					WHEN dim_detail_core_details.date_initial_report_sent IS NULL 
					AND #ClientReportDates.inverted_days_to_first_report_lifecycle BETWEEN #ClientReportDates.initial_report_days AND #ClientReportDates.initial_report_days + 5 THEN  -- 5 days before report is due and the report hasn't been sent yet
						'Orange'
					WHEN #ClientReportDates.inverted_days_to_first_report_lifecycle < #ClientReportDates.initial_report_days THEN
						'Red'
					WHEN #ClientReportDates.inverted_days_to_first_report_lifecycle >= #ClientReportDates.initial_report_days THEN
						'LimeGreen'
					ELSE
						'Transparent'
				END
	  END							AS [Inverted Initial Report RAG]
	, CASE 
		WHEN (CASE 
					WHEN ISNULL(#ClientReportDates.do_clients_require_an_initial_report, '') = 'No' OR
									RTRIM(dim_detail_core_details.present_position) IN (
																					'Final bill due - claim and costs concluded',
																					'Final bill sent - unpaid',
																					'To be closed/minor balances to be clear'            
																				) THEN
						-1
					WHEN date_subsequent_sla_report_sent IS NULL THEN 
						dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE())
					WHEN date_subsequent_sla_report_sent IS NOT NULL THEN 
						dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE())
					ELSE
						NULL
				END) < 0 THEN
			'Transparent'
		WHEN ISNULL(#ClientReportDates.update_report_sla, '') = 'subsequent report not needed' THEN
			NULL
		WHEN dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
			'Orange'
		WHEN #ClientReportDates.date_subsequent_report_due < CAST(GETDATE() AS DATE) THEN 
			'Red'
		WHEN #ClientReportDates.date_subsequent_report_due IS NULL THEN
			'Transparent'
		ELSE
			'LimeGreen'
	  END								 AS RagWithouthSub
	,referral_reason
	, dim_detail_core_details.delegated
	, CASE 
		WHEN #ClientReportDates.do_clients_require_an_initial_report = 'No' OR
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN
			0
		WHEN date_initial_report_sent IS NULL AND 
				dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS  DATE), COALESCE(#ClientReportDates.initial_report_due, #ClientReportDates.inverted_initial_report_due)) BETWEEN 0 AND 5 THEN
			1
		ELSE 
			0
	  END										AS [Count Initial Report Due In 5 Working Days]
	, CASE 
		WHEN #ClientReportDates.do_clients_require_an_initial_report = 'No' OR 
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN 
			0
		WHEN dim_detail_core_details.date_initial_report_sent IS NULL 
			AND COALESCE(#ClientReportDates.initial_report_due, #ClientReportDates.inverted_initial_report_due) < CAST(GETDATE() AS DATE) THEN
			1
		ELSE 
			0
	  END										AS [Count Initial Report Is Overdue]
	, #ClientReportDates.date_subsequent_report_due			AS [Date Subsequent Report Due]
	, CASE 
		WHEN ISNULL(#ClientReportDates.update_report_sla, '') = 'subsequent report not needed' THEN
			0
		WHEN dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
			1
		ELSE 
			0
	  END				AS [Subsequent Report Due in 10 Working Days]
	, CASE 
		WHEN ISNULL(#ClientReportDates.update_report_sla, '') = 'subsequent report not needed' THEN
			0
		WHEN #ClientReportDates.date_subsequent_report_due < CAST(GETDATE() AS DATE) THEN
			1
		ELSE 
			0
	  END				AS [Subsequent Report is Overdue]

INTO Reporting.dbo.ClaimsSLAComplianceTable
FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #FICProcess FICProcess 
		ON FICProcess.fileID = ms_fileid
	LEFT OUTER JOIN Reporting.dbo.ClientSLAs 
		ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN #ClientReportDates
		ON #ClientReportDates.master_client_code = dim_matter_header_current.master_client_code AND #ClientReportDates.master_matter_number = dim_matter_header_current.master_matter_number
WHERE 
	reporting_exclusions=0
	AND hierarchylevel2hist='Legal Ops - Claims'
	AND (date_closed_case_management IS NULL 
		OR date_closed_case_management>=@nDate)
	AND (dim_detail_outcome.outcome_of_case IS NULL OR RTRIM(LOWER(dim_detail_outcome.outcome_of_case)) <> 'exclude from reports')
	AND (dim_detail_client.zurich_data_admin_exclude_from_reports IS NULL OR RTRIM(LOWER(dim_detail_client.zurich_data_admin_exclude_from_reports)) <> 'yes')
	AND (dim_detail_core_details.referral_reason IS NULL OR RTRIM(LOWER(dim_detail_core_details.referral_reason)) <> 'in house')
	AND dim_matter_header_current.dim_matter_worktype_key <> 609 --Secondments worktype key
	AND dim_fed_hierarchy_history.hierarchylevel4hist <> 'Healthcare Secondments'
	AND LOWER(dim_matter_header_current.matter_description) NOT LIKE '%secondment%'
	AND dim_matter_header_current.ms_only = 1
	-- clause to exclude "General File" matters
	AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number NOT IN (
		'10015-3', 'M1001-7699', '94212-1', 'N12105-238', 'TR00023-61', 'A1001-6044', 'M1001-24582', '2443L-9', 'W15531-506', 'N1001-12300', 
		'N1001-12469', '113147-999', '125409T-21', '732022-2', 'N1001-14159', '754485-1', '516358-8', 'W15373-1858', '9008076-900285', '451638-999', 
		'738632-3', '451638-204', '451638-208', '901838-1', '451638-236', 'N1001-7080', '113147-448', '113147-1036', '451638-1120', 'W16551-1', '13994-7', 
		'A2002-14012', 'W18337-2', 'M00001-11111288', '659-8', 'W18791-1', '113147-1749', '468733-8', '113147-1823', 'TR00023-1001', '610426-135', 
		'N1001-16961', '662257-2', 'W19835-1', '113147-2016', 'W15508-229', '10466-103', 'W18762-5', 'W15414-23', 'W20163-69', 'N1001-17768', '720451-1029', 
		'W17369-25', '113147-2543', '113147-2592', '451638-3592', '451638-3667', '451638-3751', 'W23663-1', 'W23671-1', 'W23696-1', 'TR00023-999', 'TR00010-999',
		'N1001-8667', 'N1001-9879', 'N1001-13752', 'N1001-7817', 'R1001-5933', '739845-99', 'W15572-721', '748359-999', 'W15434-166', '9008076-900999', '1328-227',
		'TR00010-35', 'N1001-13754', '739845-999', '732022-13', '452904-1021', '113147-3466', 'W19702-17', '195691-1031'
		)
	AND (CASE 
			WHEN dim_matter_header_current.master_client_code IN ('113147', '451638') AND ISNULL(dim_detail_client.billing_group, '') NOT IN ('F', 'A') THEN 
				1
			ELSE
				0
		END) = 0
	AND ISNULL(dim_matter_header_current.dim_matter_worktype_key, '') <> 32 --Claims handling matter types removed as they don't have KPIs like this
	--AND ISNULL(#ClientReportDates.do_clients_require_an_initial_report, '') = 'No'
END



GO
