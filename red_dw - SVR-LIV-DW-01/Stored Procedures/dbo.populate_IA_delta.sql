SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[populate_IA_delta]

AS

-- Used to send data to IA from DWH.




IF OBJECT_ID ('tempdb.dbo.#offices') IS NOT NULL
DROP TABLE #offices

DECLARE @process INT 

SELECT @process = COUNT(*) FROM [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[ProcessIA]
WHERE reprocess = 'Y'
AND jobname = 'PopulateIADelta'

--PRINT @process

IF @process = 1

BEGIN

UPDATE [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[ProcessIA]
SET reprocess = 'R'
WHERE jobname = 'PopulateIADelta'

-- Populate Persons
--USE Reporting

declare @dim_max_date datetime

--set @dim_max_date = (select max(dss_update_time) from dim_client_matter_summary)

--set @dim_max_date = '2018-08-23 12:07:46.687'

set @dim_max_date = (select [lastprocessed_update] from [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[LastProcessedIA])

--print @dim_max_date

--USE red_dw

INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PERSON$1]
           ([COMP_UCI]
           ,[TITLE]
           ,[FIRST_NM]
           ,[MIDDLE_NM]
           ,[LAST_NM]
           ,[SUFFIX]
           ,[JOB_TITLE]
           ,[GOES_BY]
           ,[DEPARTMENT]
           ,[ASSISTANT_NM]
           ,[MAP_UCI])

SELECT co.dim_client_key compclikey,
left(cm.title,40),
LEFT(cm.firstname,60) Forname,
NULL middlename ,
LEFT(cm.surname,60) Surname,
NULL suffix,
left(cm.job_title,120) Jobtitle,
--LEFT(cc.kc_salutn, CHARINDEX(' ',cc.kc_salutn)) +  ' ' + REPLACE(cc.kc_salutn, LEFT(cc.kc_salutn, CHARINDEX(' ',cc.kc_salutn)),'') goesby,
--left(cm.client_name,60) goesby,
LEFT(cm.firstname,60) goesby,
NULL department,
NULL assistant,
cl.dim_client_key
FROM dbo.dim_client_matter_summary cm
INNER JOIN /*[svr-liv-dwh-01].*/red_dw.dbo.dim_client cl
ON cm.client_code = cl.client_code
INNER JOIN fact_client_matter_summary fc
on cm.dim_client_matter_summ_key = fc.dim_client_matter_summ_key
left JOIN /*[svr-liv-dwh-01].*/red_dw.dbo.dim_client co
ON cm.company_client_code = co.client_code
WHERE crm_client_type IN 
(
'Contact MK'
,'Contact'
,'Person'
,'Contact MKP'
,'Personel'
)
AND NOT EXISTS (SELECT 1 FROM [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PERSON$1] WHERE cm.dim_client_key = MAP_UCI)
AND NOT EXISTS (SELECT 1 FROM [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[contacts] WHERE DELETED_IND=1 AND cm.dim_client_key = UCI) --Added to stop deletions
AND NOT EXISTS (SELECT 1 FROM [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_COMPANY$1] WHERE cm.dim_client_key = MAP_UCI) -- added to stop converted clients coming accross again
and (cm.dss_update_time > @dim_max_date or cl.dss_update_time > @dim_max_date or fc.dss_update_time > @dim_max_date)

and cm.client_status = 'Active'
and cl.address_type = 'CL'
and isnull(cm.surname,'') <> ''
and (cl.push_to_ia = 0 or cl.push_to_ia is null)



INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PERSON$1]
           ([COMP_UCI]
           ,[TITLE]
           ,[FIRST_NM]
           ,[MIDDLE_NM]
           ,[LAST_NM]
           ,[SUFFIX]
           ,[JOB_TITLE]
           ,[GOES_BY]
           ,[DEPARTMENT]
           ,[ASSISTANT_NM]
           ,[MAP_UCI])

SELECT co.dim_client_key compclikey,
left(cm.title,40),
LEFT(cm.firstname,60) Forname,
NULL middlename ,
LEFT(cm.surname,60) Surname,
NULL suffix,
left(cm.job_title,120) Jobtitle,
--LEFT(cc.kc_salutn, CHARINDEX(' ',cc.kc_salutn)) +  ' ' + REPLACE(cc.kc_salutn, LEFT(cc.kc_salutn, CHARINDEX(' ',cc.kc_salutn)),'') goesby,
--left(cm.client_name,60) goesby,
LEFT(cm.firstname,60) goesby,
NULL department,
NULL assistant,
cl.dim_client_key
FROM dbo.dim_client_matter_summary cm
INNER JOIN /*[svr-liv-dwh-01].*/red_dw.dbo.dim_client cl
ON cm.client_code = cl.client_code
INNER JOIN fact_client_matter_summary fc
on cm.dim_client_matter_summ_key = fc.dim_client_matter_summ_key
left JOIN /*[svr-liv-dwh-01].*/red_dw.dbo.dim_client co
ON cm.company_client_code = co.client_code
WHERE crm_client_type IN 
(
'Contact MK'
,'Contact'
,'Person'
,'Contact MKP'
,'Personel'
)
AND NOT EXISTS (SELECT 1 FROM [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PERSON$1] WHERE cm.dim_client_key = MAP_UCI)
AND NOT EXISTS (SELECT 1 FROM [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[contacts] WHERE DELETED_IND=1 AND cm.dim_client_key = UCI) --Added to stop deletions
AND NOT EXISTS (SELECT 1 FROM [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_COMPANY$1] WHERE cm.dim_client_key = MAP_UCI) -- added to stop converted clients coming accross again
and (cm.dss_update_time > @dim_max_date or cl.dss_update_time > @dim_max_date or fc.dss_update_time > @dim_max_date)
and cm.client_status = 'Active'
and cl.address_type = 'CC'
and isnull(co.dim_client_key,0) <> 0 
--and cm.client_status <> 'Closed'
and (cl.push_to_ia = 0 or cl.push_to_ia is null)






--declare @dim_max_date datetime

----set @dim_max_date = (select max(dss_update_time) from dim_client_matter_summary)

----set @dim_max_date = '2018-08-23 12:07:46.687'

--set @dim_max_date = (select [lastprocessed_update] from [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[LastProcessedIA])

-- Populate Companies

-- select * from  [SVR-LIV-IASQ-01].InterAction.IDCAPP.[INT_DTS_PERSON$1] 
INSERT INTO [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1 (COMPANY_NM, COMPANY_KNOWN_AS, MAP_UCI)

SELECT dim_client_matter_summary.client_name, dim_client_matter_summary.client_name,dim_client_matter_summary.dim_client_key 
FROM dim_client_matter_summary inner join dim_client on dim_client_matter_summary.dim_client_key = dim_client.dim_client_key
INNER JOIN fact_client_matter_summary fc
on dim_client_matter_summary.dim_client_matter_summ_key = fc.dim_client_matter_summ_key
LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1 ON [INT_DTS_COMPANY$1].MAP_UCI = dim_client_matter_summary.dim_client_key AND dim_client_matter_summary.client_name = [INT_DTS_COMPANY$1].COMPANY_NM COLLATE Latin1_General_BIN
WHERE crm_client_type in ('Contact MK Comp','Company')
AND dim_client_matter_summary.client_name IS NOT NULL
and (dim_client_matter_summary.dss_update_time > @dim_max_date or dim_client.dss_update_time > @dim_max_date or fc.dss_update_time > @dim_max_date)
--and client_status <> 'Closed'
and dim_client_matter_summary.client_status = 'Active'
and (push_to_ia = 0 or push_to_ia is null)
AND NOT EXISTS (SELECT 1 FROM [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PERSON$1] WHERE dim_client_matter_summary.dim_client_key = MAP_UCI)
AND [INT_DTS_COMPANY$1].MAP_UCI IS null

UNION 

SELECT cl.client_name, cl.client_name, cl.dim_client_key FROM dbo.dim_client cl
inner join dim_client_matter_summary cm on cl.dim_client_key = cm.dim_client_key
--and cm.client_status <> 'Closed'
and cm.client_status in ('Active','Prospect')
WHERE cl.dim_client_key IN (SELECT DISTINCT COMP_UCI FROM [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_PERSON$1])
and (cl.push_to_ia = 0 or cl.push_to_ia is null)



/*FOLDERS*/

declare @dim_max_create_date datetime

set @dim_max_create_date = (select [lastprocessed_create] from [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[LastProcessedIA])

declare @dim_max_import_date datetime

set @dim_max_import_date = (select [lastprocessed_import] from [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[LastProcessedIA])

--declare @dim_max_date datetime

----set @dim_max_date = (select max(dss_update_time) from dim_client_matter_summary)

----set @dim_max_date = '2018-08-23 12:07:46.687'

--set @dim_max_date = (select [lastprocessed_update] from [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[LastProcessedIA])



INSERT into [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_FOLDER_LINK$1]

/*need to add new client review companies folder import for new clients and remove them from the below thing*/ 

select 'New Contact Review - Companies',dim_client_key 
from dim_client_matter_summary inner join [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1 
on dim_client_key = [MAP_UCI]
where dss_create_time > @dim_max_create_date
and crm_client_type in ('Contact MK Comp','Company','Prospect')
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
union
select 'New Contact Review - People',dim_client_key 
from dim_client_matter_summary inner join [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_PERSON$1]
on dim_client_key = [MAP_UCI]
where dss_create_time > @dim_max_create_date
and crm_client_type  IN 
(
'Contact MK'
,'Contact'
,'Person'
,'Contact MKP'
,'Personel'
)
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

/*TOP 200 ROLLING REV*/
UNION

SELECT 'Clients (Top)',dim_client_key--,topstuff.costs_to_date_running 
FROM 
(SELECT dim_client_key,fact_client_matter_summary.dim_client_matter_summ_key, costs_to_date_running 
,ROW_NUMBER() OVER (ORDER BY costs_to_date_running DESC) top_order 
FROM fact_client_matter_summary
INNER JOIN dbo.dim_client_matter_summary 
ON dim_client_matter_summary.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
WHERE costs_to_date_running > 0
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
) topstuff
LEFT OUTER JOIN [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_FOLDER_LINK$1] ON [INT_DTS_FOLDER_LINK$1].UCI = topstuff.dim_client_key
WHERE top_order <= 200
AND [INT_DTS_FOLDER_LINK$1].UCI IS null

union 

select LEFT(folder,150), dim_client_matter_summary.dim_client_key from [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[contact_folder_import]
inner join dim_client_matter_summary on [contact_folder_import].dim_client_key = dim_client_matter_summary.dim_client_key
where [dss_insert_time] > @dim_max_import_date AND folder is not null
and dim_client_matter_summary.dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
union 
select 'Weightmans People', dim_client_matter_summary.dim_client_key from dim_client_matter_summary

where dss_update_time > @dim_max_date and crm_client_type = 'Personel' 
and dim_client_matter_summary.client_status = 'Active'
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

 
-- Address
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_STREET_ADDRESS$1] 
(	
	[ADDRESS_ID]
	,[ADDR_TYPE]
	,[LABEL]
	,[LINE1]
	,[LINE2]
	,[LINE3]
	,[CITY]
	,[STATE]
	,[POSTAL_CODE]
	,[COUNTRY]
	,[ADDITIONAL]
	,[MAIL_IND]
	,[UCI]
)
SELECT dim_client.dim_client_key, 'BUS', 'Main Office',left(address_line_1,85),left(address_line_2,85),left(address_line_3,85),left(address_line_4,35),left(address_line_5,64),left(postcode,20), 'United Kingdom', NULL, 1, dim_client.dim_client_key
FROM dim_client inner join dim_client_matter_summary on dim_client.dim_client_key = dim_client_matter_summary.dim_client_key
where dim_client.dim_client_key  in 
( select MAP_UCI FROM
[SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PERSON$1]
UNION
SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
)
AND address_line_1 IS NOT NULL
and (push_to_ia = 0 or push_to_ia is null)

-- Phone
-- Companies
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PHONE$1]
(
	[ADDRESS_ID]
	,[ADDR_TYPE]
	,[LABEL]
	,[PHONE]
	,[PHONE_EXT]
	,[UCI]
)
SELECT cli.dim_client_key, 'BUS', 'Main Office', cli.phone_number, NULL, cli.dim_client_key
FROM red_dw.dbo.dim_client cli inner join dim_client_matter_summary on cli.dim_client_key = dim_client_matter_summary.dim_client_key

WHERE
	ISNULL(cli.phone_number,'') != '' 
	
	AND  cli.dim_client_key  in 
( select MAP_UCI FROM
[SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_COMPANY$1])
and cli.dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
  
 -- Person Phones
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PHONE$1]
(
	[ADDRESS_ID]
	,[ADDR_TYPE]
	,[LABEL]
	,[PHONE]
	,[PHONE_EXT]
	,[UCI]
)
SELECT dw2.dim_client_key, 'BUS', 'Main Office', phone_number, NULL, dw2.dim_client_key
FROM red_dw.dbo.dim_client dw2 
INNER JOIN [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1 ia ON ia.MAP_UCI = dw2.dim_client_key

WHERE
	ISNULL(phone_number,'') != '' 
and (push_to_ia = 0 or push_to_ia is null)


-- Fax
-- Companies
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_FAX$1]
(
	[ADDRESS_ID]
    ,[ADDR_TYPE]
    ,[LABEL]
    ,[FAX]
    ,[UCI]
)
SELECT dw.dim_client_key, 'BUS', 'Main Office', addr.fm_addfax, dw.dim_client_key
FROM ds_sh_axxia_kdclicon cc
INNER JOIN red_dw.dbo.dim_client dw ON dw.client_code = cc.kc_orgidn
INNER JOIN red_dw.dbo.ds_sh_axxia_fmsaddr addr ON addr.fm_addnum = cc.kc_addrid
INNER JOIN [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1 ia ON ia.MAP_UCI = dw.dim_client_key

WHERE
	addr.deleted_flag = 'N' AND
	addr.current_flag = 'Y' AND
	ISNULL(addr.fm_addfax,'') != '' 
and (push_to_ia = 0 or push_to_ia is null)


-- Person
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_FAX$1]
(
	[ADDRESS_ID]
    ,[ADDR_TYPE]
    ,[LABEL]
    ,[FAX]
    ,[UCI]
)
SELECT dw2.dim_client_key, 'BUS', 'Main Office', addr.fm_addfax, dw2.dim_client_key
FROM ds_sh_axxia_kdclicon cc
INNER JOIN red_dw.dbo.dim_client dw2 ON dw2.client_code = cc.kc_client
INNER JOIN red_dw.dbo.ds_sh_axxia_fmsaddr addr ON addr.fm_addnum = cc.kc_addrid
INNER JOIN [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1 ia ON ia.MAP_UCI = dw2.dim_client_key

WHERE
	addr.deleted_flag = 'N' AND
	addr.current_flag = 'Y' AND
	ISNULL(addr.fm_addfax,'') != '' 
and (push_to_ia = 0 or push_to_ia is null)

-- Email
-- Person
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_EMAIL$1]
(
	[ADDRESS_ID]
    ,[ADDR_TYPE]
    ,[LABEL]
    ,[EMAIL]
    ,[UCI]
)
SELECT dw2.dim_client_key, 'BUS', 'Main Office', dw2.email, dw2.dim_client_key
FROM dbo.dim_client dw2 
INNER JOIN [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1 ia ON ia.MAP_UCI = dw2.dim_client_key
where dw2.client_code NOT like 'EMP%'
and (push_to_ia = 0 or push_to_ia is null)

union 

select dim_client.dim_client_key, 'BUS', 'Main Office', email, dim_client_key
from dbo.dim_client
where dim_client.dss_update_time >= @dim_max_date
and client_code NOT like 'EMP%'
and (push_to_ia = 0 or push_to_ia is null)

INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_EMAIL$1]
(
	[ADDRESS_ID]
    ,[ADDR_TYPE]
    ,[LABEL]
    ,[EMAIL]
    ,[UCI]
)
SELECT dw2.dim_client_key, 'BUS', 'Main Office', dim_employee.workemail, dw2.dim_client_key
FROM dbo.dim_client_matter_summary dw2 JOIN dim_fed_hierarchy_history
ON replace(dw2.client_code, 'EMP','') = dim_fed_hierarchy_history.fed_code
and dss_current_flag = 'Y'
INNER JOIN dim_employee on dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_EMAIL$1] ON dw2.dim_client_key = [INT_DTS_EMAIL$1].UCI AND dim_employee.workemail = [INT_DTS_EMAIL$1].EMAIL COLLATE Latin1_General_BIN
--INNER JOIN [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1 ia ON ia.MAP_UCI = dw2.dim_client_key
where dw2.client_code like 'EMP%' and leaver = 0 
and dw2.dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
AND [INT_DTS_EMAIL$1].UCI IS null

-- Mobile
-- Doesn't exist

-- Website
-- Companies

INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_WEBSITE$1]
(
	[ADDRESS_ID]
    ,[ADDR_TYPE]
    ,[LABEL]
    ,[WEB]
    ,[UCI]
)
SELECT dw.dim_client_key, 'BUS', 'Main Office', website, dw.dim_client_key
FROM dim_client_matter_summary dw

WHERE
	 dw.dim_client_key IN 
		    		   	(
--						SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
--	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
	and isnull(website,'') <> ''
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)



-- client group code
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1]
        ( [CLIENT_GROUP_CODE], [UCI] )

SELECT DISTINCT client_group_code, cli.dim_client_key
FROM dbo.dim_client_matter_summary cli

WHERE	
	cli.dim_client_key IN 

	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) AND cli.client_group_code IS NOT NULL AND cli.client_group_code <> ''
 and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
  

-- client group name
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPNAME$1]
        ( [CLIENT_GROUP_NAME], [UCI] )

SELECT cli.client_group_name, cli.dim_client_key
FROM dbo.dim_client_matter_summary cli 

WHERE	
	 cli.dim_client_key IN 

	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) AND cli.client_group_code IS NOT NULL AND cli.client_group_code <> ''
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

/*client group partner*/

insert into [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_CLIENTGRPPARTNER$1]
SELECT DISTINCT
       windowsusername,
       dim_client.dim_client_key
FROM dim_fed_hierarchy_history
    INNER JOIN dim_client
        ON client_group_partner_name = dim_fed_hierarchy_history.name
           AND address_type = 'CL'
    INNER JOIN dim_client_matter_summary
        ON dim_client_matter_summary.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN  [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_CLIENTGRPPARTNER$1] ON dim_client.dim_client_key = [INT_DTS_CLIENTGRPPARTNER$1].UCI AND dim_fed_hierarchy_history.windowsusername = [INT_DTS_CLIENTGRPPARTNER$1].CLIENT_GROUP_PARTNER COLLATE Latin1_General_BIN
WHERE latest_hierarchy_flag = 'Y'
      AND
      (
          push_to_ia = 0
          OR push_to_ia IS NULL
      ) AND [INT_DTS_CLIENTGRPPARTNER$1].UCI IS null

	
	/******************************************************************************************************************************************************/

-- Sector
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_SECTOR$1]
           ([SECTOR]
           ,[UCI])

SELECT RTRIM(LTRIM(cli.sector)), dim_client_key
FROM dim_client_matter_summary cli
LEFT OUTER JOIN  [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_SECTOR$1] ON [INT_DTS_SECTOR$1].UCI = cli.dim_client_key AND [INT_DTS_SECTOR$1].SECTOR = RTRIM(LTRIM(cli.sector)) COLLATE Latin1_General_CI_AI
WHERE
	ISNULL(cli.sector,'') != '' 
	AND cli.dim_client_key IN 
	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	AND cli.sector IS NOT NULL 
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
AND [INT_DTS_SECTOR$1].UCI IS null


-- SubSector
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_SUBSECTOR$1]
           (SUB_SECTOR
           ,[UCI])
SELECT cli.sub_sector, dim_client_key
FROM dim_client_matter_summary cli
LEFT OUTER JOIN  [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_SUBSECTOR$1] ON [INT_DTS_SUBSECTOR$1].UCI = cli.dim_client_key AND [INT_DTS_SUBSECTOR$1].SUB_SECTOR = cli.sub_sector COLLATE Latin1_General_CI_AI
WHERE
	ISNULL(cli.sub_sector,'') != '' 
	
		AND cli.dim_client_key IN 
	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
AND [INT_DTS_SUBSECTOR$1].UCI IS null


-- Segment
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_SEGMENT$1]
		([SEGMENT]
           ,[UCI])
SELECT cli.segment, dim_client_key
FROM dim_client_matter_summary cli
LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_SEGMENT$1] ON [INT_DTS_SEGMENT$1].UCI = cli.dim_client_key AND [INT_DTS_SEGMENT$1].SEGMENT = cli.segment COLLATE Latin1_General_CI_AI

WHERE
	ISNULL(cli.segment,'') != '' 
	
			AND cli.dim_client_key IN 
	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
AND [INT_DTS_SEGMENT$1].UCI IS null


-- Client Group Rev   HERE*******************************************
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPREVENUEYTD$1]
           ([CLIENT_GROUP_REVENUE_YTD]
           ,[UCI])

		   SELECT ISNULL(costs_to_date_ytd,0), UCI
		   FROM dbo.fact_client_group_matter_summary INNER JOIN 
		   [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1] ON client_group_code =  CAST([CLIENT_GROUP_CODE] COLLATE Latin1_General_BIN AS varchar)
		 

-- Client Group Rev -1
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPREVLASTYEAR$1]
           ([CLIENT_GROUP_REVENUE_LAST_YEAR]
           ,[UCI])
		      
	   SELECT ISNULL(costs_to_date_ytd1,0), UCI
		   FROM dbo.fact_client_group_matter_summary INNER JOIN 
		   [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1] ON client_group_code =  CAST([CLIENT_GROUP_CODE] COLLATE Latin1_General_BIN AS varchar)
	

-- Client Group Rev -2
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPREVYRBEFORE$1]
           ([CLIENT_GROUP_REVENUE_YEAR_BEFORE_LAST]
           ,[UCI])
		   		      
		   SELECT ISNULL(costs_to_date_ytd2,0), UCI
		   FROM dbo.fact_client_group_matter_summary INNER JOIN 
		   [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1] ON client_group_code =  CAST([CLIENT_GROUP_CODE] COLLATE Latin1_General_BIN AS varchar)
		 
-- Client Group WIP
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPWIP$1]
           ([CLIENT_GROUP_WIP]
           ,[UCI])

		    
		  SELECT ISNULL(wip_balance_ytd,0), UCI
		   FROM dbo.fact_client_group_matter_summary INNER JOIN 
		   [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1] ON client_group_code =  CAST([CLIENT_GROUP_CODE] COLLATE Latin1_General_BIN AS varchar)
		   

-- Client Group Rolling

INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPROLLINGREV$1]
           ([CLIENT_GROUP_REVENUE_ROLLING__12_MONTHS_]
           ,[UCI])


	  SELECT ISNULL(costs_to_date_running,0), UCI
		   FROM dbo.fact_client_group_matter_summary INNER JOIN 
		   [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1] ON client_group_code =  CAST([CLIENT_GROUP_CODE] COLLATE Latin1_General_BIN AS varchar)
		   

-- Client Rev
INSERT INTO  [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_REVENUEYTD$1]
           ([REVENUE_YTD]
           ,[UCI])

		   SELECT ISNULL(costs_to_date_ytd,0),dim_client_key 
		   FROM fact_client_matter_summary INNER JOIN dbo.dim_client_matter_summary cli
		   ON cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
		   LEFT OUTER JOIN  [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_REVENUEYTD$1] ON [INT_DTS_REVENUEYTD$1].UCI = cli.dim_client_key AND ISNULL(costs_to_date_ytd,0) = [INT_DTS_REVENUEYTD$1].REVENUE_YTD
		   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
	AND [INT_DTS_REVENUEYTD$1].UCI IS null


-- Rolling Rev
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_ROLLINGREVTWELVEMNTH$1]
        ( [REVENUE_ROLLING__12_MONTHS_] ,
          [UCI] )

		   	      SELECT ISNULL(costs_to_date_running,0),dim_client_key 
		   FROM fact_client_matter_summary INNER JOIN dbo.dim_client_matter_summary cli
		   ON cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
		   LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_ROLLINGREVTWELVEMNTH$1] ON [INT_DTS_ROLLINGREVTWELVEMNTH$1].UCI = cli.dim_client_key AND ISNULL(costs_to_date_running,0) = [INT_DTS_ROLLINGREVTWELVEMNTH$1].REVENUE_ROLLING__12_MONTHS_
		   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
	AND [INT_DTS_ROLLINGREVTWELVEMNTH$1].UCI IS null

-- Client Rev -1
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_REVENUELASTYEAR$1]
           ([REVENUE_LAST_YEAR]
           ,[UCI])

		      	      SELECT ISNULL(costs_to_date_ytd1,0),dim_client_key 
				   FROM fact_client_matter_summary INNER JOIN dbo.dim_client_matter_summary cli
		   ON cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
		   LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_REVENUELASTYEAR$1] ON cli.dim_client_key = [INT_DTS_REVENUELASTYEAR$1].UCI AND [INT_DTS_REVENUELASTYEAR$1].REVENUE_LAST_YEAR = ISNULL(costs_to_date_ytd1,0)
		   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
	AND [INT_DTS_REVENUELASTYEAR$1].UCI IS NULL


-- Client Rev -2
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_REVENUEYRBEFORELAST$1]
           ([REVENUE_YEAR_BEFORE_LAST]
           ,[UCI])

		      	      SELECT ISNULL(costs_to_date_ytd2,0),dim_client_key 
		   FROM fact_client_matter_summary INNER JOIN dbo.dim_client_matter_summary cli
		   ON cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
		   LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_REVENUEYRBEFORELAST$1] ON [INT_DTS_REVENUEYRBEFORELAST$1].UCI = cli.dim_client_key AND [INT_DTS_REVENUEYRBEFORELAST$1].REVENUE_YEAR_BEFORE_LAST = ISNULL(costs_to_date_ytd2,0)
		   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
	AND [INT_DTS_REVENUEYRBEFORELAST$1].UCI IS null
	

-- Client WIP
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTWIP$1]
           ([WIP]
           ,[UCI])

		      	      SELECT ISNULL(wip_balance_ytd,0),dim_client_key 
		   FROM fact_client_matter_summary INNER JOIN dbo.dim_client_matter_summary cli
		   ON cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
		   LEFT OUTER JOIN  [SVR-LIV-IASQ-01].InterAction.[IDCAPP].INT_DTS_CLIENTWIP$1 ON [INT_DTS_CLIENTWIP$1].UCI = cli.dim_client_key AND [INT_DTS_CLIENTWIP$1].WIP =  ISNULL(fact_client_matter_summary.wip_balance_ytd,0)
		   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
	AND [INT_DTS_CLIENTWIP$1].UCI IS null



-- Date Became Client
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_DATEBECAMECLIENT$1]
           ([DATE_BECAME_CLIENT]
           ,[UCI])

SELECT open_date, dim_client_key FROM dbo.dim_client_matter_summary cli
	
		   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

-- Date Last Matter Closed
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_DATELSTCLOSEDMATTER$1]
           ([DATE_OF_LAST_CLOSED_MATTER] /************************************************/
           ,[UCI])

		   SELECT date_last_closed_matter, dim_client_key FROM dbo.dim_client_matter_summary cli
		   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

-- Date Last Matter Opened
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_DATELSTOPENMATTER$1]
           ([DATE_OF_LAST_OPENED_MATTER]
           ,[UCI])

		   SELECT date_last_opened_matter, dim_client_key FROM dbo.dim_client_matter_summary cli
			   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

-- Num Opened Matters
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_NUMOPENMATTERS$1]
           ([NUMBER_OF_OPEN_MATTERS]
           ,[UCI])
		   
		    select ISNULL(open_matters,0), dim_client_key from fact_client_matter_summary inner join dim_client_matter_summary cli
			on cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
			   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
	) 
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

	/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
--Aged Debt Client Group
INSERT INTO [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_CLIENTGRPREVAGEDDEBT$1]
			([CLIENT_GROUP_AGED_DEBT__90_DAYS_]
			,[UCI]
			)

			select ISNULL(aged_debt_total,0), UCI from fact_client_group_matter_summary cli
				     INNER JOIN 
		   [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1] ON client_group_code =  CAST([CLIENT_GROUP_CODE] COLLATE Latin1_General_BIN AS varchar)
		 

-- Total Debt Client Group
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPTOTALDEBT$1]
			([CLIENT_GROUP_TOTAL_DEBT]
			,[UCI]
			)

			select ISNULL(debt_total,0), UCI 
			  FROM dbo.fact_client_group_matter_summary INNER JOIN 
		   [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTGRPCODE$1] ON client_group_code =  CAST([CLIENT_GROUP_CODE] COLLATE Latin1_General_BIN AS varchar)
	

--Aged Debt Client 
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_AGEDDEBT$1]
			([AGED_DEBT__90_DAYS_]
			,[UCI]
			)

			select ISNULL(aged_debt_total,0), cli.dim_client_key from fact_client_matter_summary 
			inner join dim_client_matter_summary cli
			on cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
			   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
			UNION
			SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
			and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)


-- Total Debt Client 
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_TOTAL_DEBT$1]
			([TOTAL_DEBT]
			,[UCI]
			)

			select ISNULL(debt_total,0), cli.dim_client_key from fact_client_matter_summary 
					inner join dim_client_matter_summary cli
			on cli.dim_client_matter_summ_key = fact_client_matter_summary.dim_client_matter_summ_key
			LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_TOTAL_DEBT$1] ON [INT_DTS_TOTAL_DEBT$1].UCI = cli.dim_client_key AND ISNULL(fact_client_matter_summary.debt_total,0) = [INT_DTS_TOTAL_DEBT$1].TOTAL_DEBT
			   WHERE dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
	AND [INT_DTS_TOTAL_DEBT$1].UCI IS NULL -- added to stop sending data more than once


-- Matters
--USE [InterAction]
--GO

INSERT INTO [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_PROJECT$1] 
(
	[CLIENT_CD]		-- Client Code
	,[PROJECT_CD]	-- Matter Code
	,[CLIENT_NM]	-- Client Name
	,[PROJECT_NM]	-- Matter Desc
	,[DEPT_CD]		-- Correlates to DEPARTMENT$1
	,[LOCATION_CD]	-- Correlates to OFFICE$1
	,[TYPE_CD]		-- 
	,[PARENT_CLIENT_CD]
	,[PARENT_PROJECT_CD]
	,[OPEN_DATE]	-- Open Date
	,[DESCRIPTION]	-- Matters Descript
	,[EXTERNAL_REF_CD]
	,[INTERNAL_ROLE_DESC]
	,[OUTCOME_DESC] -- Not needed
	,[SIZE_UOM]		-- Cost currency 
	,[SIZE_AMOUNT]	-- Cost 
	,[FEES_UOM]		-- WIP Currency
	,[FEES_AMOUNT]	-- WIP
	,[VIEW_ACCESS_IND] -- Not needed
	,[CLOSE_DATE]	-- Close date
)

SELECT 
ltrim(rtrim(t1.client_code)), ltrim(rtrim(t2.matter_number)), SUBSTRING(t1.client_name,1,150),SUBSTRING(t3.matter_description,1,150) , ltrim(rtrim(t3.department_code)),
ltrim(rtrim(t3.branch_code)),
'General',NULL /*t3.master_client_code*/,NULL,t3.date_opened_case_management,ltrim(rtrim(t3.matter_description)),NULL,
NULL,NULL,'GBP',t2.costs_to_date,'GBP',t2.wip_balance,NULL,t3.date_closed_practice_management

FROM 
dim_client_matter_summary t1 LEFT OUTER JOIN dbo.fact_matter_summary_current t2
ON t1.client_code = t2.client_code
INNER JOIN dbo.dim_matter_header_current t3
ON t2.client_code = t3.client_code
AND t2.matter_number = t3.matter_number
WHERE t1.client_name <> 'Unknown'
AND reporting_exclusions = 0
AND t2.date_closed_case_management IS NULL
AND 
	    t1.dim_client_key IN 
		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
and t1.dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

	
	


INSERT INTO [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_DEPARTMENT$1]
           ([CODE]
           ,[DESCRIPTION])

		   SELECT  RTRIM(LTRIM(department_code)), RTRIM(LTRIM(department_name))  FROM dbo.dim_department

	   SELECT DISTINCT
       RTRIM(LTRIM([branch_code])) AS branch_code,
       RTRIM(LTRIM([branch_name])) AS [branch_name]
	   INTO #offices
FROM [dbo].[dim_matter_header_current] AS [mat]
INNER JOIN  [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_PROJECT$1] AS [ia]
ON [mat].[branch_code] = CAST([LOCATION_CD] COLLATE Latin1_General_BIN AS VARCHAR)
WHERE [branch_code] IS NOT null
and mat.client_code not in (select client_code from dbo.dim_client where push_to_ia = 1)

ORDER BY [branch_code]

INSERT INTO [SVR-LIV-IASQ-01].[InterAction].[IDCAPP].[INT_DTS_OFFICE$1]
           ([CODE]
           ,[DESCRIPTION])
		   SELECT 	* 
		   FROM	[#offices] AS [o]


INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_ALLCLIENTNUMBERS$1]

     ( [MV_SYS_ID] -- client code
      ,[RELATIONSHIP_FIELD] -- null
      ,[ALL_CLIENT_NUMBERS] -- client code
      ,[UCI] --master client code (key) 
	  )

	SELECT dim_client_key, NULL, client_code, dim_client_key FROM dbo.dim_client_matter_summary
	LEFT OUTER JOIN  [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_ALLCLIENTNUMBERS$1] ON [INT_DTS_ALLCLIENTNUMBERS$1].UCI = dim_client_matter_summary.dim_client_key
	where dim_client_key IN 
		    		(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
	and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
	AND [INT_DTS_ALLCLIENTNUMBERS$1].UCI IS null



 --Primary Client Number
INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_PRIMARYCLIENTNUMBER$1]
           ([PRIMARY_CLIENT_NUMBER]
           ,[UCI])
SELECT cli.client_code, dim_client_key cli
FROM dim_client_matter_summary cli where cli.dim_client_key IN 
	    		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)


INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_COMPANYHOUSENUM$1]

SELECT company_house_number, dim_client_key
from dim_client_matter_summary
LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_COMPANYHOUSENUM$1] ON dim_client_matter_summary.dim_client_key = [INT_DTS_COMPANYHOUSENUM$1].UCI AND [INT_DTS_COMPANYHOUSENUM$1].COMPANIES_HOUSE_NUMBER = dim_client_matter_summary.company_house_number COLLATE Latin1_General_CI_AI
where dim_client_key in 
(
SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
)
and company_house_number is not null 
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)
AND [INT_DTS_COMPANYHOUSENUM$1].UCI IS null


insert into [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_ORGANISATIONTYPE$1]

select * from

(
select 
case 
when client_type = 'Charity' then 'Charity'
when client_type = 'LLP' then 'LLP ( Limited Liability Partnership)'
when client_type = 'Limited Company' then 'Ltd ( Private Limited Co)'
when client_type = 'Partnership' then 'General Partnership'
when client_type = 'Trust' then 'Trust'
else ''
end as Organisation
, dim_client_key  
from dim_client_matter_summary
where dim_client_key in 
(
SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1
)
) Organisation
where Organisation <> ''
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

/* client partner */ 

INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTPARTNER$1]
           ([CLIENT_PARTNER]
           ,[UCI])
select windowsusername,dim_client.dim_client_key
from dim_client 
inner join dim_employee on dim_client.client_partner_code = displayemployeeid
inner join dim_client_matter_summary on dim_client_matter_summary.dim_client_key = dim_client.dim_client_key
LEFT OUTER JOIN [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_CLIENTPARTNER$1] on [INT_DTS_CLIENTPARTNER$1].[CLIENT_PARTNER] = dim_employee.windowsusername  collate Latin1_General_BIN
														AND [INT_DTS_CLIENTPARTNER$1].UCI = dim_client.dim_client_key
where dim_client.client_partner_name is not null and dim_client.address_type = 'CL'
and dim_client.dim_client_key in		   	(	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
												UNION
												SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
and dim_client.dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)

AND [INT_DTS_CLIENTPARTNER$1].UCI IS null

/* relationship partner */

INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_RELATIONSHIPPARTNER$1]
           ([RELATIONSHIP_PARTNER]
           ,[UCI])
  select 
windowsusername,dim_client.dim_client_key
from dim_client 
inner join dim_employee on firm_contact_code = displayemployeeid
inner join dim_client_matter_summary on dim_client_matter_summary.dim_client_key = dim_client.dim_client_key
where dim_client.firm_contact_name is not null and dim_client.address_type = 'CL'
and dim_client.dim_client_key in		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1

	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
and dim_client.dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)


INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_GENERATORLEVEL$1]
           ([GENERATOR_LEVEL]
           ,[UCI])
		     select 
generator_status,dim_client.dim_client_key
from dim_client 
where dim_client.dim_client_key in		   	(SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_PERSON$1
	UNION
	SELECT MAP_UCI FROM [SVR-LIV-IASQ-01].InterAction.IDCAPP.INT_DTS_COMPANY$1)
and dim_client_key not in (select dim_client_key from dbo.dim_client where push_to_ia = 1)


INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_DATEJOINED$3] 
           ([DATE_JOINED_FIRM]
           ,[UCI])
SELECT dim_employee.employeestartdate AS [DATE_JOINED_FIRM]
,dim_client_key AS UCI 
FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON REPLACE(client_code,'EMP','')=fed_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE client_code LIKE 'EMP%'
and (push_to_ia = 0 or push_to_ia is null)

INSERT INTO [SVR-LIV-IASQ-01].InterAction.[IDCAPP].[INT_DTS_DATELEFT$3]
(
    [DATE_LEFT_FIRM],
    [UCI]
)
SELECT dim_employee.leftdate AS [DATE_LEFT_FIRM]
,dim_client_key AS UCI 
FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON REPLACE(client_code,'EMP','')=fed_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE client_code LIKE 'EMP%'
AND dim_employee.leftdate IS NOT NULL
and (push_to_ia = 0 or push_to_ia is null)

INSERT INTO [SVR-LIV-IASQ-01].InterAction.IDCAPP.[INT_DTS_PRACTICEGROUPPRIMARY$3]
(
    PRACTICE_GROUP_DEPT___PRIMARY_,
    UCI
)
SELECT hierarchylevel3hist AS [PRACTICE_GROUP_DEPT___PRIMARY_],
   dim_client_key AS  UCI

FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON REPLACE(client_code,'EMP','')=fed_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE client_code LIKE 'EMP%'
and (push_to_ia = 0 or push_to_ia is null)

INSERT INTO [SVR-LIV-IASQ-01].InterAction.IDCAPP.[INT_DTS_STAFFOFFICE$3]
(
    OFFICE,
    UCI
)
SELECT locationidud AS [OFFICE] 
,dim_client_key AS [UCI]
FROM red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON REPLACE(client_code,'EMP','')=fed_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE client_code LIKE 'EMP%'
and (push_to_ia = 0 or push_to_ia is null)

INSERT INTO [SVR-LIV-IASQ-01].InterAction.IDCAPP.[INT_DTS_LEVEL$3]
(
    LEVEL,
    UCI
)
SELECT   red_dw.dbo.dim_employee.jobtitle [LEVEL],
 dim_client_key AS [UCI]
FROM  red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON REPLACE(client_code,'EMP','')=fed_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE client_code LIKE 'EMP%'
and (push_to_ia = 0 or push_to_ia is null)

--INSERT INTO [SVR-LIV-IASQ-01].InterAction.IDCAPP.[INT_DTS_PRACTICEGROUPALL$3]
--(
--    MV_SYS_ID,
--    RELATIONSHIP_FIELD,
--    PRACTICE_GROUP_DEPT___ALL_,
--    UCI
--)
--SELECT 
--NULL AS MV_SYS_ID,
--NULL AS  RELATIONSHIP_FIELD,
--  hierarchylevel3hist AS [PRACTICE_GROUP_DEPT___ALL_],
--  dim_client_key AS   UCI
--FROM  red_dw.dbo.dim_client
--INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
-- ON REPLACE(client_code,'EMP','')=fed_code COLLATE DATABASE_DEFAULT
-- AND dss_current_flag='Y'
--INNER JOIN red_dw.dbo.dim_employee
-- ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
--WHERE client_code LIKE 'EMP%'

INSERT INTO [SVR-LIV-IASQ-01].InterAction.IDCAPP.[INT_DTS_PRATICEGROUPDIVISION$3]
(
 [PRACTICE_GROUP_DEPT__PRIMARY_],
  UCI
)
SELECT 
  hierarchylevel2hist AS [PRACTICE_GROUP_DEPT_PRIMARY_],
  dim_client_key AS   UCI
FROM  red_dw.dbo.dim_client
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON REPLACE(client_code,'EMP','')=fed_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE client_code LIKE 'EMP%'
AND dim_client_key<>0
and (push_to_ia = 0 or push_to_ia is null)

/*ADD ANY NEW INSERTS BEFORE THIS POINT*/ 



/*UPDATE TIMESTAMPS*/
update  [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[LastProcessedIA]
 SET [lastprocessed_update]= 
  (SELECT MAX(dss_update_time) FROM dbo.dim_client_matter_summary)
  ,
  [lastprocessed_create] =
  (SELECT MAX(dss_create_time) FROM dbo.dim_client_matter_summary)
  ,
  [lastprocessed_import] = 
  (select max([dss_insert_time]) from [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[contact_folder_import])
  


	UPDATE [SVR-LIV-IASQ-01].[IAProcessing].[dbo].[ProcessIA]
SET reprocess = 'N', lastprocessed = GETDATE()
WHERE [jobname] = 'PopulateIADelta'

END 
GO
