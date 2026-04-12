#import "@preview/modern-g7-32:0.2.0": custom-title-template
#import custom-title-template: *

// The `arguments` function defines what parameters our template accepts
// and processes them using `fetch-field` for flexibility.
#let arguments(..args) = {
  let args = args.named()

  // Define and fetch all the fields we need for the title page.
  // The "*" marks a field as required.
  args.ministry = fetch-field(
    args.at("ministry", default: "Министерство образования Республики Беларусь"),
    ("value*",),
  ).value

  args.organization = fetch-field(
    args.at("organization", default: none),
    ("type*", "name*"),
    default: (
      type: "Учреждение образования",
      name: "«Белорусский государственный университет информатики и радиоэлектроники»",
    ),
    hint: "организации",
  )

  args.department = fetch-field(
    args.at("department", default: none),
    ("value*",),
    hint: "кафедры",
  ).value

  args.work = fetch-field(
    args.at("work", default: none),
    ("type*", "number*", "subject*", "variant*"),
    hint: "работы",
  )

  args.manager = fetch-field(
    args.at("manager", default: none),
    ("name*",),
    hint: "руководителя",
  )

  args.performer = fetch-field(
    args.at("performer", default: none),
    ("name*", "group*"),
    hint: "исполнителя",
  )

  args.footer = fetch-field(
    args.at("footer", default: none),
    ("city*", "year*"),
    hint: "подвала",
  )

  return args
}

// The `template` function receives the processed arguments and lays out the page.
#let template(
  ministry: none,
  organization: (:),
  department: none,
  work: (:),
  manager: none,
  performer: none,
  city: none,
  year: none,
  footer: none,
) = {
  // Use `per-line` for centered text blocks with vertical spacing.
  per-line(
    align: center,
    indent: 0.5em,
    ministry,
  )

  per-line(
    align: center,
    indent: 0.5em,
    organization.type,
    organization.name,
  )

  per-line(
    align: center,
    indent: 2fr,
    department,
  )

  per-line(
    align: center,
    indent: 3fr,
    [Типовой расчет по курсу: «Теория электрических цепей»],
    [Тема: «#work.subject»],
    [Шифр студента № #work.variant],
  )

  // The signature block is right-aligned. The grid columns are now 'auto'
  // to ensure the spacing between labels and names is natural.
  align(
    right,
    grid(
      columns: (auto, auto),
      column-gutter: 1em,
      row-gutter: 0.5em,
      [Проверил:], [#manager.name],
      [Выполнил:], [ст. гр. #performer.group],
      [],          [#performer.name],
    ),
  )

  v(4fr)

  place(
    bottom + center,
    dy: -1cm, // This moves it 1cm UP from the bottom
    [#footer.city #footer.year]
  )
}
