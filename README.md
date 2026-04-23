# BSUIR typst core

### Modules:
* АиЛОЦУ = AaLUB (Arithmetic and Logical Units Basics)
* ТЭЦ = ToEC (Theory of Electric Chains)

### Requirements:
* Times New Roman (and **Bold**, _Italic_, etc...) installed in system ([Linux MS fonts guide](https://linuxcapable.com/install-microsoft-fonts-on-fedora-linux/))
* typst >= 0.14.2

## Quick start:
* in progress (package will be published)

## Build locally:
* install [utpm 3.0.0](https://github.com/typst-community/utpm) (you have to build it yourself)
* ``utpm prj bump x.x.x`` (if you have changed the code and want a new version)
* ``utpm prj link``
* now use can use it with ``#import "@local/typst-bsuir-core:x.x.x": *``

## To put this project into LLM:
I used, just as example:
``folder2text ./src/aalub --tree -o my-lib.txt`` ([folder2text](https://github.com/chibixar/folder2text))

## Projects with typst-bsuir-core:
* ТЭЦ
  * [Лабораторная работа №1 (Исследование цепи постоянного тока методом наложения)](https://github.com/slavita256bit/toec-lab1)
  * [Лабораторная работа №2 (Исследование цепи постоянного тока методом узловых потенциалов и методом эквивалентного генератора)](https://github.com/slavita256bit/toec-lab2)
* АИЛОЦУ
  * [Курсовая работа, КИ, 2 семестр](https://github.com/slavita256bit/aalub-courseproject-1) (IN PROGRESS)

## Dependencies (and credits):
* gost: [modern-g7-32](https://github.com/typst-gost/modern-g7-32)
* circuits: [zap](https://github.com/l0uisgrange/zap), [documentation](https://zap.grangelouis.ch/#decorations)
* diagrams + circuits: [cetz](https://github.com/cetz-package/cetz), [documentation](https://cetz-package.github.io/docs/getting-started)

[//]: # (* math &#40;matrix operations&#41;: [numty]&#40;https://github.com/PabloRuizCuevas/numty&#41;)

[//]: # (* latex inside typst &#40;hehe&#41;: [mitex]https://github.com/mitex-rs/mitex&#41;)

## Also thanks to:

* [typst](https://github.com/typst/typst) for making this possible
* [utpm](https://github.com/typst-community/utpm) is used to create package

## Todo:
* finish aalub cource project
* make separate dependencies.typ file
* add licence file
* publish package