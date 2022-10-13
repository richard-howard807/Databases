SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CoopPresentPositionMovement]
AS
BEGIN

SELECT 
cashdr.case_id
,client,matter,case_public_desc1 AS [Matter Description]
,display_name AS [Fee Earner]
,hierarchylevel4 AS [Team]
,effective_start_date AS [Date Changed]
,ChangedTo.case_text AS [Changed To Present Position]
,ChangedFrom.case_text AS [Changed From Present Position]
,TRA086.case_date AS [Date damages settled]
,FTR087.case_date AS [Date costs settled]
FROM 
(SELECT case_id,effective_start_date,case_text
FROM red_dw.dbo.ds_sh_axxia_casdet
WHERE CONVERT(DATE,effective_start_date,103)=CONVERT(DATE,GETDATE()-1,103)
AND case_detail_code='TRA125'
AND current_flag='Y'
AND case_text='Final bill due - claim and costs concluded'
) AS ChangedTo
INNER JOIN axxia01.dbo.cashdr ON ChangedTo.case_id=cashdr.case_id
INNER JOIN axxia01.dbo.camatgrp ON client=mg_client AND matter=mg_matter
INNER JOIN red_dw.dbo.dim_fed_hierarchy_current  ON mg_feearn=fed_code
LEFT OUTER JOIN (SELECT case_id,case_text
,ROW_NUMBER() OVER (PARTITION BY case_id ORDER BY effective_end_date DESC ) AS OrderID
,effective_end_date
FROM red_dw.dbo.ds_sh_axxia_casdet
WHERE 
CONVERT(DATE,effective_end_date,103)=CONVERT(DATE,GETDATE()-1,103)
--AND case_id=592163
AND case_detail_code='TRA125'
AND case_id IN (SELECT case_id FROM red_dw.dbo.ds_sh_axxia_casdet
WHERE CONVERT(DATE,effective_start_date,103)=CONVERT(DATE,GETDATE()-1,103)
AND case_detail_code='TRA125')
) AS ChangedFrom
 ON ChangedTo.case_id=ChangedFrom.case_id
 AND OrderID=1
LEFT OUTER JOIN (SELECT case_id,case_date FROM red_dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='TRA086' AND current_flag='Y') AS TRA086
 ON cashdr.case_id=TRA086.case_id 
LEFT OUTER JOIN (SELECT case_id,case_date FROM red_dw.dbo.ds_sh_axxia_casdet WHERE case_detail_code='FTR087' AND current_flag='Y') AS FTR087
 ON cashdr.case_id=FTR087.case_id  
 
 

WHERE client IN ('00046018', '00215267', '00337897', 'C15332','C1001')
 ORDER BY client,matter
END
GO
