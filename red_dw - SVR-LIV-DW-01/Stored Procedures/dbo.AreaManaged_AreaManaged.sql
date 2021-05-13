SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[AreaManaged_AreaManaged] @Username varchar(100) as

declare @UsernameTbl table (employeeid varchar(100), management_role_one varchar(100),  team varchar(100), department varchar(100), division varchar(100), firm varchar(100))

insert into @UsernameTbl 
select distinct employeeid, management_role_one, RTRIM(hierarchylevel4hist) AS hierarchylevel4hist, RTRIM(hierarchylevel3hist) AS hierarchylevel3hist, RTRIM(hierarchylevel2hist) AS hierarchylevel2hist, RTRIM(hierarchylevel1hist) AS hierarchylevel1hist from dim_fed_hierarchy_history
where windowsusername = @Username and activeud = 1 and dss_current_flag = 'Y'

														
/**********
		Divergent Hierarchy was created to cater 
		for people that manage more than one team.
		If the user exists in this table, run the below and stop.
		Otherwise, run everything from the next "else"

		Divergent Hierarchy is a manually updated tbl in Red
													****************/

if exists (select windowslogin from ds_mds_divergent_hierarchy where windowslogin = @Username) 
begin select mdx_string,sql_string from ds_mds_divergent_hierarchy where windowslogin = @Username 
end
else 

/**********
		SQL Code Generator
					****************/

begin
--Team Manager
if not exists (select management_role_one from @UsernameTbl where management_role_one in ('HoSD', 'Director')) begin

declare @TMCodeTbl table (empcode varchar(max)) 
insert into @TMCodeTbl
select dim_fed_hierarchy_history_key as 'empcode' from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.team = dim_fed_hierarchy_history.hierarchylevel4hist
						 and u.department = dim_fed_hierarchy_history.hierarchylevel3hist
						 and u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1

declare @TMSqlString varchar(max)
set @TMSqlString = (
select empcode + ',' as [text()]
from @TMCodeTbl
FOR XML PATH('')  
)

set @TMSqlString = stuff(@TMSqlString, len(@TMSqlString), 1, '') end



--HSD
if exists (select management_role_one from @UsernameTbl where management_role_one = 'HoSD') begin
declare @HSDCodeTbl table (empcode varchar(max)) 
insert into @HSDCodeTbl
select dim_fed_hierarchy_history_key as 'empcode' from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.department = dim_fed_hierarchy_history.hierarchylevel3hist
						 and u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1

declare @HSDSqlString varchar(max)
set @HSDSqlString = (
select empcode + ',' as [text()]
from @HSDCodeTbl
FOR XML PATH('')  
)

set @HSDSqlString = stuff(@HSDSqlString, len(@HSDSqlString), 1, '') end


--Director
if exists (select management_role_one from @UsernameTbl where management_role_one = 'Director') begin
declare @DirCodeTable table (empcode varchar(max)) 
insert into @DirCodeTable
select dim_fed_hierarchy_history_key as 'empcode' from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1

declare @DirSqlString varchar(max)
set @DirSqlString = (
select empcode + ',' as [text()]
from @DirCodeTable
FOR XML PATH('')  
)

set @DirSqlString = stuff(@DirSqlString, len(@DirSqlString), 1, '') end

end
/**********
	MAIN SECTION
		*********/


begin
--Team Manager
if not exists (select management_role_one from @UsernameTbl where management_role_one in ('HoSD', 'Director')) begin
select distinct
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Team].&['+
													            team + ']&[' +
																department + ']&[' +
																division   + ']&[' +
																firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  as mdx,
@TMSqlString as [sql]
from @UsernameTbl end

--HSD
if exists (select management_role_one from @UsernameTbl where management_role_one = 'HoSD') begin
select distinct
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+
																	   department + ']&[' +
																	   division   + ']&[' +
																	   firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  as mdx,
@HSDSqlString as [sql]
from @UsernameTbl end

--Director
if exists (select management_role_one from @UsernameTbl where management_role_one = 'Director') begin
select distinct
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Business Line].&['+
																	   division   + ']&[' +
																	   firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  as mdx,
@DirSqlString as [sql]
from @UsernameTbl end

end 


GO
GRANT EXECUTE ON  [dbo].[AreaManaged_AreaManaged] TO [db_ssrs_dynamicsecurity]
GO
