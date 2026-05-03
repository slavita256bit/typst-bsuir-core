#import "@preview/cetz:0.5.0"

#let GRID_DX = 1.5
#let GRID_DY = 1.5

// Функция конвертации виртуальных координат (Колонка, Строка) в координаты CetZ
// x_col: от 0 до бесконечности (слева направо)
// y_row: от 0 до бесконечности (сверху ВНИЗ)
#let g-pt(c, r) = (c * GRID_DX, -r * GRID_DY)

// Для удобства: получение только X или только Y
#let g-x(c) = c * GRID_DX
#let g-y(r) = -r * GRID_DY

// ==========================================
// 1. БАЗОВЫЙ ЛОГИЧЕСКИЙ ВЕНТИЛЬ
// ==========================================
#let logic-gate(
  name, symbol, pos,
  inputs: 2,
  inv-in: (), inv-out: false,
  width: 1,
  pin-step: 0.5
) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)

    let span = (inputs - 1) * pin-step
    let H = calc.max(1.5, span + 0.8)
    let R = 0.1

    rect((0, 0), (width, -H), fill: white)
    content((width / 2, -0.35), text(size: 11pt)[#symbol])

    let start-y = -H / 2 + span / 2
    for i in range(inputs) {
      let pin-y = start-y - i * pin-step
      let pin-num = i + 1

      if pin-num in inv-in {
        circle((0, pin-y), radius: R, fill: white)
        anchor("in-" + str(pin-num), (-R, pin-y))
      } else {
        anchor("in-" + str(pin-num), (0, pin-y))
      }
    }

    let out-y = -H / 2
    if inv-out {
      circle((width, out-y), radius: R, fill: white)
      anchor("out", (width + R, out-y))
    } else {
      anchor("out", (width, out-y))
    }
    anchor("default", (0, 0))
  })
}

// ==========================================
// 2. МУЛЬТИПЛЕКСОР
// ==========================================
#let mux(
  name,                 // Имя элемента
  pos,                  // Координата верхнего левого угла
  data-inputs: 4, addr-inputs: 2,
  data-label: "D", addr-label: "A",
  inv-out: false,
  width: 2, label-width: 0.5, pin-step: 0.5
) = {
  import cetz.draw: *
  group(name: name, {
    translate(pos)

    let data-h = data-inputs * pin-step
    let addr-h = addr-inputs * pin-step
    let H = data-h + addr-h + 1
    let y-split = -data-h - 0.5
    let R = 0.1

    rect((0, 0), (width, -H), fill: white)
    line((label-width, 0), (label-width, -H))
    line((0, y-split), (label-width, y-split))

    content(((label-width + width) / 2, -0.4), text(size: 10pt)[MUX])

    for i in range(data-inputs) {
      let y = - (i + 1) * pin-step
      content((label-width / 2, y), text(size: 8pt, style: "italic")[#data-label#i])
      anchor("in-d" + str(i), (0, y))
    }

    for i in range(addr-inputs) {
      let y = y-split - (i + 1) * pin-step
      content((label-width / 2, y), text(size: 8pt, style: "italic")[#addr-label#i])
      anchor("in-a" + str(i), (0, y))
    }

    let out-y = -H / 2
    if inv-out {
      circle((width + R, out-y), radius: R, fill: white)
      anchor("out", (width + 2 * R, out-y))
    } else {
      anchor("out", (width, out-y))
    }
    anchor("default", (0, 0))
  })
}
// ==========================================
// 3. ПРОВОДА
// ==========================================
#let wire(
  from, to, routing: "Z", z-fract: 50%, dot: none, ..style
) = {
  import cetz.draw: *
  let pts = ()
  if type(routing) == array { pts = (from, ..routing, to) }
  else if routing == "-|" { pts = (from, (from, "-|", to), to) }
  else if routing == "|-" { pts = (from, (from, "|-", to), to) }
  else if routing == "Z" {
    let pt2 = (from, z-fract, (from, "-|", to))
    pts = (from, pt2, (pt2, "|-", to), to)
  } else { pts = (from, to) }

  line(..pts, ..style)

  let r = 0.05
  if dot in ("start", "both") { circle(from, radius: r, fill: black) }
  if dot in ("end", "both")   { circle(to, radius: r, fill: black) }
}

// ==========================================
// 4. ЕДИНАЯ ШИНА И ЕЕ ИНТЕРФЕЙС
// ==========================================

// Отрисовка магистрали шины (теперь поддерживает ломаные линии через верх)
#let draw-bus(..pts) = {
  cetz.draw.line(..pts.pos(), stroke: 2pt)
}

// Ввод простого сигнала в шину
#let bus-in(bus-x, y, label, num) = {
  import cetz.draw: *
  let start-x = bus-x - 2.5
  wire((start-x, y), (bus-x, y), routing: "direct")
  content((start-x + 0.2, y + 0.3), label, anchor: "east")
  content((bus-x - 0.1, y + 0.15), text(size: 8pt)[#num], anchor: "south-east")
}

// Ввод сигнала с инверсией
#let bus-in-inv(bus-x, y-dir, label, num-dir, num-inv, basis: "NOT") = {
  import cetz.draw: *
  let y-inv = y-dir - 1.0
  let y-inv-out = y-dir - 1.25
  let split-x = bus-x - 2.0
  let gate-x = bus-x - 1.2

  wire((split-x - 0.5, y-dir), (bus-x, y-dir), routing: "direct")
  content((split-x - 0.1, y-dir + 0.3), label, anchor: "east")
  content((bus-x - 0.1, y-dir + 0.15), text(size: 8pt)[#num-dir], anchor: "south-east")

  circle((split-x, y-dir), radius: 0.05, fill: black)

  let sym = "1"; let inps = 1
  if basis == "NAND" { sym = "&"; inps = 2 }
  if basis == "NOR"  { sym = "1"; inps = 2 }

  let gate-name = "inv_gate_" + str(num-inv)
  logic-gate(gate-name, sym, (gate-x, y-inv + 0.5), inputs: inps, inv-out: true)

  wire((split-x, y-dir), (split-x, y-inv-out), routing: "direct")
  if inps == 1 {
    wire((split-x, y-inv-out), gate-name + ".in-1", routing: "direct")
  } else {
    let branch-x = split-x + 0
    wire((split-x, y-inv), (branch-x, y-inv), routing: "direct")
    circle((branch-x, y-inv), radius: 0.05, fill: black)
    wire((branch-x, y-inv), gate-name + ".in-1", routing: "|-")
    wire((branch-x, y-inv), gate-name + ".in-2", routing: "|-")
  }

  wire(gate-name + ".out", (bus-x, y-inv-out), routing: "direct")
  content((bus-x - 0.1, y-inv-out + 0.1), text(size: 8pt)[#num-inv], anchor: "south-east")
}

// Взятие сигнала из шины
#let bus-tap(bus-x, target, num, routing: "|-", z-fract: 50%) = {
  import cetz.draw: *
  let start-coord = ((bus-x, 0), "|-", target)

  wire(start-coord, target, routing: routing, z-fract: z-fract, dot: "start")

  content(
    (rel: (0.1, 0.15), to: start-coord),
    text(size: 8pt)[#num],
    anchor: "south-west"
  )
}

// ==========================================
// ФУНКЦИЯ ДЛЯ РАЗВЕТВЛЕНИЙ (ВИЛКА)
// ==========================================
#let wire-fork(from, targets, z-fract: 50%) = {
  import cetz.draw: *

  // Находим точку перегиба (X берем по z-fract, Y от источника)
  let elbow = (from, z-fract, (from, "-|", targets.first()))

  // Горизонтальный сегмент от источника до локтя
  line(from, elbow)

  // Проходим по всем целям (важно передавать их по порядку сверху вниз)
  for (i, target) in targets.enumerate() {
    let junction = (elbow, "|-", target) // Точка на стволе ровно напротив пина

    line(junction, target) // Горизонтальный отрезок от ствола к пину

    if i == 0 {
      line(elbow, junction) // Ствол от перегиба до первой цели (Г-угол, точка не нужна)
    } else {
      let prev-junction = (elbow, "|-", targets.at(i - 1))
      line(prev-junction, junction) // Продолжаем ствол вниз до следующей цели
      circle(prev-junction, radius: 0.05, fill: black) // Т-перекресток, ставим точку!
    }
  }
}

// ==========================================
// 5. ТЕСТОВАЯ СЦЕНА (Идеально по ГОСТу)
// ==========================================

#align(center)[
  #set text(font: "GOST Type B", size: 10pt)
  #show math.equation: set text(font: "STIX Two Math", size: 10pt)
  #cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let BUS_X = 0
    let LAYERS = (1, 4)

    // 1. РИСУЕМ ЕДИНУЮ ШИНУ
    draw-bus(BUS_X, 1, -11)

    // 2. ЗАВОДИМ ПЕРЕМЕННЫЕ В ШИНУ С НУМЕРАЦИЕЙ
    // Допустим x1 в базисе И-НЕ
    bus-in-inv(BUS_X, 0, $x_1$, 1, 2, basis: "NAND")

    // Допустим x2 в базисе ИЛИ-НЕ
    bus-in-inv(BUS_X, -2.5, $x_2$, 3, 4, basis: "NOR")

    // Допустим h просто прямой
    bus-in(BUS_X, -5, $h$, 5)
    bus-in-inv(BUS_X, -6.5, $x_2$, 6, 7, basis: "NOT")


    // 3. СТАВИМ ЛОГИЧЕСКИЕ ЭЛЕМЕНТЫ СПРАВА ОТ ШИНЫ
    logic-gate("and1", "&", (LAYERS.at(0), -1), inputs: 2)
    logic-gate("and2", "&", (LAYERS.at(0), -4.5), inputs: 2)

    mux("m1", (LAYERS.at(1), -2), data-inputs: 4, addr-inputs: 2)


    // 4. ПОДКЛЮЧАЕМ ЭЛЕМЕНТЫ, ВЫТЯГИВАЯ СИГНАЛЫ ИЗ ШИНЫ (bus-tap)
    // Подключаем and1: берем x1_inv (номер 2) и x2_dir (номер 3)
    bus-tap(BUS_X, "and1.in-1", 2)
    bus-tap(BUS_X, "and1.in-2", 3)

    // Подключаем and2: берем x1_dir (номер 1) и h (номер 5)
    bus-tap(BUS_X, "and2.in-1", 1)
    bus-tap(BUS_X, "and2.in-2", 5)

    // Напрямую кинем x2_inv (номер 4) на вход MUX D3
    bus-tap(BUS_X, "m1.in-d3", 4)


    // 5. СОЕДИНЯЕМ ЭЛЕМЕНТЫ МЕЖДУ СОБОЙ
    wire("and1.out", "m1.in-d0", routing: "Z", z-fract: 40%)
    wire("and2.out", "m1.in-a0", routing: "Z", z-fract: 60%)

    // Ветвление от Z-провода (находим точную координату излома)
    wire-fork("and1.out", ("m1.in-d0", "m1.in-d1"), z-fract: 40%)

    // 6. ВЫХОД
    wire("m1.out", (rel: (1, 0)), routing: "direct")
    content("m1.out", $S_1$, anchor: "south-west", padding: 0.1)
  })
]