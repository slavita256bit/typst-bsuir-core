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