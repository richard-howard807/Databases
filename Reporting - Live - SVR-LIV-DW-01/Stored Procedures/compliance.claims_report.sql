SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 10/08/2018
-- Description:	This report was previously in DAX but some of the fields were not transferred to Mattersphere
--				in the same way when the files were converted.  
--				I am going to use sql to get around the issue by doing a coalesce to get the fed (artiion) value
--				if the field is blank (blank because of an issue with the warehouse).  
--				I will keep the dax dataset in the report so that
--				we can switch back to it when the issue is resolved
-- =============================================
-- Ticket #136643 - JB - added dim_date fields and variable to create subscription version of the report
-- =============================================
CREATE PROCEDURE [compliance].[claims_report]
	@DateFrom DATE 
	,@DateTo DATE 
AS
BEGIN
	
	 --For testing purposes
	--DECLARE @DateFrom DATE = (SELECT MIN(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.current_fin_year = 'Current')
	--DECLARE @DateTo DATE = (SELECT EOMONTH(DATEADD(MONTH, -1, CAST(GETDATE() AS DATE))))
    
	-- new variable for Claims Subscription report
	DECLARE @previous_month AS INT = (SELECT DISTINCT dim_date.fin_month FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = EOMONTH(DATEADD(MONTH, -1, CAST(GETDATE() AS DATE))))


	SELECT hierarchylevel2 AS Division, *
	
	FROM
	(


	SELECT 
         
		    
			COALESCE(RTRIM(SectionGroup),RTRIM(dim_detail_practice_area.[practice_area]),'Missing Department')  COLLATE DATABASE_DEFAULT AS [practice_area] ,
		    COALESCE(RTRIM(Section), RTRIM(dim_detail_practice_area.[weightmans_team]),'Missing Team') COLLATE DATABASE_DEFAULT AS [weightmans_team] ,
            dim_client.[client_code],
            dim_matter_header_current.[matter_number],
            dim_matter_header_current.[matter_description],
            dim_detail_client.[office_where_claim_arose],
            dim_detail_client.[pa_where_claim_arose],
            dim_detail_practice_area.[bcm_name],
            dim_detail_practice_area.[better_supervision_made_a_difference],
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
            FEDDivision,
            FEDDepartment,
            FEDTeam
           
		   , dim_date.fin_year
		   , dim_date.fin_month_no
		   , dim_date.fin_month
		   , IIF(dim_date.fin_month = @previous_month, 'Yes', 'No')	AS previous_month

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

LEFT OUTER JOIN (SELECT case_id,case_text AS FEDDivision FROM axxia01.dbo.casdet WHERE case_detail_code='RIS061') AS RIS061    
 ON dim_matter_header_current.case_id=RIS061.case_id
LEFT OUTER JOIN (SELECT case_id,case_text AS FEDDepartment FROM axxia01.dbo.casdet WHERE case_detail_code='RIS009') AS RIS009    
 ON dim_matter_header_current.case_id=RIS009.case_id 
LEFT OUTER JOIN (SELECT case_id,case_text AS FEDTeam FROM axxia01.dbo.casdet WHERE case_detail_code='RIS051') AS RIS051    
 ON dim_matter_header_current.case_id=RIS051.case_id 
  
INNER JOIN red_dw.dbo.dim_date
	ON dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_practice_management AS DATE)
             WHERE        dim_matter_header_current.[reporting_exclusions] = 0
 AND         dim_client.[client_code] = '00006930'             
  AND date_opened_practice_management BETWEEN @DateFrom AND @DateTo
   AND COALESCE(RTRIM(SectionGroup),RTRIM(dim_detail_practice_area.[practice_area]),'Missing Department')  collate database_default<> 'Missing Department'
   AND  COALESCE(RTRIM(Section), RTRIM(dim_detail_practice_area.[weightmans_team]),'Missing Team') collate database_default <> 'Missing Team'
 
 -- AND dim_detail_practice_area.[practice_area] is not NULL
 --and dim_detail_practice_area.[weightmans_team] is not null 
      ) AS AllData
	        
           LEFT OUTER JOIN (SELECT 
hierarchylevel2,hierarchylevel3 
 FROM red_dw.dbo.ds_sh_valid_hierarchy_x
WHERE dss_current_flag='Y'
AND level=3
AND hierarchylevel2 <>'Unknown'
AND hierarchylevel2 IN ('Legal Ops - Claims','Legal Ops - LTA')
) AS Division
 ON 		[practice_area]= hierarchylevel3 
END


GO
