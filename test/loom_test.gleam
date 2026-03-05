import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import loom

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn new_test() {
  let trie = loom.new()
  assert loom.is_empty(trie)
  assert trie |> loom.get([]) == Error(Nil)
}

pub fn size_test() {
  let trie = loom.new()
  assert loom.size(trie) == 0

  let trie =
    trie
    |> loom.insert(string.to_graphemes("hello"), 0)
    |> loom.insert(string.to_graphemes("hi!"), 0)
  assert loom.size(trie) == 2

  let trie = trie |> loom.delete(string.to_graphemes("hello"))
  assert loom.size(trie) == 1
}

pub fn is_empty_test() {
  let trie = loom.new()
  assert loom.is_empty(trie)

  let trie =
    trie
    |> loom.insert(string.to_graphemes("hello"), 0)
    |> loom.insert(string.to_graphemes("hi!"), 0)
  assert !loom.is_empty(trie)

  let trie = trie |> loom.delete(string.to_graphemes("hello"))
  assert !loom.is_empty(trie)

  let trie = trie |> loom.delete(string.to_graphemes("hi!"))
  assert loom.is_empty(trie)
}

pub fn has_key_test() {
  let trie = loom.new()
  assert trie |> loom.has_key([]) == False

  let trie = trie |> loom.insert(string.to_graphemes("abc"), 5)
  assert trie |> loom.has_key(string.to_graphemes("abc"))

  let trie = trie |> loom.insert(string.to_graphemes("abcd"), 6)
  assert trie |> loom.has_key(string.to_graphemes("abcd"))

  let trie = trie |> loom.delete(string.to_graphemes("abcd"))
  assert trie |> loom.has_key(string.to_graphemes("abcd")) == False
  assert trie |> loom.has_key(string.to_graphemes("abc"))
}

pub fn insert_test() {
  let trie = loom.new() |> loom.insert(["a"], 0) |> loom.insert(["a"], 1)
  assert trie |> loom.size == 1
  assert trie |> loom.get(["a"]) == Ok(1)

  let trie = trie |> loom.insert(["a", "a"], 1) |> loom.insert(["a", "b"], 2)
  assert trie |> loom.size == 3
  assert trie |> loom.get(["a", "a"]) == Ok(1)
  assert trie |> loom.get(["a", "b"]) == Ok(2)
}

pub fn get_test() {
  let trie = loom.new() |> loom.insert(string.to_graphemes("abc"), 5)
  assert trie |> loom.get(string.to_graphemes("ab")) == Error(Nil)
  assert trie |> loom.get(string.to_graphemes("bc")) == Error(Nil)
  assert trie |> loom.get(string.to_graphemes("a-bc")) == Error(Nil)
  assert trie |> loom.get(string.to_graphemes("aBc")) == Error(Nil)
  assert trie |> loom.get(string.to_graphemes("abcd")) == Error(Nil)
  assert trie |> loom.get(string.to_graphemes("abc")) == Ok(5)

  let trie = trie |> loom.delete(string.to_graphemes("abc"))
  assert trie |> loom.get(string.to_graphemes("abc")) == Error(Nil)
}

pub fn upsert_test() {
  let increment = fn(v_opt) {
    case v_opt {
      Some(v) -> Some(v + 1)
      None -> Some(1)
    }
  }

  let trie =
    loom.new()
    |> loom.insert([1, 1], 3)
    |> loom.upsert([1, 1], increment)
    |> loom.upsert([3], increment)

  assert trie |> loom.get([1, 1]) == Ok(4)
  assert trie |> loom.get([3]) == Ok(1)

  let trie =
    trie
    |> loom.upsert([1, 1], increment)
    |> loom.upsert([1, 1], increment)
    |> loom.upsert([1, 2, 3], increment)

  assert trie |> loom.get([1, 1]) == Ok(6)
  assert trie |> loom.get([1]) == Error(Nil)
  assert trie |> loom.get([1, 2]) == Error(Nil)
  assert trie |> loom.get([1, 2, 3]) == Ok(1)
}

pub fn delete_test() {
  let trie =
    loom.new()
    |> loom.insert(string.to_graphemes("abc"), 5)
    |> loom.delete(string.to_graphemes("abc"))
  assert loom.is_empty(trie)

  let trie =
    trie
    |> loom.insert(["a"], 0)
    |> loom.insert(["b"], 1)
    |> loom.insert(["a", "b"], 3)
    |> loom.delete(["a", "b"])
  assert trie |> loom.get(["a"]) == Ok(0)
  assert trie |> loom.get(["b"]) == Ok(1)
  assert trie |> loom.get(["a", "b"]) == Error(Nil)

  let trie =
    loom.new()
    |> loom.insert(["a", "b"], 0)
    |> loom.insert(["a"], 0)
    |> loom.delete(["a"])
  assert trie |> loom.get(["a"]) == Error(Nil)
}

pub fn map_values_test() {
  let trie =
    loom.new()
    |> loom.insert(string.to_graphemes("abc"), 1)
    |> loom.insert(string.to_graphemes("ab"), 2)
    |> loom.insert(string.to_graphemes("w"), 10)
    |> loom.insert(string.to_graphemes("a"), 3)
    |> loom.map_values(fn(_k, v) { Some(v * 2) })

  assert trie |> loom.get(["a", "b", "c"]) == Ok(2)
  assert trie |> loom.get(["a", "b"]) == Ok(4)
  assert trie |> loom.get(["w"]) == Ok(20)
  assert trie |> loom.get(["a"]) == Ok(6)
}

pub fn fold_test() {
  let trie =
    loom.new()
    |> loom.insert([1, 0], 3)
    |> loom.insert([2], 3)
    |> loom.insert([1, 2], 1)

  assert trie
    |> loom.fold(0, fn(acc, key, value) { acc + int.sum(key) + value })
    == 13
}

pub fn filter_test() {
  let trie =
    loom.new()
    |> loom.insert(string.to_graphemes("I"), 5)
    |> loom.insert(string.to_graphemes("love"), -2)
    |> loom.insert(string.to_graphemes("cats!"), 0)
    |> loom.filter(fn(_key, value) { value >= 0 })

  assert trie |> loom.get(string.to_graphemes("I")) == Ok(5)
  assert trie |> loom.get(string.to_graphemes("love")) == Error(Nil)
  assert trie |> loom.get(string.to_graphemes("cats!")) == Ok(0)

  let trie =
    loom.new()
    |> loom.insert(["a"], 0)
    |> loom.insert(["a", "b"], 1)
    |> loom.insert(["a", "b", "c"], 2)
    |> loom.filter(fn(_key, value) { value != 1 })

  assert trie |> loom.get(["a"]) == Ok(0)
  assert trie |> loom.get(["a", "b"]) == Error(Nil)
  assert trie |> loom.get(["a", "b", "c"]) == Ok(2)
}

pub fn to_list_test() {
  let trie =
    loom.new()
    |> loom.insert(string.to_graphemes("abc"), 1)
    |> loom.insert(string.to_graphemes("ab"), 2)
    |> loom.insert(string.to_graphemes("w"), 10)
    |> loom.insert(string.to_graphemes("a"), 3)

  assert trie
    |> loom.to_list
    |> list.sort(fn(a, b) {
      string.compare(string.concat(a.0), string.concat(b.0))
    })
    == [
      #(string.to_graphemes("a"), 3),
      #(string.to_graphemes("ab"), 2),
      #(string.to_graphemes("abc"), 1),
      #(string.to_graphemes("w"), 10),
    ]
}

pub fn from_list() {
  let trie =
    loom.from_list([
      #(string.to_graphemes("abc"), 1),
      #(string.to_graphemes("ab"), 2),
      #(string.to_graphemes("wx"), 10),
      #(string.to_graphemes("a"), 3),
    ])

  assert trie |> loom.get(string.to_graphemes("abc")) == Ok(1)
  assert trie |> loom.get(string.to_graphemes("ab")) == Ok(2)
  assert trie |> loom.get(string.to_graphemes("w")) == Error(Nil)
  assert trie |> loom.get(string.to_graphemes("wx")) == Ok(10)
  assert trie |> loom.get(string.to_graphemes("a")) == Ok(3)
}

pub fn keys_test() {
  let trie = loom.new()
  assert trie |> loom.keys == []

  let trie = trie |> loom.insert([3, 2, 1], 0) |> loom.insert([1], 4)
  assert loom.keys(trie)
    |> list.sort(fn(a, b) {
      let assert Ok(a) = list.first(a)
      let assert Ok(b) = list.first(b)
      int.compare(a, b)
    })
    == [[1], [3, 2, 1]]
}

pub fn values_test() {
  let trie = loom.new()
  assert trie |> loom.values == []

  let trie = trie |> loom.insert([3, 2, 1], 0) |> loom.insert([1], 4)
  assert loom.values(trie) |> list.sort(int.compare) == [0, 4]
}

pub fn at_prefix_test() {
  let trie =
    loom.new()
    |> loom.insert(["a", "b", "c"], 1)
    |> loom.insert(["a", "b", "d"], 2)

  assert trie |> loom.at_prefix(["z"]) == Error(Nil)
  assert trie |> loom.at_prefix(["b", "c"]) == Error(Nil)

  let assert Ok(trie) = trie |> loom.at_prefix(["a", "b"])

  assert trie |> loom.get(["c"]) == Ok(1)
  assert trie |> loom.get(["d"]) == Ok(2)
  assert trie |> loom.get(["a", "b"]) == Error(Nil)
}

pub fn find_pattern_test() {
  let trie =
    loom.new()
    |> loom.insert(string.to_graphemes("bat"), 1)
    |> loom.insert(string.to_graphemes("cat"), 2)
    |> loom.insert(string.to_graphemes("bar"), 3)
    |> loom.insert(string.to_graphemes("boat"), 4)

  assert loom.find_pattern(trie, [Some("b"), Some("a"), Some("t")])
    == [["b", "a", "t"]]

  assert loom.find_pattern(trie, [None, Some("a"), Some("t")])
    |> list.sort(fn(a, b) { string.compare(string.concat(a), string.concat(b)) })
    == [["b", "a", "t"], ["c", "a", "t"]]

  assert loom.find_pattern(trie, [Some("z"), None, None]) == []

  assert loom.find_pattern(trie, [Some("b"), None, Some("t")])
    == [["b", "a", "t"]]
}
