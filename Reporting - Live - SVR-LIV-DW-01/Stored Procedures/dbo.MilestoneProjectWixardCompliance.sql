SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






--JL 06-10-2020 - I have excluded "In House" as per Bob's request 
--JL 19-01-2021 - Excluded client 30645 as per ticket #85254
--JL 20-01-2021 - #85340 - excluded clients as per ticket 
--MT 15-06-2021 - #102676 - excluded clients as per ticket 
--JL 21-06-2012 - #103411 - excluded client and referral reason as per ticket 
--OK 29-06-2021 - #104483 - excluded client and linked file 
--MT 14-07-2021 - #106648 - excluded a number of matters
--ES 03-08-2021 - #109055 - excluded LTA matter types



CREATE PROCEDURE [dbo].[MilestoneProjectWixardCompliance]

AS 

BEGIN

SELECT hierarchylevel2hist AS Division
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,name AS [Fee Earner]
,fed_code AS [FedCode]
,1 AS [Number Live Matters]
,CASE WHEN Milestones.Completed>=1 THEN 1 ELSE 0 END  AS [WizardCompleted]
,CASE WHEN Milestones.Completed=0 THEN 1 ELSE 0 END  AS [WizardIncomplete]
,CONVERT(DATE,Milestones.DateLastCompleted,103) AS [LastTimeRan]
,DATEDIFF(DAY,CONVERT(DATE,Milestones.DateLastCompleted,103),GETDATE()) AS [DaysSinceWizardLastCompleted]
,CONVERT(DATE,GETDATE(),103) AS TodaysDate
,dim_matter_header_current.master_client_code AS [Client]
,dim_matter_header_current.master_matter_number AS [Matter]
,matter_description AS [MatterDescription]
,name AS [MatterOwner]
,dim_matter_header_current.present_position
,DATEDIFF(DAY,'2020-09-28',CONVERT(DATE,GETDATE()-1,103)) AS LiveDays
,DATEDIFF(DAY,'2020-09-28','2021-01-31') AS Day1
,DATEDIFF(DAY,'2020-09-28','2021-04-30') AS Day2
,DATEDIFF(DAY,'2020-09-28','2021-07-31') AS Day3
,date_closed_practice_management
,date_closed_case_management

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON  dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN tskComplete=1 THEN 1 ELSE 0 END) AS Completed
,SUM(CASE WHEN tskComplete=0 THEN 1 ELSE 0 END) AS Incompleted
,MAX(red_dw.dbo.datetimelocal(tskCompleted)) AS [DateLastCompleted]
FROM MS_Prod.dbo.dbTasks
WHERE tskType='MILESTONE'
AND tskDesc LIKE '%Milestone Wizard%' 
AND tskactive=1
GROUP BY fileID) AS Milestones
 ON ms_fileid=Milestones.fileID

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND dss_current_flag='Y' AND activeud=1
AND date_closed_case_management IS NULL
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'
AND leaver =0
AND NOT  (dim_matter_header_current.client_code = '00752920' AND referral_reason ='Recovery')
AND master_client_code <> '30645'
AND   RTRIM(dim_matter_header_current.client_code)+'/'+dim_matter_header_current.matter_number 
NOT IN  
('00015526/00000275',
'125409T/00001126',
'125409T/00000047',
'125409T/00001259',
'00707938/00001497',
'00707938/00001131',
'00707938/00001436',
'00707938/00001444',
'51130A/00001024',
'CNST/00000001',
'DHCLIN/00000001',
'DHLIAB/00000001',
'ELS/00000001',
'INQCOST/00000001',
'N00002/00000999',
'N00007/PPD001',
'N00007/VOL001',
'N00009/00000001',
'N00003/VOL001',
'N00004/VOL001',
'N00005/VOL001',
'N00006/PPD001',
'N00001/00000999',
'N00002/VOL001',
'N00005/PPD001',
'N00006/VOL001',
'N00033/00000999',
'N00034/00000999',
'N00003/00000999',
'N00004/00000999',
'N00004/PPD001',
'N00031/00000999',
'N00035/00000999',
'RPST/00000001',
'W16179/00000012',
'W16179/00000007',
'W16179/00000008',
'W16179/00000009',
'W16179/00000010',
'W16179/00000003',
'W16179/00000005',
'W16179/00000006',
'W16179/00000011',
'W16179/00000013',
'W16179/00000001',
'W16179/00000002',
'W16179/00000014',
'W15526/00000275', 
'POW025/00000423'

) 

AND  ms_fileid NOT IN 
(5090820,5090832,5090835,5090842,5090848,5090853,5091073,5091288,5091677
,5096365,5097171,5097193,5097355,5097677,5097684,5097751,5098182,5098201
,5098209,5098213,5098214,5098218,5098222,5098226,5098228,5098515,5098518
,5098521,5098530,5098898,5099062,5099250,
5097691,5097677,5098182,5098222,5098228
,4353408, 4930309
/*Added MT 14-07-2021 - #106648 - excluded a number of matters */
,4880088
,4915319
,4991042
,5200772
,4908444
,4908433
,4093238
,4698921
) --Old Remedy Cases to exclude per request from Bob H
AND CASE WHEN work_type_name='PL - Pol - CHIS'  AND dim_detail_core_details.is_this_the_lead_file='No' THEN 1 ELSE 0 END=0 -- Filter per #87593
AND ISNULL(dim_detail_core_details.trust_type_of_instruction,'') NOT IN
('In-house: CN','In-house: COP','In-house: EL/PL','In-house: General','In-house: INQ','In-house: Secondment') -- Per #87516
AND ISNULL(fee_arrangement,'') NOT IN ('Internal / No charge','Secondment') --Request 88266
AND ISNULL(dim_detail_core_details.is_this_a_linked_file,'') <> 'Yes'
AND ISNULL(dim_matter_header_current.master_client_code,'') <> 'W15347'

AND dim_matter_worktype.work_type_code NOT IN ('0008'
,'0018'
,'0019'
,'0020'
,'0022'
,'0023'
,'0024'
,'0025'
,'0028'
,'0030'
,'0031'
,'0034'
,'1000'
,'1001'
,'1002'
,'1003'
,'1004'
,'1005'
,'1006'
,'1007'
,'1008'
,'1009'
,'1010'
,'1011'
,'1012'
,'1013'
,'1014'
,'1015'
,'1016'
,'1017'
,'1018'
,'1019'
,'1020'
,'1021'
,'1022'
,'1023'
,'1024'
,'1025'
,'1026'
,'1027'
,'1028'
,'1029'
,'1030'
,'1031'
,'1032'
,'1033'
,'1034'
,'1035'
,'1036'
,'1037'
,'1038'
,'1039'
,'1040'
,'1041'
,'1042'
,'1043'
,'1044'
,'1045'
,'1046'
,'1047'
,'1048'
,'1049'
,'1050'
,'1051'
,'1052'
,'1053'
,'1054'
,'1055'
,'1056'
,'1057'
,'1058'
,'1059'
,'1060'
,'1061'
,'1062'
,'1063'
,'1064'
,'1065'
,'1066'
,'1067'
,'1068'
,'1069'
,'1070'
,'1071'
,'1072'
,'1073'
,'1074'
,'1075'
,'1076'
,'1077'
,'1078'
,'1079'
,'1080'
,'1081'
,'1082'
,'1083'
,'1084'
,'1085'
,'1086'
,'1087'
,'1088'
,'1089'
,'1090'
,'1091'
,'1092'
,'1093'
,'1094'
,'1095'
,'1096'
,'1097'
,'1098'
,'1099'
,'1100'
,'1101'
,'1102'
,'1103'
,'1104'
,'1105'
,'1106'
,'1107'
,'1108'
,'1109'
,'1110'
,'1111'
,'1112'
,'1113'
,'1114'
,'1115'
,'1116'
,'1117'
,'1118'
,'1119'
,'1120'
,'1121'
,'1122'
,'1123'
,'1124'
,'1125'
,'1126'
,'1127'
,'1128'
,'1129'
,'1130'
,'1131'
,'1132'
,'1133'
,'1134'
,'1135'
,'1136'
,'1137'
,'1138'
,'1139'
,'1140'
,'1141'
,'1142'
,'1143'
,'1144'
,'1145'
,'1146'
,'1147'
,'1148'
,'1149'
,'1150'
,'1151'
,'1152'
,'1153'
,'1154'
,'1155'
,'1156'
,'1157'
,'1158'
,'1159'
,'1160'
,'1161'
,'1162'
,'1319'
,'1320'
,'1321'
,'1322'
,'1323'
,'1324'
,'1325'
,'1326'
,'1327'
,'1328'
,'1329'
,'1330'
,'1331'
,'1332'
,'1333'
,'1334'
,'1340'
,'1341'
,'1342'
,'1343'
,'1344'
,'1345'
,'1346'
,'1347'
,'1348'
,'1349'
,'1350'
,'1351'
,'1352'
,'1353'
,'1354'
,'1509'
,'1563'
,'1566'
,'1567'
,'1569'
,'1570'
,'1583'
,'1586'
,'1587'
,'1588'
,'1599'
,'2037'
,'2038'
,'9000'
)

END


GO
