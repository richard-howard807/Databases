SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[stp_employee_appraisals]
AS 
BEGIN

SELECT 
	dim_fed_hierarchy_history.name		AS employee
	, dim_fed_hierarchy_history.hierarchylevel4hist		AS team
	, dim_fed_hierarchy_history.hierarchylevel3hist		AS department
	, dim_fed_hierarchy_history.hierarchylevel2hist		AS division
	, dim_employee_appraisal.dim_employee_appraisal_key
    , dim_employee_appraisal.dim_employee_key
    , dim_employee_appraisal.effectivedate_first_key
    , dim_employee_appraisal.year_of_review
    , dim_employee_appraisal.effectivedate_first
    , dim_employee_appraisal.effectivedate_all
    , dim_employee_appraisal.date_of_q1_review
    , dim_employee_appraisal.date_of_q1_sign_off
    , dim_employee_appraisal.q1_rating
    , dim_employee_appraisal.date_of_q2_review
    , dim_employee_appraisal.date_of_q2_sign_off
    , dim_employee_appraisal.q2_rating
    , dim_employee_appraisal.date_of_q3_review
    , dim_employee_appraisal.date_of_q3_sign_off
    , dim_employee_appraisal.q3_rating
    , dim_employee_appraisal.date_of_q4_review
    , dim_employee_appraisal.date_of_q4_sign_off
    , dim_employee_appraisal.q4_rating
    , dim_employee_appraisal.overall_annual_rating
    , dim_employee_appraisal.appraisal_end_of_year_sign_off_date
    , dim_employee_appraisal.appraisal_start_of_year_sign_off_date	
FROM red_dw.dbo.dim_employee_appraisal	WITH (NOLOCK) 
	INNER JOIN red_dw.dbo.dim_employee	WITH (NOLOCK) 
		ON dim_employee.dim_employee_key = dim_employee_appraisal.dim_employee_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history	 WITH (NOLOCK) 
		ON dim_fed_hierarchy_history.fed_code = dim_employee.payrollid
			AND dim_fed_hierarchy_history.dss_current_flag = 'Y'

END

GO
