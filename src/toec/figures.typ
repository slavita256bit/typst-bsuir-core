#let lab-figure(
  body,
  caption: none,
  above: 0em,
  ..args // собираем остальные аргументы
) = {
  let final-caption = if caption != none {
    caption
  } else {
    // Если caption не задан, используем трюк для пустого caption
    figure.caption(separator: none, [])
  }

  // Оборачиваем всё в блок или выносим отступ в параметры figure
  figure(
    {
      v(above) // теперь отступ часть "тела" фигуры
      move(dx: 0cm, body)
    },
    caption: final-caption,
    ..args
  )
}