SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
		Author: Paul Dutton 
		Description:  Creates the data for the report
		Home > Business Services > Finance > Partners Billing Introductions and Referrals

LD 20190603 Changed the post and invmaster.invdates to armaster.invdate so that figures match the Revenue Report figures 
ES 20200210 Added Robert Turnbull, John Schorah requested he was included on the report even though he is not a Partner, 46543 

RH 20200728 - Added percent split

RH 20200803 - Amended exclusion logic so it excludes personal billings not all billings by any refferer

RH 20200805 - Amened to include charges which are reported as revenue 'Fees'
			- Report documentation \\sbc.root\usershares\Restricted\Business Services\Information Systems\Teams\Development\Business Intelligence\Documentation\Partners Billing Introductions and Referrals Documentation.docx

exec [dbo].[Create_ROI_Data] '20190101'
*/



CREATE PROCEDURE [dbo].[Create_ROI_Data]
    @processdate DATETIME
AS

	/* For testing purposes*/
	--DECLARE @processdate DATE = '20190501'

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SET @processdate = '20190501' -- No billings before this date as this is the start of the scheme 
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
	--20200210, 46543
	OR a.displayname='Robert Turnbull'


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

SELECT x.[entity number],
       x.[client number],
       x.clientindex,
       x.[client name],
       x.[client status],
       x.[client open date],
       x.[Client Introducer],
       x.timekeeper,
       x.mattindex,
       x.postdate,
       x.billamt -  x.personalbillings  billamt,
       x.billhrs,
       x.workamt,
       x.workhrs,
       x.ref_type,
       x.reftypeno
FROM (
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
	   -- timecard.postdate ,
		armaster.invdate postdate,
		IIF(timecard.timekeeper <> co.timekeeper, 0, billamt) personalbillings,
		billamt  * (co.percentage / 100) billamt, 
		timebill.billhrs ,
		timebill.workamt ,
		timebill.workhrs ,
		'Intro of Client Billing' AS ref_type 
		-- , co.percentage / 100,
		,2 AS reftypeno
		-- select mattindex, co.*
	FROM   red_dw.dbo.ds_sh_3e_client				AS c WITH ( NOLOCK )
		INNER JOIN red_dw.dbo.ds_sh_3e_clidate		AS cd WITH ( NOLOCK ) ON cd.clientlkup = c.clientindex  AND cd.nxenddate = '99991231'
		INNER JOIN red_dw.dbo.ds_sh_3e_cliorgtkpr	AS co WITH ( NOLOCK ) ON co.clieffdate = cd.clidateid
		INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS tko WITH ( NOLOCK ) ON tko.tkprindex = co.timekeeper
		INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter ON matter.client = c.clientindex
		INNER JOIN red_dw.dbo.ds_sh_3e_timecard		AS timecard ON timecard.matter = matter.mattindex
		INNER JOIN red_dw.dbo.ds_sh_3e_timebill		AS timebill ON timebill.timecard = timecard.timeindex
		INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster ON timebill.invmaster = invmaster.invindex
		 INNER JOIN red_dw.dbo.ds_sh_3e_armaster     AS armaster ON timebill.armaster = armaster.armindex
	WHERE  ( co.timekeeper IS NOT NULL )
		-- AND matter.mattindex = 2999097
		AND armaster.invdate >= @processdate
		AND c.opendate >= '20190501'
		AND DATEDIFF(D, c.opendate, armaster.invdate) < 1095
	   --  AND timecard.timekeeper NOT IN (SELECT timekeeper FROM @timekeepers  ) -- Exclues any timecard transactions by client introducer
	 --  AND timecard.timekeeper <> co.timekeeper


	 UNION ALL
  -- Charges   

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
	   -- timecard.postdate ,
		armaster.invdate postdate,
		IIF(timecard.timekeeper <> co.timekeeper, 0, billamt) personalbillings,
		billamt  * (co.percentage / 100) billamt, 
		0 ,
		0 ,
		0 ,
		'Intro of Client Billing' AS ref_type 
		-- , co.percentage / 100,
		,2 AS reftypeno
		-- select mattindex, co.*
	FROM   red_dw.dbo.ds_sh_3e_client				AS c WITH ( NOLOCK )
		INNER JOIN red_dw.dbo.ds_sh_3e_clidate		AS cd WITH ( NOLOCK ) ON cd.clientlkup = c.clientindex  AND cd.nxenddate = '99991231'
		INNER JOIN red_dw.dbo.ds_sh_3e_cliorgtkpr	AS co WITH ( NOLOCK ) ON co.clieffdate = cd.clidateid
		INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS tko WITH ( NOLOCK ) ON tko.tkprindex = co.timekeeper
		INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter ON matter.client = c.clientindex
		INNER JOIN red_dw.dbo.ds_sh_3e_chrgcard		AS timecard ON timecard.matter = matter.mattindex AND trantype = 'FEES'
		INNER JOIN red_dw.dbo.ds_sh_3e_chrgbill		AS timebill ON timebill.chrgcard = timecard.chrgcardindex
		INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster ON timebill.invmaster = invmaster.invindex
		 INNER JOIN red_dw.dbo.ds_sh_3e_armaster     AS armaster ON timebill.armaster = armaster.armindex
	WHERE  ( co.timekeeper IS NOT NULL )
		-- AND matter.mattindex = 2999097
		AND c.opendate >= '20190501'
		AND DATEDIFF(D, c.opendate, armaster.invdate) < 1095
		AND armaster.invdate >= @processdate

) x

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
        armaster.invdate ,
        timebill_2.billamt ,
        timebill_2.billhrs ,
        timebill_2.workamt ,
        timebill_2.workhrs ,
        'Personal Billing' AS ref_type ,
        1 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_timecard					AS timecard_2
        INNER JOIN red_dw.dbo.ds_sh_3e_timebill		AS timebill_2 ON timebill_2.timecard = timecard_2.timeindex
        INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster1 ON timebill_2.invmaster = invmaster1.invindex
        INNER JOIN red_dw.dbo.ds_sh_3e_armaster     AS armaster ON timebill_2.armaster = armaster.armindex
		INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter_2 ON matter_2.mattindex = timecard_2.billmatter
        INNER JOIN red_dw.dbo.ds_sh_3e_client		AS client ON client.clientindex = matter_2.client
        INNER JOIN @timekeepers						AS refer ON timecard_2.timekeeper = refer.timekeeper
        INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper ON timekeeper.tkprindex = refer.timekeeper
WHERE  armaster.invdate >= @processdate

UNION ALL

-- Personal billing charge fees

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
        armaster.invdate ,
        timebill_2.billamt ,
        0 ,
        0 ,
        0 ,
        'Personal Billing' AS ref_type ,
        1 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_chrgcard					AS timecard_2
        INNER JOIN red_dw.dbo.ds_sh_3e_chrgbill		AS timebill_2 ON timebill_2.chrgcard = timecard_2.chrgcardindex  AND trantype = 'FEES'
        INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster1 ON timebill_2.invmaster = invmaster1.invindex
        INNER JOIN red_dw.dbo.ds_sh_3e_armaster     AS armaster ON timebill_2.armaster = armaster.armindex
		INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter_2 ON matter_2.mattindex = timecard_2.billmatter
        INNER JOIN red_dw.dbo.ds_sh_3e_client		AS client ON client.clientindex = matter_2.client
        INNER JOIN @timekeepers						AS refer ON timecard_2.timekeeper = refer.timekeeper
        INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper ON timekeeper.tkprindex = refer.timekeeper
WHERE  armaster.invdate >= @processdate




/* Matters referred */
         
UNION ALL

SELECT x.[entity number],
       x.client,
       x.clientindex,
       x.[client name],
       x.[client status],
       x.[client open date],
       x.[client introducer],
       x.timekeeper,
       x.mattindex,
       x.invdate,       
       x.billamt - x.personalbillings billamt,
       x.billhrs,
       x.workamt,
       x.workhrs,
       x.ref_type,
       x.reftypeno
FROM (

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
	   -- timecard_1.postdate ,
		armaster.invdate,
		IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt) personalbillings,
		billamt  * (mattprlftkpr.percentage / 100) billamt, 
		--timebill_1.billamt * (mattprlftkpr.percentage / 100) billamt,
		timebill_1.billhrs ,
		timebill_1.workamt ,
		timebill_1.workhrs ,
		'Referral of Matters' AS ref_type ,
		3 AS reftypeno
		-- select mattprlftkpr.*
	FROM red_dw.dbo.ds_sh_3e_timecard					AS timecard_1
		INNER JOIN red_dw.dbo.ds_sh_3e_timebill			AS timebill_1 ON timebill_1.timecard = timecard_1.timeindex
		INNER JOIN red_dw.dbo.ds_sh_3e_matter			AS matter_1 ON matter_1.mattindex = timecard_1.billmatter
		INNER JOIN red_dw.dbo.ds_sh_3e_client			AS client_1 ON client_1.clientindex = matter_1.client
		INNER JOIN red_dw.dbo.ds_sh_3e_mattdate			AS mattdate ON mattdate.matterlkup = matter_1.mattindex and mattdate.nxenddate = '9999-12-31'
		INNER JOIN red_dw.dbo.ds_sh_3e_mattprlftkpr		AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid
		INNER JOIN red_dw.dbo.ds_sh_3e_invmaster		AS invmaster ON timebill_1.invmaster = invmaster.invindex
		INNER JOIN red_dw.dbo.ds_sh_3e_armaster       AS armaster ON timebill_1.armaster = armaster.armindex
		LEFT OUTER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper_1 ON timekeeper_1.tkprindex = mattprlftkpr.timekeeper
	WHERE  armaster.invdate >= @processdate
		AND matter_1.opendate >= '20190501'
		AND DATEDIFF(D, matter_1.opendate, armaster.invdate) < 1095


	UNION ALL
        -- Charges
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
	   -- timecard_1.postdate ,
		armaster.invdate,
		IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt) personalbillings,
		billamt  * (mattprlftkpr.percentage / 100) billamt, 
		--timebill_1.billamt * (mattprlftkpr.percentage / 100) billamt,
		0 ,
		0 ,
		0 ,
		'Referral of Matters' AS ref_type ,
		3 AS reftypeno
		-- select mattprlftkpr.*
	FROM   red_dw.dbo.ds_sh_3e_chrgcard					AS timecard_1
		INNER JOIN red_dw.dbo.ds_sh_3e_chrgbill			AS timebill_1 ON timebill_1.chrgcard = timecard_1.chrgcardindex  AND trantype = 'FEES'
		INNER JOIN red_dw.dbo.ds_sh_3e_matter			AS matter_1 ON matter_1.mattindex = timecard_1.billmatter
		INNER JOIN red_dw.dbo.ds_sh_3e_client			AS client_1 ON client_1.clientindex = matter_1.client
		INNER JOIN red_dw.dbo.ds_sh_3e_mattdate			AS mattdate ON mattdate.matterlkup = matter_1.mattindex and mattdate.nxenddate = '9999-12-31'
		INNER JOIN red_dw.dbo.ds_sh_3e_mattprlftkpr		AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid
		INNER JOIN red_dw.dbo.ds_sh_3e_invmaster		AS invmaster ON timebill_1.invmaster = invmaster.invindex
		INNER JOIN red_dw.dbo.ds_sh_3e_armaster       AS armaster ON timebill_1.armaster = armaster.armindex
		LEFT OUTER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper_1 ON timekeeper_1.tkprindex = mattprlftkpr.timekeeper
	WHERE  armaster.invdate >= @processdate
		AND matter_1.opendate >= '20190501'
		AND DATEDIFF(D, matter_1.opendate, armaster.invdate) < 1095

) x 






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
   -- timecard.postdate ,
    armaster.invdate postdate,
    timebill.billamt  * (co.percentage / 100) billamt,
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
	INNER JOIN red_dw.dbo.ds_sh_3e_armaster       AS armaster ON timebill.armaster = armaster.armindex
WHERE  co.timekeeper = 6496
    AND armaster.invdate BETWEEN '20180501' AND '20190430'
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
        armaster.invdate ,
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
		INNER JOIN red_dw.dbo.ds_sh_3e_armaster       AS armaster ON timebill_2.armaster = armaster.armindex
WHERE  armaster.invdate BETWEEN '20180501' AND '20190430'
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
   -- timecard_1.postdate ,
    armaster.invdate postdate,
	timebill_1.billamt * (mattprlftkpr.percentage / 100) billamt,
    timebill_1.billhrs ,
    timebill_1.workamt ,
    timebill_1.workhrs ,
    'Referral of Matters' AS ref_type ,
    3 AS reftypeno
FROM   red_dw.dbo.ds_sh_3e_timecard					AS timecard_1
    INNER JOIN red_dw.dbo.ds_sh_3e_timebill			AS timebill_1 ON timebill_1.timecard = timecard_1.timeindex
    INNER JOIN red_dw.dbo.ds_sh_3e_matter			AS matter_1 ON matter_1.mattindex = timecard_1.billmatter
    INNER JOIN red_dw.dbo.ds_sh_3e_client			AS client_1 ON client_1.clientindex = matter_1.client
    INNER JOIN red_dw.dbo.ds_sh_3e_mattdate			AS mattdate ON mattdate.matterlkup = matter_1.mattindex  and mattdate.nxenddate = '9999-12-31'
    INNER JOIN red_dw.dbo.ds_sh_3e_mattprlftkpr		AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid AND mattprlftkpr.timekeeper = 6496 
  	INNER JOIN red_dw.dbo.ds_sh_3e_invmaster		AS invmaster ON timebill_1.invmaster = invmaster.invindex
	INNER JOIN red_dw.dbo.ds_sh_3e_armaster       AS armaster ON timebill_1.armaster = armaster.armindex
	LEFT OUTER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper_1 ON timekeeper_1.tkprindex = mattprlftkpr.timekeeper
WHERE  armaster.invdate BETWEEN '20180501' AND '20190430'
AND timecard_1.timekeeper <> 6496-- excludes matter refs







) ROI
INNER JOIN red_dw.dbo.ds_sh_3e_matter ON ds_sh_3e_matter.mattindex = ROI.mattindex;



GO
