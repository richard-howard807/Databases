SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--EXEC [dbo].[AreaManaged_AreaManaged] 'asteve'

CREATE procedure [dbo].[AreaManaged_AreaManaged] @Username varchar(100) as

--DECLARE @Username AS NVARCHAR(100) = 'asteve'

--SET @Username = IIF (@Username = '7242', 'agill', @Username)
--SET @Username = IIF (@Username = '7242', 'nodono', @Username)

DECLARE @UsernameTbl TABLE (employeeid VARCHAR(100), management_role_one VARCHAR(100),  team VARCHAR(100), department VARCHAR(100), division VARCHAR(100), firm VARCHAR(100))

INSERT INTO @UsernameTbl 
SELECT DISTINCT employeeid, management_role_one, RTRIM(hierarchylevel4hist) AS hierarchylevel4hist, RTRIM(hierarchylevel3hist) AS hierarchylevel3hist, RTRIM(hierarchylevel2hist) AS hierarchylevel2hist, RTRIM(hierarchylevel1hist) AS hierarchylevel1hist FROM dim_fed_hierarchy_history
WHERE windowsusername = @Username and activeud = 1 and dss_current_flag = 'Y'

	
-- Added 27/01/2022 to handle people who now manage more than one team	
union 

select distinct (select employeeid from dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history.windowsusername = 'ahadad' and activeud = 1 and dss_current_flag = 'Y'), 
			    (select dim_fed_hierarchy_history.management_role_one from dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history.windowsusername = 'ahadad' and activeud = 1 and dss_current_flag = 'Y'), 
	rtrim(hierarchylevel4hist) AS hierarchylevel4hist, RTRIM(hierarchylevel3hist) AS hierarchylevel3hist, RTRIM(hierarchylevel2hist) AS hierarchylevel2hist, RTRIM(hierarchylevel1hist) AS hierarchylevel1hist from dim_fed_hierarchy_history
where dim_fed_hierarchy_history.reportingbcmidud in (select employeeid from dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history.windowsusername = @Username and activeud = 1 and dss_current_flag = 'Y')
and activeud = 1 and dss_current_flag = 'Y'

union 

select distinct (select employeeid from dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history.windowsusername = 'ahadad' and activeud = 1 and dss_current_flag = 'Y'), 
			    (select dim_fed_hierarchy_history.management_role_one from dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history.windowsusername = 'ahadad' and activeud = 1 and dss_current_flag = 'Y'), 
	rtrim(hierarchylevel4hist) AS hierarchylevel4hist, RTRIM(hierarchylevel3hist) AS hierarchylevel3hist, RTRIM(hierarchylevel2hist) AS hierarchylevel2hist, RTRIM(hierarchylevel1hist) AS hierarchylevel1hist from dim_fed_hierarchy_history
where dim_fed_hierarchy_history.worksforemployeeid in (select employeeid from dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history.windowsusername = @Username and activeud = 1 and dss_current_flag = 'Y')
and activeud = 1 and dss_current_flag = 'Y'

/**********
		Divergent Hierarchy was created to cater 
		for people that manage more than one team.
		If the user exists in this table, run the below and stop.
		Otherwise, run everything from the next "else"

		Divergent Hierarchy is a manually updated tbl in Red
													****************/

if exists (select windowslogin from ds_mds_divergent_hierarchy where windowslogin = @Username) 
begin select mdx_string,sql_string, ds_mds_divergent_hierarchy.dax_string from ds_mds_divergent_hierarchy where windowslogin = @Username 
end
else 

/**********
		SQL Code Generator
					****************/

begin
--Team Manager
if not exists (select management_role_one from @UsernameTbl where management_role_one in ('HoSD', 'Director')) begin



declare @TMCodeTbl table (empcode varchar(max), fed_code VARCHAR(MAX),  team varchar(100), department varchar(100), division varchar(100), firm varchar(100)) 
insert into @TMCodeTbl
select dim_fed_hierarchy_history_key as 'empcode',
	dim_fed_hierarchy_history.fed_code + CAST(dim_fed_hierarchy_history.dim_fed_hierarchy_history_key AS NVARCHAR(20))	AS fed_code,
	rtrim(dim_fed_hierarchy_history.hierarchylevel4hist) team, 
	rtrim(dim_fed_hierarchy_history.hierarchylevel3hist) department,
	rtrim(dim_fed_hierarchy_history.hierarchylevel2hist) division, 
	rtrim(dim_fed_hierarchy_history.hierarchylevel1hist) firm
from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.team = dim_fed_hierarchy_history.hierarchylevel4hist
						 and u.department = dim_fed_hierarchy_history.hierarchylevel3hist
						 and u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1

/*

-- Removed 27/01/2022 as wasn't working for people who now manage more than one team

union all

select dim_fed_hierarchy_history_key as 'empcode', 
	rtrim(dim_fed_hierarchy_history.hierarchylevel4hist) team, 
	rtrim(dim_fed_hierarchy_history.hierarchylevel3hist) department,
	rtrim(dim_fed_hierarchy_history.hierarchylevel2hist) division, 
	rtrim(dim_fed_hierarchy_history.hierarchylevel1hist) firm
from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.employeeid = dim_fed_hierarchy_history.worksforemployeeid
						 and u.team <> dim_fed_hierarchy_history.hierarchylevel4hist
						 and u.department = dim_fed_hierarchy_history.hierarchylevel3hist
						 and u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1
						 and dim_fed_hierarchy_history.dss_current_flag = 'Y'
						 and dim_fed_hierarchy_history.leaver = 0

union all

select dim_fed_hierarchy_history_key as 'empcode', 
	rtrim(dim_fed_hierarchy_history.hierarchylevel4hist) team, 
	rtrim(dim_fed_hierarchy_history.hierarchylevel3hist) department,
	rtrim(dim_fed_hierarchy_history.hierarchylevel2hist) division, 
	rtrim(dim_fed_hierarchy_history.hierarchylevel1hist) firm
from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.employeeid = dim_fed_hierarchy_history.reportingbcmidud
						 and u.team <> dim_fed_hierarchy_history.hierarchylevel4hist
						 and dim_fed_hierarchy_history.worksforemployeeid <> u.employeeid
						 and u.department = dim_fed_hierarchy_history.hierarchylevel3hist
						 and u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1
						 and dim_fed_hierarchy_history.dss_current_flag = 'Y'
						 and dim_fed_hierarchy_history.leaver = 0
*/


declare @TMSqlString varchar(max)
set @TMSqlString = (
select empcode + ',' as [text()]
from @TMCodeTbl
FOR XML PATH('')  
)
declare @TMDaxString varchar(max)
set @TMDaxString = (
select [@TMCodeTbl].fed_code + '|' as [text()]
from @TMCodeTbl
FOR XML PATH('')  
)

set @TMSqlString = stuff(@TMSqlString, len(@TMSqlString), 1, '') 
set @TMDaxString = stuff(@TMDaxString, len(@TMDaxString), 1, '') end


--HSD
if exists (select management_role_one from @UsernameTbl where management_role_one = 'HoSD') begin
declare @HSDCodeTbl table (empcode varchar(max), fed_code VARCHAR(MAX)) 
insert into @HSDCodeTbl
select distinct dim_fed_hierarchy_history_key as 'empcode', dim_fed_hierarchy_history.fed_code + CAST(dim_fed_hierarchy_history.dim_fed_hierarchy_history_key AS NVARCHAR(20)) from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.department = dim_fed_hierarchy_history.hierarchylevel3hist
						 and u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1

declare @HSDSqlString varchar(max)
set @HSDSqlString = (
select empcode + ',' as [text()]
from @HSDCodeTbl
FOR XML PATH('')  
)
declare @HSDDaxString varchar(max)
set @HSDDaxString = (
select [@HSDCodeTbl].fed_code + '|' as [text()]
from @HSDCodeTbl
FOR XML PATH('')  
)

set @HSDSqlString = stuff(@HSDSqlString, len(@HSDSqlString), 1, '') 
set @HSDDaxString = stuff(@HSDDaxString, len(@HSDDaxString), 1, '') end

--Director
if exists (select management_role_one from @UsernameTbl where management_role_one = 'Director') begin
declare @DirCodeTable table (empcode varchar(max), fed_code VARCHAR(MAX)) 
insert into @DirCodeTable
select distinct dim_fed_hierarchy_history_key as 'empcode', dim_fed_hierarchy_history.fed_code + CAST(dim_fed_hierarchy_history.dim_fed_hierarchy_history_key AS NVARCHAR(20)) AS fed_code from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1

declare @DirSqlString varchar(max)
set @DirSqlString = (
select empcode + ',' as [text()]
from @DirCodeTable
FOR XML PATH('')  
)
declare @DirDaxString varchar(max)
set @DirDaxString = (
select [@DirCodeTable].fed_code + '|' as [text()]
from @DirCodeTable
FOR XML PATH('')  
)

set @DirSqlString = stuff(@DirSqlString, len(@DirSqlString), 1, '') 
set @DirDaxString = stuff(@DirDaxString, len(@DirDaxString), 1, '') end

end
/**********
	MAIN SECTION
		*********/


begin
--Team Manager
if not exists (select management_role_one from @UsernameTbl where management_role_one in ('HoSD', 'Director')) begin

	select distinct
	'descendants( {' 
		+ string_agg('[Dim Fed Hierarchy History].[Hierarchy].[Team].&['+
																	cast(team as varchar(max)) + ']&[' +
																	cast(department as varchar(max)) + ']&[' +
																	cast(division as varchar(max))   + ']&[' +
																	cast(firm as varchar(max)) + ']', ', ')
	+ ' } ,  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  as mdx,
	@TMSqlString as [sql],
	@TMDaxString as dax
	
	from (	select distinct team, department, division, firm
			from @TMCodeTbl ) TMCodeTbl 
	group by firm

 end

--HSD
if exists (select management_role_one from @UsernameTbl where management_role_one = 'HoSD') begin
select distinct
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+
																	   department + ']&[' +
																	   division   + ']&[' +
																	   firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  as mdx,
@HSDSqlString as [sql],
@HSDDaxString		AS dax
from @UsernameTbl end

--Director
if exists (select management_role_one from @UsernameTbl where management_role_one = 'Director') begin
select distinct
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Business Line].&['+
																	   division   + ']&[' +
																	   firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  as mdx,
@DirSqlString as [sql],
@DirDaxString		AS dax
from @UsernameTbl end

end 


GO
GRANT EXECUTE ON  [dbo].[AreaManaged_AreaManaged] TO [db_ssrs_dynamicsecurity]
GO
