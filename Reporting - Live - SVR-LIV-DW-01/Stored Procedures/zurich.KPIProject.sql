SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-02-17
-- Description:	#88726, new kpi report for zurich
-- =============================================
-- added non zurich clients as requested
-- =============================================
--EXEC [zurich].[KPIProject] 'Zurich'

CREATE PROCEDURE [zurich].[KPIProject]

@Client VARCHAR(MAX)

AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Client') IS NOT NULL   DROP TABLE #Client

			CREATE TABLE #Client 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Client
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Client) 

IF @Client='Zurich'
BEGIN
SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.date_opened_case_management AS [Date Opened]
	, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, dim_detail_core_details.date_instructions_received AS [Date Instructions Received]
	, dim_matter_worktype.work_type_group AS [Matter Type Group]
	, dim_matter_worktype.work_type_name AS [Matter Type]
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_detail_core_details.referral_reason AS [Referral Reason]
	, dim_detail_core_details.track AS [Track]
	, dim_matter_header_current.fee_arrangement AS [Fee Arrangement]
	, CASE WHEN dim_matter_header_current.fee_arrangement='Hourly rate' THEN ISNULL(fact_finance_summary.total_amount_billed,0)+ISNULL(fact_finance_summary.wip,0)
		WHEN dim_matter_header_current.fee_arrangement='Fixed Fee/Fee Quote/Capped Fee' THEN NULL ELSE NULL END AS [Billed]
	, dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS [Date of Receipt of Client's File of Papers]
	, fact_finance_summary.damages_reserve AS [Damages Reserve (gross)]
	, fact_detail_cost_budgeting.personal_injury_reserve_current AS [Personal Injury Reserve Current (aka General Damages)]
	, ISNULL(fact_finance_summary.damages_reserve,0) - ISNULL(fact_detail_cost_budgeting.personal_injury_reserve_current,0) AS [Special Damages]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, NULL AS [Last Billed Date]
	, CASE WHEN dim_detail_outcome.date_claim_concluded IS NULL THEN DATEDIFF(day, dim_matter_header_current.date_opened_case_management, GETDATE()) 
	ELSE DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_outcome.date_claim_concluded) END AS [Days Since Instructions Received]
	, fact_finance_summary.damages_paid AS [Damages Paid by Client]
	, fact_finance_summary.wip AS [WIP]
	, CASE WHEN ISNULL(dim_matter_header_current.client_group_code,'')='00000001' THEN 'Zurich' ELSE 'Non-Zurich' END AS [Client]
	, PanelAverages.[Total Reserve] AS [Panel Average Total Reserve]
    , PanelAverages.[General Damages] AS [Panel Average General Damages]
    , PanelAverages.[Special Damages] AS [Panel Average Special Damages]
    , PanelAverages.[Days to Settle] AS [Panel Average Days to Settle]
	, PanelAverages.[Own Costs] AS [Panel Averages Own Costs]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN Reporting.zurich.PanelAverages ON PanelAverages.[Work Type Group]=dim_matter_worktype.work_type_group COLLATE DATABASE_DEFAULT
AND PanelAverages.Track=dim_detail_core_details.track COLLATE DATABASE_DEFAULT

INNER JOIN #Client AS Client ON Client.ListValue = (CASE WHEN ISNULL(dim_matter_header_current.client_group_code,'')='00000001' THEN 'Zurich' ELSE 'Non-Zurich' END)

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.client_group_code='00000001'
AND dim_fed_hierarchy_history.hierarchylevel3hist='Casualty'
AND dim_matter_header_current.present_position IN ('Claims and costs outstanding','Claim concluded but costs outstanding')
AND dim_detail_core_details.referral_reason LIKE 'Dispute%'

END

ELSE 
BEGIN
SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.date_opened_case_management AS [Date Opened]
	, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, dim_detail_core_details.date_instructions_received AS [Date Instructions Received]
	, dim_matter_worktype.work_type_group AS [Matter Type Group]
	, dim_matter_worktype.work_type_name AS [Matter Type]
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_detail_core_details.referral_reason AS [Referral Reason]
	, dim_detail_core_details.track AS [Track]
	, dim_matter_header_current.fee_arrangement AS [Fee Arrangement]
	, dim_matter_header_current.fixed_fee_amount AS [Fixed Fee Amount]
	, dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS [Date of Receipt of Client's File of Papers]
	, fact_finance_summary.damages_reserve AS [Damages Reserve (gross)]
	, fact_detail_cost_budgeting.personal_injury_reserve_current AS [Personal Injury Reserve Current (aka General Damages)]
	, ISNULL(fact_finance_summary.damages_reserve,0) - ISNULL(fact_detail_cost_budgeting.personal_injury_reserve_current,0) AS [Special Damages]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, NULL AS [Last Billed Date]
	, CASE WHEN dim_detail_outcome.date_claim_concluded IS NULL THEN DATEDIFF(day, dim_matter_header_current.date_opened_case_management, GETDATE()) 
		ELSE DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, dim_detail_outcome.date_claim_concluded) END AS [Days Since Instructions Received]
	, fact_finance_summary.damages_paid AS [Damages Paid by Client]
	, fact_finance_summary.wip AS [WIP]
	, ISNULL(wip,0)+ISNULL(fact_finance_summary.defence_costs_billed,0) AS [Billed]
	, CASE WHEN ISNULL(dim_matter_header_current.client_group_code,'')='00000001' THEN 'Zurich' ELSE 'Non-Zurich' END AS [Client]
	, PanelAverages.[Total Reserve] AS [Panel Average Total Reserve]
    , PanelAverages.[General Damages] AS [Panel Average General Damages]
    , PanelAverages.[Special Damages] AS [Panel Average Special Damages]
    , PanelAverages.[Days to Settle] AS [Panel Average Days to Settle]
	, PanelAverages.[Own Costs] AS [Panel Averages Own Costs]
	, PanelAverages.Lifecycle AS [Target Lifecycle]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN Reporting.zurich.PanelAverages ON PanelAverages.[Work Type Group]=dim_matter_worktype.work_type_group COLLATE DATABASE_DEFAULT
AND PanelAverages.Track=dim_detail_core_details.track COLLATE DATABASE_DEFAULT

INNER JOIN #Client AS Client ON Client.ListValue = (CASE WHEN ISNULL(dim_matter_header_current.client_group_code,'')='00000001' THEN 'Zurich' ELSE 'Non-Zurich' END)

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.client_group_code<>'00000001'
AND dim_fed_hierarchy_history.hierarchylevel3hist='Casualty'
AND dim_matter_header_current.present_position IN ('Claims and costs outstanding','Claim concluded but costs outstanding')
AND dim_detail_core_details.referral_reason LIKE 'Dispute%'
AND (dim_matter_header_current.fee_arrangement='Fixed Fee/Fee Quote/Capped Fee' OR dim_matter_header_current.fee_arrangement IS NULL)

END
END

GO
