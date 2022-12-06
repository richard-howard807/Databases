SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE  PROCEDURE [dbo].[RealEstate_DocumentsSenttoClientReport] 


AS 




SELECT client_name AS [Client Name]
,dim_matter_header_current.master_client_code AS [Client Number]
,master_matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,name AS [Matter Owner]
,hierarchylevel4hist AS [Team]
,date_instructions_received AS [Date Instructions Received]
,date_opened_case_management AS [Date File Opened]
,date_closed_case_management AS [Date File Closed]
,CONVERT(DATE, dim_detail_plot_details.[date_documents_sent], 102) AS [Documents Sent to Client]
,MAX(dbContact.contName) OVER (PARTITION BY ms_fileid) AS [Purchase Solicitor Name]
,exchange_date_combined AS [exchange_date]

,ISNULL(dim_detail_property.[completion_date],dim_detail_plot_details.[pscompletion_date]) AS [completion_date]
,dim_detail_property.[status]
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
JOIN red_dw.dbo.fact_dimension_main 
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_plot_details
ON dim_detail_plot_details.dim_detail_plot_detail_key = fact_dimension_main.dim_detail_plot_detail_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'


LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.client_code = dim_matter_header_current.client_code
 AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number

LEFT JOIN ms_prod.config.dbAssociates
ON ms_fileid = fileID AND assocType = 'PURCHASERSOLS'
JOIN ms_prod.config.dbContact ON dbContact.contID = dbAssociates.contID

WHERE dim_matter_header_current.master_client_code IN ('61955B|165769B|00648125|W15353|174502M|177451B|118361B|161818D|177450B|117776T|113768B|190593P|00101439|00785070|153838M|W23852|00848629')
--AND (completion_date>='2021-01-01' OR completion_date IS NULL)
--AND (date_closed_case_management>='2021-01-01' OR date_closed_case_management IS NULL)
AND work_type_name LIKE '%Plot Sales%'
AND date_opened_case_management >= '2015-05-01'
AND reporting_exclusions = 0
AND dim_matter_header_current.master_client_code + '-' + master_matter_number <> '190593P-7716'

AND hierarchylevel4hist  NOT IN ( 'Workflows', 'Business Analytics')

AND name IN 
('Anita Forshaw'
,'Becky McCormick'
,'Karen Hetherington'
,'Lisa Evans'
,'Molly Heymans'
,'Anthony Howarth'
)
AND  NOT  (exchange_date_combined IS NOT NULL OR  ISNULL(dim_detail_property.[completion_date],dim_detail_plot_details.[pscompletion_date]) IS  NOT NULL)
AND date_closed_case_management IS NULL
AND ISNULL(dim_detail_property.status,'') <>'Abortive'
AND   matter_description NOT LIKE '%Abort%'
AND ms_fileid NOT IN (SELECT fileID FROM ms_prod.config.dbFile
WHERE fileNotes LIKE '%Abort%' OR fileExternalNotes LIKE '%Abort%' OR fileAlertMessage LIKE '%Abort%')
AND matter_description NOT LIKE '%Variation%'



GO
