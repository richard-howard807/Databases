SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE	[dbo].[RMGLicencesReport]
AS
BEGIN
SELECT RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [WeightmansRef]
,date_opened_case_management AS [Date Opened]
,dim_detail_property.[client_case_reference]
,dim_detail_property.[be_number]
,matter_owner_full_name AS [matter_owner_name]
,dim_detail_property.[contact_property]
,dim_detail_property.[legal_contact]
,dim_detail_property.[external_surveyor]
,dim_detail_property.[case_classification]
,dim_detail_property.[landlord]
,dim_detail_property.[completion_date] AS [completion_date_]
,dim_detail_property.[be_name]
,fileExternalNotes AS fileNotes
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN ms_prod.config.dbFile
 ON fileID=ms_fileid

WHERE case_classification = 'Licence for alterations'
AND date_closed_case_management IS NULL
END 

GO
