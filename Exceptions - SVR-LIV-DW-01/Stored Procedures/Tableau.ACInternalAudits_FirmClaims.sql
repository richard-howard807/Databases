SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
		    -- =============================================
-- Author:		Julie Loughlin
-- Create date: 2022-02-10
-- Description:	Data for Risk and Complaince to keep track of firm claim audits for dashboard
-- =============================================

CREATE PROCEDURE [Tableau].[ACInternalAudits_FirmClaims]
AS
BEGIN

SET NOCOUNT ON  
	
	--For testing purposes
	--DECLARE @DateFrom DATE = '20180501'
	--DECLARE @DateTo DATE = '20180831'

SELECT hierarchylevel2 AS Division, *
	
FROM
(

	SELECT 
         
		    
			COALESCE(RTRIM(SectionGroup),RTRIM(dim_detail_practice_area.[practice_area]),'Missing Department')  COLLATE DATABASE_DEFAULT AS [practice_area] ,
		    COALESCE(RTRIM(Section), RTRIM(dim_detail_practice_area.[weightmans_team]),'Missing Team') COLLATE DATABASE_DEFAULT AS [weightmans_team] ,
            dim_client.[client_code],
            dim_matter_header_current.[matter_number],
			dim_client.[client_code]+'-'+dim_matter_header_current.[matter_number] AS [Client/Matter Number],
            dim_matter_header_current.[matter_description],
            dim_detail_client.[office_where_claim_arose],
            dim_detail_client.[pa_where_claim_arose],
            dim_detail_practice_area.[bcm_name],
            dim_detail_practice_area.[better_supervision_made_a_difference],
			dim_fed_hierarchy_history.jobtitle AS JobLevelTitle,
			dim_fed_hierarchy_history.name, 
            dim_detail_practice_area.[case_managers_name],
            dim_detail_practice_area.[cause],
            dim_detail_practice_area.[date_closed],
            dim_detail_practice_area.[date_complaint_received],
            dim_detail_practice_area.[date_damages_paid],
            dim_detail_practice_area.[date_insurers_notified],
            dim_detail_practice_area.[disciplinary_action],
            dim_detail_practice_area.[formal_finding],
            dim_detail_practice_area.[internal_notification],
            dim_detail_practice_area.[leo_involved],
            dim_detail_practice_area.[original_clientmatter_number],
			a.fileID,
			fact_detail_cost_budgeting.costs_written_off_compliance,
			dim_detail_compliance.risk_comments,
			dim_detail_practice_area.[status_of_complaint],
            dim_detail_practice_area.[status_on_closure],
            dim_detail_practice_area.[office],
            dim_detail_practice_area.[who_received_complaint],
			date_closed_practice_management AS [matter_closed_practice_management_calendar_date],
            date_opened_practice_management AS [matter_opened_practice_management_calendar_date],
            fact_detail_client.[costs_paid],
            fact_detail_client.[costs_reserve],
            fact_detail_client.[damages_reserve_risk],
            isnull(fact_detail_paid_detail.[damages_paid_risk], 0) [DamagesNEW],
			dim_date.fin_quarter,
			dim_date.fin_quarter_no,
			dim_date.fin_year
        
           

            FROM red_dw.dbo.dim_matter_header_current
            INNER JOIN red_dw.dbo.dim_client
             ON dim_matter_header_current.client_code=dim_client.client_code

            INNER JOIN red_dw.dbo.dim_detail_practice_area
             ON dim_matter_header_current.client_code=dim_detail_practice_area.client_code
             AND dim_matter_header_current.matter_number=dim_detail_practice_area.matter_number

            LEFT OUTER JOIN red_dw.dbo.fact_detail_client
               ON dim_matter_header_current.client_code=fact_detail_client.client_code
             AND dim_matter_header_current.matter_number=fact_detail_client.matter_number
        
            LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
               ON dim_matter_header_current.client_code=fact_detail_paid_detail.client_code
             AND dim_matter_header_current.matter_number=fact_detail_paid_detail.matter_number     

			 left outer join  red_dw.dbo.fact_detail_cost_budgeting 
			 on fact_detail_cost_budgeting.matter_number = dim_matter_header_current.matter_number and 
			 fact_detail_cost_budgeting.client_code = dim_matter_header_current.client_code

			 LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance 
			 on dim_detail_compliance.matter_number = dim_matter_header_current.matter_number 
			 and dim_detail_compliance.client_code = dim_matter_header_current.client_code

			 LEFT OUTER JOIN red_dw.dbo.dim_date
			 ON CAST(dim_matter_header_current.date_opened_case_management AS date)=CAST(dim_date.calendar_date AS date)

			 LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK) 
            ON fed_code=fee_earner_code collate database_default
           AND dss_current_flag='Y'
         
            LEFT OUTER JOIN red_dw.dbo.dim_detail_client
               ON dim_matter_header_current.client_code=dim_detail_client.client_code
             AND dim_matter_header_current.matter_number=dim_detail_client.matter_number  
             LEFT OUTER JOIN(SELECT b.fileID
							,Section.Description  AS Section
							,SectionGroup.Description AS SectionGroup 
							 FROM MS_Prod.config.dbClient a
							 INNER JOIN MS_Prod.config.dbFile b ON b.clID = a.clID
							 LEFT JOIN MS_Prod.dbo.udMIPARisk c ON c.fileID = b.fileID
							 LEFT OUTER JOIN TE_3E_Prod.dbo.SectionGroup 
							 ON c.[cboPAClaimAros]=SectionGroup.Code COLLATE DATABASE_DEFAULT
							LEFT OUTER JOIN TE_3E_Prod.dbo.Section 
							 ON c.[cboWeighTeam]=Section.Code  COLLATE DATABASE_DEFAULT
							 WHERE a.clNo = '6930') AS a
  ON dim_matter_header_current.ms_fileid=a.fileID 

--LEFT OUTER JOIN (SELECT case_id,case_text AS FEDDivision FROM axxia01.dbo.casdet WHERE case_detail_code='RIS061') AS RIS061    
-- ON dim_matter_header_current.case_id=RIS061.case_id
--LEFT OUTER JOIN (SELECT case_id,case_text AS FEDDepartment FROM axxia01.dbo.casdet WHERE case_detail_code='RIS009') AS RIS009    
-- ON dim_matter_header_current.case_id=RIS009.case_id 
--LEFT OUTER JOIN (SELECT case_id,case_text AS FEDTeam FROM axxia01.dbo.casdet WHERE case_detail_code='RIS051') AS RIS051    
-- ON dim_matter_header_current.case_id=RIS051.case_id 
  
 
WHERE        dim_matter_header_current.[reporting_exclusions] = 0
 AND         dim_client.[client_code] = '00006930'             
  AND date_opened_practice_management  BETWEEN '20190501' AND GETDATE()
   AND COALESCE(RTRIM(SectionGroup),RTRIM(dim_detail_practice_area.[practice_area]),'Missing Department')  collate database_default<> 'Missing Department'
   AND  COALESCE(RTRIM(Section), RTRIM(dim_detail_practice_area.[weightmans_team]),'Missing Team') collate database_default <> 'Missing Team'
 
 -- AND dim_detail_practice_area.[practice_area] is not NULL
 --and dim_detail_practice_area.[weightmans_team] is not null 
      ) AS AllData
	        
LEFT OUTER JOIN (SELECT 
hierarchylevel2,hierarchylevel3 
 FROM red_dw..dim_fed_hierarchy_history
WHERE dss_current_flag='Y'
AND level=3
AND hierarchylevel2 <>'Unknown'
AND hierarchylevel2 IN ('Legal Ops - Claims','Legal Ops - LTA')
) AS Division
 ON 		[practice_area]= hierarchylevel3 

 END 
GO
