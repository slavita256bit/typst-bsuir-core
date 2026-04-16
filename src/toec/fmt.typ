// Умное форматирование чисел с нужным количеством знаков
#let _fmt(val, digits: 2) = {
  // Если это массив чисел, применяем форматирование ко всем элементам
  if type(val) == array {
    return val.map(v => _fmt(v, digits: digits))
  }

  // Безопасное превращение строк (даже с запятыми) в числа
  let num = val
  if type(val) == str {
    let clean = val.replace(",", ".")
    if clean.match(regex("^-?\d+(\.\d+)?$")) != none {
      num = float(clean)
    }
  }

  // Основная логика округления и добивки нулями
  if type(num) in (float, int) {
    let rounded = calc.round(float(num), digits: digits)
    let str-val = str(rounded).replace(".", ",")
    let parts = str-val.split(",")
    let int-part = parts.at(0)
    let frac-part = if parts.len() > 1 { parts.at(1) } else { "" }

    // Добиваем недостающие нули
    while frac-part.len() < digits {
      frac-part += "0"
    }

    if digits > 0 { int-part + "," + sym.wj + frac-part } else { int-part }
  } else {
    // Если это Content (например, текст или сложное выражение), оставляем как есть
    val
  }
}