#import "@preview/modern-g7-32:0.2.0": *
#import "@local/typst-bsuir-core:0.6.0": *

#set text(font: "Times New Roman", size: 14pt)
#show math.equation: set text(font: "STIX Two Math", size: 14pt)

#show: gost.with(
  title-template: custom-title-template.from-module(toec-template),
  department: "Кафедра теоретических основ электротехники",
  work: (
    type: "Лабораторная работа",
    number: "1",
    subject: "Исследование цепи постоянного тока методом наложения",
    variant: "4",
  ),
  manager: (
    name: "Батюков С.В.",
  ),
  performer: (
    name: "Ермаков В. С.",
    group: "558301",
  ),
  footer: (city: "Минск", year: 2026),
  city: none,
  year: none,
  add-pagebreaks: false,
  text-size: 14pt,
)

#show: apply-toec-styling

= Цель работы
Экспериментальная проверка метода наложения, принципа взаимосвязи, построение потенциальной диаграммы.

= Расчёт домашнего задания

Исходные данные варианта представлены в таблице 1.

$dots$