import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:tracker_mapper/location_report.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Center(
        child: MapsDisplay(),
      ),
    );
  }
}

class MapsDisplay extends StatefulWidget {
  const MapsDisplay({
    Key? key,
  }) : super(key: key);

  @override
  _MapsDisplayState createState() => _MapsDisplayState();
}

class _MapsDisplayState extends State<MapsDisplay> {
  //GoogleMapController? _googleMapController;
  late final MapController mapController;

  final LatLng _twinIngitions = LatLng(45.00076796865061, -93.27039033565887);

  List<Marker> _markers = <Marker>[];
  LatLng _dummyRobotLocation = LatLng(45.000645, -93.26994);

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    initiateRequest();
    // Timer.periodic(Duration(milliseconds: 1000), (timer) {
    //   moveDummy();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          //onPressed: () => mapController.rotate(45),
          onPressed: () => moveDummy(),
        ),
        body: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: LatLng(45.000718, -93.269865),
            zoom: 18.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
              attributionBuilder: (_) {
                return Text("© OpenStreetMap contributors");
              },
            ),
            MarkerLayerOptions(
              markers: _markers,
            ),
          ],
        )
        //  GoogleMap(
        //     myLocationEnabled: false,
        //     zoomControlsEnabled: false,
        //     initialCameraPosition:
        //         CameraPosition(target: _twinIngitions, zoom: 15),
        //     markers: Set<Marker>.of(_markers),
        //     onMapCreated: (controller) => _googleMapController = controller),
        );
  }

  void initiateRequest() async {
    var channel2 = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:8080'),
    );

    channel2.stream.listen((data) {
      if (data is String) {
        var tokens = data.split('#');
        var messageType = tokens[0];
        var message = tokens[1];
        if (messageType == "LASTLOCATIONS") {
          var lastKnownLocations =
              AllLocationsReport.fromJson(jsonDecode(message));
          setState(() {
            _markers = <Marker>[];
            for (var lr in lastKnownLocations.locations.values) {
              var latlng = LatLng(lr.latitude, lr.longitude);
              _addMarkers(latlng, color: Colors.black);
            }
            var bounds = LatLngBounds.fromPoints(lastKnownLocations
                .locations.values
                .map((e) => LatLng(e.latitude, e.longitude))
                .toList());
            mapController.centerZoomFitBounds(bounds,
                options:
                    const FitBoundsOptions(padding: EdgeInsets.all(100.0)));
          });
        }
        // var lr = LocationReport.fromJson(jsonDecode(tokens[1]));
        // print(lr);
        // setState(() {
        //   _markers = <Marker>[];
        //   var latlng = LatLng(lr.latitude, lr.longitude);
        //   _addMarkers(latlng, color: Colors.black);
        //   mapController.move(latlng, mapController.zoom);
        // });
      }
    });

    // var channel =
    //     WebSocketChannel.connect(Uri.parse('ws://b863-50-205-214-22.ngrok.io'));

    // channel.sink.add(
    //   jsonEncode(
    //     {"op": "subscribe", "topic": "/gps_pipe"},
    //   ),
    // );

//     channel.stream.listen(
//       (data) {
//         print("Data: $data");
//         String msg = jsonDecode(data)["msg"]["data"] as String;
//         var latDeg = msg.substring(21, 23);
//         var latDegDouble = double.parse(latDeg);
//         var latSecond = msg.substring(23, 32);
//         var latSecondsDouble = double.parse(latSecond);
//         var lat = (latDegDouble + latSecondsDouble / 60) * (1);

//         var longDeg = msg.substring(35, 38);
//         var longDegDouble = double.parse(longDeg);
//         var longSecond = msg.substring(38, 47);
//         var longSecondsDouble = double.parse(longSecond);
//         var long = (longDegDouble + longSecondsDouble / 60) * (-1);

//         var skippyLocation = LatLng(lat, long);
//         print("SkippyLocation: $skippyLocation");

//         _markers.clear();
//         _addMarkers(skippyLocation);
//         _addMarkers(_dummyRobotLocation, color: Colors.red);

// //LatLng(45.000718, -93.269865)
//         print("mapController: ${mapController.center}");
//         //mapController.move(LatLng(45.000718, -93.269865), 15);
//       },
//       onError: (error) => print(error),
//     );
  }

  moveDummy() {
    _dummyRobotLocation = LatLng(
        _dummyRobotLocation.latitude, _dummyRobotLocation.longitude - 0.00001);

    setState(() {
      print("markers.size before: ${_markers.length}");
      //_markers.clear(); // this does not work for some reason
      print("markers.size after clear : ${_markers.length}");
      // //_markers.removeAt(0);
      // print("markers.size after remove : ${_markers.length}");
      _markers = <Marker>[];
      // print("markers.size after reassign: ${_markers.length}");
      _addMarkers(_dummyRobotLocation, color: Colors.red);
    });

    mapController.move(_dummyRobotLocation, mapController.zoom);
  }

  void _addMarkers(LatLng skippyLocation, {Color color = Colors.black}) {
    _markers.add(Marker(
      // markerId: const MarkerId('Sol'),
      // infoWindow: const InfoWindow(title: 'Mission: DTM'),
      // icon:
      // BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      width: 50,
      height: 50,
      point: skippyLocation,
      builder: (ctx) => Container(
        child: Icon(
          Icons.accessibility_new_rounded,
          color: color,
          size: 50,
        ),
      ),
    ));
  }

  @override
  void dispose() {
    //_googleMapController!.dispose();
    super.dispose();
  }
}
