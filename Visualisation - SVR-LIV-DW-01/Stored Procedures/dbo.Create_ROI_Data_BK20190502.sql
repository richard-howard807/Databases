SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[Create_ROI_Data_BK20190502] @processdate DATETIME
AS

TRUNCATE TABLE ROI 

INSERT INTO ROI

SELECT ROI.*,getdate(),altnumber FROM 

(SELECT        c.entity AS 'entity number', c.number AS 'client number', c.clientindex, c.displayname AS 'client name', c.clistatustype AS 'client status', c.opendate AS 'client open date', tko.displayname AS 'Client Introducer', 
                         tko.tkprindex AS timekeeper, matter.mattindex, timecard.postdate, timebill.billamt, timebill.billhrs, timebill.workamt, timebill.workhrs, 'Intro of Client Billing' AS ref_type, 2 AS reftypeno
FROM            red_dw.dbo.ds_sh_3e_client AS c WITH (nolock) INNER JOIN
                         red_dw.dbo.ds_sh_3e_clidate AS cd WITH (nolock) ON cd.clientlkup = c.clientindex AND cd.nxenddate = '99991231' LEFT OUTER JOIN
                         red_dw.dbo.ds_sh_3e_cliorgtkpr AS co WITH (nolock) ON co.clieffdate = cd.clidateid LEFT OUTER JOIN
                         red_dw.dbo.ds_sh_3e_timekeeper AS tko WITH (nolock) ON tko.tkprindex = co.timekeeper INNER JOIN
                         red_dw.dbo.ds_sh_3e_matter AS matter ON matter.client = c.clientindex INNER JOIN
                         red_dw.dbo.ds_sh_3e_timecard AS timecard ON timecard.matter = matter.mattindex INNER JOIN
                         red_dw.dbo.ds_sh_3e_timebill AS timebill ON timebill.timecard = timecard.timeindex
WHERE        (co.timekeeper IS NOT NULL) 
--AND timecard.postdate between @StartDate AND @EndDate
AND timecard.postdate >= @processdate


AND timecard.timekeeper NOT IN 
                             (SELECT DISTINCT co.timekeeper
                               FROM            red_dw.dbo.ds_sh_3e_client AS c WITH (nolock) INNER JOIN
                                                         red_dw.dbo.ds_sh_3e_clidate AS cd WITH (nolock) ON cd.clientlkup = c.clientindex AND cd.nxenddate = '99991231' LEFT OUTER JOIN
                                                         red_dw.dbo.ds_sh_3e_cliorgtkpr AS co WITH (nolock) ON co.clieffdate = cd.clidateid
                               WHERE        (co.timekeeper IS NOT NULL)
                                        UNION
                                        SELECT tkprindex FROM red_dw.dbo.ds_sh_3e_timekeeper
WHERE payrollnumber 
IN ('4865'
,'5701'
,'5703'
,'5708'
,'5776'
,'5788'
,'5828'
,'5829'
,'5842'
,'5867'
,'5896'
,'5902'
,'5903'
,'5904'
,'5912'
,'5937'
,'5936'
,'5998'
,'6063')
                                      ) 




/*and                                    'Intro of Client Billing'  = @reftype*/ UNION all
SELECT        NULL AS [entity number], client.number AS client, client.clientindex, client.displayname AS [client name], client.clistatustype AS [client status], client.opendate AS [client open date], timekeeper.displayname AS [client introducer], 
                         timekeeper.tkprindex AS timekeeper, matter_2.mattindex, invmaster1.invdate, timebill_2.billamt, timebill_2.billhrs, timebill_2.workamt, timebill_2.workhrs, 'Personal Billing' AS ref_type, 1 AS reftypeno
FROM            red_dw.dbo.ds_sh_3e_timecard AS timecard_2 INNER JOIN
                         red_dw.dbo.ds_sh_3e_timebill AS timebill_2 ON timebill_2.timecard = timecard_2.timeindex INNER JOIN
                                red_dw.dbo.ds_sh_3e_invmaster AS invmaster1 ON timebill_2.invmaster = invmaster1.invindex INNER JOIN 
                         red_dw.dbo.ds_sh_3e_matter AS matter_2 ON matter_2.mattindex = timecard_2.billmatter INNER JOIN
                                red_dw.dbo.ds_sh_3e_client AS client ON client.clientindex = matter_2.client INNER JOIN
                             (SELECT DISTINCT co.timekeeper
                               FROM            red_dw.dbo.ds_sh_3e_client AS c WITH (nolock) INNER JOIN
                                                         red_dw.dbo.ds_sh_3e_clidate AS cd WITH (nolock) ON cd.clientlkup = c.clientindex AND cd.nxenddate = '99991231' LEFT OUTER JOIN
                                                         red_dw.dbo.ds_sh_3e_cliorgtkpr AS co WITH (nolock) ON co.clieffdate = cd.clidateid
                               WHERE        (co.timekeeper IS NOT NULL)
                                        UNION
                                        SELECT tkprindex FROM red_dw.dbo.ds_sh_3e_timekeeper
WHERE payrollnumber 
IN ('4865'
,'5701'
,'5703'
,'5708'
,'5776'
,'5788'
,'5828'
,'5829'
,'5842'
,'5867'
,'5896'
,'5902'
,'5903'
,'5904'
,'5912'
,'5937'
,'5936'
,'5998'
,'6063')
                                      ) AS refer ON timecard_2.timekeeper = refer.timekeeper INNER JOIN
                         red_dw.dbo.ds_sh_3e_timekeeper AS timekeeper ON timekeeper.tkprindex = refer.timekeeper
--WHERE        invdate between @StartDate AND @EndDate
WHERE        invdate >= @processdate



/*and 'Personal Billing' = @reftype*/ UNION all
SELECT        NULL AS [entity number], client_1.number AS client, client_1.clientindex, client_1.displayname AS [client name], client_1.clistatustype AS [client status], client_1.opendate AS [client open date], 
                         timekeeper_1.displayname AS [client introducer], timekeeper_1.tkprindex AS timekeeper, matter_1.mattindex, timecard_1.postdate, timebill_1.billamt, timebill_1.billhrs, timebill_1.workamt, timebill_1.workhrs, 
                         'Referral of Matters' AS ref_type, 3 AS reftypeno
FROM            red_dw.dbo.ds_sh_3e_timecard AS timecard_1 INNER JOIN
                         red_dw.dbo.ds_sh_3e_timebill AS timebill_1 ON timebill_1.timecard = timecard_1.timeindex INNER JOIN
                         red_dw.dbo.ds_sh_3e_matter AS matter_1 ON matter_1.mattindex = timecard_1.billmatter INNER JOIN
                         red_dw.dbo.ds_sh_3e_client AS client_1 ON client_1.clientindex = matter_1.client INNER JOIN
                         red_dw.dbo.ds_sh_3e_mattdate AS mattdate ON mattdate.matterlkup = matter_1.mattindex INNER JOIN
                         red_dw.dbo.ds_sh_3e_mattprlftkpr AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid LEFT OUTER JOIN
                         red_dw.dbo.ds_sh_3e_timekeeper AS timekeeper_1 ON timekeeper_1.tkprindex = mattprlftkpr.timekeeper
--WHERE        postdate between @StartDate AND @EndDate
WHERE        postdate >= @processdate) ROI INNER JOIN red_dw.dbo.ds_sh_3e_matter ON ds_sh_3e_matter.mattindex = ROI.mattindex



GO
