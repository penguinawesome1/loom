import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/list
import gleam/string
import loom.{type Trie}
import loom_string
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(text: String, output: String, trie: Trie(String, Nil))
}

fn get_dictionary() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Instead of request.to, let's build it manually 
    // to ensure there's no Result to 'assert' on.
    let req =
      request.new()
      |> request.set_host("")
      |> request.set_path("dictionary.txt")

    fetch.send(req)
    |> promise.await(fn(res) {
      case res {
        Ok(resp) -> fetch.read_text_body(resp)
        Error(e) -> promise.resolve(Error(e))
      }
    })
    |> promise.map(fn(res) {
      case res {
        // We handle BOTH success and failure cases here
        Ok(resp) -> dispatch(ApiReturnedDictionary(Ok(resp.body)))
        Error(_) -> dispatch(ApiReturnedDictionary(Error(Nil)))
      }
    })
    Nil
  })
}

fn init(_args) -> #(Model, Effect(Msg)) {
  #(Model(text: "", output: "", trie: loom.new()), get_dictionary())
}

type Msg {
  ApiReturnedDictionary(Result(String, Nil))
  UpdateName(String)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedDictionary(Ok(dict)) -> {
      let trie =
        dict
        |> string.trim
        |> string.split("\n")
        |> list.map(fn(w) { #(w, Nil) })
        |> loom_string.from_list

      #(Model(..model, trie: trie), effect.none())
    }
    ApiReturnedDictionary(_) -> #(model, effect.none())
    UpdateName(s) -> {
      let output =
        model.trie
        |> loom_string.fuzzy_search(s, 1)
        |> list.map(fn(pair) { pair.0 })
        |> string.join("\n")

      #(Model(..model, text: s, output: output), effect.none())
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.input([attribute.value(model.text), event.on_input(UpdateName)]),
    html.div([], [html.text(model.output)]),
  ])
}
