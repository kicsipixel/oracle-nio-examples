import APIService
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime
import OracleNIO

struct APIServiceImpl: APIProtocol {
  let client: OracleClient
  
  func healthCheck(_: APIService.Operations.healthCheck.Input) async throws -> APIService.Operations.healthCheck.Output {
    .ok(.init())
  }
  
  func hello(_: APIService.Operations.hello.Input) async throws -> APIService.Operations.hello.Output {
    .ok(.init(body: .plainText("Hello, World! 🌍")))
  }
  
  func listParks(_: APIService.Operations.listParks.Input) async throws -> APIService.Operations.listParks.Output {
    var parks = [Components.Schemas.Park]()
    
    try await self.client.withConnection { conn in
      let rows = try await conn.execute(
                """
                 SELECT
                    p.id,
                    p.name,
                    p.coordinates.SDO_POINT.X AS longitude,
                    p.coordinates.SDO_POINT.Y AS latitude
                FROM
                    openapi_parks p
                """
      )
      
      for try await (id, name, longitude, latitude) in rows.decode((UUID, String, Double, Double).self) {
        parks.append(.init(id: "\(id)", name: name, coordinates: .init(latitude: latitude, longitude: longitude)))
      }
    }
    
    return .ok(.init(body: .json(parks)))
  }
  
  func getParkById(_ input: APIService.Operations.getParkById.Input) async throws -> APIService.Operations.getParkById.Output {
    let guid = input.path.id.replacingOccurrences(of: "-", with: "")
    
    var park = Components.Schemas.Park()
    
    try await client.withConnection { conn in
      let rows = try await conn.execute(
                """
                SELECT
                    p.id,
                    p.name,
                    p.coordinates.SDO_POINT.X AS longitude,
                    p.coordinates.SDO_POINT.Y AS latitude
                FROM
                    openapi_parks p
                WHERE id = HEXTORAW(\(guid))
                """)
      
      for try await (id, name, longitude, latitude) in rows.decode((UUID, String, Double, Double).self) {
        park = Components.Schemas.Park(id: "\(id)", name: name, coordinates: .init(latitude: latitude, longitude: longitude))
      }
    }
    
    return .ok(.init(body: .json(park)))
  }
}
