#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# 

echo "This script was generated under a different operating system."
echo "Please update the PATH and LD_LIBRARY_PATH variables below, before executing this script"
exit

if [ -z "$PATH" ]; then
  PATH=C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vitis/2022.2/bin;C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/ids_lite/ISE/bin/nt64;C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/ids_lite/ISE/lib/nt64:C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/bin
else
  PATH=C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vitis/2022.2/bin;C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/ids_lite/ISE/bin/nt64;C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/ids_lite/ISE/lib/nt64:C:/Users/cosmo/Desktop/vivad/Xilinx_Windows_Unpacked_2022_2/Vivado/2022.2/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='C:/Users/cosmo/VivadoProjects/CourseLab/CourseLab.runs/synth_uart'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log kuz_uart_top.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source kuz_uart_top.tcl
