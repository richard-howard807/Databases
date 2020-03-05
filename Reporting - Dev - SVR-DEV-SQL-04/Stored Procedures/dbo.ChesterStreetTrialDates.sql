SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ChesterStreetTrialDates](  --EXEC [dbo].[ChesterStreetTrialDates] '20160725'
	@RunDate DATE,
	@report int
	)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--DECLARE @RunDate AS DATE-- = GETDATE()

--SET @RunDate = '20160711'

SELECT    a.client_code,    b.insurerclient_reference AS [Capita Claim Ref], c.claimant_name AS [Claimant Name], COALESCE (a.trial_due_date, a.disposal_hearing_date) AS Trial_Date, 
                         a.first_day_date AS Trial_Window
FROM            red_dw.dbo.dim_trial_date AS a LEFT OUTER JOIN
                         red_dw.dbo.dim_client_involvement AS b ON b.client_code = a.client_code AND b.matter_number = a.matter_number LEFT OUTER JOIN
                         red_dw.dbo.dim_claimant_thirdparty_involvement AS c ON c.client_code = a.client_code AND c.matter_number = a.matter_number
WHERE       ( (a.trial_due_processed_date < @RunDate) AND (DATEDIFF(DAY, a.trial_due_processed_date, @RunDate) <= 7) AND (a.trial_due_date IS NOT NULL) OR
                         (a.disposal_hearing_processed_date < @RunDate) AND (DATEDIFF(DAY, a.disposal_hearing_processed_date, @RunDate) <= 7) AND 
                         (a.disposal_hearing_date IS NOT NULL) OR
                         (a.trial_start_processed_date < @RunDate) AND (DATEDIFF(DAY, a.trial_start_processed_date, @RunDate) <= 7) AND (a.trial_start_date IS NOT NULL) OR
                         (a.trial_end_processed_date < @RunDate) AND (DATEDIFF(DAY, a.trial_end_processed_date, @RunDate) <= 7) AND (a.trial_end_date IS NOT NULL) OR
                         (a.first_day_processed_date < @RunDate) AND (DATEDIFF(DAY, a.first_day_processed_date, @RunDate) <= 7) AND (a.first_day_date IS NOT NULL)
						) and case when @report = 1 and a.client_code in ('00046253','00337896','W15373')  then 1
								when  @report = 2 and a.client_code in ('00516705', '00560475', 'W15349') then 1 else 0  end =1  
END

GO
