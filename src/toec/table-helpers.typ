// Базовая логика для ОДНОЙ ячейки
#let _format-cell(val, dec: 2, size: 10pt) = {
  if type(val) in (float, int) {
    let rounded = calc.round(float(val), digits: dec)
    let str-val = str(rounded)
    let parts = str-val.split(".")

    let int-part = parts.at(0)
    let frac-part = if parts.len() > 1 { parts.at(1) } else { "" }

    while frac-part.len() < dec { frac-part += "0" }

    let final-str = if dec > 0 {
      int-part + "," + sym.wj + frac-part
    } else { int-part }

    text(size: size)[#final-str]
  } else {
    // Если это текст/формула, просто применяем размер
    text(size: size)[#val]
  }
}

// Форматирует любое количество значений разом.
// Использование: ..format-cells(1, 2, 3, dec: 2) или ..format-cells(my_array)
#let format-cells(..values, dec: 2, size: 12pt) = {
  values.pos().flatten().map(v => _format-cell(v, dec: dec, size: size))
}

// Поворачивает на 90 градусов любое количество элементов
// Использование: ..rotate-cells([A], [B], [C])
#let rotate-cells(..values) = {
  values.pos().flatten().map(v => rotate(-90deg, reflow: true)[#v])
}