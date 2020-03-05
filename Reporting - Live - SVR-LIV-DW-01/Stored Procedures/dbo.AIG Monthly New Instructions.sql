SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Orlagh Kelly>
-- Create date: 09-07-2019
-- Description:	<report for kathy for new instructions per month for client - AIG ,,>
-- =============================================
CREATE  PROCEDURE [dbo].[AIG Monthly New Instructions]
----	-- Add the parameters for the stored procedure here
@Startdate AS DATETIME  
, @EndDate AS DATETIME 


--DECLARE @Startdate AS DATETIME  = '2019-08-01'
--DECLARE @EndDate AS DATETIME  = '2019-09-01'




--DECLARE @Team AS NVARCHAR (200) 

AS




BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
SELECT DISTINCT

       RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number AS [Weightmans Reference],
       red_dw.dbo.fact_dimension_main.client_code [Client Code],
       red_dw.dbo.fact_dimension_main.matter_number [Matter Number],
       red_dw.dbo.dim_matter_header_current.[matter_description] AS [Matter Description],
	    red_dw.dbo.dim_instruction_type.instruction_type AS [Instruction Type] ,
	   client_partner_name [Partner], 
	   name [ Fee Earner Name ], 
	   hierarchylevel4hist [Team], 
	   fileopener.MSUpdatedBy [File Opener],
	--   work_type_name [Work Type ], 
	   date_instructions_received [Date Instructions Recieved], 
	    dim_matter_header_current.date_opened_case_management AS [Date Case Opened],

[dbo].[ReturnElapsedDaysExcludingBankHolidays](date_instructions_received, red_dw.dbo.dim_matter_header_current.date_opened_case_management) [SLA - file opening],
 
--DATEDIFF(Day, date_instructions_received,dim_matter_header_current.date_opened_case_management ) AS [SLA - file opening],




	    ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0) AS [Fee Arrangement],
      
       dim_matter_header_current.date_closed_case_management AS [Date Case Closed],
	 --  track [Track], 
	 CASE WHEN   LOWER(dim_matter_header_current.delegated )=  'y' THEN 'Yes' 
	 WHEN LOWER(dim_matter_header_current.delegated )=  'n' THEN 'No '
	 ELSE '-'
END AS 	 
	 
	 [Delegated], 
	   
aig_instructing_office [Instucting Office ], 

dim_detail_core_details.[clients_claims_handler_surname_forename] [Clients Claim Handler], 

dim_detail_core_details.[aig_current_fee_scale] [Current Fee Scale], 

--red_dw.dbo.dim_matter_header_current.fixed_fee 
dim_matter_header_current.billing_arrangement [Rate Arrangement],


       --dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded],
       --dim_detail_outcome.[outcome_of_case] AS [Outcome of Case],
       CONVERT(VARCHAR(3), (dim_matter_header_current.date_opened_case_management)) + '-'
       + CONVERT(VARCHAR(4), YEAR(dim_matter_header_current.date_opened_case_management)) AS YearPeriod_MMYY,
       dim_fed_hierarchy_history.[display_name] AS [Case Manager Name],
	
       dim_fed_hierarchy_history.[hierarchylevel2hist] [Division],
       dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department],
      -- dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team],
       dim_matter_header_current.[branch_name] AS [Branch Name],
	      dim_client.client_name AS [Client Name],
       dim_matter_worktype.[work_type_name] AS [Work Type],
      dim_matter_worktype.[work_type_code] AS [Work Type Code],
       dim_client_involvement.[insurerclient_reference] AS [Insurer Client Reference FED],
       dim_detail_core_details.present_position AS [Present Position],
       dim_detail_core_details.track AS [Track],
	   red_dw.dbo.dim_detail_core_details.referral_reason [Referal Reason], 

	 
       fact_detail_elapsed_days.[elapsed_days_live_files] AS [Elapsed Days Live Files],
       CASE
           WHEN fact_detail_elapsed_days.[elapsed_days_live_files] <= 100 THEN
               '0-100'
           WHEN fact_detail_elapsed_days.[elapsed_days_live_files] <= 200 THEN
               '101-200'
           WHEN fact_detail_elapsed_days.[elapsed_days_live_files] <= 300 THEN
               '201-300'
           WHEN fact_detail_elapsed_days.[elapsed_days_live_files] <= 400 THEN
               '301-400'
           WHEN fact_detail_elapsed_days.[elapsed_days_live_files] <= 600 THEN
               '401-600'
           WHEN fact_detail_elapsed_days.[elapsed_days_live_files] > 600 THEN
               '601+'
       END AS [Elapsed Days Live Bandings],
       fact_detail_elapsed_days.[elapsed_days_conclusion] AS [Elapsed Days Conclusion],
  
       1 AS [No. of Records ],
       COALESCE(
                   dim_detail_fraud.[fraud_initial_fraud_type],
                   dim_detail_fraud.[fraud_current_fraud_type],
                   dim_detail_fraud.[fraud_type_ageas],
                   dim_detail_fraud.[fraud_current_secondary_fraud_type],
                   dim_detail_client.[coop_fraud_current_fraud_type],
                   dim_detail_fraud.[fraud_type],
                   dim_detail_fraud.[fraud_type_disease_pre_lit]
               ) AS [Fraud Type],
       CASE
           WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
               NULL
           ELSE
               fact_matter_summary_current.last_bill_date
       END AS [Last Bill Date],
    
	          CONVERT(VARCHAR(3), (dim_matter_header_current.date_opened_case_management)) + '-'
       + CONVERT(VARCHAR(4), YEAR(dim_matter_header_current.date_opened_case_management)) AS YearPeriodMonthopened_MMYY , 
	   dim_detail_core_details.[aig_reference] [Aig Reference], 
	   dim_detail_core_details. [aig_aig_department] [Aig Department], 
	   dim_detail_client.[aig_litigation_number] [Litigation Number ]



	



FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo. dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT	OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
--LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key=fact_dimension_main.dim_detail_critical_mi_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key=fact_dimension_main.dim_detail_fraud_key
--LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key = fact_matter_summary_current.dim_date_key
LEFT outer JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key 
LEFT JOIN (

SELECT client_code AS [client_code]
	,matter_number AS [matter_number]
	,tskDesc AS  [task_description]
    ,dbUser.usrfullname AS [MSUpdatedBy]
	,tskCompleted
	,tskActive
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN MS_Prod.dbo.dbTasks
 ON ms_fileid=fileID
LEFT OUTER JOIN MS_Prod.dbo.dbUser ON dbTasks.UpdatedBy=dbUser.usrid
WHERE client_group_code='00000013'
AND tskDesc LIKE '%File opening process%'
AND tskComplete=1 AND tskActive=1 
 



) AS fileopener ON fileopener.client_code = dim_matter_header_current.client_code AND fileopener.matter_number = dim_matter_header_current.matter_number




WHERE dim_matter_header_current.reporting_exclusions = 0 
AND fact_dimension_main.matter_number <> 'ML'
AND  dim_matter_header_current.date_opened_case_management BETWEEN @Startdate AND @EndDate
AND dim_client.client_group_code = '00000013'
AND fact_dimension_main.client_code = 'A2002'
--AND red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel3hist = @Team
AND ISNULL(outcome_of_case,'') <> 'Exclude from reports             
                 '


				 
END
GO
