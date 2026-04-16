#import "fmt.typ": *

#let rect(re, im) = (re: re, im: im)
#let polar(mag, ang) = (mag: mag, ang: ang) // ang в градусах

#let to-polar(c) = {
  if "mag" in c { return c }
  (
    mag: calc.sqrt(calc.pow(c.re, 2) + calc.pow(c.im, 2)),
    ang: calc.atan2(c.re, c.im).deg()
  )
}

#let to-rect(c) = {
  if "re" in c { return c }
  let ang-deg = c.ang * 1deg // <--- ИСПРАВЛЕНИЕ ЗДЕСЬ
  (
    re: c.mag * calc.cos(ang-deg),
    im: c.mag * calc.sin(ang-deg)
  )
}

#let add(c1, c2) = {
  let r1 = to-rect(c1); let r2 = to-rect(c2)
  rect(r1.re + r2.re, r1.im + r2.im)
}

#let sub(c1, c2) = {
  let r1 = to-rect(c1); let r2 = to-rect(c2)
  rect(r1.re - r2.re, r1.im - r2.im)
}

#let mul(c1, c2) = {
  let p1 = to-polar(c1); let p2 = to-polar(c2)
  polar(p1.mag * p2.mag, p1.ang + p2.ang)
}

#let div(c1, c2) = {
  let p1 = to-polar(c1); let p2 = to-polar(c2)
  polar(p1.mag / p2.mag, p1.ang - p2.ang)
}

// Умное отображение комплексного числа
#let display-complex(c, p-digits: 2, r-digits: 2, units: "") = {
  let p = to-polar(c)
  let r = to-rect(c)
  let re-part = _fmt(r.re, digits: r-digits)
  let im-part = _fmt(calc.abs(r.im), digits: r-digits)
  let sign_im = if r.im < 0 { "-" } else { "+" }

  let j_signed = if p.ang < 0 { $-j$ } else { $j$ }
  let ang = calc.abs(p.ang)
  let rect-str = $#re-part #sign_im j #im-part$
  let polar-str = $#_fmt(p.mag, digits: p-digits) e^(#j_signed #_fmt(ang, digits: p-digits) degree)$

  (rect: rect-str, polar: polar-str, both: $#rect-str = #polar-str #units$)
}