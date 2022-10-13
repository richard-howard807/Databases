SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[1stcentral]--EXEC [dbo].[inquestreport] 'Casualty Liverpool 2','Open' ,'Inquest                                 ',NULL,NULL




(
@Bill AS NVARCHAR(MAX)
,@StartDate AS DATE NULL
,@EndDate AS DATE NULL

)
AS
BEGIN

--SELECT ListValue  INTO #Bill FROM Reporting.dbo.[udt_TallySplit]('|', @Bill)



SELECT dim_date.calendar_date [Work Date],
       dim_fed_hierarchy_history.name [Fee Earner Name ],
	   fed_code, 
	  -- FE.name, 
       fact_all_time_activity.wiphrs [WIP Hours],
       dim_all_time_activity.hourly_charge_rate [WIP Rate],
       fact_all_time_activity.time_charge_value [WIP Amount],
	 dim_bill.  bill_number [Invoice Number],
	   RTRIM(dim_all_time_activity.client_code) + '/'+ RTRIM(dim_all_time_activity.matter_number) [Matter Number],
	

       time_activity_descrn [Time Type],
       narrative [Narrative],
	   disc.matter_description [Matter Name],
	  fact_bill_matter.last_bill_date [Bill Date ]


FROM red_dw.dbo.fact_all_time_activity
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
    LEFT JOIN red_dw.dbo.dim_all_time_activity
        ON dim_all_time_activity.dim_all_time_activity_key = fact_all_time_activity.dim_all_time_activity_key
    LEFT JOIN red_dw.dbo.dim_bill_narrative
        ON dim_bill_narrative.transaction_sequence_number = dim_all_time_activity.transaction_sequence_number
    LEFT OUTER JOIN red_dw.dbo.dim_date
        ON dim_date.dim_date_key = fact_all_time_activity.dim_transaction_date_key
		LEFT JOIN red_dw.dbo.dim_bill ON dim_bill.dim_bill_key = fact_all_time_activity.dim_bill_key
		LEFT JOIN red_dw.dbo.dim_date AS bd ON dim_date.dim_date_key = fact_all_time_activity.dim_bill_date_key
		LEFT JOIN (
		SELECT client_code, matter_number, matter_description , dim_matter_header_curr_key, final_bill_date
		FROM red_dw.dbo.dim_matter_header_current
		WHERE client_code ='W20352'
		
		) AS  disc ON disc.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
		--LEFT JOIN dim_fed_hierarchy_history AS FE ON FE.fed_code = fact_all_time_activity.fed_code_fee_earner

		--NNER JOIN #Bill AS matter ON Bill.ListValue COLLATE DATABASE_DEFAULT = 	  bill_number COLLATE DATABASE_DEFAULT
--

WHERE 
 dim_all_time_activity.client_code = 'W20352'

AND dim_all_time_activity.reporting_exclusions = 0 
AND 	  fact_bill_matter.last_bill_date BETWEEN @StartDate AND @EndDate
AND bill_number IN (@Bill)
--AND RTRIM(dim_all_time_activity.client_code) + '/'+ RTRIM(dim_all_time_activity.matter_number) IN (@matter)

END 
GO
