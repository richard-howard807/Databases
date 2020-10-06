SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-10-06
-- Description:	Lancaster Uni Listing Report
-- =============================================
CREATE PROCEDURE [dbo].[Lanc_Uni_Listing]
AS

BEGIN

SET NOCOUNT ON;

SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number			AS [Reference]
	, dim_matter_header_current.matter_owner_full_name															AS [Weightmans Handler]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)									AS [Date Opened in MS]
	, dim_matter_header_current.matter_description																AS [Matter Description]
	, REVERSE(LEFT(REVERSE(CAST(RTRIM(dim_matter_header_current.matter_description) AS VARCHAR(255))),
		CHARINDEX(' ', REVERSE(CAST(RTRIM(dim_matter_header_current.matter_description) AS VARCHAR(255))))-1))	AS [Client Ref]												
	, CASE		
		WHEN LOWER(dim_matter_header_current.matter_description) LIKE '% :%' THEN
			RTRIM(LEFT(dim_matter_header_current.matter_description, CHARINDEX(' :', dim_matter_header_current.matter_description)))
		WHEN LOWER(dim_matter_header_current.matter_description) LIKE '% -%' THEN
			RTRIM(LEFT(dim_matter_header_current.matter_description, CHARINDEX(' -', dim_matter_header_current.matter_description)))
	  END																										AS [Student Name]
	, dim_detail_claim.phase																					AS [Phase]
	, dim_detail_claim.complaint_type																			AS [Complaint Type]
	, dim_detail_claim.collective_title																			AS [Collective Complaint Name]
	, dim_detail_claim.complaint_subject																		AS [Complaint Subject]
	, ISNULL(dim_detail_finance.output_wip_fee_arrangement, 'Fixed Fee/Fee Quote/Capped Fee')																AS [Fee Arrangement]
	, CASE	
		WHEN dim_detail_claim.date_offer_letter_sent_to_complainant IS NOT NULL THEN
			'Yes'
		ELSE
			NULL
	  END																			AS [Offer Email Sent]
	, dim_detail_claim.date_offer_letter_sent_to_complainant						AS [Date Offer Email Sent to Complainant]
	, fact_detail_claim.offer_amount												AS [Offer Amount]
	, DATEDIFF(DAY, dim_matter_header_current.date_opened_practice_management, GETDATE())		AS [Number of Days Open]
	, CASE
		WHEN dim_detail_claim.date_offer_letter_sent_to_complainant IS NOT NULL AND ((dim_detail_claim.offer_status IS NULL OR dim_detail_claim.offer_status <> 'Offer Accepted') OR dim_detail_claim.date_investigation_started IS NULL) THEN
			DATEDIFF(DAY, dim_detail_claim.date_offer_letter_sent_to_complainant, CAST(GETDATE() AS DATE))
		ELSE
			'-'
	  END																			AS [Days Since Offer Sent]
	, CASE		
		WHEN (dim_detail_claim.offer_status IS NULL OR dim_detail_claim.offer_status = 'No Response to Offer') THEN 
			'Yes'
		ELSE
			'No'
	  END																			AS [Awaiting a Response]
	, CASE 
		WHEN dim_detail_claim.offer_status = 'Offer Accepted' THEN
			'Yes'
		ELSE
			NULL
	  END																			AS [Positive Response Received]
	, CASE 
		WHEN dim_detail_claim.offer_status = 'Offer Refused' THEN
			'Yes'
		ELSE
			NULL
	  END																			AS [Negative Response Received]
	, fact_detail_claim.offer_amount												AS [Total Amount Offered]
	, dim_detail_claim.date_investigation_started									AS [Date Investigation Started]
	, CASE 
		WHEN dim_detail_claim.student_interview_date IS NOT NULL	THEN
			'Yes'
		ELSE 
			NULL
	  END																			AS [Student Interview Scheduled]
	, dim_detail_claim.student_interview_date										AS [Student Interview Date]
	, dim_detail_claim.student_interview_completed									AS [Student Interview Completed]
	, dim_detail_claim.notes_of_interview_confirmed_as_accurate_for_sudent			AS [Notes of Interview Confirmed as Accurate for Student]
	, dim_detail_claim.university_interview_required								AS [University Interview Required?]
	, CASE	
		WHEN dim_detail_claim.university_interview_date IS NOT NULL THEN
			'Yes'
		ELSE 
			NULL
	  END																			AS [University Interview Scheduled]
	, dim_detail_claim.university_interview_date									AS [University Interview Date]
	, dim_detail_claim.university_interview_completed								AS [University Interview Completed]
	, dim_detail_claim.notes_of_interview_confirmed_as_accurate_for_staff			AS [Notes of Interview Confirmed as Accurate for Staff]
	, CASE 
		WHEN dim_detail_claim.date_investigation_report_sent IS NOT NULL THEN
			'Yes'
		ELSE
			NULL
	  END																			AS [Investigation Report Completed]
	, dim_detail_claim.panel_date													AS [Panel Date]
	, dim_detail_claim.date_management_report_sent									AS [Management Report Date]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
		ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE
	dim_matter_header_current.master_client_code = '24221U'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_worktype.work_type_code = '1152'


END
GO
