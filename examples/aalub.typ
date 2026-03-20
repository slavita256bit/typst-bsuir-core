#import "@local/typst-bsuir-core:0.6.2": *
#import "@preview/modern-g7-32:0.2.0": gost, custom-title-template

#set text(font: "Times New Roman", size: 14pt)
#show math.equation: set text(font: "STIX Two Math", size: 14pt)

#show: gost.with(
  title-template: custom-title-template.from-module(aalub-course-project-title),
  approver: (name: "В. С. Ермаков"),
  work: (
    topic: "Проектирование и логический синтез\nсумматора-умножителя двоично-четверичных чисел",
    code: "БГУИР КР 6-05-0611-05 558 ПЗ"
  ),
  student: (name: "В. С. Ермаков", group: "558301"),
  manager: (name: "Ю. А. Луцик"),
  city: "",
  year: "",
  title-city: "МИНСК",
  title-year: "2026",
)
