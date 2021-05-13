SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[AreaManaged_AreaManaged_050719] @Username VARCHAR(100) AS

declare @UsernameTbl table (employeeid varchar(100), management_role_one varchar(100),  team varchar(100), department varchar(100), division varchar(100), firm varchar(100))

insert into @UsernameTbl 
select distinct employeeid, management_role_one, hierarchylevel4hist, hierarchylevel3hist, hierarchylevel2hist, hierarchylevel1hist from dim_fed_hierarchy_history
where windowsusername = @Username and activeud = 1 and dss_current_flag = 'Y'

														
/**********
		Divergent Hierarchy was created to cater 
		for people that manage more than one team.
		If the user exists in this table, run the below and stop.
		Otherwise, run everything from the next "else"

		Divergent Hierarchy is a manually updated tbl in Red
													****************/

IF EXISTS (SELECT windowslogin FROM ds_mds_divergent_hierarchy WHERE windowslogin = @Username) 
begin select mdx_string,sql_string from ds_mds_divergent_hierarchy where windowslogin = @Username 
end
ELSE 

/**********
		SQL Code Generator
					****************/

BEGIN
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

SET @TMSqlString = STUFF(@TMSqlString, LEN(@TMSqlString), 1, '') END



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

SET @HSDSqlString = STUFF(@HSDSqlString, LEN(@HSDSqlString), 1, '') END


--Director
IF EXISTS (SELECT management_role_one FROM @UsernameTbl WHERE management_role_one = 'Director') BEGIN
declare @DirCodeTable table (empcode varchar(max)) 
insert into @DirCodeTable
select dim_fed_hierarchy_history_key as 'empcode' from dim_fed_hierarchy_history 
inner join @UsernameTbl u on u.division = dim_fed_hierarchy_history.hierarchylevel2hist
						 and activeud = 1

declare @DirSqlString varchar(max)
SET @DirSqlString = (
SELECT empcode + ',' AS [text()]
FROM @DirCodeTable
FOR XML PATH('')  
)

SET @DirSqlString = STUFF(@DirSqlString, LEN(@DirSqlString), 1, '') END

END
/**********
	MAIN SECTION
		*********/


BEGIN
--Team Manager
IF NOT EXISTS (SELECT management_role_one FROM @UsernameTbl WHERE management_role_one IN ('HoSD', 'Director')) BEGIN
SELECT DISTINCT
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Team].&['+
													            team + ']&[' +
																department + ']&[' +
																division   + ']&[' +
																firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  AS mdx,
@TMSqlString AS [sql]
FROM @UsernameTbl END

--HSD
IF EXISTS (SELECT management_role_one FROM @UsernameTbl WHERE management_role_one = 'HoSD') BEGIN
SELECT DISTINCT
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Practice Area].&['+
																	   department + ']&[' +
																	   division   + ']&[' +
																	   firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  AS mdx,
@HSDSqlString AS [sql]
FROM @UsernameTbl END

--Director
IF EXISTS (SELECT management_role_one FROM @UsernameTbl WHERE management_role_one = 'Director') BEGIN
SELECT DISTINCT
'descendants([Dim Fed Hierarchy History].[Hierarchy].[Business Line].&['+
																	   division   + ']&[' +
																	   firm + '],  [Dim Fed Hierarchy History].[Hierarchy].[Display Name])'  AS mdx,
@DirSqlString AS [sql]
FROM @UsernameTbl END

END 


GO
