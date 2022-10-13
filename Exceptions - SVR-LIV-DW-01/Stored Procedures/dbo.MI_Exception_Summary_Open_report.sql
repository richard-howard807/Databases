SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego	
-- Create date: 2018-10-10
-- Description:	Took the code out of the report and put it into a sp
-- =============================================
CREATE PROCEDURE [dbo].[MI_Exception_Summary_Open_report]
(
@FeeEarners AS NVARCHAR(max)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @nDate AS DATE = GETDATE()


;WITH feearners AS (
SELECT distinct
employeeid
FROM red_Dw.dbo.dim_fed_hierarchy_history 
INNER JOIN dbo.split_delimited_to_rows(@FeeEarners,',') AS FeeEarners ON dim_fed_hierarchy_history.fed_code COLLATE database_default = FeeEarners.val COLLATE DATABASE_DEFAULT
)

SELECT hir.employeeid,
       SUM(no_of_cases) no_of_cases,
       SUM(ISNULL(cases.cases,0)) total_cases,
       SUM(no_of_exceptions) no_of_exceptions,
       --DATEPART(WEEK, [date]) [WEEK],
       --DATEPART(YEAR, [date]) [YEAR],
       --[date],
       --CAST(DATEADD(DD, 2 - DATEPART(DW, [date]), [date]) AS DATE) [start_of_week],
       CASE
           WHEN CAST(DATEADD(DD, 2 - DATEPART(DW, [date]), [date]) AS DATE) = CAST([date] AS DATE) THEN
               1
           ELSE
               0
       END AS [start_of_week_filter],
       CASE
           WHEN @nDate = CAST([date] AS DATE) THEN
               1
           ELSE
               0
       END AS [CURRENT],
       hir.hierarchylevel2hist buisnessline,
       hir.hierarchylevel3hist PracticeArea,
       hir.hierarchylevel4hist team,
       hir.name,
       hir.fed_code,
       hir.windowsusername
FROM Exceptions.[dbo].[MI.Management]
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history hir
        ON [MI.Management].employeeid = hir.employeeid
           AND hir.dss_current_flag = 'Y'
           AND hir.activeud = 1
	INNER JOIN feearners 
		ON feearners.employeeid = hir.employeeid
    LEFT JOIN
     (
          SELECT dfhh.employeeid,
                COUNT(dmh.case_id) cases
         FROM red_dw.dbo.fact_dimension_main fdm
             INNER JOIN red_dw.dbo.dim_matter_header_current dmh WITH (NOLOCK)
                 ON dmh.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
             LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history dfhh
                 ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
         WHERE   dmh.date_closed_case_management IS null
         GROUP BY dfhh.employeeid
     ) cases
        ON cases.employeeid = hir.employeeid
WHERE date > '2017-10-07'
      AND hir.hierarchylevel2hist NOT IN ( 'Business Services', 'Legal Ops - LTA' )
	  AND(
	 CASE
           WHEN CAST(DATEADD(DD, 2 - DATEPART(DW, [date]), [date]) AS DATE) = CAST([date] AS DATE) THEN
               1
           ELSE
               0
       END = 1 
	   OR

       CASE
           WHEN @nDate = CAST([date] AS DATE) THEN
               1
           ELSE
               0
       END  =1)

GROUP BY hir.employeeid,
       CASE
           WHEN CAST(DATEADD(DD, 2 - DATEPART(DW, [date]), [date]) AS DATE) = CAST([date] AS DATE) THEN
               1
           ELSE
               0
       END ,
       CASE
           WHEN @nDate = CAST([date] AS DATE) THEN
               1
           ELSE
               0
       END,
         hir.hierarchylevel2hist,
         hir.hierarchylevel3hist,
         hir.hierarchylevel4hist,
         hir.name,
         hir.fed_code,
         hir.windowsusername
ORDER BY hir.name;
END
GO
