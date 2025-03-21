/**************************************
@ filename    : clk_rst_gen.sv
@ author      : yyrwkk
@ create time : 2025/03/21 21:59:52
@ version     : v1.0.0
**************************************/
`ifndef CLK_RST_GEN__SV
`define CLK_RST_GEN__SV 
/** 
 * =====================================================
 * @example clk 
 * reg clk ;
 * real clk_freq = 100;  // unit: Mhz
 * `clk_gen( clk, 0, clk_freq, 0 , 0.5, 0, 0 )
 * =====================================================
 * @example rst_n 
 * wire rst_n ;
 * `rst_gen( rst_n,0,0,$urandom_range(100,300))
 * =====================================================
 */ 

`define clk_gen(CLK,CLK_INIT,FREQ,PHASE,DUTY,JITTER_MIN,JITTER_MAX)           \
 initial begin                                                                \
    real freq,duty,period,period_jitter,duty_cyc_pre,duty_cyc_pst,phase;      \
    freq   = FREQ          ;                                                  \
    duty   = DUTY          ;                                                  \
    period = 1000*1.00/freq;                                                  \
    period_jitter = period + $urandom_range(JITTER_MIN,JITTER_MAX);           \
    if( PHASE == -1 ) begin                                                   \
        phase = $urandom_range(0,500);                                        \
    end else begin                                                            \
        phase  = PHASE ;                                                      \
    end                                                                       \
    CLK           = CLK_INIT                    ;                             \
    duty_cyc_pre  = period_jitter * duty        ;                             \
    duty_cyc_pst  = period_jitter * ( 1 - duty );                             \
    #(int'(phase));                                                           \
    forever begin                                                             \
        #(int'(duty_cyc_pre));                                                \
        CLK = ~CLK    ;                                                       \
        #(int'(duty_cyc_pst));                                                \
        CLK = ~CLK    ;                                                       \
    end                                                                       \
end

`define rst_gen(RST,RST_VALUE,RST_BEGIN_TIME,RST_RELEASE_TIME)                \
initial begin                                                                 \
    int rst_begin_time,rst_release_time;                                      \
    rst_begin_time   = RST_BEGIN_TIME  ;                                      \
    rst_release_time = RST_RELEASE_TIME;                                      \
    force RST = !RST_VALUE ;                                                  \
    #(int'(rst_begin_time));                                                  \
    force RST = RST_VALUE;                                                    \
    #(int'(rst_release_time));                                                \
    force RST = !RST_VALUE ;                                                  \
end

`endif 

