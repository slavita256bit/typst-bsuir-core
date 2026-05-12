#import "@preview/zap:0.5.0"
#import "complex-math.typ": to-rect

#let vector-diagram(
  currents: (),
  voltages: (),
  axes: (x: 6, y: 12),
  chain-voltages: false,
  chain-currents: false,
  sum-voltage: none,
  sum-current: none,
  current-color: rgb("e63946"),
  voltage-color: rgb("1d3557")
) = {
  align(center, zap.cetz.canvas({
    import zap.cetz.draw: *

    // Сетка (теперь симметричная относительно оси Y)
    grid((-axes.x, -axes.y/2), (axes.x, axes.y/2), step: 1, stroke: luma(230) + 0.5pt)

    // Оси
    line((0, -axes.y/2 - 0.5), (0, axes.y/2 + 0.5), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((0, axes.y/2 + 0.5), anchor: "south-west", padding: 0.1, [$+j$])

    line((-axes.x - 0.5, 0), (axes.x + 0.5, 0), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((axes.x + 0.5, 0), anchor: "north-west", padding: 0.1, [$+1$])

    // Оси
    line((0, -axes.y/2 - 0.5), (0, axes.y/2 + 0.5), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((0, axes.y/2 + 0.5), anchor: "south-west", padding: 0.1, [$+j$])

    line((-1.5, 0), (axes.x + 0.5, 0), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((axes.x + 0.5, 0), anchor: "north-west", padding: 0.1, [$+1$])

    // Функция отрисовки вектора
    let draw-vec(start, end, label, col, is-dashed: false, lbl-anchor: "south-west") = {
      line(start, end, mark: (end: "stealth", fill: col), stroke: 1.5pt + col)
      if is-dashed {
        line((0,0), end, stroke: (dash: "dashed", paint: col, thickness: 0.8pt))
      }
      if label != none {
        content(end, padding: 0.2, anchor: lbl-anchor, text(fill: col)[#label])
      }
    }

    // --- ОТРИСОВКА ТОКОВ ---
    let curr-sum = (0.0, 0.0)
    let curr-accum = (0.0, 0.0)
    for item in currents {
      let start = (0.0, 0.0)
      let end = (0.0, 0.0)
      // Берем цвет из элемента, иначе глобальный для токов
      let col = item.at("color", default: current-color)

      if "val" in item {
        let c-val = to-rect(item.val)
        let scale = item.at("scale", default: 1)
        let dx = float(c-val.re) * scale
        let dy = float(c-val.im) * scale

        start = if chain-currents { curr-accum } else { (0.0, 0.0) }
        end = (start.at(0) + dx, start.at(1) + dy)

        curr-accum = end
        curr-sum = (curr-sum.at(0) + dx, curr-sum.at(1) + dy)
      } else {
        start = item.start
        end = item.end
        curr-accum = end
        curr-sum = end
      }

      draw-vec(start, end, item.at("label", default: none), col, is-dashed: item.at("dashed", default: false), lbl-anchor: item.at("anchor", default: "south-west"))
    }

    // Отрисовка суммарного тока (если передан и enabled не равен false)
    if sum-current != none and sum-current.at("enabled", default: true) {
      let col = sum-current.at("color", default: current-color)
      draw-vec((0,0), curr-sum, sum-current.at("label", default: none), col, is-dashed: true, lbl-anchor: sum-current.at("anchor", default: "south-west"))
    }

    // --- ОТРИСОВКА НАПРЯЖЕНИЙ ---
    let volt-sum = (0.0, 0.0)
    let volt-accum = (0.0, 0.0)
    for item in voltages {
      let start = (0.0, 0.0)
      let end = (0.0, 0.0)
      // Берем цвет из элемента, иначе глобальный для напряжений
      let col = item.at("color", default: voltage-color)

      if "val" in item {
        let c-val = to-rect(item.val)
        let scale = item.at("scale", default: 1)
        let dx = float(c-val.re) * scale
        let dy = float(c-val.im) * scale

        start = if chain-voltages { volt-accum } else { (0.0, 0.0) }
        end = (start.at(0) + dx, start.at(1) + dy)

        volt-accum = end
        volt-sum = (volt-sum.at(0) + dx, volt-sum.at(1) + dy)
      } else {
        start = item.start
        end = item.end
        volt-accum = end
        volt-sum = end
      }

      draw-vec(start, end, item.at("label", default: none), col, is-dashed: item.at("dashed", default: false), lbl-anchor: item.at("anchor", default: "south-west"))
    }

    // Отрисовка суммарного напряжения (если передан и enabled не равен false)
    if sum-voltage != none and sum-voltage.at("enabled", default: true) {
      let col = sum-voltage.at("color", default: voltage-color)
      draw-vec((0,0), volt-sum, sum-voltage.at("label", default: none), col, is-dashed: true, lbl-anchor: sum-voltage.at("anchor", default: "south-west"))
    }
  }))

  v(1em)
}