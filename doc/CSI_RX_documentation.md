# CSI_RX_documentation 
### Table of Contents 
* [Sub-System Introduction](#Sub-System_Introduction)<br>
* [Sub-System Features](#Sub-System_Features)
* [Sub-System Specifications](#Sub-System_Specifications)
    * [Port Description](#Port_Description)
    * [Register Space](#Register_Space)
* [Designing With The Subsystem](#Designing_With_The_Subsystem)
    * [General Guidelines](#General_Guidelines)
    * [Clocking](#Clocking)
    * [Resets](#Resets)
    * [Programming The Subsystem](#Programming_The_Subsystem)
* [Architecture](#Architecture)
    * [Overview](#Overview)
    * [Lane Management Layer](#Lane_Management_Layer)
    * [Protocol Layer](#Protocol_Layer)
    * [Image Signal Processing Pipeline](#Image_Signal_Processing_Pipeline)
    * [AXI Master Interface](#AXI_Master_Interface)
    * [RAM Macros](#RAM_Macros)
    
<!-- headings -->
## 1. Sub-System Introduction <a name="Sub-System_Introduction"></a>
The CSI RX subsystem implements the Mobile Industry Processor Interface (MIPI) Camera
Serial Interface (CSI-2) RX subsystem according to MIPI CSI-2 standard v1.1.
The subsystem is configured through AXI4 interface and can capture images from a MIPI CSI-2
Camera sensors and output an AXI4 to be directed to a memory.

## 2. Sub-system Features <a name="Sub-System_Features"></a>

## 3. Sub-system Specifications <a name="Sub-System_Specifications"></a>

### 1. Port Description <a name="Port_Description"></a>

### 2. Register Space <a name="Register_Space"></a>
|Address Offset |Register Name |Description |
|-----|-----|-----|
|0x00 |[Core Configuration Register](#Core_Configuration_Register)|Core configuration options|
|0x04 |[Protocol Configuration Register](#Protocol_Configuration_Register)|Protocol configuration options|
|0x08 |[Interleave Configuration Register](#Interleave_Configuration_Register)|Interleaving options for the core|
|0x0C |[Frame Width Register](#Frame_Width_Register)|Frame width received from the camera|
|0x10 |[Frame Height Register](#Frame_Height_Register)|Frame height received from the camera|
|0x14 |[Frame Pointer Register](#Frame_Pointer_Register)|Frame pointer that points to the start location of the frame in the memory|
|0x18 |[Core Status Register](#Core_Status_Register)|Core status register|
|0x0C |[Global Interrupt Enable Register](#Global_Interrupt_Enable_Register)|Global interrupt enable register|
|0x14 |[Interrupt Enable Register](#Interrupt_Enable_Register)|Interrupt enable register|
|0x18 |[Dynamic VC Selection Register](#Dynamic_VC_Selection_Register)|Virtual channel select register|
|0x1C |[Generic Short Packet Register](#Dynamic_VC_Selection_Register)|Short packet data|
|0x20 |[Lane 0 Information Register](#Lane_n_Information_Registers)|Lane 0 status information|
|0x24 |[Lane 1 Information Register](#Lane_n_Information_Registers)|Lane 1 status information|
|0x28 |[Lane 2 Information Register](#Lane_n_Information_Registers)|Lane 2 status information|
|0x2C |[Lane 3 Information Register](#Lane_n_Information_Registers)|Lane 3 status information|
|0x30 |[Image Information 1 for VC0](#Image_Information_1_Registers)|Image information 1 for current processing packet with VC of 0|
|0x34 |[Image Information 2 for VC0](#Image_Information_2_Registers)|Image information 2 for current processing packet with VC of 0|
|0x38 |[Image Information 1 for VC1](#Image_Information_1_Registers)|Image information 1 for current processing packet with VC of 1|
|0x3C |[Image Information 2 for VC1](#Image_Information_2_Registers)|Image information 2 for current processing packet with VC of 1|
|0x40 |[Image Information 1 for VC2](#Image_Information_1_Registers)|Image information 1 for current processing packet with VC of 2|
|0x44 |[Image Information 2 for VC2](#Image_Information_2_Registers)|Image information 2 for current processing packet with VC of 2|
|0x48 |[Image Information 1 for VC3](#Image_Information_1_Registers)|Image information 1 for current processing packet with VC of 3|
|0x4C |[Image Information 2 for VC3](#Image_Information_2_Registers)|Image information 2 for current processing packet with VC of 3|

#### Core Configuration Register (0x00) <a name="Core_Configuration_Register"></a>
Allows you to enable and disable the MIPI CSI-2 RX Controller core and apply a soft reset during core operation.
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:3|Reserved||||
|2|Output Select|0x0|R/W|1: Selects yuv420 output </br> 0: Selects the input datatype|
|1|Soft Reset|0x0|R/W|1: Resets the core </br> 0: Takes core out of soft reset|
|0|Core Enable|0x1|R/W|1: Enables the core to receive and process packets </br> 0: Disables the core for operation|


#### Protocol Configuration Register (0x04) <a name="Protocol_Configuration_Register"></a>
Allows you to configure protocol specific options such as the number of lanes to be used.
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:12|Reserved||||
|22:20|Pixel Per Clock3|0x0|R/W|Pixel per clock for ISP channel 3</br> 0x1 1PPC </br> 0x2 2PPC </br> 0x4 4PPC|
|19:17|Pixel Per Clock2|0x0|R/W|Pixel per clock for ISP channel 2</br> 0x1 1PPC </br> 0x2 2PPC </br> 0x4 4PPC|
|16:14|Pixel Per Clock1|0x0|R/W|Pixel per clock for ISP channel 1</br> 0x1 1PPC </br> 0x2 2PPC </br> 0x4 4PPC|
|13:11|Pixel Per Clock0|0x0|R/W|Pixel per clock for ISP channel 0</br> 0x1 1PPC </br> 0x2 2PPC </br> 0x4 4PPC|
|11:10|Bayer Type3|0x0|R/W|Bayer type for ISP channel 3 </br> 0x0 RGGB </br> 0x1 BGGR </br> 0x2 GBRG </br> 0x3 GRBG|
|9:8|Bayer Type2|0x0|R/W|Bayer type for ISP channel 2 </br> 0x0 RGGB </br> 0x1 BGGR </br> 0x2 GBRG </br> 0x3 GRBG|
|7:6|Bayer Type1|0x0|R/W|Bayer type for ISP channel 1 </br> 0x0 RGGB </br> 0x1 BGGR </br> 0x2 GBRG </br> 0x3 GRBG|
|5:4|Bayer Type0|0x0|R/W|Bayer type for ISP channel 0 </br> 0x0 RGGB </br> 0x1 BGGR </br> 0x2 GBRG </br> 0x3 GRBG|
|3:0|Active Lanes|0x0|R/W|Active lanes in the core</br> 0x1-1 Lane</br> 0x2-2 Lanes</br> 0x3-3 Lanes(!NOT DONE)</br> 0x4-4 Lanes|

#### Interleave Configuration Register (0x04) <a name="Interleave_Configuration_Register"></a>
Allows you to configure protocol specific options such as the number of lanes to be used.
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:30|Vitrual Channel ID Select3|0x0|R/W|Virtual channel ID interleaving select for ISP channel3|
|29:28|Vitrual Channel ID Select2|0x0|R/W|Virtual channel ID interleaving select for ISP channel2|
|27:26|Vitrual Channel ID Select1|0x0|R/W|Virtual channel ID interleaving select for ISP channel1|
|25:24|Vitrual Channel ID Select0|0x0|R/W|Virtual channel ID interleaving select for ISP channel0|
|23:18|Data Type Select3|0x0|R/W|Data type interleaving for ISP channel 0 </br> 0x1E YUV422_8 </br> 0x24 RGB888 </br> 0x22 RGB565 </br> 0x2A RAW8 </br> 0x2B RAW10|
|17:12|Data Type Select2|0x0|R/W|Data type interleaving for ISP channel 0 </br> 0x1E YUV422_8 </br> 0x24 RGB888 </br> 0x22 RGB565 </br> 0x2A RAW8 </br> 0x2B RAW10|
|11:6|Data Type Select1|0x0|R/W|Data type interleaving for ISP channel 0 </br> 0x1E YUV422_8 </br> 0x24 RGB888 </br> 0x22 RGB565 </br> 0x2A RAW8 </br> 0x2B RAW10|
|5:0|Data Type Select0|0x0|R/W|Data type interleaving for ISP channel 0 </br> 0x1E YUV422_8 </br> 0x24 RGB888 </br> 0x22 RGB565 </br> 0x2A RAW8 </br> 0x2B RAW10|

#### Frame Width Register (0x04) <a name="Frame_Width_Register"></a>
Allows you to configure the width of the frame received from the camera module.
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:12|Reserved||||
|11:0|Frame Width|0x0|R/W|Width of the frame received from the camera module|

#### Frame Height Register (0x04) <a name="Frame_Height_Register"></a>
Allows you to configure the height of the frame received from the camera module.
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:12|Reserved||||
|11:0|Frame Height|0x0|R/W|Height of the frame received from the camera module|

#### Frame Pointer Register (0x04) <a name="Frame_Pointer_Register"></a>
Allows you to configure the pointer in memory to which a frame is written to.
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:0|Frame Pointer|0x0|R/W|Pointer in memory to which a frame is written to </br> It should include the memory address and the offset in memory|

#### Core Status Register(0x08) <a name="Core_Status_Register"></a>
Captures the error and status information of the core
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:16|Packet Count|0x0|R|Counts number of long packets written to the line buffer</br>• Packet count will roll over from 0xFFFF to 0x0000. The roll over of this counter is not reported.</br>• Count includes error packets (if any)|
|15:4|Reserved||||
|3|Short packet FIFO Full|0x0|R|Indicates the current status of short packet FIFO full condition|
|2|Short packet FIFO not empty|0x0|R|FIFO not empty: Indicates the current status of short packet FIFO not empty condition|
|1|Stream Line buffer Full|0x0|R|Indicates the current status of line buffer full condition|
|0|Soft reset/Core disable in progress|0x0|R|Set to 1 by the core to indicate that internal soft reset/core disable activities are in progress|

#### Global Interrupt Enable Register (0x0C) <a name="Global_Interrupt_Enable_Register"></a>
Captures the error and status information of the core
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:1|Reserved||||
|0|Global interrupt enable|0x0|R/W|Master enable for the device interrupt output to the system</br> 1: Enabled—the corresponding Interrupt Enable register (IER) bits are used to generate interrupts</br> 0: Disabled—Interrupt generation blocked  irrespective of IER bits|

#### Interrupt Status Register (0x10) <a name="Interrupt_Status_Regiser"></a>
Captures the error and status information of the core
|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31|Frame Received|0x0|R/W1C|Asserted when Frame End FE short packet is received for the current frame|
|30|Reserved|-----|-----|-----|
|29|RX_Skewcalhs|0x0|R/W1C|Asserted when rxskewcalhs is detected|
|28:23|Reserved|-----|-----|-----|
|22|Word Counter(WC) corruption|0x0|R/W1C|Asserted when WC field of packet header corrupted and core receives less bytes than indicated in WC field. Such a case can occur only where more than 2-bits of header are corrupted which ECC algorithm cannot report and the corruption is such that the ECC algorithm reports a higher Word Count (WC) value as part of ECC correction.In such case core limits processing of the packet on reduced number of bytes received through PPI interface.|
|21|Incorrect lane configuration|0x0|R/W1C|Asserted when Active lanes is greater than Maximum lanes in the protocol configuration register|
|20|Short Packet FIFO full|0x0|R/W1C|Active-High signal asserted when the short packet FIFO full condition detected|
|19|Short packet FIFO not empty|0x0|R/W1C|Active-High signal asserted when short packet FIFO not empty condition detected|
|18|Stream line buffer full|0x0|R/W1C|Asserts when the line buffer is full|
|17|Stop state|0x0|R/W1C|Active-High signal indicates that the lane module is currently in Stop state|
|16:14|Reserved||||
|13|SoT error (ErrSoTHS)|0x0|R/W1C|Indicates SoT synchronization completely failed|
|12|SoT sync error (ErrSotSyncHS)|0x0|R/W1C|Indicates SoT synchronization completely failed|
|11|ECC 2-bit error (ErrEccDouble)|0x0|R/W1C|Asserted when an ECC syndrome is computed and two bit errors detected in the received packet header|
|10|ECC 1-bit error (Detected and Corrected) (ErrEccCorrected)|0x0|R/W1C|Asserted when an ECC syndrome was computed and a single bit error in the packet header was detected and corrected|
|9|CRC error (ErrCrc)|0x0|R/W1C|Asserted when the computed CRC code is different from the received CRC code|
|8|Unsupported Data Type (ErrID)|0x0|R/W1C|Asserted when a packet header is decoded with an unrecognized or not implemented data ID|
|7|Frame synchronization error for VC3 (ErrFrameSync)|0x0|R/W1C|Asserted when an FE is not paired with a Frame Start (FS) on the same virtual channel|
|6|Frame level error for VC3 (ErrFrameData)|0x0|R/W1C|Asserted after an FE when the data payload received between FS and FE contains errors.The data payload errors are CRC errors.|
|5|Frame synchronization error for VC2 (ErrFrameSync)|0x0|R/W1C|Asserted when an FE is not paired with a Frame Start (FS) on the same virtual channel|
|4|Frame level error for VC2 (ErrFrameData)|0x0|R/W1C|Asserted after an FE when the data payload received between FS and FE contains errors.The data payload errors are CRC errors.|
|3|Frame synchronization error for VC1 (ErrFrameSync)|0x0|R/W1C|Asserted when an FE is not paired with a Frame Start (FS) on the same virtual channel|
|2|Frame level error for VC1 (ErrFrameData)|0x0|R/W1C|Asserted after an FE when the data payload received between FS and FE contains errors.The data payload errors are CRC errors.|
|1|Frame synchronization error for VC0 (ErrFrameSync)|0x0|R/W1C|Asserted when an FE is not paired with a Frame Start (FS) on the same virtual channel|
|0|Frame level error for VC0 (ErrFrameData)|0x0|R/W1C|Asserted after an FE when the data payload received between FS and FE contains errors.The data payload errors are CRC errors.|

#### Interrupt Enable Register (0x10) <a name="Interrupt_Enable_Register"></a>
The Interrupt Enable register (IER) allows you to selectively 
generate an interrupt at the output port for each error/status bit in the ISR.</br> An IER bit set 
to 0 does not inhibit an error/status condition from being captured, but inhibits it from generating an interrupt.

|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31|Frame Received|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt. |
|30|Reserved|-----|-----|-----|
|29|RX_Skewcalhs|0x0|R/W|Set to 1 to generate the rxskecalhs interrupt|
|28:23|Reserved|-----|-----|-----|
|22|Word Counter(WC) corruption|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt. |
|21|Incorrect lane configuration|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|20|Short Packet FIFO full|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|19|Short packet FIFO not empty|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|18|Stream line buffer full|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|17|Stop state|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|16:14|Reserved||||
|13|SoT error (ErrSoTHS)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|12|SoT sync error (ErrSotSyncHS)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|11|ECC 2-bit error (ErrEccDouble)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|10|ECC 1-bit error (Detected and Corrected) (ErrEccCorrected)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|9|CRC error (ErrCrc)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|8|Unsupported Data Type (ErrID)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|7|Frame synchronization error for VC3 (ErrFrameSync)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|6|Frame level error for VC3 (ErrFrameData)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|5|Frame synchronization error for VC2 (ErrFrameSync)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|4|Frame level error for VC2 (ErrFrameData)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|3|Frame synchronization error for VC1 (ErrFrameSync)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|2|Frame level error for VC1 (ErrFrameData)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|1|Frame synchronization error for VC0 (ErrFrameSync)|0x0|R/W| Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|
|0|Frame level error for VC0 (ErrFrameData)|0x0|R/W|Set bits in this register to 1 to generate the required interrupts.</br> Set to 0 to disable the interrupt.|

#### ! Dynamic VC Selection Register (0x18) <a name="Dynamic_VC_Selection"></a>

|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:2|Reserved||||
|1:0|VC Selection|0x0|R/W|Select which VC to be exported to the output interface|

#### Generic Short Packet Register (0x1C) <a name="Generic_Short_Packet_Register"></a>
The Generic Short Packet register is described in Table 2-27. Packets received with generic 
short packet codes are stored in a 31-deep internal FIFO and are made available through 
this register.</br>
* Note the following:
1. If one-bit error occurs during data-transmission, the MIPI CSI-2 controller fixes the 
error-bit and stores generic short packet data into the FIFO.
2. When a short packet is received with a 2-bit error, the MIPI CSI-2 controller discards the 
data without pushing the data to the FIFO.
3. Because the data field of the register is only 16 bits wide, the ECC information is not 
stored.

|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:24|Reserved||||
|23:8|Data|0x0|R|16-bit short packet data|
|7-6|Virtual Channel|0x0|R|Virtual channel number|
|5:0|Data Type|0x0|R|Generic short packet code|

#### Lane_n Information Registers (0x20, 0x24, 0x28, 0x2C) <a name="Lane_n_Information_Registers"></a>
The Lane_n Information register, where n is 0, 1, 2 or 3,
provides the status of the n data lane.</br> This register is reset when any write to the 
Protocol Configuration register is detected, irrespective of whether the Protocol 
Configuration register contents are updated or not.

|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:6|Reserved||||
|5|Stop State|0x0|R|Detection of stop state|
|4-3|Reserved|0x0|||
|2|skewcalhs|0x0|R|Indecates the deskew reception|
|1|SoT error|0x0|R|Detection of SoT error|
|0|SoT sync error|0x0|R|Detection of SoT synchronization error|

#### Image Information 1 Registers (VC0 to VC3) (0x30, 0x34, 0x38, 0x3C) <a name="Image_Information_1_Registers"></a>
The Image Information 1 registers provide image 
information for line count and byte count per VC.</br> The byte count gets updated whenever a 
long packet (from Data Types 0x18 and above) for the corresponding virtual channel is 
processed by the control FSM.</br> The line count is updated whenever the packet is written into 
the line buffer.

|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:16|Line count|0x0|R|Number of long packets written to line buffer|
|15:0|Byte count|0x0|R|Byte count of current packet being processed by the control FSM|

#### Image Information 2 Registers (VC0 to VC3) (0x40, 0x44, 0x48, 0x4C) <a name="Image_Information_2_Registers"></a>
The Image Information 2 registers provide the image 
information Data Type.</br> The Data Type is updated whenever a long packet (Data Types 0x18 
and above) for the corresponding virtual channel is processed by the control FSM.

|Bits |Name |Reset Value |Access |Description |
|-----|-----|-----|-----|-----|
|31:6|Reserved||||
|15:0|Data Type|0x0|R|Data Type of current packet being processed by control FSM|

## 4. Designing With The Subsystem <a name="Designing_With_The_Subsystem"></a>

### 4.1 General Guidelines <a name="General_Guidelines"></a>
TODO

### 4.2 Clocking <a name="Clocking"></a>
TODO

### 4.3 Resets <a name="Resets"></a>
TODO

### 4.4 Programming The Subsystem <a name="Programming_The_Subsystem"></a>
TODO

## 5. Architecture <a name="Architecture"></a>
TODO
### 5.1 Overview <a name="Overview"></a>
TODO
### 5.2 Lane Management Layer <a name="Lane_Management_Layer"></a>
TODO
### 5.3 Protocol Layer <a name="Protocol_Layer"></a>
TODO
### 5.4 Image Signal Processing Pipeline <a name="Image_Signal_Processing_Pipeline"></a>
TODO
### 5.5 AXI Master Interface <a name="AXI_Master_Interface"></a>
TODO
### 5.6 RAM Macros <a name="RAM_Macros"></a>
||*Throttle Dual Port RAM* |
|-----|-----|
|RTL instance|mipi_csi_rx_instance . isp_pipeline_i . flow_control_i . throttle_ram_i . line|
|Dimentions|52x4096|
|Number of Instances|1|
|Contents|Can hold a line of pixels for throtteling interfaces|
|Latency|1 clck cycle (RW)|
|Ports|1R1W|

||*Debayer Dual Port RAM*|
|-----|-----|
|RTL instance|mipi_csi_rx_instance . isp_pipeline_i . debayer_filter_i . line_ram_wrapper_i . line[i]|
|Dimentions|44x2048|
|Number of Instances|4|
|Contents|4 lines of image data for RAW2RGB conversion algorithm|
|Latency|1 clck cycle (RW)|
|Ports|1R1W|

||*AXIStream Single Port RAM*|
|-----|-----|
|RTL instance|mipi_csi_rx_instance.csi_axi_master_i.pixel_mem_array_i.buffer0 <br> mipi_csi_rx_instance.csi_axi_master_i.pixel_mem_array_i.buffer1 |
|Dimentions|32x256|
|Number of Instances|2|
|Contents|Ping pong memories for AXI INCR burst mode|
|Latency|1 clck cycle (RW)|
|Ports|1RW|

||*AXIStream Single Port RAM*|
|-----|-----|
|RTL instance|mipi_csi_rx_instance . csi_axi_master_i . yuv_mem_array_wrapper_i . y_buffer0 <br> mipi_csi_rx_instance . csi_axi_master_i . yuv_mem_array_wrapper_i . y_buffer1 |
|Dimentions|32x256|
|Number of Instances|2|
|Contents|Ping pong memories for AXI INCR burst mode|
|Latency|1 clck cycle (RW)|
|Ports|1RW|

||*AXIStream Single Port RAM*|
|-----|-----|
|RTL instance| mipi_csi_rx_instance . csi_axi_master_i . yuv_mem_array_wrapper_i . u_buffer0 <br> mipi_csi_rx_instance . csi_axi_master_i . yuv_mem_array_wrapper_i . u_buffer1 <br> mipi_csi_rx_instance . csi_axi_master_i . yuv_mem_array_wrapper_i . v_buffer0 <br> mipi_csi_rx_instance . csi_axi_master_i . yuv_mem_array_wrapper_i . v_buffer1|
|Dimentions|32x128|
|Number of Instances|4|
|Contents|Ping pong memories for AXI INCR burst mode|
|Latency|1 clck cycle (RW)|
|Ports|1RW|