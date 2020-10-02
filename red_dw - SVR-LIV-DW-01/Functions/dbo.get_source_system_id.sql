SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==============================================================================
-- DBMS Name       :     SQL Server
-- Script Name     :     get_source_system_id
-- Description     :     Generated
  -- Generated by   :    WhereScape RED Version 6.6.3.0 (build 121012)
-- Generated for   :     Weightmans
-- Author          :     Richard Varfoldi
-- ==============================================================================
-- Notes / History
--

CREATE FUNCTION [dbo].[get_source_system_id]
(
 @p_source_system_name         varchar(50)
) RETURNS integer
AS
BEGIN


  --===============================================================
  -- Control variables used in most programs
  --===============================================================
  DECLARE
  @v_source_system_id     integer -- RETURN value

  SET @v_source_system_id= NULL

  BEGIN


  SELECT @v_source_system_id = source_system_id
    FROM ds_mds_dw_source_system
   WHERE source_system_name=@p_source_system_name

   END

RETURN @v_source_system_id

END

GO
