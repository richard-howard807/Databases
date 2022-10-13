SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Covea_Covea New Instructions and Trial_CostsSavings]
(
	@OpenDateFrom AS DATE,
	@OpenDateTo AS DATE
)
AS

/*Testing*/
--DECLARE @OpenDateFrom AS DATE = GETDATE()-60
--,@OpenDateTo AS DATE = GETDATE()

SELECT 
 [Covea Ref] = [dim_client_involvement].insurerclient_reference
,[Covea Handler] = [dim_detail_core_details].clients_claims_handler_surname_forename
,[PH Name] = insuredclient1_addresse
,addresse
,[Weightmans Ref] = dim_matter_header_current.master_client_code +'-'+ master_matter_number
,[Weightmans Handler] = name
,[Date costs settled] = dim_detail_outcome.[date_costs_settled]
,[Claimant costs claimed] = ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0) 
						  + ISNULL(fact_finance_summary.[detailed_assessment_costs_claimed_by_claimant], 0)
						  + ISNULL(fact_finance_summary.[costs_claimed_by_another_defendant], 0)

,[Claimant costs paid] =    ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
                          + ISNULL(fact_finance_summary.[detailed_assessment_costs_paid], 0)
						  + ISNULL(fact_finance_summary.[other_defendants_costs_paid],0)


,[Weightmans Office] = locationidud
,dim_detail_outcome.[outcome_of_case]

FROM red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.[dim_detail_core_details]
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_employee
ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN 

(
select
fact_dimension_main.master_fact_key,
dim_client.contact_salutation insuredclient1_contact_salutation,
dim_client.addresse insuredclient1_addresse,
dim_client.address_line_1 insuredclient1_address_line_1,
dim_client.address_line_2 insuredclient1_address_line_2,
dim_client.address_line_3 insuredclient1_address_line_3,
dim_client.address_line_4 insuredclient1_address_line_4,
dim_client.postcode insuredclient1_postcode

from
red_dw.dbo.dim_client_involvement

inner join red_dw.dbo.fact_dimension_main
 on fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key

inner join red_dw.dbo.dim_involvement_full 
 on dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insuredclient_1_key

inner join red_dw.dbo.dim_client 
 on dim_client.dim_client_key = dim_involvement_full.dim_client_key

where 
dim_client.dim_client_key != 0

) dimClientAddress ON dimClientAddress.master_fact_key = fact_dimension_main.master_fact_key
--[dim_insuredclient_address_insuredclient1_addresse_]
WHERE 1 = 1
AND dim_client.[client_code] IN ('00162924','W15396')
AND reporting_exclusions = 0
/*Outcome field is one of the paid ones (begins settled/lost at trial/appeal) */
AND (LOWER(outcome_of_case) LIKE '%settled%' OR LOWER(outcome_of_case)  LIKE '%lost at trial%' OR LOWER(outcome_of_case) LIKE '%appeal%')
AND date_costs_settled BETWEEN @OpenDateFrom AND @OpenDateTo

--begins settled/lost at trial/appeal) 
--LEFT JOIN red_dw.dbo.dim_insur


GO
