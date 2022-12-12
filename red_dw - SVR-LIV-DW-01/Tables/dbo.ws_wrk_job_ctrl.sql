CREATE TABLE [dbo].[ws_wrk_job_ctrl]
(
[wjc_job_key] [int] NOT NULL,
[wjc_name] [varchar] (64) COLLATE Latin1_General_BIN NULL,
[wjc_description] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[wjc_sequence] [int] NULL,
[wjc_group_key] [int] NULL,
[wjc_project_key] [int] NULL,
[wjc_status] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[wjc_last_status] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[wjc_type] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[wjc_submitted] [datetime] NULL,
[wjc_first_schedule] [datetime] NULL,
[wjc_start_hour] [int] NULL,
[wjc_start_minute] [int] NULL,
[wjc_start_day] [int] NULL,
[wjc_user_key] [int] NULL,
[wjc_start_after] [datetime] NULL,
[wjc_started] [datetime] NULL,
[wjc_completed] [datetime] NULL,
[wjc_max_elapsed] [int] NULL,
[wjc_task_elapsed] [int] NULL,
[wjc_avg_elapsed] [int] NULL,
[wjc_avg_count] [int] NULL,
[wjc_publish_okay] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[wjc_publish_fail] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[wjc_task_fatal] [int] NULL,
[wjc_task_error] [int] NULL,
[wjc_task_warning] [int] NULL,
[wjc_task_info] [int] NULL,
[wjc_task_okay] [int] NULL,
[wjc_chkp_count] [int] NULL,
[wjc_max_threads] [int] NULL,
[wjc_priority] [int] NULL,
[wjc_publish_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[wjc_scheduler] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[wjc_cust_sa_hh] [int] NULL,
[wjc_cust_sa_mm] [int] NULL,
[wjc_cust_sb_hh] [int] NULL,
[wjc_cust_sb_mm] [int] NULL,
[wjc_cust_min] [int] NULL,
[wjc_cust_days] [int] NULL,
[wjc_warn_act_ind] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[wjc_publish_warn] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[wjc_run_userid] [varchar] (64) COLLATE Latin1_General_BIN NULL,
[wjc_run_pwd] [varchar] (24) COLLATE Latin1_General_BIN NULL,
[wjc_doc_1] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_2] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_3] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_4] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_5] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_6] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_7] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_8] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_9] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_10] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_11] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_12] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_13] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_14] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_15] [text] COLLATE Latin1_General_BIN NULL,
[wjc_doc_16] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute1] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute2] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute3] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute4] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute5] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute6] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute7] [text] COLLATE Latin1_General_BIN NULL,
[wjc_attribute8] [text] COLLATE Latin1_General_BIN NULL,
[wjc_idle_thread_wait] [int] NULL
) ON [DW_META]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[job_failure_alert] 

ON [dbo].[ws_wrk_job_ctrl] FOR UPDATE

AS

declare	@UpdatedValue varchar(1) = (select top 1 wjc_last_status from inserted)

-- trigger if status is updated
IF UPDATE(wjc_last_status)

BEGIN TRY
	
	/*
	20190821 - RH: Red job failure alert

		1) Get details of failed job
		2) Release job again is failure was caused by deadlock
		3) Send failure email

	*/
	IF @UpdatedValue = 'F'

		BEGIN
        
			/*
			1) Job Details
			*/
			
			declare @msg nvarchar(max)
			declare @Subj varchar(200) = 'ALERT - Red Job Failure' 
			declare @jobid int
			declare @task_name varchar(64)
			declare @error_message varchar(1024)
			declare @job_name varchar(64)
			declare @is_deadlock bit
			declare @reran int = 0
			declare @istestjob bit 

			select top 1
				@job_name = isnull(job.wjc_name, '')
				,@jobid = job.wjc_job_key
				,@task_name = isnull(task.wtr_name,'')
				,@error_message = isnull(task.wtr_return_msg,'')
				,@is_deadlock = iif(task.wtr_return_msg like '%deadlock%' or task.wtr_return_msg like '%Deadlock%' or task.wtr_return_msg LIKE '%TCP Provider: An existing connection was forcibly closed by the remote host%', 1, 0)	
				,@istestjob = iif(task.wtr_name like '%Test%' or task.wtr_name like '%test%', 1, 0)
				-- select top 1 *		
			from dbo.ws_wrk_task_run task
				inner join dbo.ws_wrk_job_ctrl job
					on task.wtr_job_key = job.wjc_job_key
			where task.wtr_run_status = 'F'and job.wjc_last_status = 'F'

			-- Ignore any job with test in name
			IF @istestjob = 0

				BEGIN
					/*
					2) Release job if deadlock error
					*/
			
					IF @is_deadlock = 1

						BEGIN

							-- Check job has not failed more than once in quick succession.

							if (select count(al.wa_task)
							-- select *
								from dbo.ws_wrk_audit_log al
								where al.wa_db_msg_code is not null 
								and al.wa_db_msg_code <> '' 
								and al.wa_time_stamp > dateadd(minute, -5, getdate())
								and al.wa_job_key = @jobid and al.wa_task = @task_name
								) < 2
							
									begin

										-- EXEC Ws_Job_Restart
								
										DECLARE @p_sequence integer

											declare @p_job_name varchar(256);
											declare @p_task_name varchar(256);
											declare @p_job_id integer;
											declare @p_task_id integer;
											declare @p_return_msg varchar(256);
											declare @p_status integer;
											declare @v_result_num integer;
											declare @v_return_code varchar(1);
											declare @v_return_msg varchar(256);
											declare @return_result varchar(1)

											exec Ws_Job_Restart @p_sequence
															  , @p_job_name
															  , @p_task_name
															  , @p_job_id
															  , @p_task_id
															  , @job_name
															  , @v_return_code output
															  , @v_return_msg output
															  , @v_result_num output;

													
										SET @reran = @v_result_num
								
									END

						END
						

						/*
						3) Build & Send Email
						*/

						SELECT @msg =
							'The job ' + @job_name + ' failed at ' + CONVERT(VARCHAR(8), GETDATE(), 108)
							+ ' on ' + @@servername + '<br> <br> ' +

							'Task: ' + @task_name + ' <br> ' +
							'Error: ' + @error_message  + ' <br> <br> ' +
							'Action Taken: ' + CASE WHEN @reran = 1 THEN 'Job restarted automatically.'
											        WHEN @reran < 0 THEN 'Could not automatically restart job, manually restart.'
													WHEN @reran = 0 THEN 'None taken, manually review.' END				
							;
				
						
						-- Send Email			
					EXEC msdb.dbo.sp_send_dbmail 
						  @importance = 'High'
						--, @recipients = 'Richard.howard@weightmans.com'
						, @recipients = 'DWAlerts@weightmans.com;DBAAlerts@weightmans.com'
						, @body = @msg
						, @subject = @Subj
						, @body_format = 'HTML'
						, @profile_name = 'DBMail'
			
				END		
							
		END	
	
END TRY

BEGIN CATCH

	EXEC msdb.dbo.sp_send_dbmail 
						  @importance = 'High'
						, @recipients = 'Richard.howard@weightmans.com'						
						, @body = 'Error sending Red job failiure email'
						, @subject = 'Error sending Red job failiure email'
						, @body_format = 'HTML'
						, @profile_name = 'DBMail'

END CATCH



GO
ALTER TABLE [dbo].[ws_wrk_job_ctrl] ADD CONSTRAINT [ws_wjc_key_job] PRIMARY KEY CLUSTERED ([wjc_job_key]) ON [DW_META]
GO
ALTER TABLE [dbo].[ws_wrk_job_ctrl] ADD CONSTRAINT [ws_wjc_key_name] UNIQUE NONCLUSTERED ([wjc_name]) ON [DW_META]
GO
GRANT SELECT ON  [dbo].[ws_wrk_job_ctrl] TO [DBDenySelect]
GO
DENY SELECT ON  [dbo].[ws_wrk_job_ctrl] TO [lnksvrdatareader]
GO
DENY SELECT ON  [dbo].[ws_wrk_job_ctrl] TO [lnksvrdatareader_artdb]
GO
DENY SELECT ON  [dbo].[ws_wrk_job_ctrl] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO
GRANT DELETE ON  [dbo].[ws_wrk_job_ctrl] TO [SBC\SQL - LIVE DWH Developers Limited]
GO
GRANT INSERT ON  [dbo].[ws_wrk_job_ctrl] TO [SBC\SQL - LIVE DWH Developers Limited]
GO
GRANT SELECT ON  [dbo].[ws_wrk_job_ctrl] TO [SBC\SQL - LIVE DWH Developers Limited]
GO
GRANT UPDATE ON  [dbo].[ws_wrk_job_ctrl] TO [SBC\SQL - LIVE DWH Developers Limited]
GO
