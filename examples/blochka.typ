#import "@preview/cetz:0.5.2"
#import "gost-flowcharts.typ": *

#set text(font: "Times New Roman", size: 10pt)

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    // ==========================================
    // 1. GRID & LAYOUT SETUP
    // ==========================================
    let col1 = 0
    let col2 = 8
    
    // Column 1 Y-steps (Dynamic spacing for annotations!)
    let y0 = 0
    let y1 = -2.8
    let y2 = -8.0  // Huge jump down because 'annot1' is ~5 units tall
    let y3 = -13.0 // Huge jump down because 'annot2' is ~5 units tall
    let y4 = -15.8
    let y5 = -18.6
    let y6 = -21.4
    let y7 = -24.2

    // Column 2 Y-steps (Standard compact spacing)
    let yc0 = 0
    let yc1 = -2.8
    let yc2 = -5.6
    let yc3 = -8.4
    let yc4 = -11.2
    let yc5 = -14.0
    let yc6 = -16.8
    let yc7 = -19.6

    // ==========================================
    // 2. COLUMN 1 BLOCKS & ANNOTATIONS
    // ==========================================

    gost-term("start", (col1, y0), [Пачатак])

    gost-proc("vars", (col1, y1), [
      Ув: char target_illness\[MAX\]\
      Child \*children - масіў\
      Вых: int (main)\
      int number_of_children = 0;\
      int result_count = 0;\
      Child \*c_w_t_illness = NULL;
    ])

    // Annotation 1
    gost-annot("annot1", (col1 + 2.5, y1), [
      #set text(size: 8pt)
      #set par(leading: 0.5em)
      *struct Child {*\
      char first_name\[MAX_ALLOW\];\
      char surname\[MAX_ALLOW\];\
      int age;\
      int was_hospitalized;\
      MedicalInfo health_info; };\
      \
      *union MedicalInfo {*\
      LocalRecord local;\
      HospitalRecord hospital; };
    ], text-width: 4.5, open: "left")
    gost-annot-link("vars.right", "annot1.tie")

    // Notice the STRICT RULE: \n before '(' and after commas!
    gost-preproc("choose_input", (col1, y2), [выклік ф.], [choose_input\n(&children,\n&number_of_children)])

    // Annotation 2
    gost-annot("annot2", (col1 + 2.5, y2), [
      #set text(size: 8pt)
      #set par(leading: 0.5em)
      *struct HospitalRecord {*\
      char illness\[MAX_ALLOW\];\
      char att_doctor\[MAX_ALLOW\];\
      char adress\[MAX_ALLOW\];\
      int hospital_number; };\
      \
      *struct LocalRecord {*\
      char illness\[MAX_ALLOW\];\
      char loc_doctor\[MAX_ALLOW\]; };
    ], text-width: 4.5, open: "left")
    gost-annot-link("choose_input.right", "annot2.tie")

    gost-preproc("out_child1", (col1, y3), [выклік ф.], [output_Child\n(children,\nnumber_of_children)])
    gost-preproc("choose_out1", (col1, y4), [выклік ф.], [choose_output\n(children,\nnumber_of_children)])
    
    gost-io("print1", (col1, y5), [Вывад:\n"Enter the target illness: "])
    
    gost-preproc("read_line", (col1, y6), [выклік ф.], [read_line\n(target_illness,\nMAX_ALLOWED, stdin)])
    
    gost-conn("conn_A1", (col1, y7), [A])

    // ==========================================
    // 3. COLUMN 2 BLOCKS
    // ==========================================

    gost-conn("conn_A2", (col2, yc0), [A])
    
    gost-preproc("analysis", (col2, yc1), [выклік ф.], [children_analysis\n(children,\nnumber_of_children,\n&c_w_t_illness, ...)])
    
    gost-rhomb("cond", (col2, yc2), [!result_count])
    
    gost-preproc("out_child2", (col2, yc3), [выклік ф.], [output_Child\n(c_w_t_illness,\nresult_count)])
    
    gost-preproc("choose_out2", (col2, yc4), [выклік ф.], [choose_output\n(c_w_t_illness,\nresult_count)])
    
    gost-preproc("free1", (col2, yc5), [выклік ф.], [free\n(children)])
    
    gost-preproc("free2", (col2, yc6), [выклік ф.], [free\n(c_w_t_illness)])
    
    gost-conn("conn_C", (col2, yc7), [C])

    // Off-column connector for True branch
    gost-conn("conn_B", (col2 + 3.0, yc2), [B])


    // ==========================================
    // 4. ROUTING / CONNECTING ARROWS
    // ==========================================
    
    // Col 1 Flow
    gost-arrow("start.bottom", "vars.top")
    gost-arrow("vars.bottom", "choose_input.top")
    gost-arrow("choose_input.bottom", "out_child1.top")
    gost-arrow("out_child1.bottom", "choose_out1.top")
    gost-arrow("choose_out1.bottom", "print1.top")
    gost-arrow("print1.bottom", "read_line.top")
    gost-arrow("read_line.bottom", "conn_A1.top")

    // Col 2 Flow
    gost-arrow("conn_A2.bottom", "analysis.top")
    gost-arrow("analysis.bottom", "cond.top")
    
    // False branch (down)
    gost-arrow("cond.bottom", "out_child2.top")
    content((rel: (0.3, -0.3), to: "cond.bottom"), [Не], anchor: "north-west")
    
    gost-arrow("out_child2.bottom", "choose_out2.top")
    gost-arrow("choose_out2.bottom", "free1.top")
    gost-arrow("free1.bottom", "free2.top")
    gost-arrow("free2.bottom", "conn_C.top")

    // True branch (right)
    gost-arrow("cond.right", "conn_B.left")
    content((rel: (0.3, 0.3), to: "cond.right"), [Так], anchor: "south-west")
  })
]
