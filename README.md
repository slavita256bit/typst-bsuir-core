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
* ```shell
    utpm prj bump x.x.x
    utpm prj link
  ```
* now use can use it with ``#import "@local/typst-bsuir-core:x.x.x": *``

## Projects with typst-bsuir-core:
* [ТЭЦ, Лабораторная работа №1 (Исследование цепи постоянного тока методом наложения)](https://github.com/vetolet/toec-lab1)

## Dependencies (and thanks):
* gost: [modern-g7-32](https://github.com/typst-gost/modern-g7-32)
* circuits: [zap](https://github.com/l0uisgrange/zap), [documentation](https://zap.grangelouis.ch/#decorations)
* diagrams + circuits: [cetz](https://github.com/cetz-package/cetz), [documentation](https://cetz-package.github.io/docs/getting-started)

## Thanks:

* [typst](https://github.com/typst/typst) for making this possible
* [utpm](https://github.com/typst-community/utpm) is used to create package

## Todo:
* more aalub cource project functions
* second toec lab
* for toec, make R_i and other inputs (and values) with const variable and calculate everything inline, without raw numbers in equations
* add licence file
* publish package