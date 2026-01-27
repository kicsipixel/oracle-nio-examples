import Elementary

struct ShowPage: HTML {
  let park: Park
  var body: some HTML {
    div {
      h1(.class("pb-2 text-3xl")) { park.details.name }
      p {
        span(.class("font-bold")) { "Latitude: " }
        "\(park.coordinates.latitude), "
        span(.class("font-bold")) { "Longitude: " }
        "\(park.coordinates.longitude)"
      }
      div(.class("mt-5 flex gap-4")) {
        a(.href("/parks/\(park.id)/edit"), .class("bg-lime-100 text-green-500 py-2 px-5 rounded hover:bg-lime-200 cursor-pointer")) { "Edit" }
        a(.href("/parks/\(park.id)/delete"), .class("bg-rose-100 text-red-500 py-2 px-5 rounded hover:bg-rose-200 cursor-pointer"), .on(.click, "return confirm('Delete this park?')")) { "Delete" }
      }
    }
  }
}
