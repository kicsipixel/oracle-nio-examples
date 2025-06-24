import Foundation
import Hummingbird
import Logging
import OracleNIO
import SotoS3

struct ParksController<Context: RequestContext> {
  let client: OracleClient
  let logger: Logger
  let s3: S3
  let bucket: String
  let folder: String

  func addRoutes(to group: RouterGroup<Context>) {
    group
      .post(use: create)
      .get(use: index)
      .get(":id", use: show)
      .patch(":id", use: update)
      .delete(":id", use: delete)
      .post(":id/upload", use: upload)
      .get(":id/download", use: download)
  }

  // MARK: - create
  /// Creates a new park with `coordinates` and `details`
  @Sendable
  func create(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let park = try await request.decode(as: Park.self, context: context)

    let detailsJSON = OracleJSON(park.details)

    let query: OracleStatement = try "INSERT INTO parks (coordinates, details) VALUES (SDO_GEOMETRY(\(park.coordinates.latitude), \(park.coordinates.longitude)), \(detailsJSON))"

    _ = try await client.withConnection { conn in
      try await conn.execute(query, logger: logger)
    }

    return .created
  }

  // MARK: - index
  /// Returns with all parks in the database
  @Sendable
  func index(_ request: Request, context: Context) async throws -> [Park] {
    var parks = [Park]()

    try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details,
           p.image_link
        FROM
          parks p
        """
      )

      for try await (id, latitude, longitude, details, image_link) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>, String?).self) {
        parks.append(
          .init(id: id, coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude), details: Park.Details.init(name: details.value.name), imageLink: image_link)
        )
      }
    }
    return parks
  }

  // MARK: - show
  /// Returns a single park with id
  @Sendable
  func show(_ request: Request, context: Context) async throws -> Park? {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details,
           p.image_link
        FROM
          parks p
        WHERE id = HEXTORAW(\(guid))
        """
      )

      for try await (id, latitude, longitude, details, image_link) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>, String?).self) {
        return Park(id: id, coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude), details: Park.Details.init(name: details.value.name), imageLink: image_link)
      }

      return nil
    }
  }

  // MARK: - update
  /// Updates a single park with id
  @Sendable
  func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")
    let park = try await request.decode(as: Park.self, context: context)
    let detailsJSON = OracleJSON(park.details)

    let query: OracleStatement = try """
    UPDATE parks
    SET coordinates = SDO_GEOMETRY(\(park.coordinates.latitude), \(park.coordinates.longitude)),
        details = \(detailsJSON)
    WHERE id = HEXTORAW(\(guid))
    """

    return try await client.withConnection { conn in
      let stream = try await conn.execute(query, logger: logger)
      let updatedRows = try await stream.affectedRows
      if updatedRows == 0 {
        return .notFound
      }

      return .ok
    }
  }

  // MARK: - delete
  /// Deletes park with id
  @Sendable
  func delete(_: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        DELETE FROM parks
        WHERE id = HEXTORAW(\(guid))
        """,
        logger: logger
      )
      let deletedRows = try await stream.affectedRows
      if deletedRows == 0 {
        return .notFound
      }
      return .noContent
    }
  }

  // MARK: - file upload
  ///
  ///  curl -i -X POST "http://localhost:8080/api/v1/parks/38439882CFDE1BFFE0630261A8C0B9F0/upload" \
  ///  -H "Content-Type: image/png" \
  ///  -H "File-Name: letna.png" \
  ///  --data-binary "@./letna.png"
  ///
  @Sendable
  func upload(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    // Check if the header exists
    guard let contentLength: Int = (request.headers[.contentLength].map { Int($0) } ?? nil)
    else {
      throw HTTPError(.badRequest)
    }

    // Get the `id` from the `context`
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    let filename = try fileName(for: request)

    context.logger.info(.init(stringLiteral: "Uploading: \(filename), size: \(contentLength)"))

    // Construct an object to upload
    let putObjectRequest = S3.PutObjectRequest(
      body: .init(asyncSequence: request.body, length: contentLength),
      bucket: self.bucket,
      contentType: request.headers[.contentType],
      key: "\(self.folder)/\(guid)/\(filename)"
    )

    do {
      _ = try await self.s3.putObject(putObjectRequest, logger: context.logger)

      let imageLink = "\(self.folder)/\(guid)/\(filename)"

      let query: OracleStatement = """
        UPDATE parks
        SET image_link = \(imageLink)
        WHERE id = HEXTORAW(\(guid))
        """

      return try await client.withConnection { conn in
        let stream = try await conn.execute(query, logger: logger)
        let updatedRows = try await stream.affectedRows
        if updatedRows == 1 {
          return .ok
        }
        return .notModified
      }
    }
    catch {
      throw HTTPError(.internalServerError, message: "\(error.localizedDescription)")
    }
  }

  // MARK: - file download
  ///
  ///  curl -o letna.png "http://localhost:8080/api/v1/parks/38439882CFDE1BFFE0630261A8C0B9F0/download"
  ///
  @Sendable
  func download(request: Request, context: some RequestContext) async throws -> Response {
    var key: String?
    // Get the `id` from the `context`
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    // Get the enrty
    let _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
           p.image_link
        FROM
          parks p
        WHERE id = HEXTORAW(\(guid))
        """
      )

      for try await (image_link) in stream.decode((String?).self) {
        key = image_link
      }
    }
    guard let key = key else {
      return Response(status: .badRequest)
    }

    let s3Response = try await self.s3.getObject(
      .init(bucket: self.bucket, key: key),
      logger: context.logger
    )

    var headers = HTTPFields()
    if let contentLength = s3Response.contentLength {
      headers[.contentLength] = contentLength.description
    }
    if let contentType = s3Response.contentType {
      headers[.contentType] = contentType
    }

    return Response(
      status: .ok,
      headers: headers,
      body: .init(asyncSequence: s3Response.body)
    )
  }
}
