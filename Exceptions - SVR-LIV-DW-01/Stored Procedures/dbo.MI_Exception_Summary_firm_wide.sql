SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		sgrego	
-- Create date: 2018-10-10
-- Description:	Took the code out of the report and put it into a sp
-- =============================================
-- 20190424 LD Amended so that people with leaver dates in the future still appear on the report.


CREATE PROCEDURE [dbo].[MI_Exception_Summary_firm_wide]
(
@FeeEarners AS NVARCHAR(MAX)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @nDate AS DATE = GETDATE()

--For testing purposes
--DECLARE @FeeEarners AS NVARCHAR(max) = '3480,5270,5529,5265'
DROP TABLE  IF EXISTS #tempfeearners

CREATE TABLE #tempfeearners  (
employeeid  NVARCHAR(MAX)
)
 
DECLARE @sql NVARCHAR(MAX)

SET @sql = '
use red_dw;
DECLARE @nDate AS DATE = GETDATE()

SELECT DISTINCT
dim_fed_hierarchy_history.employeeid
FROM red_Dw.dbo.dim_fed_hierarchy_history 
INNER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key AND (leaverlastworkdate IS NULL OR leaverlastworkdate > @nDate)
WHERE dim_fed_hierarchy_history_key IN ('+@FeeEarners+')'

INSERT into #tempfeearners 
exec sp_executesql @sql




SELECT dim_fed_hierarchy_history.employeeid,
		CASE WHEN date_closed_case_management IS NULL THEN 0 ELSE 1 END open_closed,
       --COUNT(dim_matter_header_current.case_id) cases
	   COUNT(dim_matter_header_current.ms_fileid) cases
INTO #critria_cases
FROM red_dw.dbo.fact_dimension_main
    LEFT JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.dim_detail_core_details
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
    LEFT JOIN red_dw.dbo.dim_detail_outcome
        ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code and dim_fed_hierarchy_history.dss_current_flag = 'Y'
	LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE fact_dimension_main.client_code <> 'ml'
      AND 1 = 1
    and  referral_reason LIKE 'Dispute%' AND 
(
	date_claim_concluded IS NULL  OR 
	date_claim_concluded >= CAST(CAST(YEAR(DATEADD(YEAR, -3, GETDATE())) AS NVARCHAR(4)) + '-01-01' AS DATE)  
)  AND 
dim_matter_header_current.reporting_exclusions = 0    AND 
LOWER(ISNULL(outcome_of_case, '')) NOT in ('exclude from reports','returned to client')  AND 
(
	date_closed_case_management >= CAST(CAST(YEAR(DATEADD(YEAR, -3, GETDATE())) AS NVARCHAR(4)) + '-01-01' AS DATE) OR date_closed_case_management IS NULL
)       
AND 
employeeid NOT IN 
('D7FCD8D2-A936-472A-8CEB-1BCBECFF65B9','49452DCE-A032-42C2-B328-AFCFE1079561','A7C4010A-8F29-4058-A11E-220C5461036F') AND 
(
	dim_matter_header_current.ms_only = 1  

)
AND hierarchylevel2hist = 'Legal Ops - Claims' AND work_type_code NOT IN ('0032', '1597')

GROUP BY dim_fed_hierarchy_history.employeeid,date_closed_case_management




SELECT hir.employeeid,
       hir.hierarchylevel2hist buisnessline,
       hir.hierarchylevel3hist PracticeArea,
       hir.hierarchylevel4hist team,
       hir.name,
       hir.fed_code,
       hir.windowsusername,
       ---------------------------------open------------------------------------------------------------
       SUM(   CASE
                  WHEN closed = 0 THEN
                      no_of_cases
                  ELSE
                      0
              END
          ) no_of_open_cases_with_exceptions,
       SUM(   CASE
                  WHEN closed = 0 THEN
                      no_of_exceptions
                  ELSE
                      0
              END
          ) no_of_open_exceptions,
       SUM(   CASE
                  WHEN closed = 0 THEN
                      ISNULL(cases.cases, 0)
                  ELSE
                      0
              END
          ) total_open_cases,

       -------------------------------closed------------------------------------------------------------
       SUM(   CASE
                  WHEN closed = 1 THEN
                      no_of_cases
                  ELSE
                      0
              END
          ) no_of_closed_cases_with_exceptions,
       SUM(   CASE
                  WHEN closed = 1 THEN
                      no_of_exceptions
                  ELSE
                      0
              END
          ) no_of_closed_exceptions,
       SUM(   CASE
                  WHEN closed = 1 THEN
                      ISNULL(cases_closed.cases, 0)
                  ELSE
                      0
              END
          ) total_closed_cases,

       ---------------------------------all------------------------------------------------------
       SUM(no_of_cases) no_of_cases_with_exceptions,
       SUM(no_of_exceptions) no_of_exceptions,
       SUM(   CASE
                  WHEN closed = 1 THEN
                      ISNULL(cases_closed.cases, 0)
                  ELSE
                      0
              END
          ) + SUM(   CASE
                         WHEN closed = 0 THEN
                             ISNULL(cases.cases, 0)
                         ELSE
                             0
                     END
                 ) total_cases
INTO #results
FROM Exceptions.dbo.MI_Management_firm_wide
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history hir
        ON MI_Management_firm_wide.employeeid = hir.employeeid
           AND hir.dss_current_flag = 'Y'
           AND hir.activeud = 1
    INNER JOIN #tempfeearners
    	ON #tempfeearners.employeeid COLLATE DATABASE_DEFAULT = hir.employeeid COLLATE DATABASE_DEFAULt
    LEFT JOIN
    (
        SELECT dfhh.employeeid,
               --COUNT(dmh.case_id) cases
			   COUNT(dmh.ms_fileid) cases
        FROM red_dw.dbo.fact_dimension_main fdm
            INNER JOIN red_dw.dbo.dim_matter_header_current dmh WITH (NOLOCK)
                ON dmh.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
            LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history dfhh
                ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
			LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
			 ON dim_detail_outcome.client_code = dmh.client_code
			 AND dim_detail_outcome.matter_number = dmh.matter_number
        WHERE dmh.date_closed_case_management IS NULL
		----------------- Additions to match above -------------------------
		AND ms_only = 1 
		AND reporting_exclusions = 0    
		AND LOWER(ISNULL(outcome_of_case, '')) NOT in ('exclude from reports','returned to client') 

		--------------------------------------------------------------------
        GROUP BY dfhh.employeeid
    ) cases
        ON cases.employeeid = hir.employeeid
    LEFT JOIN
    (
        SELECT dfhh.employeeid,
               --COUNT(dmh.case_id) cases
			    COUNT(dmh.ms_fileid) cases
        FROM red_dw.dbo.fact_dimension_main fdm
            INNER JOIN red_dw.dbo.dim_matter_header_current dmh WITH (NOLOCK)
                ON dmh.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
            LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history dfhh
                ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
					LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
			 ON dim_detail_outcome.client_code = dmh.client_code
			 AND dim_detail_outcome.matter_number = dmh.matter_number
        WHERE dmh.date_closed_case_management IS NOT NULL
	    ----------------- Additions to match above -------------------------
		AND ms_only = 1 
		AND reporting_exclusions = 0    
		AND LOWER(ISNULL(outcome_of_case, '')) NOT in ('exclude from reports','returned to client') 

		--------------------------------------------------------------------
        GROUP BY dfhh.employeeid
    ) cases_closed
        ON cases_closed.employeeid = hir.employeeid
WHERE hir.hierarchylevel2hist  IN ( 'Legal Ops - Claims' )
GROUP BY hir.employeeid,
         hir.hierarchylevel2hist,
         hir.hierarchylevel3hist,
         hir.hierarchylevel4hist,
         hir.name,
         hir.fed_code,
         hir.windowsusername;



SELECT #results.employeeid,
       buisnessline,
       PracticeArea,
       team,
       name,
       fed_code,
       windowsusername,
       ---------------------------------open------------------------------------------------------------
       no_of_open_cases_with_exceptions,
       no_of_open_exceptions,
       total_open_cases,

       -------------------------------closed------------------------------------------------------------
       no_of_closed_cases_with_exceptions,
       no_of_closed_exceptions,
       total_closed_cases,

       ---------------------------------all------------------------------------------------------
       no_of_cases_with_exceptions,
       no_of_exceptions,
       total_cases,
	   ---------------------------------critria------------------------------------------------------
	    ISNULL(closed_critria_cases, 0) closed_critria_cases, 
	    ISNULL(open_critria_cases,0) open_critria_cases,
	    ISNULL(critria_cases,0) critria_cases
       ---------------------------------avg------------------------------------------------------
      --CASE WHEN no_of_open_exceptions  = 0 OR total_open_cases = 0 THEN 0 ELSE CAST(CAST(no_of_open_exceptions AS DECIMAL(8, 2)) / CAST(total_open_cases AS DECIMAL(8, 2)) AS DECIMAL(8, 2)) END [average number of exceptions on open matters v number of all open matters],
      --CASE WHEN no_of_open_exceptions  = 0  OR no_of_open_cases_with_exceptions = 0THEN 0  ELSE CAST(CAST(no_of_open_exceptions AS DECIMAL(8, 2)) / CAST(no_of_open_cases_with_exceptions AS DECIMAL(8, 2)) AS DECIMAL(8, 2)) end [Average number of exceptions on open matters v number of open matters with exceptions on],
      --CASE WHEN no_of_exceptions  = 0 OR total_open_cases = 0 THEN 0 ELSE CAST(CAST(no_of_exceptions AS DECIMAL(8, 2)) / CAST(total_open_cases AS DECIMAL(8, 2)) AS DECIMAL(8, 2)) end [Average number of exceptions (open and closed matters) v number of open matters],
      --CASE WHEN no_of_exceptions  = 0  OR no_of_cases_with_exceptions = 0 THEN 0 ELSE CAST(CAST(no_of_exceptions AS DECIMAL(8, 2)) / CAST(no_of_cases_with_exceptions AS DECIMAL(8, 2)) AS DECIMAL(8, 2)) end [Average number of exceptions (open and closed matters) v number of open and closed matters where there is an exception],
      --CASE WHEN no_of_exceptions  = 0 OR ISNULL(#critria_cases.cases, 0) = 0 THEN 0 ELSE CAST(CAST(no_of_exceptions AS DECIMAL(8, 2)) / CAST(ISNULL(#critria_cases.cases, 0) AS DECIMAL(8, 2)) AS DECIMAL(8, 2)) end [Average number of exceptions (open and closed matters) v number of open and closed matters that fit criteria]
FROM #results
    LEFT JOIN (
				SELECT employeeid,
				SUM(closed_critria_cases) closed_critria_cases,
				SUM(open_critria_cases) open_critria_cases ,
				SUM(critria_cases) critria_cases
				FROM 
				(
				SELECT 
				employeeid, 
				SUM(cases) critria_cases,
				CASE WHEN #critria_cases.open_closed = 1 THEN SUM(#critria_cases.cases) END closed_critria_cases,
				CASE WHEN #critria_cases.open_closed = 0 THEN SUM(#critria_cases.cases) END open_critria_cases
				FROM #critria_cases
				GROUP BY open_closed ,
				employeeid 
				) result GROUP BY 
				employeeid  ) #critria_cases
        ON #critria_cases.employeeid = #results.employeeid
		
ORDER BY name

END
GO
GRANT EXECUTE ON  [dbo].[MI_Exception_Summary_firm_wide] TO [ssrs_dynamicsecurity]
GO
