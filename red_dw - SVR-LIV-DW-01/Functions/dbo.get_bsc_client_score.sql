SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==============================================================================
-- DBMS Name       :     SQL Server
-- Script Name     :     get_bsc_client_score
-- Description     :     Generated
  -- Generated by   :    WhereScape RED Version 6.6.3.0 (build 121012)
-- Generated for   :     Weightmans
-- Author          :     Graeme Boag
-- ==============================================================================
-- Notes / History
-- 21/05/2015 Graeme Boag  Function to derive the BSC Client Score

-- DROP FUNCTION [dbo].[get_bsc_client_score] -- Will need to be dropped before it will compile in RED


CREATE FUNCTION [dbo].[get_bsc_client_score]
(
 @p_score_text         varchar(50),
 @p_partner_flag       int,
 @p_maternity_flag     int,
 @p_trainee_flag       int
) RETURNS decimal(5,2)
AS
BEGIN


  --===============================================================
  -- Control variables used in most programs
  --===============================================================
  DECLARE
  @v_score    decimal(5,2) -- RETURN value

  SET @v_score= NULL

  SET @v_score =
    CASE WHEN @p_score_text = '1.Green'
	  THEN 3
       WHEN @p_score_text = '2.Amber'
        THEN 1.5
       WHEN @p_score_text = '3.Red'
	  THEN 0
	 WHEN (@p_score_text = '4.N/A' OR @p_partner_flag = 1 OR @p_maternity_flag = 1 OR @p_trainee_flag = 1)
	  THEN -1
       ELSE 0
    END

   RETURN @v_score


END
GO
