SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[AreaManaged_Individual] @Username varchar(100)
as begin
declare @CodeTbl table (code varchar(max), empcode varchar(max))

insert into @CodeTbl
select distinct
 '[Dim Fed Hierarchy History].[Hierarchy].[Display Name].&['+
												display_name+']&['+
												ISNULL(hierarchylevel5hist,'') + ']&['+
												RTRIM(hierarchylevel4hist)+']&['+
												hierarchylevel3hist+']&['+
												hierarchylevel2hist+']&['+
												hierarchylevel1hist+']' +',' AS code,
dim_fed_hierarchy_history_key as 'emp_code'

from dim_fed_hierarchy_history 
-- 2020/02/07 - RH - Added lower 
where LOWER(windowsusername) = @Username


declare @CodeString varchar(max)
set @CodeString = (
select distinct code as [text()]
from @CodeTbl
where code not like '%Unknown%'
FOR XML PATH('')  
)

declare @SqlString varchar(max)
set @SqlString = (
select  empcode + ',' as [text()]
from @CodeTbl
where code not like '%Unknown%'
FOR XML PATH('')  
)


select 
STUFF(
	replace(@CodeString, 'amp;', ''), -- replace XML characters in both clauses of STUFF()
	LEN(replace(@CodeString, 'amp;', '')), 
	1, '') as mdx,

STUFF(@SqlString, LEN(@SqlString), 1, '') as sql
end
GO
GRANT EXECUTE ON  [dbo].[AreaManaged_Individual] TO [db_ssrs_dynamicsecurity]
GO
