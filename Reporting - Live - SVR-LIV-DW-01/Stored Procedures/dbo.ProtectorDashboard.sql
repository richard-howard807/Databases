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

SELECT DISTINCT RTRIM(fact_dimension_main.client_code)+'-'+fact_dimension_main.matter_number AS [Weightmans Reference]
	, fact_dimension_main.client_code AS [Client Code]
	, fact_dimension_main.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, date_instructions_received AS [Date Instructions Received]
	, date_opened_case_management AS [Date Opened]
	, date_closed_case_management AS [Date Closed]
	, dim_fed_hierarchy_history.name AS [Matter Owner]
	, hierarchylevel3hist AS [Department]
	, suspicion_of_fraud AS [Suspicion of Fraud]
	, track AS [Track]
	, work_type_name AS [Work Type Name]
	, work_type_group AS [Work Type Group]
	, dim_detail_core_details.present_position AS [Present Position]
	, claimantsols_name AS [Claimant Solicitor]
	, outcome_of_case AS [Outcome]
	, date_claim_concluded AS [Date Claim Concluded]
	, damages_paid AS [Damages Paid]
	, claimants_costs_paid AS [TP Costs Paid]
	, defence_costs_billed AS [Revenue]
	, elapsed_days_damages AS [Damages Lifecycle]
	, elapsed_days_costs AS [Costs Lifecycle]
	, proceedings_issued AS [Proceedings Issued]
	, ClaimantsAddress.[claimant1_postcode] AS [Claimant's Postcode]
	, dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement]
	, Longitude
	, Latitude

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
ON fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_involvement_full
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
		LEFT OUTER JOIN red_dw.dbo.Doogal ON Doogal.Postcode=ClaimantsAddress.claimant1_postcode

WHERE reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2018-07-01')
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
,'4851','4852','4855','4863'
))
OR (dim_matter_header_current.master_client_code='W15442' AND dim_involvement_full.name LIKE '%Protector%')
OR (dim_matter_header_current.master_client_code='W20163' AND dim_detail_core_details.does_claimant_have_personal_injury_claim='Yes'AND dim_detail_core_details.incident_date>'2018-07-14')
)



END


GO
