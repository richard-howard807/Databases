SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CoopInsurerCheck]
AS
BEGIN
 
SELECT   
dim_matter_header_current.master_client_code + '-'+ master_matter_number AS [Client/matter number]  
,matter_description AS [Case Description]  
,name AS [Handler]  
,hierarchylevel4hist AS Team  
,clients_claims_handler_surname_forename AS [Insurer Client  Handler]  
,Associates.assocRef AS [Insurer Client Reference]  
,Associates.contEmail AS [Insurer Client e-mail address]  
,dim_detail_core_details.present_position AS [Present Position]  
,last_bill_date AS [Last Bill Date]  
,last_time_transaction_date AS [Last Time]  


FROM red_dw.dbo.dim_matter_header_current  
INNER JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history   
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key  
LEFT JOIN red_dw.dbo.dim_client_involvement  
 ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details  
 ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key 
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current  
ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN   
(  
SELECT DISTINCT fileID,contName,assocRef,contEmail, dbContact.contID FROM ms_prod.config.dbAssociates  
INNER JOIN ms_prod.config.dbContact  ON dbContact.contID = dbAssociates.contID  
INNER JOIN ms_prod.dbo.dbContactEmails ON dbContact.contID = dbContactEmails.contID AND contActive = 1 AND contOrder = 0
WHERE assocType='INSURERCLIENT'  
) AS Associates  
 ON ms_fileid=Associates.fileID  
  
WHERE red_dw.dbo.dim_matter_header_current.master_client_code IN ('C1001','W24438')  
AND red_dw.dbo.dim_matter_header_current.date_closed_practice_management IS NULL  
AND ms_only=1  
AND master_matter_number<>'0'  

END
GO
