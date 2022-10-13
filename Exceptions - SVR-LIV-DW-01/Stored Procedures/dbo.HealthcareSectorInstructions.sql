SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE 	[dbo].[HealthcareSectorInstructions]

AS
BEGIN
SELECT 
[Client]
,[Matter]
,[Matter Description]
,[Team] 
,[Department] 
,[Work Type] 
,[Work Type Group] 
,[Trust/Client]
,[Client Group Name] 
,[Client Sector] 
,[Insured Client Name] 
,[Insured Sector]
,[Lot]
,[Work Category]
,[Trust Region]
,[Date Case Opened]
,[Profit Costs Billed 16/17]
,[Profit Costs Billed 17/18]
,[Profit Costs Billed 18/19]
,[Profit Costs Billed 19/20]

,[New Instructions FY 2016/2017]
,[New Instructions FY 2017/2018]
,[New Instructions FY 2018/2019]
,[New Instructions FY 2019/2020]


,CASE WHEN Lot='Commercial' THEN [Profit Costs Billed 16/17] ELSE 0 END AS [Commercial Profit Costs Billed 16/17]
,CASE WHEN Lot='Commercial' THEN [Profit Costs Billed 17/18] ELSE 0 END AS [Commercial Profit Costs Billed 17/18]
,CASE WHEN Lot='Commercial' THEN [Profit Costs Billed 18/19] ELSE 0 END AS [Commercial Profit Costs Billed 18/19]
,CASE WHEN Lot='Commercial' THEN [Profit Costs Billed 19/20] ELSE 0 END AS [Commercial Profit Costs Billed 19/20]

,CASE WHEN Lot='Commercial' THEN [New Instructions FY 2016/2017] ELSE 0 END AS [Commercial New Instructions FY 2016/2017]
,CASE WHEN Lot='Commercial' THEN [New Instructions FY 2017/2018] ELSE 0 END AS [Commercial New Instructions FY 2017/2018]
,CASE WHEN Lot='Commercial' THEN [New Instructions FY 2018/2019] ELSE 0 END AS [Commercial New Instructions FY 2018/2019]
,CASE WHEN Lot='Commercial' THEN [New Instructions FY 2019/2020] ELSE 0 END AS [Commercial New Instructions FY 2019/2020]


,CASE WHEN Lot='Employment' THEN [Profit Costs Billed 16/17] ELSE 0 END AS [Employment Profit Costs Billed 16/17]
,CASE WHEN Lot='Employment' THEN [Profit Costs Billed 17/18] ELSE 0 END AS [Employment Profit Costs Billed 17/18]
,CASE WHEN Lot='Employment' THEN [Profit Costs Billed 18/19] ELSE 0 END AS [Employment Profit Costs Billed 18/19]
,CASE WHEN Lot='Employment' THEN [Profit Costs Billed 19/20] ELSE 0 END AS [Employment Profit Costs Billed 19/20]


,CASE WHEN Lot='Employment' THEN [New Instructions FY 2016/2017] ELSE 0 END AS [Employment New Instructions FY 2016/2017]
,CASE WHEN Lot='Employment' THEN [New Instructions FY 2017/2018] ELSE 0 END AS [Employment New Instructions FY 2017/2018]
,CASE WHEN Lot='Employment' THEN [New Instructions FY 2018/2019] ELSE 0 END AS [Employment New Instructions FY 2018/2019]
,CASE WHEN Lot='Employment' THEN [New Instructions FY 2019/2020] ELSE 0 END AS [Employment New Instructions FY 2019/2020]


,CASE WHEN Lot='Healthcare Advisory' THEN [Profit Costs Billed 16/17] ELSE 0 END AS [Healthcare Profit Costs Billed 16/17]
,CASE WHEN Lot='Healthcare Advisory' THEN [Profit Costs Billed 17/18] ELSE 0 END AS [Healthcare Profit Costs Billed 17/18]
,CASE WHEN Lot='Healthcare Advisory' THEN [Profit Costs Billed 18/19] ELSE 0 END AS [Healthcare Profit Costs Billed 18/19]
,CASE WHEN Lot='Healthcare Advisory' THEN [Profit Costs Billed 19/20] ELSE 0 END AS [Healthcare Profit Costs Billed 19/20]


,CASE WHEN Lot='Healthcare Advisory' THEN [New Instructions FY 2016/2017] ELSE 0 END AS [Healthcare New Instructions FY 2016/2017]
,CASE WHEN Lot='Healthcare Advisory' THEN [New Instructions FY 2017/2018] ELSE 0 END AS [Healthcare New Instructions FY 2017/2018]
,CASE WHEN Lot='Healthcare Advisory' THEN [New Instructions FY 2018/2019] ELSE 0 END AS [Healthcare New Instructions FY 2018/2019]
,CASE WHEN Lot='Healthcare Advisory' THEN [New Instructions FY 2019/2020] ELSE 0 END AS [Healthcare New Instructions FY 2019/2020]



,CASE WHEN Lot='Property' THEN [Profit Costs Billed 16/17] ELSE 0 END AS [Property Profit Costs Billed 16/17]
,CASE WHEN Lot='Property' THEN [Profit Costs Billed 17/18] ELSE 0 END AS [Property Profit Costs Billed 17/18]
,CASE WHEN Lot='Property' THEN [Profit Costs Billed 18/19] ELSE 0 END AS [Property Profit Costs Billed 18/19]
,CASE WHEN Lot='Property' THEN [Profit Costs Billed 19/20] ELSE 0 END AS [Property Profit Costs Billed 19/20]

,CASE WHEN Lot='Property' THEN [New Instructions FY 2016/2017] ELSE 0 END AS [Property New Instructions FY 2016/2017]
,CASE WHEN Lot='Property' THEN [New Instructions FY 2017/2018] ELSE 0 END AS [Property New Instructions FY 2017/2018]
,CASE WHEN Lot='Property' THEN [New Instructions FY 2018/2019] ELSE 0 END AS [Property New Instructions FY 2018/2019]
,CASE WHEN Lot='Property' THEN [New Instructions FY 2019/2020] ELSE 0 END AS [Property New Instructions FY 2019/2020]



,CASE WHEN [Work Category]='NHS Resolution' THEN 'NHS R Summary' 
WHEN [Work Category]='MDOs' THEN 'MDOs Summary'
WHEN [Work Category]='Med Mal' THEN 'Med Mal Summary'
WHEN [Work Category]='Direct Instructions' AND [Trust Region]='Northern'  THEN 'Direct Instructions – North Summary'
WHEN [Work Category]='NHS Resolution'  AND UPPER([Work Type]) LIKE'%INQUEST%'  AND [Trust Region]='Northern' THEN 'NHS R Inquests – North Summary'
WHEN [Work Category]='Direct Instructions' AND [Trust Region]='Midlands'  THEN 'Direct Instructions – Midlands Summary'
WHEN [Work Category]='NHS Resolution'  AND UPPER([Work Type]) LIKE'%INQUEST%'  AND [Trust Region]='Midlands' THEN 'NHS R Inquests – Midlands Summary'
WHEN [Work Category]='Direct Instructions' AND [Trust Region]='London'  THEN 'Direct Instructions – London Summary'
WHEN [Work Category]='NHS Resolution'  AND UPPER([Work Type]) LIKE'%INQUEST%'  AND [Trust Region]='London' THEN 'NHS R Inquests – London Summary'
END AS SummaryTab




--4. “” – Limit the data to where “Work Category is “Direct Instructions” AND “Trust Region” is “North”
--5. “NHS R Inquests – North Summary” – Limit the data to where “Work Category” is “NHS Resolution” AND “Work Type” contains “inquest” AND “Trust Region” is “North”
--6. “Direct Instructions – North Summary” – Limit the data to where “Work Category is “Direct Instructions” AND “Trust Region” is “Midlands”
--7. “NHS R Inquests – North Summary” – Limit the data to where “Work Category” is “NHS Resolution” AND “Work Type” contains “inquest” AND “Trust Region” is “Midlands”
--8. “Direct Instructions – North Summary” – Limit the data to where “Work Category is “Direct Instructions” AND “Trust Region” is “London”
--9. “NHS R Inquests – North Summary” – Limit the data to where “Work Category” is “NHS Resolution” AND “Work Type” contains “inquest” AND “Trust Region” is “London”
,work_type_group
,sector
FROM 
(

SELECT 
a.client_code AS [Client]
,a.matter_number AS [Matter]
,a.matter_description AS [Matter Description]
,hierarchylevel4hist AS [Team] 
,hierarchylevel3hist AS [Department] 
,work_type_name AS [Work Type] 
,work_type_group AS [Work Type Group] 
,COALESCE(defendant_trust,a.client_name) AS [Trust/Client]-- NHS208 OR if blank, Client Name 
,a.client_group_name AS [Client Group Name] 
,sector AS [Client Sector] 
,NULL AS [Insured Client Name] -- name from TRA00001 Directory capacity 
,insured_sector AS [Insured Sector]-- NMI086 
,CASE WHEN work_type_name IN
(
'Administration of Estates','Archive','Banking','Commercial Contracts','Commercial drafting (advice)','Company'
,'Competition Law','Construction','Consumer debt','Contract','Corporate DO NOT USE','Corporate transactions'
,'Defamation','Due Dilligence','General Advice','Governance & Regulatory','Intellectual property','Invoice Debt'
,'Non-contentious IP & IT Contracts','Partnership','Partnerships & JVs','Procurement','Secured lending','Share Structures & Company Reorganisation'
,'Share Structures & Company Reorganisatio'
)THEN 'Commercial'

WHEN work_type_name IN 
(
'Capability (inc Occupational health)','Constructive dismissal'
,'discrimination','Constructive unfair dismissal','Contracts/Policies/Procedures(inc hrs wk)'
,'Data Protection'
,'Disciplinary process','Discrimination(sex,race,sex orien,disab,Early Conciliation','Employment Advice Line','Employment DO NOT USE','General Advice : Employment'
,'Grievance','Holidays (including holiday pay)','HR Rely','Investigation','Pensions','Redundancy','Reorganisation','Settlement Agreements','Trade Union Activities'
,'Training','TUPE','Unfair dismissal','Unfair dismissal and discrimination','Unlawful deductions','Wages (inc minimum wage, notice pay)','Whistleblowing'
,'Working Time Regulations','Constructive unfair dismissal','Contracts/Policies/Procedures(inc hrs wk','Discrimination(sex,race,sex orien,disab'
,'Trade Union Activities','TUPE','Unlawful deductions'                    
)  THEN 'Employment'

WHEN work_type_name IN
(
'Comm conveyancing (business premises)','Landlord & Tenant – Commercial','Landlord & Tenant – Residential','Leases-granting,taking,assigning,renewin'
,'Property Dispute Commercial other','Property DO NOT USE','Property redevelopment','Property View','Remortgage','Residential conveyancing (houses/flats)'
,'Landlord & Tenant - Commercial','Landlord & Tenant - Residential'
) THEN 'Property'

ELSE 'Healthcare Advisory'
END 
AS [Lot]
,CASE WHEN a.client_group_name='NHS Resolution' THEN 'NHS Resolution'

WHEN (a.client_code IN ('00350490','00435869','00048564','00097607') OR a.client_group_code='00000114') AND  department_code IN ('0005','0009' ) THEN 'Med Mal'
WHEN a.client_group_code='00000029' AND department_code IN ('0005') THEN 'Med Mal'



WHEN a.client_code IN ('00134914','T15069','00134912','00134918')  AND  department_code IN ('0005','0009' ) THEN 'MDOs'
WHEN a.client_code='00733225' AND department_code IN ('0005','0009' ) THEN 'MDOs'
WHEN a.client_group_code='00000029' AND department_code IN ('0009' ) THEN 'MDOs'

WHEN sector='Health' THEN 'Direct Instructions'

ELSE 'Other' END
 
AS [Work Category]
,CASE WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%alder hey%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%blackpool %' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%bolton%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%bridgewater community%' THEN 'Northern' 
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%manchester%' THEN 'Northern' 
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%chesterfield%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%clatterbridge%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%chestert%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%lancashire%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%leicestershire%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%liverpool%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%mersey%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%nhs blood & transplantnhs england%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%cumbria%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%north west%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%southport%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%ormskirkst%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%st helens%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%knowsley %' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%stockport%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%tameside%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%christie nhs foundation trust%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%pennine%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%walton%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%warrington%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%halton%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%wirral%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%wrightington%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%wigan%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%leigh%' THEN 'Northern'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%birmingham%' THEN 'Midlands'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%burton%' THEN 'Midlands'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%dudley%' THEN 'Midlands'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%staffordshire%' THEN 'Midlands'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%stoke%' THEN 'Midlands'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%north midlands%' THEN 'Midlands'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%epsom & st helier university hospitals nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%fareham & gosport ccgfrimley health nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%great ormond street hospital for children nhs foundation tru%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%great western hospitals nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%guy''s & st thomas'' nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%heatherwood & wexham park hospitals nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%homerton university hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%hounslow & richmond%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%imperial college healthcare nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%kings college hospital nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%london ambulance service nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%luton & dunstable university%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%maidstone & tunbridge wells nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%milton keynes hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%nhs oxfordshire clinical commissioning group%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%north east london nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%north essex partnership nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%oxford university hospitals nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%oxleas nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%priory group%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%public health england%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%queen victoria hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%royal free london nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%royal surrey county hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%south central ambulance service nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%south eastern hampshire clinical commissioning group%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%south london & maudsley nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%southend university hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%st george''s healthcare nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%surrey & borders partnership nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%surrey downs clinical commissioning group (hosted service)%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%the royal marsden nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%the royal orthopaedic hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%university college london hospitals nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west hampshire clinical commissioning group%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west hertfordshire hospitals nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west london mental health nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west middlesex university hospital nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%westminster hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%barnet & chase farm hospitals nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%barnet, enfield & haringey mental health nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%barts health nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%basildon & thurrock university hospitals nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%buckinghamshire healthcare nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%camden & islington nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%central & north west london nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%central london community healthcare nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%chelsea & westminster hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%croydon health services nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%dorset county hospital nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%ealing hospital nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%east & north hertfordshire nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%east kent hospitals university nhs foundation trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%east of england ambulance service%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%east sussex healthcare nhs trust%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%eastbourne, hailsham%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%barnet%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%enfield%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%haringey%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%barts%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%basildon%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%thurrock%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%buckinghamshire %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%camden%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%islington%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%central London %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%chelsea %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%Westminster%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%croydon%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%dorset %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%ealing %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%hertfordshire%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%kent%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%east sussex%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%eastbourne%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%hailsham%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%epsom %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%st helier %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%fareham %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%frimley%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%great Ormond %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%great Western%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%heatherwood%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%wexham park %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%homerton %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%hounslow%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%richmond%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%luton %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%dunstable%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%maidstone%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%tunbridge%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%milton keynes%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%oxfordshire%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%east london%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%essex%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%oxford%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%oxleas%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%london%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%surrey%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%south eastern hampshire%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%south london %' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%maudsley%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%southend%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%surrey%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%london%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west hampshire%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west hertfordshire%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west london%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%west middlesex%' THEN 'London'
WHEN LOWER(COALESCE(defendant_trust,a.client_name)) LIKE '%westminster%' THEN 'London'






ELSE NULL END  AS [Trust Region]
,date_opened_practice_management AS [Date Case Opened]
,ISNULL(PC1.ProfitCosts,0) AS [Profit Costs Billed 16/17]
,ISNULL(PC2.ProfitCosts,0) AS [Profit Costs Billed 17/18]
,ISNULL(PC3.ProfitCosts,0) AS [Profit Costs Billed 18/19]
,ISNULL(PC4.ProfitCosts,0) AS [Profit Costs Billed 19/20]

,CASE WHEN date_opened_practice_management BETWEEN '2016-05-01' AND '2017-04-30' THEN 1 ELSE 0 END AS [New Instructions FY 2016/2017]
,CASE WHEN date_opened_practice_management BETWEEN '2017-05-01' AND '2018-04-30' THEN 1 ELSE 0 END AS [New Instructions FY 2017/2018]
,CASE WHEN date_opened_practice_management BETWEEN '2018-05-01' AND '2019-04-30' THEN 1 ELSE 0 END AS [New Instructions FY 2018/2019] 
,CASE WHEN date_opened_practice_management BETWEEN '2019-05-01' AND '2020-04-30' THEN 1 ELSE 0 END AS [New Instructions FY 2019/2020] 
 
,work_type_group
,sector
,department_code='0009'

FROM red_dw.dbo.dim_matter_header_current AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_dimension_main  AS b WITH (NOLOCK)
 ON a.dim_matter_header_curr_key=b.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_client ON a.client_code=dim_client.client_code
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH (NOLOCK)
 ON a.fee_earner_code=fed_code AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH (NOLOCK)
 ON a.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim WITH (NOLOCK)
 ON b.dim_detail_claim_key=dim_detail_claim.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH (NOLOCK)  
 ON b.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
LEFT OUTER JOIN(SELECT dim_matter_header_curr_key,SUM(fees_total) AS ProfitCosts
FROM red_dw.dbo.fact_bill_matter_detail WITH (NOLOCK) WHERE bill_date BETWEEN '2016-05-01' AND '2017-04-30' 
GROUP BY dim_matter_header_curr_key) AS PC1
 ON a.dim_matter_header_curr_key=PC1.dim_matter_header_curr_key

LEFT OUTER JOIN(SELECT dim_matter_header_curr_key,SUM(fees_total) AS ProfitCosts
FROM red_dw.dbo.fact_bill_matter_detail WITH (NOLOCK) WHERE bill_date BETWEEN '2017-05-01' AND '2018-04-30' 
GROUP BY dim_matter_header_curr_key) AS PC2
 ON a.dim_matter_header_curr_key=PC2.dim_matter_header_curr_key

LEFT OUTER JOIN(SELECT dim_matter_header_curr_key,SUM(fees_total) AS ProfitCosts
FROM red_dw.dbo.fact_bill_matter_detail WITH (NOLOCK)  WHERE bill_date BETWEEN '2018-05-01' AND '2019-04-30' 
GROUP BY dim_matter_header_curr_key) AS PC3
 ON a.dim_matter_header_curr_key=PC3.dim_matter_header_curr_key 

 LEFT OUTER JOIN(SELECT dim_matter_header_curr_key,SUM(fees_total) AS ProfitCosts
FROM red_dw.dbo.fact_bill_matter_detail WITH (NOLOCK)  WHERE bill_date BETWEEN '2019-05-01' AND '2020-04-30' 
GROUP BY dim_matter_header_curr_key) AS PC4
 ON a.dim_matter_header_curr_key=PC4.dim_matter_header_curr_key 



WHERE  reporting_exclusions=0
AND (sector='Health' OR 

(

(a.client_code IN ('00350490','00435869','00048564','00097607','00733225')  OR a.client_group_code IN ('00000114','00000029'))
AND  department_code IN ('0005','0009' )
)
)


AND (a.dim_matter_header_curr_key IN (SELECT DISTINCT dim_matter_header_curr_key FROM red_dw.dbo.fact_bill_matter_detail WITH (NOLOCK)
WHERE fact_bill_matter_detail.bill_date >='2016-05-01') OR date_opened_practice_management>='2016-05-01')
) AS AllData

--where [Work Category]='Other'


END


GO
