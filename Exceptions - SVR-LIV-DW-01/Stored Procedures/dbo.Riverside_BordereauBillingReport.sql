SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Max Taylor
-- Create date: 2022-09-07
-- Description:	166759  - datasource for Riverside Bordereau Billing Report 
 
-- =============================================
CREATE PROCEDURE [dbo].[Riverside_BordereauBillingReport] 

AS

SELECT 
	 [Client Code] =            dim_matter_header_current.master_client_code 
	,[Matter Number] =          master_matter_number
	,[UPRN] =                   dim_detail_claim.gascomp_uprn
	,[Region] =                 dim_detail_claim.gascomp_region 
	,[Matter Desc] =            matter_description
	,[Current Status]  =        dim_detail_claim.[gascomp_current_status]
	,[Bill Number] =            bill_number
	,[Bill Date] =              bill_date
	,[Bill Amount] =            SUM(bill_total)
	,[Revenue Total] = SUM(fact_bill_matter_detail.fees_total) 
	,Disbursements	= SUM(fact_bill_matter_detail.hard_costs) + SUM(fact_bill_matter_detail.soft_costs)
	,VAT  =           SUM(red_dw.dbo.fact_bill_matter_detail.vat)

	

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
    LEFT JOIN red_dw.dbo.dim_instruction_type
	ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	LEFT JOIN red_dw.dbo.dim_detail_outcome
	ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT JOIN ms_prod.dbo.udMICoreGeneralA
	ON fileID = ms_fileid

	LEFT JOIN red_dw.dbo.fact_bill_matter_detail
	ON fact_bill_matter_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key




WHERE 1 = 1
	
	AND dim_matter_header_current.master_client_code = 'W15603'
	AND matter_description LIKE '%GAS%'
	AND reporting_exclusions = 0
	AND ISNULL(matter_description, '') <> 'Ignore - opened in error'
	AND ISNULL(outcome_of_case, '') <> 'Exclude from reports'

	GROUP BY 
	dim_matter_header_current.master_client_code 
	,master_matter_number
	,dim_detail_claim.gascomp_uprn
	,dim_detail_claim.gascomp_region 
	,matter_description
	,dim_detail_claim.[gascomp_current_status]
	,bill_number
	,bill_date

	ORDER BY bill_date
	



	


    


	
GO
