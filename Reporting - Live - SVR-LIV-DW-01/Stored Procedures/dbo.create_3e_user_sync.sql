SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--USE [Reporting]
--GO
--/****** Object:  StoredProcedure [dbo].[create_3e_user_sync]    Script Date: 02/06/2016 14:48:47 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO



CREATE PROCEDURE [dbo].[create_3e_user_sync] --EXEC  [dbo].[create_3e_user_sync]


as 

insert into red_dw.dbo.ds_sh_3e_user_sync



select [Timekeeper].[TkprIndex] as timekeeperindex,
[Timekeeper].Entity,
UPPER([Timekeeper].TRE_User) AS TRE_User,
isnull([ds_sh_employee].payrollid,[ds_sh_employee].displayemployeeid) as payrollid,
[ds_sh_employee].forename as firstname,
[ds_sh_employee].surname as surname,
[ds_sh_employee].knownas as knownas,
[ds_sh_employee].knownas + ' ' + [ds_sh_employee].surname as name,
[ds_sh_employee].dateofbirth as DOB,
[ds_sh_employee].title as prefix,
case when [ds_sh_employee].sex = 1 then 'Male' else 'Female' end as gender,
[ds_sh_employee].workemail as email,
[ds_sh_employee].workphone as phonenumber,
'SBC\'+[ds_sh_employee].windowsusername as username,
[ds_sh_employee].employeestartdate as startdate,
Office.[Code] as office,
ISNULL(CASE WHEN [ds_sh_employee_jobs].locationidud = 'Manchester 3PP' THEN 'Manchester (3PP)'
WHEN [ds_sh_employee_jobs].locationidud = 'London NFL' THEN 'London (NFL)'
WHEN [ds_sh_employee_jobs].locationidud = 'Manchester PMC' THEN 'Manchester (PMC)'
WHEN [ds_sh_employee_jobs].locationidud = 'London EC3' THEN 'London (EC3)'
ELSE [ds_sh_employee_jobs].locationidud end ,'Liverpool') as officename,
[Site].Address AS address,
[Site].SiteType AS sitetype,
ISNULL(Department.[Code],10) as businessline,
Section.[Code] as team,
Title.[Code] as jobrole,
jobtitle as hrtitle,
isnull(bcm.payrollid,bcm.displayemployeeid) as payrollid_BCM,
'TKPR_1' as ratetype,
1 defaultrate,
case when [ds_sh_employee_jobs].levelidud IN ('Business Services','Legal Support','Other FE','Secondee') then 'NFE' else 'FE' end as tkrtype,
CASE WHEN [ds_sh_employee].leaver = 0 THEN 1 ELSE 0 END as userstatusid,
case when [ds_sh_employee].leaver = 0 then 'Active' when [ds_sh_employee].leaver =1 then 'Inactive' end as userstatus,
[ds_sh_employee].leftdate as leaverdate,
case when [ds_sh_employee].dss_update_time >= ds_sh_employee_jobs.dss_update_time then [ds_sh_employee].dss_update_time else ds_sh_employee_jobs.dss_update_time end as dss_update_time

FROM red_dw.[dbo].[ds_sh_employee]
left join red_dw.[dbo].ds_sh_employee_jobs on [ds_sh_employee].employeeid = ds_sh_employee_jobs.employeeid and ds_sh_employee_jobs.dss_current_flag = 'Y' and sys_activejob = 1
left join red_dw.[dbo].[ds_sh_valid_hierarchy_x] on ds_sh_employee_jobs.hierarchynode = [ds_sh_valid_hierarchy_x].hierarchynode and [ds_sh_valid_hierarchy_x].dss_current_flag ='Y'
left join red_dw.[dbo].[ds_sh_employee] as bcm on upper(ds_sh_employee_jobs.reportingbcmidud) = bcm.employeeid and bcm.dss_current_flag ='Y'
left join [SVR-LIV-3ESQ-01].TE_3E_UAT03.dbo.Section on  ISNULL(CASE WHEN  [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Local Government & Police%' THEN 'Local Government & Police'
WHEN 
[ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Motor Multi Track%' THEN 'Multi Track'
 WHEN 
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Large Loss & Technical%' THEN 'Large Loss & Technical'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Wills,Tax,Trust & Probate%' THEN 'Wills,Tax,Trust & Probate'
  WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Commercial Insurance%' THEN 'Commercial Insurance'
WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'CDR Manchester%' THEN 'Commercial Dispute Resolution'
WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Real Estate%' THEN 'Real Estate'
WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Family%' THEN 'Family'
WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Health%' THEN 'Healthcare'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Corporate%' THEN 'Corporate'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Construction%' THEN 'Construction'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Professional Risk%' THEN 'Professional Risk'
  WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Regulatory Services%' THEN 'Regulatory Services'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Private Client%' THEN 'Private Client'
  WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Employment%' THEN 'Employment'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Costs%' THEN 'Costs'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Compli%' THEN 'Compliance'
 WHEN
 [ds_sh_valid_hierarchy_x].hierarchylevel4 LIKE 'Legal Accounts%' THEN 'Finance'
 ELSE 
  [ds_sh_valid_hierarchy_x].hierarchylevel4 
 END ,'Default') = Section.[Description] COLLATE DATABASE_DEFAULT
left join [SVR-LIV-3ESQ-01].TE_3E_UAT03.dbo.Department on [ds_sh_valid_hierarchy_x].hierarchylevel2 = Department.[Description] COLLATE DATABASE_DEFAULT
left join [SVR-LIV-3ESQ-01].TE_3E_UAT03.dbo.Office ON ISNULL(CASE WHEN [ds_sh_employee_jobs].locationidud = 'Manchester 3PP' THEN 'Manchester (3PP)'
WHEN [ds_sh_employee_jobs].locationidud = 'London NFL' THEN 'London (NFL)'
WHEN [ds_sh_employee_jobs].locationidud = 'Manchester PMC' THEN 'Manchester (PMC)'
WHEN [ds_sh_employee_jobs].locationidud = 'London EC3' THEN 'London (EC3)'
ELSE [ds_sh_employee_jobs].locationidud end ,'Liverpool') = Office.Description COLLATE DATABASE_DEFAULT
LEFT JOIN [SVR-LIV-3ESQ-01].TE_3E_UAT03.[dbo].[Site] ON Office.Site = [Site].SiteIndex
left join [SVR-LIV-3ESQ-01].TE_3E_UAT03.[dbo].[Title] ON [ds_sh_employee_jobs].levelidud = [Title].Description COLLATE DATABASE_DEFAULT
left join [SVR-LIV-3ESQ-01].TE_3E_UAT03.[dbo].[Timekeeper] on isnull([ds_sh_employee].payrollid,[ds_sh_employee].displayemployeeid) = [Timekeeper].Number COLLATE DATABASE_DEFAULT

where 

--[ds_sh_employee].employeeid = 'D6885F97-1FD9-44C9-8BC9-9A4D111D01F5'
--isnull([ds_sh_employee].payrollid,[ds_sh_employee].displayemployeeid) = '3520'
ds_sh_employee.dss_current_flag ='Y'
and 
isnull([ds_sh_employee].payrollid,[ds_sh_employee].displayemployeeid) IN
(
'5428',
'5151',
'5153',
'5157',
'5160',
'5185',
'5250',
'5263',
'5232',
'5245',
'5223',
'3856',
'5474',
'3853',
'4458',
'2046',
'5355',
'5349',
'5192',
'5230',
'5235',
'5255',
'5418',
'5177',
'5307',
'5268',
'5501',
'3854',
'5434',
'5237',
'5251',
'5146',
'4778',
'5466',
'5149',
'5164',
'5208',
'5186',
'5234',
'5226',
'5183',
'5468',
'3928',
'5269',
'4106',
'831',
'1371',
'5196',
'5222',
'5350',
'5154',
'5174',
'5175',
'5170',
'5205',
'5217',
'5224',
'5191',
'5241',
'5243',
'5258',
'5236',
'5262',
'5248',
'5244',
'5193',
'5485',
'5482',
'5483',
'3880',
'3878',
'3881',
'3877',
'5134',
'5495',
'5158',
'5184',
'5202',
'5505',
'5494',
'5492',
'5209',
'5021',
'5488',
'5163',
'5450',
'5463',
'5076',
'1932',
'5427',
'5449',
'871',
'5444',
'5277',
'788',
'765',
'5411',
'5445',
'5378',
'4302',
'3684',
'5455',
'5421',
'5440',
'2072',
'5432',
'5348',
'3748',
'4559',
'2010',
'5138',
'1029',
'1881',
'1839',
'5152',
'5156',
'5178',
'5179',
'5198',
'5227',
'5212',
'5206',
'773',
'764',
'5484',
'1986',
'4185',
'1361',
'4118',
'1237',
'5500',
'5125',
'5137',
'5228',
'5433',
'5439',
'5402',
'5442',
'5460',
'5504',
'5375',
'5448',
'548',
'978',
'2098',
'5409',
'3009',
'1152',
'5354',
'954',
'5357',
'4346',
'5441',
'5161',
'1996',
'5446',
'5102',
'5083',
'4835',
'5454',
'5437',
'5018',
'5502',
'5451',
'5119',
'5377',
'772',
'554',
'763',
'846',
'186',
'42',
'5385',
'5478',
'5476',
'1196',
'5477',
'5089',
'1015',
'5342',
'5352',
'5393',
'5438',
'5435',
'5420',
'5489',
'5266',
'5461',
'5267',
'5429',
'5503',
'5309',
'5456',
'5465',
'5423',
'5431',
'5464',
'5458',
'5490',
'5390',
'5424',
'5447',
'5304',
'5430',
'5365',
'5171',
'5176',
'5189',
'5211',
'5187',
'5190',
'5145',
'5425',
'5499',
'5497',
'5487',
'5467'
)



GO
