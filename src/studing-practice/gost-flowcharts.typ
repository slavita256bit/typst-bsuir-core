#import "@preview/cetz:0.5.2"

// --- GOST PROPORTIONS & CONSTANTS ---
// Standard sizes scaled to CetZ units (1 unit = 1cm)
#let W_STD = 4.0
#let H_STD = 2.0
#let H_TERM = 1.0
#let R_CONN = 0.4

// --- SMART AUTO-SCALING TEXT ---
// Reduces font size by up to 5pt if the text height exceeds the box boundary.
// Also injects zero-width spaces around brackets and commas to allow natural wrapping.
#let fit-text(body, box-w, box-h, base-size: 10pt) = {
  context {
    let final-size = base-size - 5pt // Fallback minimum size
    
    // Test sizes from Base down to Base - 5pt
    for s in (0pt, 1pt, 2pt, 3pt, 4pt, 5pt) {
      let test-size = base-size - s
      let m = measure(block(width: box-w, text(size: test-size)[#body]))
      
      if m.height <= box-h {
        final-size = test-size
        break
      }
    }
    
    block(width: box-w, height: box-h, align(center + horizon)[
      #set text(size: final-size)
      // Allow natural wrapping around structural characters if manual \n is forgotten
      #show "(": it => sym.zws + it
      #show ",": it => it + sym.zws
      #body
    ])
  }
}

// --- SHAPE COMPONENTS ---

// 1. TERMINAL (Начало / Конец)
#let gost-term(name, pos, label, width: W_STD, height: H_TERM, ..args) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)
    rect((-width/2, -height/2), (width/2, height/2), radius: height/2, fill: white, ..args)
    
    content((0,0), fit-text(label, (width - 0.4) * 1cm, (height - 0.2) * 1cm))
    
    anchor("top", (0, height/2))
    anchor("bottom", (0, -height/2))
    anchor("left", (-width/2, 0))
    anchor("right", (width/2, 0))
  })
}

// 2. PROCESS / VARIABLES (Действие / Ув-Вых)
#let gost-proc(name, pos, label, width: W_STD, height: H_STD, ..args) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)
    rect((-width/2, -height/2), (width/2, height/2), fill: white, ..args)
    
    content((0,0), fit-text(label, (width - 0.2) * 1cm, (height - 0.2) * 1cm))
    
    anchor("top", (0, height/2))
    anchor("bottom", (0, -height/2))
    anchor("left", (-width/2, 0))
    anchor("right", (width/2, 0))
  })
}

// 3. PREDEFINED PROCESS (Вызов функции) - Strict 1:6:1 Ratio
#let gost-preproc(name, pos, title, signature, width: W_STD, height: H_STD, ..args) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)
    rect((-width/2, -height/2), (width/2, height/2), fill: white, ..args)
    
    let dx = width / 2 - (width / 8)
    line((-dx, -height/2), (-dx, height/2), ..args)
    line((dx, -height/2), (dx, height/2), ..args)
    
    let inner-w = (dx * 2 - 0.2) * 1cm
    let half-h = (height/2 - 0.1) * 1cm
    
    content((0, 0.45), fit-text(title, inner-w, half-h))
    content((0, -0.45), fit-text(signature, inner-w, half-h))
    
    anchor("top", (0, height/2))
    anchor("bottom", (0, -height/2))
    anchor("left", (-width/2, 0))
    anchor("right", (width/2, 0))
  })
}

// 4. DECISION (Условие / Решение - Ромб)
#let gost-rhomb(name, pos, label, width: W_STD, height: H_STD, ..args) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)
    line((0, height/2), (width/2, 0), (0, -height/2), (-width/2, 0), close: true, fill: white, ..args)
    
    content((0,0), fit-text(label, (width/2) * 1cm, (height/2) * 1cm))
    
    anchor("top", (0, height/2))
    anchor("bottom", (0, -height/2))
    anchor("left", (-width/2, 0))
    anchor("right", (width/2, 0))
  })
}

// 5. INPUT / OUTPUT (Ввод / Вывод - Параллелограмм)
// Extreme X points are strictly exactly width/2 and -width/2 matching rectangular blocks
#let gost-io(name, pos, label, width: W_STD, height: H_STD, ..args) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)
    let dx = width / 6 // Slant amount
    
    line((-width/2 + dx, height/2), (width/2, height/2),
         (width/2 - dx, -height/2), (-width/2, -height/2), close: true, fill: white, ..args)
    
    content((0,0), fit-text(label, (width - dx*2 - 0.2) * 1cm, (height - 0.2) * 1cm))
    
    anchor("top", (0, height/2))
    anchor("bottom", (0, -height/2))
    anchor("left", (-width/2 + dx/2, 0))
    anchor("right", (width/2 - dx/2, 0))
  })
}

// 6. CONNECTOR (Переход)
#let gost-conn(name, pos, label, radius: R_CONN, ..args) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)
    circle((0,0), radius: radius, fill: white, ..args)
    content((0,0), align(center + horizon)[#label])
    
    anchor("top", (0, radius))
    anchor("bottom", (0, -radius))
    anchor("left", (-radius, 0))
    anchor("right", (radius, 0))
  })
}

// 7. COMPACT ANNOTATION (Комментарий)
// Automatically measures height based on text and draws a precise GOST [ bracket.
#let gost-annot(name, pos, text-content, text-width: 4.5, open: "left", ..args) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)
    let w = text-width * 1cm
    let lip = 0.2
    
    if open == "left" {
      content((0.2, 0), name: "txt", anchor: "west", box(width: w, align(left)[#text-content]))
      line(
        (rel: (lip, 0), to: "txt.north-west"), 
        "txt.north-west", 
        "txt.south-west", 
        (rel: (lip, 0), to: "txt.south-west"), 
        stroke: 1pt, ..args
      )
      anchor("tie", "txt.west")
    } else {
      content((-0.2, 0), name: "txt", anchor: "east", box(width: w, align(left)[#text-content]))
      line(
        (rel: (-lip, 0), to: "txt.north-east"), 
        "txt.north-east", 
        "txt.south-east", 
        (rel: (-lip, 0), to: "txt.south-east"), 
        stroke: 1pt, ..args
      )
      anchor("tie", "txt.east")
    }
  })
}

// Helper: Dashed line linking block to annotation
#let gost-annot-link(from, to, ..args) = {
  import cetz.draw: *
  line(from, to, stroke: (dash: "dashed", thickness: 1pt), ..args)
}

// Helper: Solid black arrowhead lines for paths
#let gost-arrow(..pts) = {
  import cetz.draw: *
  let args = pts.named()
  // Triangle end-mark with solid black fill and no stroke boundary
  let mark-def = args.at("mark", default: (end: "triangle", fill: black, stroke: none, length: 0.25, width: 0.25))
  args.remove("mark", default: none)
  line(..pts.pos(), mark: mark-def, ..args)
}
