SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2019-05-10
-- Description:	AIG Trial Alert Report
-- =============================================

CREATE PROCEDURE [AIG].[AIGTrialAlertReport] 
(	
	@Month1 AS DATE
	,@Month2 AS DATE
	,@Month3 AS DATE
	,@Month4 AS DATE
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
--DECLARE @Month1 DATE ='2019-04-01'
--DECLARE @Month2 DATE ='2019-05-01'
--DECLARE @Month3 DATE ='2019-06-01'
--DECLARE @Month4 DATE ='2019-07-01'


SELECT DISTINCT fact_dimension_main.client_code AS [Client Code]
	, fact_dimension_main.matter_number AS [Matter Number]
	, dim_fed_hierarchy_history.name AS [Matter Owner]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_detail_core_details.aig_instructing_office AS [AIG Instructing Office]
	, dim_detail_core_details.clients_claims_handler_surname_forename AS [Client Claims Handler]
	, dim_detail_core_details.aig_reference AS [AIG Reference]
	, dim_detail_court.date_of_trial AS [Trial Date]
	, fact_finance_summary.total_damages_and_tp_costs_reserve AS [Indemnity Reserve]
	, fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
	, dim_detail_litigation.reason_for_trial AS [Reason for Trial]
	, [TrialKeyDateProcedureDate].calendar_date AS [Next Key Date for Trial]
	, [TrialDateTodayDate].calendar_date AS [Reminder Trial Due Today]
	, dim_detail_claim.date_of_disposal_hearing AS [Date of Disposal Hearing]
	, [DisposalHearingKeyDateProcedureDate].calendar_date AS [Next Key Date for Disposal Hearing]
	, [SmallClaimsHearingTodayDate].calendar_date AS [Next Key Date for Small Claims Hearing]
	, dim_detail_court.date_small_track_hearing AS [Date Small Track Hearing]
	, instruction_type AS [Instruction Type]
	

	, CASE WHEN (dim_client.client_code IN ('00006864','00006865') OR (dim_client.client_code='A2002' AND instruction_type IN ('Casualty','Costs only','Major Loss','Marine')))
			AND ((dim_detail_court.date_of_trial>=@Month1 AND dim_detail_court.date_of_trial<@Month2)
			OR (dim_detail_claim.date_of_disposal_hearing>=@Month1 AND dim_detail_claim.date_of_disposal_hearing<@Month2)
			OR ([TrialDateTodayDate].calendar_date>=@Month1 AND [TrialDateTodayDate].calendar_date<@Month2)
			OR ([TrialKeyDateProcedureDate].calendar_date>=@Month1 AND [TrialKeyDateProcedureDate].calendar_date<@Month2)
			OR ([DisposalHearingKeyDateProcedureDate].calendar_date>=@Month1 AND [DisposalHearingKeyDateProcedureDate].calendar_date<@Month2)
			OR ([SmallClaimsHearingTodayDate].calendar_date>=@Month1 AND [SmallClaimsHearingTodayDate].calendar_date<@Month2)
			)
			AND dim_department.department_code<>'0015'
			THEN 'EL/PL'
		WHEN (dim_client.client_code IN ('00006864','00006865','00006868','00006876','00006866','00006861') OR (dim_client.client_code='A2002' AND instruction_type IN ('Disease')))
			AND ((dim_detail_court.date_of_trial>=@Month1 AND dim_detail_court.date_of_trial<@Month4)
			OR (dim_detail_claim.date_of_disposal_hearing>=@Month1 AND dim_detail_claim.date_of_disposal_hearing<@Month4)
			OR ([TrialDateTodayDate].calendar_date>=@Month1 AND [TrialDateTodayDate].calendar_date<@Month4)
			OR ([TrialKeyDateProcedureDate].calendar_date>=@Month1 AND [TrialKeyDateProcedureDate].calendar_date<@Month4)
			OR ([DisposalHearingKeyDateProcedureDate].calendar_date>=@Month1 AND [DisposalHearingKeyDateProcedureDate].calendar_date<@Month4)
			OR ([SmallClaimsHearingTodayDate].calendar_date>=@Month1 AND [SmallClaimsHearingTodayDate].calendar_date<@Month4)
			)
			AND dim_department.department_code='0015'
			AND dim_detail_claim.matter_number<>'ML'
			THEN 'Disease'
		WHEN (dim_client.client_code IN ('00006868','00006876','00006866','00006861') OR (dim_client.client_code='A2002' AND instruction_type IN ('Motor Fraud','Motor non-Fraud')))
			AND ((dim_detail_court.date_of_trial>=@Month1 AND dim_detail_court.date_of_trial<@Month3)
			OR (dim_detail_claim.date_of_disposal_hearing>=@Month1 AND dim_detail_claim.date_of_disposal_hearing<@Month3)
			OR (dim_detail_court.date_small_track_hearing>=@Month1 AND dim_detail_court.date_small_track_hearing<@Month3)
			OR ([TrialDateTodayDate].calendar_date>=@Month1 AND [TrialDateTodayDate].calendar_date<@Month3)
			OR ([TrialKeyDateProcedureDate].calendar_date>=@Month1 AND [TrialKeyDateProcedureDate].calendar_date<@Month3)
			OR ([DisposalHearingKeyDateProcedureDate].calendar_date>=@Month1 AND [DisposalHearingKeyDateProcedureDate].calendar_date<@Month3)
			OR ([SmallClaimsHearingTodayDate].calendar_date>=@Month1 AND [SmallClaimsHearingTodayDate].calendar_date<@Month3)
			)
			THEN 'Motor'
		END AS [Category]


FROM red_dw.dbo.fact_dimension_main
INNER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key

LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [TrialDateToday] ON [TrialDateToday].client_code = fact_dimension_main.client_code 
AND [TrialDateToday].matter_number = fact_dimension_main.matter_number
AND TrialDateToday.task_desccription='Trial date - today'
LEFT OUTER JOIN red_dw.dbo.fact_tasks [TrialDateTodayFact] ON [TrialDateTodayFact].dim_tasks_key = TrialDateToday.dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [TrialDateTodayDate] ON [TrialDateTodayDate].dim_date_key = [TrialDateTodayFact].dim_task_due_date_key

LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [TrialKeyDateProcedure] ON [TrialKeyDateProcedure].client_code = fact_dimension_main.client_code 
AND [TrialKeyDateProcedure].matter_number = fact_dimension_main.matter_number
AND TrialKeyDateProcedure.task_desccription='Trial key date procedure'
LEFT OUTER JOIN red_dw.dbo.fact_tasks [TrialKeyDateProcedureFact] ON [TrialKeyDateProcedureFact].dim_tasks_key = [TrialKeyDateProcedure].dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [TrialKeyDateProcedureDate] ON [TrialKeyDateProcedureDate].dim_date_key = [TrialKeyDateProcedureFact].dim_task_due_date_key

LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [DisposalHearingKeyDateProcedure] ON [DisposalHearingKeyDateProcedure].client_code = fact_dimension_main.client_code 
AND [DisposalHearingKeyDateProcedure].matter_number = fact_dimension_main.matter_number
AND DisposalHearingKeyDateProcedure.task_desccription='Disposal hearing key date procedure'
LEFT OUTER JOIN red_dw.dbo.fact_tasks [DisposalHearingKeyDateProcedureFact] ON [DisposalHearingKeyDateProcedureFact].dim_tasks_key = [DisposalHearingKeyDateProcedure].dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [DisposalHearingKeyDateProcedureDate] ON [DisposalHearingKeyDateProcedureDate].dim_date_key = [DisposalHearingKeyDateProcedureFact].dim_task_due_date_key

LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [SmallClaimsHearingToday] ON [SmallClaimsHearingToday].client_code = fact_dimension_main.client_code 
AND [SmallClaimsHearingToday].matter_number = fact_dimension_main.matter_number
AND [SmallClaimsHearingToday].task_desccription='Small Claim Track hearing due - today                                                               '
LEFT OUTER JOIN red_dw.dbo.fact_tasks [SmallClaimsHearingTodayFact] ON [SmallClaimsHearingTodayFact].dim_tasks_key = [SmallClaimsHearingToday].dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [SmallClaimsHearingTodayDate] ON [SmallClaimsHearingTodayDate].dim_date_key = [SmallClaimsHearingTodayFact].dim_task_due_date_key

LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_litigation ON dim_detail_litigation.dim_detail_litigation_key = fact_dimension_main.dim_detail_litigation_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

WHERE dim_client.client_group_code='00000013'
AND outcome_of_case IS NULL 
AND (CASE WHEN (dim_client.client_code IN ('00006864','00006865') OR (dim_client.client_code='A2002' AND instruction_type IN ('Casualty','Costs only','Major Loss','Marine')))
			AND ((dim_detail_court.date_of_trial>=@Month1 AND dim_detail_court.date_of_trial<@Month2)
			OR (dim_detail_claim.date_of_disposal_hearing>=@Month1 AND dim_detail_claim.date_of_disposal_hearing<@Month2)
			OR ([TrialDateTodayDate].calendar_date>=@Month1 AND [TrialDateTodayDate].calendar_date<@Month2)
			OR ([TrialKeyDateProcedureDate].calendar_date>=@Month1 AND [TrialKeyDateProcedureDate].calendar_date<@Month2)
			OR ([DisposalHearingKeyDateProcedureDate].calendar_date>=@Month1 AND [DisposalHearingKeyDateProcedureDate].calendar_date<@Month2)
			OR ([SmallClaimsHearingTodayDate].calendar_date>=@Month1 AND [SmallClaimsHearingTodayDate].calendar_date<@Month2)
			)
			AND dim_department.department_code<>'0015'
			THEN 'EL/PL'
		WHEN (dim_client.client_code IN ('00006864','00006865','00006868','00006876','00006866','00006861') OR (dim_client.client_code='A2002' AND instruction_type IN ('Disease')))
			AND ((dim_detail_court.date_of_trial>=@Month1 AND dim_detail_court.date_of_trial<@Month4)
			OR (dim_detail_claim.date_of_disposal_hearing>=@Month1 AND dim_detail_claim.date_of_disposal_hearing<@Month4)
			OR ([TrialDateTodayDate].calendar_date>=@Month1 AND [TrialDateTodayDate].calendar_date<@Month4)
			OR ([TrialKeyDateProcedureDate].calendar_date>=@Month1 AND [TrialKeyDateProcedureDate].calendar_date<@Month4)
			OR ([DisposalHearingKeyDateProcedureDate].calendar_date>=@Month1 AND [DisposalHearingKeyDateProcedureDate].calendar_date<@Month4)
			OR ([SmallClaimsHearingTodayDate].calendar_date>=@Month1 AND [SmallClaimsHearingTodayDate].calendar_date<@Month4)
			)
			AND dim_department.department_code='0015'
			AND dim_detail_claim.matter_number<>'ML'
			THEN 'Disease'
		WHEN (dim_client.client_code IN ('00006868','00006876','00006866','00006861') OR (dim_client.client_code='A2002' AND instruction_type IN ('Motor Fraud','Motor non-Fraud')))
			AND ((dim_detail_court.date_of_trial>=@Month1 AND dim_detail_court.date_of_trial<@Month3)
			OR (dim_detail_claim.date_of_disposal_hearing>=@Month1 AND dim_detail_claim.date_of_disposal_hearing<@Month3)
			OR (dim_detail_court.date_small_track_hearing>=@Month1 AND dim_detail_court.date_small_track_hearing<@Month3)
			OR ([TrialDateTodayDate].calendar_date>=@Month1 AND [TrialDateTodayDate].calendar_date<@Month3)
			OR ([TrialKeyDateProcedureDate].calendar_date>=@Month1 AND [TrialKeyDateProcedureDate].calendar_date<@Month3)
			OR ([DisposalHearingKeyDateProcedureDate].calendar_date>=@Month1 AND [DisposalHearingKeyDateProcedureDate].calendar_date<@Month3)
			OR ([SmallClaimsHearingTodayDate].calendar_date>=@Month1 AND [SmallClaimsHearingTodayDate].calendar_date<@Month3)
			)
			THEN 'Motor'
		END) IS NOT NULL

END
GO
