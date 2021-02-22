SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 2019/07/11
-- Description:	Co-op Audit fields:  New table not in the warehouse yet so this is a temp / stopgap measure until the new process is created

-- =============================================
CREATE PROCEDURE [dbo].[coop_audit_report]


(
@StartDate AS DATE
,@EndDate AS DATE
)

AS

	SET NOCOUNT ON;
	SELECT DISTINCT
		 
		 header.master_client_code
		,header.master_matter_number
		,header.matter_description
		,header.matter_owner_full_name
		,CASE WHEN red_dw.dbo.dim_detail_outcome.date_claim_concluded IS NOT NULL THEN 1 ELSE 0 END AS concluded
		,CASE WHEN cboBillRateAp = 'Y' THEN 'Yes' WHEN cboBillRateAp = 'N' THEN 'No' END 		[bill_rate_approp]
		,CASE WHEN cboSetStratCon = 'Y' THEN 'Yes' WHEN	cboSetStratCon = 'N' THEN 'No' END	[sett_strategy_consid]
		,CASE WHEN cboIndemAdv = 'Y' THEN 'Yes' WHEN	cboIndemAdv = 'N' THEN 'No' END	[indemnity_advice]	
		,CASE WHEN cboLiabAdv	= 'Y' THEN 'Yes' WHEN cboLiabAdv	= 'N' THEN 'No' END	[liability_advice]
		,CASE WHEN cboQuantAdv = 'Y' THEN 'Yes' WHEN	cboQuantAdv	= 'N' THEN 'No' END[quantum_advice]
		,CASE WHEN cboAppConSetOf = 'YES' THEN 'Yes' WHEN	cboAppConSetOf	= 'NO' THEN 'No' WHEN cboAppConSetOf = 'NA' THEN 'N/A' END [approp_consideration_settlement_offer]
		,CASE WHEN cboAppUseCoun = 'YES' THEN 'Yes' WHEN	cboAppUseCoun	= 'NO' THEN 'No' WHEN cboAppUseCoun = 'NA' THEN 'N/A' END [approp_use_counsel]
		,CASE WHEN cboTSDApp = 'Y' THEN 'Yes' WHEN	cboTSDApp		= 'N' THEN 'No' END [tsd_approp]
		,CASE WHEN cboFurthRevReq = 'YES' THEN 'Yes' WHEN	cboFurthRevReq	= 'NO' THEN 'No' WHEN cboFurthRevReq = 'NA' THEN 'N/A'  END [further_review_req]
		,CASE WHEN cboSettAppro = 'YES' THEN 'Yes' WHEN	cboSettAppro	= 'NO' THEN 'No' WHEN cboSettAppro = 'NA' THEN 'N/A'  END [settlement_approp]
		,CASE WHEN cboAck2CalDay = 'Y' THEN 'Yes' WHEN	cboAck2CalDay	= 'N' THEN 'No' END [ack_two_calendar_days]
		,CASE WHEN cboInitRep10Day = 'Y' THEN 'Yes' WHEN cboInitRep10Day	= 'N' THEN 'No' END [init_report_ten_work_days]
		,CASE WHEN cboExtTimeAgr = 'Y' THEN 'Yes' WHEN	cboExtTimeAgr	= 'N' THEN 'No' END [extended_time_agreed]
		,CASE WHEN cboInvestInstr = 'Y' THEN 'Yes' WHEN	cboInvestInstr	= 'N' THEN 'No' END [investigators_instructed]
		,CASE WHEN cboAcPlaSntInRe = 'Y' THEN 'Yes' WHEN cboAcPlaSntInRe	= 'N' THEN 'No' END [action_plan_sent_init]
		,CASE WHEN cboCaPlaSntInRe = 'Y' THEN 'Yes' WHEN	cboCaPlaSntInRe = 'N' THEN 'No' END [case_plan_sent_init]
		,CASE WHEN cboEstCaSntInRe = 'Y' THEN 'Yes' WHEN cboEstCaSntInRe	= 'N' THEN 'No' END [est_calcs_sent_init]
		,CASE WHEN cboActPlaSntLQ = 'YES' THEN 'Yes' WHEN	cboActPlaSntLQ	= 'NO' THEN 'No' WHEN cboActPlaSntLQ = 'NA' THEN 'N/A'  END [action_plan_sent_qtr]
		,CASE WHEN cboCaPlaSntLQ = 'YES' THEN 'Yes' WHEN	cboCaPlaSntLQ	= 'NO' THEN 'No' WHEN cboCaPlaSntLQ = 'NA' THEN 'N/A'  END [case_plan_sent_qtr]
		,CASE WHEN cboBillSumLQ	= 'YES' THEN 'Yes' WHEN	cboBillSumLQ = 'NO' THEN 'No' WHEN cboBillSumLQ = 'NA' THEN 'N/A'  END [bill_summary_qtr]
		,CASE WHEN cboKeyDatesInp = 'Y' THEN 'Yes' WHEN	cboKeyDatesInp = 'N' THEN 'No' END 	[key_dates_input]
		,CASE WHEN cboResAccRec = 'Y' THEN 'Yes' WHEN	cboResAccRec = 'N' THEN 'No' END 	[reserves_accurate]
		,CASE WHEN cboClaimRegCRU = 'YES' THEN 'Yes' WHEN cboClaimRegCRU	= 'NO' THEN 'No' WHEN cboClaimRegCRU = 'NA' THEN 'N/A' END 	[claim_reg_cru]
		,CASE WHEN cboSettMIComp = 'YES' THEN 'Yes' WHEN	cboSettMIComp = 'NO' THEN 'No' WHEN cboSettMIComp = 'NA' THEN 'N/A' END 	[settlement_mi_complete]
		,CASE WHEN cboDisbSSUsed = 'Y' THEN 'Yes' WHEN cboDisbSSUsed	= 'N' THEN 'No' END 	[disbs_spreadsheet_used]
		,CASE WHEN cboSetInTSD = 'YES' THEN 'Yes' WHEN	cboSetInTSD = 'NO' THEN 'No' WHEN cboSetInTSD = 'NA' THEN 'N/A' END 	[settled_within_tsd]
		,CASE WHEN cboSetReTSD = 'YES' THEN 'Yes' WHEN	cboSetReTSD = 'NO' THEN 'No' WHEN cboSetReTSD = 'NA' THEN 'N/A' END 	[settled_within_revised_tsd]
		,udCoopAudit.dteAuditCoop AS [Date of Strategic Review/Quality Audit]
		,udCoopAudit.dteCPAudit AS [Date of Client Process Manager Audit]
		,instruction_type
	FROM MS_PROD.dbo.udCoopAudit udCoopAudit
	INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.ms_fileid = udCoopAudit.fileID
	INNER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = header.client_code AND dim_detail_outcome.matter_number = header.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_instruction_type
	 ON dim_instruction_type.dim_instruction_type_key = header.dim_instruction_type_key
	WHERE ((dteAuditCoop >= @StartDate OR @StartDate IS NULL) 
	AND  dteAuditCoop<=  @EndDate  OR @EndDate IS NULL) 
	AND dteAuditCoop IS NOT NULL
	AND header.reporting_exclusions=0

GO
