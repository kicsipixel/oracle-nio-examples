function initializeMap(annotationData) {
    // Replace 'YOUR_JWT_TOKEN' with your actual JWT token, because it expires after 7 days
    mapkit.init({
    authorizationCallback: function(done) {
        done('eyJraWQiOiJMTlpQTlo1NkNCIiwidHlwIjoiSldUIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiIzNThXSFFGOTRXIiwiaWF0IjoxNzI2MDQzODg3LCJleHAiOjE3MjY3MjkxOTl9.e1mVcbG1fYQED6GHqbYcG76M-QcGXTyRITDgE9ubECYpIZ2ouvW0er-S-gJPL_iUeku3W0CBtF2xIU00JBhbNg');
    }
    });
    
    var map = new mapkit.Map("map");
    
    // Set the initial region of the map
    map.region = new mapkit.CoordinateRegion(
                                             new mapkit.Coordinate(50.08639, 14.41194),
                                             new mapkit.CoordinateSpan(0.1, 0.1)
                                             );
    
    // Create an annotation
    var annotation = new mapkit.MarkerAnnotation(
                                                 new mapkit.Coordinate(50.08639, 14.41194),
                                                 {
                                                 title: "You are here",
                                                 subtitle: "You are standing the oldest bridge in Central Europe.",
                                                 color: "#FF392E",
                                                 }
                                                 );
    
    map.addAnnotation(annotation);
    
    annotationData.forEach(function(data) {
        var parkAnnotation = new mapkit.MarkerAnnotation(
                                                         new mapkit.Coordinate(data.latitude, data.longitude),
                                                         {
                                                         title: data.name,
                                                         color: "#2FCB48",
                                                         glyphImage: {
                                                             1: "images/tree-fill.svg"
                                                         }
                                                         }
                                                         );
        
        // Add the annotation to the map
        map.addAnnotation(parkAnnotation);
    });
}
