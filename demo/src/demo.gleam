import gleam/int
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
import rsvp

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    trie: Trie(String, Nil),
    text: String,
    deviation: Int,
    output: String,
    show_filters: Bool,
    required: String,
    excluded: String,
  )
}

fn get_dictionary() -> Effect(Msg) {
  let url = "./dictionary.txt"
  rsvp.get(url, rsvp.expect_text(ApiReturnedDictionary))
}

fn init(_args) -> #(Model, Effect(Msg)) {
  #(Model(loom.new(), "", 0, "", False, "", ""), get_dictionary())
}

type Msg {
  ApiReturnedDictionary(Result(String, rsvp.Error))
  UpdateName(String)
  IncrementDeviation
  DecrementDeviation
  ToggleFilters(Bool)
  UpdateRequiredLetters(String)
  UpdateExcludedLetters(String)
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
    ToggleFilters(is_active) -> {
      let model =
        Model(..model, show_filters: is_active, required: "", excluded: "")
      #(model, effect.none())
    }
    UpdateRequiredLetters(letters) -> {
      let model = Model(..model, required: letters) |> update_output
      #(model, effect.none())
    }
    UpdateExcludedLetters(letters) -> {
      let model = Model(..model, excluded: letters) |> update_output
      #(model, effect.none())
    }
  }
}

fn update_output(model: Model) -> Model {
  let search_text = string.uppercase(model.text)
  let has_wildcard =
    search_text
    |> string.to_graphemes
    |> list.any(fn(c) { c == "." || c == "*" })

  let output =
    case has_wildcard {
      True ->
        loom_string.find_pattern_where(model.trie, search_text, fn(letters, _) {
          let word = string.concat(letters) |> string.uppercase

          let has_excluded =
            string.to_graphemes(model.excluded)
            |> list.any(fn(l) { string.contains(word, string.uppercase(l)) })

          let has_all_required =
            string.to_graphemes(model.required)
            |> list.all(fn(l) { string.contains(word, string.uppercase(l)) })

          !has_excluded && has_all_required
        })
      False ->
        loom_string.fuzzy_search(model.trie, search_text, model.deviation)
    }
    |> list.map(fn(pair) { pair.0 })
    |> string.join("\n")

  Model(..model, output: output)
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.style("position", "absolute"),
      attribute.style("top", "0"),
      attribute.style("left", "10%"),
      attribute.style("width", "80%"),
      attribute.style("height", "80%"),
      attribute.style("display", "flex"),
      attribute.style("flex-direction", "column"),
      attribute.style("align-items", "center"),
      attribute.style("background-color", "#ffffff"),
      attribute.style("padding", "20px"),
      attribute.style("box-sizing", "border-box"),
      attribute.style("font-family", "sans-serif"),
      attribute.style("transform", "scale(1.25)"),
      attribute.style("transform-origin", "top center"),
      attribute.style("-webkit-font-smoothing", "antialiased"),
      attribute.style("overflow", "hidden"),
    ],
    [
      // Minimal Header - Compact
      html.header(
        [
          attribute.style("text-align", "center"),
          attribute.style("margin-bottom", "15px"),
        ],
        [
          html.h1(
            [
              attribute.style("font-size", "24px"),
              attribute.style("font-weight", "600"),
              attribute.style("margin", "0"),
            ],
            [html.text("Loom Dictionary")],
          ),
        ],
      ),

      // Main Content Card
      html.div(
        [
          attribute.style("width", "100%"),
          attribute.style("max-width", "400px"),
          attribute.style("display", "flex"),
          attribute.style("flex-direction", "column"),
          attribute.style("gap", "12px"),
          attribute.style("flex", "1"),
          attribute.style("min-height", "0"),
        ],
        list.flatten([
          [
            // Integrated Settings Bar
            html.div(
              [
                attribute.style("display", "flex"),
                attribute.style("justify-content", "space-between"),
                attribute.style("padding", "10px 18px"),
                attribute.style("background", "#F5F5F7"),
                attribute.style("border-radius", "25px"),
                attribute.style("box-sizing", "border-box"),
                attribute.style("box-shadow", "0 2px 5px rgba(0,0,0,0.05)"),
              ],
              [
                html.div(
                  [
                    attribute.style("display", "flex"),
                    attribute.style("align-items", "center"),
                  ],
                  [
                    html.button(
                      [event.on_click(DecrementDeviation), icon_btn_style()],
                      [html.text("-")],
                    ),
                    html.span(
                      [
                        attribute.style("font-size", "15px"),
                        attribute.style("font-weight", "500"),
                      ],
                      [
                        html.text(
                          "Distance: " <> int.to_string(model.deviation),
                        ),
                      ],
                    ),
                    html.button(
                      [event.on_click(IncrementDeviation), icon_btn_style()],
                      [html.text("+")],
                    ),
                  ],
                ),
                html.label(
                  [
                    attribute.style("display", "flex"),
                    attribute.style("align-items", "center"),
                    attribute.style("gap", "6px"),
                    attribute.style("padding-right", "8px"),
                    attribute.style("cursor", "pointer"),
                    attribute.style("font-size", "15px"),
                  ],
                  [
                    html.input([
                      attribute.type_("checkbox"),
                      attribute.style("accent-color", "black"),
                      event.on_check(ToggleFilters),
                    ]),
                    html.text("Wordle"),
                  ],
                ),
              ],
            ),

            // Main Input
            html.input([
              attribute.placeholder("Search patterns..."),
              attribute.value(model.text),
              event.on_input(UpdateName),
              attribute.style("padding", "16px 18px"),
              attribute.style("background-color", "#F5F5F7"),
              attribute.style("border", "none"),
              attribute.style("border-radius", "25px"),
              attribute.style("font-size", "16px"),
              attribute.style("outline", "none"),
              attribute.style("width", "100%"),
              attribute.style("box-sizing", "border-box"),
              attribute.style("box-shadow", "0 2px 5px rgba(0,0,0,0.05)"),
            ]),
          ],

          wordle_inputs(model),

          [
            // Scrollable Results Area
            html.div(
              [
                attribute.style("flex", "1"),
                attribute.style("display", "flex"),
                attribute.style("flex-direction", "column"),
                attribute.style("min-height", "0"),
                attribute.style("border-radius", "25px"),
                attribute.style("box-sizing", "border-box"),
                attribute.style("box-shadow", "0 2px 5px rgba(0,0,0,0.05)"),
              ],
              [
                html.pre(
                  [
                    attribute.style("background", "#F5F5F7"),
                    attribute.style("padding", "16px"),
                    attribute.style("border-radius", "25px"),
                    attribute.style("flex", "1"),
                    attribute.style("overflow-y", "auto"),
                    attribute.style("margin", "0"),
                    attribute.style(
                      "font-family",
                      "ui-monospace, SFMono-Regular, monospace",
                    ),
                    attribute.style("font-size", "14px"),
                    attribute.style("line-height", "1.4"),
                    attribute.style("color", "#1D1D1F"),
                  ],
                  [html.text(model.output)],
                ),
              ],
            ),
          ],
        ]),
      ),

      // Minimalist Footer - stays at bottom
      html.footer([attribute.style("padding-top", "12px")], [
        html.p(
          [
            attribute.style("font-size", "11px"),
            attribute.style("color", "#86868B"),
            attribute.style("text-align", "center"),
            attribute.style("margin", "0"),
          ],
          [html.text("Filters target patterns. Distance affects fuzzy search.")],
        ),
      ]),
    ],
  )
}

fn wordle_inputs(model: Model) -> List(Element(Msg)) {
  case model.show_filters {
    False -> []
    True -> [
      html.div(
        [attribute.style("display", "flex"), attribute.style("gap", "12px")],
        [
          html.input([
            attribute.placeholder("Required"),
            attribute.value(model.required),
            event.on_input(UpdateRequiredLetters),
            attribute.style("padding", "16px 18px"),
            attribute.style("background-color", "#F5F5F7"),
            attribute.style("border", "none"),
            attribute.style("border-radius", "25px"),
            attribute.style("font-size", "16px"),
            // 16px prevents iOS zoom on focus
            attribute.style("outline", "none"),
            attribute.style("width", "100%"),
            attribute.style("box-sizing", "border-box"),
            attribute.style("flex", "1"),
          ]),
          html.input([
            attribute.placeholder("Excluded"),
            attribute.value(model.excluded),
            event.on_input(UpdateExcludedLetters),
            attribute.style("padding", "16px 18px"),
            attribute.style("background-color", "#F5F5F7"),
            attribute.style("border", "none"),
            attribute.style("border-radius", "25px"),
            attribute.style("font-size", "16px"),
            // 16px prevents iOS zoom on focus
            attribute.style("outline", "none"),
            attribute.style("width", "100%"),
            attribute.style("box-sizing", "border-box"),
            attribute.style("flex", "1"),
          ]),
        ],
      ),
    ]
  }
}

fn icon_btn_style() -> attribute.Attribute(Msg) {
  attribute.styles([
    #("width", "28px"),
    #("height", "28px"),
    #("border", "none"),
    #("background", "transparent"),
    #("color", "black"),
    #("font-size", "20px"),
    #("font-weight", "400"),
    #("cursor", "pointer"),
    #("display", "flex"),
    #("align-items", "center"),
    #("justify-content", "center"),
  ])
}
