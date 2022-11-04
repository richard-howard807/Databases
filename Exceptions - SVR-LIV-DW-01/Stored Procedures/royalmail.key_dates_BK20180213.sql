SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 10/11/2017
-- Description:	Get List of Keydates using the view tasks_union
-- =============================================
CREATE PROCEDURE [royalmail].[key_dates_BK20180213]
	
AS


SELECT  
a.client_code
,a.matter_number
,CONVERT(VARCHAR(12),a.task_due_date,103) + ' ' +REPLACE(REPLACE(REPLACE(REPLACE(RTRIM(a.task_desc),'REM: ',''),' - [CASE MAN]',''), '[CM]',''),' [CASE MAN]','') [Category]
,a.task_due_date



FROM dbo.tasks_union a
INNER JOIN red_dw.dbo.dim_client client ON client.client_code = a.client_code COLLATE Latin1_General_CI_AS
--INNER JOIN  (	SELECT client_code
--					,matter_number
--					,MIN(task_due_date) due_date
--				FROM dbo.tasks_union 
--				WHERE client_code IN ('P00010','P00011','P00012','P00020','P00021','P00022','W15762','R1001')
--				GROUP BY client_code
--				,matter_number) next_task ON next_task.client_code = a.client_code AND next_task.matter_number = a.matter_number AND next_task.due_date = a.task_due_date


WHERE a.client_code IN ('P00010','P00011','P00012','P00020','P00021','P00022','W15762','R1001')
AND a.task_desc  LIKE 'REM:%'
AND a.task_code IN ( 'KEYDATE'
,'NHSA0298','COLA0147','SKEA0281','MOTA0119','SKEA0291','SKEA0192'
,'PSRA0170','FTRA0127','PROA2093','SKEA0183','NHSA0131','RECA0417'
,'TRAA0189','NHSA0274','TRAA0417','FAMA0157','EMPA0414','EMPA0124'
,'COLA0169','TRAA0401','GENA0124','EMPA0406','LLSA0107','EMPA0427'
,'NHSA0206','EMPA0360','NHSA0231','SKEA0101','SKEA0135','NHSA0703'
,'EMPA0139','NHSA0257','FAMA0172','RISA0207','EMPA1763','WPSA0257'
,'WPSA0275','REGA0286','SKEA0245','NHSA0248','SKEA0120','WPSA0259'
,'COSA0173','EMPA0336','COLA0178','WPSA0284','FTRA9918','FTRA2617'
,'COLA0232','EMPA0399','NHSA0320','EMPA0340','PROA2088','NHSA0326'
,'RMXA0114','COLA0138','FTRA0132','EMPA1725','NHSA0301','COSA0124'
,'WPSA0141','PROA0316','NHSA0289','EMPA0346','MOTA0208','PROA0177'
,'COLA0186','RISA0216','FTRA2632','FTRA9816','WPSA0248','EMPA0110'
,'TRAA0178','POLA0169','WPSA0125','NHSA0311','TRAA0384','TRAA0422'
,'FTRA2635','TRAA0449','TRAA0303','MOTA0203','TRAA0190','INJA0112'
,'REGA0228','TRAA0392','WPSA0220','FTRA0122','EMPA0411','WPSA0260'
,'NHSA0295','RISA0210','COSA0165','EMPA0193','EMPA0337','FTRA9821'
,'NHSA0642','REGA0222','NHSA0360','REGA0289','FTRA2620','EMPA0163'
,'COLA0142','SKEA0263','COSA0104','NHSA0256','WPSA0254','REGA0283'
,'EMPA0351','PSRA0173','COLA0160','NHSA0113','EMPA0424','FAMA0169'
,'POLA0112','NHSA0304','SKEA0237','EMPA1720','NHSA0323','WPSA0256'
,'GENA0142','REGA0146','SKEA0191','INJA0313','EMPA0444','PROA0141'
,'FTRA9808','SKEA0225','PROA2434','SKEA0200','EMPA0204','EMPA0343'
,'EMPA0183','POLA0157','REGA0281','COSA0299','SKEA0125','WPSA0287','RISA0213','COSA0177','SKEA0216','LLSA0122','NHSA0265','NHSA0280','NHSA0284','TRAA0398','RISA0118','NHSA0107','NHSA0245','TRAA0184','SKEA0123','NHSA0302','SKEA0180','EMPA0412','TRAA0175','NHSA0286','COLA0222','TRAA0314','WPSA0245','FAMA0152','NHSA0370','SKEA0198','EMPA0429','EMPA0129','SKEA0164','NHSA0260','COLA0163','TRAA0423','SKEA0270','COSA0267','COLA0187','RISA0209','COLA0145','WPSA0239','PSRA0141','MOTA0115','NHSA0617','RISA0133','NHSA0296','REGA0253','SKEA0297','EMPA0432','EMPA0352','FTRA2623','PSRA0174','EMPA0421','SKEA0128','TRAA0308','SKEA0137','NHSA0630','FTRA2615','EMPA1757','NHSA0228','PIDA0169','NHSA0376','EMPA0168','POLA0142','WPSA0277','REGA0284','SKEA0272','MOTA0121','SKEA0147','NHSA0322','PROA2449','FTRA2629','EMPA0334','TRAA0315','COSA0175','FTRA2630','SKEA0219','COSA0257','NHSA0378','NHSA0328','POLA0164','SKEA0126','COLA0154','EMPA0342','PROA2455','PROA0167','NHSA0387','TRAA0399','FAMA0164','NHSA0316','NHSA0266','TRAA0327','SKEA0155','REGA0266','SKEA0254','PIDA0107','NHSA0281','NHSA0287','TRAA0325','WPSA0135','WPSA0184','POLA0133','WPSA0262','NHSA0293','COLA0168','SKEA0288','TRA03018','TRAA0414','EMPA0435','PSRA0177','COSA0251','NHSA0139','SKEA0182','PROA0106','PSRA0146','COSA0109','COSA0260','REGA0217','RECA0407','SKEA0102','RISA0204','SKEA0261','NHSA0379','POLA0105','EMPA0134','PROA0180','EMPA0441','FTRA2614','SKEA0273','NHSA0254','TRAA0348','TRAA0165','FTRA2626','GENA0144','COLA0247','SKEA0300','TRAA0430','NHSA0269','TRAA0322','PIDA0110','EMPA0442','PROA2103','EMPA0396','COLA0139','COLA0241','EMPA0345','TRAA0411','FAMA0114','POLA0167','SKEA0108','FTRA9905','LLSA0119','NHSA0369','POLA0138','NHS01043','TRAA0186','REGA0290','COLA0151','NHSA0127','COSA2051','TRAA0330','PROA2446','PID02003','WPSA0243','EMPA0394','NHSA0144','TRAA0177','REGA0263','COSA0179','COLA0226','PSRA0120','TRAA0345','COLA0172','EMPA0438','WPSA0168','COLA0141','TRAA0419','NHSA0278','NHSA0310','NHSA0242','SKEA0162','PSRA0131','NHSA0636','FAMA0119','WPSA0263','COSA0238','COLA0190','FAMA0134','POLA0170','PSRA0164','NHSA0624','LLSA0415','TRAA0407','NHSA0183','FTRA9803','NHSA0224','FTRA9908','FTRA2621','REGA0293','WPSA0225','WPSA0253','TRAA0393','TRAA0395','EMPA0408','NHSA0608','NHSA0272','FTRA2627','WPSA083 ','COLA0115','LLSA0417','COSA0119','NHSA0307','REGA0211','SKEA0234','NHSA0385','TRAA0410','TRAA0115','PROA2098','TRAA0172','SKEA0189','REGA0278','TRAA0420','COLA0240','WPSA0280','PROA2435','POLA0166','REGA0280','FAMA0166','EMPA0397','COLA0156','WPSA0244','SKEA0153','SKEA0174','NHSA0251','COSA0302','WPSA0286','RISA0212','SKEA0207','PROA0165','RECA0441','COLA0150','NHSA0149','REGA0268','COLA0223','COLA0121','NHSA0262','NHSA0268','TRAA0141','COSA0312','COSA0178','EMPA0355','PSRA0171','EMPA0188','COLA0146','SKEA0165','WPSA0250','EMPA0144','RISA0128','TRAA0342','SKEA0306','TRAA0426','EMPA0415','TRAA0416','FAMA0158','NHSA0250','WPSA0292','SKEA0282','POLA0158','REGA0296','NHSA0232','SKEA0129','REGA0287','TRA0136 ','RISA0206','PROA0182','FTRA2618','EMPA0173','TRAA0192','NHSA0178','LLSA0110','LLSA0414','PROA0170','PROA0440','EMPA0349','FTRA2624','EMPA0426','NHSA0648','TRAA0396','TRAA0404','FAMA0173','FTRA2612','SKEA0111','REGA0265','REGA0138','PSRA0169','SKEA0119','COLA0235','SKEA0144','COSA2047','COLA0159','NHSA0189','WPSA0283','SKEA0171','REGA0292','COSA0176','EMPA0149','PROA2437','SKEA0121','PROA2452','EMPA0418','EMPA0430','PROA0131','TRAA0169','COLA0231','NHSA0325','REGA0277','COLA0135','EMPA0357','SKEA0227','PROA0176','PROA0168','EMPA0158','COSA0169','NHSA0319','WPSA0241','WPSA0178','TRAA0180','TRAA0336','RISA0215','WPSA0159','WPSA0230','FAMA0109','PIDA0167','NHSA0237','EMPA0198','FAMA0144','EMPA0436','TRAA0425','SKEA0209','TRAA0413','NHSA0259','PROA0186','PSRA0176','PSRA0123','NHSA0154','COSA0297','RISA0123','PROA2457','NHSA0219','WPSA0251','NHSA0361','TRAA0339','POLA0155','WPSA0265','NHSA0308','FAMA0170','WPSA0150','SKEA0264','COLA0181','NHSA0253','TRAA0405','EMPA0348','EMPA0354','SKEA0110','EMPA0178','PROA0183','COLA0177','FAMA0129','SKEA0299','SKEA0243','REGA0295','LLSA0117','EMPA1006','TRAA0402','PSRA0162','RECA0412','NHSA0305','PROA2451','REGA0206','FAMA0155','SKEA0236','POLA0160','COSA0114','PROA0126','EMPA0358','SKEA0122','SKEA0124','TRAA0319','COSA0171','FAMA0160','FTRA9912','TRAA0311','SKEA0201','RECA0443','NHSA0314','PROA0185','NHSA0118','EMPA0209','SKEA0228','WPSA0235','MOTA0206','PROA0179','PROA0111','NHSA0244','NHSA0283','PROA2436','TRAA0187','SKEA0252','TRAA0156','RISA0218','COSA0300','EMPA0119','COSA0314','WPSA0145','RISA0104','EMPA0339','WPSA0247','POLA0128','TRAA0386','TRAA0428','FTRA2633','COSA0246','NHSA0317','NHSA0275','WPSA0130','NHSA0313','EMPA0417','NHSA0367','NHSA0167','WPSA0290','SKEA0290','GENA0119','PSRA0126','NHSA0299','COSA0272','WPSA0278','TRAA0408','COSA2053','SKEA0117','EMPA0420','SKEA0138','EMPA0433','PIDA0170','EMPA0409','NHSA0271','NHSA0277','TRAA0390','PSRA0136','REGA0133','POLA0147','PROA0438','REGA0298','EMPA0439','NHSA0121','FAMA0167','FAMA0175','SKEA0246','FAMA0124','PIDA0172','NHSA0708','POLA0172','PROA0121','LLSA0408','SKEA0127','SKEA0218','PROA2461','WPSA0281','INJA0315','SKEA0146','NHSA0247','FTRA9913','FAMA0161','NHSA0172','EMPA0423','SKEA0279','NHSA0263','REGA0275','COLA0155','PROA2448','LLSA0120','FTRA9915','PROA2454','FAMA0163','SKEA0156','FAMA0139','SKEA0173','PROA0174','COLA0133','SKEA0255','WPSA0120','PROA0188','COSA0167','WPSA0289','FAMA0154','PROA2339','SKEA0210')

                                            
ORDER BY a.task_due_date asc



GO