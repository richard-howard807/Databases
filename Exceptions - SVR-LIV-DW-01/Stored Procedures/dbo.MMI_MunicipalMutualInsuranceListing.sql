SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================  
-- Author:  Max Taylor  
-- Create date: 04/08/2022 
-- Description: initial Create  #160998
-- =============================================  
CREATE PROCEDURE [dbo].[MMI_MunicipalMutualInsuranceListing]
   
AS  


SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [MS Reference]
	, COALESCE(dim_client_involvement.insurerclient_reference, dim_client_involvement.client_reference)		AS [Insurer Client Reference]
	, dim_claimant_thirdparty_involvement.claimant_name		AS [Claimant Name]
	, dim_client_involvement.insuredclient_name				AS [Insured Client Name]
	, dim_matter_header_current.matter_owner_full_name		AS [Matter Owner Name]
	, dim_detail_core_details.associated_matter_numbers		AS [Associated Matter Numbers]
	, dim_matter_worktype.work_type_name					AS [Matter Type Name]
	, dim_detail_core_details.brief_description_of_injury		AS [Brief Description of Injury]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE)		AS [Date Closed]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)		AS [Date Opened]
	, COALESCE(dim_court.date_of_trial, key_dates.key_date)		AS [Date of Trial]
	, CAST(dim_detail_core_details.date_initial_report_sent AS DATE)			AS [Date Initial Report Sent]
	, dim_detail_core_details.delegated			AS [Delegated Authority]
	, dim_detail_core_details.present_position		AS [Present Position]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)			AS [Date Claim Concluded]
	, dim_detail_outcome.outcome_of_case			AS [Outcome of Case]
	, CAST(fact_matter_summary_current.last_bill_date AS DATE)		AS [Last Bill Date]
	, fact_finance_summary.wip			AS [WIP]
	, dim_detail_core_details.[proceedings_issued]

FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
			AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN (
						SELECT 
							dim_key_dates.dim_matter_header_curr_key
							, CAST(dim_key_dates.key_date AS DATE)		AS key_date	
							, ROW_NUMBER() OVER(PARTITION BY dim_key_dates.dim_matter_header_curr_key ORDER BY dim_key_dates.key_date)	AS rw
						FROM red_dw.dbo.dim_key_dates
						WHERE 1 = 1
							AND CAST(dim_key_dates.key_date AS DATE) >= CAST(GETDATE() AS DATE)
							AND dim_key_dates.description = 'Date of Trial'
					) AS key_dates
		ON key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN (
						SELECT 
							dim_detail_court.dim_matter_header_curr_key
							, CAST(dim_detail_court.date_of_trial AS DATE)		AS date_of_trial
						FROM red_dw.dbo.dim_detail_court
						WHERE 1 = 1
							AND CAST(dim_detail_court.date_of_trial AS DATE) >= CAST(GETDATE() AS DATE) 
					)	AS dim_court
		ON dim_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key



WHERE
	dim_matter_header_current.master_client_code = 'M00001'
	AND dim_matter_header_current.reporting_exclusions = 0
ORDER BY
	[Date Opened]
GO
