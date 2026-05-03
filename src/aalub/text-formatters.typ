// Превращает словарь в красивую строку: "0 – 00; 1 – 11; 2 – 10; 3 – 01"
#let encoding-as-text(code-dict, dot: true) = {
  code-dict.keys().sorted().map(k => [$#k _4$ – #code-dict.at(k)]).join([; ]) + if dot {"."} else {""}
}
