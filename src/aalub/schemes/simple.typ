#import "@preview/cetz:0.5.0"
#import "elements_simple.typ": *

// ==========================================
// 1. КОНФИГУРАТОР БАЗИСОВ (ПО ГОСТ)
// ==========================================
#let get-logic-basis(basis) = {
  let cfg = (
    l1: "&", inv1: false,
    mid: none,
    l2: "1", inv2: false,
    out-inv: (sym: "1", inv: true, tied: false)
  )

  if basis == "A1" or basis == "AND-OR-NOT" {
    cfg = (l1: "&", inv1: false, mid: none, l2: "1", inv2: false, out-inv: (sym: "1", inv: true, tied: false))
  } else if basis == "A6" or basis == "NAND" {
    // И-НЕ: финальная инверсия - И-НЕ с объединенными входами
    cfg = (l1: "&", inv1: true,  mid: none, l2: "&", inv2: true, out-inv: (sym: "&", inv: true, tied: true))
  } else if basis == "A7" or basis == "NOR" {
    // ИЛИ-НЕ: финальная инверсия - ИЛИ-НЕ с объединенными входами
    cfg = (l1: "1", inv1: true,  mid: none, l2: "1", inv2: true, out-inv: (sym: "1", inv: true, tied: true))
  } else if basis == "A4" or basis == "AND-NOT" {
    // И, НЕ: инверсии делаются отдельным блоком НЕ
    cfg = (l1: "&", inv1: false, mid: (sym: "1", inv: true, tied: false), l2: "&", inv2: false, out-inv: (sym: "1", inv: true, tied: false))
  } else if basis == "A5" or basis == "OR-NOT" {
    // ИЛИ, НЕ: инверсии делаются отдельным блоком НЕ
    cfg = (l1: "1", inv1: false, mid: (sym: "1", inv: true, tied: false), l2: "1", inv2: false, out-inv: (sym: "1", inv: true, tied: false))
  }

  return cfg
}

#let get-bus-basis(basis) = {
  if basis in ("A6", "NAND") { return "NAND" }
  if basis in ("A7", "NOR") { return "NOR" }
  return "NOT"
}

// Глобальные настройки отступов
#let LAYOUT = (
  BUS_X: 0,
  LAYER_1_X: 1.5,
  LAYER_MID_X: 3.5,
  LAYER_2_X: 6.0,
  LAYER_OUT_X: 8.5,
  PIN_STEP: 0.5,
  GATE_Y_SPACING: 3,
  FUNC_Y_SPACING: 0.5
)

// ==========================================
// 2. ГЛАВНЫЙ ГЕНЕРАТОР СХЕМ
// ==========================================
#let draw-combinational-circuits(
  bus-vars,
  funcs,
  logic-basis: "A1",
  bus-basis: auto
) = {
  import cetz.draw: *

  let actual-bus-basis = if bus-basis == auto { logic-basis } else { bus-basis }
  let bus-inv-type = get-bus-basis(actual-bus-basis)
  let basis-cfg = get-logic-basis(logic-basis)

  // 1. АНАЛИЗ ВСЕХ ФУНКЦИЙ ДЛЯ ШИНЫ
  let needed-vars = (:)
  // ПРИНУДИТЕЛЬНО задаем, что прямые линии нужны всем объявленным переменным
  for v in bus-vars { needed-vars.insert(v.id, (dir: true, inv: false)) }

  for func in funcs {
    for term in func.terms {
      for sig in term {
        let is-inv = sig.starts-with("!")
        let base-sig = sig.trim("!")
        if base-sig in needed-vars {
          if is-inv { needed-vars.at(base-sig).inv = true }
        }
      }
    }
  }

  // 2. РИСУЕМ ВХОДЫ ШИНЫ
  let bus-signals = (:)
  let current-y = 0.0
  let current-num = 1
  let bus-start-y = 1.0

  for v in bus-vars {
    let usage = needed-vars.at(v.id)
    if not usage.dir and not usage.inv { continue }

    if usage.inv {
      bus-signals.insert(v.id, current-num)
      bus-signals.insert("!" + v.id, current-num + 1)
      bus-in-inv(LAYOUT.BUS_X, current-y, v.label, current-num, current-num + 1, basis: bus-inv-type)
      current-num += 2
      current-y -= 2.5
    } else {
      bus-signals.insert(v.id, current-num)
      bus-in(LAYOUT.BUS_X, current-y, v.label, current-num)
      current-num += 1
      current-y -= 1.0
    }
  }

  current-y = 0

  // 3. ПОСЛЕДОВАТЕЛЬНО СТРОИМ КАЖДУЮ ФУНКЦИЮ
  for (f-idx, func) in funcs.enumerate() {
    let l1-outputs = ()
    let func-start-y = current-y

    // --- СЛОЙ 1 И ПРОМЕЖУТОЧНЫЙ СЛОЙ (MID) ---
    for (t-idx, term) in func.terms.enumerate() {
      let gate-name = "f" + str(f-idx) + "_l1_" + str(t-idx)

      logic-gate(
        gate-name, basis-cfg.l1,
        (LAYOUT.LAYER_1_X, current-y),
        inputs: term.len(),
        inv-out: basis-cfg.inv1
      )

      for (j, sig) in term.enumerate() {
        let pin-num = bus-signals.at(sig)
        bus-tap(LAYOUT.BUS_X, gate-name + ".in-" + str(j+1), pin-num, z-fract: 30%)
      }

      if basis-cfg.mid != none {
        let mid-name = "f" + str(f-idx) + "_mid_" + str(t-idx)
        let inps = if basis-cfg.mid.at("tied", default: false) { 2 } else { 1 }

        let h-l1 = calc.max(1.5, (term.len() - 1) * LAYOUT.PIN_STEP + 0.8)
        let h-mid = calc.max(1.5, (inps - 1) * LAYOUT.PIN_STEP + 0.8)
        let mid-y = current-y - h-l1 / 2 + h-mid / 2

        logic-gate(
          mid-name, basis-cfg.mid.sym,
          (LAYOUT.LAYER_MID_X, mid-y),
          inputs: inps,
          inv-out: basis-cfg.mid.inv
        )

        if inps == 1 {
          wire(gate-name + ".out", mid-name + ".in-1", routing: "direct")
        } else {
          let split-x = LAYOUT.LAYER_MID_X - 0.5
          let actual-out-y = current-y - h-l1 / 2
          wire(gate-name + ".out", (split-x, actual-out-y), routing: "direct")
          circle((split-x, actual-out-y), radius: 0.05, fill: black)
          wire((split-x, actual-out-y), mid-name + ".in-1", routing: "|-")
          wire((split-x, actual-out-y), mid-name + ".in-2", routing: "|-")
        }

        l1-outputs.push(mid-name + ".out")
      } else {
        l1-outputs.push(gate-name + ".out")
      }

      current-y -= term.len() * LAYOUT.PIN_STEP + 1
    }

    let center-y = (func-start-y + current-y + LAYOUT.GATE_Y_SPACING) / 2
    let final-out = none
    let actual-out-y = 0.0 // Абсолютная координата выхода Y

    // --- СЛОЙ 2 (Сборка) ---
    if l1-outputs.len() > 1 {
      let gate-name = "f" + str(f-idx) + "_l2_out"

      logic-gate(
        gate-name, basis-cfg.l2,
        (LAYOUT.LAYER_2_X, center-y),
        inputs: l1-outputs.len(),
        inv-out: basis-cfg.inv2
      )

      let num-wires = l1-outputs.len()
      let custom-z = func.at("z-fracts", default: ())

      for (i, out-pin) in l1-outputs.enumerate() {
        let fraction = if i < custom-z.len() {
          custom-z.at(i)
        } else {
          15% + (i / calc.max(1, num-wires - 1)) * 70%
        }
        wire(out-pin, gate-name + ".in-" + str(i+1), routing: "Z", z-fract: fraction)
      }

      final-out = gate-name + ".out"

      // Идеально точный расчет Y выхода 2-го слоя
      let h-l2 = calc.max(1.5, (l1-outputs.len() - 1) * LAYOUT.PIN_STEP + 0.8)
      actual-out-y = center-y - h-l2 / 2

    } else if l1-outputs.len() == 1 {
      final-out = l1-outputs.first()
      // Идеально точный расчет Y выхода единственного элемента 1-го слоя
      let h-l1 = calc.max(1.5, (func.terms.first().len() - 1) * LAYOUT.PIN_STEP + 0.8)
      actual-out-y = func-start-y - h-l1 / 2
    }

    // --- ФИНАЛЬНАЯ ИНВЕРСИЯ (ОТДЕЛЬНЫЙ ЭЛЕМЕНТ) ---
    let func-inv = func.at("inv-out", default: false)

    if func-inv {
      let out-inv-name = "f" + str(f-idx) + "_out_inv"
      let inps = if basis-cfg.out-inv.tied { 2 } else { 1 }
      let h-inv = calc.max(1.5, (inps - 1) * LAYOUT.PIN_STEP + 0.8)

      let inv-x = if l1-outputs.len() > 1 { LAYOUT.LAYER_OUT_X } else { LAYOUT.LAYER_2_X }
      // Смещаем инвертор по Y так, чтобы его входы идеально совпадали с выходом L2
      let inv-y = actual-out-y + h-inv / 2

      logic-gate(
        out-inv-name, basis-cfg.out-inv.sym,
        (inv-x, inv-y),
        inputs: inps,
        inv-out: basis-cfg.out-inv.inv
      )

      if inps == 1 {
        wire(final-out, out-inv-name + ".in-1", routing: "direct")
      } else {
        let split-x = inv-x - 0.5
        wire(final-out, (split-x, actual-out-y), routing: "direct")
        circle((split-x, actual-out-y), radius: 0.05, fill: black)
        wire((split-x, actual-out-y), out-inv-name + ".in-1", routing: "|-")
        wire((split-x, actual-out-y), out-inv-name + ".in-2", routing: "|-")
      }

      final-out = out-inv-name + ".out"
      // Обновляем Y выхода с учетом сдвига
      actual-out-y = inv-y - h-inv / 2
    }

    // --- ВЫВОД ЯРЛЫКА ФУНКЦИИ ---
    let text-align-x = LAYOUT.LAYER_OUT_X + 2.0
    let end-pt = (final-out, "-|", (text-align-x, actual-out-y))

    wire(final-out, end-pt, routing: "direct")
    content((rel: (0.2, 0.2), to: end-pt), func.label, anchor: "west")

    current-y -= LAYOUT.FUNC_Y_SPACING
  }

  // 4. ДОРИСОВЫВАЕМ МАГИСТРАЛЬ ШИНЫ
  let bus-end-y = current-y + LAYOUT.FUNC_Y_SPACING - 1.0
  draw-bus(LAYOUT.BUS_X, bus-start-y, bus-end-y)
}

//=================================
// ТЕСТОВЫЕ ДАННЫЕ И ПРИМЕРЫ
//=================================

#let my-bus = (
  (id: "x1", label: $x_1$),
  (id: "x2", label: $x_2$),
  (id: "y1", label: $y_1$),
  (id: "y2", label: $y_2$),
  (id: "h",  label: $h$)
)

// Сложная функция с 4 термами
#let func-S1 = (
  name: "S1",
  label: $S_1$,
  terms: (
    ("x1", "!y1", "!h"),
    ("!x1", "y1", "!h"),
    ("!x1", "!y1", "h"),
    ("x1", "y1", "h")
  ),
  z-fracts: (60%, 40%, 60%, 80%),
  inv-out: true // ФИНАЛЬНАЯ ИНВЕРСИЯ
)

// Простая функция с 2 термами
#let func-P1 = (
  name: "P1",
  label: $P_1$,
  terms: (
    ("x1", "y1"),
    ("x1", "h"),
  ),
  z-fracts: (50%, 50%),
)

//=================================
// ПРИМЕР 1: БАЗИС "ИЛИ-НЕ" (NOR / A7)
//=================================
// В этом базисе финальная инверсия рисуется как ИЛИ-НЕ с двумя замкнутыми входами
#align(center)[
  *Пример 1: Схема в базисе "ИЛИ-НЕ" (A7)* \
  #set text(font: "GOST Type B", size: 10pt)
  #show math.equation: set text(font: "STIX Two Math", size: 10pt)

  #cetz.canvas(length: 0.9cm, {
    draw-combinational-circuits(
      my-bus,
      (func-S1, func-P1),
      logic-basis: "A7",
      bus-basis: "A7"
    )
  })
]

#v(2em)

//=================================
// ПРИМЕР 2: БАЗИС "ИЛИ, НЕ" (OR-NOT / A5)
//=================================
// В этом базисе используются простые элементы ИЛИ. Инверсии (между слоями и на выходе)
// рисуются как обычные одновходовые элементы НЕ.
#align(center)[
  *Пример 2: Схема в базисе "ИЛИ, НЕ" (A5)* \
  #set text(font: "GOST Type B", size: 10pt)
  #show math.equation: set text(font: "STIX Two Math", size: 10pt)

  #cetz.canvas(length: 0.9cm, {
    draw-combinational-circuits(
      my-bus,
      (func-S1, func-P1),
      logic-basis: "A5",
      bus-basis: "A1"
    )
  })
]