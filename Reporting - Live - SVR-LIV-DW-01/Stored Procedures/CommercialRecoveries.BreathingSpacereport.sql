SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Max Taylor>
-- Create date: <20210519,>
-- Description:	<initial create  >
-- =============================================
CREATE  PROCEDURE [CommercialRecoveries].[BreathingSpacereport]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT 


  [Weightmans Ref] = dim_matter_header_current.master_client_code + '-' + master_matter_number
 ,[Client Reference] =  dim_client_involvement.client_reference 
 ,[Defendants Name] = COALESCE(defendant.contName,  matter_description COLLATE DATABASE_DEFAULT) 
 ,dim_matter_header_current.client_code
 ,dim_matter_header_current.matter_number
 ,[Matter Description] = matter_description
 ,[Client Name] = dim_matter_header_current.client_name
 ,ms_fileid
 , CASE WHEN dim_matter_header_current.client_name LIKE '%Alphabet%' THEN 'Alphabet'
      WHEN dim_matter_header_current.client_name LIKE '%Alphera%'  THEN 'Alphera'
	  WHEN dim_matter_header_current.client_name LIKE 'BMW%' THEN 'BMW'
	  WHEN dim_matter_header_current.client_name LIKE 'Mini%' THEN 'Mini'
	  WHEN dim_matter_header_current.client_name LIKE 'Motor Insurers%' THEN 'MIB'
 END AS GroupedClientName
 /*
 Then information from the Wizard which Jake Whewell designed:

·         Mental Health Crisis or Standard Breathing space’
·         Date commenced
·         Applied through Debt Management Agency or Local Authority
·         For 30 or 60 days (for standard only)
·         Condition suffered – for Mental Health Crisis only
·         Date ended – from the wizard
*/
,[Mental Health Crisis or Standard Breathing space] = cboBreathApply.cboBreathApply
,[Date commenced] = CAST(dteBreathCom AS DATE) 
,[Applied through Debt Management Agency or Local Authority] = cboAppOnDef.cboAppOnDef
,[For 30 or 60 days (for standard only)] = cboPeriodOT.cboPeriodOT
,[Condition suffered – for Mental Health Crisis only] = txtDefCondition
,[Date ended] = CAST(dteEnded AS DATE) 
,[What breathing space has been applied for?] = cboBreathApply.cboBreathApply
,[Who has applied on behalf of the Defendant?] = cboAppOnDef.cboAppOnDef
,[What condition is the Defendant suffering from?] =  txtDefCondition


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


LEFT JOIN ms_prod.dbo.udBreathingSpace
ON udBreathingSpace.fileid = ms_fileid


/*cboBreathApply  */ 

LEFT JOIN (SELECT DISTINCT cdCode, cdDesc AS cboBreathApply FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboBreathApply' AND txtMSTable = 'udBreathingSpace') cboBreathApply 
ON cboBreathApply.cdCode = udBreathingSpace.cboBreathApply 

/*cboAppOnDef  */ 

LEFT JOIN (SELECT DISTINCT cdCode, cdDesc AS cboAppOnDef FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboAppOnDef' AND txtMSTable = 'udBreathingSpace') cboAppOnDef 
ON cboAppOnDef.cdCode = udBreathingSpace.cboAppOnDef 

/*cboPeriodOT  */ 

LEFT JOIN (SELECT DISTINCT cdCode, cdDesc AS cboPeriodOT FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboPeriodOT' AND txtMSTable = 'udBreathingSpace') cboPeriodOT 
ON cboPeriodOT.cdCode = udBreathingSpace.cboPeriodOT 

WHERE 1 =1 



 AND (dim_matter_header_current.master_client_code IN ('FW22613', 'W15335', 'FW22135', 'FW23557',  'W20110'   )
 OR fact_dimension_main.master_client_code='M1001'
 
 )

 AND reporting_exclusions = 0

 AND dteBreathCom IS NOT NULL 

 ORDER BY 1, dim_matter_header_current.client_code, dim_matter_header_current.matter_number 

 END

 


GO
