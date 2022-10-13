SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Orlagh Kelly
-- Create date: 2019-03-27
-- Description:	LTA Exceptions
-- =============================================

CREATE  PROCEDURE [dbo].[TOMLifecycle TEST] 
(
    @FedCode AS VARCHAR(MAX),
    --@Month AS VARCHAR(100)
    @Level AS VARCHAR(100)
)
AS
--BEGIN
--    -- SET NOCOUNT ON added to prevent extra result sets from
--    -- interfering with SELECT statements.
  --  SET NOCOUNT ON;
  --  DECLARE @FEDCode VARCHAR(MAX) = '126556,126961,50405,51723,53046,54374,55704,57033,58362,59691,61474,114549,119905,121477,121774,26483,37777,26484,37778' 
    --DECLARE @Month VARCHAR(100)= '2019-07 (Nov-2018)'
  --  DECLARE @Level VARCHAR(100)='Firm'
    ----- main 


DROP TABLE  IF EXISTS #FedCodeList
    	CREATE TABLE #FedCodeList  (
									ListValue  NVARCHAR(MAX)
	
									)
IF @level  <> 'Individual'
	BEGIN
	PRINT ('not Individual')
DECLARE @sql NVARCHAR(MAX)

SET @sql = '
	use red_dw;
	DECLARE @nDate AS DATE = GETDATE()

	SELECT DISTINCT
	dim_fed_hierarchy_history_key
	FROM red_Dw.dbo.dim_fed_hierarchy_history 
	WHERE dim_fed_hierarchy_history_key IN ('+@FedCode+')'

	INSERT into #FedCodeList 
	exec sp_executesql @sql
	end


	IF  @level  = 'Individual'
    BEGIN
		PRINT ('Individual')
		INSERT into #FedCodeList 
		SELECT ListValue
			-- INTO #FedCodeList
		FROM dbo.udt_TallySplit(',', @FedCode)
	END


; WITH Lifecycle AS (
		SELECT fed_code, hierarchylevel2hist, hierarchylevel3hist, hierarchylevel4hist, display_name,
			date_closed_practice_management, dim_detail_core_details.present_position,
			DATEDIFF(d, date_opened_practice_management, last_bill_date) lifecycle, fin_year

		-- select *
		FROM red_dw.dbo.dim_detail_core_details
		INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_detail_core_detail_key = dim_detail_core_details.dim_detail_core_detail_key
		INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key	
		INNER JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
		INNER JOIN red_dw.dbo.dim_date ON fact_bill_matter.last_bill_date = dim_date.calendar_date
		WHERE reporting_exclusions = 0  
		AND matter_description <> 'ML'
		AND LOWER(matter_description) NOT LIKE '%test%'
		AND hierarchylevel2hist IN ( 'Legal Ops - LTA', 'Legal Ops - Claims' )
		-- AND fed_code in ('4664','3891')
		AND fin_year IN (SELECT fin_year FROM red_dw..dim_date WHERE current_fin_year IN ('Current','Previous'))	
		--AND hierarchylevel3hist = 'Disease'
		AND (dim_detail_core_details.present_position IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')	
			OR  date_closed_practice_management IS NOT NULL)		
		AND dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
			   (
				   SELECT (CASE
							   WHEN @Level = 'Firm' THEN
								   dim_fed_hierarchy_history_key
							   ELSE
								   0
						   END
						  )
				   FROM red_dw.dbo.dim_fed_hierarchy_history
				   UNION
				   SELECT  (CASE
							   WHEN @Level IN ( 'Individual' ) THEN
								   ListValue
							   ELSE
								   0
						   END
						  )
				   FROM #FedCodeList
				   UNION
				   SELECT (CASE
							   WHEN @Level IN ( 'Area Managed' ) THEN
								   ListValue
							   ELSE
								   0
						   END
						  )
				   FROM #FedCodeList
			   ) 
		
	)

	
SELECT *
	 ,Median_fee_earner = PERCENTILE_CONT(0.5) WITHIN GROUP 
     (ORDER BY lifecycle) OVER (PARTITION BY Lifecycle.fed_code, fin_year)

	  ,Median_lvl4 = PERCENTILE_CONT(0.5) WITHIN GROUP 
     (ORDER BY lifecycle) OVER (PARTITION BY Lifecycle.hierarchylevel4hist, fin_year)

	 ,Median_lvl3 = PERCENTILE_CONT(0.5) WITHIN GROUP 
     (ORDER BY lifecycle) OVER (PARTITION BY Lifecycle.hierarchylevel3hist, fin_year)

	 ,Median_lvl2 = PERCENTILE_CONT(0.5) WITHIN GROUP 
     (ORDER BY lifecycle) OVER (PARTITION BY Lifecycle.hierarchylevel2hist, fin_year)

FROM Lifecycle






	/*
	
SELECT hierarchylevel2hist,
       hierarchylevel3hist,
       hierarchylevel4hist,
       name Name,
       fact_dimension_main.client_code + '/' + fact_dimension_main.matter_number Matter,
       header.matter_description Description,
       header.date_opened_case_management [Open Date],
       header.date_closed_case_management [Date Closed ],

       header.present_position,
       CASE
           WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3', '2020-Q4', '2019-Q2', '2019-Q1',
                                              '2019-Q3', '2019-Q4'
                                            )
                AND
                (
                    header.date_closed_case_management >= '2016-01-01'
                    OR header.date_closed_case_management IS NULL
                ) THEN
               1
           ELSE
               0
       END AS inclusion,
       fact_bill_matter.last_bill_date [Last Bill Date Composite ],

      




       calendar_date,
       DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date) [Lifecycle ],
         CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30'
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30' THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30'
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  ELSE
                      0
              END
           LFY,
   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  ELSE
                      0
              END
           Q2,
CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q1' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  ELSE
                      0
              END
          Q1,
 CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  ELSE
                      0
              END
          Q3,
 CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3', '2020-Q4' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3', '2020-Q4' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3', '2020-Q4' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      1
                  ELSE
                      0
              END
          Q4,
CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30'
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30' THEN
                      DATEDIFF(DAY, header.date_opened_case_management,       fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30'
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  ELSE
                      0
              END
           [AVG LC LFY],
 CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,       fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q1' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  ELSE
                      0
              END
           [AVG LC YTD],
          CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management,       fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  ELSE
                      0
              END
          [AVG LC q1+2],
    CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,       fact_bill_matter.last_bill_date)
                  ELSE
                      0
              END
          [AVG LC q1+2+3],
   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3', '2020-Q4' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3', '2020-Q4' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3', '2020-Q4' )
                       AND fact_matter_summary_current.date_closed_case_management IS NOT NULL THEN
                      DATEDIFF(DAY, header.date_opened_case_management,        fact_bill_matter.last_bill_date)
                  ELSE
                      0
              END
           [AVG LC q1+2+3+4]
FROM red_dw.dbo.fact_dimension_main  (NOLOCK)
    INNER JOIN red_dw.dbo.dim_fed_hierarchy_history (NOLOCK)
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current header (NOLOCK)
        ON header.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.fact_finance_summary (NOLOCK)
        ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    LEFT JOIN red_dw.dbo.fact_matter_summary_current (NOLOCK)
        ON fact_matter_summary_current.dim_matter_header_curr_key = header.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.fact_bill_matter (NOLOCK)
  ON fact_bill_matter.master_fact_key = fact_dimension_main.master_fact_key
    
    LEFT JOIN red_dw.dbo.dim_date
        ON CAST(dim_date.calendar_date AS DATE) = CAST(fact_bill_matter.last_bill_date AS DATE)
WHERE
	
    --header.date_closed_case_management IS NULL 
    header.reporting_exclusions = 0
    AND header.matter_description <> 'ML'
    AND LOWER(header.matter_description) NOT LIKE '%test%'
    AND hierarchylevel2hist IN ( 'Legal Ops - LTA', 'Legal Ops - Claims' )
    AND (CASE
             WHEN hierarchylevel2hist IN ( 'Legal Ops - LTA', 'Legal Ops - Claims' )
                  AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3', '2020-Q4', '2019-Q2', '2019-Q1',
                                                '2019-Q3', '2019-Q4'
                                              )
                  AND
                  (
                      header.date_closed_case_management >= '2016-01-01'
                      OR header.date_closed_case_management IS NULL
                  ) THEN
                 1
             ELSE
                 0
         END
        ) = 1
    AND fact_bill_matter.last_bill_date >= '2016-01-01'

AND fed_code = '3156'



AND dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
       (
           SELECT (CASE
                       WHEN @Level = 'Firm' THEN
                           dim_fed_hierarchy_history_key
                       ELSE
                           0
                   END
                  )
           FROM red_dw.dbo.dim_fed_hierarchy_history
           UNION
           SELECT  (CASE
                       WHEN @Level IN ( 'Individual' ) THEN
                           ListValue
                       ELSE
                           0
                   END
                  )
           FROM #FedCodeList
           UNION
           SELECT (CASE
                       WHEN @Level IN ( 'Area Managed' ) THEN
                           ListValue
                       ELSE
                           0
                   END
                  )
           FROM #FedCodeList
       ) 

	   END 


	   */
GO
