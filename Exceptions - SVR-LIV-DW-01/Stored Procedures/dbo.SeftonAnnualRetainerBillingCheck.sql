SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		M Taylor
-- Create date: 20220719
-- Description:	#158592 initial create 

-- =============================================
CREATE PROCEDURE [dbo].[SeftonAnnualRetainerBillingCheck] 


AS

SELECT dim_matter_header_current.[client_code] ,
       dim_matter_header_current.[matter_number] ,
       red_dw.dbo.dim_fed_hierarchy_history.name AS [Fee Earner] ,
       RTRIM(hierarchylevel4hist) AS [Team] ,
       RTRIM(work_type_name) AS work_type_name ,
       RTRIM(dim_matter_header_current.[matter_description]) AS matter_description ,
       RTRIM(dim_detail_core_details.[sefton_annual_contract]) AS sefton_annual_contract ,
       date_opened_case_management ,
       date_closed_practice_management ,
       fact_finance_summary.[total_amount_billed] ,
       fact_finance_summary.[defence_costs_billed] ,
       fact_finance_summary.[disbursements_billed] ,
       fact_finance_summary.[vat_billed] ,
       fact_finance_summary.[wip] ,
       fact_finance_summary.[disbursement_balance],
	   client.insuredclient_name
	   ,[Reason for inclusion] = 

	   CASE WHEN dim_matter_header_current.client_code IN ( 

 '00582093'
,'00755199'
,'00708402'
,'00054852'
,'00054851'
,'W15572' 
,'82953S' 
) THEN 'Sefton MBC client code'

WHEN LOWER(client.insuredclient_name) 
IN ('sefton council','sefton mbc','sefton metropolitan council', 'sefton metropolitan borough council', 'sefton arc')

THEN 'Insured Client Associate'

WHEN LOWER(DefendantAssociate) 
IN ('sefton council','sefton mbc','sefton metropolitan council', 'sefton metropolitan borough council', 'sefton arc')
THEN 'Defendant Associate'

END




FROM   red_dw.dbo.dim_matter_header_current
       INNER JOIN red_dw.dbo.fact_dimension_main main ON main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	   
	   INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code = fee_earner_code COLLATE DATABASE_DEFAULT
                                                          AND dss_current_flag = 'Y'
       LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
       LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
                                                             AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
       LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code
                                                          AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	   LEFT OUTER JOIN red_dw.dbo.dim_client_involvement client ON client.dim_client_involvement_key = main.dim_client_involvement_key

	  

	  LEFT JOIN 

	  (
	  
SELECT DISTINCT 
dim_matter_header_curr_key,
contName AS DefendantAssociate
FROM MS_Prod.config.dbAssociates 
JOIN MS_Prod.config.dbContact
ON dbContact.contID = dbAssociates.contID
JOIN red_dw.dbo.dim_matter_header_current
ON fileID = ms_fileid

WHERE  assocType = 'DEFENDANT'
AND assocActive = 1

	  ) DefendantAssociate ON DefendantAssociate.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE 1=1
AND reporting_exclusions = 0   
AND (dim_matter_header_current.client_code IN ( 

 '00582093'
,'00755199'
,'00708402'
,'00054852'
,'00054851'
,'W15572' 
,'82953S' 
)
											  
												  
OR LOWER(client.insuredclient_name) 
IN ('sefton council','sefton mbc','sefton metropolitan council', 'sefton metropolitan borough council', 'sefton arc')

OR LOWER(DefendantAssociate) 
IN ('sefton council','sefton mbc','sefton metropolitan council', 'sefton metropolitan borough council', 'sefton arc')



)


GO
