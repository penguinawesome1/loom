import gleam/io
import gleam/list
import gleam/string
import gleamy/bench
import loom_string
import simplifile

pub fn main() {
  let assert Ok(input) = simplifile.read("./test/data/dictionary.txt")

  let words =
    input
    |> string.trim
    |> string.split("\n")

  let pairs = list.map(words, fn(w) { #(w, 0) })
  let trie = loom_string.from_list(pairs)

  bench.run(
    [bench.Input("dictionary", words)],
    [
      bench.Function("build", fn(_) {
        loom_string.from_list(pairs) |> fn(_) { Nil }
      }),
      bench.Function("get  ", fn(keys) {
        list.each(keys, fn(key) { loom_string.get(trie, key) })
      }),
      bench.Function("del  ", fn(keys) {
        list.fold(keys, trie, loom_string.delete) |> fn(_) { Nil }
      }),
      bench.Function("pre  ", fn(keys) {
        list.each(keys, loom_string.at_prefix(trie, _))
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println
}
