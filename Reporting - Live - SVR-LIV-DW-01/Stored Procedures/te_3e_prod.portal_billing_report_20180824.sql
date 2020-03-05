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
CREATE PROCEDURE [te_3e_prod].[portal_billing_report_20180824]
AS	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Set the below to prevent locks, as this has happend when querying before
	-- happy for a dirty read
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

   SELECT distinct
  
		DATEDIFF(DAY,stepdate,GETDATE()) [aged_days],
        profstatus.[description] [status],
        profdate [status_date],
        profindex [proforma],
		timekeeper.displayname [current_owner],
		client.displayname [client],
		matter.number [matter],
		matter.[description] [matter_description],
		team_name.[description] [team],
		prof.feeamt [fees],
		prof.hcoamt + prof.scoamt [disbursements]
		,taxamt    
		,totamt [Total]
		,othamt
		,intamt
		,boaamt
 
	FROM [TE_3E_Prod].[dbo].[TRE_WfHistoryDetail] wfh
	JOIN [TE_3E_Prod].[dbo].[ProfMaster] prof ON wfh.joinid = prof.profmasterid
	LEFT JOIN [TE_3E_Prod].[dbo].[ProfStatus] profstatus ON profstatus.code = prof.profstatus
	LEFT JOIN [TE_3E_Prod].[dbo].[Matter] matter ON matter.mattindex = leadmatter
	LEFT JOIN [TE_3E_Prod].[dbo].[Timekeeper] timekeeper ON timekeeper.tkprindex = matter.opentkpr
	LEFT JOIN [TE_3E_Prod].[dbo].[Client] client ON matter.client = client.clientindex
	LEFT JOIN red_dw.dbo.ds_sh_3e_user_sync team ON timekeeper.tkprindex = team.timekeeperindex
	LEFT JOIN [TE_3E_Prod].[dbo].[Section] team_name ON team_name.code = team.team COLLATE DATABASE_DEFAULT


	WHERE invmaster IS NULL



END

GO
