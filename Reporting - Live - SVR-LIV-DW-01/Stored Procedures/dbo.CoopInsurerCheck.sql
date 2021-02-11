SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CoopInsurerCheck]
AS
BEGIN
SELECT 
master_client_code + '-'+ master_matter_number AS [Client/matter number]
,matter_description AS [Case Description]
,name AS [Handler]
,hierarchylevel4hist AS Team
,clients_claims_handler_surname_forename AS [Insurer Client  Handler]
,Associates.assocRef AS [Insurer Client Reference]
,Associates.assocEmail AS [Insurer Client e-mail address]
,dim_detail_core_details.present_position AS [Present Position]
,last_bill_date AS [Last Bill Date]
,last_time_transaction_date AS [Last Time]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT fileID,contName,assocRef,assocEmail FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='INSURERCLIENT'
) AS Associates
 ON ms_fileid=Associates.fileID

WHERE master_client_code IN ('C1001','W24438')
AND red_dw.dbo.dim_matter_header_current.date_closed_practice_management IS NULL
AND ms_only=1
AND master_matter_number<>'0'

END
GO
