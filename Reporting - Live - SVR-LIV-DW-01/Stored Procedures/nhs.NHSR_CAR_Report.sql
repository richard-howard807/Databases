SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Emily Smith
Created Date:		2019-11-11
Description:		Data for NHSR CAR Report, all live matters
Ticket:				29094
Current Version:	Initial Create
====================================================
====================================================

*/
CREATE PROCEDURE [nhs].[NHSR_CAR_Report]

(
@Team VARCHAR(MAX),
@FeeEarner VARCHAR(MAX)
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON

SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
SELECT ListValue  INTO #FeeEarner FROM Reporting.dbo.[udt_TallySplit]('|', @FeeEarner)

SELECT --TOP 100* 

       header.master_client_code AS [Master Client Code]
       , header.master_matter_number AS [Master Matter Number]
	   , header.client_code AS [Client Code]
	   , header.matter_number AS [Matter Number]
	   , header.matter_description AS [Matter Description]
       , header.client_group_name AS [Client Group Name]
	   , emp_hierarchy.hierarchylevel4hist AS [Team]
       , header.matter_owner_full_name AS [Matter Owner]
       , emp_hierarchy.windowsusername AS [Windows Username]
	   , header.date_opened_case_management AS [Date Opened]
	   , dim_instruction_type.instruction_type AS [Instruction Type]
	   , output_wip_fee_arrangement AS [Fee Arrangement]
	   , fin.fixed_fee_amount AS [Fixed Fee Amount]
	   , core.present_position AS [Present Position]
	   , core.is_there_an_issue_on_liability AS [Issue on Liability?]
	   , fin.damages_reserve AS [Damages Reserve]
	   , fin.damages_paid AS [Damages Paid]
	   , ISNULL(fin.defence_costs_billed,0)+ISNULL(fin.disbursements_billed,0) AS [Total Revenue & Disbursements]
	   , CONVERT(DECIMAL(16,4),shelf_life.elapsed_days_conclusion)/365 AS [Matter Age (years)]
	   , fin.wip AS [WIP]
	   , last_bill_date AS [Date of Last Bill]
	   , last_time_transaction_date AS [Last Time Recorded]
	   , [Panel Damages Paid]
	   , [Panel Defence Costs]
	   , [Panel Shelf life (yrs)]
	   , CASE WHEN CONVERT(DECIMAL(16,4),shelf_life.elapsed_days_conclusion)/365 >[Panel Shelf life (yrs)]  THEN 'Red'
				WHEN CAST(CONVERT(DECIMAL(16,4),shelf_life.elapsed_days_conclusion)/365 AS DECIMAL(10,2))/CAST([Panel Shelf life (yrs)] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
				ELSE 'Green' END AS [RAG Lifecycle]
		, CASE WHEN fin.damages_paid >[Panel Damages Paid]  THEN 'Red'
				WHEN CAST(fin.damages_paid AS DECIMAL(10,2))/CAST([Panel Damages Paid] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
				ELSE 'Green' END AS [RAG Damages]
		, CASE WHEN ISNULL(fin.defence_costs_billed,0)+ISNULL(fin.disbursements_billed,0) >[Panel Defence Costs]  THEN 'Red'
				WHEN CAST(ISNULL(fin.defence_costs_billed,0)+ISNULL(fin.disbursements_billed,0) AS DECIMAL(10,2))/CAST([Panel Defence Costs] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
				ELSE 'Green' END AS [RAG Defence]
	    
       , health.nhs_scheme AS [NHS Scheme]
       , CASE WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
                WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [Scheme]
       , health.[nhs_claim_status] AS [NHS Claim Status]
       , CASE WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid = 0 THEN '£0'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 1 AND 5000 THEN '£1-5,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 5001 AND 10000 THEN '£5,001-10,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 10001 AND 25000 THEN '£10,001-25,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid BETWEEN 25001 AND 50000 THEN '£25,001-50,000'
              WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') AND fin.damages_paid >= 50001  THEN '£50,001+'

              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND health.[nhs_claim_status] = 'Periodical payments' THEN 'PPOs'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid = 0 THEN '£0'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 1 AND 50000 THEN '£1-50,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 50001 AND 250000 THEN '£50,001-250,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 250001 AND 500000 THEN '£250,001-500,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid BETWEEN 500001 AND 1000000 THEN '£500,001-1,000,000'
              WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') AND fin.damages_paid >= 1000001 THEN '£1m+'

        END AS [Banding]

       , fin.defence_costs_billed + fin.disbursements_billed AS [Defence Costs inc Disbs]
       , emp.locationidud [Matter Owner Office]
       , CASE WHEN emp.locationidud IN ('London NFL','London Hallmark') THEN 'London'
              WHEN emp.locationidud IN ('Liverpool','Manchester Spinningfields') THEN 'Liverpool'
              ELSE emp.locationidud
		 END [Office]
       , header.date_closed_case_management AS [Date Case Closed]
       , outcome.date_claim_concluded AS [Date Claim Concluded]
       , outcome.date_costs_settled AS [Date Costs Settled]
	   , health.[zurichnhs_date_final_bill_sent_to_client] AS [Final Bill Sent to Client]
       , core.date_instructions_received AS [Date Instructions Received]
       , CONVERT(DECIMAL(16,4),shelf_life.elapsed_days_conclusion)/365 AS [Shelf Life]
       , shelf_life.days_to_send_report AS [Days to Send Report]
       , core.referral_reason AS [Referral Reason]
       , outcome.outcome_of_case AS [Outcome]
       , tpi.claimant_name AS [Claimant Name]
	   , core.date_initial_report_sent AS [Date Initial Report Sent]
       , DATEDIFF(DAY,core.date_instructions_received, core.date_initial_report_sent) [Days to Send Initial Report] 
	   , EC.count AS [MI Exceptions Outstanding]
	  

FROM red_dw.dbo.fact_dimension_main main
INNER JOIN red_dw.dbo.dim_matter_header_current header ON main.dim_matter_header_curr_key = header.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.fact_finance_summary fin ON fin.master_fact_key = main.master_fact_key
INNER JOIN red_dw.dbo.dim_detail_health health ON health.dim_detail_health_key = main.dim_detail_health_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history emp_hierarchy ON emp_hierarchy.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_employee emp ON emp_hierarchy.dim_employee_key = emp.dim_employee_key  
LEFT JOIN red_dw.dbo.dim_detail_outcome outcome ON outcome.dim_detail_outcome_key = main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_detail_elapsed_days shelf_life ON main.master_fact_key = shelf_life.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement tpi ON tpi.dim_claimant_thirdpart_key = main.dim_claimant_thirdpart_key

LEFT OUTER JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = header.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = main.master_fact_key

  LEFT OUTER JOIN
    (
        SELECT SUM(exceptions_count) count,
               fact_exceptions_update.client_code,
               fact_exceptions_update.matter_number
        FROM red_dw.dbo.fact_exceptions_update
            INNER JOIN red_dw.dbo.fact_dimension_main
                ON fact_dimension_main.client_code = fact_exceptions_update.client_code
                   AND fact_dimension_main.matter_number = fact_exceptions_update.matter_number
        WHERE duplicate_flag <> 1
              AND miscellaneous_flag <> 1
              AND datasetid = 226
        GROUP BY fact_exceptions_update.client_code,
                 fact_exceptions_update.matter_number
    ) AS EC
        ON EC.client_code = header.client_code
           AND EC.matter_number = header.matter_number

LEFT OUTER JOIN [Reporting].[nhs].[PanelAverages] ON Scheme=CASE WHEN health.nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
                WHEN health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AND Banding='Overall'

INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = emp_hierarchy.hierarchylevel4hist
INNER JOIN #FeeEarner AS FeeEarner ON FeeEarner.ListValue COLLATE DATABASE_DEFAULT = header.matter_owner_full_name

WHERE header.client_group_code = '00000003'
AND header.reporting_exclusions = 0
AND core.referral_reason IS NOT NULL 
AND core.referral_reason IN ('Dispute on liability and quantum','Dispute on quantum','Dispute on liability','Infant approval', 'Costs dispute','Dispute on Liability','Infant Approval')
AND (outcome.outcome_of_case IS NULL OR  outcome.outcome_of_case <> 'Exclude from reports')
AND health.nhs_scheme IN ('CNST','ELS','DH CL','DH Liab','LTPS','PES')
AND health.nhs_scheme IS NOT NULL 
--AND NOT (header.date_closed_case_management IS NULL AND outcome.date_claim_concluded IS NULL AND outcome.date_costs_settled IS NULL AND health.zurichnhs_date_final_bill_sent_to_client IS NULL)
AND header.date_closed_case_management IS NULL 


END
GO
