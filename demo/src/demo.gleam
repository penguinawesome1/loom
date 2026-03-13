import gleam/bool
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/int
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
  Model(trie: Trie(String, Nil), text: String, deviation: Int, output: String)
}

fn get_dictionary() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    request.new()
    |> request.set_scheme(http.Https)
    |> request.set_host("penguinawesome1.github.io")
    |> request.set_path("/loom/dictionary.txt")
    |> fetch.send
    |> promise.await(fn(res) {
      case res {
        Ok(resp) -> fetch.read_text_body(resp)
        Error(e) -> promise.resolve(Error(e))
      }
    })
    |> promise.map(fn(res) {
      case res {
        Ok(resp) -> dispatch(ApiReturnedDictionary(Ok(resp.body)))
        Error(_) -> dispatch(ApiReturnedDictionary(Error(Nil)))
      }
    })

    Nil
  })
}

fn init(_args) -> #(Model, Effect(Msg)) {
  #(Model(loom.new(), "", 0, ""), get_dictionary())
}

type Msg {
  ApiReturnedDictionary(Result(String, Nil))
  UpdateName(String)
  IncrementDeviation
  DecrementDeviation
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    IncrementDeviation -> #(
      Model(..model, deviation: int.clamp(model.deviation + 1, 0, 3))
        |> update_output,
      effect.none(),
    )
    DecrementDeviation -> #(
      Model(..model, deviation: int.clamp(model.deviation - 1, 0, 3))
        |> update_output,
      effect.none(),
    )
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
      let model = Model(..model, text: s) |> update_output
      #(model, effect.none())
    }
  }
}

fn update_output(model: Model) -> Model {
  use <- bool.guard(string.is_empty(model.text), Model(..model, output: ""))

  let output =
    model.trie
    |> loom_string.fuzzy_search(string.uppercase(model.text), model.deviation)
    |> list.map(fn(pair) { pair.0 })
    |> string.join("\n")

  Model(..model, output: output)
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.style("display", "flex"),
      attribute.style("flex-direction", "column"),
      attribute.style("align-items", "center"),
      attribute.style("justify-content", "flex-start"),
      attribute.style("min-height", "90vh"),
      attribute.style("padding-top", "5vh"),
      attribute.style("gap", "20px"),
      attribute.style("font-family", "sans-serif"),
      attribute.style("background-color", "#fafafa"),
    ],
    [
      html.h1(
        [attribute.style("margin", "0"), attribute.style("color", "#333")],
        [html.text("Loom Dictionary")],
      ),
      html.div(
        [
          attribute.style("display", "flex"),
          attribute.style("align-items", "center"),
          attribute.style("gap", "15px"),
          attribute.style("padding", "10px"),
          attribute.style("background", "#fff"),
          attribute.style("border-radius", "8px"),
          attribute.style("box-shadow", "0 2px 5px rgba(0,0,0,0.05)"),
        ],
        [
          html.button([event.on_click(DecrementDeviation), btn_style()], [
            html.text("-"),
          ]),
          html.div(
            [
              attribute.style("font-weight", "bold"),
              attribute.style("min-width", "100px"),
              attribute.style("text-align", "center"),
            ],
            [html.text("Distance: " <> int.to_string(model.deviation))],
          ),
          html.button([event.on_click(IncrementDeviation), btn_style()], [
            html.text("+"),
          ]),
        ],
      ),
      html.input([
        attribute.value(model.text),
        attribute.placeholder("Search for a word..."),
        event.on_input(UpdateName),
        attribute.style("padding", "12px 20px"),
        attribute.style("width", "320px"),
        attribute.style("font-size", "1rem"),
        attribute.style("border", "1px solid #ddd"),
        attribute.style("border-radius", "25px"),
        attribute.style("outline", "none"),
        attribute.style("box-shadow", "inset 0 1px 3px rgba(0,0,0,0.05)"),
      ]),
      html.pre(
        [
          attribute.style("background", "#ffffff"),
          attribute.style("color", "#444"),
          attribute.style("padding", "20px"),
          attribute.style("border-radius", "12px"),
          attribute.style("width", "350px"),
          attribute.style("max-height", "60vh"),
          attribute.style("overflow-y", "auto"),
          attribute.style("overflow-x", "hidden"),
          attribute.style("border", "1px solid #eee"),
          attribute.style("white-space", "pre-wrap"),
          attribute.style("font-family", "monospace"),
          attribute.style("box-shadow", "0 4px 6px rgba(0,0,0,0.05)"),
        ],
        [html.text(model.output)],
      ),
    ],
  )
}

fn btn_style() -> attribute.Attribute(Msg) {
  attribute.attribute(
    "style",
    "width: 30px; height: 30px; border-radius: 50%; border: 1px solid #ccc; background: white; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 1.2rem;",
  )
}
