SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-12-08
-- Description:	#69137, Surrey and Sussex DVPO report
-- =============================================
CREATE PROCEDURE [police].[PoliceDVPO] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT 
dim_matter_header_current.[client_code] AS [Client Code]
, dim_matter_header_current.[matter_number] AS [Matter Number]
, dim_matter_header_current.client_name AS [Client Name]
, dim_matter_header_current.[matter_description] AS [Matter Description]
, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_matter_worktype.[work_type_name] AS [Matter Type]
, dim_detail_advice.[police_respondents_date_of_birth] AS [Respondent's DOB]
, ISNULL(dim_detail_advice.[dvpo_niche_ref],dim_detail_advice.[niche_ref]) AS [Niche ref]
, dim_detail_advice.[dvpo_victim_postcode] AS [Victim Postcode]
, dim_detail_advice.[dvpo_number_of_children] AS [Number of children in property]
, dim_detail_advice.[dvpo_division] AS [Division]
, dim_detail_advice.[dvpo_granted] AS [DVPO granted]
, dim_detail_advice.[dvpo_contested] AS [DVPO contested]
, dim_detail_advice.[dvpo_breached] AS [DVPO breached]
, dim_detail_advice.[dvpo_dvpn_breach] AS [DVPN Breach]
, dim_detail_advice.[dvpo_is_first_breach] AS [First breach of DVPO]
, dim_detail_advice.[dvpo_breach_admitted] AS [DVPO breach admitted/denied]
, dim_detail_advice.[dvpo_breach_proved] AS [DVPO breach proved]
, dim_detail_advice.[dvpo_breach_sentence] AS [DVPO breach sentence]
, dim_detail_advice.[dvpo_breach_sentence_length] AS [Length of custodial sentence]
, fact_detail_paid_detail.[dvpo_breach_fine_amount] AS [Amount of fine]
, dim_detail_advice.[dvpo_legal_costs_sought] AS [Legal costs sought]
, dim_detail_advice.[dvpo_court_fee_awarded] AS [Costs (court fee) awarded]
, fact_detail_recovery_detail.[dvpo_court_fee_awarded_amount] AS [Amount of court fees awarded]
, dim_detail_advice.[dvpo_own_fees_awarded] AS [Costs (Weightmans fees) awarded]
, fact_detail_recovery_detail.[dvpo_own_fees_awarded_amount] AS [Amount of Weightmans fees awarded]
, fact_detail_recovery_detail.[dvpo_legal_costs_recovered] AS [Legal costs recovered]
, ISNULL(fact_finance_summary.[defence_costs_billed],0)+ ISNULL(fact_finance_summary.[disbursements_billed],0)
+ ISNULL(fact_finance_summary.[total_billed_disbursements_vat],0)+ ISNULL(fact_finance_summary.[defence_costs_vat],0) AS [Total billed]
, Doogal.Latitude AS [Victim Postcode Latitude]
, Doogal.Longitude AS [Victim Postcode Longitude]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT outer JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.Doogal
ON Doogal.Postcode=dim_detail_advice.dvpo_victim_postcode

WHERE dim_matter_header_current.[reporting_exclusions]=0
AND dim_matter_worktype.[work_type_code] IN ('1579','1602')

END
GO
