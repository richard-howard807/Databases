SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Orlagh Kelly
-- Create date: 23-03-2020
-- Description:	 richard howard primary made and converted into SP as security would not work 
-- =============================================

CREATE PROCEDURE [dbo].[LMScourseprogress]
(
    @FedCode AS VARCHAR(MAX),
    --@Month AS VARCHAR(100)
    @Level AS VARCHAR(100), 
	@Type AS NVARCHAR(MAX) , 
	@Status AS NVARCHAR(MAX),
	@Courses AS NVARCHAR (MAX)

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
	
	END







--------------------------------------------------------------------------

--declare @fedcode_table table (fedcode int)

--if left(@FEDCode, 1) = '('

--	begin 
--		insert into @fedcode_table
--		select dim_fed_hierarchy_history_key 		
--		from dbo.dim_fed_hierarchy_history

--	end
	
--	else 

--		insert into @fedcode_table
--		select cast(val as int) dim_fed_hierarchy_history_key
--		from split_delimited_to_rows(@FEDCodes,',')


--------------------------------------------------
select a.dim_lms_user_course_key,
a.client_user_identifier, c.fed_code, c.display_name Display_Name, c.name, 
	c.hierarchylevel2 Business_Line, c.hierarchylevel3 Practice_Area, c.hierarchylevel4 Team,
	d.course_name, 
	case when d.category is null and d.subcategory = 'IT Training' then 'IT Training'
		 when d.category is null then isnull(d.subcategory,'Unknown')
		 else d.category end category,
	isnull(d.subcategory,'Unknown') subcategory,
	a.history_status, a.course_start_date_time, a.course_end_date_time,
	b.duration_mins, b.score,
	tries.total_attempts
-- select *
from red_dw.dbo.dim_lms_user_course a
inner join red_dw.dbo.fact_lms_user_course b on a.dim_lms_user_course_key = b.dim_lms_user_course_key
inner join red_dw.dbo.dim_employee e on e.dim_employee_key = a.dim_employee_key
inner join red_Dw.dbo.dim_fed_hierarchy_current c on c.employeeid = e.employeeid
inner join red_dw.dbo.dim_lms_courses d on d.dim_lms_courses_key = a.dim_lms_courses_key
--LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = a.dim_fed_hierarchy_history_key
left outer join
	(select dim_lms_courses_key, dim_employee_key, count(dim_lms_courses_key) total_attempts 
	from red_Dw.dbo.dim_lms_user_course
	group by dim_lms_courses_key, dim_employee_key) tries on tries.dim_lms_courses_key = a.dim_lms_courses_key 
								  and tries.dim_employee_key = a.dim_employee_key
where  a.latest_attempt = 1
and e.leftdate is null
and iif(score is not null, 'Assessment', 'Course') in (@Type)
and history_status in (@Status)
and d.dim_lms_courses_key in (@Courses)

  AND a.dim_fed_hierarchy_history_key IN
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
GO
