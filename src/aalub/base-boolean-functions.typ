// ГЕНЕРАТОР БАЗОВОЙ ОЧС (Математика)
// Генерирует массив: (a, b, p, Pi, S, "комментарий")
#let generate-base-ochs(mask-fn: none) = {
  let rows = ()

  for a in (0, 1, 2, 3) {
    for b in (0, 1, 2, 3) {
      for p in (0, 1) {
        let sum = a + b + p
        let Pi = calc.quo(sum, 4) // Перенос
        let S = calc.rem(sum, 4)  // Сумма

        let comment = str(a) + "+" + str(b) + "+" + str(p) + "=" + str(Pi) + str(S)

        let Pi-str = str(Pi)
        let S-str = str(S)

        // МАГИЯ ЗДЕСЬ: Если передана функция маски, вызываем её.
        // Передаем ей текущие a, b, p. Если она возвращает true — ставим крестики!
        if mask-fn != none and mask-fn(a, b, p) {
          Pi-str = "x"
          S-str = "x"
        }

        rows.push((str(a), str(b), str(p), Pi-str, S-str, comment))
      }
    }
  }
  return rows
}

// Превращает словарь в красивую строку: "0 – 00; 1 – 11; 2 – 10; 3 – 01"
#let encoding-as-text(code-dict) = {
  code-dict.keys().sorted().map(k => [#k – #code-dict.at(k)]).join([; ]) + "."
}