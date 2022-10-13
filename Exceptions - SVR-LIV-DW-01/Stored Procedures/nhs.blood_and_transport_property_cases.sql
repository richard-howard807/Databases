SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






-- ==============================================================================================
-- Author:		Lucy Dickinson
-- Create date: 20190412
-- Description:	Ticket #14079 as requested by Bob Hetherington
--				Report to be used alongside of an Automatic Alerting process managed by an ms robot(?) 
--				Need to amend to query the reminder dates rather than doing the reminder calculations so that any changes to process
--				are automatically dealt with.
--				Query needs to be in SQL as the MSRobot tables are not currently in the warehouse
-- ================================================================================================
-- 20190514 LD added vacated property; need to put into the warehouse but am selecting straighte from MS_PROD for now (urgent)
-- 20190603 ES Ticket #20983 added logic to order the matters based on the 4 reminder dates

CREATE PROCEDURE [nhs].[blood_and_transport_property_cases]
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results

SELECT *,ROW_NUMBER() OVER (ORDER BY ref) AS RowNo
INTO #Results
FROM 

(SELECT header.master_client_code + '-' + header.master_matter_number [Ref],
       header.matter_description,
       header.matter_owner_full_name,
       worktype.work_type_name,
       worktype.work_type_group,
       header.date_opened_case_management,
       REPLACE(REPLACE(PROPERTY.break_1,' months',''), ' Months','') [notice_period], -- needs updating via api to be numbers so we don't need to do the below calculation to extract the number
       DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 12) * -1, PROPERTY.break_date) [reminder 1yr],
       DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 6) * -1, PROPERTY.break_date) [reminder 6 mnth],
       DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 3) * -1, PROPERTY.break_date) [reminder 3 mnth],
       DATEADD(d, -7, (DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date))) [reminder 1 week]

	   , CASE WHEN DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 12) * -1, PROPERTY.break_date) < GETDATE() THEN NULL ELSE DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 12) * -1, PROPERTY.break_date) END AS [Date1]
       , CASE WHEN DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 6) * -1, PROPERTY.break_date) < GETDATE() THEN NULL ELSE DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 6) * -1, PROPERTY.break_date) END AS [Date2]
       , CASE WHEN DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 3) * -1, PROPERTY.break_date) < GETDATE() THEN NULL ELSE DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 3) * -1, PROPERTY.break_date) END AS [Date3]
       , CASE WHEN DATEADD(d, -7, (DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date))) < GETDATE() THEN NULL ELSE DATEADD(d, -7, (DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date))) END AS [Date4],


       DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date) [notice],
       PROPERTY.break_date,
       PROPERTY.term_end_date,
       DATEADD(m,-6, PROPERTY.term_end_date) [reminder_term_end_6mnth],
	   DATEADD(d,-7, PROPERTY.term_end_date) [reminder_term_end_1week],

	 
	   PROPERTY.lease_expiry_date,
       PROPERTY.rent_review_dates,
       PROPERTY.completion_date,
       PROPERTY.[address],
	   CASE WHEN PV.cboVacatedProp = 'Y' THEN 'Yes'
			WHEN PV.cboVacatedProp = 'N' THEN 'No'
			ELSE 'Not Specified' END [vacated_property],
	   CASE WHEN PROPERTY.break_date IS NOT NULL AND PROPERTY.break_date > GETDATE() THEN 1 ELSE 0 END [Internal]

	
	FROM red_dw.dbo.fact_dimension_main main
    INNER JOIN red_dw.dbo.dim_matter_header_current header
        ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
    INNER JOIN red_dw.dbo.dim_matter_worktype worktype
        ON worktype.dim_matter_worktype_key = header.dim_matter_worktype_key
    INNER JOIN red_dw.dbo.dim_detail_property PROPERTY
        ON PROPERTY.dim_detail_property_key = main.dim_detail_property_key
    LEFT OUTER JOIN red_dw.dbo.fact_finance_summary fin
        ON fin.master_fact_key = main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details core
        ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
    LEFT OUTER JOIN MS_Prod.dbo.udMIPropertyView PV
        ON header.ms_fileid = PV.fileID
    LEFT OUTER JOIN MS_Prod.dbo.udMIProcessTXT mi
        ON header.ms_fileid = mi.fileID
WHERE header.client_code = '00707938'
      AND worktype.work_type_name = 'Property View'
      AND header.reporting_exclusions = 0
	   --AND PROPERTY.break_date IS NOT NULL
    --  AND PROPERTY.break_date > GETDATE()

UNION ALL


SELECT header.master_client_code + '-' + header.master_matter_number [Ref],
       header.matter_description,
       header.matter_owner_full_name,
       worktype.work_type_name,
       worktype.work_type_group,
       header.date_opened_case_management,
       REPLACE(REPLACE(PROPERTY.break_1,' months',''), ' Months','') [notice_period], -- needs updating via api to be numbers so we don't need to do the below calculation to extract the number
   
	   DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 12) * -1, PROPERTY.break_date2) [2_rem_1yr],
       DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 6) * -1, PROPERTY.break_date2) [2_rem_6_mnth],
       DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 3) * -1, PROPERTY.break_date2) [2_rem_3_mnth],
        DATEADD(d, -7, (DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date2)))  [2_rem_1_week],
		CASE WHEN DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 12) * -1, PROPERTY.break_date2) < GETDATE() THEN NULL ELSE DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 12) * -1, PROPERTY.break_date2) END AS [2Date1]
	  , CASE WHEN DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 6) * -1, PROPERTY.break_date2) < GETDATE() THEN NULL ELSE DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 6) * -1, PROPERTY.break_date2) END AS [2Date2]
	  , CASE WHEN DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 3) * -1, PROPERTY.break_date2) < GETDATE() THEN NULL ELSE DATEADD(m, (TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) + 3) * -1, PROPERTY.break_date2) END AS [2Date3]
      , CASE WHEN DATEADD(d, -7, (DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date2))) < GETDATE() THEN NULL ELSE DATEADD(d, -7, (DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date2))) END AS [2Date4],
       DATEADD(m, TRY_CAST(TRIM(LEFT(PROPERTY.break_1, 2)) AS INT) * -1, PROPERTY.break_date2) [2_notice],
       PROPERTY.break_date2,
       PROPERTY.term_end_date,
	   DATEADD(m,-6, PROPERTY.term_end_date) [reminder_term_end_6mnth],
	   DATEADD(d,-7, PROPERTY.term_end_date) [reminder_term_end_1week],

       PROPERTY.lease_expiry_date,
       PROPERTY.rent_review_dates,
       PROPERTY.completion_date,
       PROPERTY.[address],
	    CASE WHEN PV.cboVacatedProp = 'Y' THEN 'Yes'
			WHEN PV.cboVacatedProp = 'N' THEN 'No'
			ELSE 'Not Specified' END [vacated_property],
	   CASE WHEN PROPERTY.break_date2 IS NOT NULL AND PROPERTY.break_date2 > GETDATE() THEN 1 ELSE 0 END [Internal]
	

FROM red_dw.dbo.fact_dimension_main main
    INNER JOIN red_dw.dbo.dim_matter_header_current header
        ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
    INNER JOIN red_dw.dbo.dim_matter_worktype worktype
        ON worktype.dim_matter_worktype_key = header.dim_matter_worktype_key
    INNER JOIN red_dw.dbo.dim_detail_property PROPERTY
        ON PROPERTY.dim_detail_property_key = main.dim_detail_property_key
    LEFT OUTER JOIN red_dw.dbo.fact_finance_summary fin
        ON fin.master_fact_key = main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details core
        ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
    LEFT OUTER JOIN MS_Prod.dbo.udMIPropertyView PV
        ON header.ms_fileid = PV.fileID
    LEFT OUTER JOIN MS_Prod.dbo.udMIProcessTXT mi
        ON header.ms_fileid = mi.fileID
WHERE header.client_code = '00707938'
      AND worktype.work_type_name = 'Property View'
      AND header.reporting_exclusions = 0
	  --AND PROPERTY.break_date2 IS NOT NULL
   --   AND PROPERTY.break_date2 > GETDATE()
   ) AS Data


SELECT  a.Ref,
a.RowNo,
		matter_description,
       matter_owner_full_name,
       work_type_name,
       work_type_group,
       date_opened_case_management,
       notice_period,
       [reminder 1yr],
       [reminder 6 mnth],
       [reminder 3 mnth],
       [reminder 1 week],
       Date1,
       Date2,
       Date3,
       Date4,
       notice,
       break_date,
       term_end_date,
       reminder_term_end_6mnth,
       reminder_term_end_1week,
       lease_expiry_date,
       rent_review_dates,
       completion_date,
       address,
       vacated_property,
       Internal,
 EarliestDates.EarliestDate
 
FROM #Results AS a
LEFT OUTER JOIN
(
SELECT Ref,Dates.RowNo,  MIN(EarliestDate) AS [EarliestDate]
FROM #Results
UNPIVOT
(
	EarliestDate
	FOR Dates IN (Date1, Date2, Date3, Date4)
) AS Dates
GROUP BY Dates.Ref,Dates.RowNo
) AS EarliestDates
ON EarliestDates.Ref = a.Ref
AND EarliestDates.RowNo = a.RowNo

-- WHERE a.Ref='707938-1106'

ORDER BY EarliestDates.EarliestDate ASC






GO
