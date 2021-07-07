SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Max Taylor>
-- Create date: <20210519,>
-- Description:	<initial create  >
-- =============================================
CREATE  PROCEDURE [CommercialRecoveries].[LDMS_MI]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT 


 [Weightmans Ref] = dim_matter_header_current.master_client_code + '-' + master_matter_number 
,[Defendant name] = COALESCE(defendant.contName,  matter_description COLLATE DATABASE_DEFAULT) 
,[Matter Description] = matter_description
,dim_matter_header_current.client_name
,[Agreement Number] =  dim_client_involvement.client_reference 
,[Date the wizard was run] = Wizard.dteInserted
,[Wizard Text] = Wizard.txtDescription
,ms_fileid
,Wizard.[bitUpdateLDMS]

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
						
						SELECT DISTINCT fileID, dteInserted, txtDescription, [bitUpdateLDMS] FROM MS_Prod.dbo.udCRHistoryNotesSL 
						
						WHERE [bitUpdateLDMS] = 1  ) Wizard ON Wizard.fileID = dbFile.fileID

					

WHERE 1 =1 


 
 AND dim_matter_header_current.master_client_code IN ('FW22613', 'W15335', 'FW22135')
 AND reporting_exclusions = 0



 ORDER BY 1, dim_matter_header_current.master_client_code, master_matter_number

 END

 


GO
