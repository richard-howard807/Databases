SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


Create VIEW [dbo].[RMLetBreakDates]
AS
SELECT TOP (100) PERCENT
    MainDetails.case_id,
    CAST(MainDetails.TitleNumber AS VARCHAR(10)) AS Expr1,
    CASE
        WHEN PRO1109.case_text = 'Fixed date' THEN
            PRO1112.case_date
        WHEN PRO1109.case_text = 'Rolling'
             AND GETDATE() < PRO1110.case_date THEN
            PRO1110.case_date
        WHEN PRO1109.case_text = 'Rolling'
             AND GETDATE() > PRO1110.case_date THEN
    (CASE
         WHEN PRO1113.case_text = 'Month(s)' THEN
             DATEADD(MONTH, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Year(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Week(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Day(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Quarter(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
     END
    )
        WHEN PRO1109.case_text = 'Both' THEN
            CASE
                WHEN PRO1112.case_date < (CASE
                                              WHEN PRO1109.case_text = 'Fixed date' THEN
                                                  PRO1112.case_date
                                              WHEN PRO1109.case_text = 'Rolling'
                                                   AND GETDATE() < PRO1110.case_date THEN
                                                  PRO1110.case_date
                                              WHEN PRO1109.case_text = 'Rolling'
                                                   AND GETDATE() > PRO1110.case_date THEN
    (CASE
         WHEN PRO1113.case_text = 'Month(s)' THEN
             DATEADD(MONTH, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Year(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Week(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Day(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Quarter(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
     END
    )
                                          END
                                         ) THEN
                    PRO1112.case_date
                ELSE
    (CASE
         WHEN PRO1113.case_text = 'Month(s)' THEN
             DATEADD(MONTH, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Year(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Week(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Day(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
         WHEN PRO1113.case_text = 'Quarter(s)' THEN
             DATEADD(YEAR, PRO1113.case_value, PRO1110.case_date)
     END
    )
            END
    END AS LandlordBreak,
    CASE
        WHEN PRO1118.case_text = 'Fixed date' THEN
            PRO1121.case_date
        WHEN PRO1118.case_text = 'Rolling'
             AND GETDATE() < PRO1119.case_date THEN
            PRO1119.case_date
        WHEN PRO1118.case_text = 'Rolling'
             AND GETDATE() > PRO1119.case_date THEN
    (CASE
         WHEN PRO1122.case_text = 'Month(s)' THEN
             DATEADD(MONTH, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Year(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Week(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Day(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Quarter(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
     END
    )
        WHEN PRO1118.case_text = 'Both' THEN
            CASE
                WHEN PRO1121.case_date < (CASE
                                              WHEN PRO1118.case_text = 'Fixed date' THEN
                                                  PRO1121.case_date
                                              WHEN PRO1118.case_text = 'Rolling'
                                                   AND GETDATE() < PRO1119.case_date THEN
                                                  PRO1119.case_date
                                              WHEN PRO1118.case_text = 'Rolling'
                                                   AND GETDATE() > PRO1119.case_date THEN
    (CASE
         WHEN PRO1122.case_text = 'Month(s)' THEN
             DATEADD(MONTH, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Year(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Week(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Day(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Quarter(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
     END
    )
                                          END
                                         ) THEN
                    PRO1121.case_date
                ELSE
    (CASE
         WHEN PRO1122.case_text = 'Month(s)' THEN
             DATEADD(MONTH, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Year(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Week(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Day(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
         WHEN PRO1122.case_text = 'Quarter(s)' THEN
             DATEADD(YEAR, PRO1122.case_value, PRO1119.case_date)
     END
    )
            END
    END AS TenantBreak
FROM
(
    SELECT casdet.case_id,
           casdet.case_text AS TitleNumber,
           casdet.seq_no
    FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet
        INNER JOIN red_dw.dbo.ds_sh_axxia_cashdr AS cashdr
            ON casdet.case_id = cashdr.case_id
               AND cashdr.current_flag = 'Y'
			  
    WHERE (casdet.case_detail_code = 'PRO840')
          AND (cashdr.client = 'P00016')
          AND (casdet.case_text IS NOT NULL)
          AND casdet.current_flag = 'Y'
) AS MainDetails
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_8
        WHERE (case_detail_code = 'PRO1109') AND casdet_8.current_flag = 'Y'
    ) AS PRO1109
        ON MainDetails.case_id = PRO1109.case_id
           AND MainDetails.seq_no = PRO1109.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_7
        WHERE (case_detail_code = 'PRO1112') AND casdet_7.current_flag = 'Y'
    ) AS PRO1112
        ON MainDetails.case_id = PRO1112.case_id
           AND MainDetails.seq_no = PRO1112.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_6
        WHERE (case_detail_code = 'PRO1113') AND casdet_6.current_flag = 'Y'
    ) AS PRO1113
        ON MainDetails.case_id = PRO1113.case_id
           AND MainDetails.seq_no = PRO1113.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_5
        WHERE (case_detail_code = 'PRO1110') AND casdet_5.current_flag = 'Y'
    ) AS PRO1110
        ON MainDetails.case_id = PRO1110.case_id
           AND MainDetails.seq_no = PRO1110.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_4
        WHERE (case_detail_code = 'PRO1118') AND casdet_4.current_flag = 'Y'
    ) AS PRO1118
        ON MainDetails.case_id = PRO1118.case_id
           AND MainDetails.seq_no = PRO1118.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_3
        WHERE (case_detail_code = 'PRO1121') AND casdet_3.current_flag = 'Y'
    ) AS PRO1121
        ON MainDetails.case_id = PRO1121.case_id
           AND MainDetails.seq_no = PRO1121.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_2
        WHERE (case_detail_code = 'PRO1122') AND casdet_2.current_flag = 'Y'
    ) AS PRO1122
        ON MainDetails.case_id = PRO1122.case_id
           AND MainDetails.seq_no = PRO1122.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_1
        WHERE (case_detail_code = 'PRO1119') AND casdet_1.current_flag = 'Y'
    ) AS PRO1119
        ON MainDetails.case_id = PRO1119.case_id
           AND MainDetails.seq_no = PRO1119.cd_parent
ORDER BY MainDetails.case_id;

GO
