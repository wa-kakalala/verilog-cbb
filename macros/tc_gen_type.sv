/**************************************
@ filename    : tc_gen_type.sv
@ author      : yyrwkk
@ create time : 2025/03/24 23:13:02
@ version     : v1.0.0
**************************************/
`ifndef TC_GEN_TYPE__SV
`define TC_GEN_TYPE__SV

/**
 * @brief : from the sequence "aabbbcc_seq" to generate a testcase "aabbbcc"
 */

`define TC_GEN_TYPE(TC_NAME,SQR_PATH,TC_BASE)                                                             \
    class ``TC_NAME`` extends ``TC_BASE``;                                                                \
        `uvm_component_utils(``TC_NAME``)                                                                 \
                                                                                                          \
        function new(string name=`"``TC_NAME```",uvm_component parent);                                   \
            super.new(name,parent);                                                                       \
        endfunction : new                                                                                 \
                                                                                                          \
        virtual function void build_phase(uvm_phase phase);                                               \
            super.build_phase(phase);                                                                     \
            uvm_config_db#(uvm_object_wrapper)::set(this,`"``SQR_PATH``.main_phase`",                     \
                "default_sequence", ``TC_NAME``_seq::type_id::get());                                     \
        endfunction : build_phase                                                                         \
                                                                                                          \
        virutal function void connect_phase(uvm_phase phase);                                             \
        endfunction : connect_phase                                                                       \
    endclass 

`endif