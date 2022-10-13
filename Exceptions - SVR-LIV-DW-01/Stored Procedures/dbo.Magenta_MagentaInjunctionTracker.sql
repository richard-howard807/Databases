SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Max Taylor
-- Create date: 2022-03-16
-- Description:	139436  - datasource for Magenta/Magenta Injunction Tracker 
 
-- =============================================
CREATE PROCEDURE [dbo].[Magenta_MagentaInjunctionTracker] 

AS

SELECT 
	 [Weightmans Reference] = dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number 
	,[UPRN] =  gascomp_uprn
    ,[Tenant's Name] = REPLACE(REPLACE(SUBSTRING(REPLACE(matter_description,'Injunction:','Injunction') , CHARINDEX('Injunction', REPLACE(matter_description,'Injunction:','Injunction') ), CHARINDEX(':',REPLACE(matter_description,'Injunction:','Injunction') ) - CHARINDEX('Injunction', REPLACE(matter_description,'Injunction:','Injunction') ) + Len(':')), 'Injunction ',''),':','')
	,[Tenant's Address] = REPLACE(RIGHT(matter_description,NULLIF(CHARINDEX(':',REVERSE(matter_description)),0)-1) ,ISNULL(CASE WHEN RIGHT(dim_matter_header_current.matter_description,charindex(' ',reverse(dim_matter_header_current.matter_description))+4) LIKE '%,%' THEN NULL ELSE RIGHT(dim_matter_header_current.matter_description,charindex(' ',reverse(dim_matter_header_current.matter_description))+4) END, '') , '') 
	,[Tenant's Postcode] = CASE WHEN RIGHT(dim_matter_header_current.matter_description,charindex(' ',reverse(dim_matter_header_current.matter_description))+4) LIKE '%,%' THEN NULL ELSE RIGHT(dim_matter_header_current.matter_description,charindex(' ',reverse(dim_matter_header_current.matter_description))+4) END 	
	,[Date Opened] = CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		
	,[Date Closed] = CAST(dim_matter_header_current.date_closed_practice_management AS DATE)		
	,[Case Manager] = dim_matter_header_current.matter_owner_full_name		
	,[Expiry of Gas Certificate]  =  CAST(dim_detail_claim.[gascomp_expiry_of_gas_certificate] AS DATE)
	,[LBA Date Upload] = CAST(dim_detail_claim.gascomp_lba_date_upload	AS DATE)		 
	,[LBA Expiry Date] = CAST(dim_detail_claim.gascomp_lba_expiry_date AS DATE)		
	,[Injunction Application Date] = CAST(dim_detail_claim.gascomp_injunction_application_date AS DATE)	
	,[Injunction Type] = dim_detail_claim.gascomp_injunction_type		
	,[Hearing Date] = CAST(dim_detail_claim.gascomp_hearing_date AS DATE)			
	,[Date Order Served] = CAST(dim_detail_claim.gascomp_date_order_served AS DATE)		
	,[Injunction Service Date] = CAST(dim_detail_claim.gascomp_injunction_service_date AS DATE)		
	,[Date Access Obtained] = dim_detail_claim.[gascomp_date_access_obtained]
	,[Current Status]  = dim_detail_claim.[gascomp_current_status]
	,[Reason over 3 months] = dim_detail_claim.[gascomp_reason_over_three_months]
	,[Comments] = dim_detail_claim.gascomp_comments	
	,[Magenta Instruction Type] = cboMagenInsType.cboMagenInsType -- Added on 25-03-2022 MT - Waiting on DWH Field
	,[Total Billed] =  fact_finance_summary.total_amount_bill_non_comp		 
	,[Revenue] = fact_finance_summary.defence_costs_billed			
	,[Disbursements] = fact_finance_summary.disbursements_billed		
	,[VAT] = fact_finance_summary.vat_billed			
	,[Last Bill Date] =CASE WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN NULL ELSE CAST(fact_matter_summary_current.last_bill_date AS DATE) END													
	,[Completed_Ongoing_Flag] =CASE WHEN dim_detail_claim.[gascomp_date_access_obtained] IS NOT NULL THEN 'Completed' ELSE 'Ongoing' END
	,dim_matter_worktype.work_type_name
	,ms_fileid
    ,instruction_type
	,[Region] =  gascomp_region 
    ,[Matter Description] = dim_matter_header_current.matter_description	
     ,[Gas or ELec] = CASE WHEN lower(cboMagenInsType.cboMagenInsType) LIKE '%gas%' THEN 'Gas'
	                       WHEN lower(cboMagenInsType.cboMagenInsType) LIKE '%elec%' THEN 'Elec' END
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
	LEFT JOIN (SELECT DISTINCT cdCode, cdDesc AS cboMagenInsType FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboMagenInsType' AND txtMSTable = 'udMICoreGeneralA') cboMagenInsType 
ON cboMagenInsType.cdCode = udMICoreGeneralA.cboMagenInsType

WHERE 1 = 1
	
	AND dim_matter_header_current.master_client_code = 'W15498'
	AND reporting_exclusions = 0
	AND ISNULL(matter_description, '') <> 'Ignore - opened in error'
	AND ISNULL(outcome_of_case, '') <> 'Exclude from reports'
	AND (ISNULL(dim_matter_worktype.work_type_name,'') like '%Injunction%' OR instruction_type like '%Injunction%')


	ORDER BY dim_detail_claim.[gascomp_expiry_of_gas_certificate] ASC


	


    


	
GO
