# BSUIR typst core

### Modules:
* АиЛОЦУ = AaLUB (Arithmetic and Logical Units Basics) (a lot of hardcode specific to my variant)
* ТЭЦ = ToEC (Theory of Electric Chains)

### Requirements:
* Times New Roman (and **Bold**, _Italic_, etc...) installed in system ([Linux MS fonts guide](https://linuxcapable.com/install-microsoft-fonts-on-fedora-linux/))
* GOST Type A (and B and their variations ...) installed in system (just .ttf from any website)
* typst >= 0.14.2

## Quick start:
* IN PROGRESS (package will be published)

## Build locally:
* install [utpm 3.0.0](https://github.com/typst-community/utpm) (you have to build it yourself)
* ``utpm prj bump x.x.x`` (if you have changed the code and want a new version)
* ``utpm prj link``
* now use can use it with ``#import "@local/typst-bsuir-core:x.x.x": *``

## To put this project into LLM:
I used, just as example:
``folder2text ./src/aalub --tree -o my-lib.txt`` ([folder2text by Chibixar](https://github.com/chibixar/folder2text))

## Projects with typst-bsuir-core:
* ТЭЦ
  * [Лабораторная работа №1 (Исследование цепи постоянного тока методом наложения)](https://github.com/slavita256bit/toec-lab1)
    * [Лабораторная работа №2 (Исследование цепи постоянного тока методом узловых потенциалов и методом эквивалентного генератора)](https://github.com/slavita256bit/toec-lab2)
  * [Лабораторная работа №3 (Исследование простых цепей синусоидального тока)](https://github.com/slavita256bit/toec-lab3)
  * [Типовой расчёт часть 1](https://github.com/slavita256bit/toec-typical-calculations-1)
  * Типовой расчёт часть 2 [by Slavita256bit](https://github.com/slavita256bit/toec-typical-calculations-2) (IN PROGRESS), [by Chibixar](https://github.com/chibixar/TR_part2_TOEC)
* АИЛОЦУ
  * [Курсовая работа, КИ, 2 семестр](https://github.com/slavita256bit/aalub-courseproject-1)

## Dependencies (and credits):
* gost: [modern-g7-32](https://github.com/typst-gost/modern-g7-32)
* circuits: [zap](https://github.com/l0uisgrange/zap), [documentation](https://zap.grangelouis.ch/#decorations)
* diagrams + circuits: [cetz](https://github.com/cetz-package/cetz), [documentation](https://cetz-package.github.io/docs/getting-started)

[//]: # (* math &#40;matrix operations&#41;: [numty]&#40;https://github.com/PabloRuizCuevas/numty&#41;)

[//]: # (* latex inside typst &#40;hehe&#41;: [mitex]https://github.com/mitex-rs/mitex&#41;)

## Also thanks to:

* [typst](https://github.com/typst/typst) for making this possible
* [utpm](https://github.com/typst-community/utpm) is used to create package
* [gost eskd/espd frames](https://github.com/typst-gost/stamp-eskd-spds/)

## Todo:
* think about cross-file-link structure
* aalub complex scheme files are obsolete a bit, remove code duplication
* toec (and other) scheme inheritance (just to make less code duplication)?
* move some common things from aalub courceproject and toec typical 2 to common file (make **our** gost constructor)
* better project structure
* add **just** file for easier developing (for deploy/llm file generating)
* make separate dependencies.typ file
* add licence file
* publish package
* maybe: remove aalub hardcode specific to my variant

## If you want to use this project:
[//]: # (todo If you want to gain money, please give me some credits &#40;and percents&#41;)

Also, there is no guarantee of compatability between versions

P.S. After some time, I realized that a lot for things can be done better and there is a lot of hardcode, but currently I have no enough impulse to rewrite this completely 