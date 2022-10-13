SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[WhitbreadFinancials]
AS

BEGIN

SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [MS Client Matter Reference]
	, dim_matter_header_current.dim_matter_header_curr_key
	, dim_matter_header_current.matter_description		AS [Matter Description]
	, CAST(dim_date.calendar_date AS DATE)		AS [Payment Date]
	, SUM(fact_bill.bill_total)		AS [Total Paid]
	, dim_bill.bill_number		AS [Bill Number]
	, dim_detail_client.whitbread_brand		AS [Brand]
	, dim_detail_practice_area.primary_case_classification			AS [Primary Case Classification]
	, dim_detail_practice_area.secondary_case_classification		AS [Secondary Case Classification]
	, dim_detail_client.emp_rmg_sensitive_case			AS [Emp, RMG) Senstive Case]
	, dim_detail_practice_area.emp_claimant_represented		AS [Emp) Claimant Represented]
	, dim_detail_claim.dst_claimant_solicitor_firm		AS [Claimant Solicitor Firm]
	, dim_detail_client.emp_claimants_place_of_work		AS [Emp) Claimant's Place of Work]
	, dim_detail_practice_area.emp_present_position		AS [Emp) Present Position]
	, fact_detail_reserve_detail.potential_compensation		AS [Emp) Potential Compensation / Pension Loss]
	, dim_detail_practice_area.emp_prospects_of_success		AS [Emp) Prospects of Success]
	, dim_detail_court.emp_date_of_final_hearing		AS [Emp) Date of Final Hearing]
	, dim_detail_court.emp_date_of_preliminary_hearing_case_management		AS [Emp) Date of Preliminary Hearing (Case Management)]
	, dim_detail_court.location_of_hearing			AS [Emp) Location of Hearing]
	, dim_detail_court.length_of_hearing		AS [Emp) Length of Hearing]
	, dim_detail_practice_area.emp_outcome		AS [Emp) Outcome]
	, 'Bill Level'		AS [Financial Level]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
		ON dim_detail_practice_area.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_bill
		ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_bill
		ON dim_bill.bill_sequence = fact_bill.bill_sequence
	INNER JOIN red_dw.dbo.dim_date
		ON fact_bill.dim_bill_date_key = dim_date.dim_date_key
WHERE
	dim_matter_header_current.master_client_code = 'W15630'
	AND dim_bill.bill_reversed = 0
	AND fact_bill.bill_number <> 'PURGE'
	--AND dim_date.fin_year = 2022
GROUP BY
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number
	, dim_matter_header_current.dim_matter_header_curr_key
	, dim_matter_header_current.matter_description
	, CAST(dim_date.calendar_date AS DATE)
	, dim_bill.bill_number
	, dim_detail_client.whitbread_brand
	, dim_detail_practice_area.primary_case_classification
	, dim_detail_practice_area.secondary_case_classification
	, dim_detail_client.emp_rmg_sensitive_case
	, dim_detail_practice_area.emp_claimant_represented
	, dim_detail_claim.dst_claimant_solicitor_firm
	, dim_detail_client.emp_claimants_place_of_work
	, dim_detail_practice_area.emp_present_position
	, fact_detail_reserve_detail.potential_compensation
	, dim_detail_practice_area.emp_prospects_of_success
	, dim_detail_court.emp_date_of_final_hearing
	, dim_detail_court.emp_date_of_preliminary_hearing_case_management
	, dim_detail_court.location_of_hearing
	, dim_detail_court.length_of_hearing
	, dim_detail_practice_area.emp_outcome

UNION 

SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [MS Client Matter Reference]
	, dim_matter_header_current.dim_matter_header_curr_key
	, dim_matter_header_current.matter_description		AS [Matter Description]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)		AS [Payment Date]
	, fact_detail_paid_detail.actual_compensation		AS [Total Paid]
	, NULL		AS [Bill Number]
	, dim_detail_client.whitbread_brand		AS [Brand]
	, dim_detail_practice_area.primary_case_classification			AS [Primary Case Classification]
	, dim_detail_practice_area.secondary_case_classification		AS [Secondary Case Classification]
	, dim_detail_client.emp_rmg_sensitive_case			AS [Emp, RMG) Senstive Case]
	, dim_detail_practice_area.emp_claimant_represented		AS [Emp) Claimant Represented]
	, dim_detail_claim.dst_claimant_solicitor_firm		AS [Claimant Solicitor Firm]
	, dim_detail_client.emp_claimants_place_of_work		AS [Emp) Claimant's Place of Work]
	, dim_detail_practice_area.emp_present_position		AS [Emp) Present Position]
	, fact_detail_reserve_detail.potential_compensation		AS [Emp) Potential Compensation / Pension Loss]
	, dim_detail_practice_area.emp_prospects_of_success		AS [Emp) Prospects of Success]
	, dim_detail_court.emp_date_of_final_hearing		AS [Emp) Date of Final Hearing]
	, dim_detail_court.emp_date_of_preliminary_hearing_case_management		AS [Emp) Date of Preliminary Hearing (Case Management)]
	, dim_detail_court.location_of_hearing			AS [Emp) Location of Hearing]
	, dim_detail_court.length_of_hearing		AS [Emp) Length of Hearing]
	, dim_detail_practice_area.emp_outcome		AS [Emp) Outcome]
	, 'Matter Level'		AS [Financial Level]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
		ON dim_detail_practice_area.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'W15630'
	AND dim_detail_outcome.date_claim_concluded IS NOT NULL

END


GO
