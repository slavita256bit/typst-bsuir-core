#import "@preview/zap:0.5.0"

// НОВОЕ: Единый конвертер названий в векторы X, Y
#let phys-to-vec(dir) = {
    if dir in ("top", "north", "up") { (0, 1) }
    else if dir in ("bottom", "south", "down") { (0, -1) }
    else if dir in ("right", "east") { (1, 0) }
    else if dir in ("left", "west") { (-1, 0) }
    // ДИАГОНАЛИ
    else if dir in ("top-right", "right-top", "north-east", "up-right", "right-up") { (0.7071, 0.7071) }
    else if dir in ("top-left", "left-top", "north-west", "up-left", "left-up") { (-0.7071, 0.7071) }
    else if dir in ("bottom-right", "right-bottom", "south-east", "down-right", "right-down") { (0.7071, -0.7071) }
    else if dir in ("bottom-left", "left-bottom", "south-west", "down-left", "left-down") { (-0.7071, -0.7071) }
    else { (0, 0) } // Неизвестное направление
}

// Helper: Maps physical direction to Zap's local anchors ("north", "south-west"...)
#let phys-to-anchor(angle, physical) = {
    let vec = phys-to-vec(physical)
    if vec == (0, 0) { return physical } // fallback для нестандартных якорей

    let (dx, dy) = vec
    let sin-a = calc.sin(angle)
    let cos-a = calc.cos(angle)

    let lx = dx * cos-a + dy * sin-a
    let ly = -dx * sin-a + dy * cos-a

    let threshold = 0.3
    let is-n = ly > threshold
    let is-s = ly < -threshold
    let is-e = lx > threshold
    let is-w = lx < -threshold

    let res = ""
    if is-n { res += "north" }
    if is-s { res += "south" }
    if res != "" and (is-e or is-w) { res += "-" }
    if is-e { res += "east" }
    if is-w { res += "west" }

    if res == "" { "center" } else { res }
}

// Helper: Determines if physical direction corresponds to local +Y (1) or -Y (-1)
#let phys-to-y(angle, physical) = {
    if physical == "wire-left" { return 1 }
    if physical == "wire-right" { return -1 }

    let vec = phys-to-vec(physical)
    let (dx, dy) = if vec != (0, 0) { vec } else { (0, 1) }

    let ly = -dx * calc.sin(angle) + dy * calc.cos(angle)
    if ly >= 0 { 1 } else { -1 }
}

// Helper: Determines if physical direction corresponds to local +X (forward) or -X (backward)
#let phys-to-x(angle, physical) = {
    if physical == "forward" { return 1 }
    if physical == "backward" { return -1 }

    let vec = phys-to-vec(physical)
    let (dx, dy) = if vec != (0, 0) { vec } else { (1, 0) }

    let lx = dx * calc.cos(angle) + dy * calc.sin(angle)
    if lx >= 0 { 1 } else { -1 }
}

#let source-better(name, ..params) = {
    import zap: cetz, component
    let pos = params.pos()

    cetz.draw.get-ctx(ctx => {
        let angle = 0deg
        if pos.len() == 2 {
            let (ctx, rp1) = cetz.coordinate.resolve(ctx, pos.at(0))
            let (ctx, rp2) = cetz.coordinate.resolve(ctx, pos.at(1))
            angle = cetz.vector.angle2(rp1, rp2)
        }

        let named = params.named()
        let lbl = named.remove("label", default: none)
        let arrow-dir = phys-to-x(angle, named.remove("arrow-dir", default: "forward"))

        let draw(ctx, position, style) = {
            import zap: interface, cetz
            let r = style.at("radius", default: 0.53)
            interface((-r, -r), (r, r), io: position.len() < 2)
            cetz.draw.circle((0, 0), radius: r, fill: style.fill, stroke: style.stroke)

            let arrow-len = r * 0.65
            let start-x = -arrow-dir * arrow-len
            let end-x = arrow-dir * arrow-len
            cetz.draw.line((start-x, 0), (end-x, 0), stroke: style.stroke, mark: (end: ">", fill: style.stroke.paint, scale: 1.2))

            if lbl != none {
                let text-content = if type(lbl) == dictionary { lbl.content } else { lbl }
                let anchor-dir = if type(lbl) == dictionary { lbl.at("anchor", default: "top") } else { "top" }

                let vec = phys-to-vec(anchor-dir)
                let (p-dx, p-dy) = if vec != (0, 0) { vec } else { (0, 1) }

                let l-dx = p-dx * calc.cos(-angle) - p-dy * calc.sin(-angle)
                let l-dy = p-dx * calc.sin(-angle) + p-dy * calc.cos(-angle)

                let label-box = box(fill: white, inset: 1pt)[#text-content]
                let (tw, th) = cetz.util.measure(ctx, label-box) // ИЗМЕРЯЕМ ТЕКСТ (width, height)

                // Если пользователь задал distance - используем его. Иначе вычисляем сами!
                let dist = if type(lbl) == dictionary and "distance" in lbl {
                    lbl.distance
                } else {
                    // r (радиус источника) + отступ 0.15 + учет ширины и высоты текста
                    r + 0.15 + calc.abs(p-dx) * (tw / 2) + calc.abs(p-dy) * (th / 2)
                }

                cetz.draw.content(
                    (l-dx * dist, l-dy * dist),
                    label-box,
                    anchor: "center",
                )
            }
        }

        component("isource", name, ..pos, draw: draw, ..named)
    })
}

#let jsource-better(name, ..params) = {
    import zap: cetz, component
    let pos = params.pos()

    cetz.draw.get-ctx(ctx => {
        let angle = 0deg
        if pos.len() == 2 {
            let (ctx, rp1) = cetz.coordinate.resolve(ctx, pos.at(0))
            let (ctx, rp2) = cetz.coordinate.resolve(ctx, pos.at(1))
            angle = cetz.vector.angle2(rp1, rp2)
        }

        let named = params.named()
        let lbl = named.remove("label", default: none)
        let arrow-dir = phys-to-x(angle, named.remove("arrow-dir", default: "forward"))

        let draw(ctx, position, style) = {
            import zap: interface, cetz
            let r = style.at("radius", default: 0.53)
            interface((-r, -r), (r, r), io: position.len() < 2)

            cetz.draw.circle((0, 0), radius: r, fill: style.fill, stroke: style.stroke)

            let size = r * 0.35
            let shift = r * 0.2
            let global_arrows_shift = 0.1

            let chevron(tip-x) = {
                cetz.draw.line(
                    (tip-x - arrow-dir * size, size),
                    (tip-x, 0),
                    (tip-x - arrow-dir * size, -size),
                    stroke: style.stroke
                )
            }

            chevron((shift + global_arrows_shift) * arrow-dir)
            chevron((-shift + global_arrows_shift) * arrow-dir)

            if lbl != none {
                let text-content = if type(lbl) == dictionary { lbl.content } else { lbl }
                let anchor-dir = if type(lbl) == dictionary { lbl.at("anchor", default: "top") } else { "top" }

                let vec = phys-to-vec(anchor-dir)
                let (p-dx, p-dy) = if vec != (0, 0) { vec } else { (0, 1) }

                let l-dx = p-dx * calc.cos(-angle) - p-dy * calc.sin(-angle)
                let l-dy = p-dx * calc.sin(-angle) + p-dy * calc.cos(-angle)

                let label-box = box(fill: white, inset: 1pt)[#text-content]
                let (tw, th) = cetz.util.measure(ctx, label-box) // ИЗМЕРЯЕМ ТЕКСТ

                let dist = if type(lbl) == dictionary and "distance" in lbl {
                    lbl.distance
                } else {
                    // r (радиус источника) + отступ 0.15 + учет размеров метки
                    r + 0.15 + calc.abs(p-dx) * (tw / 2) + calc.abs(p-dy) * (th / 2)
                }

                cetz.draw.content(
                    (l-dx * dist, l-dy * dist),
                    label-box,
                    anchor: "center",
                )
            }
        }

        component("isource", name, ..pos, draw: draw, ..named)
    })
}

#let resistor-better(name, ..params) = {
    import zap: cetz, component
    let pos = params.pos()

    cetz.draw.get-ctx(ctx => {
        let angle = 0deg
        if pos.len() == 2 {
            let (ctx, rp1) = cetz.coordinate.resolve(ctx, pos.at(0))
            let (ctx, rp2) = cetz.coordinate.resolve(ctx, pos.at(1))
            angle = cetz.vector.angle2(rp1, rp2)
        }

        let named = params.named()
        let lbl = named.remove("label", default: none)

        // Извлекаем "сырое" название стороны для стрелки (чтобы использовать его как дефолтный anchor для метки тока)
        let raw-arrow-side = named.remove("arrow-side", default: "top")
        let arrow-side = phys-to-y(angle, raw-arrow-side)

        let arrow-dir = phys-to-x(angle, named.remove("arrow-dir", default: "right"))
        let arrow-label = named.remove("arrow-label", default: none)
        let arrow-offset = named.remove("arrow-offset", default: 0.5)

        let draw(ctx, position, style) = {
            import zap: interface, cetz
            let w = style.at("width", default: 1.41)
            let h = style.at("height", default: 0.47)

            interface((-w/2, -h/2), (w/2, h/2), io: position.len() < 2)
            cetz.draw.rect((-w/2, -h/2), (w/2, h/2), fill: style.fill, stroke: style.stroke)

            // СТРЕЛКА ТОКА И ЕЕ МЕТКА
            if arrow-label != none {
                let y = arrow-side * arrow-offset
                let arrow-len = w * 0.8
                let start-x = -arrow-dir * (arrow-len / 2)
                let end-x = arrow-dir * (arrow-len / 2)

                cetz.draw.line(
                    (start-x, y), (end-x, y),
                    stroke: style.stroke,
                    mark: (end: ">", fill: style.stroke.paint)
                )

                let arr-content = if type(arrow-label) == dictionary { arrow-label.content } else { arrow-label }
                // По умолчанию используем ту же сторону, с которой нарисована сама стрелка (raw-arrow-side)
                let arr-anchor-dir = if type(arrow-label) == dictionary { arrow-label.at("anchor", default: raw-arrow-side) } else { raw-arrow-side }

                let vec = phys-to-vec(arr-anchor-dir)
                let (p-dx, p-dy) = if vec != (0, 0) { vec } else { (0, 1) }

                let l-dx = p-dx * calc.cos(-angle) * 0 - p-dy * calc.sin(-angle)
                let l-dy = p-dx * calc.sin(-angle) + p-dy * calc.cos(-angle)

                let arr-label-box = box(fill: white, inset: 1pt)[#arr-content]
                let (atw, ath) = cetz.util.measure(ctx, arr-label-box)

                let dist = if type(arrow-label) == dictionary and "distance" in arrow-label {
                    arrow-label.distance
                } else {
                    // Базовый отступ от линии стрелки 0.15 + размеры самой текстовой метки
                    0.15 + calc.abs(p-dx) * (atw / 2) * 1.5 + calc.abs(p-dy) * (ath / 2) * 1.5
                }

                // (0, y) — это геометрический центр нарисованной стрелки
                cetz.draw.content(
                    (l-dx * dist, y + l-dy * dist),
                    arr-label-box,
                    anchor: "center",
                )
            }

            // ОСНОВНАЯ МЕТКА РЕЗИСТОРА (R1, R2...)
            if lbl != none {
                let text-content = if type(lbl) == dictionary { lbl.content } else { lbl }
                let anchor-dir = if type(lbl) == dictionary { lbl.at("anchor", default: "top") } else { "top" }

                let vec = phys-to-vec(anchor-dir)
                let (p-dx, p-dy) = if vec != (0, 0) { vec } else { (0, 1) }

                let l-dx = p-dx * calc.cos(-angle) * 0 - p-dy * calc.sin(-angle) * 0
                let l-dy = p-dx * calc.sin(-angle) * 1.3 + p-dy * calc.cos(-angle) * 1.3

                let label-box = box(fill: white, inset: 1pt)[#text-content]
                let (tw, th) = cetz.util.measure(ctx, label-box)

                let dist = if type(lbl) == dictionary and "distance" in lbl {
                    lbl.distance
                } else {
                    let comp-dist = -calc.abs(l-dx) * (w / 2) - calc.abs(l-dy) * (h / 2)
                    comp-dist + 0.8 + calc.abs(p-dx) * (tw / 4) + calc.abs(p-dy) * (th / 3)
                }

                cetz.draw.content(
                    (l-dx * dist, l-dy * dist),
                    label-box,
                    anchor: "center",
                )
            }
        }

        component("resistor", name, ..pos, draw: draw, ..named)
    })
}

#let ground-better(node-name, length: 1.2, spacing: 0.2, stroke: 1pt) = {
  import zap: cetz, wire
  cetz.draw.get-ctx(ctx => {
      let (ctx, pos) = cetz.coordinate.resolve(ctx, node-name)
      let (x, y, z) = pos

      wire(pos, (x, y - 0.5)) // Провод вниз от узла

      let start_x = x - length / 2
      let end_x = x + length / 2
      let base_y = y - 0.5

      cetz.draw.line((start_x, base_y), (end_x, base_y), stroke: stroke)
      cetz.draw.line((start_x + spacing, base_y - spacing), (end_x - spacing, base_y - spacing), stroke: stroke)
      cetz.draw.line((start_x + 2*spacing, base_y - 2*spacing), (end_x - 2*spacing, base_y - 2*spacing), stroke: stroke)
  })
}

// Wrapper function for customized Zap circuits
#let circuit-better(
    scale-factor: 100%,
    alignment: center,
    text-font: "Times New Roman",
    math-font: "STIX Two Math",
    text-size: 14pt,
    stroke-thickness: 1.2pt,
    resistor-width: 1.6,
    resistor-height: 0.5,
    ..zap-args,
    body
) = {
    let reversed-factor = 100% / scale-factor
    align(alignment, block(
        scale(scale-factor)[
            // Apply text and math font settings
            #set text(font: text-font, size: text-size * reversed-factor)
            #show math.equation: set text(font: math-font, size: text-size * reversed-factor)

            // Initialize the Zap circuit
            #zap.circuit(..zap-args, {
                // Apply default styles
                zap.set-style(stroke: (thickness: stroke-thickness * reversed-factor))
                zap.set-style(wire: (stroke: (thickness: stroke-thickness * reversed-factor)))
                zap.set-style(resistor: (width: resistor-width, height: resistor-height))

                // Insert the user's circuit components
                body
            })
        ]
    ))
}

#let node-better(name, pos, visible: false, radius: 0.12, fill: black, ..params) = {
    import zap: cetz, node

    let named = params.named()

    // 1. Обрабатываем якоря (top, bottom, left, right)
    let lbl = named.at("label", default: none)
    if type(lbl) == dictionary and "anchor" in lbl {
        lbl.anchor = phys-to-anchor(0deg, lbl.anchor)
        named.label = lbl
    }

    // 2. Вызываем стандартный узел zap, но ЖЕСТКО делаем его невидимым
    node(name, pos, stroke: none, fill: false, radius: 0.0000001, ..named)

    // 3. Если узел должен быть видимым — рисуем поверх него свой кружок
    // с нужным нам радиусом и цветом
    if visible {
        cetz.draw.circle(name, radius: radius, fill: fill, stroke: none)
    }
}

#let open-branch-better(name, ..params) = {
    import zap: cetz, component
    let pos = params.pos()

    cetz.draw.get-ctx(ctx => {
        let angle = 0deg
        if pos.len() == 2 {
            let (ctx, rp1) = cetz.coordinate.resolve(ctx, pos.at(0))
            let (ctx, rp2) = cetz.coordinate.resolve(ctx, pos.at(1))
            angle = cetz.vector.angle2(rp1, rp2)
        }

        let named = params.named()

        // Основные настройки метки и стрелки
        let lbl = named.remove("label", default: none)
        let raw-arrow-side = named.remove("arrow-side", default: "bottom")
        let arrow-side = phys-to-y(angle, raw-arrow-side)

        let arrow-dir = phys-to-x(angle, named.remove("arrow-dir", default: "forward"))
        let arrow-offset = named.remove("arrow-offset", default: 0.35) // Отступ стрелки от центра

        // Настройки геометрии разрыва
        let gap = named.remove("gap", default: 1.5) // Размер пустого пространства
        let node-radius = named.remove("node-radius", default: 0.08)
        let show-terminals = named.remove("show-terminals", default: false) // Косые черточки (как на рис 2)

        let draw(ctx, position, style) = {
            import zap: interface, cetz
            let w = style.at("width", default: 1.41)
            let h = style.at("height", default: 0.47)
            let half-gap = gap / 2

            // Теперь интерфейс — это полноценный прямоугольник, а не линия
            interface((-w/2, -h/2), (w/2, h/2), io: position.len() < 2)

            // 1. Рисуем провода до разрыва
            cetz.draw.line((-w/2, 0), (-half-gap, 0), stroke: style.stroke)
            cetz.draw.line((half-gap, 0), (w/2, 0), stroke: style.stroke)

            // 2. Рисуем узлы (точки)
            cetz.draw.circle((-half-gap, 0), radius: node-radius, fill: style.stroke.paint, stroke: none)
            cetz.draw.circle((half-gap, 0), radius: node-radius, fill: style.stroke.paint, stroke: none)

            // 3. Опционально: Рисуем косые черточки (клеммы, как на 2-м скриншоте)
            if show-terminals {
                let t-size = 0.2
                // Левая клемма (под углом 45 градусов)
                cetz.draw.line((-half-gap - t-size, -t-size), (-half-gap + t-size, t-size), stroke: style.stroke)
                // Правая клемма
                cetz.draw.line((half-gap - t-size, -t-size), (half-gap + t-size, t-size), stroke: style.stroke)
            }

            // 4. Рисуем стрелку напряжения и подпись
            if lbl != none {
                let y = arrow-side * arrow-offset
                let arrow-len = gap * 0.9 // Длина стрелки чуть меньше зазора
                let start-x = -arrow-dir * (arrow-len / 2)
                let end-x = arrow-dir * (arrow-len / 2)

                // Сама стрелка
                cetz.draw.line(
                    (start-x, y), (end-x, y),
                    stroke: style.stroke,
                    mark: (end: ">", fill: style.stroke.paint)
                )

                // Логика позиционирования текста (идентична резистору)
                let arr-content = if type(lbl) == dictionary { lbl.content } else { lbl }
                let arr-anchor-dir = if type(lbl) == dictionary { lbl.at("anchor", default: raw-arrow-side) } else { raw-arrow-side }

                let vec = phys-to-vec(arr-anchor-dir)
                let (p-dx, p-dy) = if vec != (0, 0) { vec } else { (0, 1) }

                let l-dx = p-dx * calc.cos(-angle) * 0 - p-dy * calc.sin(-angle)
                let l-dy = p-dx * calc.sin(-angle) + p-dy * calc.cos(-angle)

                let arr-label-box = box(fill: white, inset: 1pt)[#arr-content]
                let (atw, ath) = cetz.util.measure(ctx, arr-label-box)

                let dist = if type(lbl) == dictionary and "distance" in lbl {
                    lbl.distance
                } else {
                    0.15 + calc.abs(p-dx) * (atw / 2) * 1.5 + calc.abs(p-dy) * (ath / 2) * 1.5
                }

                cetz.draw.content(
                    (l-dx * dist, y + l-dy * dist),
                    arr-label-box,
                    anchor: "center",
                )
            }
        }

        component("resistor", name, ..pos, draw: draw, ..named)
    })
}

// EXAMPLE
#circuit-better(scale-factor: 80%, {
    import zap: *

//     set-style(stroke: (thickness: 1.2pt))
//     set-style(wire: (stroke: (thickness: 1.2pt)))
//     set-style(resistor: (width: 1.6, height: 0.5))

    node-better("e", (0, 3.5), label: (content: "e", anchor: "west"), visible: true)
    node-better("a", (5, 7), label: (content: "a", anchor: "north"), visible: true)
    node-better("б", (11, 7), label: (content: "б", anchor: "north"), visible: true)
    node-better("в", (16, 3.5), label: (content: "в", anchor: "east"), visible: true)
    node-better("д", (5, 0), label: (content: "д", anchor: "south"), visible: true)
    node-better("г", (11, 0), label: (content: "г", anchor: "south"), visible: true)

    // Notice how intuitive this becomes: you just ask for the physical "left", "right", "top", "bottom"
    // Left Branch (UP):
    wire("д", (0,0))
    source-better("E1", (0,0), "e", arrow-dir: "up", label: (content: $E_1$, anchor: "left"))
    resistor-better("R1", "e", (0,7), label: (content: $R_1$, anchor: "right"), arrow-label: $I_1$, arrow-side: "left", arrow-dir: "up")
    wire((0,7), "a")

    // Top Branch (RIGHT):
    resistor-better("R2", "a", "б", label: (content: $R_2$, anchor: "top"), arrow-label: $I_2$, arrow-side: "bottom", arrow-dir: "right")

    // Middle Branches (DOWN):
    resistor-better("R5", "a", "д", label: (content: $R_5$, anchor: "left"), arrow-label: $I_5$, arrow-side: "right", arrow-dir: "down")
    resistor-better("R4", "б", "г", label: (content: $R_4$, anchor: "right"), arrow-label: $I_4$, arrow-side: "left", arrow-dir: "down")

    // Right Branch (UP):
    wire("г", (16,0))
    source-better("E3", (16,0), "в", arrow-dir: "up", label: (content: $E_3$, anchor: "right"))
    resistor-better("R3", "в", (16,7), label: (content: $R_3$, anchor: "left"), arrow-label: $I_3$, arrow-side: "right", arrow-dir: "up")
    wire((16,7), "б")

    // Bottom Branch (LEFT, from г to д):
    resistor-better("R6", "г", "д", label: (content: $R_6$, anchor: "bottom"), arrow-label: $I_6$, arrow-side: "top", arrow-dir: "left")
})


#circuit-better(scale-factor: 80%, {
  import zap: *

  node-better("1", (0, -1), label: (content: "1", anchor: "west"), visible: true)
  node-better("3", (16, -1), label: (content: "3", anchor: "east"), visible: true)
  node-better("2", (8, 9), label: (content: "2", anchor: "north"), visible: true)
  node-better("4", (8, 3), label: (content: "4", anchor: "north-west"), visible: true)

  node-better("5", (4, 1), visible: false) // скрыл вспомогательные узлы
  node-better("6", (12, 1), visible: false) // скрыл вспомогательные узлы

  // Внешний контур
  resistor-better("R1", "1", "2", label: (content: $R_1$, anchor: "right"), arrow-label: $I_1$, arrow-side: "left", arrow-dir: "forward")
  resistor-better("R5", "2", "3", label: (content: $R_5$, anchor: "left"), arrow-label: $I_5$, arrow-side: "right", arrow-dir: "forward")
  resistor-better("R3", "1", "3", label: (content: $R_3$, anchor: "bottom"), arrow-label: $I_3$, arrow-side: "top", arrow-dir: "forward")

  // Внутренняя звезда
  resistor-better("R6", "2", "4", label: (content: $R_6$, anchor: "right"), arrow-label: $I_6$, arrow-side: "left", arrow-dir: "forward")

  // Ветвь 4-1 (с E2)
  resistor-better("R2", "4", "5", label: (content: $R_2$, anchor: "top"))
  source-better("E2", "5", "1", position: 15%, arrow-dir: "forward", label: (content: $E_2$, anchor: "bottom"))

  // Ветвь 4-3 (с E4)
  resistor-better("R4", "4", "6", label: (content: $R_4$, anchor: "top"))
  source-better("E4", "6", "3", position: 15%, arrow-dir: "forward", label: (content: $E_4$, anchor: "bottom"))

  ground-better("3", length: 1.2, spacing: 0.2)
})

#circuit-better(scale-factor: 100%, {
  import zap: *

  // Пример 1: Обычный разрыв
  open-branch-better("XX1", (0, 2), (3, 2), label: $U_(x x)$, arrow-side: "bottom", arrow-dir: "forward")

  // Пример 2: Разрыв с клеммами
  open-branch-better("XX2", (5, 2), (8, 2), label: $U_(x x)$, arrow-side: "bottom", arrow-dir: "forward", show-terminals: true)

  // Пример вертикального разрыва
  open-branch-better("XX3", (1, -2), (1, 0), label: $U_(x x)$, arrow-side: "right", arrow-dir: "up")
})