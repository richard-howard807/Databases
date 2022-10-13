SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[IncompleteMIProcess] --'Regulatory'	,'PDGHSC'
(
@FEDCode AS VARCHAR(MAX)
,@Level as VARCHAR(100)


)
AS 
BEGIN

SELECT ListValue  INTO #FedCodeList FROM dbo.udt_TallySplit(',', @FEDCode)

SELECT client_code AS [Client]
,matter_number AS [Matter]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_practice_management AS [Date Closed]
,hierarchylevel2hist
,hierarchylevel3hist 
,hierarchylevel4hist 
,matter_owner_full_name 
,tskDue AS [MI Process Date]
,tskDesc AS [MI Process Task]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN MS_Prod.dbo.dbTasks
 ON ms_fileid=fileID
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code collate database_default AND dss_current_flag='Y'

WHERE tskComplete=0
AND ms_only=1
AND date_closed_practice_management IS NULL
AND tskType='MILESTONE'
AND tskDesc LIKE '%MI Process%'
AND hierarchylevel2hist IN ('Legal Ops - Claims','Legal Ops - LTA')
and dim_fed_hierarchy_history.dim_fed_hierarchy_history_key in 
(
select (case when @Level = 'Firm' then dim_fed_hierarchy_history_key else 0 end) 
from red_dw.dbo.dim_fed_hierarchy_history
union
select (case when @Level IN ('Individual') then ListValue else 0 end) from #FedCodeList
union
select (case when @Level IN ('Area Managed') then ListValue else 0 end) from #FedCodeList
)
END 
GO
