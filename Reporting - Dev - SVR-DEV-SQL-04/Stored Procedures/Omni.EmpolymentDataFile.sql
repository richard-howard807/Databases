SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Employment Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[EmpolymentDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT  
        RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]	
		, fact_dimension_main.[client_code] AS [Client Code]
		, fact_dimension_main.[matter_number] AS [Matter Number]
		, dim_client.client_name AS [Client Name]
		, dim_detail_advice.[knowledge_gap] AS [Knowledge Gap]
		, dim_detail_advice.[summary_of_advice] AS [Summary of Advice]
		, dim_detail_advice.[workplace_postcode] AS [Workplace Postcode]
		, dim_detail_advice.[brief_description] AS [Brief Description]
		, dim_detail_advice.[category_of_advice] AS [Category of Advice]
		, dim_detail_advice.[diversity_issue] AS [Diversity Issue]
		, dim_detail_advice.[employment_start_date] AS [Employment Start Date]
		, dim_detail_advice.[greene_king_outcome] AS [Greene King Outcome]
		, dim_detail_advice.[job_title_of_caller_emp] AS [Job Title of Caller Employee]
		, dim_detail_advice.[job_title_of_caller_gk] AS [Job Title of Caller Gk]
		, dim_detail_advice.[job_title_of_caller_tgipe] AS [Job Title of Caller]
		, dim_detail_advice.[job_title_of_employee] AS [Job Title of Employee]
		, dim_detail_advice.[name_of_caller] AS [Name of Caller]
		, dim_detail_advice.[name_of_employee] AS [Name of Employee]
		, dim_detail_advice.[outcome] AS Outcome
		, dim_detail_advice.[outcome_pe] AS [Outcome Pe]
		, dim_detail_advice.[policy_issue] AS [Policy Issue]
		, dim_detail_advice.[region] AS Region
		, dim_detail_advice.[risk] AS Risk
		, dim_detail_advice.[secondary_issue] AS [Secondary Issue]
		, dim_detail_advice.[site] AS [Site]
		, dim_detail_advice.[site_gk] AS [Site gk]
		, dim_detail_advice.[site_sv] AS [Site sv]
		, dim_detail_advice.[status] AS [Status_Advice]
		, dim_detail_advice.[client] AS [Client]
		, dim_detail_advice.[summary_of_advice] AS [Summary of Advice]
		, dim_detail_advice.[tgif_classification] AS [TGIF Classifications]
		, dim_detail_advice.[whitbread_call_generated] AS [Whitbread Call Generated]
		, dim_detail_advice.[whitbread_caller_job_title] AS [Whitbread Caller Job Title]
		, dim_detail_advice.[whitbread_caller_location] AS [Whitbread Caller Location]
		, dim_detail_advice.[whitbread_caller_team] AS [Whitbread Caller Team]
		, dim_detail_advice.[whitbread_employee_job_title] AS [Whitbread Job Title]
		, dim_detail_advice.[whitbread_employee_location] AS [Whitbread Employee Location]
		, dim_detail_advice.[whitbread_employee_team] AS [Whitbread Team]
		, dim_detail_advice.[whitbread_number_of_contacts] AS [Whitbread Number of Contacts]
		, dim_detail_advice.[whitbread_weightmans_attendance_as_employee_meetings] AS [Whitbread Attendance at Employee Meetings]
		, dim_detail_advice.[workplace_postcode] AS [Workplace Postcode]
		, dim_detail_claim.[comments] AS Comments
		, dim_detail_claim.[work_referrer_identity] AS [Work Referrer Identity]
		, dim_detail_claim.[work_referrer_type] AS [Work Referrer Type]
		, dim_detail_claim.[work_referral_recipient] AS [Work Referral Recipient]
		, dim_detail_client.[emp_rmg_sensitive_case] AS [Emp Rmg Sensitive Case]
		, dim_detail_core_details.[consortium_instruction] AS [Consortium instruction?]
		, dim_detail_core_details.[date_initial_estimate_retainer] AS [Date of initial estimate to complete retainer]
		, dim_detail_core_details.[date_of_current_estimate_to_complete_retainer] AS [Date of current estimate to complete retainer]
		, dim_detail_core_details.[name_of_consortium] AS [Name of Consortium]
		, dim_detail_core_details.[emp_litigatednonlitigated] AS [Contentious/non-contentious]
		, dim_detail_court.[emp_date_of_final_hearing] AS [Date of final hearing]
		, dim_detail_court.[emp_date_of_preliminary_hearing_case_management] AS [Date of Preliminary Hearing (case management)]
		, dim_detail_court.[emp_date_of_preliminary_hearing_jurisdictionprospects] AS [Date of Preliminary Hearing (jurisdiction/prospects)]
		, dim_detail_court.[length_of_hearing] AS [Length of Hearing]
		, dim_detail_court.[location_of_hearing] AS [Location of Hearing]
		, dim_detail_practice_area.[date_et3_due] AS [Date ET3 due]
		, dim_detail_practice_area.[date_remedy_hearing] AS [Date of Remedy Hearing]
		, dim_detail_practice_area.[emp_claimant_represented] AS [Claimant Represented?]
		, dim_detail_practice_area.[emp_outcome] AS [Outcome - Employment]
		, dim_detail_practice_area.[emp_present_position] AS [Present Position - Employment]
		, dim_detail_practice_area.[emp_prospects_of_success] AS [Prospects of Success]
		, dim_detail_practice_area.[emp_stage_of_outcome] AS [Stage of Outcome]
		, dim_detail_property.[emls_work_category] AS [EMLS Work Category]
		, fact_detail_paid_detail.[actual_compensation] AS [ET Compensation Paid]
		, fact_detail_reserve_detail.[potential_compensation] AS [Potential Compensation/Pension Loss]
		, pc.Postcode AS AirportPostcodes
		, CaseClassification.[Classification Description] AS CaseClassificationDescription
		, dim_detail_client.whitbread_rom AS [Whitbread ROM]
		, dim_detail_client.whitbread_rdm AS [Whitbread RDM]
		, dim_detail_advice.site_gk AS Site_Employment
		, dim_site_address.postcode AS WhitbreadPostCode
		, dim_site_address.street
		, dim_site_address.locality
		, dim_site_address.town
		, dim_site_address.area
		, dim_detail_core_details.[under_annual_retainer] AS [Are you acting under an annual retainer?]
		, dim_court_involvement.[tribunal_name] AS [Tribunal Name]
		, dim_detail_advice.[emph_primary_issue] AS [Emp Primary Issue]
		, dim_detail_advice.[emph_secondary_issue] AS [Emp Secondary Issue]
		, COALESCE(dim_detail_advice.name_of_caller,dim_detail_advice.name_of_caller) AS [Name of caller]
		, dim_detail_property.[commercial_bl_status] AS [Reservation Status]
		, CASE WHEN dim_detail_core_details.[emp_litigatednonlitigated]  IN ('Contentious','Litigated') THEN 'Tribunal'
	        WHEN dim_detail_core_details.[emp_litigatednonlitigated]  IN ( 'Non-contentious','Non contentious','Non-litigated') THEN 'Advisory'
	        ELSE dim_detail_core_details.[emp_litigatednonlitigated]  END AS [Type of Work]
		, CASE WHEN dim_detail_advice.site_sv='Dublin'  THEN 53.426080000000000000 
			 WHEN dim_detail_advice.site_sv='Shannon' THEN 52.692810700000000000  
			 WHEN dim_detail_advice.site_sv='Cork'    THEN 51.848915700000000000
			 WHEN dim_detail_advice.site_sv='Belfast City'    THEN 54.661663300000000000
			 END AS Latitude2 
		, CASE WHEN dim_detail_advice.site_sv='Dublin' THEN -6.239119999999957000 
			 WHEN dim_detail_advice.site_sv='Shannon'THEN -8.921404199999983000
			 WHEN dim_detail_advice.site_sv='Cork'   THEN -8.489205099999936000
			 WHEN dim_detail_advice.site_sv='Belfast City'    THEN -6.216597999999976000  
			 END AS Longitude2
		, CASE WHEN   dim_detail_advice.issue like 'Conduct%' THEN 'Conduct Issue' ELSE '' END AS ConductIssue   
		, CASE WHEN dim_detail_advice.outcome IS NULL THEN 'Ongoing' ELSE dim_detail_advice.outcome END AS [Outcome]     
		, CASE WHEN dim_detail_advice.status IS NULL THEN 'Ongoing' ELSE dim_detail_advice.status END  AS [Status - Empolyment]    
		, CASE WHEN datename(dw,dim_matter_header_current.date_opened_case_management)='Monday' THEN 1
			WHEN datename(dw,dim_detail_core_details.date_instructions_received)='Tuesday' THEN 2
			WHEN datename(dw,dim_detail_core_details.date_instructions_received)='Wednesday' THEN 3
			WHEN datename(dw,dim_detail_core_details.date_instructions_received)='Thursday' THEN 4
			WHEN datename(dw,dim_detail_core_details.date_instructions_received)='Friday' THEN 5
			WHEN datename(dw,dim_detail_core_details.date_instructions_received)='Saturday' THEN 6
			WHEN datename(dw,dim_detail_core_details.date_instructions_received)='Sunday' THEN 7 
			END AS DayNumber
		, CASE WHEN dim_detail_advice.status='Closed' THEN 'Concluded' ELSE 'Ongoing' END AS ClaimStatus
		, CASE	when datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE()) THEN 1	  -- current may to dec
		        when datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) > Datepart(yyyy,GETDATE()) THEN 1	  -- current jan to apr
				when datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE()) THEN 2	  -- historic -1	
				when datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-1 THEN 2  -- historic -1
				when datepart(mm,dim_matter_header_current.date_opened_case_management) < 5 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-1 THEN 3  -- historic -2	
				when datepart(mm,dim_matter_header_current.date_opened_case_management) > 4 AND Datepart(yyyy,dim_matter_header_current.date_opened_case_management) = Datepart(yyyy,GETDATE())-2 THEN 3  -- historic -2
		  ELSE 4
		  end [Period Type - TGIF]

		, CAST((CASE WHEN MONTH(dim_matter_header_current.date_opened_case_management) >= 3 THEN CAST(YEAR(dim_matter_header_current.date_opened_case_management) as varchar) + '/' + CAST((YEAR(dim_matter_header_current.date_opened_case_management) + 1) AS varchar)
                 ELSE CAST((YEAR(dim_matter_header_current.date_opened_case_management) - 1) AS VARCHAR) + '/' + CAST(YEAR(dim_matter_header_current.date_opened_case_management) AS VARCHAR) 
                   END) AS VARCHAR) [Financial Year - Whitbread]
		, CASE WHEN Omni.TGIPostcodes.Region IS NULL THEN 'TBA' ELSE Omni.TGIPostcodes.Region END AS [Region - TGIF]
		, CASE WHEN Omni.TGIPostcodes.Team IS NULL THEN 'TBA' ELSE Omni.TGIPostcodes.Team END AS [Team - TGIF] 
		, Omni.TGIPostcodes.Postcode AS [Postcode - TGIF] 


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key=fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement ON red_dw.dbo.dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_site_address ON dim_site_address.client_code=dim_detail_client.client_code AND dim_site_address.matter_number=dim_detail_client.matter_number
LEFT OUTER JOIN (SELECT * FROM Omni.ServisairClassificatons ) AS CaseClassification
ON dim_detail_client.case_type_classification=CaseClassification.[Classification Code] collate database_default
LEFT OUTER JOIN (SELECT * FROM Omni.sairPostcodes) AS pc
ON dim_detail_advice.site_sv=PC.Airport collate database_default
LEFT OUTER JOIN Omni.TGIPostcodes ON RTRIM(Branch)=RTRIM(CASE WHEN dim_matter_header_current.matter_number IN('00000681','00000867','00000944','00000957','00000810') THEN 'Norwich' ELSE dim_detail_advice.[site] END) collate database_default
--LEFT OUTER JOIN (
--SELECT tt_client,tt_matter,Sum(tt_numins) AS TimeRecorded
--               FROM red_dw_replication.dbo.catimtrn
--               WHERE tt_client IN('W00012')
--               AND tt_numins >0
--               AND tt_bilnum <> 'xxxxxxxx'
--               GROUP BY tt_client,tt_matter
--         ) AS tr
--ON dbo.fact_dimension_main.client_code=tr_client AND  dbo.fact_dimension_main.matter_code=tr_matter -- this is for [Time recorded on file]



WHERE 
ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.matter_number<>'ML'
AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)


END

GO
