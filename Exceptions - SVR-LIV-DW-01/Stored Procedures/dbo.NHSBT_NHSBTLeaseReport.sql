SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Author : Max Taylor
Date: 2021/06/10
Report - Initial Create NHSBT / NHSBT Lease Report

*/
CREATE  PROCEDURE [dbo].[NHSBT_NHSBTLeaseReport] 

@ReminderStartDate DATE, 
@ReminderEndDate DATE

AS 

BEGIN
--TESTING
--DECLARE @ReminderStartDate AS DATE = NULL
--DECLARE @ReminderEndDate AS DATE = NULL


IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
IF OBJECT_ID('tempdb..#FinalResults') IS NOT NULL DROP TABLE #FinalResults
IF OBJECT_ID('tempdb..#FinalResultsMAIN') IS NOT NULL DROP TABLE #FinalResultsMAIN
  

SELECT *,ROW_NUMBER() OVER (ORDER BY ref) AS RowNo
INTO #Results
FROM 

(SELECT DISTINCT header.master_client_code + '-' + header.master_matter_number [Ref],
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



IF @ReminderStartDate IS NULL

SELECT DISTINCT  a.Ref,
 ROW_NUMBER() OVER (PARTITION BY a.Ref ORDER BY a.Ref) RN ,
		matter_description,
       matter_owner_full_name,
       work_type_name,
       work_type_group,
       date_opened_case_management,
       notice_period,
       [reminder 1yr] = MIN([reminder 1yr]) OVER (PARTITION BY a.Ref),
       [reminder 6 mnth] =  MIN([reminder 6 mnth]) OVER (PARTITION BY a.Ref),
       [reminder 3 mnth] =  MIN([reminder 3 mnth]) OVER (PARTITION BY a.Ref),
       [reminder 1 week] = MIN([reminder 1 week]) OVER (PARTITION BY a.Ref),
       Date1,
       Date2,
       Date3,
       Date4,
       notice =  MIN(notice) OVER (PARTITION BY a.Ref),
       break_date =  MIN(break_date) OVER (PARTITION BY a.Ref),
       term_end_date =  MIN(term_end_date) OVER (PARTITION BY a.Ref),
       reminder_term_end_6mnth,
       reminder_term_end_1week,
       lease_expiry_date,
       rent_review_dates,
       completion_date,
       address,
       vacated_property,
       Internal,
 EarliestDates.EarliestDate

 INTO #FinalResultsMAIN  
 
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
ON EarliestDates.Ref = a.Ref AND EarliestDates.RowNo = a.RowNo

ORDER BY EarliestDates.EarliestDate ASC

IF @ReminderStartDate IS NULL

SELECT * FROM #FinalResultsMAIN WHERE RN = 1 

ELSE

SELECT distinct 
       ROW_NUMBER() OVER (PARTITION BY a.Ref ORDER BY a.Ref) RN ,
	   a.Ref,
		matter_description,
       matter_owner_full_name,
       work_type_name,
       work_type_group,
       date_opened_case_management,
       notice_period,
       [reminder 1yr] = MIN(a.[reminder 1yr]) OVER (PARTITION BY a.Ref),
       [reminder 6 mnth] =  MIN(a.[reminder 6 mnth]) OVER (PARTITION BY a.Ref),
       [reminder 3 mnth] = MIN(a.[reminder 3 mnth]) OVER (PARTITION BY a.Ref),
       [reminder 1 week] = MIN(a.[reminder 1 week]) OVER (PARTITION BY a.Ref),
       Date1 = MIN(Date1) OVER (PARTITION BY a.Ref) ,
       Date2 = MIN(Date2) OVER (PARTITION BY a.Ref),
       Date3 = MIN(Date3) OVER (PARTITION BY a.Ref),
       Date4 = MIN(Date4) OVER (PARTITION BY a.Ref),
       notice,
       break_date = MIN(break_date) OVER (PARTITION BY a.Ref) ,
       term_end_date,
       reminder_term_end_6mnth,
       reminder_term_end_1week,
       lease_expiry_date,
       rent_review_dates,
       completion_date,
       address,
       vacated_property,
       Internal,
       EarliestDate = MIN(EarliestDates.EarliestDate) OVER (PARTITION BY a.Ref)
 INTO #FinalResults
FROM #Results AS a
LEFT OUTER JOIN
(
SELECT DISTINCT Ref,Dates.RowNo,  MIN(EarliestDate) AS [EarliestDate]
FROM #Results
UNPIVOT
(
	EarliestDate
	FOR Dates IN (Date1, Date2, Date3, Date4)
) AS Dates
GROUP BY Dates.Ref,Dates.RowNo
) AS EarliestDates
ON EarliestDates.Ref = a.Ref AND EarliestDates.RowNo = a.RowNo

WHERE break_date BETWEEN COALESCE(@ReminderStartDate, break_date) AND COALESCE(@ReminderEndDate, break_date)  -- Added as per Ticket 48964

-- WHERE a.Ref='707938-1106'

ORDER BY a.Ref ASC

IF @ReminderStartDate IS not NULL

SELECT * FROM #FinalResults WHERE RN = 1 

END
GO
