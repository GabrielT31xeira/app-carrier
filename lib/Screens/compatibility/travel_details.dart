import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TravelDetailsPage extends StatefulWidget {
  final String travelId;
  final String carrierId;

  const TravelDetailsPage({super.key, required this.travelId, required this.carrierId});
  // TravelDetailsPage({required this.travelId});

  @override
  _TravelDetailsPageState createState() => _TravelDetailsPageState();
}

class _TravelDetailsPageState extends State<TravelDetailsPage> {
  late Map<String, dynamic> travel;
  bool isLoading = true;
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  final String googleAPIKey = 'AIzaSyBscAm8DFRRyyGsyCWcINDhYt03PYmPwDg';
  late GoogleMapController mapController;
  Map<MarkerId, Marker> markers = {};

  final _formKey = GlobalKey<FormState>();
  final _dataChegadaController = TextEditingController();
  final _dataSaidaController = TextEditingController();
  final _precoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTravelDetails();
  }

  Future<void> fetchTravelDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://35.174.5.208:83/api/travel/${widget.travelId}');
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

  void _showProposalForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Fazer Proposta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _dataSaidaController,
                  decoration: InputDecoration(labelText: 'Data de Saída'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dataSaidaController.text = pickedDate.toString().split(' ')[0];
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a data de saída';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _dataChegadaController,
                  decoration: InputDecoration(labelText: 'Data de Chegada'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dataChegadaController.text = pickedDate.toString().split(' ')[0];
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a data de chegada';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _precoController,
                  decoration: InputDecoration(labelText: 'Preço'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o preço';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _sendProposal();
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Enviar Proposta'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendProposal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/client/${widget.travelId}/carrier/${widget.carrierId}');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'data_chegada': _dataChegadaController.text,
        'data_saida': _dataSaidaController.text,
        'preco': double.parse(_precoController.text),
      }),
    );
    print(url);
    if (response.statusCode == 200) {
      _showSucess(context);
    } else if (response.statusCode == 422) {
      final errors = json.decode(response.body);
      _showValidationErrors(context, errors);
    } else {
      _showError(context);
    }
  }

  void _showValidationErrors(BuildContext context, Map<String, dynamic> errors) {
    String errorMessage = '';
    errors.forEach((key, value) {
      errorMessage += value.join('\n') + '\n';
    });

    Fluttertoast.showToast(
      msg: errorMessage,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSucess(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Proposta enviada com sucesso!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showError(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Erro ao enviar a proposta, tente novamente mais tarde!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
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
                    Text('Pacote: ${travel['package']['description']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('Peso: ${travel['package']['weight']} ${travel['package']['metric_weight']}'),
                    Text('Dimensões: ${travel['package']['width']} ${travel['package']['metric_width']} x ${travel['package']['height']} ${travel['package']['metric_height']}'),
                    Text('Fragilidade: ${travel['package']['fragility']}'),
                    Text('Saída: ${travel['output']['state']} - ${travel['output']['city']}'),
                    Text('Chegada: ${travel['arrival']['state']} - ${travel['arrival']['city']}'),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            _showProposalForm(context);
                          },
                          child: Text('Fazer Proposta'),
                        ),
                      ],
                    ),
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