# What's DataNoC?

DataNoC is a Network-on-Chip solution for prototyping (heterogeneous) many core systems in FPGA.

It has been developed by the Group of Parallel Architectures (GAP) of the Technical University of Valencia (UPV) and used in different projects, including the MANGO project ([mango-project.eu](http://www.mango-project.eu)), founded by the European Commision under H2020 program.

The DataNoC born as part of the PEAK manycore, an FPGA RISC manycore prototype, developed internally by the GAP. It has reached such a good maturity degree that we have decided to release it, so other entities can integrate it in their projects.

It has been developed from scratch in Verilog HDL, thus it can be synthesized for both Xilinx and Intel FPGAs. Nevertheless, we only deliver the scripts for synthesizing and generating a Vivado project for Xilinx FPGAs.

Notice that:

1. The scripts delivered in this repository are only compatible with Linux-like shell environments.
2. It is required some knowledge on the Vivado Desgin Suite and HDL programming in order to take advantage of the DataNoC project.

# DataNoC components

The main components of the DataNoC are the switch (or router) and the network injector.

The switch routes packets from source and destination nodes arranged in a 2D mesh topology. The router has provision for Virtual Channels (VC’s) that can be configured at design time. VCs can be grouped also in Virtual Networks (VN) where each VN can be assigned to a specific application flow or task flow. The number of VNs can be adapted at design time, thereby enabling the exploration of different overlapping and independent communication flows. In addition, the packets traveling through VNs are associated with specific labels in their headers, enabling allocator units at routers to establish priorities for resource assignments (output ports of the routers), thereby enabling timing guarantees from the application perspective.

The network injector is a component of a network interface (NI) that multiplexes the requests received from the manycore elements that require network access, such as caches, core, etc. The network inject module implement similar logic of a router output port with virtual networks (VNs) support to separate data traffic.

By replicating the router in a 2D manner a mesh network topology can be generated. The user can find a 4x4 mesh example in the sim_examples folder. The examples are not ready for synthesis, but they can be simulated in Vivado project mode. In addition, to generate a 8x8 example the user just have to comment the 4x4 corresponding local parameters and uncomment the 8x8 ones at the beginning of mesh2d_vc_tb file.

# How to synthesize?

We have enabled two modes for NoC synthesis.

1. Run the synthesis script in non-poject mode.
2. Generate a Vivado project and then use the project mode synthesis flow.

In both cases the user has to set ROOT_PATH environment variable to the location of the file system where the code has been downloaded.

Once that variable has been set, the user must run the script vivado_me.sh, located in the vivado folder.

The options for this script are as follows.

```bash
 echo "  USAGE:    ./vivado_me.sh  [-m SYNTH|PRJ>] [-f <FPGA DEVICE>] [-t <Design top level>] [-s <Simulation top level>] [-o <output_dir>] [-c] [-h]"
 echo " "
 echo "                           -m  mode for working with vivado"
 echo "                               Options: SYNTH -> Run a synthesis in non-project mode"
 echo "                                        PRJ   -> Auto generate a Vivado projet to work on"
 echo "                           -f  FPGA device to synthesize for (default xcku115-flvb2014-2-e)"
 echo "                           -t  Top level module to synthesize."
 echo "                           -s  Top level for simulation"
 echo "                           -c  clear previous generated files (if any) before launching Vivado"
 echo "                           -o  output directory for generated files"
 echo "                               (default output_files)"
 echo "                           -h  shows this help"
```
Thus `-m` option allows to synthesize (SYNTH) in non-poject mode or generate a Vivado project (PRJ) to work with it.

There are two modules that can be synthesized: the switch (or router) and the network injector.

# How to simulate?

For simulating the DataNoC we recommend to generate a Vivado project file first. This can be done with vivado_me.sh script, found in vivado folder. For that, use
`-m`option with PRJ value.

Then, the user can open the vivado project to simulate synthetic traffic in a 4x4 and 8x8 mesh topologies as described above.
