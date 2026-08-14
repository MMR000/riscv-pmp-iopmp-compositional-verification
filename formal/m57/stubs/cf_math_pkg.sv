// Formal-only Yosys-compatible stub.
`ifndef CF_MATH_PKG
`define CF_MATH_PKG
package cf_math_pkg;
  function automatic integer idx_width(input integer num_idx);
    begin
      if (num_idx > 1)
        idx_width = $clog2(num_idx);
      else
        idx_width = 1;
    end
  endfunction
endpackage
`endif
