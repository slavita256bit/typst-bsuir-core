// Превращает словарь в красивую строку: "0 – 00; 1 – 11; 2 – 10; 3 – 01"
#let encoding-as-text(code-dict) = {
  code-dict.keys().sorted().map(k => [#k – #code-dict.at(k)]).join([; ]) + "."
}