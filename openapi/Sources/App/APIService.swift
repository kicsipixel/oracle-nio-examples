import APIService
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime
import OracleNIO

struct APIServiceImpl: APIProtocol {
    let client: OracleClient
    
    func healthCheck(_: APIService.Operations.healthCheck.Input) async throws -> APIService.Operations.healthCheck.Output {
        return .ok(.init())
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
                  name,
                  comments
                FROM
                  openapi_parks
                """
            )
            
            for try await (name, comments) in rows.decode((String, String).self) {
                parks.append(.init(name: name, comments: comments))
            }
        }
        
        return .ok(.init(body: .json(parks)))
    }
}


struct Park: Codable {
    let features: [Feature]

    struct Feature: Codable {
        let geometry: Geometry
        let properties: Properties
    }
}

struct Geometry: Codable {
    let coordinates: [Double]
}

struct Properties: Codable {
    let name: String
}
