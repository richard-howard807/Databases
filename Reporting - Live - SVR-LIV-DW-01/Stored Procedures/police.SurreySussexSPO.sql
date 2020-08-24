SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-21
-- Description:	#69137, Surrey and Sussex SPO report
-- =============================================
CREATE PROCEDURE [police].[SurreySussexSPO] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, matter_owner_full_name AS [Case Manager]
	, date_opened_case_management AS [Date Opened]
	, NULL AS [Niche Ref]
	, dim_detail_advice.[dvpo_victim_postcode] AS [Victim Postcode]
	, NULL AS [Perpetrator Postcode]
	, CASE WHEN dim_matter_header_current.master_client_code='451638' THEN dim_detail_claim.[borough] 
		WHEN dim_matter_header_current.master_client_code='113147' THEN dim_detail_claim.[district] 
		ELSE NULL END AS [Division]
	, curPerpAge AS [Perpetrator Age]
	, cboPerpGender AS [Perpetrator Gender]
	, cboPerpType AS [Perpetrator Type]
	, cboVictGender AS [Victim Gender]
	, curVictAge AS [Victim Age]
	, cboVictSuppApp AS [Victim Supports]
	, NULL AS [Application Contested]
	, cboInterApp AS [Interim Granted]
	, NULL AS [If Contested, Date of Next Hearing]
	, NULL AS [Full Order Granted]
	, NULL AS [Length of Order]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN (SELECT fileID
					, curPerpAge
					, red_dw.dbo.get_ms_code_lkup_val('GENDER',cboPerpGender) cboPerpGender
					, red_dw.dbo.get_ms_code_lkup_val('PERPTYPE',cboPerpType) cboPerpType
					, curVictAge
					, red_dw.dbo.get_ms_code_lkup_val('GENDER',cboVictGender) cboVictGender
					, red_dw.dbo.get_ms_code_lkup_val('VICTSUPPAP',cboVictSuppApp) cboVictSuppApp
					, red_dw.dbo.get_ms_code_lkup_val('INTERAPP',cboInterApp) cboInterApp
				 FROM MS_Prod.dbo.udMIPAPolice
				 LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
				 ON fileID=ms_fileid
				 WHERE dim_matter_header_current.master_client_code IN ('451638','113147')) AS [MSDetails] ON MSDetails.fileID=ms_fileid

WHERE dim_matter_header_current.master_client_code IN ('451638','113147')
AND work_type_name ='PL - Pol - Stalking Protection Order'
AND reporting_exclusions=0


END
GO
