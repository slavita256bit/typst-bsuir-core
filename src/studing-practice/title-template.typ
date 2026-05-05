#import "@preview/modern-g7-32:0.2.0": custom-title-template
#import custom-title-template: *

// 1. ARGUMENTS PARSER
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
    args.at("faculty", default: "компьютерных систем и сетей"),
    ("value*",),
    hint: "факультета"
  ).value

  args.department = fetch-field(
    args.at("department", default: "электронных вычислительных машин"),
    ("value*",),
    hint: "кафедры"
  ).value

  args.work = fetch-field(
    args.at("work", default: (
      type: "Отчет",
      subject: "по учебной (ознакомительной) практике"
    )),
    ("type*", "subject*"),
    hint: "работы"
  )

  args.student = fetch-field(
    args.at("student", default: (name: "Иванов И.И.", group: "150501")),
    ("name*", "group*"),
    hint: "студента"
  )

  args.manager = fetch-field(
    args.at("manager", default: (
      name: "Петров П.П.",
      title: "кандидат технических наук, доцент"
    )),
    ("name*", "title*"),
    hint: "руководителя"
  )

  args.footer = fetch-field(
    args.at("footer", default: (city: "МИНСК", year: "2026")),
    ("city*", "year*"),
    hint: "подвала",
  )

  return args
}

// 2. TEMPLATE LAYOUT
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
) = {

  // Отключаем абзацный отступ для титульника и настраиваем межстрочный интервал
  set par(first-line-indent: 0pt, leading: 0.65em)

  // --- ШАПКА ---
  align(center)[
    #ministry \
    #v(0.5em)
    #organization.type \
    #organization.name

    #v(1em)

    Факультет #faculty
    #v(0.5em)
    Кафедра #department
  ]

  v(1fr)

  // --- ЦЕНТР (Название работы) ---
  align(center)[
    #work.type \
    #work.subject
  ]

  v(1.5fr)

  // --- ПОДПИСИ (Смещены вправо, но выровнены по левому краю) ---
  move(dx: 21em, align(right)[
    #block(width: 8.5cm, align(left)[
      Студент: \
      гр. #student.group #student.name

      #v(2.5em)

      Руководитель: \
      #manager.title \
      #manager.name
    ])
  ])

  v(3fr)

  // --- ПОДВАЛ (Город и год через твой трюк) ---
  place(
    bottom + center,
    dy: -1cm,
    [#footer.city #footer.year]
  )
}