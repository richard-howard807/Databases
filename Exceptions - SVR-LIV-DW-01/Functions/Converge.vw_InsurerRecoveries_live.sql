SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM [Converge].[vw_InsurerRecoveries](339866, '2012-11-01')
-- SELECT * FROM [Converge].[vw_InsurerRecoveries_live](339866)

CREATE FUNCTION [Converge].[vw_InsurerRecoveries_live] (
	  @CaseID int
)
RETURNS @rettab TABLE (case_id int, TotalInsurerRecovered money)
AS
BEGIN
	INSERT INTO @rettab
	SELECT cashdr.case_id
		 , SUM(ISNULL(childval.case_value,0)) AS TotalInsurerRecovered
	FROM axxia01.dbo.caslup child
	INNER JOIN axxia01.dbo.cmldetsubd link ON child.case_detail_code = link.sub_detail
	INNER JOIN axxia01.dbo.caslup parent ON link.detail_code = parent.case_detail_code
	INNER JOIN axxia01.dbo.casdet parentval ON parent.case_detail_code = parentval.case_detail_code
	LEFT JOIN axxia01.dbo.stdetlst parentlup ON parentval.case_detail_code = parentlup.sd_detcod AND parentval.case_text = parentlup.sd_liscod
	LEFT JOIN axxia01.dbo.casdet childval ON parentval.seq_no = childval.cd_parent AND parentval.case_id = childval.case_id AND childval.case_detail_code = 'VE00130'
	INNER JOIN axxia01.dbo.cashdr ON childval.case_id = axxia01.dbo.cashdr.case_id
	LEFT JOIN axxia01.dbo.casdet PaymentSeqNo ON parentval.seq_no = PaymentSeqNo.cd_parent AND parentval.case_id = PaymentSeqNo.case_id AND PaymentSeqNo.case_detail_code = 'VE00327'
	LEFT JOIN axxia01.dbo.casdet RecoverySeqNo ON parentval.seq_no = RecoverySeqNo.cd_parent AND parentval.case_id = RecoverySeqNo.case_id AND RecoverySeqNo.case_detail_code = 'VE00328'
	WHERE child.case_detail_code = 'VE00130'
		AND LOWER(parentlup.sd_listxt) LIKE '%insurer%'
		AND NOT (cashdr.client = '00513126' -- Exclude Severn Trent payments made on or after 08/10/11 which don't have sequence numbers.
				 AND parentval.case_date >= '2011-10-08'
				 AND COALESCE(PaymentSeqNo.case_text, RecoverySeqNo.case_text) IS NULL
				 AND child.case_detail_code IN ('VE00130', 'VE00158', 'VE00159', 'VE00160')
				)
		AND cashdr.case_id = @CaseID
	GROUP BY cashdr.case_id

	RETURN
END
GO
