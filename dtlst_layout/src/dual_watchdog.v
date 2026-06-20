`timescale 1ns / 1ps
// =============================================================
// Straka 2013 NASA USRP Internship Final Report
// "Implementing a Microcontroller Watchdog with an FPGA"
// Konversi VHDL → Verilog
// Platform target: PYNQ-Z2 (Zynq-7020), Vivado 2024.2
// Versi: FC dan Jetson 
// =============================================================

// =============================================================
// MODULE 1: custom_counter
// =============================================================
module custom_counter #(
    parameter integer COUNT         = 125_000_000, // 1000ms @ 125MHz
    parameter         EDGE_TYPE     = 1,
    parameter         COUNTER_DRIVE = 1,
    parameter         OUTPUT_HL     = 1,
    parameter integer TCNT_DUR      = 0
)(
    input  wire clk,
    input  wire reset,
    output reg  tcnt
);

// 27 bit cukup untuk 1000 (2^27 = 134_217_728)
reg [26:0] internal_count;
reg [26:0] assert_time;

wire reset_count = (internal_count == COUNT);

generate
    // KOMBINASI 1: posedge clock, rising edge reset
    if (COUNTER_DRIVE == 1 && EDGE_TYPE == 1) begin : gen_pos_rise

        always @(posedge clk or posedge reset) begin
            if (reset)
                internal_count <= 0;
            else begin
                if (reset_count) internal_count <= 0;
                else             internal_count <= internal_count + 1;
            end
        end

        always @(posedge clk or posedge reset) begin
            if (reset) begin
                tcnt        <= OUTPUT_HL[0];
                assert_time <= TCNT_DUR;
            end else begin
                if (reset_count) begin
                    tcnt        <= ~OUTPUT_HL[0];
                    assert_time <= 0;
                end else begin
                    if (assert_time == TCNT_DUR)
                        tcnt <= OUTPUT_HL[0];
                    else begin
                        assert_time <= assert_time + 1;
                        tcnt        <= ~OUTPUT_HL[0];
                    end
                end
            end
        end

    // KOMBINASI 2: posedge clock, falling edge reset
    end else if (COUNTER_DRIVE == 1 && EDGE_TYPE == 0) begin : gen_pos_fall

        always @(posedge clk or negedge reset) begin
            if (!reset)
                internal_count <= 0;
            else begin
                if (reset_count) internal_count <= 0;
                else             internal_count <= internal_count + 1;
            end
        end

        always @(posedge clk or negedge reset) begin
            if (!reset) begin
                tcnt        <= OUTPUT_HL[0];
                assert_time <= TCNT_DUR;
            end else begin
                if (reset_count) begin
                    tcnt        <= ~OUTPUT_HL[0];
                    assert_time <= 0;
                end else begin
                    if (assert_time == TCNT_DUR)
                        tcnt <= OUTPUT_HL[0];
                    else begin
                        assert_time <= assert_time + 1;
                        tcnt        <= ~OUTPUT_HL[0];
                    end
                end
            end
        end

    // KOMBINASI 3: negedge clock, rising edge reset
    end else if (COUNTER_DRIVE == 0 && EDGE_TYPE == 1) begin : gen_neg_rise

        always @(negedge clk or posedge reset) begin
            if (reset)
                internal_count <= 0;
            else begin
                if (reset_count) internal_count <= 0;
                else             internal_count <= internal_count + 1;
            end
        end

        always @(negedge clk or posedge reset) begin
            if (reset) begin
                tcnt        <= OUTPUT_HL[0];
                assert_time <= TCNT_DUR;
            end else begin
                if (reset_count) begin
                    tcnt        <= ~OUTPUT_HL[0];
                    assert_time <= 0;
                end else begin
                    if (assert_time == TCNT_DUR)
                        tcnt <= OUTPUT_HL[0];
                    else begin
                        assert_time <= assert_time + 1;
                        tcnt        <= ~OUTPUT_HL[0];
                    end
                end
            end
        end

    // KOMBINASI 4: negedge clock, falling edge reset
    end else begin : gen_neg_fall

        always @(negedge clk or negedge reset) begin
            if (!reset)
                internal_count <= 0;
            else begin
                if (reset_count) internal_count <= 0;
                else             internal_count <= internal_count + 1;
            end
        end

        always @(negedge clk or negedge reset) begin
            if (!reset) begin
                tcnt        <= OUTPUT_HL[0];
                assert_time <= TCNT_DUR;
            end else begin
                if (reset_count) begin
                    tcnt        <= ~OUTPUT_HL[0];
                    assert_time <= 0;
                end else begin
                    if (assert_time == TCNT_DUR)
                        tcnt <= OUTPUT_HL[0];
                    else begin
                        assert_time <= assert_time + 1;
                        tcnt        <= ~OUTPUT_HL[0];
                    end
                end
            end
        end

    end
endgenerate

initial begin
    internal_count = 0;
    assert_time    = TCNT_DUR;
    tcnt           = OUTPUT_HL[0];
end

endmodule


// =============================================================
// MODULE 2: watchdog
// Versi: bad_rise dinonaktifkan, hanya stuck_low dan stuck_high
// =============================================================
module watchdog (
    input  wire heartbeat,
    input  wire clk,
    input  wire initialize,
    output wire error,
    output wire status,
    output wire stuck_high,
    output wire stuck_low,
    output wire bad_rise
);

wire no_falling_edge;
wire no_rising_edge;
wire bad_rising_edge;
reg  q_latch;
wire status_sig;

// Counter 1: FallingEdgeTimeout - deteksi stuck HIGH
custom_counter #(
    .COUNT        (125_000_000),  // 1000ms @ 125MHz
    .EDGE_TYPE    (0),
    .COUNTER_DRIVE(1),
    .OUTPUT_HL    (0),
    .TCNT_DUR     (5)
) falling_edge_timeout (
    .clk  (clk),
    .reset(heartbeat),
    .tcnt (no_falling_edge)
);

// Counter 2: RisingEdgeTimeout - deteksi stuck LOW / signal lost
custom_counter #(
    .COUNT        (125_000_000),  // 1000ms @ 125MHz
    .EDGE_TYPE    (1),
    .COUNTER_DRIVE(1),
    .OUTPUT_HL    (0),
    .TCNT_DUR     (5)
) rising_edge_timeout (
    .clk  (clk),
    .reset(heartbeat),
    .tcnt (no_rising_edge)
);

// bad_rise dinonaktifkan sementara
assign bad_rising_edge = 1'b0;

// OR gate: satu error cukup aktifkan status
assign status_sig = no_rising_edge | no_falling_edge;
assign status     = status_sig;

// Error latch permanen
always @(posedge status_sig or posedge initialize) begin
    if (initialize)
        q_latch <= 0;
    else
        q_latch <= 1;
end

assign error      = q_latch;
assign stuck_high = no_falling_edge;
assign stuck_low  = no_rising_edge;
assign bad_rise   = bad_rising_edge;

initial begin
    q_latch = 0;
end

endmodule


// =============================================================
// MODULE 3: dual_watchdog
// Versi: FC dg reset dan Jetson tanpa reset
// =============================================================
module dual_watchdog (
    input  wire clk,
    input  wire initialize,

    // Heartbeat FC
    input  wire heartbeat_fc,
    
    //Heartbeat Jetson
    input wire heartbeat_jetson,

    // Reset output
    output wire reset_n_fc,

    // Diagnostik FC
    output wire fc_error,
    output wire fc_stuck_high,
    output wire fc_stuck_low,
    output wire fc_bad_rise,
    
    // Diagnostik Jetson
    output wire jetson_error,
    output wire jetson_stuck_high,
    output wire jetson_stuck_low,
    output wire jetson_bad_rise
);

wire fc_status;
wire jetson_status;

// Watchdog FC
watchdog watchdog_fc (
    .heartbeat  (heartbeat_fc),
    .clk        (clk),
    .initialize (initialize),
    .error      (fc_error),
    .status     (fc_status),
    .stuck_high (fc_stuck_high),
    .stuck_low  (fc_stuck_low),
    .bad_rise   (fc_bad_rise)
);

//Wathcdog Jetson
watchdog watchdog_jetson (
    .heartbeat  (heartbeat_jetson),
    .clk        (clk),
    .initialize (initialize),
    .error      (jetson_error),
    .status     (jetson_status),
    .stuck_high (jetson_stuck_high),
    .stuck_low  (jetson_stuck_low),
    .bad_rise   (jetson_bad_rise)
);

// Reset active LOW
assign reset_n_fc = ~fc_status;

endmodule
