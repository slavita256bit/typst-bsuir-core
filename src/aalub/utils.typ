#import "maps.typ": *
#import "map-converters.typ": tt-to-karnaugh, tt-to-veitch
#import "formatters.typ": get-mcnf, get-mdnf

// Универсальная функция для отрисовки карты Карно и вывода формулы
#let draw-map-block(
    encoded-tt,        // Закодированная таблица истинности
    in-cols,           // Индексы входных колонок, например (0, 1, 2, 3, 4)
    out-col,           // Индекс выходной колонки
    x-labels,          // Метки X (gray-code)
    y-labels,          // Метки Y (gray-code)
    vars-label,        // Подписи переменных, например ($a_1 a_2$, $b_1 b_2 p$)
    vars-map,          // Карта позиций переменных для генератора МДНФ
    vars-list,         // Список переменных для формулы, например ($a_1$, $a_2$, ...)
    groups,            // Группы (контуры) на карте
    eq-name,           // Имя функции, например $S_1$ или $P_1$
    is-mcnf: false     // Если true - строит МКНФ и прячет "1"
) = align(center)[
    #let map-data = tt-to-karnaugh(
        encoded-tt, in-cols, out-col,
        gray-cols: x-labels, gray-rows: y-labels,
        default-val: "БРЕД" // поможет увидеть ошибки на карте
    )

    #karnaugh-map(
        x-labels: x-labels,
        y-labels: y-labels,
        hide: if is-mcnf { "1" } else { "0" },
        vars-label: vars-label,
        grid-data: map-data,
        groups: groups
    )

    #let eq = if is-mcnf {
        get-mcnf(groups, vars-map, vars-list, rows: y-labels.len(), cols: x-labels.len())
    } else {
        get-mdnf(groups, vars-map, vars-list, rows: y-labels.len(), cols: x-labels.len())
    }

    $ #eq-name = #eq $
]