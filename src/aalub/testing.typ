// Генератор файла по таблице истинности для проверки на устройтве
#let generate-tt-file-content(
  title,             // Строка, например "OCHU" или "OCHS"
  data,              // Данные таблицы (массив массивов, как encoded-ochu)
  input-headers,     // Массив имен входных переменных, например ("a", "b", "c", "d", "e")
  output-headers,    // Массив имен выходных переменных, например ("F1", "F2", "F3", "F4")
  num-inputs         // Количество входных колонок для разделения
) = {
  let lines = ()

  // Строка 1: Заголовок
  lines.push(title)

  // Строка 2: Названия переменных
  let header = input-headers.join("") + "  " + output-headers.join("")
  lines.push(header)

  // Строки 3..N: Данные
  for row in data {
    // Разделяем строку на входы и выходы
    let inputs = row.slice(0, num-inputs)
    let outputs = row.slice(num-inputs, num-inputs + output-headers.len())

    if outputs.at(0) != "x" {
      // Форматируем каждую часть и объединяем
      let line = " " + inputs.join(" ") + "   " + outputs.join(" ")
      lines.push(line)
    }
  }

  // Объединяем все строки в один большой текстовый блок с переносами
  return lines.join("\n")
}