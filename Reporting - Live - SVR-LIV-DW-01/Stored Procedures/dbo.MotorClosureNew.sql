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



SELECT DISTINCT
                red_dw.dbo.fact_dimension_main.[client_code] [client_code] ,
                dim_matter_header_current.[matter_number] [matter_number],
				    REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'+
     REPLACE(LTRIM(REPLACE(RTRIM(dim_matter_header_current.master_matter_number), '0', ' ')), ' ', '0') AS [Mattersphere Weightmans Reference],
                dim_matter_header_current.[matter_description] ,
                red_dw.dbo.dim_fed_hierarchy_history.name [matter_owner_name],
               -- dim_fed_hierarchy_history_matter_owner[matter_owner_displayname],
                dim_fed_hierarchy_history.hierarchylevel4hist[matter_owner_team],
                dim_detail_core_details.[track],
                dim_detail_core_details.[present_position],
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

				--disb.Disbursements, 

	--			  CASE
 --       WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
 --           NULL
 --       ELSE
 --           fact_matter_summary_current.last_bill_date
 --   END AS [Last Bill Date], 
	--CASE
 --       WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
 --           NULL
 --       ELSE
 --           fact_matter_summary_current.last_bill_date
 --   END AS [last_bill_calendar_date],

               -- dim_date_last_bill.[last_bill_calendar_date],
                dim_detail_core_details.[is_this_a_linked_file],
                dim_detail_core_details.[is_this_the_lead_file],
                dim_client_involvement.[insuredclient_reference],
                fact_finance_summary.[defence_costs_billed],
                fact_finance_summary.[client_account_balance_of_matter],
              --  fact_matter_summary_current.[last_time_transaction_date] [last_time_calendar_date],
                fact_finance_summary.[unpaid_bill_balance],
                fact_detail_reserve_detail.[total_reserve], 
				exceptions.no_excptions [Action]
				--COUNT(DISTINCT(dbo.fact_exceptions_update.)) NoExceptions
				--exceptions.no_excptions
				

FROM 
red_Dw.dbo.fact_dimension_main 


LEFT JOIN red_dw.dbo. dim_matter_header_current  ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #FeeEarnerList AS FeeEarner ON FeeEarner.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT
LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key

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
            + REPLACE(LTRIM(REPLACE(RTRIM(dim_matter_header_current.master_matter_number), '0', ' ')), ' ', '0'),
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
			fact_detail_reserve_detail.total_reserve


			END 
GO
