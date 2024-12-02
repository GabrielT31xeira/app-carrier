import 'package:carrier/Screens/compatibility/CompatibilityPageState.dart';
import 'package:carrier/Screens/page/package_details_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WaitingPage extends StatefulWidget {
  @override
  _WaitingPageState createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  List<dynamic> travels = [];

  @override
  void initState() {
    super.initState();
    fetchTravels();
  }

  Future<void> fetchTravels() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/travel/all/$id');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        travels = json.decode(response.body)['travel'];
      });

    } else {
      throw Exception('Failed to load travels');
    }
  }

  Future<void> deleteTravel(String packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/travel/$packageId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        travels.removeWhere((package) => package['id_travel'] == packageId);
        fetchTravels();
        _showSucess(context);
      });
    } else {
      _showError(context);
      throw Exception('Failed to load packages');
    }
  }

  void _showSucess(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Viagem apagada com sucesso!",
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
      msg: "Erro por parte do servidor, tente novamente mais tarde!",
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
        title: Text('Minhas Viagens', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: Container(
        color: Colors.purple[50],
        child: travels.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: travels.length,
          itemBuilder: (context, index) {
            final travel = travels[index];
            final vehicle = travel['vehicle'];

            return Card(
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Placa: ${vehicle['plate']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Saída: ${travel['output']['state']} - ${travel['output']['city']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Chegada: ${travel['arrival']['state']} - ${travel['arrival']['city']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('Tipo do veiculo: ${vehicle['vehicle_type']}'),
                    Text('Marca: ${vehicle['brand']}'),
                    Text('Modelo: ${vehicle['model']}'),
                    Text('Ano do Modelo: ${vehicle['model_year']}'),
                    Text('Ano de Fabricação: ${vehicle['year_manufacture']}'),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            deleteTravel(travel['id_travel']);
                          },
                          child: Text('Apagar', style: TextStyle(color: Colors.red)),
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PackageDetailsPage(travelId: travel['id_travel']),
                              ),
                            );
                          },
                          child: Text('Detalhes', style: TextStyle(color: Colors.blue)),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompatibilityPage(travelId: travel['id_travel']),
                              ),
                            );
                          },
                          child: Text('Entregas Compativeis', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}