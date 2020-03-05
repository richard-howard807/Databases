SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[NewStarterIssueLog]
AS
BEGIN
SELECT
payrollid
,firstname
,surname
,knownas
,name
,DOB
,prefix
,gender
,email
,phonenumber
,username
,startdate
,office
,officename
,address
,sitetype
,businessline
,cdDesc AS [Business Description]
,team
,Section.Description AS [Team Name]
,jobrole
,hrtitle
,payrollid_BCM
,ratetype
,defaultrate
,tkrtype
,userstatusid
,userstatus
,leaverdate
,rate_class
,effstart
,employeeid
,CASE WHEN ds_reckey IS NOT NULL THEN 'Yes' ELSE 'No' END  AS [User Created in FED?]
,CASE WHEN cdDesc='Legal Ops - LTA' THEN 'No' ELSE 'Yes' END AS [Needs FED Account?]
FROM red_dw.dbo.stage_ds_sh_3e_user_sync_01 AS a
LEFT OUTER JOIN axxia01.dbo.cadescrp ON RTRIM(payrollid)=RTRIM(ds_reckey) AND ds_rectyp='PE'
LEFT OUTER JOIN [TE_3E_Prod].[dbo].[Section] ON team=Code collate database_default
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM MS_Prod.dbo.dbCodeLookup WHERE cdType='DEPT') AS Department
 ON businessline=Department.cdCode collate database_default
WHERE mandatory_error_flag=1 AND startdate >='2018-08-01'
ORDER BY effstart
END
GO
