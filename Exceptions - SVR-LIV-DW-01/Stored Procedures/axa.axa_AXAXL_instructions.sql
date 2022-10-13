SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Julie Loughlin
-- Create date: 19/10/2021
-- Ticket Number:#118862
-- Description:	New datasource for the AXA XL - to track the identity/office from where client has instructed us
   
------------ =============================================
CREATE PROCEDURE [axa].[axa_AXAXL_instructions]
AS
BEGIN


    SELECT DISTINCT
		  dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS  [Weightmans Ref] 
		  ,dim_matter_header_current.matter_description 
		  ,dim_matter_header_current.client_name
		  ,dim_matter_header_current.date_opened_case_management
		  ,dim_matter_header_current.date_closed_case_management
		  ,dim_matter_header_current.matter_owner_full_name
		  ,dim_fed_hierarchy_history.hierarchylevel4hist	 AS [Matter Owner Team]
		  ,dim_fed_hierarchy_history.hierarchylevel3hist AS [Matter Owner Department]
		  ,work_type_name
		  ,referral_reason
		  ,dim_detail_core_details.present_position
		  ,total_amount_billed
		  ,dim_client_involvement.insurerclient_name AS [Insurer Associate]
		  ,dim_detail_core_details.clients_claims_handler_surname_forename as [AXA XL Handler] 
		  ,assocRef
		  ,contEmail

		  ,addLine1
		  ,addLine2
,addLine3
,addLine4
,addLine5
,addPostcode
,contTypeCode
,Associates.contName
,Associates.assocType
,fileID
		  
		  -- [Client Ref] = ISNULL(dim_client_involvement.insurerclient_reference,dim_involvement_full.reference),
           
	
		
    FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
			ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history 
            ON dim_fed_hierarchy_history .dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement 
            ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
   		LEFT JOIN red_dw.dbo.dim_detail_outcome 
			ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key

		LEFT OUTER JOIN   
(  
SELECT DISTINCT fileID,contName,assocRef,contEmail, dbContact.contID,addLine1
,addLine2
,addLine3
,addLine4
,addLine5
,addPostcode
,assocType
,contTypeCode

FROM ms_prod.config.dbAssociates  
INNER JOIN ms_prod.config.dbContact  ON dbContact.contID = dbAssociates.contID  
INNER JOIN ms_prod.dbo.dbContactEmails ON dbContact.contID = dbContactEmails.contID AND contActive = 1 AND contOrder = 0
LEFT OUTER JOIN ms_prod.dbo.dbAddress
ON contDefaultAddress=addID
WHERE assocType='INSURERCLIENT'
AND assocActive = '1'
) AS Associates  
 ON ms_fileid=Associates.fileID  
	
 
 WHERE ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          
          AND dim_matter_header_current.matter_number <> 'ML'
          AND dim_matter_header_current.master_client_code = 'A1001'
          AND dim_matter_header_current.reporting_exclusions = 0
		  AND  work_type_name <>'Commercial Insurance DO NOT USE'
  
  END    
GO
