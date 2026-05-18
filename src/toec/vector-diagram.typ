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
  current-color: rgb("#000000"),
  voltage-color: rgb("#000000"),
  voltage-scale: none,
  current-scale: none,
  scale-label-pos: "start",
) = {
  // ДОБАВЬТЕ ЭТИ ДВЕ СТРОЧКИ СЮДА:
  import "@preview/zap:0.5.0"
  import "complex-math.typ": to-rect

  align(center, zap.cetz.canvas({
    import zap.cetz.draw: *

    // 1. Вычисляем границы осей.
    let x-min = if type(axes.x) == array { axes.x.at(0) } else { -axes.x }
    let x-max = if type(axes.x) == array { axes.x.at(1) } else { axes.x }
    let y-min = if type(axes.y) == array { axes.y.at(0) } else { -axes.y/2 }
    let y-max = if type(axes.y) == array { axes.y.at(1) } else { axes.y/2 }
    // Сетка по заданным границам
    grid((x-min, y-min), (x-max, y-max), step: 1, stroke: luma(230) + 0.5pt)

    // Ось Y
    line((0, y-min - 0.5), (0, y-max + 0.5), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((0, y-max + 0.5), anchor: "south-west", padding: 0.1, [$+j$])

    // Ось X
    line((x-min - 0.5, 0), (x-max + 0.5, 0), mark: (end: "stealth", fill: black), stroke: 1pt + black)
    content((x-max + 0.5, 0), anchor: "north-west", padding: 0.1, [$+1$])

    // Ноль в начале координат
    content((-0.2, -0.2), anchor: "north-east", text(size: 9pt)[0])

    // Метки масштаба на осях
    if voltage-scale != none or current-scale != none {
      let tick = 0.15
      let lbl-size = 14pt

      if scale-label-pos == "end" {
        // Позиция: ПРЕДПОСЛЕДНЯЯ КЛЕТКА относительно максимума
        let target-x = x-max - 1
        let target-y = y-max - 1

        if voltage-scale != none {
          let base-val = voltage-scale.value
          let x-label-val = base-val * target-x
          let y-label-val = base-val * target-y

          // Засечка и текст на оси X
          line((target-x, -tick), (target-x, tick), stroke: 1pt + black)
          content((target-x, tick), anchor: "south", padding: 0.1, text(size: lbl-size)[#x-label-val, #voltage-scale.unit])

          // Засечка и текст на оси Y
          line((-tick, target-y), (tick, target-y), stroke: 1pt + black)
          content((-tick, target-y), anchor: "east", padding: 0.1, text(size: lbl-size)[#y-label-val, #voltage-scale.unit])
        }

        if current-scale != none {
          let base-val = current-scale.value
          let x-label-val = base-val * target-x
          let y-label-val = base-val * target-y

          // Текст для тока на оси X
          line((target-x, -tick), (target-x, tick), stroke: 1pt + black)
          content((target-x, -tick), anchor: "north", padding: 0.1, text(size: lbl-size)[#x-label-val, #current-scale.unit])

          // Текст для тока на оси Y
          line((-tick, target-y), (tick, target-y), stroke: 1pt + black)
          content((tick, target-y), anchor: "west", padding: 0.1, text(size: lbl-size)[#y-label-val, #current-scale.unit])
        }
      }
    }

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

    if sum-voltage != none and sum-voltage.at("enabled", default: true) {
      let col = sum-voltage.at("color", default: voltage-color)
      draw-vec((0,0), volt-sum, sum-voltage.at("label", default: none), col, is-dashed: true, lbl-anchor: sum-voltage.at("anchor", default: "south-west"))
    }
  }))

  v(1em)
}

#let scale_pt(c, scale) = (to-rect(c).re * scale, to-rect(c).im * scale)