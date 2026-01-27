import Elementary

struct IndexPage: HTML {
  let parks: [Park]
  var body: some HTML {
    div {
      h1(.class("text-3xl")) { "Parks" }
      table(.class("w-full border-collapse border border-gray-300 mt-4")) {
        thead(.class("bg-lime-100")) {
          tr {
            th(.class("border border-gray-300 px-4 py-2 text-left")) { "Name" }
            th(.class("border border-gray-300 px-4 py-2 text-left")) { "Latitude" }
            th(.class("border border-gray-300 px-4 py-2 text-left")) { "Longitude" }
          }
        }
        tbody {
          for park in parks {
            tr(.class("hover:bg-gray-50")) {
              td(.class("border border-gray-300 px-4 py-2")) { a(.href("parks/\(park.id)"), .class("text-green-700 underline")) { park.details.name } }
              td(.class("border border-gray-300 px-4 py-2")) { "\(park.coordinates.latitude)" }
              td(.class("border border-gray-300 px-4 py-2")) { "\(park.coordinates.longitude)" }
            }
          }
        }
      }
    }
  }
}
