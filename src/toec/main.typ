#import "@preview/modern-g7-32:0.2.0": *
#import "@local/typst-bsuir-core:1.1.1": *
#import "@preview/zap:0.5.0"

#set text(font: "Times New Roman", size: 14pt)
#show math.equation: set text(font: "STIX Two Math", size: 14pt)

#show: gost.with(
  title-template: custom-title-template.from-module(toec-typical-template),
  department: "Кафедра теоретических основ электротехники",
  work: (
    type: "Типовой расчет по курсу: «Теория электрических цепей»",
    number: "",
    subject: "Расчет сложной цепи периодического синусоидального тока",
    variant: "558301-21",
  ),
  manager: (
    name: "Батюков С.В.",
  ),
  performer: (
    name: "Иванов И.И.",
    group: "558301",
  ),
  footer: (city: "Минск", year: 2024),
  city: none,
  year: none,
  add-pagebreaks: false,
  text-size: 14pt,
)

#show: apply-toec-styling

= Расшифровка задания

#figure(
  caption: none,
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    align: center + horizon,
    table.header(
      table.cell(rowspan: 2)[Номер\ ветви],
      table.cell(rowspan: 2)[Начало-\ конец],
      table.cell(colspan: 3)[Сопротивления, Ом],
      table.cell(colspan: 2)[Источник ЭДС],
      table.cell(colspan: 2)[Источник тока],
      [$R$], [$X_L$], [$X_C$],
      [Мод., В], [Арг., $degree$],
      [Мод., А], [Арг., $degree$]
    ),
    [1], [31], [89], [47], [0], [0], [0], [0], [0],
    [2], [15], [44], [0], [0], [0], [0], [0], [0],
    [3], [54], [0], [46], [68], [0], [0], [0], [0],
    [4], [46], [0], [81], [0], [0], [0], [0], [0],
    [5], [62], [55], [0], [27], [38], [114], [0], [0],
    [6], [23], [0], [45], [75], [0], [0], [7], [236],
    [7], [16], [63], [0], [42], [0], [0], [0], [0],
  )
)

Найти токи по методу эквивалентных преобразований. Составить баланс мощностей. Построить векторную диаграмму токов и напряжений. Найти ток в ветви 6 МЭГН.

На рисунке 1 изображена исходная схема.

#lab-figure(
  caption: [Исходная схема],
  circuit-better(scale-factor: 70%, {
    import zap: *
    node-better("1", (0, 6), label: (content: "1", anchor: "east", distance: 0.5), visible: true)
    node-better("5", (5, 12), label: (content: "5", anchor: "south", distance: 0.5), visible: true)
    node-better("4", (11, 12), label: (content: "4", anchor: "south", distance: 0.5), visible: true)
    node-better("6", (16, 6), label: (content: "6", anchor: "west", distance: 0.5), visible: true)
    node-better("2", (16, 0), label: (content: "2", anchor: "east", distance: 0.5), visible: true)
    node-better("3", (0, 0), label: (content: "3", anchor: "west", distance: 0.5), visible: true)

    // Ветвь 2, 3, 4 (Верхний прямоугольный путь)
    wire("1", (0, 12))
    resistor-better("R2", (0, 12), "5", label: (content: $R_2$, anchor: "south", distance: 1.0), arrow-label: (content: $I_2$, anchor: "north", distance: 1.0), arrow-side: "north", arrow-offset: 0.6, arrow-dir: "forward")
    inductor-better("L3", "5", (8,12), label: (content: $L_3$, anchor: "south", distance: 1.0), arrow-label: (content: $I_3$, anchor: "north", distance: 1.0), arrow-side: "north", arrow-offset: 0.6)
    capacitor-better("C3", (8,12), "4", label: (content: $C_3$, anchor: "south", distance: 1.0))
    inductor-better("L4", "4", (16,12), label: (content: $L_4$, anchor: "south", distance: 1.0), arrow-label: (content: $I_4$, anchor: "north", distance: 1.0), arrow-side: "north", arrow-offset: 0.6, arrow-dir: "forward")
    wire((16,12), "6")

    // Ветвь 7 (Средний путь)
    resistor-better("R7", "1", (8,6), label: (content: $R_7$, anchor: "south", distance: 1.0), arrow-label: (content: $I_7$, anchor: "north", distance: 1.0), arrow-side: "north", arrow-offset: 0.6)
    capacitor-better("C7", (8,6), "6", label: (content: $C_7$, anchor: "south", distance: 1.0))

    // Ветвь 5 (Правый вертикальный путь, ток идет от 6 к 2)
    source-better("E5", "6", (16,4), label: (content: $E_5$, anchor: "west", distance: 1.0), arrow-dir: "forward")
    resistor-better("R5", (16,4), (16,2), label: (content: $R_5$, anchor: "west", distance: 1.0))
    capacitor-better("C5", (16,2), "2", label: (content: $C_5$, anchor: "west", distance: 1.0), arrow-label: (content: $I_5$, anchor: "east", distance: 1.0), arrow-side: "east", arrow-offset: 0.6)
    
    // Ветвь 6 (Нижний горизонтальный путь, ток идет от 2 к 3)
    // Рисуем слева направо, чтобы L6 смотрела витками вверх
    capacitor-better("C6", "3", (8,0), label: (content: $C_6$, anchor: "south", distance: 1.0), arrow-label: (content: $I_6$, anchor: "north", distance: 1.0), arrow-side: "north", arrow-offset: 0.6, arrow-dir: "backward")
    inductor-better("L6", (8,0), "2", label: (content: $L_6$, anchor: "south", distance: 1.0))
    
    // Источник J6 параллельно ветви 6
    wire("2", (16, -3))
    jsource-better("J6", (16,-3), (0,-3), label: (content: $J_6$, anchor: "south", distance: 1.0), arrow-dir: "forward")
    wire((0,-3), "3")

    // Ветвь 1 (Левый вертикальный путь, ток идет от 3 к 1)
    resistor-better("R1", "3", (0,3), label: (content: $R_1$, anchor: "east", distance: 1.0), arrow-label: (content: $I_1$, anchor: "west", distance: 1.0), arrow-side: "west", arrow-offset: 0.6)
    inductor-better("L1", (0,3), "1", label: (content: $L_1$, anchor: "east", distance: 1.0))
  })
)

= Расчет токов в ветвях исходной цепи
Находим комплексные сопротивления каждой из ветвей:
#mathtype-mimic[
  $ dot(Z)_1 &= R_1 + j X_(L_1) = 89 + 47 j " Ом"; $
  $ dot(Z)_2 &= R_2 = 44 " Ом"; $
  $ dot(Z)_3 &= j X_(L_3) - j X_(C_3) = 46 j - 68 j = -22 j " Ом"; $
  $ dot(Z)_4 &= j X_(L_4) = 81 j " Ом"; $
  $ dot(Z)_5 &= R_5 - j X_(C_5) = 55 - 27 j " Ом"; $
  $ dot(Z)_6 &= j X_(L_6) - j X_(C_6) = 45 j - 75 j = -30 j " Ом"; $
  $ dot(Z)_7 &= R_7 - j X_(C_7) = 63 - 42 j " Ом". $
]

Запишем комплексы независимых источников:
#mathtype-mimic[
  $ dot(E)_5 &= 38 e^(114 degree j) = -15.46 + 34.71 j " В"; $
  $ dot(J)_6 &= 7 e^(236 degree j) = -3.91 - 5.80 j " А". $
]

По методу эквивалентных преобразований преобразуем источник тока $dot(J)_6$ в эквивалентную ЭДС $dot(E)_(J_6)$, направленную так же, как и источник тока (от узла 2 к узлу 3):
#mathtype-mimic[
  $ dot(E)_(J_6) = dot(J)_6 dot dot(Z)_6 = (-3.91 - 5.80 j)(-30 j) = -174.09 + 117.42 j " В". $
]

Объединим последовательно соединенные элементы. Ветви 2, 3 и 4 образуют эквивалентную ветвь $A$ между узлами 1 и 6:
#mathtype-mimic[
  $ dot(Z)_A = dot(Z)_2 + dot(Z)_3 + dot(Z)_4 = 44 - 22 j + 81 j = 44 + 59 j " Ом". $
]

Ветвь 7 образует ветвь $B$ ($dot(Z)_B = dot(Z)_7$) между узлами 1 и 6. 
Ветви 5, 6 и 1 соединены последовательно и образуют ветвь $C$ от узла 6 к узлу 1 (схема на рисунке 2):
#mathtype-mimic[
  $ dot(Z)_C &= dot(Z)_5 + dot(Z)_6 + dot(Z)_1 = 55 - 27 j - 30 j + 89 + 47 j = 144 - 10 j " Ом"; $
  $ dot(E)_C &= dot(E)_5 + dot(E)_(J_6) = (-15.46 + 34.71 j) + (-174.09 + 117.42 j) = -189.55 + 152.13 j " В". $
]

#lab-figure(
  caption: [Объединение последовательных элементов],
  circuit-better(scale-factor: 85%, {
    import zap: *
    node-better("1", (0, 6), label: (content: "1", anchor: "east", distance: 0.5), visible: true)
    node-better("6", (14, 6), label: (content: "6", anchor: "west", distance: 0.5), visible: true)
    
    wire("1", (0, 10))
    resistor-better("ZA", (0, 10), (14, 10), label: (content: $Z_A$, anchor: "south", distance: 0.5), arrow-label: (content: $I_2$, anchor: "north", distance: 0.5), arrow-side: "north", arrow-offset: 0.4)
    wire((14, 10), "6")

    resistor-better("ZB", "1", "6", label: (content: $Z_B$, anchor: "south", distance: 0.5), arrow-label: (content: $I_7$, anchor: "north", distance: 0.5), arrow-side: "north", arrow-offset: 0.4)

    wire("6", (14, 2))
    source-better("EC", (14, 2), (9, 2), label: (content: $E_C$, anchor: "south", distance: 0.5), arrow-dir: "forward")
    resistor-better("ZC", (9, 2), (0, 2), label: (content: $Z_C$, anchor: "south", distance: 0.5), arrow-label: (content: $I_1$, anchor: "north", distance: 0.5), arrow-side: "north", arrow-offset: 0.4)
    wire((0, 2), "1")
  })
)

Найдем эквивалентное сопротивление параллельных ветвей $A$ и $B$ (схема на рисунке 3):
#mathtype-mimic[
  $ dot(Z)_"AB" = (dot(Z)_A dot dot(Z)_B) / (dot(Z)_A + dot(Z)_B) = ((44 + 59 j)(63 - 42 j)) / (44 + 59 j + 63 - 42 j) = (5250 + 1869 j) / (107 + 17 j) = 50.56 + 9.43 j " Ом". $
]

#lab-figure(
  caption: [Эквивалентное сопротивление $Z_"AB"$],
  circuit-better(scale-factor: 85%, {
    import zap: *
    node-better("1", (0, 6), label: (content: "1", anchor: "east", distance: 0.5), visible: true)
    node-better("6", (14, 6), label: (content: "6", anchor: "west", distance: 0.5), visible: true)
    
    resistor-better("ZAB", "1", "6", label: (content: $Z_"AB"$, anchor: "south", distance: 0.5), arrow-label: (content: $I_1$, anchor: "north", distance: 0.5), arrow-side: "north", arrow-offset: 0.4)

    wire("6", (14, 2))
    source-better("EC", (14, 2), (9, 2), label: (content: $E_C$, anchor: "south", distance: 0.5), arrow-dir: "forward")
    resistor-better("ZC", (9, 2), (0, 2), label: (content: $Z_C$, anchor: "south", distance: 0.5), arrow-label: (content: $I_1$, anchor: "north", distance: 0.5), arrow-side: "north", arrow-offset: 0.4)
    wire((0, 2), "1")
  })
)

Схема свернулась до одного контура, состоящего из $dot(Z)_"AB"$ и $dot(Z)_C$. Ток в этом контуре $dot(I)_1$ (он же $dot(I)_5$ и $dot(I)_6$) равен:
#mathtype-mimic[
  $ dot(I)_1 = dot(I)_5 = dot(I)_6 = dot(E)_C / (dot(Z)_"AB" + dot(Z)_C) = (-189.55 + 152.13 j) / (194.56 - 0.57 j) = -0.976 + 0.779 j = 1.250 e^(141.4 degree j) " А". $
]

Напряжение между узлами 1 и 6:
#mathtype-mimic[
  $ dot(U)_16 = dot(I)_1 dot dot(Z)_"AB" = (-0.976 + 0.779 j)(50.56 + 9.43 j) = -56.70 + 30.18 j " В". $
]

Определяем оставшиеся токи в параллельных ветвях:
#mathtype-mimic[
  $ dot(I)_2 = dot(I)_3 = dot(I)_4 = dot(U)_16 / dot(Z)_A = (-56.70 + 30.18 j) / (44 + 59 j) = -0.132 + 0.863 j = 0.873 e^(98.7 degree j) " А"; $
  $ dot(I)_7 = dot(U)_16 / dot(Z)_B = (-56.70 + 30.18 j) / (63 - 42 j) = -0.844 - 0.084 j = 0.848 e^(-174.3 degree j) " А". $
]

По найденным комплексам записываем мгновенные значения токов:
#mathtype-mimic[
  $ i_1(t) = i_5(t) = i_6(t) &= sqrt(2) dot 1.250 sin(omega t + 141.4 degree) " А"; $
  $ i_2(t) = i_3(t) = i_4(t) &= sqrt(2) dot 0.873 sin(omega t + 98.7 degree) " А"; $
  $ i_7(t) &= sqrt(2) dot 0.848 sin(omega t - 174.3 degree) " А". $
]

= Составление баланса мощностей
Напряжение на источнике тока $dot(J)_6$ (направлено от узла 2 к 3):
#mathtype-mimic[
  $ dot(U)_(J_6) = (dot(I)_6 - dot(J)_6) dot dot(Z)_6 = (-0.976 + 0.779 j + 3.914 + 5.803 j)(-30 j) = 197.46 - 88.14 j " В". $
]

Комплексная мощность, отдаваемая источниками (с учетом того, что источник тока отдает мощность $dot(S)_J = -dot(U)_(J_6) dot(J)_6^*$ при несовпадении направлений с напряжением узлов):
#mathtype-mimic[
  $ dot(S)_"ист" &= dot(E)_5 dot(I)_5^* - dot(U)_(J_6) dot(J)_6^* = $
  $ &= (-15.46 + 34.71 j)(-0.976 - 0.779 j) - (197.46 - 88.14 j)(-3.914 + 5.803 j) = $
  $ &= (42.13 - 21.84 j) - (-261.38 + 1490.84 j) = 303.51 - 1512.68 j " ВА". $
]
Активная и реактивная мощности источника: $P_"ист" = 303.5 " Вт"$, $Q_"ист" = -1512.7 " ВАр"$.

Мощность, рассеиваемая на пассивных элементах цепи:
#mathtype-mimic[
  $ dot(S)_"потр" &= |dot(I)_1|^2 dot(Z)_1 + |dot(I)_2|^2 dot(Z)_A + |dot(I)_7|^2 dot(Z)_B + |dot(I)_5|^2 dot(Z)_5 + |dot(I)_6 - dot(J)_6|^2 dot(Z)_6 = $
  $ &= 1.559(89 + 47 j) + 0.762(44 + 59 j) + 0.720(63 - 42 j) + 1.559(55 - 27 j) + 51.95(-30 j) = $
  $ &= 138.8 + 73.3 j + 33.5 + 45.0 j + 45.4 - 30.2 j + 85.7 - 42.1 j - 1558.5 j = $
  $ &= 303.4 - 1512.5 j " ВА". $
]
Как видим, активные и реактивные мощности источника ЭДС, источника тока и сопротивлений оказываются равны.

= Определяем потенциалы узлов и рисуем векторную диаграмму
Примем потенциал узла 1 равным нулю ($phi_1 = 0$).
#mathtype-mimic[
  $ phi_5 &= phi_1 - dot(I)_2 dot(Z)_2 = -(-0.132 + 0.863 j) dot 44 = 5.81 - 37.97 j " В"; $
  $ phi_4 &= phi_5 - dot(I)_3 dot(Z)_3 = 5.81 - 37.97 j - (-0.132 + 0.863 j)(-22 j) = -13.18 - 40.88 j " В"; $
  $ phi_6 &= phi_4 - dot(I)_4 dot(Z)_4 = -13.18 - 40.88 j - (-0.132 + 0.863 j)(81 j) = 56.71 - 30.18 j " В"; $
  $ phi_3 &= phi_1 + dot(I)_1 dot(Z)_1 = (-0.976 + 0.779 j)(89 + 47 j) = -123.48 + 23.46 j " В"; $
  $ phi_2 &= phi_3 + (dot(I)_6 - dot(J)_6)dot(Z)_6 = -123.48 + 23.46 j + 197.46 - 88.14 j = 73.98 - 64.68 j " В". $
]

#lab-figure(
  caption: [Векторная диаграмма токов],
  vector-diagram(
    currents: (
      (val: (re: -0.132, im: 0.863), label: $dot(I)_2$, color: rgb("e63946"), anchor: "south-east"),
      (val: (re: -0.844, im: -0.084), label: $dot(I)_7$, color: rgb("2a9d8f"), anchor: "north-west"),
      (val: (re: -0.976, im: 0.779), label: $dot(I)_1$, color: rgb("1d3557"), dashed: true, anchor: "north-east"),
    ),
    axes: (x: 2, y: 2)
  )
)

= Определение тока в ветви 6 МЭГН
Исключаем 6-ю ветвь (разрываем цепь между узлами 2 и 3). При этом цепь ветвей 5 и 1 разрывается, и ток в них становится равным нулю.
На рисунке 4 изображена схема для расчета напряжения холостого хода.

#lab-figure(
  caption: [Схема для расчета напряжения холостого хода],
  circuit-better(scale-factor: 85%, {
    import zap: *
    node-better("1", (0, 6), label: (content: "1", anchor: "east", distance: 0.5), visible: true)
    node-better("6", (12, 6), label: (content: "6", anchor: "west", distance: 0.5), visible: true)
    node-better("2", (12, 0), label: (content: "2", anchor: "west", distance: 0.5), visible: true)
    node-better("3", (0, 0), label: (content: "3", anchor: "east", distance: 0.5), visible: true)

    resistor-better("ZAB", "1", "6", label: (content: $Z_"AB"$, anchor: "south", distance: 0.5))
    
    source-better("E5", "6", (12, 3), label: (content: $E_5$, anchor: "east", distance: 0.5), arrow-dir: "forward")
    resistor-better("Z5", (12, 3), "2", label: (content: $Z_5$, anchor: "east", distance: 0.5))

    resistor-better("Z1", "3", "1", label: (content: $Z_1$, anchor: "west", distance: 0.5))

    open-branch-better("Uxx", "2", "3", label: (content: $dot(U)_230$, anchor: "south", distance: 0.5), arrow-side: "south", arrow-dir: "forward", show-terminals: true, arrow-offset: 0.4)
  })
)

Напряжение холостого хода:
#mathtype-mimic[
  $ dot(U)_230 = phi_2 - phi_3 = (phi_6 + dot(E)_5) - phi_1 = dot(U)_61^("хх") + dot(E)_5. $
]
Так как пассивные ветви $A$ и $B$ не содержат источников, $dot(U)_61^("хх") = 0$. Следовательно:
#mathtype-mimic[
  $ dot(U)_230 = dot(E)_5 = -15.46 + 34.71 j " В". $
]

Закоротив источники ЭДС, находим эквивалентное сопротивление схемы относительно зажимов 2-3 (рисунок 5):

#lab-figure(
  caption: [Схема для расчета эквивалентного сопротивления],
  circuit-better(scale-factor: 85%, {
    import zap: *
    node-better("1", (0, 6), label: (content: "1", anchor: "east", distance: 0.5), visible: true)
    node-better("6", (12, 6), label: (content: "6", anchor: "west", distance: 0.5), visible: true)
    node-better("2", (12, 0), label: (content: "2", anchor: "west", distance: 0.5), visible: true)
    node-better("3", (0, 0), label: (content: "3", anchor: "east", distance: 0.5), visible: true)

    resistor-better("ZAB", "1", "6", label: (content: $Z_"AB"$, anchor: "south", distance: 0.5))
    
    wire("6", (12, 3))
    resistor-better("Z5", (12, 3), "2", label: (content: $Z_5$, anchor: "east", distance: 0.5))

    resistor-better("Z1", "3", "1", label: (content: $Z_1$, anchor: "west", distance: 0.5))

    open-branch-better("Zin", "2", "3", label: (content: $Z_"экв"$, anchor: "south", distance: 0.5), arrow-side: "south", arrow-dir: "forward", arrow-offset: 0.4)
  })
)

#mathtype-mimic[
  $ dot(Z)_"экв" = dot(Z)_5 + dot(Z)_"AB" + dot(Z)_1 = (55 - 27 j) + (50.56 + 9.43 j) + (89 + 47 j) = 194.56 + 29.43 j " Ом". $
]

Подключаем ветвь 6 к эквивалентному генератору (рисунок 6) и находим ток $dot(I)_6$:

#lab-figure(
  caption: [Эквивалентная схема МЭГН],
  circuit-better(scale-factor: 85%, {
    import zap: *
    node-better("2", (12, 6), label: (content: "2", anchor: "west", distance: 0.5), visible: true)
    node-better("3", (0, 6), label: (content: "3", anchor: "east", distance: 0.5), visible: true)
    
    wire("2", (12, 2))
    source-better("Eeq", (12, 2), (6, 2), label: (content: $dot(U)_230$, anchor: "south", distance: 0.5), arrow-dir: "backward")
    resistor-better("Zeq", (6, 2), (0, 2), label: (content: $Z_"экв"$, anchor: "south", distance: 0.5))
    wire((0, 2), "3")

    capacitor-better("C6", "3", (6,6), label: (content: $C_6$, anchor: "south", distance: 0.5), arrow-label: (content: $I_6$, anchor: "north", distance: 0.5), arrow-side: "north", arrow-offset: 0.4, arrow-dir: "backward")
    inductor-better("L6", (6,6), "2", label: (content: $L_6$, anchor: "south", distance: 0.5))
    
    wire("2", (12, 10))
    jsource-better("J6", (12,10), (0,10), label: (content: $J_6$, anchor: "north", distance: 0.5), arrow-dir: "forward")
    wire((0,10), "3")
  })
)

#mathtype-mimic[
  $ dot(I)_6 = (dot(U)_230 + dot(J)_6 dot(Z)_6) / (dot(Z)_"экв" + dot(Z)_6) = (-15.46 + 34.71 j - 174.09 + 117.42 j) / (194.56 + 29.43 j - 30 j) = $
  $ = (-189.55 + 152.13 j) / (194.56 - 0.57 j) = -0.976 + 0.779 j " А". $
]
Ток полностью совпадает с рассчитанным ранее.

= Таблица ответов

#figure(
  caption: none,
  table(
    columns: (auto, auto, auto, auto, auto),
    align: center + horizon,
    table.header(
      table.cell(rowspan: 2)[Параметр],
      table.cell(colspan: 2)[Алгебраическая форма],
      table.cell(colspan: 2)[Показательная форма],
      [Re], [Im], [Модуль], [Арг., $degree$]
    ),
    [$I_1=I_5=I_6$], [-0.976], [0.779], [1.250], [141.4],
    [$I_2=I_3=I_4$], [-0.132], [0.863], [0.873], [98.7],
    [$I_7$], [-0.844], [-0.084], [0.848], [-174.3],
    [Мощность $S_"ист"$], [303.51], [-1512.68], [1542.8], [-78.6],
    [Мощность $S_"потр"$], [303.42], [-1512.50], [1542.6], [-78.6],
    [$U_230$], [-15.46], [34.71], [38.00], [114.0],
    [$Z_"экв"$], [194.56], [29.43], [196.77], [8.6]
  )
)