#import "complex-math.typ": *
#import "mathtype-mimic.typ": mathtype-mimic
#import "fmt.typ": *

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

// --- Базовые элементы ---
#let calc-reactance-L(f, L, symbol: "L", L-unit: "mH") = {
  let L-val = L * 1e-3
  let w = 2 * calc.pi * f
  let XL = w * L-val

  let display = mathtype-mimic[
    $ X_L = omega #symbol = 2 pi f #symbol = 2 dot calc.pi dot #f dot #L dot 10^(-3) = #_fmt(XL) " Ом". $
  ]
  (val: XL, display: display)
}

#let calc-reactance-C(f, C, symbol: "C", C-unit: "µF") = {
  let C-val = C * 1e-6
  let w = 2 * calc.pi * f
  let XC = 1 / (w * C-val)

  let display = mathtype-mimic[
    $ X_C = 1 / (omega #symbol) = 1 / (2 pi f #symbol) = 1 / (2 dot calc.pi dot #f dot #C dot 10^(-6)) = #_fmt(XC) " Ом". $
  ]
  (val: XC, display: display)
}

// --- Комбинации элементов ---
#let calc-series-impedance(components, symbol: "вх") = {
  let R_total = components.filter(c => c.type == "R").map(c => c.val).sum()
  let XL_total = components.filter(c => c.type == "XL").map(c => c.val).sum()
  let XC_total = components.filter(c => c.type == "XC").map(c => c.val).sum()
  let X_total = XL_total - XC_total

  let Z = rect(R_total, X_total)

  let symbolic-R = components.filter(c => c.type == "R").map(c => c.symbol).join($+$)
  let symbolic-X = $X_L - X_C$ // Упрощено для примера, можно сделать сложнее

  let display = mathtype-mimic[
    $ dot(Z)_#symbol = (#symbolic-R) + j(#symbolic-X) = #display-complex(Z).both " Ом." $
  ]
  (val: Z, display: display)
}

// --- Законы цепей ---
#let calc-ohms-law(U, Z, I-symbol: "I") = {
  let I = div(U, Z)
  let I-mA = polar(I.mag * 1000, I.ang) // Сразу в мА для удобства

  let display = mathtype-mimic[
    $ dot(#I-symbol) = dot(U) / dot(Z) = #display-complex(U).polar / #display-complex(Z).polar = #display-complex(I-mA).polar " мА". $
  ]
  (val: I, val-mA: I-mA, display: display)
}

#let calc-voltage-drop(I, Z, U-symbol: "U") = {
  let U = mul(I, Z)
  let display = mathtype-mimic[
    $ dot(#U-symbol) = dot(I) dot(Z) = #display-complex(I).polar dot #display-complex(Z).polar = #display-complex(U).polar " В". $
  ]
  (val: U, display: display)
}

#let calc-voltage-drop-explicit(I, Z, Z-sym, Z-val, U-symbol: "U") = {
  let U_res = mul(I, Z)
  let I-p = to-polar(I)
  let U-p = to-polar(U_res)

  let display = mathtype-mimic[
    $ dot(#U-symbol) = dot(I) (#Z-sym) = #display-complex(I-p).polar dot (#Z-val) = #display-complex(U-p).polar " В". $
  ]
  return (val: U_res, display: display)
}

#let add_j(value) = {
  return [#if value > 0 { $j$ } else { $-j$ } #_fmt(value)]
}


// Просто передаем сырые float-числа через точку!
#calc-par("23456", "5", "2346", 1.5, 3.52, 1.05)

// Если нужно изменить точность для конкретной формулы:
#calc-par("23456", "5", "2346", 1.5, 3.52, 1.05, d-args: 3, d-res: 4)
