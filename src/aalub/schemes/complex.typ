#import "@preview/cetz:0.5.0"
#import "elements_complex.typ": logic-gate, mux, wire, bus-in, bus-in-inv, draw-bus, bus-tap

// ==========================================
// 1. DSL (ФУНКЦИИ ДЛЯ ОПИСАНИЯ СХЕМЫ)
// ==========================================

#let sig(name, pos: auto, z-fract: 30%) = (type: "sig", id: name, pos: pos, z-fract: z-fract)

#let gate(kind, inv-out: false, pos: auto, z-fracts: (), ..inps) = (
  type: "gate", kind: kind, inps: inps.pos(), inv-out: inv-out, pos: pos, z-fracts: z-fracts
)

#let and-g(..inps)  = gate("&", ..inps)
#let nand-g(..inps) = gate("&", inv-out: true, ..inps)
#let or-g(..inps)   = gate("1", ..inps)
#let nor-g(..inps)  = gate("1", inv-out: true, ..inps)
#let xor-g(..inps)  = gate("=1", ..inps)
#let not-g(inp, pos: auto, z-fracts: ()) = gate("1", inv-out: true, pos: pos, z-fracts: z-fracts, inp)

#let mux-g(data: (), addr: (), pos: auto, z-fracts: ()) = (
  type: "mux", data: data, addr: addr, pos: pos, z-fracts: z-fracts
)

// ==========================================
// НАСТРОЙКИ КОМПОНОВКИ (СЕТКА)
// ==========================================
#let default-layout = (
  grid-x-step: 2.5,    // Сантиметров на 1 колонку (depth)
  grid-y-step: 0.5,    // Сантиметров на 1 строку (ряд)

  row-gate-gap: 1,     // Пустых строк между вентилями
  row-func-gap: 3,     // Пустых строк между большими функциями
)

#let _merge-layout(custom) = {
  let res = default-layout
  if custom != none and type(custom) == dictionary {
    for (k, v) in custom { res.insert(k, v) }
  }
  return res
}

// ==========================================
// 2. ДВИЖОК КОМПОНОВКИ (GRID LAYOUT ENGINE)
// ==========================================
#let _build-instructions(node, uid: 0, row-start: 0, layout: default-layout) = {

  if node.type == "sig" {
    return (
      uid: uid, row-end: row-start + 1, col: 0,
      out-pin: node.id, type: "sig", z-fract: node.z-fract, cmds: ()
    )
  }

  let current-row = row-start
  let current-uid = uid + 1
  let max-col = 0
  let cmds = ()
  let input-results = ()

  let all-inps = if node.type == "mux" { node.data + node.addr } else { node.inps }

  for inp in all-inps {
    let res = _build-instructions(inp, uid: current-uid, row-start: current-row, layout: layout)
    current-uid = res.uid
    current-row = res.row-end + layout.row-gate-gap
    max-col = calc.max(max-col, res.col)
    cmds += res.cmds
    input-results.push(res)
  }
  current-row -= layout.row-gate-gap // Убираем последний лишний зазор

  // Если позиция задана вручную - используем её, иначе вычисляем по сетке
  let my-col = if node.pos != auto { node.pos.at(0) } else { max-col + 1 }
  // По Y вентиль центрируется относительно своих входов
  let my-row = if node.pos != auto { node.pos.at(1) } else { (row-start + current-row) / 2 }

  let my-id = if node.type == "mux" { "mux_" + str(current-uid) } else { "gate_" + str(current-uid) }
  current-uid += 1

  if node.type == "mux" {
    cmds.push((
      type: "draw-mux", id: my-id,
      col: my-col, row: my-row,
      d-len: node.data.len(), a-len: node.addr.len()
    ))
  } else {
    cmds.push((
      type: "draw-gate", id: my-id, kind: node.kind, inv-out: node.inv-out,
      col: my-col, row: my-row, inps: node.inps.len()
    ))
  }

  for (i, res) in input-results.enumerate() {
    let target-pin = if node.type == "mux" {
      if i < node.data.len() { my-id + ".in-d" + str(i) } else { my-id + ".in-a" + str(i - node.data.len()) }
    } else {
      my-id + ".in-" + str(i+1)
    }

    let custom-z = node.at("z-fracts", default: ())
    let z-f = if i < custom-z.len() and custom-z.at(i) != auto { custom-z.at(i) }
              else { 25% + (i / calc.max(1, all-inps.len() - 1)) * 50% }

    if "type" in res and res.type == "sig" {
      cmds.push((type: "bus-tap", sig: res.out-pin, to: target-pin, z-fract: res.z-fract))
    } else {
      cmds.push((type: "wire", from: res.out-pin, to: target-pin, routing: "Z", z-fract: z-f))
    }
  }

  return (
    uid: current-uid,
    row-end: calc.max(current-row, row-start + all-inps.len() * 1.0), // 1.0 - шаг пинов
    col: my-col, out-pin: my-id + ".out", cmds: cmds
  )
}

// ==========================================
// 3. ОТРИСОВЩИК (РЕНДЕРЕР СХЕМЫ)
// ==========================================
#let draw-ast-circuit(
  bus-vars,
  functions,       // Массив словарей: (name: "S1", label: $S_1$, tree: node, bus-x: 0)
  bus-paths: (),   // Массив массивов координат для отрисовки линий шин
  bus-inv-basis: "NOT",
  layout: (:)
) = {
  import cetz.draw: *
  let lay = _merge-layout(layout)

  // 1. РИСУЕМ ЛИНИИ ШИНЫ (в том числе "через верх")
  for path in bus-paths {
    draw-bus(..path)
  }

  // 2. ВХОДЫ В ШИНУ
  let bus-signals = (:)
  let current-y = 0.0
  let current-num = 1
  let default-bus-x = 0 // По умолчанию входы рисуем на левой шине (x=0)

  for v in bus-vars {
    if v.at("need-inv", default: false) {
      bus-signals.insert(v.id, current-num)
      bus-signals.insert("!" + v.id, current-num + 1)
      bus-in-inv(default-bus-x, current-y, v.label, current-num, current-num + 1, basis: bus-inv-basis)
      current-num += 2
      current-y -= 2.5
    } else {
      bus-signals.insert(v.id, current-num)
      bus-in(default-bus-x, current-y, v.label, current-num)
      current-num += 1
      current-y -= 1.0
    }
  }

  // 3. ГЕНЕРАЦИЯ И ОТРИСОВКА ФУНКЦИЙ
  let current-row = -current-y / lay.grid-y-step + 1 // Начинаем функции ниже входов
  let uid-counter = 0

  for func in functions {
    // Каждая функция может быть привязана к своей "отвесной" шине (по умолчанию x=0)
    let f-bus-x = func.at("bus-x", default: 0)

    let res = _build-instructions(func.tree, uid: uid-counter, row-start: current-row, layout: lay)
    uid-counter = res.uid
    current-row = res.row-end + lay.row-func-gap

    for cmd in res.cmds {
      if cmd.type == "draw-gate" {
        let real-x = f-bus-x + cmd.col * lay.grid-x-step
        let real-y = -(cmd.row * lay.grid-y-step)
        logic-gate(cmd.id, cmd.kind, (real-x, real-y),
                   inputs: cmd.inps, inv-out: cmd.inv-out, pin-step: lay.grid-y-step)

      } else if cmd.type == "draw-mux" {
        let real-x = f-bus-x + cmd.col * lay.grid-x-step
        let real-y = -(cmd.row * lay.grid-y-step)
        mux(cmd.id, (real-x, real-y),
            data-inputs: cmd.d-len, addr-inputs: cmd.a-len, pin-step: lay.grid-y-step)

      } else if cmd.type == "wire" {
        wire(cmd.from, cmd.to, routing: cmd.at("routing", default: "Z"), z-fract: cmd.z-fract)

      } else if cmd.type == "bus-tap" {
        let pin-num = bus-signals.at(cmd.sig, default: "?")
        // Отвод делается от той шины, к которой привязана функция (f-bus-x)
        bus-tap(f-bus-x, cmd.to, pin-num, routing: "|-", z-fract: cmd.z-fract)
      }
    }

    // ВЫВОД РЕЗУЛЬТАТА (ИМЯ ФУНКЦИИ)
    wire(res.out-pin, (rel: (1.5, 0)), routing: "direct")
    content((rel: (1.2, 0.3), to: res.out-pin), func.label, anchor: "west")
  }
}

// ==========================================
// ТЕСТОВАЯ СЦЕНА: ШИНА ЧЕРЕЗ ВЕРХ ПО ГОСТ
// ==========================================
#align(center)[
  #set page(width: auto, height: auto, margin: 1cm)
  #set text(font: "GOST Type B", size: 10pt)
  #show math.equation: set text(font: "STIX Two Math", size: 10pt)

  #cetz.canvas(length: 1cm, {
    let my-bus = (
      (id: "x1", label: $x_1$),
      (id: "x2", label: $x_2$),
      (id: "y1", label: $y_1$, need-inv: true),
      (id: "p",  label: $p$)
    )

    // Функция 1 (слева, привязана к x=0)
    // Используем жесткое позиционирование pos: (col, row) для xor-g
    let S1-tree = xor-g(
      and-g(pos: (1, 6), sig("x1"), sig("x2")),
      sig("!y1")
    )

    // Функция 2 (справа, привязана к x=9)
    let P1-tree = mux-g(
      data: (sig("p"), not-g(sig("y1")), and-g(sig("y1"), sig("p")), sig("!y1")),
      addr: (sig("x1"), sig("x2"))
    )

    draw-ast-circuit(
      my-bus,
      (
        (name: "S1", label: $S_1$, tree: S1-tree, bus-x: 0),
        (name: "P1", label: $P_1$, tree: P1-tree, bus-x: 10) // Эта функция питается от правой шины
      ),
      // Рисуем саму шину ломаными линиями
      bus-paths: (
        ((0, 1), (0, -12)),            // Левый ствол
        ((0, 1), (10, 1), (10, -12))   // Перекидываем через верх направо и опускаем вниз
      ),
      layout: (
        grid-x-step: 2.5, // Расстояние между слоями логики
      )
    )
  })
]