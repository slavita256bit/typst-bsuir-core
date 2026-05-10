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
  continuation-align: left,  // ВЫРАВНИВАНИЕ НАДПИСИ "Продолжение..." (left, right, center)
  break-after: none          // <--- НОВОЕ: Индекс(ы) строки, после которой принудительно разорвать таблицу
) = {
  let cols = rows.at(0).len()

  // 1. Разбиваем данные на блоки (chunks), если задан параметр break-after
  let breaks = if type(break-after) == int { (break-after,) }
               else if type(break-after) == array { break-after }
               else { () }

  let chunks = ()
  let curr = 0
  for b in breaks {
    if b > curr and b < rows.len() {
      chunks.push((start: curr, end: b, data: rows.slice(curr, b)))
      curr = b
    }
  }
  if curr < rows.len() {
    chunks.push((start: curr, end: rows.len(), data: rows.slice(curr, rows.len())))
  }

  let hdr-offset = header_rows + int(show-numbers)
  let results = ()

  for (i, chunk) in chunks.enumerate() {
    let is-first = (i == 0)
    let is-last = (i == chunks.len() - 1)

    // Уникальный якорь для поиска первой страницы таблицы (с учетом чанка)
    let chunk-lbl-str = "start-" + str(lbl) + "-" + str(i)
    if lbl == none and caption != none { chunk-lbl-str = "start-" + repr(caption) + "-" + str(i) }
    let start-lbl = label(chunk-lbl-str)

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

            // Показываем "Продолжение...", если Typst сам разбил блок,
            // ЛИБО если это принудительный блок >= 1 (то есть мы сами разбили таблицу)
            if current-page > first-page or i > 0 {
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

    // Вертикальные линии
    let max_vlines = cols + 1
    let vlines = bold-vlines.map(x => table.vline(
      x: calc.rem(x + max_vlines, max_vlines),
      start: 1,
      stroke: 1.5pt + black
    ))

    // Горизонтальные линии: фильтруем и сдвигаем только те, что попали в текущий чанк
    let local-hlines = ()
    for y in bold-hlines {
      if y < 0 {
        // Отрисовка нижней границы (индекс -1) только для последнего блока
        if is-last {
          local-hlines.push(table.hline(y: chunk.data.len() + hdr-offset + 1, stroke: 1.5pt + black))
        }
      } else {
        if y <= hdr-offset {
          // Линии шапки рисуются во всех блоках (y=0, 1 и т.д.)
          local-hlines.push(table.hline(y: y + 1, stroke: 1.5pt + black))
        } else {
          // Линии внутри данных: проверяем, попала ли линия в текущий кусок
          let data_y = y - hdr-offset
          if data_y > chunk.start and data_y <= chunk.end {
            let local_y = data_y - chunk.start + hdr-offset
            local-hlines.push(table.hline(y: local_y + 1, stroke: 1.5pt + black))
          }
        }
      }
    }

    let num-row = ()
    if show-numbers {
      for col-idx in range(1, cols + 1) {
        num-row.push(strong(str(col-idx)))
      }
    }

    // Управляем дублированием шапки
    let header-block = if repeat-header or is-first {
      table.header(continuation-cell, ..headers, ..num-row)
    } else {
      table.header(continuation-cell)
    }

    let tbl = table(
      columns: if column-widths == auto { cols } else { column-widths },
      align: center + horizon,
      // ДИНАМИЧЕСКИЕ РАМКИ: у строки y=0 (где "Продолжение") отключаем рамки!
      stroke: (x, y) => {
        if y == 0 { return none }
        return 0.5pt + black
      },
      ..vlines,
      ..local-hlines,
      header-block,
      ..chunk.data.flatten()
    )

    // Обертка figure
    if is-first and caption != none {
      show figure: set block(breakable: true)
      let fig = figure(
        caption: caption,
        kind: table,
        supplement: "Таблица",
        tbl
      )
      results.push(if type(lbl) == label { [#fig #lbl] } else { fig })
    } else {
      // Для последующих блоков делаем figure без заголовка,
      // чтобы он не ломал нумерацию таблиц, но сохранял форматирование
      show figure: set block(breakable: true)
      results.push(figure(
        caption: none,
        kind: "table-continuation",
        supplement: none,
        tbl
      ))
    }

    // Вставляем разрыв страницы между блоками
    if not is-last {
      results.push(pagebreak())
    }
  }

  // Возвращаем все сгенерированные блоки разом
  results.join()
}

// СОРТИРОВКА ТАБЛИЦЫ ИСТИННОСТИ
// Сортирует массив строк по указанным колонкам
#let sort-tt(rows, sort-cols: auto) = {
  if sort-cols == auto {
    return rows.sorted()
  }
  let key-fn = row => sort-cols.map(idx => str(row.at(idx)))
  return rows.sorted(key: key-fn)
}