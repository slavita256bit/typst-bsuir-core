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

#let draw-truth-table(
  headers: (),
  rows: (),
  bold-vlines: (), // Индексы столбцов, ПОСЛЕ которых нужна жирная вертикальная линия (начиная с 1)
  bold-hlines: (), // Индексы строк, ПОСЛЕ которых нужна жирная горизонтальная линия (начиная с 1)
  header_cols: 1,
  show-numbers: false // Строка с нумерацией столбцов
) = {
  let cols = rows.at(0).len()

  let all_cols_count = cols + 1 + int(show-numbers)
  let all_rows_count = rows.len() + 1 + header_cols

  // Генерируем жирные вертикальные и горизонтальные линии
  let vlines = bold-vlines.map(x => table.vline(x: calc.rem(x + all_cols_count, all_cols_count), stroke: 1.5pt + black))
  let hlines = bold-hlines.map(y => table.hline(y: calc.rem(y + all_rows_count, all_rows_count), stroke: 1.5pt + black))

  // Генерируем строку 1, 2, 3...
  let num-row = ()
  if show-numbers {
    for i in range(1, cols + 1) {
      num-row.push(strong(str(i)))
    }
  }

  align(center)[
    #table(
      columns: cols,
      align: center + horizon,
      stroke: 0.5pt + black,

      ..vlines,
      ..hlines,

      ..headers,
      ..num-row,
      ..rows.flatten()
    )
  ]
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