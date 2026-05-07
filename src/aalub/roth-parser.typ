// Отрисовка таблицы с переносом и выравниванием по левому краю
#let render-roth-table(csv-data, caption-text, lbl, text-size: 12pt) = {
  let cols = csv-data.at(0).len()

  // Уникальный якорь для поиска первой страницы таблицы
  let start-lbl = if type(lbl) == label {
    label("start-" + str(lbl))
  } else {
    label("start-roth-table")
  }

  // Ячейка-заглушка для надписи "Продолжение таблицы..."
  let continuation-cell = table.cell(
    colspan: cols,
    stroke: none,
    inset: 0pt,
    align: left + bottom,
    [
      #metadata(none) #start-lbl
      #context {
        let start-cells = query(start-lbl)
        if start-cells.len() > 0 {
          let first-page = start-cells.first().location().page()
          let current-page = here().page()

          if current-page > first-page {
            let lbl-text = if type(lbl) == label {
              ref(lbl)
            } else {
              caption-text
            }
            pad(bottom: 0.5em)[
              Продолжение таблицы #lbl-text
            ]
          }
        }
      }
    ]
  )

  // Форматируем шапку (первая строка CSV)
  let header-cells = csv-data.at(0).map(val => {
    let v = if val == "" { " " } else { val }
    table.cell()[#text(size: text-size, weight: "bold")[#v]]
  })

  // Форматируем тело таблицы
  let body-cells = ()
  let j = 0
  for row in csv-data.slice(1) {
    for (i, val) in row.enumerate() {
      let v = if val == "" { " " } else { val }
      if i == 0 {
        body-cells.push(table.cell()[#text(size: text-size, weight: "bold")[#v]])
      } else if i == j + 1 {
        body-cells.push(table.cell(fill: luma(240))[])
//       } else if not "y" in val and csv-data.at(0).at(0).at(0) == "C" {
//         body-cells.push(table.cell()[])
      } else {
        body-cells.push(table.cell()[#text(size: text-size)[#v]])
      }
    }
    j += 1
  }

  v(1em)

  // --- МАГИЯ ВЫРАВНИВАНИЯ ---
  // Отключаем встроенное в Typst центрирование содержимого внутри figure
  show figure: set align(left)
  show figure: set block(breakable: true)

  let fig = figure(
    caption: caption-text,
    kind: table,
    supplement: "Таблица",
    table(
      columns: cols,
      align: center + horizon, // Это выравнивание ТЕКСТА внутри ячеек (оставляем по центру)
      // Отключаем рамки для технической строки y=0 (строка продолжения)
      stroke: (x, y) => {
        if y == 0 { return none }
        return 0.5pt + black
      },
      table.header(continuation-cell, ..header-cells),
      ..body-cells
    )
  )

  if type(lbl) == label {
    [#fig #lbl]
  } else {
    fig
  }
}

// Функция для разбиения огромных матриц на несколько страниц А4
#let render-split-roth-table(csv-data, caption-text, lbl, chunks: 3, overlap-cols: 2, text-size: 12pt, cell-padding: 0.2em) = {
  let cols = csv-data.at(0).len()
  let data-cols = cols - 1 // Исключаем первый столбец с заголовками строк

  // Рассчитываем размер блока данных с учетом дублирующихся колонок
  let chunk-size = calc.ceil((data-cols + (chunks - 1) * overlap-cols) / chunks)

  for i in range(chunks) {
    set page(
      width: 210mm,
      height: 279mm,
      margin: (top: 10mm, left: 5mm, right: 5mm, bottom: 0mm),
      numbering: if i == chunks - 1 { "1" } else { none }
    )

    let start-data = i * (chunk-size - overlap-cols)
    let end-data = calc.min(data-cols, start-data + chunk-size)

    // Последний кусок добиваем до конца
    if i == chunks - 1 {
      end-data = data-cols
    }

    // Вырезаем данные. Если первый кусок — берем левую колонку. Иначе — только данные.
    let sliced-data = csv-data.map(row => {
      if i == 0 {
        (row.at(0),) + row.slice(start-data + 1, end-data + 1)
      } else {
        row.slice(start-data + 1, end-data + 1)
      }
    })

    let slice-len = sliced-data.at(0).len()
    let formatted-data = sliced-data.flatten().map(x => if x == "" { " " } else { x })

    // Подпись (caption) оставляем только для первой части
//     let current-caption = if i == 0 { caption-text } else { none }
    let current-caption

    pad(10pt)[
      #let fig = figure(
        caption: current-caption,
        table(
          rows: (auto,) * sliced-data.len(),
          columns: slice-len,
          align: center + horizon,
          stroke: 0.5pt + black,
          ..formatted-data.enumerate().map(pair => {
            let (idx, val) = pair
            let row_idx = calc.quo(idx, slice-len) // это твой `i`
            let local_col = calc.rem(idx, slice-len)

            // Восстанавливаем оригинальный номер колонки (это твой `j + 1`)
            let orig_col = if local_col == 0 { 0 } else { start-data + local_col }

            // Проверка на то, что это таблица C*C
            let is_c_table = csv-data.at(0).at(0).starts-with("C")

            // Применяем твою логику
            if row_idx == 0 or (i == 0 and local_col == 0) {
              table.cell(inset: (y: cell-padding))[#text(size: text-size, weight: "bold")[#val]]
            } else if val == "----" {
              table.cell(fill: luma(240), inset: (y: cell-padding))[]
//             } else if row_idx < orig_col and is_c_table {
//               table.cell(fill: luma(240))[]
//             } else if not "y" in val {
//               table.cell(inset: (y: cell-padding))[]
            } else {
              table.cell(inset: (y: cell-padding))[#text(size: text-size)[#val]]
            }
          })
        )
      )
      // Якорь вешаем только на первую часть таблицы
      #if i == 0 { [#fig #lbl] } else { fig }
    ]

    if i != 0 {counter(page).update(n => n - 1)}
  }
}

// Умная вытяжка кубов из последней строки таблицы (например, строки "Ai" или "ost")
#let extract-cubes(csv-data, row-prefix) = {
  let cubes = ()
  for row in csv-data {
    if row.at(0).starts-with(row-prefix) {
      for cell in row.slice(1) {
        if cell != "" and cell != " " and cell != "----" {
          // В ячейках кубы могут быть разделены переносом строки
          let parts = cell.split(regex("\r?\n")).map(x => x.trim())
          for p in parts {
            if p != "" and p not in cubes {
              cubes.push(p)
            }
          }
        }
      }
    }
  }
  return cubes
}

// Красивое форматирование множества: A_1 = { 101x, ... }
// Новая логика автопереноса длинных множеств кубов
#let format-set(name, cubes) = {
  if cubes.len() == 0 {
    return align(center)[$#name = emptyset$]
  }

  // Выводим как обычный центрированный текст, где каждый куб — математический символ.
  // Это позволяет Typst делать переносы строк в любом месте после запятых.
  align(center)[
    #pad(top: 0.5em, bottom: 0.5em)[#block(width: 90%)[
      $#name = \{$ #cubes.map(c => $#c$).join(", ") $}$
    ]]
  ]
}