SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		orlagh kelly
-- Create date: 06-09-2018
-- Description:	report to drive RIO partners report in the KIP folder  ----- Ticket No 329457
-- =============================================
CREATE PROCEDURE [dbo].[riopartnersreport]
AS


BEGIN

	Declare @StartDate as Datetime 
	DECLARE @Partner as NVARCHAR (2000) 

set @StartDate = '2018-05-01'
set @Partner = 'Bob Pritchard'
    -- Insert statements for procedure here
select        c.entity as 'entity number', c.number as 'client number', c.clientindex, c.displayname as 'client name', c.clistatustype as 'client status', 
                         c.opendate as 'client open date', tko.displayname as 'client introducer', tko.tkprindex as timekeeper, matter.mattindex, timecard.postdate, timebill.billamt, 
                         timebill.billhrs, timebill.workamt, timebill.workhrs, 'Intro of Client Billing' as ref_type, 2 as reftypeno
from        red_dw.dbo.ds_sh_3e_client as c with (nolock) inner join
        red_dw.dbo.ds_sh_3e_clidate as cd with (nolock) on cd.clientlkup = c.clientindex and cd.nxenddate = '99991231' left outer join
                          red_dw.dbo.ds_sh_3e_cliorgtkpr as co with (nolock) on co.clieffdate = cd.clidateid left outer join
                          red_dw.dbo.ds_sh_3e_timekeeper as tko with (nolock) on tko.tkprindex = co.timekeeper inner join
                          red_dw.dbo.ds_sh_3e_matter as matter on matter.client = c.clientindex inner join
                          red_dw.dbo.ds_sh_3e_timecard as timecard on timecard.matter = matter.mattindex inner join
                          red_dw.dbo.ds_sh_3e_timebill  as timebill on timebill.timecard = timecard.timeindex
where        (co.timekeeper is not null)
and timecard.postdate >=@StartDate
and  tko.tkprindex = @Partner 
union
select        null as [entity number], client.number as client, client.clientindex, client.displayname as [client name], client.clistatustype as [client status], 
                         client.opendate as [client open date], timekeeper.displayname as [client introducer], timekeeper.tkprindex as timekeeper, matter_2.mattindex, 
                         timecard_2.postdate, timebill_2.billamt, timebill_2.billhrs, timebill_2.workamt, timebill_2.workhrs, 'Personal Billing' as ref_type, 1 as reftypeno
from            red_dw.dbo.ds_sh_3e_timecard as timecard_2 inner join
                          red_dw.dbo.ds_sh_3e_timebill as timebill_2 on timebill_2.timecard = timecard_2.timeindex inner join
                          red_dw.dbo.ds_sh_3e_matter as matter_2 on matter_2.mattindex = timecard_2.billmatter inner join
                          red_dw.dbo.ds_sh_3e_client  as client on client.clientindex = matter_2.client inner join
                             (select distinct co.timekeeper
                               from             red_dw.dbo.ds_sh_3e_client as c with (nolock) inner join
                                                          red_dw.dbo.ds_sh_3e_clidate as cd with (nolock) on cd.clientlkup = c.clientindex and cd.nxenddate = '99991231' left outer join
                                                          red_dw.dbo.ds_sh_3e_cliorgtkpr as co with (nolock) on co.clieffdate = cd.clidateid
                               where        (co.timekeeper is not null)) as refer on timecard_2.timekeeper = refer.timekeeper inner join
                          red_dw.dbo.ds_sh_3e_timekeeper as timekeeper on timekeeper.tkprindex = refer.timekeeper
					where postdate >=@StartDate
					and timekeeper.tkprindex  =@Partner
union
select        null as [entity number], client_1.number as client, client_1.clientindex, client_1.displayname as [client name], client_1.clistatustype as [client status], 
                         client_1.opendate as [client open date], timekeeper_1.displayname as [client introducer], timekeeper_1.tkprindex as timekeeper, matter_1.mattindex, 
                         timecard_1.postdate, timebill_1.billamt, timebill_1.billhrs, timebill_1.workamt, timebill_1.workhrs, 'referral of matters' as ref_type, 3 as reftypeno
from             red_dw.dbo.ds_sh_3e_timecard as timecard_1 inner join
                          red_dw.dbo.ds_sh_3e_timebill as timebill_1 on timebill_1.timecard = timecard_1.timeindex inner join
                          red_dw.dbo.ds_sh_3e_matter as matter_1 on matter_1.mattindex = timecard_1.billmatter inner join
                          red_dw.dbo.ds_sh_3e_client as client_1 on client_1.clientindex = matter_1.client inner join
                          red_dw.dbo.ds_sh_3e_mattdate as mattdate on mattdate.matterlkup = matter_1.mattindex inner join
                          red_dw.dbo.ds_sh_3e_mattprlftkpr as mattprlftkpr on mattprlftkpr.mattdate = mattdate.mattdateid left outer join
                          red_dw.dbo.ds_sh_3e_timekeeper as timekeeper_1 on timekeeper_1.tkprindex = mattprlftkpr.timekeeper
						  	where postdate >=@StartDate 
							and  timekeeper_1.tkprindex = @Partner









END
GO
