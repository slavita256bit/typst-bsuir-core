// АВТОМАТИЧЕСКИЙ ГЕНЕРАТОР БУЛЕВЫХ ФУНКЦИЙ (МДНФ / МКНФ)
// Анализирует геометрию групп (r, c, w, h) на соответствие карте переменных (vars-map)
#let generate-boolean-function(
  groups,
  vars-map,
  var-names,       // Массив названий переменных в math, например: ($x_1$, $x_2$, $y_1$, $y_2$, $h$)
  rows: 4,
  cols: 4,
  is-dnf: true     // true = МДНФ, false = МКНФ
) = {

  // 0. Группируем контуры по полю `id`.
  // Если у контуров одинаковый `id`, они станут одной импликантой.
  // Если `id` нет, используем уникальный индекс (поведение по умолчанию).
  let logical-groups = (:)
  for (i, g) in groups.enumerate() {
    let key = str(g.at("id", default: -i))
    if key not in logical-groups {
      logical-groups.insert(key, ())
    }
    logical-groups.at(key).push(g)
  }

  let terms = ()

  // Итерируемся по сгруппированным логическим контурам
  for (_, sub-groups) in logical-groups {
    // 1. Собираем все координаты (r, c), со ВСЕХ частей этой группы
    let covered-cells = ()
    for g in sub-groups {
      for r-idx in range(g.h) {
        let r = calc.rem(g.r + r-idx, rows)
        for c-idx in range(g.w) {
          let c = calc.rem(g.c + c-idx, cols)
          covered-cells.push((r: r, c: c))
        }
      }
    }

    // 2. Смотрим, как ведут себя переменные внутри этих ячеек
    let term-vars = ()
    for (i, vmap) in vars-map.enumerate() {
      let all-ones = true
      let all-zeros = true

      for cell in covered-cells {
        let is-one = false
        if "r" in vmap {
          let r-ones = if type(vmap.r) == array { vmap.r } else { (vmap.r,) }
          if cell.r in r-ones { is-one = true }
        }
        if "c" in vmap {
          let c-ones = if type(vmap.c) == array { vmap.c } else { (vmap.c,) }
          if cell.c in c-ones { is-one = true }
        }

        if is-one { all-zeros = false } else { all-ones = false }
      }

      // Если переменная не меняет свое значение - оставляем её в импликанте
      if all-ones { term-vars.push((name: var-names.at(i), val: 1)) }
      else if all-zeros { term-vars.push((name: var-names.at(i), val: 0)) }
    }

    // 3. Форматируем импликанту
    if term-vars.len() == 0 {
       terms.push(if is-dnf { $1$ } else { $0$ })
    } else {
       let term-content = ()
       for tv in term-vars {
         let name = tv.name
         // Логика инверсий для МДНФ и МКНФ
         if is-dnf {
           if tv.val == 1 { term-content.push(name) }
           else { term-content.push(math.overline(name)) }
         } else {
           if tv.val == 1 { term-content.push(math.overline(name)) }
           else { term-content.push(name) }
         }
       }

       if is-dnf {
         terms.push(term-content.join()) // x1 * x2
       } else {
         terms.push($(#term-content.join($+$))$) // (x1 + x2)
       }
    }
  }

  // 4. Собираем итоговое выражение 
  if terms.len() == 0 {
     return if is-dnf { $0$ } else { $1$ }
  }

  if is-dnf {
    return terms.join($+$)
  } else {
    return terms.join() // Неявное умножение: (a+b)(c+d)
  }
}

// Удобные алиасы для вызова
#let get-mdnf(groups, vars-map, var-names, rows: 4, cols: 4) = {
  generate-boolean-function(groups, vars-map, var-names, rows: rows, cols: cols, is-dnf: true)
}

#let get-mcnf(groups, vars-map, var-names, rows: 4, cols: 4) = {
  generate-boolean-function(groups, vars-map, var-names, rows: rows, cols: cols, is-dnf: false)
}

// УНИВЕРСАЛЬНЫЙ ПРЕОБРАЗОВАТЕЛЬ В БАЗИС "ИЛИ / НЕ"
// (Заменяет get-nor-basis и get-or-not-basis)

#let generate-or-not-expression(
  groups,
  vars-map,
  var-names,
  rows: 4,
  cols: 4,
  is-dnf: true // true = работаем с МДНФ (группы единиц), false = с МКНФ (группы нулей)
) = {
  // --- Шаг 1: Парсинг контуров (без изменений) ---
  let logical-groups = (:)
  for (i, g) in groups.enumerate() {
    let key = str(g.at("id", default: -i))
    if key not in logical-groups { logical-groups.insert(key, ()) }
    logical-groups.at(key).push(g)
  }

  // --- Шаг 2: Генерация термов ---
  let terms = ()
  for (_, sub-groups) in logical-groups {
    let covered-cells = ()
    for g in sub-groups {
      for r-idx in range(g.h) {
        let r = calc.rem(g.r + r-idx, rows)
        for c-idx in range(g.w) {
          let c = calc.rem(g.c + c-idx, cols)
          covered-cells.push((r: r, c: c))
        }
      }
    }

    let term-vars = ()
    for (i, vmap) in vars-map.enumerate() {
      let all-ones = true; let all-zeros = true
      for cell in covered-cells {
        let is-one = false
        if "r" in vmap {
          let r-ones = if type(vmap.r) == array { vmap.r } else { (vmap.r,) }
          if cell.r in r-ones { is-one = true }
        }
        if "c" in vmap {
          let c-ones = if type(vmap.c) == array { vmap.c } else { (vmap.c,) }
          if cell.c in c-ones { is-one = true }
        }
        if is-one { all-zeros = false } else { all-ones = false }
      }
      if all-ones { term-vars.push((name: var-names.at(i), val: 1)) }
      else if all-zeros { term-vars.push((name: var-names.at(i), val: 0)) }
    }

    // --- Шаг 3: Преобразование термов в базис ИЛИ/НЕ ---
    if term-vars.len() == 0 {
      // Группа покрывает всю карту
      terms.push(if is-dnf { $1$ } else { $0$ })
    } else {
      if is-dnf {
        // --- Логика для МДНФ (F = T1 + T2) ---
        // Преобразуем каждый терм-произведение T в overline(сумма инверсий)
        let term-content = ()
        for tv in term-vars {
          if tv.val == 1 { term-content.push(math.overline(tv.name)) }
          else { term-content.push($#tv.name$) }
        }
        terms.push(math.overline(term-content.join($+$)))
      } else {
        // --- Логика для МКНФ (F = T1 * T2) ---
        // Оставляем каждый терм-сумму T как есть (пока что)
        let term-content = ()
        for tv in term-vars {
          if tv.val == 1 { term-content.push(math.overline(tv.name)) }
          else { term-content.push(tv.name) }
        }
        terms.push($(#term-content.join($+$))'$) // Используем кавычки для группировки
      }
    }
  }

  // --- Шаг 4: Сборка финального выражения ---
  if terms.len() == 0 {
    return if is-dnf { $0$ } else { $1$ }
  }

  if is-dnf {
    // Для МДНФ: просто складываем преобразованные термы
    // F = overline(...) + overline(...)
    return terms.join($+$)
  } else {
    // Для МКНФ: применяем де Моргана к произведению скобок
    // F = T1 * T2  =>  F = overline(overline(T1) + overline(T2))
    // Ключевое исправление: добавляем внешнюю инверсию!
    let inverted-terms = terms.map(t => math.overline(t))
    return math.overline(inverted-terms.join($+$))
  }
}

// todo проверить
// Возвращает абстрактное синтаксическое дерево (AST) функции для отрисовки схемы
#let get-mdnf-ast(
  groups,
  vars-map,
  var-names-str,  // ВАЖНО: сюда передаем СТРОКИ ("x1", "x2"), а не math!
  rows: 4,
  cols: 4
) = {
  let logical-groups = (:)
  for (i, g) in groups.enumerate() {
    let key = str(g.at("id", default: -i))
    if key not in logical-groups { logical-groups.insert(key, ()) }
    logical-groups.at(key).push(g)
  }

  let terms = ()

  for (_, sub-groups) in logical-groups {
    let covered-cells = ()
    for g in sub-groups {
      for r-idx in range(g.h) {
        let r = calc.rem(g.r + r-idx, rows)
        for c-idx in range(g.w) {
          let c = calc.rem(g.c + c-idx, cols)
          covered-cells.push((r: r, c: c))
        }
      }
    }

    let term-content = ()
    for (i, vmap) in vars-map.enumerate() {
      let all-ones = true
      let all-zeros = true

      for cell in covered-cells {
        let is-one = false
        if "r" in vmap {
          let r-ones = if type(vmap.r) == array { vmap.r } else { (vmap.r,) }
          if cell.r in r-ones { is-one = true }
        }
        if "c" in vmap {
          let c-ones = if type(vmap.c) == array { vmap.c } else { (vmap.c,) }
          if cell.c in c-ones { is-one = true }
        }
        if is-one { all-zeros = false } else { all-ones = false }
      }

      // Формируем строковые идентификаторы для схемы
      if all-ones { term-content.push(var-names-str.at(i)) }
      else if all-zeros { term-content.push("!" + var-names-str.at(i)) }
    }

    if term-content.len() > 0 {
      terms.push(term-content)
    }
  }

  return terms
}