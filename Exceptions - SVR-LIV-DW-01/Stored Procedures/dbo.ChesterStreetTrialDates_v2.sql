SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
CREATE PROCEDURE [dbo].[ChesterStreetTrialDates_v2](  --EXEC [dbo].[ChesterStreetTrialDates] '20160725'
	@RunDate DATE,
	@report INT
	)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


----DECLARE @RunDate AS DATE-- = GETDATE()

----SET @RunDate = '20160711'

--SELECT    a.client_code,    b.insurerclient_reference AS [Capita Claim Ref], c.claimant_name AS [Claimant Name], COALESCE (a.trial_due_date, a.disposal_hearing_date) AS Trial_Date, 
--                         a.first_day_date AS Trial_Window
--FROM            red_dw.dbo.dim_trial_date AS a 
--LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON a.client_code=dim_detail_outcome.client_code AND a.matter_number=dim_detail_outcome.matter_number
--LEFT OUTER JOIN
--                         red_dw.dbo.dim_client_involvement AS b ON b.client_code = a.client_code AND b.matter_number = a.matter_number LEFT OUTER JOIN
--                         red_dw.dbo.dim_claimant_thirdparty_involvement AS c ON c.client_code = a.client_code AND c.matter_number = a.matter_number
--WHERE outcome_of_case IS NULL AND date_claim_concluded IS NULL AND 
-- ( (a.trial_due_processed_date < @RunDate) AND (DATEDIFF(DAY, a.trial_due_processed_date, @RunDate) <= 7) AND (a.trial_due_date IS NOT NULL) OR
--                         (a.disposal_hearing_processed_date < @RunDate) AND (DATEDIFF(DAY, a.disposal_hearing_processed_date, @RunDate) <= 7) AND 
--                         (a.disposal_hearing_date IS NOT NULL) OR
--                         (a.trial_start_processed_date < @RunDate) AND (DATEDIFF(DAY, a.trial_start_processed_date, @RunDate) <= 7) AND (a.trial_start_date IS NOT NULL) OR
--                         (a.trial_end_processed_date < @RunDate) AND (DATEDIFF(DAY, a.trial_end_processed_date, @RunDate) <= 7) AND (a.trial_end_date IS NOT NULL) OR
--                         (a.first_day_processed_date < @RunDate) AND (DATEDIFF(DAY, a.first_day_processed_date, @RunDate) <= 7) AND (a.first_day_date IS NOT NULL)
--						) and case when @report = 1 and a.client_code in ('00046253','00337896','W15373')  then 1
--								when  @report = 2 and a.client_code in ('00516705', '00560475', 'W15349') then 1 else 0  end =1 

SELECT    dim_matter_header_current.client_code, master_client_code+ '-'+ master_matter_number [MS Ref]
,    b.insurerclient_reference AS [Capita Claim Ref], c.claimant_name AS [Claimant Name]
, date_of_trial AS Trial_Date
,date_of_first_day_of_trial_window AS Trial_Window
--,'MI Detail' source
						 FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_matter_header_current.client_code=dim_detail_outcome.client_code AND dim_matter_header_current.matter_number=dim_detail_outcome.matter_number
LEFT OUTER JOIN
                         red_dw.dbo.dim_client_involvement AS b ON b.client_code = dim_matter_header_current.client_code AND b.matter_number = dim_matter_header_current.matter_number LEFT OUTER JOIN
                         red_dw.dbo.dim_claimant_thirdparty_involvement AS c ON c.client_code = dim_matter_header_current.client_code AND c.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client_code, matter_number, date_of_trial
FROM red_dw.dbo.dim_detail_previous_details
WHERE DATEDIFF(DAY, date_of_trial_changed, @RunDate) <= 7
) AS TrialDate
 ON TrialDate.client_code = dim_matter_header_current.client_code
 AND TrialDate.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN (SELECT 
client_code, matter_number, date_of_first_day_of_trial_window 
FROM red_dw.dbo.dim_detail_previous_details
WHERE DATEDIFF(DAY, date_of_first_day_of_trial_window_changed, @RunDate) <= 7
) AS  Window
 ON Window.client_code = dim_matter_header_current.client_code
 AND Window.matter_number = dim_matter_header_current.matter_number
WHERE outcome_of_case IS NULL AND date_claim_concluded IS NULL 
AND (date_of_trial IS NOT NULL OR date_of_first_day_of_trial_window IS NOT NULL)
AND  CASE WHEN @report = 1 AND dim_matter_header_current.client_code IN ('00046253','00337896','W15373')  THEN 1
								WHEN  @report = 2 AND dim_matter_header_current.client_code IN ('00516705', '00560475', 'W15349') THEN 1 ELSE 0  END =1

UNION


SELECT    dim_matter_header_current.client_code, master_client_code+ '-'+ master_matter_number [MS Ref]
,    b.insurerclient_reference AS [Capita Claim Ref], c.claimant_name AS [Claimant Name]
, date_of_trial AS Trial_Date
,date_of_first_day_of_trial_window AS Trial_Window
--,'KeyDate'
						 FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_matter_header_current.client_code=dim_detail_outcome.client_code AND dim_matter_header_current.matter_number=dim_detail_outcome.matter_number
LEFT OUTER JOIN
                         red_dw.dbo.dim_client_involvement AS b ON b.client_code = dim_matter_header_current.client_code AND b.matter_number = dim_matter_header_current.matter_number LEFT OUTER JOIN
                         red_dw.dbo.dim_claimant_thirdparty_involvement AS c ON c.client_code = dim_matter_header_current.client_code AND c.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT   dbTasks.fileID
	,tskDue AS  date_of_trial 
	FROM  MS_Prod.dbo.dbTasks
								 INNER JOIN ms_prod.dbo.dbKeyDates ON kdRelatedID = tskRelatedID
								 WHERE kdType IN ('TRIAL') 
								 								 AND LOWER(tskDesc) LIKE '%today%'
																 --AND tskActive = 1#
																 AND dbTasks.tskActive = 1 AND DATEDIFF(DAY,  dbKeyDates.Created, @RunDate) <= 7 
																 ) trail_date  ON trail_date.fileID = ms_fileid
LEFT OUTER JOIN (SELECT  dbTasks.fileID
	,tskDue AS  date_of_first_day_of_trial_window 
	FROM  MS_Prod.dbo.dbTasks
								 INNER JOIN ms_prod.dbo.dbKeyDates ON kdRelatedID = tskRelatedID
								 WHERE kdType IN ('TRIALWINDOW') 
								 								 AND LOWER(tskDesc) LIKE '%today%'
																 --AND tskActive = 1#
																 AND dbTasks.tskActive = 1 AND DATEDIFF(DAY,  dbKeyDates.Created, @RunDate) <= 7  
																 ) trail_window ON trail_window.fileID = ms_fileid

WHERE outcome_of_case IS NULL AND date_claim_concluded IS NULL 
AND (date_of_trial IS NOT NULL OR date_of_first_day_of_trial_window IS NOT NULL)
AND  CASE WHEN @report = 1 AND dim_matter_header_current.client_code IN ('00046253','00337896','W15373')  THEN 1
								WHEN  @report = 2 AND dim_matter_header_current.client_code IN ('00516705', '00560475', 'W15349') THEN 1 ELSE 0  END =1
								 
END

GO
