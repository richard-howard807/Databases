SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Max Taylor>
-- Create date: <20210517,>
-- Description:	<initial create  >
-- =============================================
CREATE  PROCEDURE [CommercialRecoveries].[Vulnerablecustomerreport]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT 


[BMW_or_MIB] = CASE WHEN dim_matter_header_current.master_client_code IN ('FW22613', 'W15335', 'FW22135') THEN 'BMW'
                    WHEN fact_dimension_main.master_client_code='M1001' THEN 'MIB' END

,[Weightmans Ref] = dim_matter_header_current.master_client_code + '-' + master_matter_number
 ,dim_matter_header_current.client_code
 ,dim_matter_header_current.matter_number
,[Agreement Number] =  dim_client_involvement.client_reference  
,[Customers Name] = COALESCE(defendant.contName,  matter_description COLLATE DATABASE_DEFAULT) 
,[Matter Description] = matter_description
,[Vulnerability Reason]	= dbFile.fileAlertMessage	
,dim_matter_header_current.client_name
,fileAlertLevel
,ms_fileid
,VulnerabilityNotes.txtDescription AS VulnerabilityNotesDesc
,VulnerabilityNotes.txtExtraTxt    AS VulnerabilityNotesText
,VulnerabilityNotes.dteLstEdited   AS VulnerabilityNotesDate
FROM 

red_dw.dbo.dim_matter_header_current 
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
JOIN ms_prod.config.dbFile	
ON ms_fileid = fileID

LEFT JOIN  red_dw.dbo.dim_defendant_involvement
ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key

LEFT JOIN  ( SELECT DISTINCT ROW_NUMBER () OVER (PARTITION BY fileID ORDER BY assocActive DESC, assocOrder  ) AS RN , fileID, dbContact.contName 
				FROM ms_prod.[config].[dbAssociates]
				JOIN ms_prod.config.dbContact ON dbContact.contID = dbAssociates.contID
						WHERE 1 = 1 
						AND assocType = 'DEFENDANT'
						AND contIsClient = 0) 
						defendant ON defendant.fileID = dbFile.fileID AND defendant.RN = 1 


LEFT JOIN (
SELECT 
		udCRHistoryNotesSL.fileID,
		MAX(udCRHistoryNotesSL.txtDescription) txtDescription, 
        MAX(udCRHistoryNotesSL.txtExtraTxt) txtExtraTxt,
		MIN(udCRHistoryNotesSL.dteLstEdited) dteLstEdited
FROM ms_prod.dbo.udCRHistoryNotesSL

WHERE  noteType = 10 OR ( noteType = 9 AND (LOWER(udCRHistoryNotesSL.txtDescription) LIKE '%vuln%' OR LOWER(udCRHistoryNotesSL.txtDescription) LIKE '%vc %' OR LOWER(udCRHistoryNotesSL.txtDescription) LIKE '%v c%'))
      AND ISNULL(udCRHistoryNotesSL.txtDescription, '') <> ''
GROUP BY udCRHistoryNotesSL.fileID
) VulnerabilityNotes ON VulnerabilityNotes.fileID = dbFile.fileID



WHERE 1 =1 


--AND (fileAlertLevel =1 
 
--OR (LOWER(dbFile.fileAlertMessage) LIKE '%vuln%' OR LOWER(dbFile.fileAlertMessage) LIKE '%vc %' OR LOWER(dbFile.fileAlertMessage) LIKE '%v c%')
AND  VulnerabilityNotes.fileID IS NOT null

 AND (dim_matter_header_current.master_client_code IN ('FW22613', 'W15335', 'FW22135')
 OR fact_dimension_main.master_client_code='M1001')


 ORDER BY 1, dim_matter_header_current.master_client_code, master_matter_number

 END





GO
