#import "@preview/cetz:0.5.0"
#import "elements.typ": logic-gate, mux, wire, bus-in, bus-in-inv, draw-bus, bus-tap

// ==========================================
// 1. DSL (ФУНКЦИИ ДЛЯ ОПИСАНИЯ СХЕМЫ)
// ==========================================

// Сигнал из шины. dy - сдвиг точки подключения к шине, z-fract - точка излома провода
#let sig(name, dy: 0, z-fract: 20%) = (type: "sig", id: name, dy: dy, z-fract: z-fract)

// Базовый вентиль. dy - сдвиг всего вентиля, z-fracts - массив изломов для входов
#let gate(kind, inv-out: false, dy: 0, z-fracts: (), ..inps) = (
  type: "gate",
  kind: kind,
  inps: inps.pos(),
  inv-out: inv-out,
  dy: dy,
  z-fracts: z-fracts
)

#let and-g(..inps)  = gate("&", ..inps)
#let nand-g(..inps) = gate("&", inv-out: true, ..inps)
#let or-g(..inps)   = gate("1", ..inps)
#let nor-g(..inps)  = gate("1", inv-out: true, ..inps)
#let xor-g(..inps)  = gate("=1", ..inps)
#let not-g(inp, dy: 0, z-fracts: ()) = gate("1", inv-out: true, dy: dy, z-fracts: z-fracts, inp)

// Мультиплексор
#let mux-g(data: (), addr: (), dy: 0, z-fracts: ()) = (
  type: "mux",
  data: data,
  addr: addr,
  dy: dy,
  z-fracts: z-fracts
)

// ==========================================
// НАСТРОЙКИ КОМПОНОВКИ ПО УМОЛЧАНИЮ
// ==========================================
#let default-layout = (
  x-bus-gap: 2.0,      // Расстояние от шины до первого слоя
  x-step: 2.5,         // Расстояние по X между слоями
  y-pin-step: 0.5,     // Расстояние между пинами внутри вентиля
  y-gate-gap: 0.5,     // Зазор между соседними вентилями
  y-func-gap: 1.5,     // Зазор между полностью разными функциями (S1 и P1)
  y-bus-step: 1.0,     // Шаг по Y на шине
  y-bus-inv-step: 2.5, // Шаг по Y на шине для сигнала с инвертором
)

#let _merge-layout(custom) = {
  let res = default-layout
  if custom != none and type(custom) == dictionary {
    for (k, v) in custom { res.insert(k, v) }
  }
  return res
}

// ==========================================
// 2. ДВИЖОК КОМПОНОВКИ (LAYOUT ENGINE)
// ==========================================
#let _build-instructions(node, uid: 0, y-start: 0, layout: default-layout) = {

  // Базовый случай: сигнал из шины
  if node.type == "sig" {
    return (
      uid: uid, y-end: y-start, depth: 0,
      out-pin: node.id, type: "sig", dy: node.dy, z-fract: node.z-fract, cmds: ()
    )
  }

  let current-y = y-start
  let current-uid = uid + 1
  let max-depth = 0
  let cmds = ()
  let input-results = ()

  // Обработка мультиплексора
  if node.type == "mux" {
    let all-inps = node.data + node.addr
    for inp in all-inps {
      let res = _build-instructions(inp, uid: current-uid, y-start: current-y, layout: layout)
      current-uid = res.uid
      current-y = res.y-end + layout.y-gate-gap
      max-depth = calc.max(max-depth, res.depth)
      cmds += res.cmds
      input-results.push(res)
    }
    current-y -= layout.y-gate-gap

    let my-depth = max-depth + 1
    let my-x = layout.x-bus-gap + (my-depth - 1) * layout.x-step

    // Вычисляем Y с учетом ручного сдвига (dy)
    let my-y = (y-start + current-y) / 2 + node.at("dy", default: 0)
    let my-id = "mux_" + str(current-uid)
    current-uid += 1

    cmds.push((
      type: "draw-mux", id: my-id,
      x: my-x, y: -my-y,
      d-len: node.data.len(), a-len: node.addr.len(),
      pin-step: layout.y-pin-step
    ))

    for (i, res) in input-results.enumerate() {
      let target-pin = if i < node.data.len() { my-id + ".in-d" + str(i) }
                       else { my-id + ".in-a" + str(i - node.data.len()) }

      // Извлечение кастомного z-fract
      let custom-z = node.at("z-fracts", default: ())
      let z-f = if i < custom-z.len() and custom-z.at(i) != auto {
        custom-z.at(i)
      } else {
        30% + (i / calc.max(1, all-inps.len() - 1)) * 40%
      }

      if "type" in res and res.type == "sig" {
        cmds.push((type: "bus-tap", sig: res.out-pin, to: target-pin, dy: res.dy, z-fract: res.z-fract))
      } else {
        cmds.push((type: "wire", from: res.out-pin, to: target-pin, routing: "Z", z-fract: z-f))
      }
    }

    return (
      uid: current-uid,
      y-end: calc.max(current-y, y-start + all-inps.len() * layout.y-pin-step),
      depth: my-depth, out-pin: my-id + ".out", cmds: cmds
    )
  }

  // Обработка обычного логического вентиля
  if node.type == "gate" {
    for inp in node.inps {
      let res = _build-instructions(inp, uid: current-uid, y-start: current-y, layout: layout)
      current-uid = res.uid
      current-y = res.y-end + layout.y-gate-gap
      max-depth = calc.max(max-depth, res.depth)
      cmds += res.cmds
      input-results.push(res)
    }
    current-y -= layout.y-gate-gap

    let my-depth = max-depth + 1
    let my-x = layout.x-bus-gap + (my-depth - 1) * layout.x-step

    // Учитываем ручной сдвиг (dy)
    let my-y = (y-start + current-y) / 2 + node.at("dy", default: 0)
    let my-id = "gate_" + str(current-uid)
    current-uid += 1

    cmds.push((
      type: "draw-gate", id: my-id, kind: node.kind,
      inv-out: node.inv-out,
      x: my-x, y: -my-y, inps: node.inps.len(),
      pin-step: layout.y-pin-step
    ))

    for (i, res) in input-results.enumerate() {
      let target-pin = my-id + ".in-" + str(i+1)

      // Извлечение кастомного z-fract
      let custom-z = node.at("z-fracts", default: ())
      let z-f = if i < custom-z.len() and custom-z.at(i) != auto {
        custom-z.at(i)
      } else {
        25% + (i / calc.max(1, node.inps.len() - 1)) * 50%
      }

      if "type" in res and res.type == "sig" {
        cmds.push((type: "bus-tap", sig: res.out-pin, to: target-pin, dy: res.dy, z-fract: res.z-fract))
      } else {
        cmds.push((type: "wire", from: res.out-pin, to: target-pin, routing: "Z", z-fract: z-f))
      }
    }

    return (
      uid: current-uid,
      y-end: calc.max(current-y, y-start + node.inps.len() * layout.y-pin-step),
      depth: my-depth, out-pin: my-id + ".out", cmds: cmds
    )
  }
}

// ==========================================
// 3. ОТРИСОВЩИК (РЕНДЕРЕР СХЕМЫ)
// ==========================================
#let draw-ast-circuit(
  bus-vars,
  functions,
  names: (:),
  bus-x: 0,
  bus-inv-basis: "NOT",
  layout: (:)
) = {
  import cetz.draw: *
  let lay = _merge-layout(layout)

  // 1. РИСУЕМ ШИНУ
  let bus-signals = (:)
  let current-y = 0.0
  let current-num = 1
  let bus-start-y = 1.0

  for v in bus-vars {
    if v.at("need-inv", default: false) {
      bus-signals.insert(v.id, current-num)
      bus-signals.insert("!" + v.id, current-num + 1)
      bus-in-inv(bus-x, current-y, v.label, current-num, current-num + 1, basis: bus-inv-basis)
      current-num += 2
      current-y -= lay.y-bus-inv-step
    } else {
      bus-signals.insert(v.id, current-num)
      bus-in(bus-x, current-y, v.label, current-num)
      current-num += 1
      current-y -= lay.y-bus-step
    }
  }

  let bus-end-y = current-y
  current-y = -1.0

  // 2. ГЕНЕРИРУЕМ КОМАНДЫ ДЛЯ ФУНКЦИЙ
  let all-cmds = ()
  let uid-counter = 0

  for (func-name, ast-tree) in functions {
    let res = _build-instructions(ast-tree, uid: uid-counter, y-start: current-y, layout: lay)
    uid-counter = res.uid
    current-y = res.y-end + lay.y-func-gap
    all-cmds += res.cmds

    let display-label = names.at(func-name, default: func-name)
    all-cmds.push((type: "output-label", from: res.out-pin, label: display-label))
  }

  bus-end-y = calc.min(bus-end-y, -current-y + lay.y-func-gap)

  // 3. ВЫПОЛНЯЕМ КОМАНДЫ В CETZ
  for cmd in all-cmds {
    if cmd.type == "draw-gate" {
      logic-gate(cmd.id, cmd.kind, (bus-x + cmd.x, cmd.y),
                 inputs: cmd.inps, inv-out: cmd.inv-out, pin-step: cmd.pin-step)
    } else if cmd.type == "draw-mux" {
      mux(cmd.id, (bus-x + cmd.x, cmd.y),
          data-inputs: cmd.d-len, addr-inputs: cmd.a-len, pin-step: cmd.pin-step)
    } else if cmd.type == "wire" {
      wire(cmd.from, cmd.to, routing: cmd.at("routing", default: "Z"), z-fract: cmd.z-fract)
    } else if cmd.type == "bus-tap" {
      let pin-num = bus-signals.at(cmd.sig, default: "?")

      // МАГИЯ СДВИГА ПРОВОДА (dy)
      if cmd.dy != 0 {
        let start-coord = (rel: (0, -cmd.dy), to: ((bus-x, 0), "|-", cmd.to))

        // Используем кастомный z-fract
        wire(start-coord, cmd.to, routing: "Z", z-fract: cmd.z-fract, dot: "start")

        content(
          (rel: (0.1, 0.15), to: start-coord),
          text(size: 8pt)[#pin-num],
          anchor: "south-west"
        )
      } else {
        bus-tap(bus-x, cmd.to, pin-num, routing: "|-")
      }
    } else if cmd.type == "output-label" {

      wire(cmd.from, (rel: (1.5, 0)), routing: "direct")
      content((rel: (1.2, 0.3), to: cmd.from), cmd.label, anchor: "west")
    }
  }

  draw-bus(bus-x, bus-start-y, bus-end-y - 1.0)
}


//============
//EXAMPLE
//============

#align(center)[
  #set text(font: "GOST Type B", size: 10pt)
  #show math.equation: set text(font: "STIX Two Math", size: 10pt)

  #cetz.canvas(length: 1cm, {
    let my-bus = (
      (id: "x1", label: $x_1$),
      (id: "x2", label: $x_2$),
      (id: "y1", label: $y_1$, need-inv: true),
      (id: "p",  label: $p$)
    )

    let S1-tree = nand-g(
      nand-g(sig("x1"), sig("y1")),
      nand-g(sig("!y1"), sig("p"))
    )

    let P1-tree = mux-g(dy: 1.0,
      z-fracts: (50%, 30%, 60%, auto, auto, auto),
      data: (sig("p", dy: -2, z-fract: 90%), not-g(sig("y1"), dy: 2), and-g(dy: 2, sig("y1"), sig("p")), sig("!y1", dy: 0.5, z-fract: 75%)),
      addr: (sig("x1"), sig("x2"))
    )

    draw-ast-circuit(
      my-bus,
      ("S1": S1-tree, "P1": P1-tree),
      names: ("S1": $S_1$, "P1": $P_1$),

      // ===== ВОТ ЗДЕСЬ ГИБКАЯ НАСТРОЙКА =====
      layout: (
        x-bus-gap: 3.0,       // Отодвигаем первый слой от шины подальше
        x-step: 3.5,          // Делаем провода между слоями длиннее
        y-gate-gap: 1.0,      // Больше воздуха между вентилями внутри функции
        y-func-gap: 2.0       // Сильно отделяем S1 от P1 по вертикали
      )
    )
  })
]