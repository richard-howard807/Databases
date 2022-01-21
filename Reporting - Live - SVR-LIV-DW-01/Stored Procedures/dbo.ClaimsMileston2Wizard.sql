SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE  [dbo].[ClaimsMileston2Wizard]

AS 

BEGIN
SELECT hierarchylevel2hist AS Division
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,name AS [Fee Earner]
,fed_code AS [FedCode]
,1 AS [Number Live Matters]
,CASE WHEN ISNULL(Milestones.Completed,0)>=1 THEN 1 ELSE 0 END  AS [No of Matters Workflow Commenced]
,CASE WHEN ISNULL(Milestones.Completed,0)=0 THEN 1 ELSE 0 END  AS [No of Matters Workflow Not Commenced]
,CASE WHEN ISNULL(Milestones.Completed,0)>=1 THEN 1 ELSE 0 END  AS [No of Matters Workflow Completed]
,CASE WHEN ISNULL(Milestones.Completed,0)=0 THEN 1 ELSE 0 END  AS [No of Matter Workflow Not Completed]
,dim_matter_header_current.master_client_code AS [Client]
,dim_matter_header_current.master_matter_number AS [Matter]
,matter_description AS [MatterDescription]
,ISNULL([Review Matter Process],'Not Outstanding') AS [Review Matter Process]
,ISNULL([FIC process],'Not Outstanding') AS [FIC process]
,ISNULL([Intel Process],'Not Outstanding') AS [Intel Process]
,ISNULL([MIIC Process],'Not Outstanding') AS [MIIC Process]
,ISNULL([CRU Process],'Not Outstanding') AS [CRU Process]
,ISNULL([Magic Phone Call Process],'Not Outstanding') AS [Magic Phone Call Process]
,ISNULL([Contact Insured Process],'Not Outstanding') AS [Contact Insured Process]
,ISNULL([Vulnerable Person Process],'Not Outstanding') AS [Vulnerable Person Process]
,ISNULL([Report to Client Process],'Not Outstanding') AS [Report to Client Process]
,ISNULL([Report MI Process],'Not Outstanding') AS [Report MI Process]
,ISNULL([Date of Next File Review],'Not Outstanding') AS [Date of Next File Review]

,name AS [MatterOwner]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT  AND dss_current_flag='Y' AND activeud=1
LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1 THEN 1 ELSE 0 END AS Completed FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_ReviewMatter' AND tskMSStage='2') AS Milestones
 ON ms_fileid=Milestones.fileID
LEFT OUTER JOIN (SELECT fileID,CASE WHEN  tskActive=1 THEN 1 ELSE 0 END AS Completed FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_1270_DateNextFR' AND tskMSStage='2') AS Workflow
 ON ms_fileid=Workflow.fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Review Matter Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_ReviewMatter' AND tskMSStage='2') AS [Review Matter Process]
 ON ms_fileid=[Review Matter Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [FIC process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_021_02_010_FIC' AND tskMSStage='2') AS [FIC process]
 ON ms_fileid=[FIC process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Intel Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_023_02_010_Intel' AND tskMSStage='2') AS [Intel Process]
 ON ms_fileid=[Intel Process].fileID

 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [MIIC Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_01_02_010_TechCheckMot' AND tskMSStage='2') AS [MIIC Process]
 ON ms_fileid=[MIIC Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [CRU Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_028_02_010_CRU' AND tskMSStage='2') AS [CRU Process]
 ON ms_fileid=[CRU Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Magic Phone Call Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_020_010_MagicPhone' AND tskMSStage='2') AS [Magic Phone Call Process]
 ON ms_fileid=[Magic Phone Call Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Contact Insured Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_270_ContactInsured' AND tskMSStage='2') AS [Contact Insured Process]
 ON ms_fileid=[Contact Insured Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Vulnerable Person Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_280_Vulnerable' AND tskMSStage='2') AS [Vulnerable Person Process]
 ON ms_fileid=[Vulnerable Person Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Report to Client Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_310_RepClient' AND tskMSStage='2') AS [Report to Client Process]
 ON ms_fileid=[Report to Client Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Report MI Process]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_1260_ReportMI' AND tskMSStage='2') AS [Report MI Process]
 ON ms_fileid=[Report MI Process].fileID
 LEFT OUTER JOIN (SELECT fileID,CASE WHEN tskComplete=1 AND tskActive=1  THEN 'Completed'
 WHEN tskActive=1 AND tskComplete=0 THEN 'Outstanding'
 WHEN tskActive=0 AND tskComplete=0 THEN 'Deleted' 
 ELSE 'Not Outstanding' END AS [Date of Next File Review]
FROM ms_prod.dbo.dbTasks WHERE tskFilter='tsk_02_010_1270_DateNextFR' AND tskMSStage='2') AS [Date of Next File Review]
 ON ms_fileid=[Date of Next File Review].fileID
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details 
ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE date_opened_case_management>='2022-01-17'
AND hierarchylevel2hist='Legal Ops - Claims'
AND date_closed_case_management IS NULL
AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(referral_reason,'')<>'Advice only'
AND ISNULL(referral_reason,'')<> 'In House'
AND leaver =0
AND NOT  (dim_matter_header_current.client_code = '00752920' AND referral_reason ='Recovery')
AND master_client_code <> '30645'
AND CASE WHEN work_type_name='PL - Pol - CHIS'  AND dim_detail_core_details.is_this_the_lead_file='No' THEN 1 ELSE 0 END=0 -- Filter per #87593
AND ISNULL(dim_detail_core_details.trust_type_of_instruction,'') NOT IN
('In-house: CN','In-house: COP','In-house: EL/PL','In-house: General','In-house: INQ','In-house: Secondment') -- Per #87516
AND ISNULL(fee_arrangement,'') NOT IN ('Internal / No charge','Secondment') --Request 88266
AND ISNULL(dim_detail_core_details.is_this_a_linked_file,'') <> 'Yes'
AND ISNULL(dim_matter_header_current.master_client_code,'') <> 'W15347'
AND dim_matter_worktype.work_type_code NOT IN ('0008'
,'0018','0019','0020','0022','0023','0024','0025','0028','0030','0031','0034','1000','1001'
,'1002','1003','1004','1005','1006','1007','1008','1009','1010','1011','1012','1013','1014'
,'1015','1016','1017','1018','1019','1020','1021','1022','1023','1024','1025','1026','1027'
,'1028','1029','1030','1031','1032','1033','1034','1035','1036','1037','1038','1039','1040'
,'1041','1042','1043','1044','1045','1046','1047','1048','1049','1050','1051','1052','1053'
,'1054','1055','1056','1057','1058','1059','1060','1061','1062','1063','1064','1065','1066'
,'1067','1068','1069','1070','1071','1072','1073','1074','1075','1076','1077','1078','1079'
,'1080','1081','1082','1083','1084','1085','1086','1087','1088','1089','1090','1091','1092'
,'1093','1094','1095','1096','1097','1098','1099','1100','1101','1102','1103','1104','1105'
,'1106','1107','1108','1109','1110','1111','1112','1113','1114','1115','1116','1117','1118'
,'1119','1120','1121','1122','1123','1124','1125','1126','1127','1128','1129','1130','1131'
,'1132','1133','1134','1135','1136','1137','1138','1139','1140','1141','1142','1143','1144'
,'1145','1146','1147','1148','1149','1150','1151','1152','1153','1154','1155','1156','1157'
,'1158','1159','1160','1161','1162','1319','1320','1321','1322','1323','1324','1325','1326'
,'1327','1328','1329','1330','1331','1332','1333','1334','1340','1341','1342','1343','1344'
,'1345','1346','1347','1348','1349','1350','1351','1352','1353','1354','1509','1563','1566'
,'1567','1569','1570','1583','1586','1587','1588','1599','2037','2038','9000')
--AND master_client_code='W20218' AND master_matter_number='517'
AND name <>'Steve Hassall'

END
GO
