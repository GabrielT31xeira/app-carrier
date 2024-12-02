import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PackageDetailsPage extends StatefulWidget {
  final String travelId;

  PackageDetailsPage({required this.travelId});

  @override
  _PackageDetailsPageState createState() => _PackageDetailsPageState();
}

class _PackageDetailsPageState extends State<PackageDetailsPage> {
  late Map<String, dynamic> travel;
  bool isLoading = true;
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  final String googleAPIKey = 'AIzaSyBscAm8DFRRyyGsyCWcINDhYt03PYmPwDg';
  late GoogleMapController mapController;
  Map<MarkerId, Marker> markers = {};

  @override
  void initState() {
    super.initState();
    fetchTravelDetails();
  }

  Future<void> fetchTravelDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/travel/${widget.travelId}');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        travel = json.decode(response.body)['travel'];
        print(travel);
        _addMarkers();
        _getPolyline();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load travel details');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addMarkers() {
    final outputLatLng = LatLng(
      double.parse(travel['output']['latitude']),
      double.parse(travel['output']['longitude']),
    );
    final arrivalLatLng = LatLng(
      double.parse(travel['arrival']['latitude']),
      double.parse(travel['arrival']['longitude']),
    );

    _addMarker(outputLatLng, 'output', BitmapDescriptor.defaultMarker);
    _addMarker(arrivalLatLng, 'arrival', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
  }

  void _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(markerId: markerId, icon: descriptor, position: position);
    setState(() {
      markers[markerId] = marker;
    });
  }

  void _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    setState(() {
      polylines.add(polyline);
    });
  }

  void _getPolyline() async {
    final outputLatLng = LatLng(
      double.parse(travel['output']['latitude']),
      double.parse(travel['output']['longitude']),
    );
    final arrivalLatLng = LatLng(
      double.parse(travel['arrival']['latitude']),
      double.parse(travel['arrival']['longitude']),
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleAPIKey,
      request: PolylineRequest(
        origin: PointLatLng(outputLatLng.latitude, outputLatLng.longitude),
        destination: PointLatLng(arrivalLatLng.latitude, arrivalLatLng.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      _addPolyLine();
    } else {
      print(result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Entrega', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Veículo: ${travel['vehicle']['plate']} - ${travel['vehicle']['vehicle_type']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('Saída: ${travel['output']['city']} - ${travel['output']['state']}'),
                    Text('Chegada: ${travel['arrival']['city']} - ${travel['arrival']['state']}'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  double.parse(travel['output']['latitude']),
                  double.parse(travel['output']['longitude']),
                ),
                zoom: 5,
              ),
              markers: Set<Marker>.of(markers.values),
              polylines: polylines,
            ),
          ),
        ],
      ),
    );
  }
}