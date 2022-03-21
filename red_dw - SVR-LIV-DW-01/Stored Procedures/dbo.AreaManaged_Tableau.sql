SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[AreaManaged_Tableau] @Username varchar(10) as begin

declare @StartDate date set @StartDate = '2017-05-01'
declare @EndDate date set @EndDate = '2019-05-01'


	declare @Path NVARCHAR(1024)
	declare @Query nvarchar(max)
	declare @Query2 NVARCHAR(MAX)
	declare @Path2 NVARCHAR(1024)

	SET @Query = '         
				SELECT @Path = distinguishedName         
				FROM OPENQUERY
							(ADSI, ''             
									SELECT distinguishedName              
									FROM ''''LDAP://lb-ldaps:636''''             
									WHERE                  
									sAMAccountName = ''''' + @Username
		+ '''''         
							'')     '    
  
	--PRINT @Query  

	EXEC master.sys.SP_EXECUTESQL @Query, N'@Path NVARCHAR(1024) OUTPUT',
		@Path = @Path OUTPUT

		SET @Query = '         
			SELECT *          
			FROM OPENQUERY(ADSI,''             
				SELECT  name,  distinguishedName            
				FROM ''''LDAP://lb-ldaps:636''''             
				WHERE                  
						objectClass=''''group'''' 
				AND member=''''' + @Path + '''''         
				'')         ORDER BY name     '     

 
		SET @Query2 = '         
			SELECT *          
			FROM OPENQUERY(ADSI,''             
				SELECT  name,  distinguishedName            
				FROM ''''LDAP://lb-ldaps:636''''             
				WHERE                  
						objectClass=''''group'''' 
				AND member=''''' + REPLACE(@Path,'''','''''''''') + '''''         
				'')         ORDER BY name     '   

	--PRINT @Query2

	IF OBJECT_ID('tempdb..#ADGroups') IS NOT NULL 
	DROP TABLE #ADGroups

		CREATE TABLE #ADGroups
		(
			distinguishedName VARCHAR(2000) ,
			Name VARCHAR(200)
		)
		INSERT  INTO [#ADGroups]
		( distinguishedName, Name )
		VALUES  ( NULL, 'Everyone' )
		INSERT  INTO [#ADGroups]   
		(distinguishedName, Name ) 

	EXEC master.sys.SP_EXECUTESQL @Query2, N'@Path2 NVARCHAR(1024) OUTPUT',
		@Path2 = @Path2 OUTPUT  


	declare @FinalTbl table (Level varchar(100), mdx varchar(max), [sql] varchar(max), [default] varchar(100))
	insert into @FinalTbl values ('Individual', NULL, NULL, NULL)
	insert into @FinalTbl (Level)

	select 
	CASE WHEN Name = 'People - Directors and Partners' THEN 'Firm'
	WHEN Name = 'Head of Business Services' THEN 'Firm'
	WHEN Name = 'People - All Consultants' THEN 'Firm'
	WHEN Name = 'SSRS - Dev_ReportsAdmin' THEN 'Firm'
	WHEN Name = 'Restricted - Operations - Finance' THEN 'Firm'
	WHEN Name = 'Restricted - Operations - Risk & Compliance' THEN 'Firm'
	WHEN Name = 'Restricted - Operations - Marketing' THEN 'Firm'
	WHEN Name = 'Restricted - Operations - HR&D' THEN 'Firm'
	WHEN Name = 'CascadeDepartment - Business Process' then 'Firm'
	WHEN Name = 'Reports_Testers' THEN 'Firm'
	WHEN Name = 'People - All PAs' THEN 'Firm'
	WHEN Name = 'People - Governance staff' THEN 'Firm'
	WHEN Name = 'People - Business Services Management Department' then 'Firm'

	END
	from #ADGroups







declare @UsernameTbl table (employeeid varchar(100), windowsusername varchar(100), management_role_one varchar(100),  team varchar(100), department varchar(100), division varchar(100), firm varchar(100))

insert into @UsernameTbl 
select distinct employeeid, windowsusername, management_role_one, hierarchylevel4hist, hierarchylevel3hist, hierarchylevel2hist, hierarchylevel1hist from dim_fed_hierarchy_history
where windowsusername = @Username and activeud = 1 and dss_current_flag = 'Y'

														
/**********
		Divergent Hierarchy was created to cater 
		for people that manage more than one team.
		If the user exists in this table, run the below and stop.
		Otherwise, run everything from the next "else"

		Divergent Hierarchy is a manually updated tbl in Red
													****************/

if exists (select windowslogin from ds_mds_divergent_hierarchy where windowslogin = @Username) 
begin select mdx_string,null from ds_mds_divergent_hierarchy where windowslogin = @Username 
end
/**********
	MAIN SECTION
		*********/

declare @tblHierarchy table (windowsusername varchar(10), director_flag bit, hierarchy2 varchar(100), hierarchy3 varchar(100), hierarchy4 varchar(100), default_hierarchy2 varchar(100), default_hierarchy3 varchar(100), default_hierarchy4 varchar(100))


-- Team Manager and HSD
if exists (select management_role_one from @UsernameTbl where management_role_one in ('HoSD', 'Team Manager')) begin

insert into @tblHierarchy (hierarchy2, hierarchy3, hierarchy4)
select distinct hierarchylevel2hist, hierarchylevel3hist, hierarchylevel4hist as team 
from dim_fed_hierarchy_history
where hierarchylevel3hist in ( select department from @UsernameTbl )
  and hierarchylevel2hist in (select division from @UsernameTbl )
and dss_start_date >= @StartDate and dss_start_date <= @EndDate
and hierarchylevel4hist is not null


end

--Director and Partners
if exists (select * from @FinalTbl where Level = 'Firm') begin
insert into @tblHierarchy (hierarchy2, hierarchy3, hierarchy4)
select distinct hierarchylevel2hist, hierarchylevel3hist, hierarchylevel4hist from dim_fed_hierarchy_history
where hierarchylevel2hist is not null and hierarchylevel3hist is not null and hierarchylevel4hist is not null
and dss_start_date >= @StartDate and dss_start_date <= @EndDate

update @tblHierarchy 
set windowsusername = T1.windowsusername,
    director_flag = 0
	from @UsernameTbl as T1

end



if exists (select management_role_one from @UsernameTbl where management_role_one = 'Director') begin
-- Director 

update @tblHierarchy
set windowsusername = T1.windowsusername, 
    director_flag = 1,
	default_hierarchy2 = T1.division,
	default_hierarchy3 = '(All)',
	default_hierarchy4 = '(All)'
	from @UsernameTbl as T1
end


----HSD and Team Manager
if exists (select management_role_one from @UsernameTbl where management_role_one in ('HoSD', 'Team Manager')) begin

update @tblHierarchy
set windowsusername = T1.windowsusername, 
director_flag = 0,
default_hierarchy2= T1.division,
default_hierarchy3 = T1.department,
default_hierarchy4 = '(All)'

from @UsernameTbl as T1

end 


insert into dbo.HierarchyTest 
select distinct
windowsusername,
director_flag, 
hierarchy2,
hierarchy3,
hierarchy4,
case when default_hierarchy2 is null then hierarchy2 else default_hierarchy2 end as 'default_hierarchy2', 
case when default_hierarchy3 is null then hierarchy3 else default_hierarchy3 end as 'default_hierarchy3',
case when default_hierarchy4 is null then hierarchy4 else default_hierarchy4 end as 'default_hierarchy4'

from @tblHierarchy

end

GO
