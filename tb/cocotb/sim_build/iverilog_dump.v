module iverilog_dump();
initial begin
    $dumpfile("soc_top.fst");
    $dumpvars(0, soc_top);
end
endmodule
