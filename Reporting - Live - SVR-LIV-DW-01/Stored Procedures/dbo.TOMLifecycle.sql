SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Orlagh Kelly
-- Create date: 2019-03-27
-- Description:	LTA Exceptions
-- =============================================

CREATE PROCEDURE [dbo].[TOMLifecycle]
(
    @FedCode AS VARCHAR(MAX),
    --@Month AS VARCHAR(100)
    @Level AS VARCHAR(100)
)
AS
BEGIN
--    -- SET NOCOUNT ON added to prevent extra result sets from
--    -- interfering with SELECT statements.
    SET NOCOUNT ON;
    --DECLARE @FEDCode VARCHAR(MAX) = '126556,126961,50405,51723,53046,54374,55704,57033,58362,59691,61474,114549,119905,121477,121774,26483,37777,26484,37778' 
    --DECLARE @Month VARCHAR(100)= '2019-07 (Nov-2018)'
    --DECLARE @Level VARCHAR(100)='Firm'
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

	END;




SELECT hierarchylevel2hist,
       hierarchylevel3hist,
       hierarchylevel4hist,
       name [Name],
       fact_dimension_main.client_code + '/' + fact_dimension_main.matter_number [Matter],
       header.matter_description [Description],
       header.date_opened_case_management [Open Date],
       header.date_closed_case_management [Date Closed ],
       lastbill.[Last Bill Date] [Last Bill Date],
	   header.present_position,

	 CASE WHEN   header.date_closed_case_management
    BETWEEN '2018-05-01' AND GETDATE()    THEN 1 
	
		   WHEN 
	             hierarchylevel2hist = 'Legal Ops - Claims'
				 AND header.date_closed_case_management IS NULL 
	                       AND present_position IN ( 'Final bill sent - unpaid',
	                                                 'To be closed/minor balances to be clear                     '
	                                               )  THEN 1 ELSE 0  END [inclusion],
              












	   calendar_date, 
       DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date]) [Lifecycle ],

       SUM(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30' THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30' THEN
                      1
                  ELSE
                      0
              END
          ) [LFY],
       SUM(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' ) THEN
                      1
                  ELSE
                      0
              END
          ) [Q2],
       SUM(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1' ) THEN
                      1
                  ELSE
                      0
              END
          ) [Q1],
       SUM(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3' ) THEN
                      1
                  ELSE
                      0
              END
          ) [Q3],
       SUM(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3', '2020-Q4' ) THEN
                      1
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q2', '2020-Q1', '2020-Q3', '2020-Q4' ) THEN
                      1
                  ELSE
                      0
              END
          ) [Q4],
       AVG(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30' THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND calendar_date
                       BETWEEN '2018-05-01' AND '2019-04-30' THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  ELSE
                      0
              END
          ) [AVG LC LFY],
       AVG(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  ELSE
                      0
              END
          ) [AVG LC YTD],
       AVG(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  ELSE
                      0
              END
          ) [AVG LC q1+2],
       AVG(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  ELSE
                      0
              END
          ) [AVG LC q1+2+3],
       AVG(   CASE
                  WHEN hierarchylevel2hist = 'Legal Ops - LTA'
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3', '2020-Q4' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  WHEN hierarchylevel2hist = 'Legal Ops - Claims'
                       AND present_position IN ( 'Final bill sent - unpaid',
                                                 'To be closed/minor balances to be clear                     '
                                               )
                       AND dim_date.fin_quarter IN ( '2020-Q1', '2020-Q2', '2020-Q3', '2020-Q4' ) THEN
                      DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date])
                  ELSE
                      0
              END
          ) [AVG LC q1+2+3+4]
FROM red_dw.dbo.fact_dimension_main
    INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
    LEFT JOIN red_dw.dbo.dim_matter_header_current header
        ON header.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.fact_finance_summary
        ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    LEFT JOIN red_dw.dbo.fact_matter_summary_current
        ON fact_matter_summary_current.dim_matter_header_curr_key = header.dim_matter_header_curr_key
    LEFT JOIN
    (
        SELECT client_code,
               matter_number,
               CASE
                   WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
                       NULL
                   ELSE
                       fact_matter_summary_current.last_bill_date
               END AS [Last Bill Date]
        FROM red_dw.dbo.fact_matter_summary_current
    ) lastbill
        ON lastbill.client_code = header.client_code
           AND lastbill.matter_number = header.matter_number
    LEFT JOIN red_dw.dbo.dim_date
        ON CAST(dim_date.calendar_date AS DATE) = CAST(lastbill.[Last Bill Date] AS DATE)







WHERE
    --header.date_closed_case_management IS NULL 
    header.reporting_exclusions = 0
    AND header.matter_description <> 'ML'
    AND LOWER(header.matter_description) NOT LIKE '%test%'
    AND hierarchylevel2hist IN ( 'Legal Ops - LTA', 'Legal Ops - Claims' )
    AND   CASE WHEN   header.date_closed_case_management
    BETWEEN '2018-05-01' AND GETDATE()    THEN 1 
	
		   WHEN 
	             hierarchylevel2hist = 'Legal Ops - Claims'
				 AND header.date_closed_case_management IS NULL 
	                       AND present_position IN ( 'Final bill sent - unpaid',
	                                                 'To be closed/minor balances to be clear                     '
	                                               )  THEN 1 ELSE 0  END = 1 

							






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

GROUP BY	fact_dimension_main.client_code + '/' + fact_dimension_main.matter_number,
            CASE
            WHEN hierarchylevel2hist = 'Legal Ops - LTA' THEN
            1
            WHEN hierarchylevel2hist = 'Legal Ops - Claims'
            AND present_position IN ( 'Final bill sent - unpaid',
            'To be closed/minor balances to be clear                     '
            ) THEN
            1
            ELSE
            0
            END,
            DATEDIFF(DAY, header.date_opened_case_management, lastbill.[Last Bill Date]),
            hierarchylevel2hist,
            hierarchylevel3hist,
            hierarchylevel4hist,
            name,
            calendar_date, 
			matter_description, 
			header.date_opened_case_management,
			header.date_closed_case_management, lastbill.[Last Bill Date], 
			 header.present_position


END 
GO
