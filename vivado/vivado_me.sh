#!/bin/bash

function PrintUsage() {
 echo "-------------------------------------------------------------------"
 echo "----  Vivado script for DataNoC                               -----"
 echo "-------------------------------------------------------------------"
 echo "  USAGE:    ./vivado_me.sh  [-m SYNTH|PRJ>] [-f <FPGA DEVICE>] [-t <Design top level>] [-s <Simulation top level>] [-o <output_dir>] [-c] [-h]"
 echo " "
 echo "                           -m  mode for working with vivado"
 echo "                               Options: SYNTH -> Run a synthesis in non-project mode"
 echo "                                        PRJ   -> Auto generate a Vivado projet to work on"
 echo "                           -f  FPGA device to synthesize for (default xcku115-flvb2014-2-e)"
 echo "                           -t  Top level module to synthesize."
 echo "                               Options: $*"
 echo "                                        (default $1)"
 echo "                           -s  Top level for simulation"
 echo "                               Options: $*"
 echo "                                        (default $1)"
 echo "                           -c  clear previous generated files (if any) before launching Vivado"
 echo "                           -o  output directory for generated files"
 echo "                               (default output_files)"
 echo "                           -h  shows this help"
 echo " "
 echo " "
 exit 1
}


set -e

if [[ -z "${ROOT_PATH}" ]] ; then
	echo "Environment variable 'ROOT_PATH' not set. Please set to the root path of DataNoC project"
fi

# list of possible modules to synthesize.
TOP_SYNTH_LIST=$(cat ${ROOT_PATH}/vivado/top_synth_modules.txt | tr '\n' ' ')
TOP_SIM_LIST=$(cat ${ROOT_PATH}/vivado/top_sim_modules.txt | tr '\n' ' ')
TOP_SYNTH=${TOP_SYNTH_LIST%% *}
TOP_SIM=${TOP_SIM_LIST%% *}
DEVICE="xcku115-flvb2104-1-c"
CLEAN=0
MODE="SYNTH"
OUTPUT_DIR="output_files"

# Parse input parameter and make sure they are valid
while getopts m:f:t:s:o:ch option
do
    case "${option}" in
	f)
	    DEVICE=$OPTARG
	    ;;
        t)  FOUND=0
            TOP_SYNTH=$OPTARG
            for m in ${TOP_SYNTH_LIST} ; do
              if [ "$m" == "${TOP_SYNTH}" ] ; then
                FOUND=1
                break
              fi
            done
            if [ $FOUND -eq 0 ] ; then
              echo "The module ${TOP_SYNTH} cannot be synthesized through this script"
              exit 0
            fi
            ;;
        s)  FOUND=0
            TOP_SIM=$OPTARG
            for m in ${TOP_SIM_LIST} ; do
              if [ "$m" == "${TOP_SIM}" ] ; then
                FOUND=1
                break
              fi
            done
            if [ $FOUND -eq 0 ] ; then
              echo "The module ${TOP_SIM} does not seems a testbench this script can handle"
              exit 0
            fi
	    ;;
        o)  OUTPUT_DIR=$OPTARG
            ;;
	c)  CLEAN=1
	    ;;
	m)  MODE=$OPTARG
            if [[ "$MODE" != "SYNTH" && "$MODE" != "PRJ" ]] ; then
              echo "Mode ${MODE} is not supported"
	      exit 0
            fi
            ;;
	*)
	    PrintUsage ${TOP_SYNTH_LIST} ${TOP_SIM_LIST}
	    exit;
	    ;;
    esac
done


if [ ${CLEAN} -eq 1 ] ; then
  rm -rf ${OUTPUT_DIR}
  mkdir ${OUTPUT_DIR}
fi

[[ ! -d "${OUTPUT_DIR}" ]] && mkdir -p ${OUTPUT_DIR}

if [[ "$MODE" == "SYNTH" ]] ; then
  echo "Synthesizing ${TOP_SYNTH} for FPGA DEVICE ${DEVICE}. Files generated will be writen to ${OUTPUT_DIR}"
  vivado -mode batch -source ${ROOT_PATH}/vivado/vivado_synth.tcl -journal ${OUTPUT_DIR}/vivado.jou -log ${OUTPUT_DIR}/vivado.log -tclargs --dev ${DEVICE} --top_synth ${TOP_SYNTH} --output_dir ${OUTPUT_DIR}
else
  echo "Opening auto generated vivado project"
  vivado -mode tcl -source ${ROOT_PATH}/vivado/vivado_project.tcl -journal ${OUTPUT_DIR}/vivado.jou -log ${OUTPUT_DIR}/vivado.log -tclargs --dev ${DEVICE} --top_synth ${TOP_SYNTH} --top_sim ${TOP_SIM} --prj_dir ${OUTPUT_DIR}
fi

exit $?

