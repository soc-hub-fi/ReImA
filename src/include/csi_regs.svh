
`ifndef CSI_REGS_SVH_
`define CSI_REGS_SVH_

`define REG_NUM_BYTES 32'd96

`define REG_ADDR_OFFSET(reg_name,offset) `REG_ADDR(reg_name)+offset

`define REG_ADDR_OFFSET(reg_name) \
    reg_name=="CCR" ?       32768: \
    reg_name=="PCR" ?       32772: \
    reg_name=="ICR" ?       32776: \
    reg_name=="FWR" ?       32780: \
    reg_name=="FHR" ?       32784: \
    reg_name=="FPR0" ?      32788: \
    reg_name=="FPR1" ?      32792: \
    reg_name=="CSR" ?       32796: \
    reg_name=="GIER" ?      32800: \
    reg_name=="IER" ?       32804: \
    reg_name=="DVCSR"?      32808: \
    reg_name=="GSPR" ?      32812: \
    reg_name=="L0IR" ?      32816: \
    reg_name=="L1IR" ?      32820: \
    reg_name=="L2IR" ?      32824: \
    reg_name=="L3IR" ?      32828: \
    reg_name=="II1VC0R" ?   32832: \
    reg_name=="II2VC0R" ?   32836: \
    reg_name=="II1VC1R" ?   32840: \
    reg_name=="II2VC1R" ?   32844: \
    reg_name=="II1VC2R" ?   32848: \
    reg_name=="II2VC2R" ?   32852: \
    reg_name=="II1VC3R" ?   32856: \
    reg_name=="II2VC3R" ?   32860: \
    0

`define REG_ADDR(reg_name) \
    reg_name=="CCR" ?       0: \
    reg_name=="PCR" ?       4: \
    reg_name=="ICR" ?       8: \
    reg_name=="FWR" ?       12: \
    reg_name=="FHR" ?       16: \
    reg_name=="FPR0" ?      20: \
    reg_name=="FPR1" ?      24: \
    reg_name=="CSR" ?       28: \
    reg_name=="GIER" ?      32: \
    reg_name=="IER" ?       36: \
    reg_name=="DVCSR"?      40: \
    reg_name=="GSPR" ?      44: \
    reg_name=="L0IR" ?      48: \
    reg_name=="L1IR" ?      52: \
    reg_name=="L2IR" ?      56: \
    reg_name=="L3IR" ?      60: \
    reg_name=="II1VC0R" ?   64: \
    reg_name=="II2VC0R" ?   68: \
    reg_name=="II1VC1R" ?   72: \
    reg_name=="II2VC1R" ?   76: \
    reg_name=="II1VC2R" ?   80: \
    reg_name=="II2VC2R" ?   84: \
    reg_name=="II1VC3R" ?   88: \
    reg_name=="II2VC3R" ?   92: \
    0

`define REG_DATA(reg_name, reg_data, offset, width) \
    reg_data[int'(`REG_ADDR(reg_name))*8 + offset +:width]

`define REG_RO(reg_name, REG_RO_EN) \
    REG_RO_EN[`REG_ADDR(reg_name)*4 +:4]

/**
 * Macro to define a read-only register.
 *
 * This macro defines a read-only register with the given register name.
 * The enable signal is a 4-bit vector that determines the read enable for each byte of the register.
 * The macro updates the REG_RO_EN parameter to include the read-only register for use in the CSI module.
 *
 * @param REG_RO_EN The parameter used to select RO registers.
 */

`define ASSIGN_RO_REGS \
    96'b1111<<int'(`REG_ADDR("CSR")) | \
    96'b1111<<int'(`REG_ADDR("GSPR")) | \
    96'b1111<<int'(`REG_ADDR("L0IR")) | \
    96'b1111<<int'(`REG_ADDR("L1IR")) | \
    96'b1111<<int'(`REG_ADDR("L2IR")) | \
    96'b1111<<int'(`REG_ADDR("L3IR")) | \
    96'b1111<<int'(`REG_ADDR("II1VC0R")) | \
    96'b1111<<int'(`REG_ADDR("II2VC0R")) | \
    96'b1111<<int'(`REG_ADDR("II1VC1R")) | \
    96'b1111<<int'(`REG_ADDR("II2VC1R")) | \
    96'b1111<<int'(`REG_ADDR("II1VC2R")) | \
    96'b1111<<int'(`REG_ADDR("II2VC2R")) | \
    96'b1111<<int'(`REG_ADDR("II1VC3R")) | \
    96'b1111<<int'(`REG_ADDR("II2VC3R"))

/**
 * Macro `ASSIGN_RST_REGS` is used to assign reset values to registers.
 * It takes a parameter `REG_RST_VAL` which represents the reset value to be assigned for the whole register space.
 * The macro modifies REG_RST_VAL to include the reset value for the registers specified in the macro.
 * Then it can be used in the CSI module parameter list.
 * The example shows the assignment of reset value 32'h00000004 to the Protocol Configuration Register (PCR).
 */
`define ASSIGN_RST_REGS \
    768'd4 << `REG_ADDR("PCR")*8

/**
 * This file defines a set of macros for fetching specific fields from various registers.
 * Each macro takes in the register data and the field name as arguments and returns the value of the specified field.
 * If the field name is not recognized, the macro returns an "Out of Range" error message.
 */

`define FETCH_CCR_FIELD(reg_data, field_name) \
    field_name == "DOUB_BUFF_EN" ?  `REG_DATA("CCR", reg_data, 3, 1): \
    field_name == "OUTPUT_SELECT" ? `REG_DATA("CCR", reg_data, 2, 1): \
    field_name == "SOFT_RESET" ?    `REG_DATA("CCR", reg_data, 1, 1): \
    field_name == "CORE_ENABLE" ?   `REG_DATA("CCR", reg_data, 0, 1): \
    0

`define FETCH_PCR_FIELD(reg_data, field_name) \
    field_name == "PIXEL_PER_CLK3" ?    `REG_DATA("PCR", reg_data, 21, 3): \
    field_name == "PIXEL_PER_CLK2" ?    `REG_DATA("PCR", reg_data, 18, 3): \
    field_name == "PIXEL_PER_CLK1" ?    `REG_DATA("PCR", reg_data, 15, 3): \
    field_name == "PIXEL_PER_CLK0" ?    `REG_DATA("PCR", reg_data, 12, 3): \
    field_name == "BAYER_TYPE3" ?       `REG_DATA("PCR", reg_data, 10, 2): \
    field_name == "BAYER_TYPE2" ?       `REG_DATA("PCR", reg_data, 8, 2): \
    field_name == "BAYER_TYPE1" ?       `REG_DATA("PCR", reg_data, 6, 2): \
    field_name == "BAYER_TYPE0" ?       `REG_DATA("PCR", reg_data, 4, 2): \
    field_name == "ACTIVE_LANES" ?      `REG_DATA("PCR", reg_data, 0, 4): \
    0

`define FETCH_ICR_FIELD(reg_data, field_name) \
    field_name == "VCID_SEL3" ?         `REG_DATA("ICR", reg_data, 30, 2): \
    field_name == "VCID_SEL2" ?         `REG_DATA("ICR", reg_data, 28, 2): \
    field_name == "VCID_SEL1" ?         `REG_DATA("ICR", reg_data, 26, 2): \
    field_name == "VCID_SEL0" ?         `REG_DATA("ICR", reg_data, 24, 2): \
    field_name == "DATA_TYPE_SEL3" ?    `REG_DATA("ICR", reg_data, 18, 6): \
    field_name == "DATA_TYPE_SEL2" ?    `REG_DATA("ICR", reg_data, 12, 6): \
    field_name == "DATA_TYPE_SEL1" ?    `REG_DATA("ICR", reg_data, 6, 6): \
    field_name == "DATA_TYPE_SEL0" ?    `REG_DATA("ICR", reg_data, 0, 6): \
    0

`define FETCH_FWR_FIELD(reg_data, field_name) \
    field_name == "FRAME_WIDTH" ?       `REG_DATA("FWR", reg_data, 0, 12): \
    0

`define FETCH_FHR_FIELD(reg_data, field_name) \
    field_name == "FRAME_HEIGHT" ?       `REG_DATA("FHR", reg_data, 0, 12): \
    0

`define FETCH_FPR0_FIELD(reg_data, field_name) \
    field_name == "FRAME_POINTER" ?     `REG_DATA("FPR0", reg_data, 0, 32): \
    0

`define FETCH_FPR1_FIELD(reg_data, field_name) \
    field_name == "FRAME_POINTER" ?     `REG_DATA("FPR1", reg_data, 0, 32): \
    0

`define FETCH_CSR_FIELD(reg_data, field_name) \
    field_name == "PACKET_COUNT" ?        `REG_DATA("CSR", reg_data, 16, 16): \
    field_name == "SP_FIFO_FULL" ?        `REG_DATA("CSR", reg_data, 3, 1): \
    field_name == "SP_FIFO_NEMP" ?        `REG_DATA("CSR", reg_data, 2, 1): \
    field_name == "STR_LINE_BUFF_FULL" ?  `REG_DATA("CSR", reg_data, 1, 1): \
    field_name == "SR_INP" ?              `REG_DATA("CSR", reg_data, 0, 1): \
    0

`define FETCH_GIER_FIELD(reg_data, field_name) \
    field_name == GIEN ? `REG_DATA(GIER, reg_data, 0, 1): \
    0

`define FETCH_ISR_FIELD(reg_data, field_name) \
    field_name == "FRAME_RECEIVED" ?          `REG_DATA("ISR", reg_data, 31, 1): \
    field_name == "RX_SKEWCALHS" ?            `REG_DATA("ISR", reg_data, 29, 1): \
    field_name == "WC_CORRUPTION" ?           `REG_DATA("ISR", reg_data, 22, 1): \
    field_name == "INCORRECT_LANE_CONFIG" ?   `REG_DATA("ISR", reg_data, 21, 1): \
    field_name == "SP_FIFO_FULL" ?            `REG_DATA("ISR", reg_data, 20, 1): \
    field_name == "SP_FIFO_NEMP" ?            `REG_DATA("ISR", reg_data, 19, 1): \
    field_name == "STR_LINE_BUFF_FULL" ?      `REG_DATA("ISR", reg_data, 18, 1): \
    field_name == "STOP_STATE" ?              `REG_DATA("ISR", reg_data, 17, 1): \
    field_name == "SOT_ERROR" ?               `REG_DATA("ISR", reg_data, 13, 1): \
    field_name == "SOT_SYNC_ERROR" ?          `REG_DATA("ISR", reg_data, 12, 1): \
    field_name == "ECC_2BIT_ERROR" ?          `REG_DATA("ISR", reg_data, 11, 1): \
    field_name == "ECC_1BIT_ERROR" ?          `REG_DATA("ISR", reg_data, 10, 1): \
    field_name == "CRC_ERROR" ?               `REG_DATA("ISR", reg_data, 9, 1): \
    field_name == "UNSUPPORTED_DATA_TYPE" ?   `REG_DATA("ISR", reg_data, 8, 1): \
    field_name == "FRAME_SYNC_ERROR_VC3" ?    `REG_DATA("ISR", reg_data, 7, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC3" ?   `REG_DATA("ISR", reg_data, 6, 1): \
    field_name == "FRAME_SYNC_ERROR_VC2" ?    `REG_DATA("ISR", reg_data, 5, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC2" ?   `REG_DATA("ISR", reg_data, 4, 1): \
    field_name == "FRAME_SYNC_ERROR_VC1" ?    `REG_DATA("ISR", reg_data, 3, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC1" ?   `REG_DATA("ISR", reg_data, 2, 1): \
    field_name == "FRAME_SYNC_ERROR_VC0" ?    `REG_DATA("ISR", reg_data, 1, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC0" ?   `REG_DATA("ISR", reg_data, 0, 1): \
    0

`define FETCH_IER_FIELD(reg_data, field_name) \
    field_name == "FRAME_RECEIVED" ?          `REG_DATA("IER", reg_data, 31, 1): \
    field_name == "RX_SKEWCALHS" ?            `REG_DATA("IER", reg_data, 29, 1): \
    field_name == "WC_CORRUPTION" ?           `REG_DATA("IER", reg_data, 22, 1): \
    field_name == "INCORRECT_LANE_CONFIG" ?   `REG_DATA("IER", reg_data, 21, 1): \
    field_name == "SP_FIFO_FULL" ?            `REG_DATA("IER", reg_data, 20, 1): \
    field_name == "SP_FIFO_NEMP" ?            `REG_DATA("IER", reg_data, 19, 1): \
    field_name == "STR_LINE_BUFF_FULL" ?      `REG_DATA("IER", reg_data, 18, 1): \
    field_name == "STOP_STATE" ?              `REG_DATA("IER", reg_data, 17, 1): \
    field_name == "SOT_ERROR" ?               `REG_DATA("IER", reg_data, 13, 1): \
    field_name == "SOT_SYNC_ERROR" ?          `REG_DATA("IER", reg_data, 12, 1): \
    field_name == "ECC_2BIT_ERROR" ?          `REG_DATA("IER", reg_data, 11, 1): \
    field_name == "ECC_1BIT_ERROR" ?          `REG_DATA("IER", reg_data, 10, 1): \
    field_name == "CRC_ERROR" ?               `REG_DATA("IER", reg_data, 9, 1): \
    field_name == "UNSUPPORTED_DATA_TYPE" ?   `REG_DATA("IER", reg_data, 8, 1): \
    field_name == "FRAME_SYNC_ERROR_VC3" ?    `REG_DATA("IER", reg_data, 7, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC3" ?   `REG_DATA("IER", reg_data, 6, 1): \
    field_name == "FRAME_SYNC_ERROR_VC2" ?    `REG_DATA("IER", reg_data, 5, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC2" ?   `REG_DATA("IER", reg_data, 4, 1): \
    field_name == "FRAME_SYNC_ERROR_VC1" ?    `REG_DATA("IER", reg_data, 3, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC1" ?   `REG_DATA("IER", reg_data, 2, 1): \
    field_name == "FRAME_SYNC_ERROR_VC0" ?    `REG_DATA("IER", reg_data, 1, 1): \
    field_name == "FRAME_LEVEL_ERROR_VC0" ?   `REG_DATA("IER", reg_data, 0, 1): \
    0

`define FETCH_DVCSR_FIELD(reg_data, field_name) \
    field_name == "VC_SELECTION" ? `REG_DATA("DVCSR", reg_data, 0, 2): \
    0

`define FETCH_GSPR_FIELD(reg_data, field_name) \
    field_name == "DATA" ?        `REG_DATA("GSPR", reg_data, 8, 16): \
    field_name == "VC" ?          `REG_DATA("GSPR", reg_data, 6, 2): \
    field_name == "DATA_TYPE" ?   `REG_DATA("GSPR", reg_data, 0, 6): \
    0

`define FETCH_L0IR_FIELD(reg_data, field_name) \
    field_name == "STOP_STATE" ?      `REG_DATA("L0IR", reg_data, 5, 1): \
    field_name == "SKEWCALHS" ?       `REG_DATA("L0IR", reg_data, 2, 1): \
    field_name == "SOT_ERROR" ?       `REG_DATA("L0IR", reg_data, 1, 1): \
    field_name == "SOT_SYNC_ERROR" ?  `REG_DATA("L0IR", reg_data, 0, 1): \
    0

`define FETCH_L1IR_FIELD(reg_data, field_name) \
    field_name == "STOP_STATE" ?      `REG_DATA("L1IR", reg_data, 5, 1): \
    field_name == "SKEWCALHS" ?       `REG_DATA("L1IR", reg_data, 2, 1): \
    field_name == "SOT_ERROR" ?       `REG_DATA("L1IR", reg_data, 1, 1): \
    field_name == "SOT_SYNC_ERROR" ?  `REG_DATA("L1IR", reg_data, 0, 1): \
    0

`define FETCH_L2IR_FIELD(reg_data, field_name) \
    field_name == "STOP_STATE" ?      `REG_DATA("L2IR", reg_data, 5, 1): \
    field_name == "SKEWCALHS" ?       `REG_DATA("L2IR", reg_data, 2, 1): \
    field_name == "SOT_ERROR" ?       `REG_DATA("L2IR", reg_data, 1, 1): \
    field_name == "SOT_SYNC_ERROR" ?  `REG_DATA("L2IR", reg_data, 0, 1): \
    0

`define FETCH_L3IR_FIELD(reg_data, field_name) \
    field_name == "STOP_STATE" ?      `REG_DATA("L3IR", reg_data, 5, 1): \
    field_name == "SKEWCALHS" ?       `REG_DATA("L3IR", reg_data, 2, 1): \
    field_name == "SOT_ERROR" ?       `REG_DATA("L3IR", reg_data, 1, 1): \
    field_name == "SOT_SYNC_ERROR" ?  `REG_DATA("L3IR", reg_data, 0, 1): \
    0

`define FETCH_II1VC0R_FIELD(reg_data, field_name) \
    field_name == "LINE_COUNT" ?   `REG_DATA("II1VC0R", reg_data, 16, 16): \
    field_name == "BYTE_COUNT" ?   `REG_DATA("II1VC0R", reg_data, 0, 16): \
    0

`define FETCH_II2VC0R_FIELD(reg_data, field_name) \
    field_name == "DATA_TYPE" ?   `REG_DATA("II2VC0R", reg_data, 0, 16): \
    0

`define FETCH_II1VC1R_FIELD(reg_data, field_name) \
    field_name == "LINE_COUNT" ?   `REG_DATA("II1VC1R", reg_data, 16, 16): \
    field_name == "BYTE_COUNT" ?   `REG_DATA("II1VC1R", reg_data, 0, 16): \
    0

`define FETCH_II2VC1R_FIELD(reg_data, field_name) \
    field_name == "DATA_TYPE" ?   `REG_DATA("II2VC1R", reg_data, 0, 16): \
    0

`define FETCH_II1VC2R_FIELD(reg_data, field_name) \
    field_name == "LINE_COUNT" ?   `REG_DATA("II1VC2R", reg_data, 16, 16): \
    field_name == "BYTE_COUNT" ?   `REG_DATA("II1VC2R", reg_data, 0, 16): \
    0

`define FETCH_II2VC2R_FIELD(reg_data, field_name) \
    field_name == "DATA_TYPE" ?   `REG_DATA("II2VC2R", reg_data, 0, 16): \
    0

`define FETCH_II1VC3R_FIELD(reg_data, field_name) \
    field_name == "LINE_COUNT" ?   `REG_DATA("II1VC3R", reg_data, 16, 16): \
    field_name == "BYTE_COUNT" ?   `REG_DATA("II1VC3R", reg_data, 0, 16): \
    0

`define FETCH_II2VC3R_FIELD(reg_data, field_name) \
    field_name == "DATA_TYPE" ?   `REG_DATA("II2VC3R", reg_data, 0, 16)[15:0]: \
    0

`endif // CSI_REGS_SVH_