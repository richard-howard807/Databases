SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		04/10/2022
Description:		New version of NHSRDefenceCostsManagement - filters look at temp table, so we only need to update the 1 query rather than 4. 
					Changed logic to trache from work_type_group to nhs_scheme.
					Added in panel averages from data science table
Current Version:	1.1
====================================================
[dbo].[NHSRDefenceCostsManagement] - original proc - History
 Date		 Name	Version		
 20/11/2018	 JL		1.1 - excluded present position matters as per ticket 2482
 03/09/2019	 ES		1.2 - added dim_detail_critical_mi.[is_there_an_issue_on_liability] as per ticket 30785 
 07/05/2020	 ES		1.3 - amended panel averages and changed age of matter to years rater than days as pert ticket 57804
 16/07/2020	 ES		1.4 - #64794 added ms ref 
 29/07/2020	 JL		1.5 - 66147 - Matter age (years) amended logic 
 27/01/2021  JB		1.6 - #85960 changed nominated partner details to look at field in Matter Details in MS. Also updated the TMEmail to match the subsciption with correct teams to look at	
====================================================

*/


-- Report will ask to define variables if refreshing dataset. Enter "All" into the values of each variable and click ok
CREATE PROCEDURE [dbo].[NHSRDefenceCostsManagementV2] -- 'All','All', 'All'
(
@FeeEarner AS NVARCHAR(MAX)
,@TM AS NVARCHAR(MAX)
,@Partner AS NVARCHAR(MAX) 
)
AS
BEGIN

SET NOCOUNT ON 


DROP TABLE IF EXISTS #nhsr_defence_costs_management


SELECT 
[time_charge_value]
,[instruction_type]
,[matter_owner_practice_area]
,[client_code]
,[matter_number]
,AllData.Ref
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
,panel_averages.[defence costs]  AS [Panel Average Defence Costs]
,panel_averages.[defence costs]  -ISNULL(WIPPlusBilled,0) AS AverageMinusBills
,ISNULL(WIPPlusBilled,0)/panel_averages.[defence costs] AS PercentageReached
, CASE WHEN (ISNULL(WIPPlusBilled,0)/panel_averages.[defence costs]) >1 THEN 'Red'
WHEN (ISNULL(WIPPlusBilled,0)/panel_averages.[defence costs]) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG
,NominatedPartnerName
,[NominatedPartnerEmail]
,[Team Manager]
,[Matters Partner Name]
,TMEMail
,InstructionType
,TotalBilledExcVAT
,panel_averages.[settlement time]		AS [Panel Average Life Cycle]
,age_of_matter AS Age
, CASE WHEN [age_of_matter] >panel_averages.[settlement time]  THEN 'Red'
WHEN CAST([age_of_matter] AS DECIMAL(10,2))/CAST(panel_averages.[settlement time] AS DECIMAL(10,2)) BETWEEN 0.75 AND 1 THEN 'Orange'
ELSE 'Green' END AS RAG1
,[Is there an issue on liability?]
,AllData.[Tranche]
INTO #nhsr_defence_costs_management
FROM 
(
SELECT
fact_finance_summary.[time_charge_value]
,dim_instruction_type.[instruction_type]
,hierarchylevel4hist AS [matter_owner_practice_area]
,dim_client.[client_code]
,dim_matter_header_current.[matter_number]
,dim_matter_header_current.master_client_code+'-'+master_matter_number AS [Ref]
,dim_matter_header_current.[matter_description]
,dim_fed_hierarchy_history.fed_code
,fact_finance_summary.[wip]
,fact_finance_summary.[defence_costs_billed]
,fact_finance_summary.[disbursement_balance]
,fact_finance_summary.[time_billed]
,dim_matter_header_current.date_opened_case_management AS date_opened_case_management
, DATEDIFF(day, dim_detail_core_details.date_instructions_received, COALESCE(dim_detail_outcome.date_claim_concluded, getdate()))/365.0 AS [age_of_matter] --1.5 jl
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
WHEN tranche_groups.tranche_group = 'Clinical' AND  ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN '£0'
WHEN tranche_groups.tranche_group = 'Clinical' AND  fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 50000 THEN '£1-£50,000'
WHEN tranche_groups.tranche_group = 'Clinical' AND  fact_finance_summary.[damages_reserve] BETWEEN 50000.01 AND 250000 THEN '£50,000-£250,000'
WHEN tranche_groups.tranche_group = 'Clinical' AND  fact_finance_summary.[damages_reserve] BETWEEN 250000.01 AND 500000 THEN '£250,000-£500,000' 
WHEN tranche_groups.tranche_group = 'Clinical' AND  fact_finance_summary.[damages_reserve] BETWEEN 500000.01 AND 1000000 THEN '£500,000-£1,000,000'  
WHEN tranche_groups.tranche_group = 'Clinical' AND  fact_finance_summary.[damages_reserve]>1000000 THEN '£1,000,000+' 

WHEN tranche_groups.tranche_group = 'Non-Clinical' AND ISNULL(fact_finance_summary.[damages_reserve],0)=0 THEN '£0' 
WHEN tranche_groups.tranche_group = 'Non-Clinical' AND fact_finance_summary.[damages_reserve] BETWEEN 0.01 AND 5000 THEN '£1-£5,000' 
WHEN tranche_groups.tranche_group = 'Non-Clinical' AND fact_finance_summary.[damages_reserve] BETWEEN 5000.01 AND 10000 THEN '£5,000-£10,000'
WHEN tranche_groups.tranche_group = 'Non-Clinical' AND fact_finance_summary.[damages_reserve] BETWEEN 10000.01 AND 25000 THEN '£10,000-£25,000'
WHEN tranche_groups.tranche_group = 'Non-Clinical' AND fact_finance_summary.[damages_reserve] BETWEEN 25000.01 AND 50000 THEN '£25,000-£50,000'
WHEN tranche_groups.tranche_group = 'Non-Clinical' AND fact_finance_summary.[damages_reserve] > 50000.01 THEN '£50,000+'
END AS [Tranche]
, tranche_groups.tranche_group
,NominatedPartnerName
,[NominatedPartnerEmail]
,worksforname AS [Team Manager]
,matter_partner_full_name AS [Matters Partner Name]
,CASE WHEN hierarchylevel4hist='North West Healthcare 2' THEN 'james.hough@weightmans.com'
WHEN dim_fed_hierarchy_history.hierarchylevel4hist='North West Healthcare 1' THEN 'Sam.Harland@Weightmans.com'
WHEN hierarchylevel4hist='London Healthcare' THEN 'luke.gleeson@weightmans.com'
WHEN hierarchylevel4hist='Birmingham Healthcare 1' OR hierarchylevel4hist='Healthcare Management' THEN 'jasmine.armstrong@weightmans.com'
WHEN hierarchylevel4hist='Birmingham Healthcare 2' THEN 'sarah.hopwood@weightmans.com' END AS TMEMail
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
 LEFT OUTER JOIN (
	SELECT 
		dbClient.clNo+'-'+dbFile.fileNo	AS ms_ref
		, dbFile.fileID
		, dbFeeEarner.feeSignOff
		, nom_partner_email.nominated_partner	AS NominatedPartnerName
		, nom_partner_email.NominatedPartnerEmail
	FROM MS_Prod.config.dbFile
		INNER JOIN MS_Prod.config.dbClient
			ON dbClient.clID = dbFile.clID
		INNER JOIN MS_Prod.dbo.udExtFile
			ON udExtFile.fileID = dbFile.fileID
		LEFT OUTER JOIN MS_Prod.[dbo].[dbFeeEarner]
			ON dbFeeEarner.feeusrID = udExtFile.cboNomPartner
		INNER JOIN 
		(
			SELECT 
				RTRIM(dim_employee.knownas) + ' ' + RTRIM(dim_employee.surname) AS nominated_partner
				, dim_employee.workemail		AS [NominatedPartnerEmail]
			FROM red_dw.dbo.dim_employee 
		) AS nom_partner_email
			ON nom_partner_email.nominated_partner COLLATE DATABASE_DEFAULT = dbFeeEarner.feeSignOff
	WHERE 
		dbClient.clNo = 'N1001'
	) AS NominatedPartner
	ON NominatedPartner.fileID = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN (
				SELECT DISTINCT
					dim_detail_health.nhs_scheme
					, CASE 
						WHEN dim_detail_health.nhs_scheme IN ('CNSGP', 'CNST', 'DH CL', 'ELS', 'ELSGP', 'ELSGP (MDDUS)', 'ELSGP (MPS)', 'CNSC') THEN
							'Clinical'
						WHEN dim_detail_health.nhs_scheme IN ('DH Liab', 'LTPS','PES') THEN 
							'Non-Clinical'
						ELSE
							'Other'
						END									AS tranche_group
				FROM red_dw.dbo.dim_detail_health
				)	AS tranche_groups
	ON ISNULL(tranche_groups.nhs_scheme, 'empty') = ISNULL(dim_detail_health.nhs_scheme, 'empty')
WHERE dim_matter_header_current.client_group_name='NHS Resolution'
AND dim_matter_header_current.date_closed_practice_management IS NULL
AND reporting_exclusions=0
AND work_type_group  IN ('EL','PL All','NHSLA')
AND dim_detail_outcome.[date_costs_settled] IS NULL
AND dim_matter_header_current.present_position NOT IN ('To be closed/minor balances to be clear','Final bill sent - unpaid','Final bill due - claim and costs concluded') /*jl 1.1*/
AND LOWER(ISNULL(dim_detail_core_details.[referral_reason],'')) NOT IN ('advice only','pre-action disclosure') 
) AS AllData
LEFT OUTER JOIN (
				SELECT 
					pivot_data.tranche
					, pivot_data.matter_type
					, pivot_data.[claimant costs]
					, pivot_data.[damages]
					, pivot_data.[defence costs]
					, pivot_data.[settlement time]
				--INTO #panel_averages
				FROM (
					SELECT 
						all_data.tranche
						, all_data.matter_type
						, all_data.type	AS kpi_type
						, SUM(all_data.total_panel_value) / SUM(all_data.no_of_cases_converted)		AS panel_average
					FROM ( 
						SELECT 
							*
							, IIF(p45_NHSR_data.scheme = 'CNST', 'Clinical', 'Non-Clinical')		AS matter_type
							, CAST(ROUND(CAST(p45_NHSR_data.no_cases AS FLOAT), 0) AS INT)	AS no_of_cases_converted
							, (CAST(ROUND(CAST(p45_NHSR_data.no_cases AS FLOAT), 0) AS INT) * CAST(p45_NHSR_data.average AS FLOAT))  AS total_panel_value
						FROM DataScience..p45_NHSR_data
						WHERE
							p45_NHSR_data.date = (SELECT MAX(p45_NHSR_data.date) FROM DataScience..p45_NHSR_data WHERE p45_NHSR_data.scheme <> 'ELS')
							AND p45_NHSR_data.scheme <> 'ELS'
						) AS all_data
					GROUP BY
						all_data.tranche
						, all_data.matter_type
						, all_data.type
					) AS panel_average_data
				PIVOT
					(
						SUM(panel_average)
						FOR kpi_type IN ([claimant costs], [damages], [defence costs], [settlement time])
					) AS pivot_data
				) AS panel_averages
	ON AllData.Tranche = panel_averages.tranche
		AND AllData.tranche_group = panel_averages.matter_type


-----------------All filters---------------------------
IF @FeeEarner='All' AND @TM='All'  AND @Partner='All'
BEGIN

SELECT *
FROM #nhsr_defence_costs_management

END 

-----------------Fee Earner filters---------------------
IF @FeeEarner<>'All' AND @TM='All'  AND @Partner='All'
BEGIN

SELECT *
FROM #nhsr_defence_costs_management
WHERE [workemail] =@FeeEarner

END 

-----------------TM filters----------------------------
IF @FeeEarner='All' AND @TM<>'All'  AND @Partner='All'
BEGIN

SELECT *
FROM #nhsr_defence_costs_management
WHERE
	TMEMail =@TM

END 

-----------------Partner filters------------------------
IF @FeeEarner='All' AND @TM='All'  AND @Partner<>'All'
BEGIN

SELECT *
FROM #nhsr_defence_costs_management
WHERE 
	NominatedPartnerEmail =@Partner

END 
END
GO
