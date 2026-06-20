`timescale 1ns / 1ps
// =============================================================
// system_top.v - Gabungan UART Relay (bidirectional) + Dual Watchdog
// Platform : PYNQ-Z2 (Zynq-7020), Vivado 2024.2
//
// Berisi dua subsistem independen:
//   1. UART relay bidirectional - RasPi <-> Jetson  (PMODA)
//   2. dual_watchdog - monitor heartbeat FC & Jetson (PMODB)
//
// Keduanya hanya berbagi clk 125 MHz. Pin terpisah total.
// =============================================================

module sistem_lengkap (
    input  wire clk,            // 125 MHz dari H16

    // ── UART Relay bidirectional (PMODA) ────────────────
    input  wire rxd_raspi,      // dari RasPi TX   (JA1_P / Y18)
    output wire txd_jetson,     // ke Jetson RX    (JA2_P / Y16)
    input  wire rxd_jetson,     // dari Jetson TX  (JA3_P / U18)
    output wire txd_raspi,      // ke RasPi RX     (JA4_P / W18)

    // ── Watchdog (PMODB) ────────────────────────────────
    input  wire heartbeat_fc,       // dari RasPi GPIO  (JB1_P / W14)
    input  wire heartbeat_jetson,   // dari Jetson GPIO (JB3_P / V16)
    output wire reset_n_fc,         // reset ke FC      (JB2_P / T11)
    input  wire initialize          // tombol clear error (BTN0 / D19)
);

// =============================================================
// RESET INTERNAL untuk UART (255 cycle pertama saat startup)
// =============================================================
reg        uart_rst = 1;
reg [7:0]  rst_cnt  = 0;
always @(posedge clk) begin
    if (rst_cnt < 255) begin
        rst_cnt  <= rst_cnt + 1;
        uart_rst <= 1;
    end else begin
        uart_rst <= 0;
    end
end

// Prescale UART: 115200 baud @ 125MHz = 136
wire [15:0] prescale = 16'd136;

// =============================================================
// SUBSISTEM 1: UART RELAY BIDIRECTIONAL
// =============================================================

// ── Arah 1: RasPi -> Jetson ─────────────────────────────
wire [7:0] data_r2j;
wire       valid_r2j;
wire       ready_r2j;

uart_rx_raspi #(.DATA_WIDTH(8)) uart_rx_raspi_inst (
    .clk          (clk),
    .rst          (uart_rst),
    .rxd_raspi    (rxd_raspi),
    .m_axis_tdata (data_r2j),
    .m_axis_tvalid(valid_r2j),
    .m_axis_tready(ready_r2j),
    .prescale     (prescale),
    .busy         (),
    .overrun_error(),
    .frame_error  ()
);

uart_tx_jetson #(.DATA_WIDTH(8)) uart_tx_jetson_inst (
    .clk          (clk),
    .rst          (uart_rst),
    .s_axis_tdata (data_r2j),
    .s_axis_tvalid(valid_r2j),
    .s_axis_tready(ready_r2j),
    .txd_jetson   (txd_jetson),
    .prescale     (prescale),
    .busy         ()
);

// ── Arah 2: Jetson -> RasPi ─────────────────────────────
wire [7:0] data_j2r;
wire       valid_j2r;
wire       ready_j2r;

uart_rx_jetson #(.DATA_WIDTH(8)) uart_rx_jetson_inst (
    .clk          (clk),
    .rst          (uart_rst),
    .rxd_raspi    (rxd_jetson),   // port bernama rxd_raspi, diisi sinyal jetson
    .m_axis_tdata (data_j2r),
    .m_axis_tvalid(valid_j2r),
    .m_axis_tready(ready_j2r),
    .prescale     (prescale),
    .busy         (),
    .overrun_error(),
    .frame_error  ()
);

uart_tx_raspi #(.DATA_WIDTH(8)) uart_tx_raspi_inst (
    .clk          (clk),
    .rst          (uart_rst),
    .s_axis_tdata (data_j2r),
    .s_axis_tvalid(valid_j2r),
    .s_axis_tready(ready_j2r),
    .txd_raspi    (txd_raspi),
    .prescale     (prescale),
    .busy         ()
);

// =============================================================
// SUBSISTEM 2: DUAL WATCHDOG (FC + Jetson)
// =============================================================
wire fc_error;
wire fc_stuck_high, fc_stuck_low, fc_bad_rise;
wire jetson_error;
wire jetson_stuck_high, jetson_stuck_low, jetson_bad_rise;

dual_watchdog dual_watchdog_inst (
    .clk              (clk),
    .initialize       (initialize),
    .heartbeat_fc     (heartbeat_fc),
    .heartbeat_jetson (heartbeat_jetson),
    .reset_n_fc       (reset_n_fc),
    .fc_error         (fc_error),
    .fc_stuck_high    (fc_stuck_high),
    .fc_stuck_low     (fc_stuck_low),
    .fc_bad_rise      (fc_bad_rise),
    .jetson_error     (jetson_error),
    .jetson_stuck_high(jetson_stuck_high),
    .jetson_stuck_low (jetson_stuck_low),
    .jetson_bad_rise  (jetson_bad_rise)
);

endmodule