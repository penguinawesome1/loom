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
    [bench.Input("all_words", pairs)],
    [
      bench.Function("build", fn(pairs) {
        loom_string.from_list(pairs) |> fn(_) { Nil }
      }),
    ],
    [bench.Duration(2000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println

  bench.run(
    [bench.Input("short_word", "cat"), bench.Input("long_word", "strawberry")],
    [
      bench.Function("get", fn(word) {
        loom_string.get(trie, word) |> fn(_) { Nil }
      }),
      bench.Function("delete", fn(word) {
        loom_string.delete(trie, word) |> fn(_) { Nil }
      }),
      bench.Function("prefix", fn(word) {
        loom_string.at_prefix(trie, word) |> fn(_) { Nil }
      }),
      bench.Function("fuzzy", fn(word) {
        loom_string.fuzzy_search(trie, word, 1) |> fn(_) { Nil }
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.P(99)])
  |> io.println
}
