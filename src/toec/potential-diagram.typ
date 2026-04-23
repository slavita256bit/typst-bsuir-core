#import "@preview/cetz:0.5.0"
#import "math-helpers.typ": _fmt // Можно раскомментировать и использовать для форматирования

#let potential-diagram(
  points,
  width: 14,
  height: 8,
  x-label: $R", Ом"$,
  y-label: $phi", В"$,
  r-label-pos: "bottom" // По умолчанию все R снизу
) = {
  align(center, cetz.canvas({
    import cetz.draw: *
    import cetz.decorations // Импортируем модуль для фигурных скобок

    let xs = points.map(p => p.r)
    let ys = points.map(p => p.phi)

    let min-x = calc.min(0, ..xs)
    let max-x = calc.max(1, ..xs)
    let min-y = calc.min(0, ..ys)
    let max-y = calc.max(1, ..ys)

    let dx = (max-x - min-x) * 0.1
    let dy = (max-y - min-y) * 0.15
    let start-x = min-x - dx
    let end-x = max-x + dx
    let start-y = min-y - dy
    let end-y = max-y + dy

    let scale-x = width / (end-x - start-x)
    let scale-y = height / (end-y - start-y)

    let tx(x) = (x - start-x) * scale-x
    let ty(y) = (y - start-y) * scale-y

    let origin-x = tx(0)
    let origin-y = ty(0)

    // Оси
    line((origin-x, ty(start-y)), (origin-x, ty(end-y)), mark: (end: ">"), stroke: 1pt)
    content((origin-x, ty(end-y)), anchor: "south-east", padding: 0.2)[#y-label]

    line((tx(start-x), origin-y), (tx(end-x), origin-y), mark: (end: ">"), stroke: 1pt)
    content((tx(end-x), origin-y), anchor: "north-west", padding: 0.2)[#x-label]

    // Точка 0 в начале координат
    content((origin-x, origin-y), anchor: "north-east", padding: 0.1)[0]

    // Рисуем саму линию диаграммы
    let path-pts = points.map(p => (tx(p.r), ty(p.phi)))
    line(..path-pts, stroke: 1.5pt + black)

    // Узлы, их названия и проекции
    for p in points {
      let px = tx(p.r)
      let py = ty(p.phi)

      circle((px, py), radius: 0.08, fill: black)

      // Правильный выбор якоря для label
      let anchor-pos_label = p.at("anchor", default: if p.phi >= 0 { "south-east" } else { "north-east" })
      let padding = if (p.at("anchor").contains("-")) {0.15} else {0.3}
      if "label" in p {
        content((px, py), anchor: anchor-pos_label, padding: padding)[#p.label]
      }

      // Проекции на оси
      if calc.abs(p.phi) > 0.01 {
        // Проекция на ось X
        line((px, py), (px, origin-y), stroke: (dash: "dashed", thickness: 0.5pt, paint: gray))

        if p.at("show-phi", default: true) {
            // НОВОЕ: Проекция на ось Y + Подпись значения потенциала
            line((px, py), (origin-x, py), stroke: (dash: "dashed", thickness: 0.5pt, paint: gray))

            // Форматируем число (меняем точку на запятую). Если используете _fmt, можно заменить на #_fmt(p.phi)
    //         let val = str(p.phi).replace(".", ",")
            let val = _fmt(p.phi)
            content((origin-x, py), anchor: "east", padding: 0.15)[#val]
        }
      }
    }

    // Скобочки для резисторов и подписи ЭДС
    for i in range(points.len() - 1) {
    let p1 = points.at(i)
    let p2 = points.at(i+1)

    if calc.abs(p2.r - p1.r) > 0.001 {
       let x1 = tx(p1.r)
       let x2 = tx(p2.r)

       // ОПРЕДЕЛЯЕМ ПОЗИЦИЮ (смотрим в точку p2 или берем общую для функции)
       let pos = p2.at("r-pos", default: r-label-pos)

       let y-brace = 0
       let y-text = 0
       let brace-flip = true
       let text-anchor = "north"

       if pos == "top" {
         y-brace = ty(max-y) + 0.3 // Чуть выше верхнего края графика
         y-text = y-brace + 0.4
         brace-flip = false
         text-anchor = "south"
       } else {
         y-brace = origin-y - 0.15 // Под осью X
         y-text = y-brace - 0.4
         brace-flip = true
         text-anchor = "north"
       }

       // Рисуем фигурную скобку
       decorations.brace((x1, y-brace), (x2, y-brace), flip: brace-flip, amplitude: 0.25, stroke: 0.8pt)

       if "r-label" in p2 {
         content(((x1+x2)/2, y-text), anchor: text-anchor, padding: 0.1)[#p2.r-label]
       }

       // Если есть вертикальный скачок - подписываем ЭДС сбоку
      if calc.abs(p2.phi - p1.phi) > 0.001 and calc.abs(p2.r - p1.r) < 0.001 {
         let mid-y = ty((p1.phi + p2.phi) / 2)
         let px = tx(p1.r)
         if "e-label" in p2 {
           let align = if p1.r < (start-x + end-x) / 2 { "east" } else { "west" }
           content((px, mid-y), anchor: align, padding: 0.2)[#p2.e-label]
         }
      }
    }}
  }))
}

#figure(
  potential-diagram((
    (r: 0,   phi: 0,     label: [г], anchor: "south-east"),
    (r: 1.0, phi: 3.40,  label: [д], anchor: "south-east", r-label: $R_6$),
    (r: 1.0, phi: 18.40, label: [e], anchor: "south", e-label: move(dy: 1.3em, $E_1$)),
    (r: 4.9, phi: 11.26123123123, label: [a], anchor: "south", r-label: $R_1$),
    (r: 6.1, phi: 15.34, label: [б], anchor: "south", r-label: $R_2$, show-phi: false),
    (r: 8.1, phi: 30.00, label: [в], anchor: "south", r-label: $R_3$),
    (r: 8.1, phi: 0,     anchor: "south-west", e-label: $E_3$),
  ))
)