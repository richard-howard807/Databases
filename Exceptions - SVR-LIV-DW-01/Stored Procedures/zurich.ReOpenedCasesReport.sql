SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		ste G
-- Create date: 11/01/2017
-- Description: Zurich Re-opened Cases Report for Magdalena Wloka   (Webby 285258 )
-- =============================================


CREATE PROCEDURE [zurich].[ReOpenedCasesReport]
	
	@StartDate DATE
	,@EndDate DATE
AS
BEGIN
	
	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    -- For Testing Purposes
	--DECLARE @StartDate Datetime
	--DECLARE @EndDate Datetime
	--SET @StartDate = '20200930'
	--SET @EndDate = '20201007'


	DROP TABLE IF EXISTS  [tempdb].dbo.#results;
	DROP TABLE IF EXISTS  [tempdb].dbo.#max_re_opened;


SELECT 
		dim_matter_header_current.ms_fileid
		
		,dim_detail_critical_mi.claim_status
		,date_reopened 
		,date_reopened_1
		,date_reopened_2
		,date_reopened_3
		,date_reopened_4
		,date_reopened_5
		,StatusChange.dss_start_date
		INTO #results
	FROM red_Dw.dbo.fact_dimension_main fdm
	LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
	INNER JOIN (SELECT DISTINCT client_code,matter_number,dss_start_date FROM red_Dw.dbo.dim_matter_claim_status_change WHERE dss_current_flag = 'Y'  ) StatusChange
		ON fdm.client_code = StatusChange.client_code
		AND fdm.matter_number = StatusChange.matter_number
	LEFT JOIN red_Dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = fdm.dim_detail_critical_mi_key 
	WHERE  dim_detail_critical_mi.claim_status = 'Re-opened'
	



	SELECT ms_fileid,  MAX(max_date_reopened)   date_reopened
	INTO #max_re_opened
FROM   
   (SELECT 		
   ms_fileid
		,try_CAST(date_reopened AS DATE) date_reopened
		,try_CAST(date_reopened_1 AS DATE) date_reopened_1
		,try_CAST(date_reopened_2 AS DATE) date_reopened_2
		,try_CAST(date_reopened_3 AS DATE) date_reopened_3
		,try_CAST(date_reopened_4 AS DATE) date_reopened_4
		,try_CAST(date_reopened_5 AS DATE) date_reopened_5
		,try_CAST(dss_start_date  AS DATE)  dss_start_date
   FROM #results) p  
UNPIVOT  
   (max_date_reopened FOR dates IN   
      (date_reopened, date_reopened_1, date_reopened_2, date_reopened_3, date_reopened_5,dss_start_date)  
)AS unpvt
GROUP BY ms_fileid

		SELECT 
		dim_matter_header_current.ms_fileid
		, 'Weightmans'		[Panel Firm]
		, zurichrsa_claim_number	[Zurich Reference]
		, RTRIM(fdm.client_code) +  '.' + CAST(CAST(fdm.matter_number AS INT)AS VARCHAR) [Panel Ref]
		, dim_client_involvement.insuredclient_name   [Insured]
		, claimant_name [Claimant Name]
		, date_instructions_received		[Date Instructed] 
		, date_claim_concluded			[Date Settled]
		, dim_detail_claim.reason_for_settlement		[Reason fo Settlement]
		, reason_for_reopening_request			[Reason for Reopening Request]
		, converge_disease_reserve			[Current Reserve]
		, dim_detail_critical_mi.claim_status
		,#max_re_opened.date_reopened [Reopen Date]
		,name AS [Case Handler]
	FROM red_Dw.dbo.fact_dimension_main fdm
	LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
	INNER JOIN #max_re_opened ON #max_re_opened.ms_fileid = dim_matter_header_current.ms_fileid AND  #max_re_opened.date_reopened  BETWEEN @StartDate AND @EndDate 
	left join red_Dw.dbo.dim_claimant_thirdparty_involvement on fdm.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
	left join red_dw.dbo.dim_client_involvement on fdm.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
	LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fdm.dim_detail_core_detail_key 
	LEFT JOIN red_Dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fdm.dim_detail_outcome_key
	LEFT JOIN red_Dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fdm.dim_detail_claim_key
	LEFT JOIN red_Dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fdm.master_fact_key
	LEFT JOIN red_Dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = fdm.dim_detail_critical_mi_key 
	LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
	LEFT JOIN red_Dw.dbo.dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = fdm.dim_detail_practice_ar_key
	LEFT JOIN red_Dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fdm.dim_detail_client_key
	WHERE 1=1 and
	-- standard exclusions for test cases and Money Laundering matters
		  (fdm.client_code IN ('Z00002','Z00004','Z00018','Z00014')
		OR (fdm.client_code = 'Z1001' and zurich_instruction_type IN ('Outsource - NIHL', 'Outsource - Coats', 'Outsource - HAVS')
		
		)
		)

		AND fdm.matter_number <> 'ML'

		AND fdm.client_code NOT IN ('00030645','95000C','00453737')  -- Need to exclude these clients in reports (Test clients)
		AND ISNULL(outcome_of_case,'') <> 'Exclude from reports'	
		AND dim_detail_critical_mi.claim_status = 'Re-opened'
		ORDER BY fdm.client_code,fdm.matter_number

		
END

GO
