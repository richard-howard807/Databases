SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[NHSKeyDates]

AS 

BEGIN
IF OBJECT_ID(N'tempdb..#KeyDates') IS NOT NULL BEGIN DROP TABLE #KeyDates END

SELECT 
	header.master_client_code																AS [Client]
	, header.master_client_code + '.' + header.master_matter_number							AS [Matter Number]
	, header.matter_description																AS [Matter Description]
    , dbTasks.tskID																			AS [Task ID]
    , CAST([red_dw].[dbo].[datetimelocal](tskdue) AS DATE)									AS [Date Due]
    , ISNULL(a.activity_code, dbKeyDates.kdType)											AS [Task Code]
    , dbUser.usrFullName																	AS [Task Owner]
    , dbUser.usrAlias																		AS [Task Owner Code]
    , dbTasks.tskDesc																		AS [Key Date Reminder]
    , header.matter_owner_full_name															AS [Matter Owner]
    , fed.hierarchylevel4																	AS [Team]
	, a.activity_code
    , fed.hierarchylevel3																	AS [Department]
    , CASE
		WHEN dbKeyDates.kdRelatedID IS NULL THEN
			'Converted'
        ELSE
            'Mattersphere'
      END																					AS [Key Date Type]
    , CASE
		WHEN [red_dw].[dbo].[datetimelocal](tskdue) < CAST(GETDATE() AS DATE) THEN
			1
        ELSE
            0
      END
	  AS [Overdue]
	  INTO #KeyDates
FROM [MS_Prod].[dbo].[dbTasks] dbTasks
    INNER JOIN [MS_Prod].config.dbFile dbFile
        ON dbFile.fileID = dbTasks.fileID
    INNER JOIN red_dw.dbo.dim_matter_header_current header
        ON dbFile.fileID = header.ms_fileid
    LEFT JOIN red_dw.dbo.fact_dimension_main main
        ON main.dim_matter_header_curr_key = header.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history fed
        ON fed.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
    LEFT JOIN [MS_Prod].dbo.dbKeyDates dbKeyDates
        ON dbTasks.tskRelatedID = dbKeyDates.kdRelatedID
    LEFT JOIN [MS_Prod].dbo.dbUser dbUser
        ON dbUser.usrID = dbTasks.feeusrID
    LEFT JOIN [MS_Prod].dbo.dbTaskBridge dbTasksBridge
        ON dbTasksBridge.tskID = dbTasks.tskID
    LEFT JOIN axxia01.dbo.casact a
        ON dbTasksBridge.OriginatingSystemID COLLATE DATABASE_DEFAULT = a.case_id
           AND dbTasksBridge.OriginatingSequenceID = a.activity_seq
    LEFT JOIN axxia01.dbo.actlup b
        ON b.activity_code = a.activity_code COLLATE DATABASE_DEFAULT
WHERE tskType = 'KEYDATE'
AND header.master_client_code='N1001'
      AND
      (
          --CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskdue),103) BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
		 --AND CONVERT(DATE,EOMONTH(GETDATE()),103)
		 CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskdue),103) BETWEEN CONVERT(DATE,GETDATE(),103) AND   CONVERT(DATE,GETDATE()+14,103)
      )
      --  AND tskRelatedID IS NOT NULL -- exclude the manual tasks
      AND header.ms_only = 1 -- files are on MS only
      --AND dbTasksBridge.tskID IS NULL -- exclude converted tasks
      AND dbFile.fileClosed IS NULL -- only open file tasks
      AND dbTasks.tskActive = 1 -- exclude inactive tasks
      AND dbTasks.tskCompleted IS NULL
      AND dbTasks.tskComplete = 0
      AND header.reporting_exclusions = 0
	  AND ISNULL(dbKeyDates.kdType, '') <> 'REPORTCLIENT'
      AND ISNULL(LOWER(dbTasks.tskDesc), '') NOT LIKE '%tomorrow%'
	  AND ISNULL(LOWER(dbTasks.tskDesc), '') NOT LIKE '%[0-9] year%'
	  AND ISNULL(LOWER(dbTasks.tskDesc), '') NOT LIKE '%[0-9] month%'
	  AND ISNULL(LOWER(dbTasks.tskDesc), '') NOT LIKE '%[0-9] day%'
      AND ISNULL(LOWER(dbTasks.tskDesc), '') NOT LIKE '%weeks%'
      AND ISNULL(LOWER(dbTasks.tskDesc), '') NOT LIKE '%due 1d%'
      AND ISNULL(LOWER(dbTasks.tskDesc), '') NOT LIKE '%two days%'
	 AND ISNULL(a.activity_code,'') IN (
										'','NHSA0376','PSRA0146','PSRA0131','COLA0121','TRAA0315'
										,'WPSA0220','TRAA0115','WPSA0120','WPSA0178','EMPA0110'
										,'FTRA9808','TRA03018','PSRA0141','PIDA0107','TRAA0141'
										,'LLSA0414','LLSA0107','TRAA0319','NHSA0167','TRAA0392'
										,'COSA0267','SKEA0225','WPSA0141','NHSA0231','SKEA0252'
										,'LLSA0110','SKEA0288','EMPA1720','PSRA0120','TRAA0395'
										,'WPSA0159','TRAA0165','WPSA0184','MOTA0203','EMPA0129'
										,'TRAA0339','NHSA0624','POLA0138','NHSA0367','RMXA0114'
										,'POLA0128','SKEA0331','TRAA0311','PROA1133','NHSA0636'
										,'EMPA1757','REGA0146','FTRA0122','REGA0228','PROA0141'
										,'EMPA1725','EMPA0193','POLA0112','FTRA1791','REGA0222'
										,'TRAA0322','WPSA0145','REGA0217','PROA0316','COLA0235'
										,'COSA0322','PSRA0136','TRAA0325','SKEA0123','PROA2103'
										,'COLA0163','FTRA2687','REGA0133','WPSA0125','EMPA0119'
										,'RISA0104','NHSA0172','FTRA0127','WPSA0235','PROA2093'
										,'PROA0131','NHS01043','NHSA0237','SKEA0234','FTRA9908'
										,'NHSA0219','COLA0172','TRAA0303','PROA2339','FTRA1037'
										,'FTRA1034','RISA0133','COLA0247','SKEA0117','NHSA0206'
										,'RISA0118','TRAA0430','EMPA0168','NHSA0648','WPSA0130'
										,'TRAA0384','REGA0206','TRAA0386','SKEA0162','TRAA0327'
										,'TRAA0390','SKEA0261','COLA0181','PID02003','FTRA1031'
										,'TRAA0449','SKEA0306','EMPA0163','COSA0114','SKEA0189'
										,'COLA0226','NHSA0385','EMPA0139','EMPA0149','TRAA0393'
										,'GENA0119','EMPA0198','RECA0412','TRAA0169','FAMA0119'
										,'SKEA0321','PIDA0110','NHSA0224','NHSA0118','SKEA0153'
										,'FAMA0134','SKEA0135','COLA0115','EMPA1006','FTRA9816'
										,'NHSA0232','EMPA0124','FTRA0132','FTRA1025','PIDA0172'
										,'FAMA0139','PROA1139','PIDA0170','COSA0119','NHSA0107'
										,'SKEA0279','COSA0246','SKEA0216','POLA0133','FTRA1046'
										,'NHSA0149','NHSA0113','LLSA0408','SKEA0312','PROA2098'
										,'SKEA0326','PROA2461','COSA0251','EMPA1763','NHSA0642'
										,'SKEA0124','WPSA0150','COSA0109','SKEA0270','TRAA0172'
										,'SKEA0122','NHSA0630','INJA0112','RISA0123','PROA0126'
										,'NHSA0183','TRAA0342','RISA0128','COLA0190','SKEA0207'
										,'TRAA0330','NHSA0708','COSA0272','PROA0111','SKEA0127'
										,'WPSA0135','WPSA0230','NHSA0703','SKEA0316','NHSA0131'
										,'PROA2449','FAMA0114','TRAA0314','COLA0145','SKEA0144'
										,'TRAA0345','TRAA0336','FTRA9803','RECA0417','COSA0104'
										,'REGA0211','EMPA0158','PROA0106','PROA0121','FAMA0109'
										,'SKEA0108','WPSA0168','EMPA0188','TRAA0156','FTRA1028'
										,'EMPA0183','EMPA0178','COSA0260','REGA0138','NHSA0139'
										,'SKEA0320','EMPA0173','SKEA0171','POLA0147','COSA0257'
										,'NHSA0127','SKEA0126','POLA0105','POLA0142','PSRA0123'
										,'SKEA0180','PROA2451','COSA0124','MOTA0115','NHSA0144'
										,'NHSA0617','EMPA0209','SKEA0243','WPSA083','FTRA1040'
										,'REGA0253','FAMA0144','NHSA0387','TRAA0348','FTRA3258'
										,'FTRA0177','RECA0407','NHSA0121','NHSA0154','NHSA0228'
										,'FTRA1022','COSA2047','PSRA0126','NHSA0608','EMPA0134'
										,'EMPA0144','COLA0154','GENA0124','WPSA0155','PROA2088'
										,'EMPA0204','FAMA0124','FTRA9821','TRA0136 ','TRAA0308'
										,'FTRA0906'
										)




										SELECT [Matter Number],STRING_AGG(CAST(KeyDates.KeyDateMonth AS NVARCHAR(MAX)),'|') AS KeyDateMonth FROM 
										(SELECT [Matter Number],[Key Date Reminder] ,[Date Due],
										REPLACE([Key Date Reminder],' - today','')  + ' ' + CONVERT(VARCHAR, CAST([Date Due] AS DATETIME), 103)
										AS KeyDateMonth
										FROM #KeyDates
										) AS KeyDates
										GROUP BY [Matter Number]


										END
GO
