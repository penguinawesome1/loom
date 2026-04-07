import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit
import loom
import loom_string

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn trie_lifecycle_test() {
  let trie =
    loom.new()
    |> loom_string.insert("apple", 1)
    |> loom_string.insert("app", 2)
    |> loom_string.insert("banana", 3)

  assert loom_string.get(trie, "apple") == Ok(1)
  assert loom_string.get(trie, "app") == Ok(2)
  assert loom_string.has_key(trie, "banana") == True
  assert loom_string.get(trie, "ap") == Error(Nil)

  let trie = loom_string.delete(trie, "apple")
  assert loom_string.get(trie, "apple") == Error(Nil)
  assert loom_string.get(trie, "app") == Ok(2)
}

pub fn upsert_test() {
  let trie =
    loom.new()
    |> loom_string.insert("score", 10)

  let trie =
    loom_string.upsert(trie, "score", fn(val) {
      case val {
        Some(n) -> Some(n + 5)
        None -> Some(0)
      }
    })
  assert loom_string.get(trie, "score") == Ok(15)

  let trie = loom_string.upsert(trie, "new", fn(_) { Some(1) })
  assert loom_string.get(trie, "new") == Ok(1)
}

pub fn map_values_test() {
  let trie = loom_string.from_list([#("a", 1), #("b", 2)])

  let trie = loom_string.map_values(trie, fn(_key, val) { Some(val * 10) })

  assert loom_string.get(trie, "a") == Ok(10)
  assert loom_string.get(trie, "b") == Ok(20)
}

pub fn fold_test() {
  let trie = loom_string.from_list([#("a", 1), #("b", 2), #("c", 3)])

  let total = loom_string.fold(trie, 0, fn(acc, _key, val) { acc + val })
  assert total == 6

  let all_keys = loom_string.fold(trie, "", fn(acc, key, _val) { acc <> key })
  assert all_keys == "abc"
}

pub fn filter_test() {
  let trie = loom_string.from_list([#("apple", 1), #("ball", 2), #("ant", 3)])

  let trie =
    loom_string.filter(trie, fn(key, _val) { string.starts_with(key, "a") })

  assert loom_string.has_key(trie, "apple") == True
  assert loom_string.has_key(trie, "ant") == True
  assert loom_string.has_key(trie, "ball") == False
}

pub fn at_prefix_test() {
  let trie =
    loom_string.from_list([
      #("pod", 1),
      #("pool", 2),
      #("pork", 3),
    ])

  let res = loom_string.at_prefix(trie, "po")
  assert res != Error(Nil)
  let assert Ok(sub) = res

  assert loom_string.has_key(sub, "d") == True
  assert loom_string.has_key(sub, "ol") == True
  assert loom_string.has_key(sub, "rk") == True

  assert loom_string.keys(sub) == ["d", "ol", "rk"]
}

pub fn find_pattern_test() {
  let trie =
    loom.new()
    |> loom_string.insert("bat", 1)
    |> loom_string.insert("cat", 2)
    |> loom_string.insert("bar", 3)
    |> loom_string.insert("boat", 4)

  assert loom_string.find_pattern(trie, "bat") == [#("bat", 1)]
  assert loom_string.find_pattern(trie, "z..") == []
  assert loom_string.find_pattern(trie, "b.t") == [#("bat", 1)]
  assert loom_string.find_pattern(trie, ".at")
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    == [#("bat", 1), #("cat", 2)]
  assert loom_string.find_pattern(trie, "ba.")
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    == [#("bar", 3), #("bat", 1)]
}

pub fn find_pattern_where_test() {
  let trie =
    loom.new()
    |> loom_string.insert("bat", 1)
    |> loom_string.insert("cat", 2)
    |> loom_string.insert("bar", 3)
    |> loom_string.insert("boat", 4)

  assert loom_string.find_pattern_where(trie, ".at", fn(_key, val) { val > 1 })
    == [#("cat", 2)]

  assert loom_string.find_pattern_where(trie, "ba.", fn(key, _val) {
      list.first(key) |> result.unwrap("") == "r"
    })
    == [#("bar", 3)]

  assert loom_string.find_pattern_where(trie, "...", fn(_key, val) { val > 10 })
    == []

  let results =
    loom_string.find_pattern_where(trie, ".at", fn(_, _) { True })
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })

  assert results == [#("bat", 1), #("cat", 2)]
}

pub fn fuzzy_search_test() {
  let trie =
    loom.new()
    |> loom_string.insert("bat", 1)
    |> loom_string.insert("cat", 2)
    |> loom_string.insert("bar", 3)
    |> loom_string.insert("boat", 4)
    |> loom_string.insert("boot", 5)
    |> loom_string.insert("b", 6)
    |> loom_string.insert("ba", 7)
    |> loom_string.insert("batty", 8)
    |> loom_string.insert("baaat", 9)
    |> loom_string.insert("bt", 10)
    |> loom_string.insert("t", 11)

  assert trie
    |> loom_string.fuzzy_search("bat", 1)
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    == [
      #("ba", 7),
      #("bar", 3),
      #("bat", 1),
      #("boat", 4),
      #("bt", 10),
      #("cat", 2),
    ]
}
