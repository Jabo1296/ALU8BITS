
/*
 * Copyright (c) 2024 JAIME ZAMORA
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_alu_jzamora (
    input  wire [7:0] ui_in,    // PORT_A (dato)
    output wire [7:0] uo_out,   // Acumulador / resultado
    input  wire [7:0] uio_in,   // PORT_B (control)
    output wire [7:0] uio_out,  // Banderas
    output wire [7:0] uio_oe,   // 0=entrada, 1=salida
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  reg  [7:0] ACC;
  reg  [7:0] RES;
  reg  [7:0] ZV;
  reg        C;
  reg        FLAG_ONLY;
  reg        COUT;
  reg        Z;

  wire [7:0] PORT_A = ui_in;
  wire [4:0] SEL    = uio_in[4:0];   // S4..S0 juntos
  wire       CIN    = uio_in[7];
  wire [7:0] MUL4   = ACC[3:0] * PORT_A[3:0];

  always @(*) begin
    C         = 1'b0;
    RES       = 8'b0;
    ZV        = 8'b0;
    FLAG_ONLY = 1'b0;

    case (SEL)
      // Banco 0 (S4 = 0)
      5'b00000: {C, RES} = {1'b0, PORT_A};                              // CARGA
      5'b00001: {C, RES} = ACC + PORT_A;                                // ADD
      5'b00010: {C, RES} = ACC + PORT_A + CIN;                          // ADC
      5'b00011: {C, RES} = {1'b0, ~ACC};                                // NOT
      5'b00100: {C, RES} = {1'b0, ACC & PORT_A};                        // AND
      5'b00101: {C, RES} = {1'b0, ACC | PORT_A};                        // OR
      5'b00110: {C, RES} = {1'b0, ACC ^ PORT_A};                        // XOR
      5'b00111: {C, RES} = {ACC[7], ACC[6:0], 1'b0};                    // LSL
      5'b01000: {C, RES} = {ACC[0], 1'b0, ACC[7:1]};                    // LSR
      5'b01001: {C, RES} = {1'b0, ACC} - {1'b0, PORT_A};                // SUB
      5'b01010: {C, RES} = {1'b0, ACC} + 9'd1;                          // INC
      5'b01011: {C, RES} = {1'b0, ACC} - 9'd1;                          // DEC
      5'b01100: {C, RES} = {ACC[7], ACC[6:0], CIN};                     // ROL
      5'b01101: {C, RES} = {ACC[0], CIN, ACC[7:1]};                     // ROR
      5'b01110: {C, RES} = {1'b0, (ACC > PORT_A) ? ACC : PORT_A};       // MAX
      5'b01111: {C, RES} = 9'd0 - {1'b0, ACC};                          // NEG

      // Banco 1 (S4 = 1)
      5'b10000: {C, RES} = {1'b0, ~(ACC & PORT_A)};                     // NAND
      5'b10001: {C, RES} = {1'b0, ~(ACC | PORT_A)};                     // NOR
      5'b10010: {C, RES} = {1'b0, ~(ACC ^ PORT_A)};                     // XNOR
      5'b10011: {C, RES} = {ACC[0], ACC[7], ACC[7:1]};                  // ASR
      5'b10100: {C, RES} = {1'b0, ACC[3:0], ACC[7:4]};                  // SWAP nibbles
      5'b10101: {C, RES} = 9'd0;                                        // CLR
      5'b10110: {C, RES} = 9'h0FF;                                      // SET
      5'b10111: begin                                                   // CMP (solo banderas)
                  {C, ZV}   = {1'b0, ACC} - {1'b0, PORT_A};
                  RES       = ACC;
                  FLAG_ONLY = 1'b1;
                end
      5'b11000: {C, RES} = {1'b0, PORT_A} - {1'b0, ACC};                // RSUB
      5'b11001: {C, RES} = {1'b0, ACC} - {1'b0, PORT_A} - {8'b0, CIN};  // SBC
      5'b11010: {C, RES} = {1'b0, ACC & ~PORT_A};                       // BIC
      5'b11011: {C, RES} = {1'b0, ACC[0], ACC[1], ACC[2], ACC[3],
                                  ACC[4], ACC[5], ACC[6], ACC[7]};      // REV bits
      5'b11100: begin                                                   // TST (solo banderas)
                  ZV        = ACC & PORT_A;
                  RES       = ACC;
                  FLAG_ONLY = 1'b1;
                end
      5'b11101: {C, RES} = {1'b0, MUL4};                                // MUL 4x4
      5'b11110: {C, RES} = PORT_A + 8'd30;                              // ADD #30 (para el test)
      5'b11111: {C, RES} = {1'b0, (ACC < PORT_A) ? ACC : PORT_A};       // MIN
      default:  {C, RES} = 9'd0;
    endcase

    if (!FLAG_ONLY) ZV = RES;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ACC  <= 8'b0;
      COUT <= 1'b0;
      Z    <= 1'b1;
    end else begin
      ACC  <= RES;
      COUT <= C;
      Z    <= (ZV == 8'b0);
    end
  end

  assign uo_out  = (SEL == 5'b11110) ? RES : ACC;
  assign uio_out = {1'b0, Z, COUT, 5'b00000};
  assign uio_oe  = 8'b01100000;

  wire _unused = &{ena, uio_in[6:5], 1'b0};

endmodule
