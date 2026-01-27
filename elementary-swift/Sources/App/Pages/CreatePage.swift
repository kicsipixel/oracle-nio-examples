import Elementary

struct CreatePage: HTML {
  var isEditing: Bool = false
  var park: Park? = nil

  var body: some HTML {
    h1(.class("text-3xl mb-4")) { isEditing ? "Edit park" : "Add a new park" }
    form(.action(isEditing ? "/parks/\(park.map { $0.id.uuidString } ?? "")/edit" : "/parks/create"), .method(.post)) {
      div(.class("mb-4")) {
        label(.for("name"), .class("block text-sm font-medium mb-1")) { "Park name" }
        input(
          .type(.text),
          .name("name"),
          .id("name"),
          .value(park?.details.name ?? ""),
          .class("w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-lime-200"),
          .autofocus
        )
      }
      div(.class("grid grid-cols-2 gap-4 mb-4")) {
        div {
          label(.for("latitude"), .class("block text-sm font-medium mb-1")) { "Latitude" }
          input(
            .type(.text),
            .name("latitude"),
            .id("latitude"),
            .value("\(park?.coordinates.latitude ?? 0.0)"),
            .class("w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-lime-200")
          )
        }
        div {
          label(.for("longitude"), .class("block text-sm font-medium mb-1")) { "Longitude" }
          input(
            .type(.text),
            .name("longitude"),
            .id("longitude"),
            .value("\(park?.coordinates.longitude ?? 0.0)"),
            .class("w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-lime-200")
          )
        }
      }
      input(.type(.submit), .value("Submit"), .class("bg-lime-100 text-green-500 px-4 py-2 rounded hover:bg-lime-200 cursor-pointer"))
    }
  }
}
