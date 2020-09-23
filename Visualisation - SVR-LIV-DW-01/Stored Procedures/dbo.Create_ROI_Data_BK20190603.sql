SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Create_ROI_Data_BK20190603]
    @processdate DATETIME
AS

	/* For testing purposes*/
	--DECLARE @processdate DATE = '20190501'

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SET @processdate = '20190501' -- not sure where this date gets passed through from so I am hardcoding to 20190501 as this is the start of the project
	DECLARE @timekeepers TABLE (timekeeper INT)

	/* Inserts timekeepers that have a record in client referral */

	INSERT INTO @timekeepers ( timekeeper )
	/* inserts records for client introducers set up by Finance in the front end*/
	SELECT DISTINCT co.timekeeper
	--uncomment the below to see the names
	--,t.displayname
	FROM   red_dw.dbo.ds_sh_3e_client			AS c 
	INNER JOIN red_dw.dbo.ds_sh_3e_clidate		AS cd ON cd.clientlkup = c.clientindex AND cd.nxenddate = '99991231'
	INNER JOIN red_dw.dbo.ds_sh_3e_cliorgtkpr	AS co ON co.clieffdate = cd.clidateid
	INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS t  ON t.tkprindex = co.timekeeper

	WHERE  ( co.timekeeper IS NOT NULL )
	/* inserts timekeepers that are fixed share partners */
	UNION
	SELECT tkprindex
		FROM   red_dw.dbo.ds_sh_3e_timekeeper a
		INNER JOIN [TE_3E_Prod].[dbo].[TkprDate] b ON a.tkprindex = b.TimekeeperLkUp AND b.NxEndDate = '99991231'
		INNER JOIN red_dw.dbo.ds_sh_3e_title c ON b.Title = c.code COLLATE DATABASE_DEFAULT

	WHERE  c.description IN (
	'Fixed Share Partner' )


	DECLARE @matter_refs TABLE (timekeeper INT)
	INSERT INTO @matter_refs
	
	SELECT DISTINCT mattprlftkpr.timekeeper
	FROM   red_dw.dbo.ds_sh_3e_matter			AS matter_1		
    INNER JOIN red_dw.dbo.ds_sh_3e_mattdate		AS mattdate ON mattdate.matterlkup = matter_1.mattindex AND mattdate.nxenddate = '99991231'
    INNER JOIN red_dw.dbo.ds_sh_3e_mattprlftkpr	AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid


--SELECT * FROM @timekeepers

    TRUNCATE TABLE ROI;

    INSERT INTO ROI
SELECT ROI.* ,
    GETDATE() ,
    altnumber
FROM   (   

/* Billings on the Introducers Clients that are not their own personal billings*/

SELECT c.entity AS 'entity number' ,
    c.number AS 'client number' ,
    c.clientindex ,
    c.displayname AS 'client name' ,
    c.clistatustype AS 'client status' ,
    c.opendate AS 'client open date' ,
    tko.displayname AS 'Client Introducer' ,
    tko.tkprindex AS timekeeper ,
--	timecard.timekeeper AS 'fee', -- for testing purposes to see which fee earners time records
    matter.mattindex ,
    timecard.postdate ,
    timebill.billamt ,
    timebill.billhrs ,
    timebill.workamt ,
    timebill.workhrs ,
    'Intro of Client Billing' AS ref_type ,
    2 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_client				AS c WITH ( NOLOCK )
    INNER JOIN red_dw.dbo.ds_sh_3e_clidate		AS cd WITH ( NOLOCK ) ON cd.clientlkup = c.clientindex  AND cd.nxenddate = '99991231'
    INNER JOIN red_dw.dbo.ds_sh_3e_cliorgtkpr	AS co WITH ( NOLOCK ) ON co.clieffdate = cd.clidateid
    INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS tko WITH ( NOLOCK ) ON tko.tkprindex = co.timekeeper
    INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter ON matter.client = c.clientindex
    INNER JOIN red_dw.dbo.ds_sh_3e_timecard		AS timecard ON timecard.matter = matter.mattindex
    INNER JOIN red_dw.dbo.ds_sh_3e_timebill		AS timebill ON timebill.timecard = timecard.timeindex
	INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster ON timebill.invmaster = invmaster.invindex
WHERE  ( co.timekeeper IS NOT NULL )
    AND invmaster.invdate >= @processdate
    AND timecard.timekeeper NOT IN (SELECT timekeeper FROM @timekeepers  ) -- Exclues any timecard transactions by client introducer


/* Revenue or Personal Billings */
                        
   UNION ALL


SELECT NULL AS [entity number] ,
        client.number AS client ,
        client.clientindex ,
        client.displayname AS [client name] ,
        client.clistatustype AS [client status] ,
        client.opendate AS [client open date] ,
        timekeeper.displayname AS [client introducer] ,
        timekeeper.tkprindex AS timekeeper ,
--		timecard_2.timekeeper AS 'fee',
        matter_2.mattindex ,
        invmaster1.invdate ,
        timebill_2.billamt ,
        timebill_2.billhrs ,
        timebill_2.workamt ,
        timebill_2.workhrs ,
        'Personal Billing' AS ref_type ,
        1 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_timecard					AS timecard_2
        INNER JOIN red_dw.dbo.ds_sh_3e_timebill		AS timebill_2 ON timebill_2.timecard = timecard_2.timeindex
        INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster1 ON timebill_2.invmaster = invmaster1.invindex
        INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter_2 ON matter_2.mattindex = timecard_2.billmatter
        INNER JOIN red_dw.dbo.ds_sh_3e_client		AS client ON client.clientindex = matter_2.client
        INNER JOIN @timekeepers						AS refer ON timecard_2.timekeeper = refer.timekeeper
        INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper ON timekeeper.tkprindex = refer.timekeeper
WHERE  invmaster1.invdate >= @processdate


/* Matters referred */
         
UNION ALL

SELECT NULL AS [entity number] ,
    client_1.number AS client ,
    client_1.clientindex ,
    client_1.displayname AS [client name] ,
    client_1.clistatustype AS [client status] ,
    client_1.opendate AS [client open date] ,
    timekeeper_1.displayname AS [client introducer] ,
    timekeeper_1.tkprindex AS timekeeper ,
--	timecard_1.timekeeper AS 'fee',
    matter_1.mattindex ,
    timecard_1.postdate ,
    timebill_1.billamt ,
    timebill_1.billhrs ,
    timebill_1.workamt ,
    timebill_1.workhrs ,
    'Referral of Matters' AS ref_type ,
    3 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_timecard					AS timecard_1
    INNER JOIN red_dw.dbo.ds_sh_3e_timebill			AS timebill_1 ON timebill_1.timecard = timecard_1.timeindex
    INNER JOIN red_dw.dbo.ds_sh_3e_matter			AS matter_1 ON matter_1.mattindex = timecard_1.billmatter
    INNER JOIN red_dw.dbo.ds_sh_3e_client			AS client_1 ON client_1.clientindex = matter_1.client
    INNER JOIN red_dw.dbo.ds_sh_3e_mattdate			AS mattdate ON mattdate.matterlkup = matter_1.mattindex
    INNER JOIN red_dw.dbo.ds_sh_3e_mattprlftkpr		AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid
    LEFT OUTER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper_1 ON timekeeper_1.tkprindex = mattprlftkpr.timekeeper
	INNER JOIN red_dw.dbo.ds_sh_3e_invmaster		AS invmaster ON timebill_1.invmaster = invmaster.invindex

WHERE  invdate >= @processdate 
AND timecard_1.timekeeper NOT IN (SELECT timekeeper FROM @matter_refs ) -- excludes matter refs

/* Kieran Donovan is a special case and started earlier I am adding his figures from 2018 separately*/

UNION ALL

SELECT c.entity AS 'entity number' ,
    c.number AS 'client number' ,
    c.clientindex ,
    c.displayname AS 'client name' ,
    c.clistatustype AS 'client status' ,
    c.opendate AS 'client open date' ,
    tko.displayname AS 'Client Introducer' ,
    tko.tkprindex AS timekeeper ,
--	timecard.timekeeper AS 'fee', -- for testing purposes to see which fee earners time records
    matter.mattindex ,
    timecard.postdate ,
    timebill.billamt ,
    timebill.billhrs ,
    timebill.workamt ,
    timebill.workhrs ,
    'Intro of Client Billing' AS ref_type ,
    2 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_client				AS c WITH ( NOLOCK )
    INNER JOIN red_dw.dbo.ds_sh_3e_clidate		AS cd WITH ( NOLOCK ) ON cd.clientlkup = c.clientindex  AND cd.nxenddate = '99991231'
    INNER JOIN red_dw.dbo.ds_sh_3e_cliorgtkpr	AS co WITH ( NOLOCK ) ON co.clieffdate = cd.clidateid
    INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS tko WITH ( NOLOCK ) ON tko.tkprindex = co.timekeeper
    INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter ON matter.client = c.clientindex
    INNER JOIN red_dw.dbo.ds_sh_3e_timecard		AS timecard ON timecard.matter = matter.mattindex
    INNER JOIN red_dw.dbo.ds_sh_3e_timebill		AS timebill ON timebill.timecard = timecard.timeindex
	INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster ON timebill.invmaster = invmaster.invindex
WHERE  co.timekeeper = 6496
    AND invmaster.invdate BETWEEN '20180501' AND '20190430'
    AND timecard.timekeeper <> 6496 -- Exclues any timecard transactions by client introducer
                        
   UNION ALL


SELECT NULL AS [entity number] ,
        client.number AS client ,
        client.clientindex ,
        client.displayname AS [client name] ,
        client.clistatustype AS [client status] ,
        client.opendate AS [client open date] ,
        timekeeper.displayname AS [client introducer] ,
        timekeeper.tkprindex AS timekeeper ,
--		timecard_2.timekeeper AS 'fee',
        matter_2.mattindex ,
        invmaster1.invdate ,
        timebill_2.billamt ,
        timebill_2.billhrs ,
        timebill_2.workamt ,
        timebill_2.workhrs ,
        'Personal Billing' AS ref_type ,
        1 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_timecard					AS timecard_2
        INNER JOIN red_dw.dbo.ds_sh_3e_timebill		AS timebill_2 ON timebill_2.timecard = timecard_2.timeindex
        INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster1 ON timebill_2.invmaster = invmaster1.invindex
        INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter_2 ON matter_2.mattindex = timecard_2.billmatter
        INNER JOIN red_dw.dbo.ds_sh_3e_client		AS client ON client.clientindex = matter_2.client
        INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper ON timekeeper.tkprindex = timecard_2.timekeeper
WHERE  invmaster1.invdate BETWEEN '20180501' AND '20190430'
AND  timecard_2.timekeeper = 6496

/* Matters referred */
         
UNION ALL

SELECT NULL AS [entity number] ,
    client_1.number AS client ,
    client_1.clientindex ,
    client_1.displayname AS [client name] ,
    client_1.clistatustype AS [client status] ,
    client_1.opendate AS [client open date] ,
    timekeeper_1.displayname AS [client introducer] ,
    timekeeper_1.tkprindex AS timekeeper ,
--	timecard_1.timekeeper AS 'fee',
    matter_1.mattindex ,
    timecard_1.postdate ,
    timebill_1.billamt ,
    timebill_1.billhrs ,
    timebill_1.workamt ,
    timebill_1.workhrs ,
    'Referral of Matters' AS ref_type ,
    3 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_timecard					AS timecard_1
    INNER JOIN red_dw.dbo.ds_sh_3e_timebill			AS timebill_1 ON timebill_1.timecard = timecard_1.timeindex
    INNER JOIN red_dw.dbo.ds_sh_3e_matter			AS matter_1 ON matter_1.mattindex = timecard_1.billmatter
    INNER JOIN red_dw.dbo.ds_sh_3e_client			AS client_1 ON client_1.clientindex = matter_1.client
    INNER JOIN red_dw.dbo.ds_sh_3e_mattdate			AS mattdate ON mattdate.matterlkup = matter_1.mattindex
    INNER JOIN red_dw.dbo.ds_sh_3e_mattprlftkpr		AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid AND mattprlftkpr.timekeeper = 6496
    LEFT OUTER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper_1 ON timekeeper_1.tkprindex = mattprlftkpr.timekeeper
	INNER JOIN red_dw.dbo.ds_sh_3e_invmaster		AS invmaster ON timebill_1.invmaster = invmaster.invindex

WHERE  invdate BETWEEN '20180501' AND '20190430'
AND timecard_1.timekeeper <> 6496-- excludes matter refs







) ROI
INNER JOIN red_dw.dbo.ds_sh_3e_matter ON ds_sh_3e_matter.mattindex = ROI.mattindex;



GO
