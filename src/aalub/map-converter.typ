// КОНВЕРТЕР ДЛЯ КАРТ КАРНО/ВЕЙЧА
// Превращает плоскую таблицу в 2D матрицу
#let tt-to-map-grid(
  encoded-rows,
  in-cols,         // Массив индексов колонок-входов (например: (0, 1, 2, 3))
  out-col,         // Индекс колонки-выхода (например: 5)
  gray-rows: ("00", "01", "11", "10"), // Коды для строк карты
  gray-cols: ("00", "01", "11", "10"), // Коды для столбцов карты
  default-val: "x" // Если набор не найден
) = {
  let grid-data = ()
  for r-code in gray-rows {
    let grid-row = ()
    for c-code in gray-cols {
      let target-combo = r-code.clusters() + c-code.clusters()
      let found-val = default-val

      for row in encoded-rows {
        let current-combo = in-cols.map(idx => str(row.at(idx)))
        if current-combo == target-combo {
          found-val = row.at(out-col)
          break
        }
      }
      grid-row.push(found-val)
    }
    grid-data.push(grid-row)
  }
  return grid-data
}