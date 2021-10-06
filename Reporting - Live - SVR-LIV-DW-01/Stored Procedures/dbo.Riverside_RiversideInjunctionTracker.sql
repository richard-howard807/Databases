SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Max Taylor
-- Create date: 2021-03-29
-- Description:	93740 - datasource for Riverside/Riverside Injunction Tracker 
 
-- =============================================
CREATE PROCEDURE [dbo].[Riverside_RiversideInjunctionTracker] 
AS

SELECT 
	dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [Weightmans Reference]
	, dim_matter_worktype.work_type_name
	, gascomp_uprn		AS [UPRN]
	, gascomp_region AS [Region]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)		AS [Date Closed]
	, dim_matter_header_current.matter_owner_full_name		AS [Case Manager]
	, CAST(dim_detail_claim.gascomp_lba_date_upload	AS DATE)		AS [LBA Date Upload]
	, CAST(dim_detail_claim.gascomp_lba_expiry_date AS DATE)		AS [LBA Expiry Date]
	, CAST(dim_detail_claim.gascomp_injunction_application_date AS DATE)	AS [Injunction Application Date]
	, dim_detail_claim.gascomp_injunction_type		AS [Injunction Type]
	, CAST(dim_detail_claim.gascomp_hearing_date AS DATE)			AS [Hearing Date]
	, CAST(dim_detail_claim.gascomp_date_order_served AS DATE)		AS [Date Order Served]
	, CAST(dim_detail_claim.gascomp_injunction_service_date AS DATE)		AS [Injunction Service Date]
	, dim_detail_claim.gascomp_comments				AS [Comments]
	, fact_finance_summary.total_amount_bill_non_comp		AS [Total Billed]
	, fact_finance_summary.defence_costs_billed			AS [Revenue]
	, fact_finance_summary.disbursements_billed		AS [Disbursements]
	, fact_finance_summary.vat_billed			AS [VAT]
	, CASE
		WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
			NULL
		ELSE
            CAST(fact_matter_summary_current.last_bill_date AS DATE)
	  END													AS [Last Bill Date],

	[Expiry of Gas Certificate]  =  CAST(dim_detail_claim.[gascomp_expiry_of_gas_certificate] AS DATE),
	[Date Access Obtained] = dim_detail_claim.[gascomp_date_access_obtained], 
	[Current Status]  = dim_detail_claim.[gascomp_current_status],
	[Reason over 3 months] = dim_detail_claim.[gascomp_reason_over_three_months],

	[Completed_Ongoing_Flag] = CASE WHEN dim_detail_claim.[gascomp_date_access_obtained] IS NOT NULL THEN 'Completed' ELSE 'Ongoing' END,
	[Tenant's Name] = TRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(dim_matter_header_current.matter_description, 'Kerrie-Louise', 'Kerrie Louise'), 'Wilkes-Ryan', 'Wilkes Ryan'), 'Abdel-Salam', 'Abdel Salam'), 'Hannah-Martin', 'Hannah Martin'), CHARINDEX('GAS  ', REPLACE(REPLACE(REPLACE(REPLACE(dim_matter_header_current.matter_description, 'Kerrie-Louise', 'Kerrie Louise'), 'Wilkes-Ryan', 'Wilkes Ryan'), 'Abdel-Salam', 'Abdel Salam'), 'Hannah-Martin', 'Hannah Martin')), CHARINDEX('-',REPLACE(REPLACE(REPLACE(REPLACE(dim_matter_header_current.matter_description, 'Kerrie-Louise', 'Kerrie Louise'), 'Wilkes-Ryan', 'Wilkes Ryan'), 'Abdel-Salam', 'Abdel Salam'), 'Hannah-Martin', 'Hannah Martin')) - CHARINDEX('GAS  ', REPLACE(REPLACE(REPLACE(REPLACE(dim_matter_header_current.matter_description, 'Kerrie-Louise', 'Kerrie Louise'), 'Wilkes-Ryan', 'Wilkes Ryan'), 'Abdel-Salam', 'Abdel Salam'), 'Hannah-Martin', 'Hannah Martin')) + Len('-')), 'GAS  ', ''), 'GAS ', ''), '-', '')),
	[Tenant's Address] = CASE WHEN matter_description LIKE '%-%' THEN  TRIM(',' FROM REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(matter_description, TRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(dim_matter_header_current.matter_description, CHARINDEX('GAS  ', dim_matter_header_current.matter_description), CHARINDEX('-',dim_matter_header_current.matter_description) - CHARINDEX('GAS  ', dim_matter_header_current.matter_description) + Len('-')), 'GAS  ', ''), 'GAS ', ''), '-', '')), ''), RIGHT(dim_matter_header_current.matter_description,CHARINDEX(',',REVERSE(dim_matter_header_current.matter_description))-1), ''), 'GAS  - ', ''), 'GAS -', ''), 'Martin - ', ''), 'Louise Darby - ', ''), 'Salam - ', ''), 'Ryan - ', '')) ELSE matter_description END
	,[Tenant's Postcode] =  RIGHT(dim_matter_header_current.matter_description,CHARINDEX(',',REVERSE(dim_matter_header_current.matter_description))-1) 
	,matter_description
  ,ms_fileid
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.client_code = dim_matter_header_current.client_code
			AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	INNER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN	red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
			AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number


WHERE 1 = 1
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code = 'W15603'
	AND RTRIM(dim_matter_worktype.work_type_name) = 'Injunction'
	AND reporting_exclusions = 0
	AND ISNULL(matter_description, '') <> 'Ignore - opened in error'


	ORDER BY dim_detail_claim.[gascomp_expiry_of_gas_certificate] asc
	
	
GO
