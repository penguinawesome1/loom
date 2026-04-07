//// Provides trie wrapper implementation for string keys.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import loom.{type Trie}

/// Checks if a string key exists within the trie.
/// See `loom.has_key` for implementation details.
/// 
pub fn has_key(trie: Trie(String, v), key: String) -> Bool {
  loom.has_key(trie, string.to_graphemes(key))
}

/// Inserts a value at the specified string key, returning a new trie.
/// See `loom.insert` for implementation details.
/// 
pub fn insert(
  into trie: Trie(String, v),
  for key: String,
  insert value: v,
) -> Trie(String, v) {
  loom.insert(trie, string.to_graphemes(key), value)
}

/// Fetches the value associated with a string key.
/// See `loom.get` for implementation details.
/// 
pub fn get(from trie: Trie(String, v), get key: String) -> Result(v, Nil) {
  loom.get(trie, string.to_graphemes(key))
}

/// Updates a string key's value or inserts a new one using a callback.
/// See `loom.upsert` for implementation details.
/// 
pub fn upsert(
  from trie: Trie(String, v),
  update key: String,
  using fun: fn(Option(v)) -> Option(v),
) -> Trie(String, v) {
  loom.upsert(trie, string.to_graphemes(key), fun)
}

/// Removes a string key and any orphaned nodes from the trie.
/// See `loom.delete` for implementation details.
/// 
pub fn delete(from trie: Trie(String, v), delete key: String) -> Trie(String, v) {
  loom.delete(trie, string.to_graphemes(key))
}

/// Transforms all values in the trie using the provided string-aware function.
/// See `loom.map_values` for implementation details.
/// 
pub fn map_values(
  in trie: Trie(String, v),
  with fun: fn(String, v) -> Option(a),
) -> Trie(String, a) {
  loom.map_values(trie, fn(key, value) { fun(string.concat(key), value) })
}

/// Reduces the trie into a single value using a string-aware accumulator.
/// See `loom.fold` for implementation details.
/// 
pub fn fold(
  over trie: Trie(String, v),
  from initial: acc,
  with fun: fn(acc, String, v) -> acc,
) -> acc {
  loom.fold(trie, initial, fn(acc, key, value) {
    fun(acc, string.concat(key), value)
  })
}

/// Returns a new trie containing only entries that satisfy the string predicate.
/// See `loom.filter` for implementation details.
/// 
pub fn filter(
  in trie: Trie(String, v),
  keeping predicate: fn(String, v) -> Bool,
) -> Trie(String, v) {
  loom.filter(trie, fn(key, value) { predicate(string.concat(key), value) })
}

/// Converts the trie into an alphabetically sorted list of string-value pairs.
/// Internally uses `fold` and `list.reverse`.
/// 
pub fn to_list(trie: Trie(String, v)) -> List(#(String, v)) {
  fold(trie, [], fn(acc, key, value) { [#(key, value), ..acc] }) |> list.reverse
}

/// Creates a trie from a list of string keys, all sharing the same value.
/// See `loom.insert` for details on how keys are stored.
/// 
pub fn from_list(list: List(#(String, v))) -> Trie(String, v) {
  use acc, #(key, value) <- list.fold(list, loom.new())
  acc |> insert(key, value)
}

/// Returns an alphabetically sorted list of all string keys in the trie.
/// Internally uses `fold` and `list.reverse`.
/// 
pub fn keys(trie: Trie(String, v)) -> List(String) {
  fold(trie, [], fn(acc, key, _value) { [key, ..acc] }) |> list.reverse
}

/// Returns the sub-trie located at the specified string prefix.
/// See `loom.at_prefix` for implementation details.
/// 
pub fn at_prefix(
  trie: Trie(String, v),
  prefix: String,
) -> Result(Trie(String, v), Nil) {
  loom.at_prefix(trie, string.to_graphemes(prefix))
}

/// Returns a list of all keys that match the given pattern.
/// The pattern uses `.` or `*` as a wildcard to match any character at that position.
/// See `loom.find_pattern` for implementation details.
///
pub fn find_pattern(
  trie: Trie(String, v),
  pattern: String,
) -> List(#(String, v)) {
  find_pattern_where(trie, pattern, fn(_, _) { True })
}

/// Returns a list of all keys and values that match the given pattern and satisfy a predicate.
/// 
/// The pattern uses `.` or `*` as a wildcard to match any single character at that position.
/// 
/// The predicate receives the key as a `List(String)` (graphemes) and the associated value.
/// The key list is provided in REVERSE order. This allows for efficient O(1) checking of the
/// most recently matched character using `list.first`.
/// 
/// See `loom.find_pattern_where` for complexity and implementation details.
///
pub fn find_pattern_where(
  trie: Trie(String, v),
  pattern: String,
  predicate: fn(List(String), v) -> Bool,
) -> List(#(String, v)) {
  let pattern = {
    use c <- list.map(string.to_graphemes(pattern))
    case c {
      "." | "*" -> None
      _ -> Some(c)
    }
  }

  use pair <- list.map(loom.find_pattern_where(trie, pattern, predicate))
  #(string.concat(pair.0), pair.1)
}

/// Performs a fuzzy search with a specified deviation from the pattern.
/// See `loom.fuzzy_search` for implementation details.
///
pub fn fuzzy_search(
  trie: Trie(String, v),
  pattern: String,
  deviation: Int,
) -> List(#(String, v)) {
  loom.fuzzy_search(trie, string.to_graphemes(pattern), deviation)
  |> list.map(fn(pair) { #(string.concat(pair.0), pair.1) })
}
