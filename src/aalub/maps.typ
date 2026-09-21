#let mark-groups(groups, cell-size, cols, rows, offset) = {
    // Рамки группировок
    for g in groups {
      let start-c = g.c; let start-r = g.r; let w = g.w; let h = g.h;
      let c-color = g.at("color", default: red); let pad = g.at("pad", default: 3pt);
      let c-dash = g.at("dash", default: "solid");
      let draw-rect(r, c, rw, rh, open-edges) = {
        let x = offset + c * cell-size; let y = offset + r * cell-size;
        let width = rw * cell-size; let height = rh * cell-size; let stroke-w = 1pt;
        let base-stroke = (paint: c-color, thickness: stroke-w, dash: c-dash);
        let s-top = if "top" in open-edges { none } else { base-stroke };
        let s-bot = if "bottom" in open-edges { none } else { base-stroke };
        let s-left = if "left" in open-edges { none } else { base-stroke };
        let s-right = if "right" in open-edges { none } else { base-stroke };
        let rad = 6pt;
        place(top + left, dx: x + pad, dy: y + pad,
          rect(width: width - pad*2, height: height - pad*2,
            stroke: (top: s-top, bottom: s-bot, left: s-left, right: s-right), radius: rad))
      };
      let wrap-x = start-c + w > cols; let wrap-y = start-r + h > rows;
      if not wrap-x and not wrap-y { draw-rect(start-r, start-c, w, h, ()) }
      else if wrap-x and not wrap-y { let w1 = cols - start-c; let w2 = w - w1; draw-rect(start-r, start-c, w1, h, ("right",)); draw-rect(start-r, 0, w2, h, ("left",)) }
      else if wrap-y and not wrap-x { let h1 = rows - start-r; let h2 = h - h1; draw-rect(start-r, start-c, w, h1, ("bottom",)); draw-rect(0, start-c, w, h2, ("top",)) }
      else { let w1 = cols-start-c; let w2 = w-w1; let h1 = rows-start-r; let h2 = h-h1; draw-rect(start-r, start-c, w1, h1, ("bottom", "right")); draw-rect(start-r, 0, w2, h1, ("bottom", "left")); draw-rect(0, start-c, w1, h2, ("top", "right")); draw-rect(0, 0, w2, h2, ("top", "left")) }
    }
}

#let karnaugh-map(
  grid-data: (),
  x-labels: (),
  y-labels: (),
  vars-label: none,
  cell-size: 2.6em,
  hide: 0,
  groups: ()
) = {
  let rows = grid-data.len()
  let cols = grid-data.at(0).len()

  let total-width = cell-size * (cols + 1)
  let total-height = cell-size * (rows + 1)

  let format-cell(content) = {
    box(width: 100%, height: 100%, align(center + horizon)[#content])
  }

  // 1. Формируем ячейки только с контентом
  let cells = ()

  if vars-label != none {
    cells.push(
      box(width: 100%, height: 100%)[
        // Диагональная линия
        #place(line(start: (0%, 0%), end: (100%, 100%), stroke: 0.5pt))

        // Переменные вращаются на 45 градусов, чтобы идти вдоль линии.
        // dx и dy смещают их ровно перпендикулярно от линии в обе стороны
        #place(center + horizon, dx: -0.4em, dy: 0.4em, rotate(45deg)[#vars-label.at(0)])
        #place(center + horizon, dx: 0.4em, dy: -0.7em, rotate(45deg)[#vars-label.at(1)])
      ]
    )
  } else {
    cells.push([])
  }

  // Верхняя ось (с отступом снизу, чтобы не наезжать на границу)
  for label in x-labels { 
    cells.push(box(width: 100%, height: 100%, align(center + bottom, pad(bottom: 0.3em)[#label]))) 
  }
  
  for (r, row) in grid-data.enumerate() {
    // Левая ось (с отступом справа, чтобы не наезжать на границу)
    cells.push(box(width: 100%, height: 100%, align(right + horizon, pad(right: 0.4em)[#y-labels.at(r)])))
    
    // Внутренние данные таблицы
    for val in row {
      if val == 2 { cells.push(move(format-cell(strong(text(size: 15pt, "*"))), dy: 0.4em)) }
      else if val == hide { cells.push(format-cell([])) }
      else { cells.push(format-cell(val)) }
    }
  }

  box(width: total-width, height: total-height)[
    // Таблица с умной функцией рамок
    #place(top + left)[
      #table(
        columns: (cell-size,) * (cols + 1),
        rows: (cell-size,) * (rows + 1),
        inset: 0pt,
        // функция для отрисовки только нужных линий
        stroke: (c, r) => {
          let s = (:) // Начинаем без рамок

          s.bottom = 0.5pt
          s.right = 0.5pt

          if r == 0 { s.right = none }
          if c == 0 { s.bottom = none }

          // Ячейка (0,0) полностью без рамок
          if c == 0 and r == 0 { s = none }

          return s
        },
        ..cells
      )
    ]

    #mark-groups(groups, cell-size, cols, rows, cell-size)
  ]
}

#let veitch-map(
  grid-data: (),
  cell-size: 2.6em,
  hide: 0,
  vars: (),
  groups: ()
) = {
  let rows = grid-data.len()
  let cols = grid-data.at(0).len()

  let total-width = cell-size * cols
  let total-height = cell-size * rows

  let format-cell(content) = {
    box(width: 100%, height: 100%, align(center + horizon)[#content])
  }

  // Сборка чистых данных таблицы
  let cells = ()
  for row in grid-data {
    for val in row {
      if val == 2 { cells.push(move(format-cell(strong(text(size: 15pt, "*"))), dy: 0.4em)) }
      else if val == hide { cells.push(format-cell([])) }
      else { cells.push(format-cell(val)) }
    }
  }

  // Используем pad, чтобы наружные линии не обрезались краями страницы/блока
  pad(2.5em)[
    #box(width: total-width, height: total-height)[
      // Слой 1: Чистая таблица
      #place(top + left)[
        #table(
          columns: (cell-size,) * cols,
          rows: (cell-size,) * rows,
          inset: 0pt,
          stroke: 0.5pt + black,
          ..cells
        )
      ]

      #mark-groups(groups, cell-size, cols, rows, 0pt)

      // Отрисовка переменных Вейча (линии снаружи)
      #for v in vars {
        let side = v.at("side")
        let start = v.at("start")
        let span = v.at("span")
        let label = v.at("label")
        let offset = v.at("offset", default: 0.6em) // Отдаление по умолчанию

        let cs = cell-size
        let line-w = 1pt // Толщина черты переменной

        if side == "top" {
          let x = start * cs
          let w = span * cs
          // Линия
          place(top + left, dx: x, dy: -offset, line(length: w, stroke: line-w))
          // Текст над линией строго по центру
          place(top + left, dx: x, dy: -offset - 1.2em, box(width: w, align(center)[#label]))
        }
        else if side == "bottom" {
          let x = start * cs
          let w = span * cs
          place(top + left, dx: x, dy: total-height + offset, line(length: w, stroke: line-w))
          place(top + left, dx: x, dy: total-height + offset + 0.4em, box(width: w, align(center)[#label]))
        }
        else if side == "left" {
          let y = start * cs
          let h = span * cs
          // ИСПРАВЛЕНИЕ ЗДЕСЬ (path -> line)
          place(top + left, dx: -offset, dy: y, line(start: (0pt, 0pt), end: (0pt, h), stroke: line-w))
          place(top + left, dx: -offset - 1.5em, dy: y, box(height: h, align(right + horizon)[#label]))
        }
        else if side == "right" {
          let y = start * cs
          let h = span * cs
          // ИСПРАВЛЕНИЕ ЗДЕСЬ (path -> line)
          place(top + left, dx: total-width + offset, dy: y, line(start: (0pt, 0pt), end: (0pt, h), stroke: line-w))
          place(top + left, dx: total-width + offset + 0.5em, dy: y, box(height: h, align(left + horizon)[#label]))
        }
      }
    ]
  ]
}

// EXAMPLE

#align(center)[
  #veitch-map(
    cell-size: 2.6em,

    // Данные 2x4
    grid-data: (
      (0, 0, 0, 1),
      (1, 2, 1, 1)
    ),

    hide:1,

    // Настраиваемые переменные
    vars: (
      // Верхняя линия Q2 начинается с 0 колонки и длится 2 колонки
      (side: "top", start: 0, span: 2, label: $Q_2$, offset: 0.6em),

      // Левая линия Q1 начинается с 0 строки и длится 1 строку
      (side: "left", start: 0, span: 1, label: $Q_1$, offset: 0.6em),

      // Нижняя линия p начинается с 1 колонки и длится 2 колонки
      (side: "bottom", start: 1, span: 2, label: $p$, offset: 0.6em),
    ),

    groups: (
      (r: 0, c: 0, w: 2, h: 1, color: rgb("#4a7bbb"), pad: 4pt),
      (r: 0, c: 1, w: 2, h: 1, color: rgb("#92d050"), pad: 6pt),
    )
  )
]

#let gray-code(n) = {
  if n == 0 { return ("") }
  if n == 1 { return ("0", "1") }

  let prev = gray-code(n - 1)
  // Прямой порядок с добавлением "0" в начало
  let top = prev.map(x => "0" + x)
  // Обратный порядок с добавлением "1" в начало
  let bot = prev.rev().map(x => "1" + x)

  return top + bot
}

#align(center)[
  #karnaugh-map(
    x-labels: ("000", "001", "011", "010", "110", "111", "101", "100"),
    y-labels: ("00", "01", "11", "10"),
    hide: 0,
    vars-label: ($a_1 a_2$, $b_1 b_2 p$),

    grid-data: (
      (1, 1, 1, 0, 1, 1, 0, 0),
      (0, 1, 0, 0, 2, 2, 0, 0),
      (1, 1, 1, 1, 1, 1, 1, 0),
      (0, 0, 0, 0, 0, 2, 0, 0)
    ),

    groups: (
      (r: 0, c: 5, w: 1, h: 4, color: rgb("#00b0f0"), pad: 2pt, dash: "dashed"),
      (r: 1, c: 4, w: 2, h: 2, color: rgb("#ff0000"), pad: 4pt, dash: "dash-dotted"),
      (r: 0, c: 4, w: 2, h: 1, color: rgb("#7030a0"), pad: 6pt, dash: "dotted"),

      (r: 0, c: 0, w: 2, h: 1, color: rgb("#4a7bbb"), pad: 2pt),
      (r: 0, c: 1, w: 2, h: 1, color: rgb("#92d050"), pad: 5pt),
      (r: 0, c: 1, w: 1, h: 2, color: rgb("#ffff00"), pad: 8pt),

      (r: 2, c: 0, w: 4, h: 1, color: rgb("#ffc000"), pad: 2pt),
      (r: 2, c: 1, w: 2, h: 1, color: rgb("#00b050"), pad: 5pt),
      (r: 2, c: 5, w: 2, h: 1, color: rgb("#00b050"), pad: 5pt),
    )
  )
]


#align(center)[
  #karnaugh-map(
    x-labels: ("000", "001", "011", "010", "110", "111", "101", "100"),
    y-labels: ("000", "001", "011", "010", "110", "111", "101", "100"),
    hide: none,
    // Убрал rotate(-45deg), так как функция теперь сама красиво поворачивает переменные вдоль линии
    vars-label: ($P_1 x_1 x_2$, $y_1 y_2 h$),
    cell-size: 2.2em,
    grid-data: (
      ("1", "0", "0", "0", "x", "x", "0", "1"),
      ("1", "0", "0", "0", "x", "x", "0", "1"),
      ("1", "1", "1", "1", "x", "x", "1", "1"),
      ("1", "1", "1", "1", "x", "x", "1", "1"),
      ("x", "x", "x", "x", "x", "x", "x", "0"),
      ("x", "x", "x", "x", "x", "x", "x", "0"),
      ("x", "x", "x", "x", "x", "x", "x", "0"),
      ("x", "x", "x", "x", "x", "x", "x", "0")
    ),
    groups: (
      (r: 0, c: 0, w: 1, h: 2, color: black, pad: 2pt),
      (r: 2, c: 0, w: 4, h: 2, color: black, pad: 2pt),
      (r: 4, c: 0, w: 1, h: 4, color: black, pad: 2pt),
      (r: 0, c: 7, w: 1, h: 2, color: black, pad: 2pt),
      (r: 2, c: 7, w: 1, h: 2, color: black, pad: 2pt),
      (r: 0, c: 4, w: 1, h: 6, color: black, pad: 2pt),
    )
  )
]