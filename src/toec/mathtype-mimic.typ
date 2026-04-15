    #let mathtype-mimic(receive: false, digits: 3, body) = {
  // Set the MathType-equivalent font
  show math.equation: set text(font: "STIX Two Math", size: 14pt)

  // FIX 1: Decimal comma (removes space after comma in numbers like 1,5)
  show math.equation: it => {
    show ",": math.class("normal", ",")
    it
  }

  // FIX: Автоматическое округление и форматирование дробных чисел
  // Ищем числа с точкой или запятой
  let num-regex = regex("\d+[\.,]\d+")
  show math.equation: eq => {
    show num-regex: it => {
      // Заменяем запятую на точку для преобразования в float
      let text-val = it.text.replace(",", ".")
      let val = float(text-val)

      // Округляем до заданного количества знаков
      let rounded = calc.round(val, digits: digits)

      // Конвертируем обратно в строку с ГОСТовской запятой
      let str-val = str(rounded).replace(".", ",")
      let parts = str-val.split(",")

      let int-part = parts.at(0)
      let frac-part = if parts.len() > 1 { parts.at(1) } else { "" }

      // Добиваем нулями до нужного количества знаков (например, 1,5 -> 1,500)
      if frac-part.len() < digits {
        frac-part = frac-part + "0" * (digits - frac-part.len())
      }

      // Собираем итоговое число
      if digits > 0 {
        int-part + "," + frac-part
      } else {
        int-part
      }
    }
    eq
  }

  // FIX 2: GLOBAL LOWERED SUBSCRIPTS
  // Intercepts all subscripts (like R_5) automatically!
  show math.attach: it => {
    let b = it.at("b", default: none)

    let fixed-base = math.italic(it.base)

    // Check if there is a subscript AND it hasn't been padded yet (prevents infinite loop!)
    if b != none and b.func() != pad {
      // Rebuild the attachment with our modifications
      math.attach(
        fixed-base,
        t: it.at("t", default: none), // preserve superscripts if they exist
        // Adjust 'dy' to push further down, and 'bottom' pad to push the fraction line away
        b: pad(bottom: 1em, move(dx: 0.1em, dy: 0.5em, b)),
        tl: it.at("tl", default: none),
        bl: it.at("bl", default: none),
        tr: it.at("tr", default: none),
        br: it.at("br", default: none),
      )
    } else {
      it
    }
  }

  // FIX 3: SMART FRACTION PADDING (mimics looser MathType division gaps)
  show math.frac: it => {
    // Проверка, чтобы не уйти в бесконечный цикл
    if it.num.func() != pad {

      // ХИТРЫЙ ТРЮК: превращаем структуру числителя/знаменателя в текст (repr)
      // и проверяем, есть ли внутри них вложенная дробь "frac("
      let has-nested-n = repr(it.num).contains("frac(")
      let has-nested-d = repr(it.denom).contains("frac(")
      // Гибкая настройка отступов:
      // Если есть вложенная дробь -> раздвигаем сильно (0.6em)
      // Если это простая дробь -> раздвигаем чуть-чуть (0.3em)
      let pad-n = if has-nested-n { 0.8em } else { 0.4em }
      let pad-d = if has-nested-d { 0.8em } else { 0.4em }

      // Оборачиваем в display, чтобы размер цифр 2-го яруса был как у 1-го
      let n = math.display(it.num)
      let d = math.display(it.denom)

      // Применяем вычисленные отступы
      math.frac(
        pad(bottom: pad-n, n),
        pad(top: pad-d, d)
      )
    } else {
      it
    }
  }


  block(breakable: false, width: 100%, [
    #if (receive) [Получаем]
    #align(center, block(above: 2em, below: 2em)[
      // 2. Make the equations INSIDE this group tightly packed
      #show math.equation.where(block: true): set block(spacing: 0.6em)

      #body
    ])
  ])
}

// EXAMPLE
// Теперь можно указывать количество знаков вот так:
#mathtype-mimic(digits: 3)[
  $
  R_23456 = (R_5 R_2346) / (R_5 + R_2346)
          = (1.5 dot 3.52) / (1.5 + 3.52)
          = 1.05 "кОм."
  $
]

#hide("|")


#hide("|")


#hide("|")


#let V = (
  R1: 230, R2: 470, R3: 160, R4: 570, R5: 310, R6: 190, R7: 550,
  E2: 500, E4: 500,
  J4: 3, J7: 9,
  VARIANT: 14,
)
#let E4_prime = V.J4 * V.R4
#let E7_prime = V.J7 * V.R7
#let E4_sum = V.E4 + E4_prime
#let R_156 = V.R1 + V.R6 + V.R5
#let R_234 = V.R2 + V.R3 + V.R4
#let E_2404 = V.E2 + E4_sum
#let U_14 = (-E7_prime / V.R7 - E_2404 / R_234) / (1 / R_156 + 1 / V.R7 + 1 / R_234)

#mathtype-mimic[
  $ U_14 = (-E_07/R_7 - E_2404/R_234) / (1/R_156 + 1/R_7 + 1/R_234) = (-#E7_prime/#V.R7 - #E_2404/#R_234) / (1/#R_156 + 1/#V.R7 + 1/#R_234) = #U_14 " В". $
]