import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProposalPage extends StatefulWidget {
  @override
  _ProposalPageState createState() => _ProposalPageState();
}

class _ProposalPageState extends State<ProposalPage> {
  List<dynamic> accept_proposal = [];
  List<dynamic> not_accept_proposal = [];

  @override
  void initState() {
    super.initState();
    fetchProposal();
  }

  Future<void> fetchProposal() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/travel/$id/proposal');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        accept_proposal = json.decode(response.body)['accepted_proposals'];
        not_accept_proposal = json.decode(response.body)['not_accepted_proposals'];
      });

    } else {
      throw Exception('Failed to load travels');
    }
  }

  Future<void> deleteProposal(String proposalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/proposal/$proposalId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print(url);
    if (response.statusCode == 200) {
      setState(() {
        fetchProposal();
        _showSucess(context);
      });
    } else {
      _showError(context);
      throw Exception('Failed to load Proposals');
    }
  }

  void _showSucess(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Proposta apagada com sucesso!",
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
        title: Text('Minhas Propostas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Propostas Aceitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: accept_proposal.isEmpty
                      ? Center(child: Text('Sem propostas aceitas'))
                      : ListView.builder(
                    itemCount: accept_proposal.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Placa do Veículo: ${accept_proposal[index]['vehicle_plate']}', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Tipo de Veículo: ${accept_proposal[index]['vehicle_type']}'),
                              Text('Marca: ${accept_proposal[index]['vehicle_brand']}'),
                              Text('Modelo: ${accept_proposal[index]['vehicle_model']} (${accept_proposal[index]['vehicle_model_year']})'),
                              SizedBox(height: 10),
                              Text('Saída: ${accept_proposal[index]['output_city']}, ${accept_proposal[index]['output_state']}'),
                              Text('Endereço de Saída: ${accept_proposal[index]['output_address']}'),
                              Text('Data de Saída: ${accept_proposal[index]['date_output']}'),
                              SizedBox(height: 10),
                              Text('Chegada: ${accept_proposal[index]['arrival_city']}, ${accept_proposal[index]['arrival_state']}'),
                              Text('Endereço de Chegada: ${accept_proposal[index]['arrival_address']}'),
                              Text('Data de Chegada: ${accept_proposal[index]['date_arrival']}'),
                              SizedBox(height: 10),
                              Text('Preço: R\$${accept_proposal[index]['price']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Column(
              children: [
                Text('Propostas Não Aceitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: not_accept_proposal.isEmpty
                      ? Center(child: Text('Sem propostas realizadas'))
                      : ListView.builder(
                    itemCount: not_accept_proposal.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Placa do Veículo: ${not_accept_proposal[index]['vehicle_plate']}', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Tipo de Veículo: ${not_accept_proposal[index]['vehicle_type']}'),
                              Text('Marca: ${not_accept_proposal[index]['vehicle_brand']}'),
                              Text('Modelo: ${not_accept_proposal[index]['vehicle_model']} (${not_accept_proposal[index]['vehicle_model_year']})'),
                              SizedBox(height: 10),
                              Text('Saída: ${not_accept_proposal[index]['output_city']}, ${not_accept_proposal[index]['output_state']}'),
                              Text('Endereço de Saída: ${not_accept_proposal[index]['output_address']}'),
                              Text('Data de Saída: ${not_accept_proposal[index]['date_output']}'),
                              SizedBox(height: 10),
                              Text('Chegada: ${not_accept_proposal[index]['arrival_city']}, ${not_accept_proposal[index]['arrival_state']}'),
                              Text('Endereço de Chegada: ${not_accept_proposal[index]['arrival_address']}'),
                              Text('Data de Chegada: ${not_accept_proposal[index]['date_arrival']}'),
                              SizedBox(height: 10),
                              Text('Preço: R\$${not_accept_proposal[index]['price']}'),
                              SizedBox(height: 10),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  deleteProposal(not_accept_proposal[index]['id_proposal']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}