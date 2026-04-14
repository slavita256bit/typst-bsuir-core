#import "mathtype-mimic.typ": mathtype-mimic

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

// Расчет параллельного соединения
#let calc-par(name, r1, r2, v1, v2, res, unit: "кОм", receive: false, d-args: 2, d-res: 3) = {
  let f1 = _fmt(v1, digits: d-args)
  let f2 = _fmt(v2, digits: d-args)
  let fres = _fmt(res, digits: d-res)
  mathtype-mimic(receive: receive, [
    $ R_#name = (R_#r1 R_#r2) / (R_#r1 + R_#r2) = (#f1 dot #f2) / (#f1 + #f2) = #fres #unit. $
  ])
}

// Расчет последовательного соединения
#let calc-seq(name, rs, vs, res, unit: "кОм", receive: false, d-args: 2, d-res: 3) = {
  let fvs = _fmt(vs, digits: d-args)
  let fres = _fmt(res, digits: d-res)
  mathtype-mimic(receive: receive, [
    $ R_#name = #rs.map(r => $R_#r$).join($+$) = #fvs.join($+$) = #fres #unit. $
  ])
}

// Базовое деление (Закон Ома)
#let calc-div(left, top-sym, bot-sym, top-val, bot-val, res, unit: "мА", receive: false, d-args: 2, d-res: 3) = {
  let ftop = _fmt(top-val, digits: d-args)
  let fbot = _fmt(bot-val, digits: d-args)
  let fres = _fmt(res, digits: d-res)
  mathtype-mimic(receive: receive, [
    $ #left = #top-sym / #bot-sym = #ftop / #fbot = #fres #unit. $
  ])
}

// Хелпер для расчета проводимости (сумма обратных сопротивлений)
// Принимает имя узла (напр. "11"), массив индексов сопротивлений ("1", "2") и их значения как числа
#let calc-g(name, r-indices, r-vals, receive: false) = {
  // Считаем математический результат
  let res-val = r-vals.map(v => 1 / v).sum()

  // Формируем символьную часть: 1/R1 + 1/R2 ...
  let sym-part = r-indices.map(i => $1 / R_#i$).join($+$)

  // Формируем часть с числами: 1/2.4 + 1/2.0 ...
  let num-part = r-vals.map(v => $1 / #_fmt(v)$).join($+$)

  mathtype-mimic(receive: receive, [
    $ g_#name = #sym-part = #num-part = #_fmt(calc.round(res-val, digits: 3)) " См". $
  ])
}

// Хелпер для Закона Ома ветви (с ЭДС и разностью потенциалов)
// I = (phi_start - phi_end + E) / R
#let calc-branch-i(i-idx, phi-s-idx, phi-e-idx, e-idx, r-idx, phi-s-val, phi-e-val, e-val, r-val, receive: false) = {

  // Вычисляем результат в мА
  let res-val = (phi-s-val - phi-e-val + e-val) / r-val

  // Собираем числитель символьно
  let num-sym = ()
  if phi-s-idx != none { num-sym.push($phi_#phi-s-idx$) }
  if phi-e-idx != none { num-sym.push($- phi_#phi-e-idx$) }
  if e-idx != none {
    if e-val > 0 { num-sym.push($+ E_#e-idx$) } else { num-sym.push($- E_#e-idx$) }
  }
  let sym-top = num-sym.join()

  // Собираем числитель с числами
  let num-vals = ()
  if phi-s-idx != none { num-vals.push($#_fmt(calc.round(phi-s-val, digits: 3))$) }
  if phi-e-idx != none { num-vals.push($- #_fmt(calc.round(phi-e-val, digits: 3))$) }
  if e-idx != none {
    if e-val > 0 { num-vals.push($+ #_fmt(e-val)$) } else { num-vals.push($- #_fmt(calc.abs(e-val))$) }
  }
  let val-top = num-vals.join()

  mathtype-mimic(receive: receive, [
    $ I_#i-idx = (#sym-top) / R_#r-idx = (#val-top) / #_fmt(r-val) = #_fmt(calc.round(res-val, digits: 3)) " мА". $
  ])
}


// Правило плеч
#let calc-shoulder(left, i-sym, r-top, r-bot, i-val, top-val, bot-val, res, unit: "мА", receive: false, d-args: 2, d-res: 3) = {
  let fi = _fmt(i-val, digits: d-args)
  let ftop = _fmt(top-val, digits: d-args)
  let fbot = _fmt(bot-val, digits: d-args)
  let fres = _fmt(res, digits: d-res)
  mathtype-mimic(receive: receive, [
    $ #left = #i-sym #r-top / (#r-bot) = #fi (#ftop) / (#fbot) = #fres #unit. $
  ])
}

// Просто передаем сырые float-числа через точку!
#calc-par("23456", "5", "2346", 1.5, 3.52, 1.05)

// Если нужно изменить точность для конкретной формулы:
#calc-par("23456", "5", "2346", 1.5, 3.52, 1.05, d-args: 3, d-res: 4)