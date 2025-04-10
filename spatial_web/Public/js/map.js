function initializeMap(annotationData, defaultLocation) {
    // Replace 'YOUR_JWT_TOKEN' with your actual JWT token, because it expires after 7 days
    mapkit.init({
        authorizationCallback: function (done) {
            done('eyJraWQiOiJYSlYzVzZTNEczIiwidHlwIjoiSldUIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiIzNThXSFFGOTRXIiwiaWF0IjoxNzQzNDExMjE2LCJleHAiOjE3NDQwOTU1OTl9.G9QmlDdZDCybta9xiHLAPhe0xzZgUyXJekeC6HgOAEbGoiJUrDfzp4YekjMmEIjpO4aMV0eyeYZc1GemKJ88VA');
        }
    });

    // Start in Satellite mode for better visibility
    var map = new mapkit.Map("map", {
        mapType: mapkit.Map.MapTypes.Satellite
    });

    // Set the initial region of the map
    map.region = new mapkit.CoordinateRegion(
        new mapkit.Coordinate(50.08639, 14.41194),
        new mapkit.CoordinateSpan(0.1, 0.1)
    );

    // Create parks
    annotationData.forEach(function (data) {
        var parkAnnotation = new mapkit.MarkerAnnotation(
            new mapkit.Coordinate(data.latitude, data.longitude), {
                title: data.name,
                color: "#2FCB48",
                glyphImage: {
                    1: "/images/park.svg"
                }
            }
        );

        // Add the annotation to the map
        map.addAnnotation(parkAnnotation);
    });

    // Create "You are here"
    var annotation = new mapkit.MarkerAnnotation(
        new mapkit.Coordinate(defaultLocation.latitude, defaultLocation.longitude), {
            title: "You are here",
            subtitle: "You are standing the oldest bridge in Central Europe.",
            color: "#FF392E",
        }
    );

    map.addAnnotation(annotation);
}
