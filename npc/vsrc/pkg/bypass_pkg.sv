package bypass_pkg;
  typedef struct packed {
    logic             valid   ;
    isa_pkg::word_t   pc      ;
  } pc_fwd_t;
endpackage
