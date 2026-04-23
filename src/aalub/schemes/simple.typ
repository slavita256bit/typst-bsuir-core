#import "@preview/cetz:0.5.0"
#import "elements.typ": *

// ==========================================
// 1. КОНФИГУРАТОР БАЗИСОВ (ПО ГОСТ)
// ==========================================
// Возвращает параметры отрисовки для 1-го и 2-го слоя:
// (символ_L1, инверсия_L1, символ_L2, инверсия_L2)
#let get-logic-basis(basis) = {
  if basis == "A1" { return ("&", false, "1", false) } // И, ИЛИ, НЕ
  if basis == "A6" { return ("&", true,  "&", true)  } // И-НЕ (Шеффера)
  if basis == "A7" { return ("1", true,  "1", true)  } // ИЛИ-НЕ (Пирса)

  // todo A2, A3, A4, A5
  // Для A2, A3, A4, A5 можно добавить специфичную логику.
  // Например, A4 (И, НЕ) часто визуально строится как И-НЕ,
  // если нет строгих требований рисовать отдельные инверторы.
  if basis == "A4" { return ("&", false,  "&", true)  }

  // По умолчанию классическая ДНФ (И-ИЛИ)
  return ("&", false, "1", false)
}

// Конфигуратор инверторов для шины
// Возвращает (тип_вентиля_для_bus-in-inv)
#let get-bus-basis(basis) = {
  if basis == "A6" { return "NAND" } // В A6 инвертор = И-НЕ со связанными входами
  if basis == "A7" { return "NOR"  } // В A7 инвертор = ИЛИ-НЕ со связанными входами
  // todo А2, А3
  return "NOT"                       // A1, A4, A5 используют обычный НЕ
}

// Глобальные настройки отступов
#let LAYOUT = (
  BUS_X: 0,
  LAYER_1_X: 1,
  LAYER_2_X: 4,
  PIN_STEP: 0.5,
  GATE_Y_SPACING: 3,
  FUNC_Y_SPACING: 0.5
)

// ==========================================
// 2. ГЛАВНЫЙ ГЕНЕРАТОР СХЕМ
// ==========================================
#let draw-combinational-circuits(
  bus-vars,
  funcs,               // ТЕПЕРЬ ЭТО МАССИВ ФУНКЦИЙ!
  logic-basis: "A1",   // Базис для самой схемы (L1 и L2)
  bus-basis: auto      // Базис для инверторов на шине. Если auto - берем из logic-basis
) = {
  import cetz.draw: *

  // Определяем параметры отрисовки
  let actual-bus-basis = if bus-basis == auto { logic-basis } else { bus-basis }
  let bus-inv-type = get-bus-basis(actual-bus-basis)
  let (sym-l1, inv-l1, sym-l2, inv-l2) = get-logic-basis(logic-basis)

  // 1. АНАЛИЗ ВСЕХ ФУНКЦИЙ ДЛЯ ШИНЫ
  // Ищем, какие переменные реально используются и нужны ли им инверсии
  let needed-vars = (:)
  for v in bus-vars { needed-vars.insert(v.id, (dir: false, inv: false)) }

  for func in funcs {
    for term in func.terms {
      for sig in term {
        let is-inv = sig.starts-with("!")
        let base-sig = sig.trim("!")
        if base-sig in needed-vars {
          if is-inv { needed-vars.at(base-sig).inv = true }
          else      { needed-vars.at(base-sig).dir = true }
        }
      }
    }
  }

  // 2. РИСУЕМ ВХОДЫ ШИНЫ И НАЗНАЧАЕМ ИМ НОМЕРА (АДРЕСА)
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
      current-y -= 2.5 // Инвертор занимает больше места
    } else {
      bus-signals.insert(v.id, current-num)
      bus-in(LAYOUT.BUS_X, current-y, v.label, current-num)
      current-num += 1
      current-y -= 1.0
    }
  }

  // Сбрасываем отступ перед началом логических вентилей
  current-y = 0

  // 3. ПОСЛЕДОВАТЕЛЬНО СТРОИМ КАЖДУЮ ФУНКЦИЮ
  for (f-idx, func) in funcs.enumerate() {
    let l1-outputs = ()
    let func-start-y = current-y

    // СЛОЙ 1 (Термы)
    for (t-idx, term) in func.terms.enumerate() {
      let gate-name = "f" + str(f-idx) + "_l1_gate_" + str(t-idx)

      logic-gate(
        gate-name, sym-l1,
        (LAYOUT.LAYER_1_X, current-y),
        inputs: term.len(),
        inv-out: inv-l1
      )

      // Подключаем к шине
      for (j, sig) in term.enumerate() {
        let pin-num = bus-signals.at(sig)
        bus-tap(LAYOUT.BUS_X, gate-name + ".in-" + str(j+1), pin-num, z-fract: 30%)
      }

      l1-outputs.push(gate-name + ".out")
      current-y -= term.len() * LAYOUT.PIN_STEP + 1
    }

    // СЛОЙ 2 (Сборка)
    if l1-outputs.len() > 1 {
      let gate-name = "f" + str(f-idx) + "_l2_gate_out"
      let center-y = (func-start-y + current-y + LAYOUT.GATE_Y_SPACING) / 2

      logic-gate(
        gate-name, sym-l2,
        (LAYOUT.LAYER_2_X, center-y),
        inputs: l1-outputs.len(),
        inv-out: inv-l2
      )

      let num-wires = l1-outputs.len()
      let custom-z = func.at("z-fracts", default: ()) // Ищем кастомные настройки

      for (i, out-pin) in l1-outputs.enumerate() {
        // Берем переданное значение, а если его нет — считаем автоматом
        let fraction = if i < custom-z.len() {
          custom-z.at(i)
        } else {
          20% + (i / calc.max(1, num-wires - 1)) * 60%
        }

        wire(out-pin, gate-name + ".in-" + str(i+1), routing: "Z", z-fract: fraction)
      }

      // Вывод функции
      wire(gate-name + ".out", (rel: (1.0, 0)), routing: "direct")
      content((rel: (0.6, 0.3), to: gate-name + ".out"), func.label, anchor: "west")

    } else if l1-outputs.len() == 1 {
      // Если терм один (например функция = просто x1 * x2)
      wire(l1-outputs.first(), (rel: (4.0, 0)), routing: "direct")
      content((rel: (4.2, 0.2), to: l1-outputs.first()), func.label, anchor: "west")
    }

    // Отступ перед следующей функцией
    current-y -= LAYOUT.FUNC_Y_SPACING
  }

  // 4. ДОРИСОВЫВАЕМ МАГИСТРАЛЬ ШИНЫ ДО САМОГО НИЗА
  let bus-end-y = current-y + LAYOUT.FUNC_Y_SPACING - 1.0
  draw-bus(LAYOUT.BUS_X, bus-start-y, bus-end-y)
}


//=================================
// EXAMPLE
//=================================

// 1. Описание переменных на шине
#let my-bus = (
  (id: "x1", label: $x_1$),
  (id: "x2", label: $x_2$),
  (id: "y1", label: $y_1$),
  (id: "y2", label: $y_2$),
  (id: "p",  label: $p$)
)

// 2. Первая функция (например, Сумма младшего разряда)
#let func-S1 = (
  name: "S1",
  label: $S_1$,
  terms: (
    ("x1", "!y1", "!p"),
    ("!x1", "y1", "!p"),
    ("!x1", "!y1", "p"),
    ("x1", "y1", "p")
  ),
  z-fracts: (50%, 30%, 30%, 50%)
)

// 3. Вторая функция (например, Перенос)
#let func-P1 = (
  name: "P1",
  label: $P_1$,
  terms: (
    ("x1", "y1"),
    ("x1", "p"),
    ("y1", "p")
  )
)

// 4. Отрисовка
#align(center)[
  #set text(font: "GOST Type B", size: 10pt)
  #show math.equation: set text(font: "STIX Two Math", size: 10pt)

  #cetz.canvas(length: 1cm, {
    draw-combinational-circuits(
      my-bus,
      (func-S1, func-P1),    // Передаем массив функций!
      logic-basis: "A7",
      bus-basis: "A1"
    )
  })
]