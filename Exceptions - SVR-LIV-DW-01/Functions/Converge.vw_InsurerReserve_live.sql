SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM Converge.vw_InsurerReserve(335054, '2012-06-01')
-- SELECT * FROM Converge.vw_InsurerReserve_live(335054)

CREATE FUNCTION [Converge].[vw_InsurerReserve_live] (
	  @CaseID int
)
RETURNS @rettab TABLE (case_id int, TotalInsurerReserveIncFees money, TotalInsurerReserveExcFees money)
AS
BEGIN
	INSERT INTO @rettab
	SELECT cashdr.case_id,
		0 + ISNULL([VE00166].case_value, 0)+ ISNULL([VE00174].case_value, 0)+ ISNULL([VE00178].case_value, 0)+ ISNULL([VE00182].case_value, 0)
		+ ISNULL([VE00186].case_value, 0)+ ISNULL([VE00190].case_value, 0)+ ISNULL([VE00194].case_value, 0)+ ISNULL([VE00198].case_value, 0)
		+ ISNULL([VE00202].case_value, 0)+ ISNULL([VE00206].case_value, 0)+ ISNULL([VE00210].case_value, 0)+ ISNULL([VE00214].case_value, 0)
		+ ISNULL([VE00218].case_value, 0)+ ISNULL([VE00222].case_value, 0)+ ISNULL([VE00226].case_value, 0)+ ISNULL([VE00230].case_value, 0)
		+ ISNULL([VE00234].case_value, 0)+ ISNULL([VE00238].case_value, 0)+ ISNULL([VE00242].case_value, 0)+ ISNULL([VE00246].case_value, 0)
		+ ISNULL([VE00250].case_value, 0)+ ISNULL([VE00254].case_value, 0)+ ISNULL([VE00258].case_value, 0)+ ISNULL([VE00262].case_value, 0)
		+ ISNULL([VE00266].case_value, 0)+ ISNULL([VE00270].case_value, 0)+ ISNULL([VE00274].case_value, 0)+ ISNULL([VE00282].case_value, 0)
		+ ISNULL([VE00286].case_value, 0)+ ISNULL([VE00291].case_value, 0)+ ISNULL([VE00295].case_value, 0)+ ISNULL([VE00299].case_value, 0)
		+ ISNULL([VE00340].case_value, 0)+ ISNULL([VE00344].case_value, 0)+ ISNULL([VE00348].case_value, 0)+ ISNULL([VE00352].case_value, 0)
		+ ISNULL([VE00383].case_value, 0)+ ISNULL([VE00387].case_value, 0)+ ISNULL([VE00391].case_value, 0)+ ISNULL([VE00395].case_value, 0)
		+ ISNULL([VE00399].case_value, 0)+ ISNULL([VE00403].case_value, 0)+ ISNULL([VE00407].case_value, 0)+ ISNULL([VE00411].case_value, 0)
		+ ISNULL([VE00416].case_value, 0)+ ISNULL([VE00420].case_value, 0)+ ISNULL([VE00424].case_value, 0)
		+ ISNULL([VE00428].case_value, 0) AS TotalInsurerReserveIncFees,
		0 + ISNULL([VE00166].case_value, 0)+ ISNULL([VE00174].case_value, 0)+ ISNULL([VE00178].case_value, 0)+ ISNULL([VE00182].case_value, 0)
		+ ISNULL([VE00186].case_value, 0)+ ISNULL([VE00190].case_value, 0)+ ISNULL([VE00194].case_value, 0)+ ISNULL([VE00198].case_value, 0)
		+ ISNULL([VE00202].case_value, 0)+ ISNULL([VE00206].case_value, 0)+ ISNULL([VE00210].case_value, 0)+ ISNULL([VE00214].case_value, 0)
		+ ISNULL([VE00218].case_value, 0)+ ISNULL([VE00222].case_value, 0)+ ISNULL([VE00226].case_value, 0)+ ISNULL([VE00230].case_value, 0)
		+ ISNULL([VE00234].case_value, 0)+ ISNULL([VE00238].case_value, 0)+ ISNULL([VE00242].case_value, 0)+ ISNULL([VE00246].case_value, 0)
		+ ISNULL([VE00250].case_value, 0)+ ISNULL([VE00254].case_value, 0)+ ISNULL([VE00258].case_value, 0)+ ISNULL([VE00262].case_value, 0)
		+ ISNULL([VE00266].case_value, 0)+ ISNULL([VE00270].case_value, 0)+ ISNULL([VE00274].case_value, 0)+ ISNULL([VE00282].case_value, 0)
		+ ISNULL([VE00286].case_value, 0)+ ISNULL([VE00291].case_value, 0)+ ISNULL([VE00295].case_value, 0)+ ISNULL([VE00299].case_value, 0)
		+ ISNULL([VE00340].case_value, 0)+ ISNULL([VE00344].case_value, 0)+ ISNULL([VE00348].case_value, 0)+ ISNULL([VE00352].case_value, 0)
		+ ISNULL([VE00399].case_value, 0)+ ISNULL([VE00403].case_value, 0)+ ISNULL([VE00407].case_value, 0)+ ISNULL([VE00411].case_value, 0)
		+ ISNULL([VE00416].case_value, 0)+ ISNULL([VE00420].case_value, 0)+ ISNULL([VE00424].case_value, 0)
		+ ISNULL([VE00428].case_value, 0) AS TotalInsurerReserveExcFees
	FROM axxia01.dbo.cashdr
	LEFT JOIN axxia01.dbo.casdet AS VE00166 ON axxia01.dbo.cashdr.case_id = VE00166.case_id AND VE00166.case_detail_code = 'VE00166'
	LEFT JOIN axxia01.dbo.casdet AS VE00174 ON axxia01.dbo.cashdr.case_id = VE00174.case_id AND VE00174.case_detail_code = 'VE00174'
	LEFT JOIN axxia01.dbo.casdet AS VE00178 ON axxia01.dbo.cashdr.case_id = VE00178.case_id AND VE00178.case_detail_code = 'VE00178'
	LEFT JOIN axxia01.dbo.casdet AS VE00182 ON axxia01.dbo.cashdr.case_id = VE00182.case_id AND VE00182.case_detail_code = 'VE00182'
	LEFT JOIN axxia01.dbo.casdet AS VE00186 ON axxia01.dbo.cashdr.case_id = VE00186.case_id AND VE00186.case_detail_code = 'VE00186'
	LEFT JOIN axxia01.dbo.casdet AS VE00190 ON axxia01.dbo.cashdr.case_id = VE00190.case_id AND VE00190.case_detail_code = 'VE00190'
	LEFT JOIN axxia01.dbo.casdet AS VE00194 ON axxia01.dbo.cashdr.case_id = VE00194.case_id AND VE00194.case_detail_code = 'VE00194'
	LEFT JOIN axxia01.dbo.casdet AS VE00198 ON axxia01.dbo.cashdr.case_id = VE00198.case_id AND VE00198.case_detail_code = 'VE00198'
	LEFT JOIN axxia01.dbo.casdet AS VE00202 ON axxia01.dbo.cashdr.case_id = VE00202.case_id AND VE00202.case_detail_code = 'VE00202'
	LEFT JOIN axxia01.dbo.casdet AS VE00206 ON axxia01.dbo.cashdr.case_id = VE00206.case_id AND VE00206.case_detail_code = 'VE00206'
	LEFT JOIN axxia01.dbo.casdet AS VE00210 ON axxia01.dbo.cashdr.case_id = VE00210.case_id AND VE00210.case_detail_code = 'VE00210'
	LEFT JOIN axxia01.dbo.casdet AS VE00214 ON axxia01.dbo.cashdr.case_id = VE00214.case_id AND VE00214.case_detail_code = 'VE00214'
	LEFT JOIN axxia01.dbo.casdet AS VE00218 ON axxia01.dbo.cashdr.case_id = VE00218.case_id AND VE00218.case_detail_code = 'VE00218'
	LEFT JOIN axxia01.dbo.casdet AS VE00222 ON axxia01.dbo.cashdr.case_id = VE00222.case_id AND VE00222.case_detail_code = 'VE00222'
	LEFT JOIN axxia01.dbo.casdet AS VE00226 ON axxia01.dbo.cashdr.case_id = VE00226.case_id AND VE00226.case_detail_code = 'VE00226'
	LEFT JOIN axxia01.dbo.casdet AS VE00230 ON axxia01.dbo.cashdr.case_id = VE00230.case_id AND VE00230.case_detail_code = 'VE00230'
	LEFT JOIN axxia01.dbo.casdet AS VE00234 ON axxia01.dbo.cashdr.case_id = VE00234.case_id AND VE00234.case_detail_code = 'VE00234'
	LEFT JOIN axxia01.dbo.casdet AS VE00238 ON axxia01.dbo.cashdr.case_id = VE00238.case_id AND VE00238.case_detail_code = 'VE00238'
	LEFT JOIN axxia01.dbo.casdet AS VE00242 ON axxia01.dbo.cashdr.case_id = VE00242.case_id AND VE00242.case_detail_code = 'VE00242'
	LEFT JOIN axxia01.dbo.casdet AS VE00246 ON axxia01.dbo.cashdr.case_id = VE00246.case_id AND VE00246.case_detail_code = 'VE00246'
	LEFT JOIN axxia01.dbo.casdet AS VE00250 ON axxia01.dbo.cashdr.case_id = VE00250.case_id AND VE00250.case_detail_code = 'VE00250'
	LEFT JOIN axxia01.dbo.casdet AS VE00254 ON axxia01.dbo.cashdr.case_id = VE00254.case_id AND VE00254.case_detail_code = 'VE00254'
	LEFT JOIN axxia01.dbo.casdet AS VE00258 ON axxia01.dbo.cashdr.case_id = VE00258.case_id AND VE00258.case_detail_code = 'VE00258'
	LEFT JOIN axxia01.dbo.casdet AS VE00262 ON axxia01.dbo.cashdr.case_id = VE00262.case_id AND VE00262.case_detail_code = 'VE00262'
	LEFT JOIN axxia01.dbo.casdet AS VE00266 ON axxia01.dbo.cashdr.case_id = VE00266.case_id AND VE00266.case_detail_code = 'VE00266'
	LEFT JOIN axxia01.dbo.casdet AS VE00270 ON axxia01.dbo.cashdr.case_id = VE00270.case_id AND VE00270.case_detail_code = 'VE00270'
	LEFT JOIN axxia01.dbo.casdet AS VE00274 ON axxia01.dbo.cashdr.case_id = VE00274.case_id AND VE00274.case_detail_code = 'VE00274'
	LEFT JOIN axxia01.dbo.casdet AS VE00282 ON axxia01.dbo.cashdr.case_id = VE00282.case_id AND VE00282.case_detail_code = 'VE00282'
	LEFT JOIN axxia01.dbo.casdet AS VE00286 ON axxia01.dbo.cashdr.case_id = VE00286.case_id AND VE00286.case_detail_code = 'VE00286'
	LEFT JOIN axxia01.dbo.casdet AS VE00291 ON axxia01.dbo.cashdr.case_id = VE00291.case_id AND VE00291.case_detail_code = 'VE00291'
	LEFT JOIN axxia01.dbo.casdet AS VE00295 ON axxia01.dbo.cashdr.case_id = VE00295.case_id AND VE00295.case_detail_code = 'VE00295'
	LEFT JOIN axxia01.dbo.casdet AS VE00299 ON axxia01.dbo.cashdr.case_id = VE00299.case_id AND VE00299.case_detail_code = 'VE00299'
	LEFT JOIN axxia01.dbo.casdet AS VE00340 ON axxia01.dbo.cashdr.case_id = VE00340.case_id AND VE00340.case_detail_code = 'VE00340'
	LEFT JOIN axxia01.dbo.casdet AS VE00344 ON axxia01.dbo.cashdr.case_id = VE00344.case_id AND VE00344.case_detail_code = 'VE00344'
	LEFT JOIN axxia01.dbo.casdet AS VE00348 ON axxia01.dbo.cashdr.case_id = VE00348.case_id AND VE00348.case_detail_code = 'VE00348'
	LEFT JOIN axxia01.dbo.casdet AS VE00352 ON axxia01.dbo.cashdr.case_id = VE00352.case_id AND VE00352.case_detail_code = 'VE00352'
	LEFT JOIN axxia01.dbo.casdet AS VE00383 ON axxia01.dbo.cashdr.case_id = VE00383.case_id AND VE00383.case_detail_code = 'VE00383'
	LEFT JOIN axxia01.dbo.casdet AS VE00387 ON axxia01.dbo.cashdr.case_id = VE00387.case_id AND VE00387.case_detail_code = 'VE00387'
	LEFT JOIN axxia01.dbo.casdet AS VE00391 ON axxia01.dbo.cashdr.case_id = VE00391.case_id AND VE00391.case_detail_code = 'VE00391'
	LEFT JOIN axxia01.dbo.casdet AS VE00395 ON axxia01.dbo.cashdr.case_id = VE00395.case_id AND VE00395.case_detail_code = 'VE00395'
	LEFT JOIN axxia01.dbo.casdet AS VE00399 ON axxia01.dbo.cashdr.case_id = VE00399.case_id AND VE00399.case_detail_code = 'VE00399'
	LEFT JOIN axxia01.dbo.casdet AS VE00403 ON axxia01.dbo.cashdr.case_id = VE00403.case_id AND VE00403.case_detail_code = 'VE00403'
	LEFT JOIN axxia01.dbo.casdet AS VE00407 ON axxia01.dbo.cashdr.case_id = VE00407.case_id AND VE00407.case_detail_code = 'VE00407'
	LEFT JOIN axxia01.dbo.casdet AS VE00411 ON axxia01.dbo.cashdr.case_id = VE00411.case_id AND VE00411.case_detail_code = 'VE00411'
	LEFT JOIN axxia01.dbo.casdet AS VE00416 ON axxia01.dbo.cashdr.case_id = VE00416.case_id AND VE00416.case_detail_code = 'VE00416'
	LEFT JOIN axxia01.dbo.casdet AS VE00420 ON axxia01.dbo.cashdr.case_id = VE00420.case_id AND VE00420.case_detail_code = 'VE00420'
	LEFT JOIN axxia01.dbo.casdet AS VE00424 ON axxia01.dbo.cashdr.case_id = VE00424.case_id AND VE00424.case_detail_code = 'VE00424'
	LEFT JOIN axxia01.dbo.casdet AS VE00428 ON axxia01.dbo.cashdr.case_id = VE00428.case_id AND VE00428.case_detail_code = 'VE00428'
	WHERE cashdr.case_id = @CaseID

	RETURN
END
GO
