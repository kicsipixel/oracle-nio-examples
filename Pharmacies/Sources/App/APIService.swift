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

  // MARK: - create
  /// Create a new pharmacy
  func createPharmacy(_ input: APIService.Operations.createPharmacy.Input) async throws -> APIService.Operations.createPharmacy.Output {
    guard case let .json(data) = input.body,
      let pharmacyName = data.name,
      let pharamcyAddress = data.address,
      let pharmacyEmail = data.email,
      let pharmacyPhone = data.phone,
      let pharmacyWeb = data.web,
      let pharmacyOpeningHours = data.openinghours
    else {
      return .badRequest(.init())
    }

    guard let pharmacyCoordinates = data.coordinates,
      let pharmacyLatitude = pharmacyCoordinates.latitude,
      let pharmacyLongitude = pharmacyCoordinates.longitude
    else {
      return .badRequest(.init())
    }

    // Handle opening hours
    var openingHours = [OpeningHour]()

    for hour in pharmacyOpeningHours {
      if let daysOfWeek = hour.day_of_week, let opens = hour.opens, let closes = hour.closes {
        let openingHour = OpeningHour(
          dayOfWeek: daysOfWeek,
          opens: opens,
          closes: closes
        )
        openingHours.append(openingHour)
      }
    }

    // Handle address
    guard let pharmacyCity = pharamcyAddress.city,
      let pharmacyStreet = pharamcyAddress.street,
      let pharmacyZip = pharamcyAddress.zip
    else {
      return .badRequest(.init())
    }

    // Create a details constant
    let details = OracleJSON(
      Details(
        name: pharmacyName,
        address: Address(
          city: pharmacyCity,
          street: pharmacyStreet,
          zip: pharmacyZip
        ),
        email: pharmacyEmail,
        phone: pharmacyPhone,
        web: pharmacyWeb,
        openingHours: openingHours
      )
    )

    let isOpenSat = pharmacyOpeningHours.contains(where: { $0.day_of_week == "Saturday" })
    let isOpenSun = pharmacyOpeningHours.contains(where: { $0.day_of_week == "Sunday" })
    let isOpenPublicHoliday = pharmacyOpeningHours.contains(where: { $0.day_of_week == "PublicHoliday" })

    // PL/SQL statement to insert a new pharmacy
    let query: OracleStatement = try """
    INSERT INTO pharmacies (pharmacy_coordinates, details, is_open_sat, is_open_sun, is_open_public_holiday)
        VALUES (
            SDO_GEOMETRY(\(pharmacyLatitude), \(pharmacyLongitude)),
            \(details),
            \(isOpenSat),
            \(isOpenSun),
            \(isOpenPublicHoliday)
        )
    """

    _ = try await client.withConnection { conn in
      try await conn.execute(query)
    }

    return .created(.init())
  }

  // MARK: - list
  /// List all pharmacies in the database
  func listPharmacies(_ input: APIService.Operations.listPharmacies.Input) async throws -> APIService.Operations.listPharmacies.Output {
    var query: OracleStatement?
    var pharmacies = [Components.Schemas.Pharmacy]()

    // As the list and query use the same path, we need to differentiate betweeen the two
    // Check if we need to filter distance
    if let latlong = input.query.latlong, let distance = input.query.distance, let unit = input.query.unit {
      // Separate query input into latitude and longitude
      let coordinates = latlong.components(separatedBy: ",")
      guard coordinates.count == 2,
        let latitude = Double(coordinates[0]),
        let longitude = Double(coordinates[1])
      else {
        return .badRequest(.init())
      }

      let distanceUnitString = "distance=\(distance) unit=\(unit)"

      query = """
        SELECT
          p.id,
          p.pharmacy_coordinates.SDO_POINT.X AS latitude,
          p.pharmacy_coordinates.SDO_POINT.Y AS longitude,
          p.details
        FROM
          pharmacies p
        WHERE
         SDO_WITHIN_DISTANCE(pharmacy_coordinates, SDO_GEOMETRY(\(latitude), \(longitude)), \(distanceUnitString)) = 'TRUE'
        """
    }
    else {
      query =
        """
          SELECT
              p.id,
              p.pharmacy_coordinates.SDO_POINT.X AS latitude,
              p.pharmacy_coordinates.SDO_POINT.Y AS longitude,
              p.details
          FROM
              pharmacies p
        """
    }

    guard let query = query else {
      return .internalServerError(.init())
    }

    try await self.client.withConnection { conn in
      let stream = try await conn.execute(query)

      for try await (id, latitude, longitude, details) in stream.decode((UUID, Double, Double, OracleJSON<Details>).self) {
        var openingHoursArray = [Components.Schemas.OpeningHour]()

        for item in details.value.openingHours {
          let openingHoursOfTheDay = Components.Schemas.OpeningHour(
            day_of_week: item.dayOfWeek,
            opens: item.opens,
            closes: item.closes
          )
          openingHoursArray.append(openingHoursOfTheDay)
        }

        pharmacies.append(
          .init(
            id: "\(id)",
            name: details.value.name,
            coordinates: .init(latitude: latitude, longitude: longitude),
            address: .init(
              city: details.value.address.city,
              street: details.value.address.street,
              zip: details.value.address.zip
            ),
            web: details.value.web,
            email: details.value.email,
            phone: details.value.phone,
            openinghours: openingHoursArray
          )
        )
      }
    }

    return .ok(.init(body: .json(pharmacies)))
  }

  // MARK: - get
  /// Get a pharmacy by ID
  func getPharmacyById(_ input: APIService.Operations.getPharmacyById.Input) async throws -> APIService.Operations.getPharmacyById.Output {
    // As Oracle DB has different idea about UUID, you need to work on it a bit
    let guid = input.path.id.replacingOccurrences(of: "-", with: "")

    let query: OracleStatement =
      """
        SELECT
            p.id,
            p.pharmacy_coordinates.SDO_POINT.X AS latitude,
            p.pharmacy_coordinates.SDO_POINT.Y AS longitude,
            p.details
        FROM
            pharmacies p
        WHERE
            id = HEXTORAW(\(guid))
      """

    return try await self.client.withConnection { conn in
      let stream = try await conn.execute(query)

      for try await (id, latitude, longitude, details) in stream.decode((UUID, Double, Double, OracleJSON<Details>).self) {
        var openingHoursArray = [Components.Schemas.OpeningHour]()

        for item in details.value.openingHours {
          let openingHoursOfTheDay = Components.Schemas.OpeningHour(
            day_of_week: item.dayOfWeek,
            opens: item.opens,
            closes: item.closes
          )
          openingHoursArray.append(openingHoursOfTheDay)
        }

        let pharmacy = Components.Schemas.Pharmacy(
          id: "\(id)",
          name: details.value.name,
          coordinates: .init(latitude: latitude, longitude: longitude),
          address: .init(
            city: details.value.address.city,
            street: details.value.address.street,
            zip: details.value.address.zip
          ),
          web: details.value.web,
          email: details.value.email,
          phone: details.value.phone,
          openinghours: openingHoursArray
        )

        return .ok(.init(body: .json(pharmacy)))
      }
      return .notFound(.init())
    }
  }

  // MARK: - update
  /// Update a pharmacy by ID
  func updatePharmacyById(_ input: APIService.Operations.updatePharmacyById.Input) async throws -> APIService.Operations.updatePharmacyById.Output {
    let guid = input.path.id.replacingOccurrences(of: "-", with: "")

    guard case let .json(data) = input.body,
      let pharmacyName = data.name,
      let pharamcyAddress = data.address,
      let pharmacyEmail = data.email,
      let pharmacyPhone = data.phone,
      let pharmacyWeb = data.web,
      let pharmacyOpeningHours = data.openinghours
    else {
      return .badRequest(.init())
    }

    guard let pharmacyCoordinates = data.coordinates,
      let pharmacyLatitude = pharmacyCoordinates.latitude,
      let pharmacyLongitude = pharmacyCoordinates.longitude
    else {
      return .badRequest(.init())
    }

    // Handle opening hours
    var openingHours = [OpeningHour]()

    for hour in pharmacyOpeningHours {
      if let daysOfWeek = hour.day_of_week, let opens = hour.opens, let closes = hour.closes {
        let openingHour = OpeningHour(
          dayOfWeek: daysOfWeek,
          opens: opens,
          closes: closes
        )
        openingHours.append(openingHour)
      }
    }

    // Handle address
    guard let pharmacyCity = pharamcyAddress.city,
      let pharmacyStreet = pharamcyAddress.street,
      let pharmacyZip = pharamcyAddress.zip
    else {
      return .badRequest(.init())
    }

    // Create a details constant
    let details = OracleJSON(
      Details(
        name: pharmacyName,
        address: Address(
          city: pharmacyCity,
          street: pharmacyStreet,
          zip: pharmacyZip
        ),
        email: pharmacyEmail,
        phone: pharmacyPhone,
        web: pharmacyWeb,
        openingHours: openingHours
      )
    )

    let isOpenSat = pharmacyOpeningHours.contains(where: { $0.day_of_week == "Saturday" })
    let isOpenSun = pharmacyOpeningHours.contains(where: { $0.day_of_week == "Sunday" })
    let isOpenPublicHoliday = pharmacyOpeningHours.contains(where: { $0.day_of_week == "PublicHoliday" })

    let query: OracleStatement = try """
    UPDATE pharmacies
    SET pharmacy_coordinates = SDO_GEOMETRY(\(pharmacyLatitude), \(pharmacyLongitude)),
    details = \(details),
    is_open_sat = \(isOpenSat),
    is_open_sun = \(isOpenSun),
    is_open_public_holiday = \(isOpenPublicHoliday)
    WHERE id = HEXTORAW(\(guid))
    """

    return try await client.withConnection { conn in
      let stream = try await conn.execute(query)
      let insertedRows = try await stream.affectedRows
      if insertedRows == 0 {
        return .notFound(.init())
      }

      let pharmacy = Components.Schemas.Pharmacy(
        name: pharmacyName,
        coordinates: .init(
          latitude: pharmacyLatitude,
          longitude: pharmacyLongitude
        ),
        address: .init(
          city: pharmacyCity,
          street: pharmacyStreet,
          zip: pharmacyZip
        ),
        web: pharmacyWeb,
        email: pharmacyEmail,
        phone: pharmacyPhone,
        openinghours: pharmacyOpeningHours,
        isopensat: pharmacyOpeningHours.contains(where: {
          $0.day_of_week == "Saturday"
        }),
        isopensun: pharmacyOpeningHours.contains(where: {
          $0.day_of_week == "Sunday"
        }),
        isopenpublicholiday: pharmacyOpeningHours.contains(where: {
          $0.day_of_week == "PublicHoliday"
        })
      )

      return .ok(.init(body: .json(pharmacy)))
    }
  }

  // MARK: - delete
  /// Delete a pharmacy by ID
  func deletePharmacyById(_ input: APIService.Operations.deletePharmacyById.Input) async throws -> APIService.Operations.deletePharmacyById.Output {
    let guid = input.path.id.replacingOccurrences(of: "-", with: "")

    let query: OracleStatement = """
      DELETE FROM pharmacies
      WHERE id = HEXTORAW(\(guid))
      """

    return try await client.withConnection { conn in
      let stream = try await conn.execute(query)
      let deletedRows = try await stream.affectedRows
      if deletedRows == 0 {
        return .notFound(.init())
      }

      return .noContent(.init())
    }
  }
}
