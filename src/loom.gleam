import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

/// Data structure optimized for efficient reTRIEval.
/// This implementation provides O(m) time complexity for insertion and search operations,
/// where 'm' is the length of the string.
/// It is particularly useful for autocomplete systems, spell checkers, and IP routing.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> insert(string.to_graphemes("hello world!"), 120)
/// ```
/// 
pub opaque type Trie(key, value) {
  Trie(value: Option(value), children: Dict(key, Trie(key, value)))
}

/// Creates an empty trie.
/// 
pub fn new() -> Trie(k, v) {
  Trie(value: None, children: dict.new())
}

/// Returns the number of values stored in the trie.
/// Runs in O(n) time where 'n' is the total number of nodes.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> size
/// // -> 0
/// ```
/// 
/// ```gleam
/// new() |> insert([1, 5, 2], "value") |> size
/// // -> 1
/// ```
/// 
pub fn size(trie: Trie(k, v)) -> Int {
  let count = case trie.value {
    Some(_) -> 1
    None -> 0
  }

  use acc, _key, child <- dict.fold(trie.children, count)
  acc + size(child)
}

/// Determines whether or not the trie is empty,
/// containing no children or value.
/// 
pub fn is_empty(trie: Trie(k, v)) -> Bool {
  option.is_none(trie.value) && dict.is_empty(trie.children)
}

/// Determines whether or not a value is stored at the given key.
/// Runs in O(m) time, where 'm' is the length of the key.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> insert(["a", "b"], 0) |> has_key(["a"])
/// // -> False
/// ```
/// 
/// ```gleam
/// new() |> insert(["a", "b"], 0) |> has_key(["a", "b"])
/// // -> True
/// ```
/// 
pub fn has_key(trie: Trie(k, v), key: List(k)) -> Bool {
  case key {
    [] -> option.is_some(trie.value)
    [first, ..rest] ->
      trie.children
      |> dict.get(first)
      |> result.map(has_key(_, rest))
      |> result.unwrap(False)
  }
}

/// Inserts a value into the trie at the end of the key.
/// Runs in O(m) time, where 'm' is the length of the key.
/// 
/// If the trie already has a value at the given tree the value is replaced
/// with the new value.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> insert(string.to_graphemes("key"), "value")
/// // -> from_list(#(["k", "e", "y"], "value"))
/// ```
/// 
/// ```gleam
/// new() |> insert(["a"], 0) |> insert(["a", "b"], 1)
/// // -> from_list([#(["a"], 0), #(["a", "b"], 1)])
/// ```
/// 
pub fn insert(
  into trie: Trie(k, v),
  for key: List(k),
  insert value: v,
) -> Trie(k, v) {
  case key {
    [] -> Trie(..trie, value: Some(value))
    [first, ..rest] -> {
      let child = dict.get(trie.children, first) |> result.unwrap(new())
      let child = insert(child, rest, value)
      let children = trie.children |> dict.insert(first, child)

      Trie(..trie, children: children)
    }
  }
}

/// Fetches the value at the end of the key from the trie.
/// Runs in O(m) time, where 'm' is the length of the key.
/// 
/// The trie may not have a value for the key, so the value is wrapped in a `Result`.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> insert(["a"], 0) |> get(["a"])
/// // -> Ok(0)
/// ```
/// 
/// ```gleam
/// new() |> insert(["a"], 0) |> get(["b"])
/// // -> Error(Nil)
/// ```
/// 
pub fn get(from trie: Trie(k, v), get key: List(k)) -> Result(v, Nil) {
  case key {
    [] -> trie.value |> option.to_result(Nil)
    [first, ..rest] ->
      dict.get(trie.children, first) |> result.try(get(_, rest))
  }
}

/// Update an existing value if present, otherwise insert.
/// Runs in O(m) time, where 'm' is the length of the key.
/// 
/// Inserting None on a node with no children will delete it, unless it is the root.
/// 
/// ## Examples
/// 
/// ```gleam
/// let increment = fn(v_opt) {
///   case v_opt {
///     Some(v) -> Some(v + 1)
///     None -> Some(1)
///   }
/// }
/// 
/// new()
/// |> insert([1, 1], 3)
/// |> upsert([1, 1], increment)
/// |> upsert([3], increment)
/// // -> trie.from_list([#([1, 1], 4), #([3], 1)])
/// ```
/// 
pub fn upsert(
  from trie: Trie(k, v),
  update key: List(k),
  using fun: fn(Option(v)) -> Option(v),
) -> Trie(k, v) {
  case key {
    [] -> Trie(..trie, value: fun(trie.value))
    [first, ..rest] -> {
      let child =
        dict.get(trie.children, first)
        |> result.unwrap(new())
        |> upsert(rest, fun)

      let children = case is_empty(child) {
        True -> dict.delete(trie.children, first)
        False -> dict.insert(trie.children, first, child)
      }

      Trie(..trie, children: children)
    }
  }
}

/// Creates a new trie without the value at the end of the key listed, if it exists.
/// Runs in O(m) time, where 'm' is the length of the key.
/// 
/// ## Examples
/// 
/// ```gleam
/// from_list([#(["a"], 0), #(["a", "b"], 1)]) |> delete("a")
/// // -> from_list([#(["a", "b"], 1)])
/// ```
/// 
/// ```gleam
/// from_list([#(["a"], 0)]) |> delete("b")
/// // -> from_list([#(["a"], 0)])
/// ```
/// 
pub fn delete(from trie: Trie(k, v), delete key: List(k)) -> Trie(k, v) {
  case key {
    [] -> Trie(..trie, value: None)
    [first, ..rest] ->
      case dict.get(trie.children, first) {
        Ok(child) -> {
          let child = delete(child, rest)

          let children = case is_empty(child) {
            True -> trie.children |> dict.delete(first)
            False -> trie.children |> dict.insert(first, child)
          }

          Trie(..trie, children: children)
        }
        Error(Nil) -> trie
      }
  }
}

/// Updates all values in a given dict by calling a given function
/// on each key and value.
/// 
/// Prunes branches with no values.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> insert([2], 3) |> map_values(fn(k, v) { int.sum(k) * v })
/// // -> from_list(#([2], 6))
/// ```
/// 
pub fn map_values(
  in trie: Trie(k, v),
  with fun: fn(List(k), v) -> Option(a),
) -> Trie(k, a) {
  map_values_loop(trie, [], fun) |> result.unwrap(new())
}

fn map_values_loop(
  trie: Trie(k, v),
  key_acc: List(k),
  fun: fn(List(k), v) -> Option(a),
) -> Result(Trie(k, a), Nil) {
  let children = {
    use acc, key, child <- dict.fold(trie.children, dict.new())
    let key_acc = [key, ..key_acc]

    case map_values_loop(child, key_acc, fun) {
      Ok(child) -> acc |> dict.insert(key, child)
      Error(Nil) -> acc
    }
  }

  let value = case trie.value {
    Some(value) -> fun(list.reverse(key_acc), value)
    None -> None
  }

  let trie = Trie(value: value, children: children)

  case is_empty(trie) {
    True -> Error(Nil)
    False -> Ok(trie)
  }
}

/// Combines all entries into a single value
/// by calling a given function on each one.
/// Runs in O(n m) time where 'n' is the total number of nodes
/// and 'm' is the average depth.
/// 
/// It does not iterate over elements in a predictable way
/// and any current order may be changed.
/// 
/// ## Examples
/// 
/// ```gleam
/// new()
/// |> insert(["a"], 1)
/// |> insert(["a", "b"], 2)
/// |> fold(0, fn(acc, _key, value) { acc + value })
/// // -> 3
/// ```
/// 
pub fn fold(
  over trie: Trie(k, v),
  from initial: acc,
  with fun: fn(acc, List(k), v) -> acc,
) -> acc {
  fold_loop(trie, [], initial, fun)
}

fn fold_loop(
  trie: Trie(k, v),
  key_acc: List(k),
  acc: acc,
  fun: fn(acc, List(k), v) -> acc,
) -> acc {
  let acc = case trie.value {
    Some(v) -> fun(acc, list.reverse(key_acc), v)
    None -> acc
  }

  use acc, key, child <- dict.fold(trie.children, acc)
  fold_loop(child, [key, ..key_acc], acc, fun)
}

/// Creates a new trie containing only entries for which the
/// predicate returns 'True'.
/// Runs in O(n m) time where 'n' is the total number of nodes
/// and 'm' is the average depth.
/// 
/// Prunes branches with no values.
/// 
/// ## Examples
/// 
/// ```gleam
/// new()
/// |> insert(string.to_graphemes("I"), 5)
/// |> insert(string.to_graphemes("love"), -2)
/// |> insert(string.to_graphemes("cats!"), 0)
/// |> filter(fn(_key, value) { value >= 0 })
/// // -> from_list(#(string.to_graphemes("I"), 5), #(string.to_graphemes("cats!"), 0))
/// ```
///
pub fn filter(in trie: Trie(k, v), keeping predicate: fn(List(k), v) -> Bool) {
  use key, value <- map_values(trie)

  case predicate(key, value) {
    True -> Some(value)
    False -> None
  }
}

/// Converts the trie to a list of keys and values.
/// Runs in O(n) time where 'n' is the total number of nodes.
/// 
/// Will not print the starting node as it should be empty in a trie.
/// 
/// ## Examples
/// 
/// ```gleam
/// new() |> insert(string.to_graphemes("abc"), 0)
/// // -> [#(["a", "b", "c"], 0)]
/// ```
/// 
pub fn to_list(trie: Trie(k, v)) -> List(#(List(k), v)) {
  fold(trie, [], fn(acc, key, value) { [#(key, value), ..acc] })
}

/// Creates a trie from key value pairs in a list.
/// Runs in O(i m) time where 'i' is the number of list items
/// and 'm' is the average key length.
/// 
/// Overwrites any value that appears twice.
/// 
pub fn from_list(list: List(#(List(k), v))) -> Trie(k, v) {
  use acc, #(key, value) <- list.fold(list, new())
  acc |> insert(key, value)
}

/// Gets a list of all keys in a given trie.
///
/// ## Examples
///
/// ```gleam
/// from_list([#(["a"], 0), #(["a", "b"], 1)]) |> keys
/// // -> [["a"], ["a", "b"]]
/// ```
///
pub fn keys(trie: Trie(k, v)) -> List(List(k)) {
  fold(trie, [], fn(acc, key, _value) { [key, ..acc] })
}

/// Gets a list of all values in a given trie.
///
/// ## Examples
///
/// ```gleam
/// from_list([#(["a"], 0), #(["a", "b"], 1)]) |> values
/// // -> [0, 1]
/// ```
///
pub fn values(trie: Trie(k, v)) -> List(v) {
  fold(trie, [], fn(acc, _key, value) { [value, ..acc] })
}

/// Returns the sub trie at the end of the given prefix, if it exists.
/// Runs in O(m) time, where 'm' is the length of the prefix.
/// 
/// ## Examples
/// 
/// ```gleam
/// new()
/// |> insert(["a", "b", "c"], 1)
/// |> insert(["a", "b", "d"], 2)
/// |> at_prefix(["a", "b"])
/// |> result.map(to_list)
/// // -> Ok([#(["c"], 1), #(["d"], 2)])
/// ```
/// 
/// ```gleam
/// new() |> insert(["a", "b"], 0) |> at_prefix(["b"])
/// // -> Error(Nil)
/// ```
/// 
pub fn at_prefix(trie: Trie(k, v), prefix: List(k)) -> Result(Trie(k, v), Nil) {
  case prefix {
    [] -> Ok(trie)
    [first, ..rest] ->
      dict.get(trie.children, first) |> result.try(at_prefix(_, rest))
  }
}
