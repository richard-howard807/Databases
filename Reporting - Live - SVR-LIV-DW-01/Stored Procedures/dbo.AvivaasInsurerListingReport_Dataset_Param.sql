SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AvivaasInsurerListingReport_Dataset_Param]
@StartDate AS DATE, @EndDate AS DATE

AS

/*Testing*/
--DECLARE 
--@StartDate AS DATE = GETDATE() -1000
--,@EndDate AS DATE = GETDATE()

/*Filters*/
DROP TABLE IF EXISTS #filterList
SELECT DISTINCT 
	 ms_fileid = CAST(ms_fileid AS VARCHAR(20))
	 INTO #filterList
	 FROM red_dw.dbo.dim_matter_header_current
	 JOIN red_dw.dbo.fact_dimension_main
	 ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	 JOIN red_dw.dbo.dim_client
	 ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
	 LEFT JOIN red_dw.dbo.dim_client_involvement
	 ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	 LEFT JOIN red_dw.dbo.dim_detail_core_details
	 ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	 LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
	 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	
	WHERE 1 =1 
	
          AND (LOWER(dim_client.[client_name]) LIKE '%aviva%'
          OR (LOWER(dim_client.[client_name]) LIKE '%bibby%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client_involvement.[insuredclient_name]) LIKE '%bibby%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client.[client_name]) LIKE '%veolia%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client_involvement.[insuredclient_name]) LIKE '%veolia%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client.[client_name]) LIKE '%green%king%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (LOWER(dim_client_involvement.[insuredclient_name]) LIKE '%green%king%' AND LOWER(dim_client_involvement.[insurerclient_name]) LIKE '%aviva%' )
          OR (dim_client.[client_name] LIKE '%menzies%' AND dim_client_involvement.[insurerclient_name] LIKE '%aviva%' )
          OR (dim_client_involvement.[insuredclient_name] LIKE '%menzies%' AND dim_client_involvement.[insurerclient_name] LIKE '%aviva%' )
		  /*Bring in matters under Client No 817628 (Smiths News) where ‘Does claimant have personal injury claim’ = Yes and Aviva is listed in the Associates section*/
          OR (
		  dim_matter_header_current.master_client_code = '817628' 
		  AND does_claimant_have_personal_injury_claim = 'Yes'
		  AND ms_fileid IN (SELECT DISTINCT fileID FROM MS_Prod.[config].[dbAssociates]LEFT JOIN MS_Prod.config.dbContact ON dbContact.contID = dbAssociates.contID WHERE assocHeading LIKE '%Aviva%' OR contName LIKE '%Aviva%' )
           ))
--Remove all matters closed before 1st Jan 2020
AND ISNULL(date_closed_case_management, GETDATE()) >= '2020-01-01'
--Remove any matters within Real Estate teams
AND hierarchylevel3hist <> 'Real Estate'

DROP TABLE IF EXISTS #t1
DROP TABLE IF EXISTS #Payornames

SELECT  
DISTINCT 
dim_matter_header_curr_key
,[payor_name] =Payor.DisplayName

INTO #t1
FROM  TE_3E_Prod.dbo.InvPayor  
JOIN TE_3E_Prod.dbo.InvMaster ON InvMaster.InvIndex = InvPayor.InvMaster
JOIN TE_3E_Prod.dbo.Matter ON Matter.MattIndex = InvMaster.LeadMatter
JOIN TE_3E_Prod.dbo.Client ON Client.ClientIndex = Matter.Client
JOIN TE_3E_Prod.dbo.Payor ON Payor.PayorIndex = InvPayor.Payor
JOIN red_dw.dbo.dim_matter_header_current  ON master_client_code + '-' + master_matter_number = Matter.Number COLLATE DATABASE_DEFAULT
WHERE ms_fileid IN (SELECT ms_fileid FROM #filterList)

SELECT 

dim_matter_header_curr_key, 

[payor_name] = STUFF(
             (SELECT ',' + [payor_name] 
              FROM #t1 t1
              WHERE t1.dim_matter_header_curr_key = t2.dim_matter_header_curr_key
              FOR XML PATH (''))
             , 1, 1, '') 
INTO #Payornames
			 FROM #t1 t2
group by dim_matter_header_curr_key;



SELECT 
     distinct  
	 ms_fileid
FROM red_dw..fact_dimension_main
LEFT JOIN red_dw..fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw..dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw..dim_matter_branch ON   dim_matter_branch.branch_code = dim_matter_header_current.branch_code
LEFT JOIN red_dw..dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_dw..dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key	  
LEFT JOIN red_dw..dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw..dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key	
LEFT JOIN red_dw..dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key	
LEFT JOIN red_dw..dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key	
LEFT JOIN red_dw..fact_detail_paid_detail ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_detail_core_details.dim_matter_header_curr_key	
LEFT JOIN red_dw..fact_detail_claim ON fact_detail_claim.dim_matter_header_curr_key = dim_detail_core_details.dim_matter_header_curr_key	

LEFT JOIN (
SELECT DISTINCT fileID FROM MS_Prod.[config].[dbAssociates]
LEFT JOIN MS_Prod.config.dbContact ON dbContact.contID = dbAssociates.contID
WHERE assocHeading LIKE '%Aviva%' OR contName LIKE '%Aviva%'
) AssociateAviva ON AssociateAviva.fileID = ms_fileid


LEFT JOIN #Payornames ON #Payornames.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	     
WHERE ms_fileid

IN (SELECT ms_fileid FROM #filterList)

 AND CAST(date_opened_case_management AS DATE )
 BETWEEN @StartDate AND @EndDate
 
GO
