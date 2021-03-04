SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






--author OK 

--report to drive the Motor closure report which will include the Exceptions




CREATE PROCEDURE [dbo].[MotorClosureNew] --EXEC [dbo].[MotorClosureNew] 'Motor Management'
(
	@Team AS VARCHAR(MAX) 
	, @FeeEarner AS VARCHAR(MAX)

)
AS
	BEGIN  

	
	IF OBJECT_ID('tempdb..#FeeEarnerList') IS NOT NULL   DROP TABLE #FeeEarnerList

	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team

	SELECT ListValue  INTO #FeeEarnerList FROM 	dbo.udt_TallySplit(',', @FeeEarner)

	SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)



	;WITH test AS ( 



	SELECT  
	red_dw.dbo.dim_matter_header_current.client_code [Clientcte], dim_matter_header_current.matter_number [Mattercte], dim_detail_finance.[output_wip_fee_arrangement] ,

CASE WHEN 
(( (dim_detail_core_details.present_position not IN
(
--'Claim and costs concluded but recovery outstanding',
'Claim and costs outstanding',
'Claim concluded but costs outstanding'
)

AND (dim_detail_outcome.outcome_of_case IS NULL OR 
            dim_detail_outcome.date_claim_concluded IS NULL )) OR 
			
			
			(( (dim_detail_core_details.present_position IN
(
--'Claim and costs concluded but recovery outstanding',
'Claim and costs outstanding',
'Claim concluded but costs outstanding'
) AND 

(dim_detail_outcome.outcome_of_case IS NOT  NULL OR 
            dim_detail_outcome.date_claim_concluded IS NOT NULL )))))) THEN 1 ELSE 0 END AS final, 

      
			

				CASE WHEN fact_finance_summary.unpaid_bill_balance >1 THEN 1 ELSE 0 END AS [unpaidbillbalance],
				
CASE WHEN dim_detail_core_details.present_position IN
(

'Final bill due - claim and costs concluded',
'Final bill sent - unpaid',
'To be closed/minor balances to be clear'
)

 AND fact_finance_summary.wip > 1  THEN 1 
 WHEN 
 dim_detail_core_details.present_position IN
(
'Final bill due - claim and costs concluded',
'Final bill sent - unpaid',
'To be closed/minor balances to be clear'
)

AND fact_finance_summary.disbursement_balance > 1

THEN 1 ELSE 0 END [unpaidbills], 

CASE WHEN ((dim_matter_header_current.fee_arrangement NOT   IN
(
'Fixed Fee/Fee Quote/Capped Fee                              '
)
AND dim_matter_header_current.fixed_fee_amount > 0 ) OR 


(
dim_matter_header_current.fee_arrangement   IN
(
'Fixed Fee/Fee Quote/Capped Fee                              '
)
AND dim_matter_header_current.fixed_fee_amount = 0


)) THEN 1 ELSE 0 END AS 
[Fixed Fee Amount is inconistent with fee arrangement], 



CASE WHEN 


dim_detail_core_details.present_position NOT IN
(
'Claim and costs concluded but recovery outstanding',
'Claim and costs outstanding',
'Claim concluded but costs outstanding'
) AND (dim_detail_outcome.outcome_of_case IS NULL OR dim_detail_outcome.date_claim_concluded IS NULL ) THEN 1 

WHEN 
dim_detail_core_details.present_position  IN
(
'Claim and costs concluded but recovery outstanding',
'Claim and costs outstanding',
'Claim concluded but costs outstanding'
) AND (dim_detail_outcome.outcome_of_case IS NOT NULL OR dim_detail_outcome.date_claim_concluded IS not NULL ) THEN 1 ELSE 0 END AS [PP is inconsistent with DCC/ Outcome] , 

CASE WHEN 

 dim_detail_core_details.present_position IN
(
'Final bill due - claim and costs concluded',
'Final bill sent - unpaid',
'To be closed/minor balances to be clear'
) AND dim_detail_outcome.date_costs_settled IS NULL THEN 1 

WHEN 
 dim_detail_core_details.present_position NOT  IN
(
'Final bill due - claim and costs concluded',
'Final bill sent - unpaid',
'To be closed/minor balances to be clear'
) AND dim_detail_outcome.date_costs_settled IS NOT NULL THEN 1 ELSE 0 END AS [PP is consistent with Costs Settled], 

CASE WHEN 

	DATEDIFF(d, fact_matter_summary_current.last_time_transaction_date, GETDATE()) > 60 THEN 1 ELSE 0 END AS [Not worked on for 60+ days],
	CASE WHEN dim_fed_hierarchy_history.leaver= 1 THEN 1 ELSE 0 END AS [Leaver]


FROM 
red_Dw.dbo.fact_dimension_main 


LEFT JOIN red_dw.dbo. dim_matter_header_current  ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

WHERE
dim_matter_header_current.date_closed_case_management IS NULL 
AND fact_dimension_main.client_code NOT IN ('00030645','00453737')
AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'

AND dim_matter_header_current.date_closed_case_management IS NULL 


) 



SELECT CASE WHEN test.unpaidbills = 1 THEN 'Unpaid Bills' ELSE '' END AS [Unpaid Bills1], 
CASE WHEN [Fixed Fee Amount is inconistent with fee arrangement] = 1 THEN 'Fixed Fee Amount is inconistent with fee arrangement' ELSE '' END AS [Fixed Fee Amount is inconistent with fee arrangement2],
CASE WHEN [PP is inconsistent with DCC/ Outcome] = 1 THEN 'PP is inconsistent with DCC/ Outcome' ELSE '' END AS [PP is inconsistent with DCC/ Outcome3],
CASE WHEN [PP is consistent with Costs Settled] = 1 THEN 'PP is consistent with Costs Settled' ELSE '' END as [PP is consistent with Costs Settled4], 
CASE WHEN [Not worked on for 60+ days] = 1 THEN 'Not worked on for 60+ days' ELSE '' END AS [Not worked on for 60+ days5], 
CASE WHEN [Leaver] = 1 THEN 'Leaver' ELSE '' END AS [Leaver6], 





                fact_dimension_main.[client_code] [client_code] ,
                dim_matter_header_current.[matter_number] [matter_number],
				dim_matter_header_current.master_client_code, dim_matter_header_current.master_matter_number, 
				    REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'+
     REPLACE(LTRIM(REPLACE(RTRIM(dim_matter_header_current.master_matter_number), '0', ' ')), ' ', '0') AS [Mattersphere Weightmans Reference],
                dim_matter_header_current.[matter_description] ,
                red_dw.dbo.dim_fed_hierarchy_history.name [matter_owner_name],
               -- dim_fed_hierarchy_history_matter_owner[matter_owner_displayname],
                dim_fed_hierarchy_history.hierarchylevel4hist[matter_owner_team],
                dim_detail_core_details.[track],
                dim_detail_core_details.[present_position],
				test.unpaidbills,
								CASE WHEN dim_detail_core_details.present_position IN
(
'Claim and costs concluded but recovery outstanding'
)
AND 
dim_fed_hierarchy_history.name <> 'Chris Ball' THEN 'Refer to Chris Ball' ELSE dim_detail_core_details.present_position END AS [Present Postion],
                dim_matter_header_current.date_opened_case_management [matter_opened_practice_management_calendar_date],
                dim_detail_core_details.[proceedings_issued],
                dim_detail_outcome.[date_claim_concluded],
                dim_detail_outcome.[outcome_of_case],
                dim_detail_outcome.[date_costs_settled],
                dim_detail_core_details.[grpageas_motor_moj_stage],
                dim_detail_core_details.[fixed_fee],
                fact_finance_summary.[fixed_fee_amount],
                fact_finance_summary.[wip],
                fact_finance_summary.[disbursement_balance],
				fact_matter_summary_current.last_bill_date, 
				DATEDIFF(d, fact_matter_summary_current.last_time_transaction_date, GETDATE()) lastworkedon, 
				


CASE WHEN ((dim_matter_header_current.fee_arrangement NOT   IN
(
'Fixed Fee/Fee Quote/Capped Fee                              '
)
AND dim_matter_header_current.fixed_fee_amount > 0 ) OR 


(
dim_matter_header_current.fee_arrangement   IN
(
'Fixed Fee/Fee Quote/Capped Fee                              '
)
AND dim_matter_header_current.fixed_fee_amount = 0


)) THEN 1 ELSE 0 END AS colourfixedfee,

--dim_fed_hierarchy_history.leaver , 






CASE WHEN 
( (dim_detail_core_details.present_position not IN
(
--'Claim and costs concluded but recovery outstanding',
'Claim and costs outstanding',
'Claim concluded but costs outstanding'
)

AND (dim_detail_outcome.outcome_of_case IS NULL OR 
            dim_detail_outcome.date_claim_concluded IS NULL ) OR 
			
			
			( (dim_detail_core_details.present_position IN
(
--'Claim and costs concluded but recovery outstanding',
'Claim and costs outstanding',
'Claim concluded but costs outstanding'
) AND 

(dim_detail_outcome.outcome_of_case IS NOT  NULL OR 
            dim_detail_outcome.date_claim_concluded IS NOT NULL ))))) THEN 1 ELSE 0 END AS final, 

                dim_detail_core_details.[is_this_a_linked_file],
                dim_detail_core_details.[is_this_the_lead_file],
                dim_client_involvement.[insuredclient_reference],
                fact_finance_summary.[defence_costs_billed],
                fact_finance_summary.[client_account_balance_of_matter],
              --  fact_matter_summary_current.[last_time_transaction_date] [last_time_calendar_date],
                fact_finance_summary.[unpaid_bill_balance],
                fact_detail_reserve_detail.[total_reserve], 
				exceptions.no_excptions [Action], 
				dim_detail_core_details.referral_reason [Referral Reason] , dim_detail_finance.output_wip_fee_arrangement




FROM test 
LEFT JOIN 
red_Dw.dbo.fact_dimension_main ON fact_dimension_main.client_code = test.Clientcte AND test.Mattercte = fact_dimension_main.matter_number


LEFT JOIN red_dw.dbo.dim_matter_header_current  ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
--INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist COLLATE DATABASE_DEFAULT
--INNER JOIN #FeeEarnerList AS FeeEarner ON FeeEarner.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT
LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

LEFT JOIN ( SELECT fact_exceptions_update.fieldname,
COUNT(*) no_excptions, 
fact_exceptions_update.client_code, fact_exceptions_update.matter_number

FROM red_dw.dbo.fact_exceptions_update
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_exceptions_update.dim_fed_hierarchy_history_key

WHERE fact_exceptions_update.datasetid = '226'
AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
AND fact_exceptions_update.duplicate_flag <> 1

GROUP BY	fact_exceptions_update.client_code,
            fact_exceptions_update.matter_number, fact_exceptions_update.fieldname


) AS exceptions ON exceptions.matter_number = fact_finance_summary.matter_number AND exceptions.client_code = fact_finance_summary.client_code

LEFT JOIN dbo.fact_exceptions_update ON fact_exceptions_update.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key

WHERE
dim_matter_header_current.date_closed_case_management IS NULL 
AND fact_dimension_main.client_code NOT IN ('00030645','00453737')
AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
--AND dim_fed_hierarchy_history.hierarchylevel4hist IN (@Team)
--AND dim_fed_hierarchy_history.name IN (@FeeEarner)
AND dim_matter_header_current.date_closed_case_management IS NULL 

GROUP BY	REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'
            + REPLACE(LTRIM(REPLACE(RTRIM(dim_matter_header_current.master_matter_number), '0', ' ')), ' ', '0'),dim_detail_finance.output_wip_fee_arrangement,
            CASE
            WHEN dim_detail_core_details.present_position IN ( 'Claim and costs concluded but recovery outstanding' )
            AND dim_fed_hierarchy_history.name <> 'Chris Ball' THEN
            'Refer to Chris Ball'
            ELSE
            dim_detail_core_details.present_position
            END,
            CASE
            WHEN
            (
            (
            dim_matter_header_current.fee_arrangement NOT IN ( 'Fixed Fee/Fee Quote/Capped Fee                              ' )
            AND dim_matter_header_current.fixed_fee_amount > 0
            )
            OR
            (
            dim_matter_header_current.fee_arrangement IN ( 'Fixed Fee/Fee Quote/Capped Fee                              ' )
            AND dim_matter_header_current.fixed_fee_amount = 0
            )
            ) THEN
            1
            ELSE
            0
            END,
            fact_dimension_main.client_code,
            fact_dimension_main.matter_number,
			dim_matter_header_current.matter_number,
            dim_matter_header_current.matter_description,
            dim_fed_hierarchy_history.name,
            dim_fed_hierarchy_history.hierarchylevel4hist,
            dim_detail_core_details.track,
            dim_matter_header_current.present_position,
            dim_matter_header_current.date_opened_case_management,
            dim_detail_core_details.proceedings_issued,
            dim_detail_outcome.date_claim_concluded,
            dim_detail_outcome.outcome_of_case,
            dim_detail_outcome.date_costs_settled,
            dim_detail_core_details.grpageas_motor_moj_stage,
            dim_matter_header_current.fixed_fee,
            dim_matter_header_current.fixed_fee_amount,
            fact_finance_summary.wip,
            fact_finance_summary.disbursement_balance,
            fact_matter_summary_current.last_bill_date,
            dim_detail_core_details.is_this_a_linked_file,
            dim_detail_core_details.is_this_the_lead_file,
            dim_client_involvement.insuredclient_reference,
            fact_finance_summary.defence_costs_billed,
            fact_finance_summary.client_account_balance_of_matter,
            fact_finance_summary.unpaid_bill_balance,
            fact_finance_summary.total_reserve,
            exceptions.no_excptions, dim_detail_core_details.present_position,
			red_dw.dbo.dim_detail_core_details.fixed_fee,
			red_dw.dbo.fact_finance_summary.fixed_fee_amount, 
			fact_detail_reserve_detail.total_reserve, 
			dim_fed_hierarchy_history.leaver, 
			last_time_transaction_date, 
			test.unpaidbills, 
			[Fixed Fee Amount is inconistent with fee arrangement], 
			[PP is inconsistent with DCC/ Outcome], 
			[PP is consistent with Costs Settled], 
			[Not worked on for 60+ days], 
			[Leaver], dim_detail_core_details.referral_reason, dim_matter_header_current.master_client_code, dim_matter_header_current.master_matter_number











			END


				--COUNT(DISTINCT(dbo.fact_exceptions_update.)) NoExceptions
				--exceptions.no_excptions
				

GO
