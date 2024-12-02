import 'package:carrier/Screens/compatibility/travel_details.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CompatibilityPage extends StatefulWidget {
  final String travelId;

  CompatibilityPage({required this.travelId});

  @override
  _CompatibilityPageState createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends State<CompatibilityPage> {
  List<dynamic> travels = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchTravelsCompatible();
  }

  Future<void> fetchTravelsCompatible() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('http://54.205.181.130:84/api/travel/${widget.travelId}/compatible');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          travels = json.decode(response.body)['travels'];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        throw Exception('Failed to load travels');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print(e);
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

  Future<bool> _onWillPop() async {
    Navigator.of(context).pushReplacementNamed('/home');
    return false; // Impede a navegação padrão
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Entregas Compatíveis', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/home'),
          ),
        ),
        body: Container(
          color: Colors.purple[50],
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : hasError || travels.isEmpty
              ? Center(child: Text('Nenhuma entrega compatível', style: TextStyle(fontSize: 18, color: Colors.black)))
              : ListView.builder(
            itemCount: travels.length,
            itemBuilder: (context, index) {
              final travel = travels[index];

              return Card(
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saída: ${travel['output']['state']} - ${travel['output']['city']}', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Chegada: ${travel['arrival']['state']} - ${travel['arrival']['city']}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TravelDetailsPage(travelId: travel['id_travel'], carrierId: widget.travelId),
                                ),
                              );
                            },
                            child: Text('Mais Detalhes'),
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
      ),
    );
  }
}