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
      
      for try await (id, name, longitude, latitude) in rows.decode(
        (UUID, String, Double, Double).self) {
        parks.append(
          .init(
            id: "\(id)", name: name, coordinates: .init(latitude: latitude, longitude: longitude)))
      }
    }
    
    return .ok(.init(body: .json(parks)))
  }
  
  func getParkById(_ input: APIService.Operations.getParkById.Input) async throws -> APIService.Operations.getParkById.Output {
    let guid = input.path.id.replacingOccurrences(of: "-", with: "")
    
    return try await client.withConnection { conn in
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
      
      for try await (id, name, longitude, latitude) in rows.decode(
        (UUID, String, Double, Double).self) {
        let park = Components.Schemas.Park(
          id: "\(id)", name: name, coordinates: .init(latitude: latitude, longitude: longitude))
        return .ok(.init(body: .json(park)))
      }
      
      return .notFound(.init())
    }
  }
  
  func createPark(_ input: APIService.Operations.createPark.Input) async throws -> APIService.Operations.createPark.Output {
    guard case .json(let park) = input.body,
          let name = park.name,
          let coordinates = park.coordinates,
          let latitude = coordinates.latitude,
          let longitude = coordinates.longitude
    else {
      return .badRequest(.init())
    }
    
    _ = try await client.withConnection { conn in
      try await conn.execute(
        """
        INSERT INTO openapi_parks (
          name,
          coordinates
        )
        VALUES (
          \(name)
          ,SDO_GEOMETRY(\(latitude), \(longitude))
        )
        """)
    }
    
    return .created(.init())
  }
  
  func updatePark(_ input: APIService.Operations.updatePark.Input) async throws -> APIService.Operations.updatePark.Output {
    let guid = input.path.id.replacingOccurrences(of: "-", with: "")
    
    guard case .json(let park) = input.body,
          let name = park.name,
          let coordinates = park.coordinates,
          let latitude = coordinates.latitude,
          let longitude = coordinates.longitude
    else {
      return .badRequest(.init())
    }
    
    return try await client.withConnection { conn in
      let rows = try await conn.execute(
        """
        SELECT
            p.id
        FROM
            openapi_parks p
        WHERE id = HEXTORAW(\(guid))
        """)
      
      for try await (_) in rows.decode(
        (UUID).self) {
        try await conn.execute(
          """
          UPDATE openapi_parks
           SET name = \(name),
               coordinates = SDO_GEOMETRY(\(latitude), \(longitude))
          WHERE id = HEXTORAW(\(guid))
          """)
        return .ok(.init())
      }
      return .notFound(.init())
    }
  }
  
  func deletePark(_ input: APIService.Operations.deletePark.Input) async throws -> APIService.Operations.deletePark.Output {
    let guid = input.path.id.replacingOccurrences(of: "-", with: "")
    
    return try await client.withConnection { conn in
      try await conn.execute(
                """
                DELETE FROM openapi_parks
                WHERE id = HEXTORAW(\(guid))
                """)
      return .ok(.init())
    }
  }
}
