SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-07-10
-- Description:	this was created as katy wanted to see only working days for the figues of elapsed days
-- =============================================
-- LD commented out the dateclosed.calendardate bits in the where clause at the end
CREATE PROCEDURE [dbo].[TMKIS_Report_query]
	-- Add the parameters for the stored procedure here
	@startdate datetime,
	@enddate datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--DECLARE @startdate datetime = '20180401'
	--DECLARE @enddate datetime = '20190331'



	SET NOCOUNT ON;

SELECT  
fdm.client_code "dim_client[client_code]",
fdm.matter_number "dim_matter_header_current[matter_number]",
date_opened.calendar_date "dim_date_matter_opened_case_management[matter_opened_case_management_calendar_date]",
ddo.date_costs_settled "dim_detail_outcome[date_costs_settled]",
ddcd.motor_date_of_instructions_being_reopened "dim_detail_core_details[motor_date_of_instructions_being_reopened]",
ddcd.suspicion_of_fraud "dim_detail_core_details[suspicion_of_fraud]",
ddo.date_claim_concluded "dim_detail_outcome[date_claim_concluded]",
ddo.outcome_of_case "dim_detail_outcome[outcome_of_case]",
ffs.damages_reserve "fact_finance_summary[damages_reserve]",
ffs.defence_costs_billed "fact_finance_summary[defence_costs_billed]",
ffs.disbursements_billed "fact_finance_summary[disbursements_billed]",
date_closed.calendar_date "dim_date_matter_closed_case_management[matter_closed_case_management_calendar_date]",
ddl.repudiation "dim_detail_litigation[repudiation]",
ddcd.aig_grp_date_initial_acknowledgement_to_claims_handler "dim_detail_core_details[aig_grp_date_initial_acknowledgement_to_claims_handler]",
ddcd.date_initial_report_sent "dim_detail_core_details[date_initial_report_sent]",
ddpd.prev_date_subsequent_sla_report_sent "dim_detail_previous_details[prev_date_subsequent_sla_report_sent]",
ddcd.date_subsequent_sla_report_sent "dim_detail_core_details[date_subsequent_sla_report_sent]",
ddc.date_proceedings_issued "dim_detail_court[date_proceedings_issued]",
ddcd.date_the_closure_report_sent "dim_detail_core_details[date_the_closure_report_sent]",
dfhh.name "dim_fed_hierarchy_history_matter_owner[matter_owner_name]",
ddcd.referral_reason "dim_detail_core_details[referral_reason]",
dci.insurerclient_name "dim_client_involvement[insurerclient_name]",
ddclient.sabre_coop_fraudrmgendsleigh_complaints "dim_detail_client[sabre_coop_fraudrmgendsleigh_complaints]",
ddclient.date_of_complaint "dim_detail_client[date_of_complaint]",
'Q'+ CAST(date_opened.fin_quarter_no AS NVARCHAR(1))  ID_Quarter_Opened_,
CASE WHEN date_opened.fin_quarter_no  = 1 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Instructions_Received_Q1_",
CASE WHEN date_opened.fin_quarter_no  = 2 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Instructions_Received_Q2_",
CASE WHEN date_opened.fin_quarter_no  = 3 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Instructions_Received_Q3_",
CASE WHEN date_opened.fin_quarter_no  = 4 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Instructions_Received_Q4_",

CASE WHEN datecostfin.fin_quarter_no  = 1 AND datecostfin.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Concluded_Q1_",
CASE WHEN datecostfin.fin_quarter_no  = 2 AND datecostfin.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Concluded_Q2_",
CASE WHEN datecostfin.fin_quarter_no  = 3 AND datecostfin.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Concluded_Q3_",
CASE WHEN datecostfin.fin_quarter_no  = 4 AND datecostfin.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Concluded_Q4_",

CASE WHEN re_opened.fin_quarter_no  = 1 AND re_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Re_opened_Q1_",
CASE WHEN re_opened.fin_quarter_no  = 1 AND re_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Re_opened_Q2_",
CASE WHEN re_opened.fin_quarter_no  = 1 AND re_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Re_opened_Q3_",
CASE WHEN re_opened.fin_quarter_no  = 1 AND re_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Cases_Re_opened_Q4_",

CASE WHEN date_opened.fin_quarter_no  > 1 AND date_opened.fin_year = fin_year.fin_year THEN 0 when date_closed.calendar_date IS NULL OR (date_closed.calendar_date IS NOT NULL AND date_closed.fin_quarter_no  IN (2,3,4) AND date_closed.fin_year = fin_year.fin_year)  THEN 1 ELSE 0 END "ID_Open_Cases_Q1_",
CASE WHEN date_opened.fin_quarter_no  > 2 AND date_opened.fin_year = fin_year.fin_year THEN 0  when date_closed.calendar_date IS NULL  OR (date_closed.calendar_date IS NOT NULL AND date_closed.fin_quarter_no  IN (3,4) AND date_closed.fin_year = fin_year.fin_year)    THEN 1 ELSE 0 END "ID_Open_Cases_Q2_",
CASE WHEN date_opened.fin_quarter_no  > 3 AND date_opened.fin_year = fin_year.fin_year THEN 0  when date_closed.calendar_date IS NULL  OR (date_closed.calendar_date IS NOT NULL AND date_closed.fin_quarter_no  IN (4) AND date_closed.fin_year = fin_year.fin_year)    THEN 1 ELSE 0 END "ID_Open_Cases_Q3_",
CASE WHEN date_opened.fin_quarter_no  > 4 AND date_opened.fin_year = fin_year.fin_year THEN 0 when date_closed.calendar_date IS NULL   THEN 1 ELSE 0 END "ID_Open_Cases_Q4_",

CASE WHEN ddcd.suspicion_of_fraud = 'Yes' AND date_opened.fin_month_no >=1 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 end "ID_Open_Fraud_Cases_Q1_",
CASE WHEN ddcd.suspicion_of_fraud = 'Yes' AND date_opened.fin_month_no >=2 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 end "ID_Open_Fraud_Cases_Q2_",
CASE WHEN ddcd.suspicion_of_fraud = 'Yes' AND date_opened.fin_month_no >=3 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 end "ID_Open_Fraud_Cases_Q3_",
CASE WHEN ddcd.suspicion_of_fraud = 'Yes' AND date_opened.fin_month_no >=4 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 end "ID_Open_Fraud_Cases_Q4_",

CASE WHEN date_closed.calendar_date is NULL AND  datecliam_concluded.fin_month_no = 1 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Live_Concluded_Cases_Q1_",
CASE WHEN date_closed.calendar_date is NULL AND  datecliam_concluded.fin_month_no = 2 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Live_Concluded_Cases_Q2_",
CASE WHEN date_closed.calendar_date is NULL AND  datecliam_concluded.fin_month_no = 3 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Live_Concluded_Cases_Q3_",
CASE WHEN date_closed.calendar_date is NULL AND  datecliam_concluded.fin_month_no = 4 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Live_Concluded_Cases_Q4_",

CASE when date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' AND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 1 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Concluded_Fraud_Cases_Q1_",
CASE when date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' AND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 2 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Concluded_Fraud_Cases_Q2_",
CASE when date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' AND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 3 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Concluded_Fraud_Cases_Q3_",
CASE when date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' AND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 4 AND datecliam_concluded.fin_year = fin_year.fin_year THEN 1 ELSE 0 end  "ID_Concluded_Fraud_Cases_Q4_",

CASE WHEN date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' aND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 1 AND datecliam_concluded.fin_year = fin_year.fin_year THEN damages_reserve ELSE 0 end   "ID_Concluded_Fraud_Reserves_Q1_",
CASE WHEN date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' aND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 2 AND datecliam_concluded.fin_year = fin_year.fin_year THEN damages_reserve ELSE 0 end   "ID_Concluded_Fraud_Reserves_Q2_",
CASE WHEN date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' aND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 3 AND datecliam_concluded.fin_year = fin_year.fin_year THEN damages_reserve ELSE 0 end   "ID_Concluded_Fraud_Reserves_Q3_",
CASE WHEN date_closed.calendar_date is NULL AND ddl.repudiation LIKE '%Repudiated%' aND ddcd.suspicion_of_fraud = 'Yes' AND datecliam_concluded.fin_month_no = 4 AND datecliam_concluded.fin_year = fin_year.fin_year THEN damages_reserve ELSE 0 end   "ID_Concluded_Fraud_Reserves_Q4_",

CASE WHEN date_opened.fin_quarter_no = 1 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT null THEN  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *-1  ELSE 0 end "ID_Initial_Report_Sent_Q1_",
CASE WHEN date_opened.fin_quarter_no = 2 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT null THEN  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *-1  ELSE 0 end "ID_Initial_Report_Sent_Q2_",
CASE WHEN date_opened.fin_quarter_no = 3 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT null THEN  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *-1  ELSE 0 end "ID_Initial_Report_Sent_Q3_",
CASE WHEN date_opened.fin_quarter_no = 4 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT null THEN  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *-1  ELSE 0 end "ID_Initial_Report_Sent_Q4_",

CASE WHEN dateprocedingissued.fin_month_no = 1 AND dateprocedingissued.fin_year = fin_year.fin_year  THEN 1 ELSE 0 END "ID_Proceedings_Issued_Q1_",
CASE WHEN dateprocedingissued.fin_month_no = 2 AND dateprocedingissued.fin_year = fin_year.fin_year  THEN 1 ELSE 0 END "ID_Proceedings_Issued_Q2_",
CASE WHEN dateprocedingissued.fin_month_no = 3 AND dateprocedingissued.fin_year = fin_year.fin_year  THEN 1 ELSE 0 END "ID_Proceedings_Issued_Q3_",
CASE WHEN dateprocedingissued.fin_month_no = 4 AND dateprocedingissued.fin_year = fin_year.fin_year  THEN 1 ELSE 0 END "ID_Proceedings_Issued_Q4_",

CASE WHEN ddcd.referral_reason LIKE '%Recovery%' AND date_opened.fin_quarter_no  = 1 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Recovery_Cases_Q1_",
CASE WHEN ddcd.referral_reason LIKE '%Recovery%' AND date_opened.fin_quarter_no  = 2 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Recovery_Cases_Q2_",
CASE WHEN ddcd.referral_reason LIKE '%Recovery%' AND date_opened.fin_quarter_no  = 3 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Recovery_Cases_Q3_",
CASE WHEN ddcd.referral_reason LIKE '%Recovery%' AND date_opened.fin_quarter_no  = 4 AND date_opened.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Recovery_Cases_Q4_",

CASE WHEN ddclient.sabre_coop_fraudrmgendsleigh_complaints = 'Yes' AND dateofcomplaint.fin_month_no = 1 AND dateofcomplaint.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Complaints_Q1_", 
CASE WHEN ddclient.sabre_coop_fraudrmgendsleigh_complaints = 'Yes' AND dateofcomplaint.fin_month_no = 2 AND dateofcomplaint.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Complaints_Q2_" ,
CASE WHEN ddclient.sabre_coop_fraudrmgendsleigh_complaints = 'Yes' AND dateofcomplaint.fin_month_no = 3 AND dateofcomplaint.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Complaints_Q3_" ,
CASE WHEN ddclient.sabre_coop_fraudrmgendsleigh_complaints = 'Yes' AND dateofcomplaint.fin_month_no = 4 AND dateofcomplaint.fin_year = fin_year.fin_year THEN 1 ELSE 0 END "ID_Complaints_Q4_" ,

CASE WHEN date_opened.fin_quarter_no  = 1 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL THEN 1 ELSE 0 end "ID_Initail_Report_SLA_Q1_",
CASE WHEN date_opened.fin_quarter_no  = 1 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL and reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 < 31 AND  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 > 0 THEN 1 ELSE 0 end "ID_Initail_Report_within_SLA_Q1_",
CASE WHEN date_opened.fin_quarter_no  = 2 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL THEN 1 ELSE 0 end "ID_Initail_Report_SLA_Q2_",
CASE WHEN date_opened.fin_quarter_no  = 2 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL and reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 < 31 AND  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 > 0 THEN 1 ELSE 0 end "ID_Initail_Report_within_SLA_Q2_",
CASE WHEN date_opened.fin_quarter_no  = 3 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL THEN 1 ELSE 0 end "ID_Initail_Report_SLA_Q3_",
CASE WHEN date_opened.fin_quarter_no  = 3 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL and reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 < 31 AND  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 > 0 THEN 1 ELSE 0 end "ID_Initail_Report_within_SLA_Q3_",
CASE WHEN date_opened.fin_quarter_no  = 4 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL THEN 1 ELSE 0 end "ID_Initail_Report_SLA_Q4_",
CASE WHEN date_opened.fin_quarter_no  = 4 AND date_opened.fin_year = fin_year.fin_year AND ddcd.date_initial_report_sent IS NOT NULL and reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 < 31 AND  reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date) *- 1 > 0 THEN 1 ELSE 0 end "ID_Initail_Report_within_SLA_Q4_",


CASE WHEN ddcd.aig_grp_date_initial_acknowledgement_to_claims_handler IS NULL THEN NULL ELSE reporting.[dbo].[getWeekdays](ddcd.aig_grp_date_initial_acknowledgement_to_claims_handler,date_opened.calendar_date) * -1 end "ID_Days_to_Acknowledge_",
CASE WHEN ddcd.date_initial_report_sent IS NULL THEN NULL ELSE reporting.[dbo].[getWeekdays](ddcd.date_initial_report_sent,date_opened.calendar_date)  * -1 end "ID_Days_to_Send_Initial_Report_",
CASE WHEN ddcd.date_subsequent_sla_report_sent IS NULL THEN NULL ELSE reporting.[dbo].[getWeekdays](ddcd.date_subsequent_sla_report_sent,date_opened.calendar_date)  * -1 end  "ID_Days_to_Subsquent_Report_Sent_",
CASE WHEN ddc.date_proceedings_issued IS NULL THEN null ELSE reporting.[dbo].[getWeekdays](ddc.date_proceedings_issued,date_opened.calendar_date)  * -1 end "ID_Days_to_Proceedings_Issued__",
CASE WHEN ddcd.date_the_closure_report_sent IS NULL THEN null ELSE reporting.[dbo].[getWeekdays](ddcd.date_the_closure_report_sent,date_opened.calendar_date)  * -1 end "ID_Days_to_Closure_Report_Sent_"

FROM 
red_Dw.dbo.fact_dimension_main fdm
LEFT JOIN red_Dw.dbo.dim_matter_header_current dmhc ON dmhc.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_date date_opened ON date_opened.dim_date_key = fdm.dim_open_case_management_date_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ddo ON ddo.dim_detail_outcome_key = fdm.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_detail_core_details ddcd ON ddcd.dim_detail_core_detail_key = fdm.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_detail_litigation ddl ON ddl.dim_detail_litigation_key = fdm.dim_detail_litigation_key
LEFT JOIN red_Dw.dbo.fact_finance_summary ffs ON ffs.master_fact_key = fdm.master_fact_key
LEFT JOIN red_Dw.dbo.dim_detail_previous_details ddpd ON ddpd.dim_detail_previous_details_key = fdm.dim_detail_previous_details_key
LEFT JOIN red_dw.dbo.dim_detail_court ddc ON ddc.dim_detail_court_key = fdm.dim_detail_court_key
LEFT JOIN red_Dw.dbo.dim_detail_client ddclient ON ddclient.dim_detail_client_key = fdm.dim_detail_client_key
LEFT JOIN red_dw.dbo.dim_date date_closed ON date_closed.dim_date_key = fdm.dim_closed_case_management_date_key AND fdm.dim_closed_case_management_date_key <> 0
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history dfhh ON dfhh.dim_fed_hierarchy_history_key = fdm.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_client_involvement dci ON dci.dim_client_involvement_key = fdm.dim_client_involvement_key
LEFT JOIN red_Dw.dbo.dim_date fin_year ON CAST(fin_year.calendar_date AS DATE) = CAST(GETDATE() AS DATE)
LEFT JOIN red_Dw.dbo.dim_date datecostfin ON CAST(datecostfin.calendar_date AS DATE) = CAST(ddo.date_costs_settled  AS DATE)
LEFT JOIN red_Dw.dbo.dim_date re_opened ON CAST(re_opened.calendar_date AS DATE) = CAST(ddcd.motor_date_of_instructions_being_reopened  AS DATE)
LEFT JOIN red_Dw.dbo.dim_date datecliam_concluded ON  CAST(datecliam_concluded.calendar_date AS DATE) = CAST(ddo.date_claim_concluded  AS DATE)
LEFT JOIN red_Dw.dbo.dim_date dateprocedingissued ON  CAST(dateprocedingissued.calendar_date AS DATE) = CAST(ddc.date_proceedings_issued  AS DATE)
LEFT JOIN red_Dw.dbo.dim_date dateofcomplaint ON  CAST(dateofcomplaint.calendar_date AS DATE) = CAST(ddclient.date_of_complaint  AS DATE)
WHERE 
(dmhc.reporting_exclusions = 0 AND fdm.client_code IN ('00116723','00593153','T15036','W15693'))
AND
(
 date_closed.calendar_date IS null OR ddo.date_claim_concluded >= '2017-01-01'
) --AND
--date_closed.calendar_date =  @startdate
--AND 
--date_closed.calendar_date = @enddate
--AND dci.matter_number = '00000012'
ORDER BY date_opened.calendar_date 
END
GO
