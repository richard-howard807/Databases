SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-05-31
-- Description:	To get RMG Previous fields for last month 
-- =============================================
CREATE PROCEDURE [royalmail].[P0003PreviousResults]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @PreviousMonthEnd Date
		set @PreviousMonthEnd = DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) 

--select All last months data from fed
IF OBJECT_ID('tempdb..#P0003ResultsFed') IS NOT NULL DROP TABLE #P0003ResultsFed
SELECT 
cashdr.client,
cashdr.matter,
case_text,
case_value,
case_date,
casdet.case_id,
case_detail_code,
cashdr.date_closed
INTO #P0003ResultsFed
FROM  red_dw.dbo.ds_sh_axxia_casdet casdet WITH (NOLOCK) 
inner JOIN  red_Dw.dbo.ds_sh_axxia_cashdr cashdr WITH (NOLOCK) ON  
cashdr.case_id = casdet.case_id AND 
@PreviousMonthEnd BETWEEN cashdr.effective_start_date AND cashdr.effective_end_date 	
WHERE 
@PreviousMonthEnd BETWEEN casdet.effective_start_date AND casdet.effective_end_date  and 
cashdr.client IN ('P00003','R1001') and
casdet.deleted_flag <> 'Y' AND 
casdet.case_detail_code in ('TRA070','TRA072','TRA086','FTR087','TRA078','FTR049','TRA076','TRA080','TRA125','RMX073','RMX074','NMI065','NMI519','NMI066','NMI378','NMI379')

--select all current data from fed
IF OBJECT_ID('tempdb..#P0003ResultsFedCurrent') IS NOT NULL DROP TABLE #P0003ResultsFedCurrent
SELECT 
cashdr.client,
cashdr.matter,
case_text,
case_value,
case_date,
casdet.case_id,
case_detail_code,
cashdr.date_closed
INTO #P0003ResultsFedCurrent
FROM  red_dw.dbo.ds_sh_axxia_casdet casdet WITH (NOLOCK) 
inner JOIN  red_Dw.dbo.ds_sh_axxia_cashdr cashdr WITH (NOLOCK) ON  
cashdr.case_id = casdet.case_id AND cashdr.current_flag = 'Y'
WHERE 
cashdr.client IN ('P00003','R1001') and
casdet.current_flag = 'Y' AND 
casdet.case_detail_code in ('TRA070','TRA072','TRA086','FTR087','TRA078','FTR049','TRA076','TRA080','TRA125','RMX073','RMX074','NMI065','NMI519','NMI066','NMI378','NMI379')



SELECT 
presults.client,
presults.matter,
presults.client_matter,
isnull(CASE WHEN cresults.dteClaimConclud IS NOT NULL THEN isnull(presults.curDamsPaidCli,0) ELSE isnull(cresults.curInDamPayPo,0) + isnull(cresults.curIntDamsPreIn,0) END,0) AS [Payments (damages and CRU)],
isnull(CASE WHEN presults.dteClaimConclud IS NOT NULL THEN isnull(presults.curDamsPaidCli,0) ELSE isnull(presults.curInDamPayPo,0) + isnull(presults.curIntDamsPreIn,0) END,0) AS [Previous Payments (damages and CRU)],
isnull(CASE WHEN cresults.dteCostsSettled IS NOT NULL THEN ISNULL(cresults.curClaCostCliBS,0) + ISNULL(cresults.curCostPaAnDef,0) + ISNULL(cresults.curInterPaidClt,0) + ISNULL(cresults.curAssCostsPai,0) ELSE isnull(cresults.curIntCoPayPost,0) + isnull(cresults.curIntCoPayPre,0) END,0) as [Payments (claimant costs)],
isnull(CASE WHEN presults.dteCostsSettled IS NOT NULL THEN ISNULL(presults.curClaCostCliBS,0) + ISNULL(presults.curCostPaAnDef,0) + ISNULL(presults.curInterPaidClt,0) + ISNULL(presults.curAssCostsPai,0) ELSE isnull(presults.curIntCoPayPost,0) + isnull(presults.curIntCoPayPre,0) END,0) as [Previous Payments (claimant costs)] ,
CASE WHEN cresults.dteClaimConclud IS NOT NULL  THEN 0 ELSE ISNULL(coalesce(cresults.curDamResCur,presults.RMX073),0) - (ISNULL(cresults.curInDamPayPo,0) + isnull(cresults.curIntDamsPreIn,0)) END  AS [Outstanding reserve (damages and CRU inc NHS)],
CASE WHEN presults.dteClaimConclud IS NOT NULL  THEN 0 ELSE ISNULL(coalesce(presults.curDamResCur,presults.RMX073),0) - (ISNULL(presults.curInDamPayPo,0) + isnull(presults.curIntDamsPreIn,0)) END  AS [Previous Outstanding reserve (damages and CRU inc NHS)],
CASE WHEN cresults.dteCostsSettled IS NOT NULL  THEN 0 ELSE (ISNULL(coalesce(cresults.curClaCostReCur,presults.RMX074),0) + ISNULL(cresults.curOthDeCosResC,0)) - (ISNULL(cresults.curIntCoPayPost,0) + isnull(cresults.curIntCoPayPre,0)) END AS [Outstanding claimant costs],
CASE WHEN presults.dteCostsSettled IS NOT NULL  THEN 0 ELSE (ISNULL(coalesce(presults.curClaCostReCur,presults.RMX074),0) + ISNULL(presults.curOthDeCosResC,0)) - (ISNULL(presults.curIntCoPayPost,0) + isnull(presults.curIntCoPayPre,0)) END AS [Previous Outstanding claimant costs],
ISNULL(BillUpToCurrent,0) AS [Own costs paid to date],
ISNULL(BillUpToPrevious,0) AS [Previous Own costs paid to date],
CASE WHEN cresults.date_closed is not null or rtrim(cresults.cboPresentPos) = 'To be closed/minor balances to be clear' THEN 0 ELSE cresults.curDefCostReCur - ISNULL(BillUpToCurrent,0)END  AS [Outstanding own costs],
CASE WHEN presults.date_closed is not null or rtrim(presults.cboPresentPos) = 'To be closed/minor balances to be clear' THEN 0 ELSE presults.curDefCostReCur - ISNULL(BillUpToPrevious,0)END  AS [Previous Outstanding own costs]

FROM
(
SELECT 
cashdr.client,
cashdr.matter,
cashdr.case_id,
RTRIM(cashdr.client) + '-' + RTRIM(cashdr.matter) client_matter ,
date_closed,
TRA070.Value curDamsPaidCli,
NMI065.Value curInDamPayPo,
FTR049.Value curIntDamsPreIn,
TRA072.Value curClaCostCliBS,
NMI379.Value curCostPaAnDef,
NMI377.Value curInterPaidClt,
NMI143.Value curAssCostsPai,
NMI066.Value curIntCoPayPost,
NMI378.Value curIntCoPayPre,
TRA076.Value curDamResCur,
RMX073.Value RMX073,
TRA080.Value curClaCostReCur,
RMX074.Value RMX074,
NMI519.Value curOthDeCosResC,
TRA078.Value curDefCostReCur,
TRA086.case_date dteClaimConclud,
FTR087.case_date dteCostsSettled,
TRA125.case_text cboPresentPos
FROM #P0003ResultsFed  cashdr
LEFT OUTER JOIN (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'TRA070') AS TRA070 on cashdr.case_id = TRA070.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'NMI065') AS NMI065 ON cashdr.case_id = NMI065.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'FTR049') AS FTR049 ON cashdr.case_id = FTR049.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'TRA072') AS TRA072 ON cashdr.case_id = TRA072.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'NMI379') AS NMI379 ON cashdr.case_id = NMI379.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'NMI377') AS NMI377 ON cashdr.case_id = NMI377.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'NMI143') AS NMI143 ON cashdr.case_id = NMI143.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'NMI066') AS NMI066 ON cashdr.case_id = NMI066.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'NMI378') AS NMI378 ON cashdr.case_id = NMI378.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'TRA076') AS TRA076 ON cashdr.case_id = TRA076.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'RMX073') AS RMX073 ON cashdr.case_id = RMX073.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'TRA080') AS TRA080 ON cashdr.case_id = TRA080.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'RMX074') AS RMX074 ON cashdr.case_id = RMX074.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'NMI519') AS NMI519 ON cashdr.case_id = NMI519.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFed WHERE case_detail_code = 'TRA078' ) AS TRA078 ON cashdr.case_id = TRA078.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_date  FROM #P0003ResultsFed WHERE case_detail_code = 'TRA086') AS TRA086 ON cashdr.case_id = TRA086.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_date  FROM #P0003ResultsFed WHERE case_detail_code = 'FTR087' ) AS FTR087 ON cashdr.case_id = FTR087.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_text FROM #P0003ResultsFed WHERE case_detail_code = 'TRA125' ) AS TRA125 ON cashdr.case_id = TRA125.case_id

UNION 

SELECT 
CASE WHEN ISNUMERIC(client.clno) = 1 THEN  RIGHT('00000000'+client.clno,8) ELSE client.clno END client,
RIGHT('00000000'+a.fileno,8) matter,
a.fileid,
udextfile.fedcode,
fileclosed,
d.curdamspaidcli,
d.curindampaypo,
d.curintdamsprein,
c.curclacostclibs,
c.curcostpaandef,
c.curinterpaidclt,
c.curasscostspai,
c.curintcopaypost,
c.curintcopaypre,
b.curdamrescur,
0 RMX073,
b.curclacostrecur,
0 RMX074,
b.curothdecosresc,
b.curdefcostrecur,
d.dteclaimconclud,
c.dtecostssettled,
d.cbopresentpos
FROM red_Dw.dbo.ds_sh_ms_dbfile a
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbclient client ON client.clid = a.clid 
LEFT JOIN red_Dw.dbo.ds_sh_ms_udextfile udextfile  ON udextfile.fileid = a.fileid
LEFT JOIN  red_Dw.dbo.ds_sh_ms_udmicurrentreserves_history b ON b.fileid = a.fileid AND @PreviousMonthEnd BETWEEN b.dss_start_date AND b.dss_end_date
LEFT JOIN red_Dw.dbo.ds_sh_ms_udmioutcomecosts_history c  ON a.fileid = c.fileid AND @PreviousMonthEnd BETWEEN c.dss_start_date AND c.dss_end_date   
LEFT JOIN red_Dw.dbo.ds_sh_ms_udmioutcomedamages_history d ON d.fileid = a.fileid AND @PreviousMonthEnd BETWEEN d.dss_start_date AND d.dss_end_date  
WHERE (
d.curdamspaidcli IS NOT NULL OR 
d.curindampaypo IS NOT NULL OR 
d.curintdamsprein IS NOT NULL OR 
c.curclacostclibs IS NOT NULL OR 
c.curcostpaandef IS NOT NULL OR 
c.curinterpaidclt IS NOT NULL OR 
c.curasscostspai IS NOT NULL OR 
c.curintcopaypost IS NOT NULL OR 
c.curintcopaypre IS NOT NULL OR 
b.curdamrescur IS NOT NULL OR 
b.curclacostrecur IS NOT NULL OR 
b.curothdecosresc IS NOT NULL OR 
b.curdefcostrecur IS NOT NULL OR 
d.dteclaimconclud IS NOT NULL OR 
c.dtecostssettled IS NOT NULL OR 
d.cbopresentpos  IS NOT NULL )
) presults
LEFT JOIN (SELECT client_code,matter_number,SUM(bill_total) BillUpToPrevious from red_dw.dbo.fact_bill_matter_detail WHERE bill_date <=  @PreviousMonthEnd GROUP BY client_code,matter_number) billsp  ON billsp.client_code = presults.client AND billsp.matter_number = presults.matter
--join curren records
LEFT JOIN (
SELECT 
cashdr.client,
cashdr.matter,
cashdr.case_id,
RTRIM(cashdr.client) + '-' + RTRIM(cashdr.matter) client_matter ,
date_closed,
TRA070.Value curDamsPaidCli,
NMI065.Value curInDamPayPo,
FTR049.Value curIntDamsPreIn,
TRA072.Value curClaCostCliBS,
NMI379.Value curCostPaAnDef,
NMI377.Value curInterPaidClt,
NMI143.Value curAssCostsPai,
NMI066.Value curIntCoPayPost,
NMI378.Value curIntCoPayPre,
TRA076.Value curDamResCur,
RMX073.Value RMX073,
TRA080.Value curClaCostReCur,
RMX074.Value RMX074,
NMI519.Value curOthDeCosResC,
TRA078.Value curDefCostReCur,
TRA086.case_date dteClaimConclud,
FTR087.case_date dteCostsSettled,
TRA125.case_text cboPresentPos
FROM #P0003ResultsFed  cashdr
LEFT OUTER JOIN (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'TRA070') AS TRA070 on cashdr.case_id = TRA070.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'NMI065') AS NMI065 ON cashdr.case_id = NMI065.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'FTR049') AS FTR049 ON cashdr.case_id = FTR049.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'TRA072') AS TRA072 ON cashdr.case_id = TRA072.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'NMI379') AS NMI379 ON cashdr.case_id = NMI379.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'NMI377') AS NMI377 ON cashdr.case_id = NMI377.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'NMI143') AS NMI143 ON cashdr.case_id = NMI143.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'NMI066') AS NMI066 ON cashdr.case_id = NMI066.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'NMI378') AS NMI378 ON cashdr.case_id = NMI378.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'TRA076') AS TRA076 ON cashdr.case_id = TRA076.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'RMX073') AS RMX073 ON cashdr.case_id = RMX073.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'TRA080') AS TRA080 ON cashdr.case_id = TRA080.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'RMX074') AS RMX074 ON cashdr.case_id = RMX074.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'NMI519') AS NMI519 ON cashdr.case_id = NMI519.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_value as Value FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'TRA078' ) AS TRA078 ON cashdr.case_id = TRA078.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_date  FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'TRA086') AS TRA086 ON cashdr.case_id = TRA086.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_date  FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'FTR087' ) AS FTR087 ON cashdr.case_id = FTR087.case_id
		LEFT OUTER JOIN  (SELECT case_id, case_text FROM #P0003ResultsFedCurrent WHERE case_detail_code = 'TRA125' ) AS TRA125 ON cashdr.case_id = TRA125.case_id

UNION 

SELECT 
CASE WHEN ISNUMERIC(client.clno) = 1 THEN  RIGHT('00000000'+client.clno,8) ELSE client.clno END client,
RIGHT('00000000'+a.fileno,8) matter,
a.fileid,
udextfile.fedcode,
fileclosed,
d.curdamspaidcli,
d.curindampaypo,
d.curintdamsprein,
c.curclacostclibs,
c.curcostpaandef,
c.curinterpaidclt,
c.curasscostspai,
c.curintcopaypost,
c.curintcopaypre,
b.curdamrescur,
0 RMX073,
b.curclacostrecur,
0 RMX074,
b.curothdecosresc,
b.curdefcostrecur,
d.dteclaimconclud,
c.dtecostssettled,
d.cbopresentpos
FROM red_Dw.dbo.ds_sh_ms_dbfile a
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbclient client ON client.clid = a.clid 
LEFT JOIN red_Dw.dbo.ds_sh_ms_udextfile udextfile  ON udextfile.fileid = a.fileid
LEFT JOIN  red_Dw.dbo.ds_sh_ms_udmicurrentreserves b ON b.fileid = a.fileid 
LEFT JOIN red_Dw.dbo.ds_sh_ms_udmioutcomecosts c  ON a.fileid = c.fileid   
LEFT JOIN red_Dw.dbo.ds_sh_ms_udmioutcomedamages d ON d.fileid = a.fileid 
WHERE (
d.curdamspaidcli IS NOT NULL OR 
d.curindampaypo IS NOT NULL OR 
d.curintdamsprein IS NOT NULL OR 
c.curclacostclibs IS NOT NULL OR 
c.curcostpaandef IS NOT NULL OR 
c.curinterpaidclt IS NOT NULL OR 
c.curasscostspai IS NOT NULL OR 
c.curintcopaypost IS NOT NULL OR 
c.curintcopaypre IS NOT NULL OR 
b.curdamrescur IS NOT NULL OR 
b.curclacostrecur IS NOT NULL OR 
b.curothdecosresc IS NOT NULL OR 
b.curdefcostrecur IS NOT NULL OR 
d.dteclaimconclud IS NOT NULL OR 
c.dtecostssettled IS NOT NULL OR 
d.cbopresentpos  IS NOT NULL )
) cresults ON cresults.client = presults.client and cresults.matter = presults.matter
LEFT JOIN (SELECT client_code,matter_number,SUM(bill_total) BillUpToCurrent from red_dw.dbo.fact_bill_matter_detail  GROUP BY client_code,matter_number) billsc  ON billsc.client_code = cresults.client AND billsc.matter_number = cresults.matter

where presults.client IN ('R1001','P00003')  

END
GO
