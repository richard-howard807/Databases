SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-03-12
-- Description: #91818 New report request for client Riverside
-- =============================================
*/

CREATE PROCEDURE [dbo].[riverside_monthly_report]

AS

BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	CASE 
		WHEN dim_matter_header_current.date_closed_practice_management IS NULL THEN
			'Open'
		ELSE
			'Closed'
	END							AS [Open or Closed]
	, dim_detail_client.instructing_officer			AS [TRGL Instructing Officer]
	, dim_client_involvement.client_reference			AS [Purchase Order No.]
	, dim_matter_header_current.matter_owner_full_name			AS [Instructed Solicitor]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number		AS [Panel Case Reference Number]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
	, dim_matter_header_current.matter_description			AS [Claimants Details]
	, CASE
		WHEN te_3e_disb.Description = 'Experts' OR te_3e_disb.Description = 'Experts (no VAT)' THEN
			te_3e_disb.disb_value
		ELSE 
			0
	  END				AS [Surveyor Fees]
	, CASE
		WHEN dim_detail_property.disrepair_outcome IS NULL THEN	
			'N'
		ELSE
			'Y'
	  END						AS [Settled]
	, ms_data.cboLiabAdmitted				AS [Liability Denied]
	, ms_data.cboIssueProc				AS [Litigated]
	, CASE
		WHEN LTRIM(RTRIM(LOWER(te_3e_disb.Description))) = 'court fees' THEN
			te_3e_disb.disb_value
		ELSE 
			0
	  END						AS [Court Fees]
	, CASE
		WHEN LOWER(te_3e_disb.Description) LIKE '%counsel%' THEN
			te_3e_disb.disb_value
		ELSE 
			0
	  END					AS [Counsel Fees]
	, ms_data.curDamages				AS [Damages Paid]
	, ms_data.curRevEstimate			AS [Panel Fees Agreed]
	, fact_finance_summary.wip			AS [WIP Outstanding]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.defence_costs_vat, 0)	AS [Panel Fees to Date (Incl. VAT)]
	, fact_detail_property.amount_claimed_tenant				AS [3rd Party Solicitor Fees Claimed (Incl. VAT)]
	, fact_detail_property.tenants_solicitors_costs				AS [3rd Party Solicitor Fees Paid (Incl. VAT)]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)			AS [Case Closed Date]
	, dim_detail_property.status_comment			AS [Reason Case Length Exceeds 6 Months]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_property
		ON dim_detail_property.client_code = dim_detail_client.client_code
			AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_property
		ON fact_detail_property.client_code = dim_matter_header_current.client_code 
			AND fact_detail_property.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN (
						SELECT 
							dbFile.fileID
							, udMICoreGeneral.curRevEstimate
							, udRealEstate.cboIssueProc
							, udRealEstate.cboLiabAdmitted
							, udRealEstate.curDamages
						FROM MS_Prod.config.dbFile
							INNER JOIN MS_Prod.config.dbClient
								ON dbClient.clID = dbFile.clID
							LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneral
								ON udMICoreGeneral.fileID = dbFile.fileID
							LEFT OUTER JOIN MS_Prod.[dbo].[udRealEstate]
								ON dbFile.fileID = [udRealEstate].fileID
						WHERE 1 = 1
							AND dbClient.clNo = 'W15603'
					) AS ms_data
		ON ms_data.fileID = dim_matter_header_current.ms_fileid
	LEFT OUTER JOIN (
						SELECT DISTINCT
							Matter.Number
							, CostType.Description
							, SUM(CostCard.WorkAmt)		AS disb_value	
						FROM TE_3E_Prod.dbo.Matter WITH (NOLOCK)
							INNER JOIN red_dw.dbo.dim_matter_header_current 
								ON dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number  = Matter.Number COLLATE DATABASE_DEFAULT 
							INNER JOIN red_dw.dbo.dim_matter_worktype
								ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
							INNER JOIN TE_3E_Prod.dbo.CostCard WITH (NOLOCK)
								ON Matter.MattIndex = CostCard.Matter
							INNER JOIN TE_3E_Prod.dbo.CostType WITH (NOLOCK)
								ON CostType.Code = CostCard.CostType
							INNER JOIN TE_3E_Prod.dbo.Voucher WITH (NOLOCK)
								ON Voucher.VchrIndex = CostCard.Voucher
						WHERE 1 = 1
							AND dim_matter_header_current.master_client_code = 'W15603'
							AND dim_matter_worktype.work_type_code = '1150'
						GROUP BY
							Matter.Number
							, CostType.Description
					) AS te_3e_disb
			ON te_3e_disb.Number COLLATE DATABASE_DEFAULT = dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'W15603'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_worktype.work_type_code = '1150'
ORDER BY
	[Date Opened]

END

GO