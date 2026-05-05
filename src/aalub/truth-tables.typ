// ЛОГИКА ПРЕОБРАЗОВАНИЯ (ЭНКОДЕР)
// Принимает сырые данные (массив массивов) и схему.
// Схема — это массив, где каждый элемент соответствует колонке:
// - none: оставить колонку как есть
// - dictionary: заменить значение по словарю и разбить на биты (например, "0" -> "00" -> "0", "0")
#let encode-tt(raw-rows, schema) = {
  let result = ()

  for row in raw-rows {
    let new-row = ()
    for (i, val) in row.enumerate() {
      // Если для колонки нет правила, пропускаем её как есть
      let rule = if i < schema.len() { schema.at(i) } else { none }
      let str-val = str(val).trim()

      if type(rule) == dictionary {
        // Узнаем ширину битов по первому элементу словаря (обычно 2)
        let bit-width = rule.values().at(0).clusters().len()

        // Обработка безразличных состояний ('x' или 'х' кириллическая)
        if str-val == "x" or str-val == "х" {
          for _ in range(bit-width) { new-row.push("x") }
        } else {
          // Ищем значение в словаре. Если нет (например, комментарий) — не бьем на биты
          let encoded = rule.at(str-val, default: none)
          if encoded != none {
            for bit in encoded.clusters() { new-row.push(bit) }
          } else {
            new-row.push(str-val) // fallback
          }
        }
      } else {
        new-row.push(str-val) // правило none -> просто переносим
      }
    }
    result.push(new-row)
  }
  return result
}

// ЧТЕНИЕ ИЗ CSV
// Удобная обертка. Берет строку CSV (или уже загруженные данные),
// отрезает заголовок (если нужно) и прогоняет через энкодер.
#let load-csv-tt(csv-data, schema, skip-header: true) = {
  let data = if type(csv-data) == str { csv.decode(csv-data) } else { csv-data }
  if skip-header { data = data.slice(1) }
  return encode-tt(data, schema)
}

// ОТРИСОВКА ТАБЛИЦЫ С АВТОМАТИЧЕСКИМ ПЕРЕНОСОМ
#let draw-truth-table(
  caption: none,             // Название таблицы
  lbl: none,                 // Якорь (например: <tbl-ochs>)
  headers: (),
  rows: (),
  bold-vlines: (),           // Индексы столбцов для жирной вертикальной линии
  bold-hlines: (),           // Индексы строк для жирной горизонтальной линии
  header_rows: 1,
  show-numbers: false,       // Выводить ли строку с нумерацией 1, 2, 3...
  column-widths: auto,       // Массив ширин столбцов
  repeat-header: true,       // ПОВТОРЯТЬ ЛИ ШАПКУ НА НОВЫХ СТРАНИЦАХ
  continuation-align: left   // ВЫРАВНИВАНИЕ НАДПИСИ "Продолжение..." (left, right, center)
) = {
  let cols = rows.at(0).len()

  // Уникальный якорь для поиска первой страницы таблицы
  let start-lbl = if type(lbl) == label {
    label("start-" + str(lbl))
  } else if caption != none {
    label("start-" + repr(caption))
  } else {
    label("start-default-table")
  }

  // Корректируем координаты линий из-за новой скрытой строки y=0
  let max_vlines = cols + 1
  let max_hlines = rows.len() + header_rows + int(show-numbers) + 2

  // Вертикальные линии: start: 1 гарантирует, что они не проткнут надпись "Продолжение"
  let vlines = bold-vlines.map(x => table.vline(
    x: calc.rem(x + max_vlines, max_vlines),
    start: 1,
    stroke: 1.5pt + black
  ))

  // Горизонтальные линии: сдвигаем на 1 вниз
  let shift-y = y => if y >= 0 { y + 1 } else { y }
  let hlines = bold-hlines.map(y => table.hline(
    y: calc.rem(shift-y(y) + max_hlines, max_hlines),
    stroke: 1.5pt + black
  ))

  let num-row = ()
  if show-numbers {
    for i in range(1, cols + 1) {
      num-row.push(strong(str(i)))
    }
  }

  let table-cols = if column-widths == auto { cols } else { column-widths }

  // СТРОКА ПРОДОЛЖЕНИЯ: полностью прозрачная (stroke: none), без рамок
  let continuation-cell = table.cell(
    colspan: cols,
    stroke: none,
    inset: 0pt,
    align: continuation-align + bottom,
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
            } else if caption != none {
              caption
            } else {
              ""
            }
            // Отступ, чтобы надпись не прилипала к верхней рамке таблицы
            pad(bottom: 0.5em)[
              #move(dy: 0.2em)[Продолжение таблицы #lbl-text]
            ]
          }
        }
      }
    ]
  )

  // Управляем дублированием: если repeat-header: false, заголовки уходят в тело таблицы
  let header-block = if repeat-header {
    table.header(continuation-cell, ..headers, ..num-row)
  } else {
    table.header(continuation-cell)
  }

  let body-block = if repeat-header {
    rows.flatten()
  } else {
    headers + num-row + rows.flatten()
  }

  let tbl = table(
    columns: table-cols,
    align: center + horizon,

    // ДИНАМИЧЕСКИЕ РАМКИ: у строки y=0 (где "Продолжение") отключаем вообще все рамки!
    stroke: (x, y) => {
      if y == 0 { return none }
      return 0.5pt + black
    },

    ..vlines,
    ..hlines,

    header-block,
    ..body-block
  )

  if caption != none {
    show figure: set block(breakable: true)
    let fig = figure(
      caption: caption,
      kind: table,
      supplement: "Таблица",
      tbl
    )
    if type(lbl) == label {
      [#fig #lbl]
    } else {
      fig
    }
  } else {
    tbl
  }
}

// СОРТИРОВКА ТАБЛИЦЫ ИСТИННОСТИ
// Сортирует массив строк по указанным колонкам
#let sort-tt(rows, sort-cols: auto) = {
  // Если колонки не указаны, сортируем по всей строке целиком
  if sort-cols == auto {
    return rows.sorted()
  }

  // Функция ключа: берет только те колонки, по которым мы хотим сортировать.
  // В Typst массивы строк сортируются лексикографически (как слова в словаре),
  // поэтому "001" будет строго перед "010".
  let key-fn = row => sort-cols.map(idx => str(row.at(idx)))

  return rows.sorted(key: key-fn)
}