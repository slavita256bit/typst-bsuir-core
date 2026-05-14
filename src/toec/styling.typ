#let apply-toec-styling(body) = {
    set math.equation(numbering: none)
    set heading(numbering: "1.1.")

    show figure.where(kind: table): set figure(gap: 0.3em)

    // --- SMART NUMBER FORMATTER ---
    let format-value(it) = context {
      let allow-format = state("allow-format", true)
      if allow-format.get() {
          // 1. Convert comma to dot for Typst math
          let text = it.text.replace(",", ".")
          let val = float(text)

          // 2. Round to exactly 2 decimal places
          let rounded = calc.round(val, digits: 2)

          // 3. Convert back to string and replace dot with GOST comma
          let str-val = str(rounded).replace(".", ",")

          // 4. Add padding zeros if necessary
          let parts = str-val.split(",")
          if parts.len() == 1 {
            str-val + ",00"
          } else if parts.at(1).len() == 1 {
            str-val + "0"
          } else {
            str-val
          }
      } else {
        it
      }
    }

    // Ищет числа, где есть точка или запятая и хотя бы 1 цифра после нее
    // Это защищает индексы (I_1) от превращения в I_1,00
    let num-regex = regex("[0-9]+[\.,][0-9]+")

    // Применяем авто-форматирование к формулам
//     show math.equation: eq => {
//       show num-regex: format-value
//       eq
//     }

    // Применяем авто-форматирование к таблицам
    show table.cell: cell => {
      show num-regex: format-value
      cell
    }

    set figure.caption(separator: [ #[--] ])

    show figure.caption: cap => context {
//       set text(size: 12pt)
//       set par(first-line-indent: 0pt)

      let num = none
      if cap.numbering != none {
        num = cap.counter.display(cap.numbering)
      }

      let content = [#cap.supplement #num#cap.separator#cap.body]

      if cap.kind == table {
        block(align(left)[#content])
      } else {
        block(width: 100%, align(center)[#content])
      }
    }

    // Все ",00" -> пустота
    show math.equation: eq => {
      show regex(",\u{2060}?00+([^0-9]|$)"): it => {
        if it.text.ends-with("0") { none } else { it.text.slice(-1) }
      }
      eq
    }

    show math.equation: it => {
      // Находим все греческие буквы и принудительно делаем их upright
      show regex("[\u{0370}-\u{03FF}]"): it => math.upright(it)
      it
    }

    // Все картинки по центру страницы
    show figure: fig => {
      if fig.kind == table {
        fig
      } else {
        move(dx: -7.5mm, fig)
      }
    }

    body
}

#let unformat(body) = {
    let allow-format = state("allow-format", true)
    allow-format.update(false)
    body
    allow-format.update(true)
}

#let im(val) = [#val$j$]