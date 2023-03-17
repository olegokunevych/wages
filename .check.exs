[
  parallel: false,
  tools: [
    {:credo, "mix credo diff --strict --format oneline", order: 1},
    {:excoveralls, "mix coveralls.html", order: 2},
    {:sobelow, "mix sobelow --config", order: 3},
    {:dialyzer, "mix dialyzer --format short", order: 4}
  ]
]
