#import "@preview/modern-g7-32:0.2.0": custom-title-template
#import custom-title-template: *

// 1. ПАРСЕР АРГУМЕНТОВ
#let arguments(..args) = {
  let args = args.named()

  args.ministry = fetch-field(
    args.at("ministry", default: "Министерство образования Республики Беларусь"),
    ("value*",),
  ).value

  args.organization = fetch-field(
    args.at("organization", default: none),
    ("type*", "name*"),
    default: (
      type: "Учреждение образования",
      name: "БЕЛОРУССКИЙ ГОСУДАРСТВЕННЫЙ УНИВЕРСИТЕТ\nИНФОРМАТИКИ И РАДИОЭЛЕКТРОНИКИ",
    ),
    hint: "организации",
  )

  args.faculty = fetch-field(
    args.at("faculty", default: "информационной безопасности"),
    ("value*",),
    hint: "факультета"
  ).value

  args.department = fetch-field(
    args.at("department", default: "информационно-измерительных систем"),
    ("value*",),
    hint: "кафедры"
  ).value

  args.work = fetch-field(
    args.at("work", default: (
      type: "ОТЧЕТ",
      number: "к практическому занятию №2",
      topic: "Метрологические параметры в цифровых системах"
    )),
    ("type*", "number*", "topic*"),
    hint: "работы"
  )

  args.student = fetch-field(
    args.at("student", default: (name: "Каптюг И. М.", group: "550503")),
    ("name*", "group*"),
    hint: "студента"
  )

  args.manager = fetch-field(
    args.at("manager", default: (name: "Доронина А.В.")),
    ("name*",),
    hint: "руководителя"
  )

  args.footer = fetch-field(
    args.at("footer", default: (city: "Минск", year: "2026")),
    ("city*", "year*"),
    hint: "подвала",
  )

  return args
}

// 2. ВЕРСТКА ТИТУЛЬНИКА
#let template(
  ministry: none,
  organization: (:),
  faculty: none,
  department: none,
  work: (:),
  student: (:),
  manager: (:),
  city: none,
  year: none,
  footer: none,
  ..args
) = {
  // Отключаем абзацный отступ для титульника и ставим компактный интервал
  set par(first-line-indent: 0pt, leading: 0.65em)

  // --- ШАПКА ---
  align(center)[
    #ministry \
    #v(0.8em)
    #organization.type \
    #organization.name

    #v(1.4em)

    #if not faculty.starts-with("Факультет") [Факультет ]#faculty \
    #v(0.6em)
    #if not department.starts-with("Кафедра") [Кафедра ]#department
  ]

  v(1.5fr)

  // --- ЦЕНТР (Название работы) ---
  align(center)[
    #work.type \
    #work.number \
    на тему \
    #work.topic
  ]

  v(2fr)

  // --- ПОДПИСИ (Смещены вправо, но выровнены по левому краю) ---
  move(dx: 21em, align(right)[
    #block(width: 8.5cm, align(left)[
      Выполнил: \
      студент гр. #student.group \
      #student.name

      #v(2.5em)

      Проверил: \
      #manager.name
    ])
  ])

  v(3fr)

  // --- ПОДВАЛ (Город и год) ---
  place(
    bottom + center,
    dy: -1cm,
    [#footer.city #footer.year]
  )
}