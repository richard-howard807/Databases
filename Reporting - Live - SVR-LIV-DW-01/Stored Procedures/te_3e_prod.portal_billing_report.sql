SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		lucy dickinson
-- Create date: 01/08/2018
-- Description:	Portal Billing Report for Jenny Byfield Ticket 300733
--				Jenny currently has to produce this report manually and would like this automated so that it
--				can be done in her abscence.
--				
-- =============================================
CREATE PROCEDURE [te_3e_prod].[portal_billing_report]
AS	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Set the below to prevent locks, as this has happend when querying before
	-- happy for a dirty read
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	
SELECT DISTINCT

DATEDIFF(DAY, isnull(NxWfItemStep.StepDate, prof.TimeStamp), getdate()) [aged_days],
profstatus.[description] [status],
profdate [status_date],
profindex [proforma],
NxUser.BaseUserName [current_owner],
client.displayname [client],
matter.number [matter],
matter.[description] [matter_description],
--team_name.[description] [team],
prof.feeamt [fees],
prof.hcoamt + prof.scoamt [disbursements]
,taxamt
,totamt [Total]
,othamt
,intamt
,boaamt
,prof.BillTkpr
, team_name.Description
-- select *
FROM  TE_3E_Prod..[ProfMaster] (nolock)   prof --ON WfHistory.joinid = prof.profmasterid
LEFT JOIN TE_3E_Prod..[ProfStatus] (nolock)  profstatus ON profstatus.code = prof.profstatus 
LEFT JOIN TE_3E_Prod..[Matter] (nolock)  matter ON matter.mattindex = prof.leadmatter
LEFT JOIN TE_3E_Prod..[Client] (nolock)  client ON matter.client = client.clientindex
INNER JOIN TE_3E_Prod..NxWfItemStep (nolock) as NxWfItemStep ON NxWfItemStep.JoinID = prof.ProfMasterID and NxWfItemStep.NxWFStepState = 1 
LEFT OUTER JOIN TE_3E_Prod..NxBaseUser (nolock) AS NxUser ON NxWfItemStep.NextStepOwner = NxUser.NxBaseUserID
LEFT OUTER JOIN TE_3E_Prod..Timekeeper (nolock)  tkpr ON tkpr.TRE_User = isnull(NxUser.NxBaseUserID, WM_Approver)

LEFT JOIN TE_3E_Prod..[Timekeeper] (nolock) timekeeper ON timekeeper.tkprindex = prof.BillTkpr

left outer join red_dw.dbo.ds_sh_3e_user_sync team on prof.BillTkpr = team.timekeeperindex
LEFT JOIN [TE_3E_Prod].[dbo].[Section] team_name ON team_name.code = team.team COLLATE DATABASE_DEFAULT

WHERE
--WfHistory.CompletedDate IS NULL
--AND WfHistory.IsHide = 0
--AND
----prof.InvMaster IS NULL
-- prof.ProfIndex=2440229 
-- and
-- prof.WFRouteTo_ccc is not null

 prof.ProfStatus not in ('Billed','RejectApproval','CL','CL_WM')

	


END


GO
