/*
 * Copyright (c) 2024 JAIME ZAMORA
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_alu_jzamora (
    input  wire [7:0] ui_in,    // PORT_A (dato)
    output wire [7:0] uo_out,   // Acumulador
    input  wire [7:0] uio_in,   // PORT_B (control)
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    reg  [7:0] ACC;
    reg  [7:0] RES;
    reg        C;
    reg        COUT;
    reg        Z;

    wire [7:0] PORT_A = ui_in;
    wire [3:0] S      = uio_in[3:0];
    wire       CIN    = uio_in[4];

    always @(*) begin
        case (S)
            4'b0000: {C, RES} = {1'b0, PORT_A};
            4'b0001: {C, RES} = ACC + PORT_A;
            4'b0010: {C, RES} = ACC + PORT_A + CIN;
            4'b0011: {C, RES} = {1'b0, ~ACC};
            4'b0100: {C, RES} = {1'b0, ACC & PORT_A};
            4'b0101: {C, RES} = {1'b0, ACC | PORT_A};
            4'b0110: {C, RES} = {1'b0, ACC ^ PORT_A};
            4'b0111: {C, RES} = {ACC[7], ACC[6:0], 1'b0};
            4'b1000: {C, RES} = {ACC[0], 1'b0, ACC[7:1]};
            default: {C, RES} = 9'b0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ACC  <= 8'b0;
            COUT <= 1'b0;
            Z    <= 1'b1;
        end else begin
            ACC  <= RES;
            COUT <= C;
            Z    <= (RES == 8'b0);
        end
    end

    assign uo_out  = ACC;
    assign uio_out = {1'b0, Z, COUT, 5'b00000};
    assign uio_oe  = 8'b01100000;   // uio[6:5] salidas, el resto entradas

    wire _unused = &{ena, uio_in[7:5], 1'b0};

endmodule
