SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:Steven Gregory
-- Date: 23/05/19
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [converge].[NextListing]

AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	SELECT 
fact_dimension_main.client_code,
fact_dimension_main.matter_number,
dim_matter_header_current.master_client_code,
master_matter_number,
case_id,
CAST(CAST(fact_dimension_main.matter_number AS INT) AS VARCHAR(50)) AS WeightmansRef,
dim_claimant_address.addresse Claimantname,
dim_detail_critical_mi.policy_type PolicyType,
[dim_detail_core_details].[incident_date] Dateofincident ,
dim_detail_client.[business_unit] BusinessUnit, 
dim_detail_incident.[status_summary] StatusOfClaim,
dim_detail_client.[cause] EONCause,
dim_detail_hire_details.[description_of_injury] Descriptionofinjury,
dim_detail_critical_mi.[accident_description] Descriptionofincident,
dim_detail_critical_mi.[date_closed] Recordofcloseddates,
dim_detail_court.[date_proceedings_issued]  DateProceedingsIssued,
ISNULL(dim_detail_litigation.[reason_for_litigation], 'No')   Litigated,
insurerclient_reference reference,
insuredclient_reference InsuredReference,
dim_matter_header_current.date_opened_case_management DateOpened,
dim_matter_header_current.date_opened_case_management DateClosed,
dim_detail_critical_mi.[claim_status]  ClaimStatus,
dim_detail_incident.[location_of_incident_2]  [Location Of Incident Postcode],
dim_detail_incident.[location_of_incident_1] [Location of Incident],
dim_detail_client.[handling_method] [Handling Method],
dim_detail_flight_delay.[jurisdiction] [Jurisdiction],
dim_detail_critical_mi.[portal_claim] [Portal Claim],
dim_detail_critical_mi.[settled_within_portal] [Settled within Portal],
dim_detail_incident.[portal_drop_out_reason] [Portal drop out reason],

CASE WHEN 	
dim_detail_client.[handling_method] IN ('Desktop - CMS','Destop - CMS*') THEN 1 -- Converge tab -- SSRS temperamental when filtering by text!
				 WHEN dim_detail_client.[handling_method] IN ('In Litigation') THEN 2 -- Weightmans tab
				 WHEN dim_detail_client.[handling_method] IN ('Insurer Led') THEN 3 -- Zurich tab
				 END [Report Tab],

fact_detail_reserve_detail.general_damages_reserve_current GeneralDamagesReserve,
fact_detail_paid_detail.general_damages_paid GeneralDamagesPayment,
fact_detail_reserve_detail.special_damages_reserve_current SpecialDamagesReserve,
fact_detail_paid_detail.special_damages_paid SpecialDamagesPayment,
fact_detail_reserve_detail.tp_costs_reserve TPLegalCostsReserve,
fact_detail_paid_detail.total_tp_costs_paid TPLegalCostsPayment,
fact_detail_reserve_detail.own_costs_reserve OwnLegalCostsReserve,
fact_finance_summary.defence_costs_billed OwnLegalCostsPayment,
0 ClaimHandlingFeeReserve,
0 ClaimHandlingFeePayment,
0 GeneralDamagesInsurerReserve,
0 GeneralDamagesInsurerPayment,
0 SpecialDamagesInsurerReserve,
0 SpecialDamagesInsurerPayment,
0 TPLegalCostsInsurerReserve,
0 TPLegalCostsInsurerPayment,
0 OwnLegalCostsInsurerReserve,
0 OwnLegalCostsInsurerPayment,
0 ClaimHandlingFeeInsurerReserve,
0 ClaimHandlingFeeInsurerPayment,
0 TPPropertyDamage,
0 TPPropertyDamageReserve,
0 TPPropertyDamageInsurer,
0 TPPropertyDamageInsurerReserve,
total_incurred TotalIncurred,
fact_finance_summary.total_paid TotalPaid,
fact_finance_summary.total_reserve TotalReserve,
fact_finance_summary.total_recovery TotalRecovered
FROM red_Dw.dbo.fact_dimension_main
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_detail_health ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT JOIN red_Dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
LEFT JOIN red_dw.dbo.dim_detail_hire_details ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
LEFT JOIN red_Dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT JOIN red_Dw.dbo.dim_detail_incident ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
LEFT JOIN red_dw.dbo.dim_detail_client ON   dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT JOIN red_Dw.dbo.dim_detail_litigation ON dim_detail_litigation.dim_detail_litigation_key = fact_dimension_main.dim_detail_litigation_key
LEFT JOIN red_dw.dbo.dim_detail_flight_delay ON dim_detail_flight_delay.dim_detail_flight_dela_key = fact_dimension_main.dim_detail_flight_dela_key
LEFT JOIN red_dw.dbo.dim_department ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT JOIN red_Dw.dbo.dim_claimant_address ON dim_claimant_address.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_Dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_Dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
WHERE
( 
fact_dimension_main.client_code IN ('00636684', '00538797')
AND reporting_exclusions = 0
AND dim_department.department_code = '0027'
AND ISNULL(dim_detail_critical_mi.[claim_status],'') <> 'Cancelled'
AND ISNULL(dim_detail_critical_mi.[policy_type],'') <> '663'
AND fact_dimension_main.matter_number <> 'ML'
)
OR fact_dimension_main.client_code = '00538797' AND fact_dimension_main.matter_number = '00000024'

ORDER BY WeightmansRef




END 



GO
