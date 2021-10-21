SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Orlagh Kelly
-- Create date: 2019-03-27
-- Description:	LTA Exceptions
-- =============================================

CREATE PROCEDURE [dbo].[LTAExceptions]
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

INSERT INTO #FedCodeList 
EXEC sp_executesql @sql
	END
	
	
	IF  @level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT INTO #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END


    ;WITH nofocases
    AS (SELECT fact_dimension_main.client_code,
               fact_dimension_main.matter_number,
               CASE
                   WHEN 
				   
				   
				   
		(dim_detail_finance.[output_wip_fee_arrangement] IS NULL)
                        OR

                        -- OR 

                        (
                            dim_detail_finance.[output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee'
                            AND
                            (
                                fact_finance_summary.[fixed_fee_amount] IS NULL
                                OR fact_finance_summary.[fixed_fee_amount] < 1
                            )
                        )
                        OR
                        (
                           
                  NOT   (
                                       work_type_name  LIKE ('PL%')
                                       OR work_type_name  LIKE ('Prof Risk%')
                                       OR work_type_name  LIKE ('LMT%')
                                   )
				  AND 
				  
						   
						   
						    DATEDIFF(d, dim_matter_header_current.date_opened_case_management, GETDATE()) > 28
                            AND dim_detail_finance.[output_wip_fee_arrangement] = 'Hourly rate'
                            AND
                            (
                                ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) IS NULL
                                OR ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) < 1
                                   --AND
                                   --(
                                   --    work_type_name NOT LIKE ('PL%')
                                   --    OR work_type_name NOT LIKE ('Prof Risk%')
                                   --    OR work_type_name NOT LIKE ('LMT%')
                                   --)
                            )
                        ) THEN
                       1
                   ELSE
                       0
               END AS [Noexceptions],
               CASE
                   WHEN dim_detail_finance.[output_wip_fee_arrangement] IS NULL THEN
                       1
                   ELSE
                       0
               END AS [Exfeearrangement],
               CASE
                   WHEN dim_detail_finance.[output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee'
                        AND
                        (
                            fact_finance_summary.[fixed_fee_amount] IS NULL
                            OR fact_finance_summary.[fixed_fee_amount] < 1
                        ) THEN
                       1
                   ELSE
                       0
               END AS [ExFixedfeeamountexception],
               CASE
                   WHEN
				   
				    NOT   (
                                       work_type_name  LIKE ('PL%')
                                       OR work_type_name  LIKE ('Prof Risk%')
                                       OR work_type_name  LIKE ('LMT%')
                                   )
				  AND 
				  
				   
				    dim_detail_finance.[output_wip_fee_arrangement] = 'Hourly rate'
                        AND DATEDIFF(d, dim_matter_header_current.date_opened_case_management, GETDATE()) > 28
                        AND
                        (
                            ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) IS NULL
                            OR ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) < 1
                        )
                        --AND
                        --(
                        --    work_type_name NOT LIKE ('PL%')
                        --    OR work_type_name NOT LIKE ('Prof Risk%')
                        --    OR work_type_name NOT LIKE ('LMT%')
                        --) 
						
						
						THEN
                       1
                   ELSE
                       0
               END AS [ExCommencialCosts]
        FROM red_dw.dbo.fact_dimension_main
            INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
                ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
            LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
                ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
            LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
                ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
            LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
                ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
            LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
                ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
            LEFT OUTER JOIN red_dw.dbo.dim_detail_property
                ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
        WHERE dim_matter_header_current.date_closed_practice_management IS NULL
              AND hierarchylevel2 = 'Legal Ops - LTA'
              AND dim_matter_worktype.work_type_code NOT IN ( '1114', '1143', '1101', '1077', '1106' )
			   AND matter_description <> 'MIBTEST'
              AND ISNULL(exclude_from_exceptions_reports, '') <> 'Yes'
              AND reporting_exclusions = 0
              AND ISNULL(dim_detail_property.[commercial_bl_status], '') <> 'Pending   
                                                  '
              AND ISNULL(output_wip_fee_arrangement, '') IN ( NULL,
                                                              'Hourly Rate                                                 ',
                                                              'Hourly rate                                                 ',
                                                              'HOURLY', '',
                                                              'Fixed Fee/Fee Quote/Capped Fee                              '
                                                            ))
    SELECT hierarchylevel2hist,
           hierarchylevel3hist,
           hierarchylevel4hist,
        red_dw.dbo.fact_dimension_main.client_code [Client Code],
           red_dw.dbo.fact_dimension_main.matter_number [Matter Number ],
           matter_description [Matter Description ],
           dim_fed_hierarchy_history.name [Fee Earner Name ],
           dim_matter_header_current.date_opened_case_management [Open Date],
           date_closed_case_management [Closed Date ],
           1 AS [Count ],
           ISNULL(nofocases.Exfeearrangement, 0) + ISNULL(nofocases.ExFixedfeeamountexception, 0)
           + ISNULL(nofocases.ExCommencialCosts, 0) AS [NumberOfExceptions],
           nofocases.Noexceptions [Number of Cases with Exceptions ],
           fact_finance_summary.[fixed_fee_amount] [Fixed Fee Amount ],
           dim_detail_finance.[output_wip_fee_arrangement] [Fee Arrangement ],
           ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) [Current Costs Estimate],
           CASE
               WHEN dim_detail_finance.[output_wip_fee_arrangement] IS NULL THEN
                   1
               ELSE
                   0
           END AS [Exfeearrangement],
           CASE
               WHEN dim_detail_finance.[output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee'
                    AND
                    (
                        fact_finance_summary.[fixed_fee_amount] IS NULL
                        OR fact_finance_summary.[fixed_fee_amount] < 1
                    ) THEN
                   1
               ELSE
                   0
           END AS [ExFixedfeeamountexception],
           CASE
               WHEN 
			   
			    NOT   (
                                       work_type_name  LIKE ('PL%')
                                       OR work_type_name  LIKE ('Prof Risk%')
                                       OR work_type_name  LIKE ('LMT%')
                                   )
				  AND 
				  
			   
			   dim_detail_finance.[output_wip_fee_arrangement] = 'Hourly rate'
                    AND DATEDIFF(d, dim_matter_header_current.date_opened_case_management, GETDATE()) > 28
                    AND
                    (
                        ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate)IS NULL
                        OR ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) < 1
                    )
                        --           AND
                        --(
                        --    work_type_name NOT LIKE ('PL%')
                        --    OR work_type_name NOT LIKE ('Prof Risk%')
                        --    OR work_type_name NOT LIKE ('LMT%') 
							
							THEN
                   1
               ELSE
                   0
           END AS [ExCommencialCosts]
    FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        INNER JOIN red_dw.dbo.dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        INNER JOIN red_dw.dbo.dim_detail_finance
            ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
        LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN nofocases
            ON nofocases.client_code = dim_detail_finance.client_code
               AND nofocases.matter_number = dim_detail_finance.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_property
            ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
    WHERE dim_matter_header_current.date_closed_practice_management IS NULL
          AND ISNULL(exclude_from_exceptions_reports, '') <> 'Yes'
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
          AND hierarchylevel2 = 'Legal Ops - LTA'
          AND dim_matter_worktype.work_type_code NOT IN ( '1114', '1143', '1101', '1077', '1106' )
		  AND ISNULL(exclude_from_exceptions_reports, '') <> 'Yes'
          AND reporting_exclusions = 0
          AND ISNULL(dim_detail_property.[commercial_bl_status], '') <> 'Pending   
                                                  '
												    AND matter_description <> 'MIBTEST'
          AND ISNULL(output_wip_fee_arrangement, '') IN ( NULL,
                                                          'Hourly Rate                                                 ',
                                                          'Hourly rate                                                 ',
                                                          'HOURLY', '',
                                                          'Fixed Fee/Fee Quote/Capped Fee                              '
                                                        )





    --AND (CASE WHEN dim_detail_finance.[output_wip_fee_arrangement]  IS NULL THEN 1 ELSE 0 END = 1  
    --OR CASE WHEN dim_detail_finance.[output_wip_fee_arrangement] ='Fixed Fee/Fee Quote/Capped Fee' AND fact_finance_summary.[fixed_fee_amount] IS NULL THEN 1 ELSE 0 END = 1 
    --OR( CASE WHEN DATEDIFF(d,dbo.dim_matter_header_current.date_opened_case_management, GETDATE()) > 28 AND fact_finance_summary.[commercial_costs_estimate] IS NULL THEN 1 ELSE 0 END )= 1 )
GROUP BY	ISNULL(nofocases.Exfeearrangement, 0) + ISNULL(nofocases.ExFixedfeeamountexception, 0)
            + ISNULL(nofocases.ExCommencialCosts, 0),
            CASE
            WHEN dim_detail_finance.[output_wip_fee_arrangement] IS NULL THEN
            1
            ELSE
            0
            END,
            CASE
            WHEN dim_detail_finance.[output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee'
            AND
            (
            fact_finance_summary.[fixed_fee_amount] IS NULL
            OR fact_finance_summary.[fixed_fee_amount] < 1
            ) THEN
            1
            ELSE
            0
            END,
            CASE
            WHEN NOT   (
                                       work_type_name  LIKE ('PL%')
                                       OR work_type_name  LIKE ('Prof Risk%')
                                       OR work_type_name  LIKE ('LMT%')
                                   )
            AND dim_detail_finance.[output_wip_fee_arrangement] = 'Hourly rate'
            AND DATEDIFF(d, dim_matter_header_current.date_opened_case_management, GETDATE()) > 28
            AND
            (
            ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) IS NULL
            OR ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate) < 1
            )
            --           AND
            --(
            --    work_type_name NOT LIKE ('PL%')
            --    OR work_type_name NOT LIKE ('Prof Risk%')
            --    OR work_type_name NOT LIKE ('LMT%') 
            THEN
            1
            ELSE
            0
            END,
            hierarchylevel2hist,
            hierarchylevel3hist,
            hierarchylevel4hist,
            fact_dimension_main.client_code,
            fact_dimension_main.matter_number,
            matter_description,
            name,
            date_opened_case_management,
            date_closed_case_management,
            fact_finance_summary.fixed_fee_amount,
            output_wip_fee_arrangement, 
			nofocases.Noexceptions, 
			ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate)

			END;
GO
