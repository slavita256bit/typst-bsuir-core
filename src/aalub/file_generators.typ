// Генератор файла по таблице истинности для проверки на устройтве
#let generate-tt-file-content(
  title,             // Строка, например "OCHU" или "OCHS"
  data,              // Данные таблицы (массив массивов, как encoded-ochu)
  input-headers,     // Массив имен входных переменных, например ("a", "b", "c", "d", "e")
  output-headers    // Массив имен выходных переменных, например ("F1", "F2", "F3", "F4")
) = {
  let num-inputs = input-headers.len()
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

//     if outputs.at(0) != "x" {
      // Форматируем каждую часть и объединяем
      let line = " " + inputs.join(" ") + "   " + outputs.join(" ")
      lines.push(line)
//     }
  }

  // Объединяем все строки в один большой текстовый блок с переносами
  return lines.join("\n")
}

// Генератор файла для алгоритма рота (моего)
#let generate-rots-file-content(
  title,             // Строка, например "OCHU" или "OCHS"
  data,              // Данные таблицы (массив массивов, как encoded-ochu)
  input-labels,     // Массив имен входных переменных, например ("a", "b", "c", "d", "e")
  num-output        // Номер выходной колонока
) = {
  let num-inputs = input-labels.len()
  let lines = ()

  let count_1 = 0
  let count_x = 0
  for row in data {
    let inputs = row.slice(0, num-inputs)
    let output = row.at(num-output)

    if output == "x" {count_x += 1}
    if output == "1" {count_1 += 1}
  }

  lines.push(str(num-inputs))

  lines.push(str(count_1))
  for row in data {
    let inputs = row.slice(0, num-inputs)
    let output = row.at(num-output)

    if output == "1" {lines.push(inputs.join(""))}
  }

  lines.push(str(count_x))
  for row in data {
    let inputs = row.slice(0, num-inputs)
    let output = row.at(num-output)

    if output == "x" {lines.push(inputs.join(""))}
  }

  for label in input-labels {
    lines.push(label)
  }

  return lines.join("\n")
}

