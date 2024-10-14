# FPGA Prototyping of Vector-Crypto Subsystem (Marian) for Bow

## Directory Structure

```
/fpga
|--/board_files
|--/build (tmp)
|--/constraints
|--/doc
|--/hdl
|  |--/include
|  |--/ip
|  |--/src
|  |--/tb
|--/ips
|--/scripts
|--/sim
|--/sw
|--/utils
```
- **build**: The output directory for build-related files. It includes subdirectories for Vivado projects, logs and temporary files. The final bitstream may be stored here. Note that this is a temporary directory and is never to be committed in version control.

- **board_files**: Contains board specific metadata (relevant to boards which do not have board files in Vivado already).

- **doc**: Contains detailed documentation, user guides, and any other relevant documentation.

- **hdl**: This is where the hardware description language (HDL) source code resides. It includes subdirectories for custom source files (src), headers/packages (include), ip-specific RTL (ip) and testbenches (tb).

- **ips**: If the project uses any vendor IPs, the build scripts and source files can be stored in this directory.

- **constraints**: Holds any constraint files (e.g., Xilinx Design Constraints - XDC files) that define the timing and placement constraints for the FPGA design.

- **sim**: Contains simulation-related files. For example, simulation scripts can be stored here.

- **scripts**: Houses various scripts used in the project, such as build scripts or deployment scripts.

- **sw**: All software artefacts used for FPGA development are stored here.

-**utils**: Holds ancillary items used when interacting with the FPGA prototyping project e.g. openOCD scripts and memory initialisation files. 
