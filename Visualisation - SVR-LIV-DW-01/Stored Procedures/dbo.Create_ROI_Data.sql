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

RH 20200204 - Excluded two clients from hard cutoff date after request from Laura Harrison 

ES 20210610 - added legal directors and martin vincent, requested by greg

RH 20210630 - Greg requested change in logic to how personal billings are deducated from client/matter total
						old logic (billamt)		= (Total - Personal Billings) * Percent split
						new logic (billamt_v2)  = (total * percent split) - personal billings

JB 20220202 - altered table and query to show amount paid on the bills as per Greg's request. 

exec [dbo].[Create_ROI_Data] '20190101'
*/



CREATE PROCEDURE [dbo].[Create_ROI_Data]
    @processdate DATETIME
AS

	/* For testing purposes*/
	--DECLARE @processdate DATE = '20190501'
	--DECLARE @test_partner AS INT = 176 --Alex Marler
	--DECLARE @start_date AS DATE = '2021-05-01'
	--DECLARE @end_date AS DATE = '2022-02-01'

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
	'Fixed Share Partner', 'Legal Director' )
	--20200210, 46543
	OR a.displayname IN ('Robert Turnbull','Martin Vincent')


	DECLARE @matter_refs TABLE (timekeeper INT)
	INSERT INTO @matter_refs
	
	SELECT DISTINCT mattprlftkpr.timekeeper
	FROM   red_dw.dbo.ds_sh_3e_matter			AS matter_1		
    INNER JOIN red_dw.dbo.ds_sh_3e_mattdate		AS mattdate ON mattdate.matterlkup = matter_1.mattindex AND mattdate.nxenddate = '99991231'
    INNER JOIN red_dw.dbo.ds_sh_3e_mattprlftkpr	AS mattprlftkpr ON mattprlftkpr.mattdate = mattdate.mattdateid


--SELECT * FROM @timekeepers 
    TRUNCATE TABLE ROI;

DROP TABLE IF EXISTS #partner_bills

SELECT [entity number],
       [client number],
       clientindex,
       [client name],
       [client status],
       [client open date],
       [Client Introducer],
       timekeeper,
	   actual_timekeeper,
       ROI.mattindex,
       postdate,
	   invoice_date,
       billamt,
	   billamt_v2,
       billhrs,
       workamt,
       workhrs,
       ref_type,
       reftypeno
	   ,[percentage] ,
    GETDATE() AS update_time,
    altnumber,
	invindex
INTO #partner_bills
FROM   (   

/* Billings on the Introducers Clients that are not their own personal billings*/



	SELECT c.entity AS 'entity number' ,
		c.number AS 'client number' ,
		c.clientindex ,
		c.displayname AS 'client name' ,
		c.clistatustype AS 'client status' ,
		c.opendate AS 'client open date' ,
		tko.displayname + ' (' + tko.payrollnumber + ')' AS 'Client Introducer' ,
		tko.tkprindex AS timekeeper ,
		timecard.timekeeper	AS actual_timekeeper,
	--	timecard.timekeeper AS 'fee', -- for testing purposes to see which fee earners time records
		matter.mattindex ,
	   -- timecard.postdate ,
		armaster.invdate postdate,
		invmaster.invdate	AS invoice_date,
	--	IIF(timecard.timekeeper <> co.timekeeper, 0, billamt) personalbillings,
		(billamt - IIF(timecard.timekeeper <> co.timekeeper, 0, billamt))  * (co.percentage / 100) billamt,
		(billamt * (co.percentage / 100)) - iif(timecard.timekeeper <> co.timekeeper, 0, billamt) billamt_v2,
		timebill.billhrs ,
		timebill.workamt ,
		timebill.workhrs ,
		'Intro of Client Billing' AS ref_type 
		-- , co.percentage / 100,
		,2 AS reftypeno
		,co.percentage
		, invmaster.invindex
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
		--and c.number = 'W21295'
		AND ((c.opendate >= '20190501' 
		AND DATEDIFF(D, c.opendate, armaster.invdate) < 1095)
		OR c.number IN ('123447R','W21348','W21295','89377S','105576','W18918','WB170835','115222')) -- Request to exclude two clients from hard date cut off by Laura Harrison | 'W21295' from Greg | '89377S','105576','W18918' from Anna | FY 21/22 'WB170835','115222' From Greg 
			AND armaster.invdate >= @processdate														
	   --  AND timecard.timekeeper NOT IN (SELECT timekeeper FROM @timekeepers  ) -- Exclues any timecard transactions by client introducer
	 --  AND timecard.timekeeper <> co.timekeeper
		--AND tko.tkprindex = @test_partner
	    


	 UNION ALL
  -- Charges   

	 SELECT c.entity AS 'entity number' ,
		c.number AS 'client number' ,
		c.clientindex ,
		c.displayname AS 'client name' ,
		c.clistatustype AS 'client status' ,
		c.opendate AS 'client open date' ,
		tko.displayname + ' (' + tko.payrollnumber + ')' AS 'Client Introducer' ,
		tko.tkprindex AS timekeeper ,
		timecard.timekeeper AS actual_timekeeper,
	--	timecard.timekeeper AS 'fee', -- for testing purposes to see which fee earners time records
		matter.mattindex ,
	   -- timecard.postdate ,
		armaster.invdate postdate,
		invmaster.invdate	AS invoice_date,
		--iif(timecard.timekeeper <> co.timekeeper, 0, billamt) personalbillings,
		(billamt - IIF(timecard.timekeeper <> co.timekeeper, 0, billamt))  * (co.percentage / 100) billamt, 
		(billamt * (co.percentage / 100)) - iif(timecard.timekeeper <> co.timekeeper, 0, billamt) billamt_v2,
		0 ,
		0 ,
		0 ,
		'Intro of Client Billing' AS ref_type 
		-- , co.percentage / 100,
		,2 AS reftypeno
		,co.percentage
		, invmaster.invindex
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
		--and c.number = 'W21295'
		AND ((c.opendate >= '20190501' 
		AND DATEDIFF(D, c.opendate, armaster.invdate) < 1095)
	OR c.number IN ('123447R','W21348','W21295','89377S','105576','W18918','WB170835','115222')) -- Request to exclude two clients from hard date cut off by Laura Harrison | 'W21295' from Greg | '89377S','105576','W18918' from Anna | FY 21/22 'WB170835','115222' From Greg
														
		AND armaster.invdate >= @processdate
		--AND tko.tkprindex = @test_partner

/* Revenue or Personal Billings */
                        
   UNION ALL


SELECT NULL AS [entity number] ,
        client.number AS client ,
        client.clientindex ,
        client.displayname AS [client name] ,
        client.clistatustype AS [client status] ,
        client.opendate AS [client open date] ,
        timekeeper.displayname + ' (' + timekeeper.payrollnumber + ')' AS [client introducer] ,
        timekeeper.tkprindex AS timekeeper ,
		timecard_2.timekeeper AS actual_timekeeper,
--		timecard_2.timekeeper AS 'fee',
        matter_2.mattindex ,
        armaster.invdate ,
		invmaster1.invdate	AS invoice_date,
        timebill_2.billamt ,
		timebill_2.billamt billamt_v2 ,
        timebill_2.billhrs ,
        timebill_2.workamt ,
        timebill_2.workhrs ,
        'Personal Billing' AS ref_type ,
        1 AS reftypeno
		,NULL 
		, invmaster1.invindex
FROM   red_dw.dbo.ds_sh_3e_timecard					AS timecard_2
        INNER JOIN red_dw.dbo.ds_sh_3e_timebill		AS timebill_2 ON timebill_2.timecard = timecard_2.timeindex
        INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster1 ON timebill_2.invmaster = invmaster1.invindex
        INNER JOIN red_dw.dbo.ds_sh_3e_armaster     AS armaster ON timebill_2.armaster = armaster.armindex
		INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter_2 ON matter_2.mattindex = timecard_2.billmatter
        INNER JOIN red_dw.dbo.ds_sh_3e_client		AS client ON client.clientindex = matter_2.client
        INNER JOIN @timekeepers						AS refer ON timecard_2.timekeeper = refer.timekeeper
        INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper ON timekeeper.tkprindex = refer.timekeeper
WHERE  armaster.invdate >= @processdate
	--AND timekeeper.tkprindex = @test_partner

UNION ALL

-- Personal billing charge fees

SELECT NULL AS [entity number] ,
        client.number AS client ,
        client.clientindex ,
        client.displayname AS [client name] ,
        client.clistatustype AS [client status] ,
        client.opendate AS [client open date] ,
        timekeeper.displayname + ' (' + timekeeper.payrollnumber + ')' AS [client introducer] ,
        timekeeper.tkprindex AS timekeeper ,
		timecard_2.timekeeper AS actual_timekeeper,
--		timecard_2.timekeeper AS 'fee',
        matter_2.mattindex ,
        armaster.invdate ,
		invmaster1.invdate	AS invoice_date,
        timebill_2.billamt ,
		timebill_2.billamt billamt_v2 ,
        0 ,
        0 ,
        0 ,
        'Personal Billing' AS ref_type ,
        1 AS reftypeno
		,NULL  
		, invmaster1.invindex
FROM   red_dw.dbo.ds_sh_3e_chrgcard					AS timecard_2
        INNER JOIN red_dw.dbo.ds_sh_3e_chrgbill		AS timebill_2 ON timebill_2.chrgcard = timecard_2.chrgcardindex  AND trantype = 'FEES'
        INNER JOIN red_dw.dbo.ds_sh_3e_invmaster	AS invmaster1 ON timebill_2.invmaster = invmaster1.invindex
        INNER JOIN red_dw.dbo.ds_sh_3e_armaster     AS armaster ON timebill_2.armaster = armaster.armindex
		INNER JOIN red_dw.dbo.ds_sh_3e_matter		AS matter_2 ON matter_2.mattindex = timecard_2.billmatter
        INNER JOIN red_dw.dbo.ds_sh_3e_client		AS client ON client.clientindex = matter_2.client
        INNER JOIN @timekeepers						AS refer ON timecard_2.timekeeper = refer.timekeeper
        INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper	AS timekeeper ON timekeeper.tkprindex = refer.timekeeper
WHERE  armaster.invdate >= @processdate
	--AND timekeeper.tkprindex = @test_partner



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
	   x.actual_timekeeper,
       x.mattindex,
       x.invdate,  
	   x.invoice_date,
       --x.billamt - x.personalbillings billamt,
	   x.billamt billamt,
	    x.billamt billamt_v2,
	   x.billhrs,
       x.workamt,
       x.workhrs,
       x.ref_type,
       x.reftypeno
	   ,x.percentage
	   , x.invindex
FROM (

	SELECT NULL AS [entity number] ,
		client_1.number AS client ,
		client_1.clientindex ,
		client_1.displayname AS [client name] ,
		client_1.clistatustype AS [client status] ,
		client_1.opendate AS [client open date] ,
		timekeeper_1.displayname + ' (' + timekeeper_1.payrollnumber + ')' AS [client introducer] ,
		timekeeper_1.tkprindex AS timekeeper ,
		timecard_1.timekeeper	AS actual_timekeeper,
	--	timecard_1.timekeeper AS 'fee',
		matter_1.mattindex ,
	   -- timecard_1.postdate ,
		armaster.invdate,
		invmaster.invdate	AS invoice_date,
		IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt) personalbillings,
		(billamt - IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt))  * (mattprlftkpr.percentage / 100) billamt, 
		(billamt * (mattprlftkpr.percentage / 100)) - IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt)   billamt_v2, 
		--timebill_1.billamt * (mattprlftkpr.percentage / 100) billamt,
		timebill_1.billhrs ,
		timebill_1.workamt ,
		timebill_1.workhrs ,
		'Referral of Matters' AS ref_type ,
		3 AS reftypeno
		,mattprlftkpr.percentage
		, invmaster.invindex
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
	WHERE  armaster.invdate >= '20190501'
			and ((matter_1.opendate >= '20190501'		
			and DATEDIFF(D, matter_1.opendate, armaster.invdate) < 1095)

				or matter_1.number IN ('720451-1001','W21334-1')) -- Request to exclude matter from cut-off date from Anna | '720451-1001
				--and matter_1.number = '720451-1001'
		--AND timekeeper_1.tkprindex = @test_partner
		
	UNION all

        -- Charges
		SELECT NULL AS [entity number] ,
		client_1.number AS client ,
		client_1.clientindex ,
		client_1.displayname AS [client name] ,
		client_1.clistatustype AS [client status] ,
		client_1.opendate AS [client open date] ,
		timekeeper_1.displayname + ' (' + timekeeper_1.payrollnumber + ')' AS [client introducer] ,
		timekeeper_1.tkprindex AS timekeeper ,
		timecard_1.timekeeper AS actual_timekeeper,
	--	timecard_1.timekeeper AS 'fee',
		matter_1.mattindex ,
	   -- timecard_1.postdate ,
		armaster.invdate,
		invmaster.invdate	AS invoice_date,
		IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt) personalbillings,
		(billamt - IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt)) * (mattprlftkpr.percentage / 100) billamt, 
		
		(billamt * (mattprlftkpr.percentage / 100)) - IIF(timecard_1.timekeeper <> mattprlftkpr.timekeeper, 0, billamt)   billamt_v2, 
		--timebill_1.billamt * (mattprlftkpr.percentage / 100) billamt,
		0 ,
		0 ,
		0 ,
		'Referral of Matters' AS ref_type ,
		3 AS reftypeno
		,mattprlftkpr.percentage
		, invmaster.invindex
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
			and ((matter_1.opendate >= '20190501'		
			and DATEDIFF(D, matter_1.opendate, armaster.invdate) < 1095)

				or matter_1.number IN ('720451-1001','W21334-1')) -- Request to exclude matter from cut-off date from Anna | '720451-1001
			--AND timekeeper_1.tkprindex = @test_partner

) x 






/* Kieran Donovan is a special case and started earlier I am adding his figures from 2018 separately*/

UNION ALL

SELECT c.entity AS 'entity number' ,
    c.number AS 'client number' ,
    c.clientindex ,
    c.displayname AS 'client name' ,
    c.clistatustype AS 'client status' ,
    c.opendate AS 'client open date' ,
    tko.displayname + ' (' + tko.payrollnumber + ')' AS 'Client Introducer' ,
    tko.tkprindex AS timekeeper ,
	timecard.timekeeper	AS actual_timekeeper,
--	timecard.timekeeper AS 'fee', -- for testing purposes to see which fee earners time records
    matter.mattindex ,
   -- timecard.postdate ,
    armaster.invdate postdate,
	invmaster.invdate	AS invoice_date,
    timebill.billamt  * (co.percentage / 100) billamt,
	timebill.billamt  * (co.percentage / 100) billamt_v2,
    timebill.billhrs ,
    timebill.workamt ,
    timebill.workhrs ,
    'Intro of Client Billing' AS ref_type ,
    2 AS reftypeno
	,co.percentage
	, invmaster.invindex
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
        timekeeper.displayname + ' (' + timekeeper.payrollnumber + ')' AS [client introducer] ,
        timekeeper.tkprindex AS timekeeper ,
		timecard_2.timekeeper		AS actual_timekeeper,
--		timecard_2.timekeeper AS 'fee',
        matter_2.mattindex ,
        armaster.invdate ,
		invmaster1.invdate	AS invoice_date,
        timebill_2.billamt ,
		timebill_2.billamt billamt_v2 ,
        timebill_2.billhrs ,
        timebill_2.workamt ,
        timebill_2.workhrs ,
        'Personal Billing' AS ref_type ,
        1 AS reftypeno
		,NULL 
		, invmaster1.invindex
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
    timekeeper_1.displayname + ' (' + timekeeper_1.payrollnumber + ')' AS [client introducer] ,
    timekeeper_1.tkprindex AS timekeeper ,
	timecard_1.timekeeper AS actual_timekeeper,
--	timecard_1.timekeeper AS 'fee',
    matter_1.mattindex ,
   -- timecard_1.postdate ,
    armaster.invdate postdate,
	invmaster.invdate	AS invoice_date,
	timebill_1.billamt * (mattprlftkpr.percentage / 100) billamt,
	timebill_1.billamt * (mattprlftkpr.percentage / 100) billamt_2v,
    timebill_1.billhrs ,
    timebill_1.workamt ,
    timebill_1.workhrs ,
    'Referral of Matters' AS ref_type ,
    3 AS reftypeno
	,mattprlftkpr.percentage
	, invmaster.invindex
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




--Include payment data for bills raised
INSERT INTO ROI
(
	[entity number],
    [client number],
    clientindex,
    [client name],
    [client status],
    [client open date],
    [Client Introducer],
    timekeeper,
    ROI.mattindex,
    postdate,
    billamt,
	billamt_v2,
    billhrs,
    workamt,
    workhrs,
    ref_type,
    reftypeno,
	[percentage] ,
	update_time,
	altnumber,
	actual_timekeeper,
	invindex,
	paid_total
)
SELECT 
	#partner_bills.[entity number],
    #partner_bills.[client number],
    #partner_bills.clientindex,
    #partner_bills.[client name],
    #partner_bills.[client status],
    #partner_bills.[client open date],
    #partner_bills.[Client Introducer],
    #partner_bills.timekeeper,
    #partner_bills.mattindex,
	#partner_bills.invoice_date,
    SUM(#partner_bills.billamt)		AS billamt,
    SUM(#partner_bills.billamt_v2) AS billamt_v2,
    SUM(#partner_bills.billhrs)	AS billhrs,
    SUM(#partner_bills.workamt) AS workamt,
    SUM(#partner_bills.workhrs) AS workhrs,
    #partner_bills.ref_type,
    #partner_bills.reftypeno,
    #partner_bills.percentage,
    #partner_bills.update_time,
	#partner_bills.altnumber,
	#partner_bills.actual_timekeeper,
    #partner_bills.invindex,
	IIF(#partner_bills.ref_type = 'Personal Billing', total_paid.bill_paid_total,
		(bill_paid_total * (#partner_bills.percentage / 100)) - iif(#partner_bills.actual_timekeeper <> #partner_bills.timekeeper, 0, bill_paid_total)) AS paid_total
FROM #partner_bills
	LEFT OUTER JOIN (
						SELECT 
							fact_bill_receipts_detail.bill_sequence
							, ds_sh_3e_timekeeper.tkprindex
							, matterindex_bill_item
							, SUM(fact_bill_receipts_detail.revenue)	AS bill_paid_total
						FROM red_dw.dbo.fact_bill_receipts_detail
							INNER JOIN red_dw.dbo.ds_sh_3e_timekeeper
								ON ds_sh_3e_timekeeper.number = fact_bill_receipts_detail.fed_code
							INNER JOIN (SELECT DISTINCT #partner_bills.invindex FROM #partner_bills) AS partner_bills
								ON fact_bill_receipts_detail.bill_sequence = partner_bills.invindex
							INNER JOIN red_dw.dbo.dim_date
								ON dim_date.calendar_date = CAST(fact_bill_receipts_detail.bill_date AS DATE)
						WHERE 1 = 1
							and bill_fully_paid = 1 -- only fully paid bills included in bonus scheme
							--Exclude payments over 3 months after year end of the bills fin year 
							AND fact_bill_receipts_detail.receipt_date < DATEADD(MONTH, 3, DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, 12 - dim_date.fin_month_no, fact_bill_receipts_detail.bill_date))))
						GROUP BY
							fact_bill_receipts_detail.bill_sequence
							, matterindex_bill_item
							, ds_sh_3e_timekeeper.tkprindex
					) AS total_paid
		ON total_paid.bill_sequence = #partner_bills.invindex
			AND total_paid.tkprindex = #partner_bills.actual_timekeeper
			and #partner_bills.mattindex = total_paid.matterindex_bill_item
WHERE 1 = 1
	--AND #partner_bills.invoice_date BETWEEN @start_date AND @end_date
GROUP BY
	#partner_bills.[entity number],
    #partner_bills.[client number],
    #partner_bills.clientindex,
    #partner_bills.[client name],
    #partner_bills.[client status],
    #partner_bills.[client open date],
    #partner_bills.[Client Introducer],
    #partner_bills.timekeeper,
    #partner_bills.mattindex,
    #partner_bills.ref_type,
    #partner_bills.reftypeno,
    #partner_bills.percentage,
    #partner_bills.update_time,
    #partner_bills.altnumber,
	#partner_bills.actual_timekeeper,
	#partner_bills.invoice_date,
    #partner_bills.invindex,
	total_paid.bill_paid_total




GO
