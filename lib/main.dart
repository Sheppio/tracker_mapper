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
  late final MapController mapController;

  final LatLng _twinIngitions = LatLng(45.00076796865061, -93.27039033565887);

  List<Marker> _markers = <Marker>[];
  LatLng _dummyRobotLocation = LatLng(45.000645, -93.26994);

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    initiateRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => mapToFitBounds(),
          child: const Icon(Icons.center_focus_strong_sharp),
          backgroundColor: Colors.blue,
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
        ));
  }

  mapToFitBounds() {
    var bounds = LatLngBounds.fromPoints(_markers
        .map((e) => LatLng(e.point.latitude, e.point.longitude))
        .toList());
    mapController.fitBounds(bounds,
        options:
            const FitBoundsOptions(zoom: 12, padding: EdgeInsets.all(100.0)));
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
          });
        }
      }
    });
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
    super.dispose();
  }
}
