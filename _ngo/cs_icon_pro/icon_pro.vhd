-------------------------------------------------------------------------------
-- Copyright (c) 2021 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : icon_pro.vhd
-- /___/   /\     Timestamp  : Sat Apr 24 16:49:39 中国标准时间 2021
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY icon_pro IS
  port (
    CONTROL0: inout std_logic_vector(35 downto 0));
END icon_pro;

ARCHITECTURE icon_pro_a OF icon_pro IS
BEGIN

END icon_pro_a;
