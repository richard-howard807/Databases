SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				?
Created Date:		?
Description:		HNSR Defence Costs Management Report
Current Version:	1.1
====================================================
History
 Date		 Name	Version		
 20/11/2018	 JL		1.1 - excluded present position matters as per ticket 2482
 03/09/2019	 ES		1.2 - added dim_detail_critical_mi.[is_there_an_issue_on_liability] as per ticket 30785 
====================================================

*/

CREATE PROCEDURE [dbo].[NHSRDefenceCostsManagement] -- 'All','All'
(
@FeeEarner AS NVARCHAR(1000)
,@TM AS NVARCHAR(1000)
,@Partner AS NVARCHAR(1000) 
)
AS
BEGIN


IF @FeeEarner='All' AND @TM='All'  AND @Partner='All'

BEGIN 
SELECT 
[time_charge_value]
,[instruction_type]
,[matter_owner_practice_area]
,[client_code]
,[matter_number]
,[matter_description]
,fed_code
,[wip]
,[defence_costs_billed]
,[disbursement_balance]
,[time_billed]
,date_opened_case_management
,[age_of_matter]
,[fixed_fee_amount]
,[workemail]
,[worksforemail]
,[letter_of_response_due]
,[matter_owner_team]
,[last_time_calendar_date]
,[work_type_name]
,[matter_owner_name]
,[locationidud]
,[output_wip_fee_arrangement]
,[output_wip_percentage_complete]
,[present_position]
,[outcome_of_case]
,[date_claim_concluded]
,[date_costs_settled]
,[is_this_a_linked_file]
,[are_we_pursuing_a_recovery]
,WIPPlusBilled
,[damages_reserve]
,[Panel Average Defence Costs]
,[Panel Average Defence Costs]  -ISNULL(WIPPlusBilled,0) AS AverageMinusBills
,ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs] AS PercentageReached
, CASE WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) >1 THEN 'Red'
WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG
,NominatedPartnerName
,[NominatedPartnerEmail]
,[Team Manager]
,[Matters Partner Name]
,TMEMail
,InstructionType
,TotalBilledExcVAT
,[Panel Average Life Cycle]
,age_of_matter AS Age
, CASE WHEN [age_of_matter] >[Panel Average Life Cycle]  THEN 'Red'
WHEN CAST([age_of_matter] AS DECIMAL(10,2))/CAST([Panel Average Life Cycle] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG1
,[Is there an issue on liability?]

FROM 
(
SELECT
fact_finance_summary.[time_charge_value]
,dim_instruction_type.[instruction_type]
,hierarchylevel4hist AS [matter_owner_practice_area]
,dim_client.[client_code]
,dim_matter_header_current.[matter_number]
,dim_matter_header_current.[matter_description]
,dim_fed_hierarchy_history.fed_code
,fact_finance_summary.[wip]
,fact_finance_summary.[defence_costs_billed]
,fact_finance_summary.[disbursement_balance]
,fact_finance_summary.[time_billed]
,dim_matter_header_current.date_opened_case_management AS date_opened_case_management
,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,GETDATE()) AS [age_of_matter]
,fact_finance_summary.[fixed_fee_amount]
,dim_employee.[workemail]
,dim_employee.[worksforemail]
,dim_detail_health.[letter_of_response_due]
,hierarchylevel4hist AS [matter_owner_team]
,last_time_transaction_date AS [last_time_calendar_date]
,dim_matter_worktype.[work_type_name]
,dim_fed_hierarchy_history.name AS [matter_owner_name]
,dim_employee.[locationidud]
,dim_detail_finance.[output_wip_fee_arrangement]
,dim_detail_finance.[output_wip_percentage_complete]
,dim_detail_core_details.[present_position]
,dim_detail_outcome.[outcome_of_case]
,dim_detail_outcome.[date_claim_concluded]
,dim_detail_outcome.[date_costs_settled]
,dim_detail_core_details.[is_this_a_linked_file]
,dim_detail_outcome.[are_we_pursuing_a_recovery]
,(fact_finance_summary.[wip] + fact_finance_summary.[defence_costs_billed] + fact_finance_summary.disbursement_balance + disbursements_billed) WIPPlusBilled
,fact_finance_summary.[damages_reserve]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 4446
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 6289
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 23163
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 42109
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 58709 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 93926

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 2399
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 4359
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 10639
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 26338
END AS [Panel Average Defence Costs]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 457 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 457
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 740 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 947 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 1242  
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 1706 

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 313 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 341 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 489 
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 767 
END AS [Panel Average Life Cycle]

,NominatedPartnerName
,[NominatedPartnerEmail]
,worksforname AS [Team Manager]
,matter_partner_full_name AS [Matters Partner Name]
,CASE WHEN hierarchylevel4hist='Risk Pool' THEN 'james.hough@weightmans.com'
WHEN hierarchylevel4hist='Clinical London' THEN 'luke.gleeson@weightmans.com'
WHEN hierarchylevel4hist='Clinical Birmingham' OR hierarchylevel4hist='Healthcare Management' THEN 'jasmine.armstrong@weightmans.com'
WHEN hierarchylevel4hist='Clinical Liverpool and Manchester' THEN 'ian.critchley@weightmans.com ' END AS TMEMail
,hierarchylevel4hist
,dim_detail_health.[nhs_instruction_type] AS InstructionType
,defence_costs_billed + wip + fact_finance_summary.disbursement_balance + disbursements_billed AS TotalBilledExcVAT
,dim_detail_critical_mi.[is_there_an_issue_on_liability] AS [Is there an issue on liability?]
FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
 ON dim_matter_header_current.client_code=dim_client.client_code
INNER JOIN red_dw.dbo.fact_dimension_main   WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK)
 ON dim_matter_header_current.dim_instruction_type_key=dim_instruction_type.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK) 
 ON fact_dimension_main.dim_fed_hierarchy_history_key=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_employee WITH (NOLOCK)
 ON dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_finance_key=dim_detail_finance.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_health_key=dim_detail_health.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_matter_summary_current.client_code
 AND dim_matter_header_current.matter_number=fact_matter_summary_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi WITH (NOLOCK)
 ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
LEFT OUTER JOIN (SELECT case_id,personnel_code AS NominatedPartnerCode
,name AS NominatedPartnerName
,workemail AS [NominatedPartnerEmail]
FROM axxia01.dbo.casper
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=personnel_code AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee on dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
WHERE capacity_code='NOMPART') AS NominatedPartner
 ON dim_matter_header_current.case_id=NominatedPartner.case_id
WHERE dim_matter_header_current.client_group_name='NHS Resolution'
AND dim_matter_header_current.date_closed_practice_management IS NULL
AND reporting_exclusions=0
AND work_type_group  IN ('EL','PL All','NHSLA')
AND dim_detail_outcome.[date_costs_settled] IS NULL
AND dim_matter_header_current.present_position NOT IN ('To be closed/minor balances to be clear','Final bill sent - unpaid','Final bill due - claim and costs concluded') /*jl 1.1*/
AND LOWER(ISNULL(dim_detail_core_details.[referral_reason],'')) NOT IN ('advice only','pre-action disclosure') 
) AS AllData

END



IF @FeeEarner<>'All' AND @TM='All'  AND @Partner='All'

BEGIN 
SELECT 
[time_charge_value]
,[instruction_type]
,[matter_owner_practice_area]
,[client_code]
,[matter_number]
,[matter_description]
,fed_code
,[wip]
,[defence_costs_billed]
,[disbursement_balance]
,[time_billed]
,date_opened_case_management
,[age_of_matter]
,[fixed_fee_amount]
,[workemail]
,[worksforemail]
,[letter_of_response_due]
,[matter_owner_team]
,[last_time_calendar_date]
,[work_type_name]
,[matter_owner_name]
,[locationidud]
,[output_wip_fee_arrangement]
,[output_wip_percentage_complete]
,[present_position]
,[outcome_of_case]
,[date_claim_concluded]
,[date_costs_settled]
,[is_this_a_linked_file]
,[are_we_pursuing_a_recovery]
,WIPPlusBilled
,[damages_reserve]
,[Panel Average Defence Costs]
,[Panel Average Defence Costs]  -ISNULL(WIPPlusBilled,0) AS AverageMinusBills
,ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs] AS PercentageReached
, CASE WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) >1 THEN 'Red'
WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG
,NominatedPartnerName
,[NominatedPartnerEmail]
,[Team Manager]
,[Matters Partner Name]
,TMEMail
,InstructionType
,TotalBilledExcVAT
,[Panel Average Life Cycle]
,age_of_matter AS Age
, CASE WHEN [age_of_matter] >[Panel Average Life Cycle]  THEN 'Red'
WHEN CAST([age_of_matter] AS DECIMAL(10,2))/CAST([Panel Average Life Cycle] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG1
,[Is there an issue on liability?]

FROM 
(
SELECT
fact_finance_summary.[time_charge_value]
,dim_instruction_type.[instruction_type]
,hierarchylevel4hist AS [matter_owner_practice_area]
,dim_client.[client_code]
,dim_matter_header_current.[matter_number]
,dim_matter_header_current.[matter_description]
,dim_fed_hierarchy_history.fed_code
,fact_finance_summary.[wip]
,fact_finance_summary.[defence_costs_billed]
,fact_finance_summary.[disbursement_balance]
,fact_finance_summary.[time_billed]
,dim_matter_header_current.date_opened_case_management AS date_opened_case_management
,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,GETDATE()) AS [age_of_matter]
,fact_finance_summary.[fixed_fee_amount]
,dim_employee.[workemail]
,dim_employee.[worksforemail]
,dim_detail_health.[letter_of_response_due]
,hierarchylevel4hist AS [matter_owner_team]
,last_time_transaction_date AS [last_time_calendar_date]
,dim_matter_worktype.[work_type_name]
,dim_fed_hierarchy_history.name AS [matter_owner_name]
,dim_employee.[locationidud]
,dim_detail_finance.[output_wip_fee_arrangement]
,dim_detail_finance.[output_wip_percentage_complete]
,dim_detail_core_details.[present_position]
,dim_detail_outcome.[outcome_of_case]
,dim_detail_outcome.[date_claim_concluded]
,dim_detail_outcome.[date_costs_settled]
,dim_detail_core_details.[is_this_a_linked_file]
,dim_detail_outcome.[are_we_pursuing_a_recovery]
,(fact_finance_summary.[wip] + fact_finance_summary.[defence_costs_billed] + fact_finance_summary.disbursement_balance + disbursements_billed) WIPPlusBilled
,fact_finance_summary.[damages_reserve]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 4446
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 6289
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 23163
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 42109
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 58709 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 93926

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 2399
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 4359
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 10639
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 26338
END AS [Panel Average Defence Costs]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 457 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 457
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 740 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 947 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 1242  
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 1706 

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 313 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 341 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 489 
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 767 
END AS [Panel Average Life Cycle]

,NominatedPartnerName
,[NominatedPartnerEmail]
,worksforname AS [Team Manager]
,matter_partner_full_name AS [Matters Partner Name]
,CASE WHEN hierarchylevel4hist='Risk Pool' THEN 'james.hough@weightmans.com'
WHEN hierarchylevel4hist='Clinical London' THEN 'luke.gleeson@weightmans.com'
WHEN hierarchylevel4hist='Clinical Birmingham' OR hierarchylevel4hist='Healthcare Management' THEN 'jasmine.armstrong@weightmans.com'
WHEN hierarchylevel4hist='Clinical Liverpool and Manchester' THEN 'ian.critchley@weightmans.com ' END AS TMEMail
,hierarchylevel4hist
,dim_detail_health.[nhs_instruction_type] AS InstructionType
,defence_costs_billed + wip + fact_finance_summary.disbursement_balance  + disbursements_billed  AS TotalBilledExcVAT
,dim_detail_critical_mi.[is_there_an_issue_on_liability] AS [Is there an issue on liability?]

FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
 ON dim_matter_header_current.client_code=dim_client.client_code
INNER JOIN red_dw.dbo.fact_dimension_main   WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK)
 ON dim_matter_header_current.dim_instruction_type_key=dim_instruction_type.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK) 
 ON fact_dimension_main.dim_fed_hierarchy_history_key=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_employee WITH (NOLOCK)
 ON dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_finance_key=dim_detail_finance.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_health_key=dim_detail_health.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_matter_summary_current.client_code
 AND dim_matter_header_current.matter_number=fact_matter_summary_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi WITH (NOLOCK)
 ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
LEFT OUTER JOIN (SELECT case_id,personnel_code AS NominatedPartnerCode
,name AS NominatedPartnerName
,workemail AS [NominatedPartnerEmail]
FROM axxia01.dbo.casper
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=personnel_code AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee on dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
WHERE capacity_code='NOMPART') AS NominatedPartner
 ON dim_matter_header_current.case_id=NominatedPartner.case_id
WHERE dim_matter_header_current.client_group_name='NHS Resolution'
AND dim_matter_header_current.date_closed_practice_management IS NULL
AND reporting_exclusions=0
AND work_type_group  IN ('EL','PL All','NHSLA')
AND dim_detail_outcome.[date_costs_settled] IS NULL
AND dim_matter_header_current.present_position NOT IN ('To be closed/minor balances to be clear','Final bill sent - unpaid','Final bill due - claim and costs concluded')/*jl 1.1*/
AND LOWER(ISNULL(dim_detail_core_details.[referral_reason],'')) NOT IN ('advice only','pre-action disclosure') 
) AS AllData
WHERE [workemail] =@FeeEarner

END



IF @FeeEarner='All' AND @TM<>'All'  AND @Partner='All'
BEGIN 
SELECT 
[time_charge_value]
,[instruction_type]
,[matter_owner_practice_area]
,[client_code]
,[matter_number]
,[matter_description]
,fed_code
,[wip]
,[defence_costs_billed]
,[disbursement_balance]
,[time_billed]
,date_opened_case_management
,[age_of_matter]
,[fixed_fee_amount]
,[workemail]
,[worksforemail]
,[letter_of_response_due]
,[matter_owner_team]
,[last_time_calendar_date]
,[work_type_name]
,[matter_owner_name]
,[locationidud]
,[output_wip_fee_arrangement]
,[output_wip_percentage_complete]
,[present_position]
,[outcome_of_case]
,[date_claim_concluded]
,[date_costs_settled]
,[is_this_a_linked_file]
,[are_we_pursuing_a_recovery]
,WIPPlusBilled
,[damages_reserve]
,[Panel Average Defence Costs]
,[Panel Average Defence Costs]  -ISNULL(WIPPlusBilled,0) AS AverageMinusBills
,ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs] AS PercentageReached
, CASE WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) >1 THEN 'Red'
WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG
,NominatedPartnerName
,[NominatedPartnerEmail]
,[Team Manager]
,[Matters Partner Name]
,TMEMail
,InstructionType
,TotalBilledExcVAT
,[Panel Average Life Cycle]
,age_of_matter AS Age
, CASE WHEN [age_of_matter] >[Panel Average Life Cycle]  THEN 'Red'
WHEN CAST([age_of_matter] AS DECIMAL(10,2))/CAST([Panel Average Life Cycle] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG1
,[Is there an issue on liability?]

FROM 
(
SELECT
fact_finance_summary.[time_charge_value]
,dim_instruction_type.[instruction_type]
,hierarchylevel4hist AS [matter_owner_practice_area]
,dim_client.[client_code]
,dim_matter_header_current.[matter_number]
,dim_matter_header_current.[matter_description]
,dim_fed_hierarchy_history.fed_code
,fact_finance_summary.[wip]
,fact_finance_summary.[defence_costs_billed]
,fact_finance_summary.[disbursement_balance]
,fact_finance_summary.[time_billed]
,dim_matter_header_current.date_opened_case_management AS date_opened_case_management
,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,GETDATE()) AS [age_of_matter]
,fact_finance_summary.[fixed_fee_amount]
,dim_employee.[workemail]
,dim_employee.[worksforemail]
,dim_detail_health.[letter_of_response_due]
,hierarchylevel4hist AS [matter_owner_team]
,last_time_transaction_date AS [last_time_calendar_date]
,dim_matter_worktype.[work_type_name]
,dim_fed_hierarchy_history.name AS [matter_owner_name]
,dim_employee.[locationidud]
,dim_detail_finance.[output_wip_fee_arrangement]
,dim_detail_finance.[output_wip_percentage_complete]
,dim_detail_core_details.[present_position]
,dim_detail_outcome.[outcome_of_case]
,dim_detail_outcome.[date_claim_concluded]
,dim_detail_outcome.[date_costs_settled]
,dim_detail_core_details.[is_this_a_linked_file]
,dim_detail_outcome.[are_we_pursuing_a_recovery]
,(fact_finance_summary.[wip] + fact_finance_summary.[defence_costs_billed] + fact_finance_summary.disbursement_balance + disbursements_billed) WIPPlusBilled
,fact_finance_summary.[damages_reserve]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 4446
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 6289
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 23163
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 42109
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 58709 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 93926

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 2399
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 4359
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 10639
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 26338
END AS [Panel Average Defence Costs]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 457 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 457
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 740 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 947 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 1242  
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 1706 

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 313 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 341 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 489 
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 767 
END AS [Panel Average Life Cycle]

,NominatedPartnerName
,[NominatedPartnerEmail]
,worksforname AS [Team Manager]
,matter_partner_full_name AS [Matters Partner Name]
,CASE WHEN hierarchylevel4hist='Risk Pool' THEN 'james.hough@weightmans.com'
WHEN hierarchylevel4hist='Clinical London' THEN 'luke.gleeson@weightmans.com'
WHEN hierarchylevel4hist='Clinical Birmingham' OR hierarchylevel4hist='Healthcare Management' THEN 'jasmine.armstrong@weightmans.com'
WHEN hierarchylevel4hist='Clinical Liverpool and Manchester' THEN 'ian.critchley@weightmans.com ' END AS TMEMail
,hierarchylevel4hist
,dim_detail_health.[nhs_instruction_type] AS InstructionType
,defence_costs_billed + wip + fact_finance_summary.disbursement_balance  + disbursements_billed  AS TotalBilledExcVAT
,dim_detail_critical_mi.[is_there_an_issue_on_liability] AS [Is there an issue on liability?]

FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
 ON dim_matter_header_current.client_code=dim_client.client_code
INNER JOIN red_dw.dbo.fact_dimension_main   WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK)
 ON dim_matter_header_current.dim_instruction_type_key=dim_instruction_type.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK) 
 ON fact_dimension_main.dim_fed_hierarchy_history_key=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_employee WITH (NOLOCK)
 ON dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_finance_key=dim_detail_finance.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_health_key=dim_detail_health.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_matter_summary_current.client_code
 AND dim_matter_header_current.matter_number=fact_matter_summary_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi WITH (NOLOCK)
 ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
LEFT OUTER JOIN (SELECT case_id,personnel_code AS NominatedPartnerCode
,name AS NominatedPartnerName
,workemail AS [NominatedPartnerEmail]
FROM axxia01.dbo.casper
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=personnel_code AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee on dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
WHERE capacity_code='NOMPART') AS NominatedPartner
 ON dim_matter_header_current.case_id=NominatedPartner.case_id
WHERE dim_matter_header_current.client_group_name='NHS Resolution'
AND dim_matter_header_current.date_closed_practice_management IS NULL
AND reporting_exclusions=0
AND work_type_group  IN ('EL','PL All','NHSLA')
AND dim_detail_outcome.[date_costs_settled] IS NULL
AND dim_matter_header_current.present_position NOT IN ('To be closed/minor balances to be clear','Final bill sent - unpaid','Final bill due - claim and costs concluded') /*jl 1.1*/
AND LOWER(ISNULL(dim_detail_core_details.[referral_reason],'')) NOT IN ('advice only','pre-action disclosure') 
) AS AllData
WHERE TMEMail =@TM

END



IF @FeeEarner='All' AND @TM='All'  AND @Partner<>'All'
BEGIN 
SELECT 
[time_charge_value]
,[instruction_type]
,[matter_owner_practice_area]
,[client_code]
,[matter_number]
,[matter_description]
,fed_code
,[wip]
,[defence_costs_billed]
,[disbursement_balance]
,[time_billed]
,date_opened_case_management
,[age_of_matter]
,[fixed_fee_amount]
,[workemail]
,[worksforemail]
,[letter_of_response_due]
,[matter_owner_team]
,[last_time_calendar_date]
,[work_type_name]
,[matter_owner_name]
,[locationidud]
,[output_wip_fee_arrangement]
,[output_wip_percentage_complete]
,[present_position]
,[outcome_of_case]
,[date_claim_concluded]
,[date_costs_settled]
,[is_this_a_linked_file]
,[are_we_pursuing_a_recovery]
,WIPPlusBilled
,[damages_reserve]
,[Panel Average Defence Costs]
,[Panel Average Defence Costs]  -ISNULL(WIPPlusBilled,0) AS AverageMinusBills
,ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs] AS PercentageReached
, CASE WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) >1 THEN 'Red'
WHEN (ISNULL(WIPPlusBilled,0)/[Panel Average Defence Costs]) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG
,NominatedPartnerName
,[NominatedPartnerEmail]
,[Team Manager]
,[Matters Partner Name]
,TMEMail
,InstructionType
,TotalBilledExcVAT
,[Panel Average Life Cycle]
,age_of_matter AS Age
, CASE WHEN [age_of_matter] >[Panel Average Life Cycle]  THEN 'Red'
WHEN CAST([age_of_matter] AS DECIMAL(10,2))/CAST([Panel Average Life Cycle] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG1
,[Is there an issue on liability?]

FROM 
(
SELECT
fact_finance_summary.[time_charge_value]
,dim_instruction_type.[instruction_type]
,hierarchylevel4hist AS [matter_owner_practice_area]
,dim_client.[client_code]
,dim_matter_header_current.[matter_number]
,dim_matter_header_current.[matter_description]
,dim_fed_hierarchy_history.fed_code
,fact_finance_summary.[wip]
,fact_finance_summary.[defence_costs_billed]
,fact_finance_summary.[disbursement_balance]
,fact_finance_summary.[time_billed]
,dim_matter_header_current.date_opened_case_management AS date_opened_case_management
,DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management,GETDATE()) AS [age_of_matter]
,fact_finance_summary.[fixed_fee_amount]
,dim_employee.[workemail]
,dim_employee.[worksforemail]
,dim_detail_health.[letter_of_response_due]
,hierarchylevel4hist AS [matter_owner_team]
,last_time_transaction_date AS [last_time_calendar_date]
,dim_matter_worktype.[work_type_name]
,dim_fed_hierarchy_history.name AS [matter_owner_name]
,dim_employee.[locationidud]
,dim_detail_finance.[output_wip_fee_arrangement]
,dim_detail_finance.[output_wip_percentage_complete]
,dim_detail_core_details.[present_position]
,dim_detail_outcome.[outcome_of_case]
,dim_detail_outcome.[date_claim_concluded]
,dim_detail_outcome.[date_costs_settled]
,dim_detail_core_details.[is_this_a_linked_file]
,dim_detail_outcome.[are_we_pursuing_a_recovery]
,(fact_finance_summary.[wip] + fact_finance_summary.[defence_costs_billed] + fact_finance_summary.disbursement_balance + disbursements_billed) WIPPlusBilled
,fact_finance_summary.[damages_reserve]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 4446
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 6289
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 23163
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 42109
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 58709 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 93926

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 1777
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 2399
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 4359
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 10639
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 26338
END AS [Panel Average Defence Costs]
,CASE 
WHEN work_type_group='NHSLA' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 457 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN 457
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN 740 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN 947 
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN 1242  
WHEN work_type_group='NHSLA' AND  fact_finance_summary.[damages_reserve]>1000000 THEN 1706 

WHEN  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN 243 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN 313 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN 341 
WHEN  fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN 489 
WHEN  fact_finance_summary.[damages_reserve] > 50000.01 THEN 767 
END AS [Panel Average Life Cycle]

,NominatedPartnerName
,[NominatedPartnerEmail]
,worksforname AS [Team Manager]
,matter_partner_full_name AS [Matters Partner Name]
,CASE WHEN hierarchylevel4hist='Risk Pool' THEN 'james.hough@weightmans.com'
WHEN hierarchylevel4hist='Clinical London' THEN 'luke.gleeson@weightmans.com'
WHEN hierarchylevel4hist='Clinical Birmingham' OR hierarchylevel4hist='Healthcare Management' THEN 'jasmine.armstrong@weightmans.com'
WHEN hierarchylevel4hist='Clinical Liverpool and Manchester' THEN 'ian.critchley@weightmans.com ' END AS TMEMail
,hierarchylevel4hist
,dim_detail_health.[nhs_instruction_type] AS InstructionType
,defence_costs_billed + wip + fact_finance_summary.disbursement_balance  + disbursements_billed  AS TotalBilledExcVAT
,dim_detail_critical_mi.[is_there_an_issue_on_liability] AS [Is there an issue on liability?]

FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK)
 ON dim_matter_header_current.client_code=dim_client.client_code
INNER JOIN red_dw.dbo.fact_dimension_main   WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK)
 ON dim_matter_header_current.dim_instruction_type_key=dim_instruction_type.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK) 
 ON fact_dimension_main.dim_fed_hierarchy_history_key=dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_employee WITH (NOLOCK)
 ON dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_finance_key=dim_detail_finance.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH (NOLOCK)
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH (NOLOCK)
 ON fact_dimension_main.dim_detail_health_key=dim_detail_health.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_matter_summary_current.client_code
 AND dim_matter_header_current.matter_number=fact_matter_summary_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi WITH (NOLOCK)
 ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
LEFT OUTER JOIN (SELECT case_id,personnel_code AS NominatedPartnerCode
,name AS NominatedPartnerName
,workemail AS [NominatedPartnerEmail]
FROM axxia01.dbo.casper
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=personnel_code AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee on dim_fed_hierarchy_history.dim_employee_key=dim_employee.dim_employee_key
WHERE capacity_code='NOMPART') AS NominatedPartner
 ON dim_matter_header_current.case_id=NominatedPartner.case_id
WHERE dim_matter_header_current.client_group_name='NHS Resolution'
AND dim_matter_header_current.date_closed_practice_management IS NULL
AND reporting_exclusions=0
AND work_type_group  IN ('EL','PL All','NHSLA')
AND dim_detail_outcome.[date_costs_settled] IS NULL
AND dim_matter_header_current.present_position NOT IN ('To be closed/minor balances to be clear','Final bill sent - unpaid','Final bill due - claim and costs concluded') /*jl 1.1*/
AND LOWER(ISNULL(dim_detail_core_details.[referral_reason],'')) NOT IN ('advice only','pre-action disclosure') 
) AS AllData
WHERE NominatedPartnerEmail =@Partner

END




END


GO
