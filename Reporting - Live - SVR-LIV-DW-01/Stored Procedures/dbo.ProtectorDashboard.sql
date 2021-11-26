SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021/10/07
-- Description:	#117334, data used for new version of Protector Dashboard, requested by KM
-- =============================================
CREATE PROCEDURE [dbo].[ProtectorDashboard]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID(N'tempdb..#KeyDates') IS NOT NULL
BEGIN
DROP TABLE #KeyDates
END
SELECT t.dim_matter_header_curr_key,
MAX(red_dw.dbo.dim_task_due_date.calendar_date) AS [TaskDueDate]
INTO #KeyDates
FROM [red_dw].[dbo].[fact_tasks] t WITH(NOLOCK)
  INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
   ON dim_matter_header_current.dim_matter_header_curr_key = t.dim_matter_header_curr_key
  JOIN [red_dw].[dbo].[dim_tasks] dimt WITH(NOLOCK) ON t.dim_tasks_key = dimt.dim_tasks_key
  LEFT OUTER JOIN red_dw.dbo.dim_task_due_date WITH(NOLOCK)
   ON dim_task_due_date.dim_task_due_date_key = t.dim_task_due_date_key
  WHERE 
     (t.task_code IN ('TRAA0348', 'NHSA0183')  -- Task Codes TRAA0348 REM: Trial due today - [CASE MAN] ,     REM: Disposal hearing due today [CASE MAN]   
	 OR dimt.task_desccription IN ('Trial date - today' ,  'Trial window - today')   )
	 AND master_client_code IN
	 ('W17427','W15632','W15366','W15442','W20163')
     
GROUP BY  t.dim_matter_header_curr_key


SELECT DISTINCT RTRIM(fact_dimension_main.client_code)+'-'+fact_dimension_main.matter_number AS [Weightmans Reference]
	, fact_dimension_main.client_code AS [Client Code]
	, fact_dimension_main.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, dim_matter_header_current.client_name AS [Client Name]
	, date_instructions_received AS [Date Instructions Received]
	, date_opened_case_management AS [Date Opened]
	, date_closed_case_management AS [Date Closed]
	, dim_fed_hierarchy_history.name AS [Matter Owner]
	, hierarchylevel3hist AS [Department]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, suspicion_of_fraud AS [Suspicion of Fraud]
	, dim_detail_core_details.track AS [Track]
	, work_type_name AS [Work Type Name]
	, work_type_group AS [Work Type Group]
	, client_reference [Client Reference]
	, dim_detail_core_details.clients_claims_handler_surname_forename AS [Clients Claim Handler] 
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_detail_core_details.[referral_reason] [Referral Reason] 
	, dim_detail_core_details.[credit_hire] [Credit Hire?]
	, claimantsols_name AS [Claimant Solicitor]
	, dim_detail_core_details.[date_initial_report_sent] [Date Initial Report]
	, dim_detail_core_details.[date_subsequent_sla_report_sent] [Date of Subsequent Report]
	, outcome_of_case AS [Outcome]
	, dim_detail_outcome.repudiation_outcome AS [Repudiation]
	, date_claim_concluded AS [Date Claim Concluded]
	, fact_finance_summary.[damages_reserve] [Damages Reserve Current]
	, fact_detail_reserve_detail.[claimant_costs_reserve_current] [Claimants Cost Reserve Current]
    , fact_finance_summary.[defence_costs_reserve] [Defence Cost Reserve Current] 
	, damages_paid AS [Damages Paid]
	, claimants_costs_paid AS [TP Costs Paid]
	, dim_detail_outcome.[date_costs_settled] [Date Costs Settled] 
	, fact_finance_summary.[tp_total_costs_claimed] [Claimants Total Costs Claimed against Client]
    , fact_finance_summary.[claimants_costs_paid] [Claimant's Costs Paid by Client - Disease]
	, defence_costs_billed AS [Revenue]
	, wip AS [WIP]
	, elapsed_days_damages AS [Damages Lifecycle]
	, elapsed_days_costs AS [Costs Lifecycle]
	, proceedings_issued AS [Proceedings Issued]
	,CAST(dim_detail_core_details.[date_subsequent_sla_report_sent] AS DATE) AS [Date of Subsequent SLA Report Sent] 
	,COALESCE(dim_detail_court.[date_of_trial],KeyDates.TaskDueDate) AS [Date of Trial]
	,fact_detail_elapsed_days.[elapsed_days_damages] AS [Elapsed Days Damages]
	,CAST(dim_detail_core_details.[date_initial_report_due] AS DATE) AS [Date Initial Report Due] 
	,dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Extension Requested]
	,elapsed_days_live_files AS [Elapsed Days Live Files]
	,elapsed_days_costs_to_settle AS [Elapsed Days Costs to Settle]
	, fact_detail_elapsed_days.days_to_first_report_lifecycle AS [Days to First Report Lifecycle]
	, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management) AS [Working Days to File Opening]
	, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management) AS [Working Days to Acknowledge]
	, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_matter_header_current.date_opened_case_management, GETDATE()) AS [Working Days Since File Opened]
	, ClaimantsAddress.[claimant1_postcode] AS [Claimant's Postcode]
	, dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
	, Longitude
	, Latitude

FROM red_dw.dbo.fact_dimension_main WITH(NOLOCK)
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK)
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days WITH(NOLOCK)
ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement WITH(NOLOCK)
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH(NOLOCK)
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_involvement_full WITH(NOLOCK)
ON dim_involvement_full.client_code=dim_matter_header_current.client_code
AND dim_involvement_full.matter_number=dim_matter_header_current.matter_number
AND dim_involvement_full.is_active=1
LEFT OUTER JOIN
        (
            SELECT fact_dimension_main.master_fact_key [fact_key],
                   dim_client.contact_salutation [claimant1_contact_salutation],
                   dim_client.addresse [claimant1_addresse],
                   dim_client.address_line_1 [claimant1_address_line_1],
                   dim_client.address_line_2 [claimant1_address_line_2],
                   dim_client.address_line_3 [claimant1_address_line_3],
                   dim_client.address_line_4 [claimant1_address_line_4],
                   dim_client.postcode [claimant1_postcode]
            FROM red_dw.dbo.dim_claimant_thirdparty_involvement
                INNER JOIN red_dw.dbo.fact_dimension_main
                    ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
                INNER JOIN red_dw.dbo.dim_involvement_full
                    ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
                INNER JOIN red_dw.dbo.dim_client
                    ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
            WHERE dim_client.dim_client_key != 0
			AND dim_client.client_code IN ('W17427','W15632','W15366','W15442','W20163')
        ) AS ClaimantsAddress 
            ON fact_dimension_main.master_fact_key = ClaimantsAddress.fact_key
		LEFT OUTER JOIN red_dw.dbo.Doogal WITH(NOLOCK) ON Doogal.Postcode=ClaimantsAddress.claimant1_postcode
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail WITH(NOLOCK)
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT JOIN red_dw.dbo.dim_detail_court WITH(NOLOCK)
ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN #KeyDates AS KeyDates WITH(NOLOCK)
 ON KeyDates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management IS NULL --OR dim_matter_header_current.date_closed_case_management>='2020-01-01'
	OR dim_detail_outcome.date_claim_concluded>='2020-01-01' OR dim_detail_outcome.date_costs_settled>='2020-01-01')
AND ISNULL(dim_detail_outcome.outcome_of_case,'') <>'Exclude from reports'
AND (
dim_matter_header_current.master_client_code='W17427'
OR (dim_matter_header_current.master_client_code='W15632' AND (dim_involvement_full.name LIKE '%Sedgwick%' OR dim_involvement_full.name LIKE '%Cunningham Lindsey%'))
OR (dim_matter_header_current.master_client_code='W15366' AND dim_matter_header_current.master_matter_number IN ('4482'
,'4532','4552','4553','4560','4594','4601'
,'4611','4628','4663','4678','4720','4733'
,'4750','4756','4770','4773','4779','4780'
,'4783','4784','4785','4786','4790','4792'
,'4804','4813','4825','4826','4831','4834'
,'4851','4852','4855','4863','4864','4867'
,'4870','4872','4874','4884','4885','4892'
,'4896','4895'
))
OR (dim_matter_header_current.master_client_code='W15442' AND dim_involvement_full.name LIKE '%Protector%')
OR (dim_matter_header_current.master_client_code='W20163' AND dim_detail_core_details.does_claimant_have_personal_injury_claim='Yes'AND dim_detail_core_details.incident_date>'2018-07-14')
)



END


GO
