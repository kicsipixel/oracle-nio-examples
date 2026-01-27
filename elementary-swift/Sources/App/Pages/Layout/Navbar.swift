import Elementary

struct Navbar: HTML {
  var body: some HTML {
    nav(.class("bg-lime-100 px-4 py-2 flex flex-wrap items-center md:flex-nowrap")) {
      // Brand
      a(.href("/"), .class("flex items-center")) {
        img(
          .src("/images/PoP_logo.png"),
          .class("w-[120px] h-auto"),
          .alt("logo")
        )
      }

      // Nav links
      div(.id("navMenu"), .class("hidden w-full md:flex md:w-auto md:items-center")) {
        ul(.class("flex flex-col md:flex-row md:space-x-4 mt-2 md:mt-0")) {
          li {
            a(.href("/"), .class("block py-2 px-3 text-green-700 hover:text-green-900")) {
              "Home"
            }
          }
          li {
            a(.href("/parks/create"), .class("block py-2 px-3 text-green-700 hover:text-green-900")) {
              "+ Add"
            }
          }
        }
      }
    }
  }
}
