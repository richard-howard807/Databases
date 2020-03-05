SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--DECLARE @Username VARCHAR(100) = 'gbrenn'
CREATE procedure [dbo].[HierarchyAreaManaged] 
@Username varchar(100) as
SELECT DISTINCT
    @Username 'windowsusername',
	'[Dim Fed Hierarchy History].[Hierarchy].[Team].&[' + hierarchylevel4hist + ']&[' + hierarchylevel3hist + ']&[' + hierarchylevel2hist + ']&[' + hierarchylevel1hist + ']' + ',' AS bcmstring
	
into #bcmtemp
FROM red_dw.dbo.dim_fed_hierarchy_history hierarchy
WHERE (
		hierarchy.dss_current_flag = 'Y'
		--and hierarchy.activeud = 1
		AND hierarchy.hierarchylevel2hist IN (
			SELECT DISTINCT hier.hierarchylevel2hist
			FROM red_dw.dbo.ds_sh_employee emp
			LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history hier ON (
					(
						UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
						OR UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid)
						)
					OR UPPER(emp.employeeid) = UPPER(hier.employeeid)
					)
				AND hier.dss_current_flag = 'Y'
				AND hier.activeud = 1
			WHERE emp.dss_current_flag = 'Y'
				AND emp.windowsusername = @Username
			)
		AND hierarchy.hierarchylevel3hist IN (
			SELECT DISTINCT hier.hierarchylevel3hist
			FROM red_dw.dbo.ds_sh_employee emp
			LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history hier ON (
					(
						UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
						OR UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid)
						)
					OR UPPER(emp.employeeid) = UPPER(hier.employeeid)
					)
				AND hier.dss_current_flag = 'Y'
				AND hier.activeud = 1
			WHERE emp.dss_current_flag = 'Y'
				AND emp.windowsusername = @Username
			)
		AND hierarchy.hierarchylevel4hist IN (
			SELECT DISTINCT hier.hierarchylevel4hist
			FROM red_dw.dbo.ds_sh_employee emp
			LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history hier ON (
					(
						UPPER(emp.employeeid) = UPPER(hier.reportingbcmidud)
						OR UPPER(emp.employeeid) = UPPER(hier.worksforemployeeid)
						)
					OR UPPER(emp.employeeid) = UPPER(hier.employeeid)
					)
				AND hier.dss_current_flag = 'Y'
				AND hier.activeud = 1
			WHERE emp.dss_current_flag = 'Y'
				AND emp.windowsusername = @Username
			)
		)
-- above where clause taken from old hierarchy proc. unsure if this can be simplified or not to be honest
-- puts all relevant team heirarchy strings into a table where a fee earner's reportingbcmid, worksforemployeeid or own employeeid is the current user

declare @BCMString varchar(max) 
select @BCMString = CONVERT(VarChar(MAX), (
select distinct bcmstring as [text()]
from #bcmtemp
where bcmstring not like '%Unknown%'
FOR XML PATH('') )) 
-- concatenate all teams into one string

set @BCMString = replace(@BCMString, '&amp;', '&')
set @BCMString = 'descendants({' + LEFT(@BCMString, LEN(@BCMString) - 1) + '}, 2)'
-- data cleanse & mdx formatting

select @BCMString

drop table #bcmtemp
GO
