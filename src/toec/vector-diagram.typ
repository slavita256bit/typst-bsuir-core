#import "@preview/zap:0.5.0"

#let vector-diagram(currents: (), voltages: (), axes: (x: 6, y: 12)) = {
  align(center, zap.cetz.canvas({
    import zap.cetz.draw: *

    // Сетка
    grid((-1, -axes.y/2), (axes.x, axes.y/2), step: 1, stroke: luma(230) + 0.5pt)

    // Оси комплексной плоскости
    line((0, -axes.y/2 - 0.5), (0, axes.y/2 + 0.5), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((0, axes.y/2 + 0.5), anchor: "south-west", padding: 0.1, [$+j$])

    line((-1.5, 0), (axes.x + 0.5, 0), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((axes.x + 0.5, 0), anchor: "north-west", padding: 0.1, [$+1$])

    // Функция отрисовки одного вектора
    let draw-vec(start, end, label, col, is-dashed: false, lbl-anchor: "south-west") = {
      line(start, end, mark: (end: "stealth", fill: col), stroke: 1.5pt + col)
      if is-dashed {
        // Пунктир от начала координат (для демонстрации полного вектора)
        line((0,0), end, stroke: (dash: "dashed", paint: col, thickness: 0.8pt))
      }
      content(end, padding: 0.15, anchor: lbl-anchor, text(fill: col)[#label])
    }

    // Отрисовка токов (красные)
    for c in currents {
      draw-vec(c.start, c.end, c.label, rgb("e63946"), lbl-anchor: "south-east")
    }

    // Отрисовка напряжений (синие)
    for v in voltages {
      draw-vec(v.start, v.end, v.label, rgb("1d3557"), is-dashed: v.at("dashed", default: false), lbl-anchor: v.at("anchor", default: "south-west"))
    }
  }))
}