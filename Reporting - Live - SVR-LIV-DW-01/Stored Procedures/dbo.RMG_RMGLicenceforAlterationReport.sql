SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RMG_RMGLicenceforAlterationReport]

(
@OpenDateFrom AS DATE, 
@OpenDateTo AS DATE,
@Status AS VARCHAR(20)
)

AS 

/* Testing*/
--DECLARE 
--@OpenDateFrom AS DATE = GETDATE() -300, 
--@OpenDateTo AS DATE = GETDATE(),
--@Status AS VARCHAR(20) = 'Closed'


SELECT 

[Client Matter] = fact_dimension_main.master_client_code +'-'+master_matter_number,
[Date Opened] = CAST(date_opened_case_management AS DATE),
[Date Closed] = CAST(date_closed_case_management AS DATE),
[Team] = hierarchylevel4hist,
[Case Description] = matter_description,
[BE Name] = dim_detail_property.[be_name], 
[RMG Reference] = dim_detail_property.[client_case_reference],
[BE Number] = dim_detail_property.[be_number],
[Weightmans Contact] = name,
[RM Estate Manager]	= dim_detail_property.[estate_manager],
[RM Project Manager] =	dim_detail_property.[management_company],
[RM Lawyer] =	dim_detail_property.[legal_contact],
[External Agent] =	dim_detail_property.[external_surveyor],
[Landlord] =	dim_detail_property.landlord,
[Landlord's Solicitor] ='',
[Landlord's Costs] ='',
[Undertaking provided] ='',
[Works Description] ='',
[Date of Instruction] = dim_detail_core_details.[date_instructions_received],
[Proposed Start Date] ='',
[Works Status] ='',
[Comments] = '',
[Status] = CASE WHEN date_closed_case_management IS NOT NULL THEN 'Closed' ELSE 'Open' END
FROM 

red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_detail_property
ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
WHERE 1 = 1 
AND dim_client.[client_group_name] = 'Royal Mail'

AND CAST(date_opened_case_management AS DATE) BETWEEN @OpenDateFrom AND @OpenDateTo

AND reporting_exclusions = 0

AND dim_detail_property.[case_classification] = 'Licence for alterations'

AND ISNULL(@Status, 'All') =    
CASE WHEN @Status = 'All' THEN 'All' 
WHEN date_closed_case_management IS NOT NULL THEN 'Closed' 
ELSE 'Open' 
END
GO
