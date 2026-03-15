# loom

[![Deploy Status](https://github.com/penguinawesome1/loom/actions/workflows/deploy.yml/badge.svg?branch=master)](https://github.com/penguinawesome1/loom/actions/workflows/deploy.yml)

![Strawberry Search](./demo/assets/examples/strawberry_search.png)

A flexible and optimized Trie implementation for the Gleam programming language.

## ✨ Features

+ Generic Core: Full support for custom key and value types, allowing the Trie to store anything from strings to game move sequences.
+ String Wrapper: Includes a dedicated module for easy out-of-the-box use with standard strings.
+ Fuzzy Search: Efficiently find matches with a specified allowed deviation (Levenshtein distance).
+ Pattern Matching: Advanced sequence matching capabilities, including wildcard support.

## Initialization

| Operation      | Dataset       | Min Time      | Iterations/sec |
| :------------- | :------------ | :------------ | :------------- |
| **Build Trie** | 180,000 words | **751.01 ms** | 1.21           |

## Query Latency

| Operation              | Short Word ("cat") | Long Word ("strawberry") |
| :--------------------- | :----------------- | :----------------------- |
| **Lookup (`get`)**     | 0.0006 ms          | 0.0010 ms                |
| **Prefix Search**      | 0.0006 ms          | 0.0010 ms                |
| **Delete**             | 0.0006 ms          | 0.0010 ms                |
| **Fuzzy Search (d=1)** | 0.0645 ms          | 0.0666 ms                |

_Benchmarks performed on the Erlang/BEAM target (OTP 27) on an Intel(R) Core(TM) Ultra 7 155H (3.80 GHz). Note: Tests were conducted in a power-saving state; performance may be higher under full clock speeds._

## Quick Start

```gleam
import loom
import loom_string

pub fn main() {
  let trie = loom.new()
    |> loom_string.insert("bat", 1)
    |> loom_string.insert("cat", 2)

  // Pattern matching with wildcards
  let matches = loom_string.find_pattern(trie, ".at")
  // -> [#("bat", 1), #("cat", 2)]

  // Fuzzy search with distance of 1
  let fuzzy = loom_string.fuzzy_search(trie, "bt", 1)
  // -> [#("bat", 1)]
}
```

## 📦 Installation

Add this to your `gleam.toml`:
```toml
[dependencies]
loom = { git = "https://github.com/penguinawesome1/loom.git", tag = "v0.1.0" }
```
