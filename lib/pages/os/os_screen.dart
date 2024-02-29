import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/os/os_view.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
// import 'package:mapos_app/pages/os/os_add.dart';
import 'package:page_transition/page_transition.dart';


class OsScreen extends StatefulWidget {
  @override
  _OsScreenState createState() => _OsScreenState();
}
class _OsScreenState extends State<OsScreen> {
  int _selectedIndex = 4;
  List<dynamic> os = [];
  List<dynamic> filteredOs = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getOs();
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getOs() async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';

    var url = '${APIConfig.baseURL}${APIConfig.osEndpoint}?X-API-KEY=$ciKey';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        List<dynamic> newOs = data['result'];
        setState(() {
          os.addAll(newOs);
          filteredOs = List.from(os); // Update filtered list
        });
      } else {
        print('Key "os" not found in API response');
      }
    } else {
      print('Failed to load os');
    }
  }

  void _startSearch() {
    setState(() {
      isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      isSearching = false;
      searchController.clear();
      filteredOs = List.from(os); // Restore filtered list to original
    });
  }

  void _filterOs(String searchText) {
    setState(() {
      filteredOs = os
          .where((os) =>
          os['nomeCliente'].toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }
  Color _getStatusColor(String status) {
    String statusLowerCase = status.toLowerCase().trim();

    switch (statusLowerCase) {
      case 'aberto':
        return Colors.black;
      case 'orçamento':
        return Colors.blue;
      case 'aprovado':
        return Colors.green;
      case 'em andamento':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      case 'finalizado':
        return Color(0xff225566);
      case 'Faturado':
        return Color(0xff8100fc);
      default:
        return Colors.grey;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: !isSearching ? Text('Ordens de Serviço') : TextField(
          controller: searchController,
          style: TextStyle(color: Colors.white),
          onChanged: (value) {
            _filterOs(value);
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar...',
            hintStyle: TextStyle(color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Color(0xff56596e),
            contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          ),
        ),
        actions: <Widget>[
          isSearching
              ? IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () {
              _stopSearch();
            },
          )
              : IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _startSearch();
            },
          ),
        ],
      ),
      body: filteredOs.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          :ListView.builder(
        itemCount: filteredOs.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0), // Ajuste os valores de padding vertical conforme necessário
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0), // Defina a margem externa dos cartões
              child: ListTile(
                onTap: () async {
                  Navigator.push(
                    context,
                    PageTransition(
                      child: OsManager(os: filteredOs[index]),
                      type: PageTransitionType.leftToRight,
                    ),
                  );
                },

                contentPadding: EdgeInsets.all(8.0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF333649),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.all(10.0),
                          child: Center(
                            child: Text(
                              '${filteredOs[index]['idOs']}',
                              style: TextStyle(
                                fontSize: (MediaQuery.of(context).size.width * 0.040),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filteredOs[index]['nomeCliente']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: (MediaQuery.of(context).size.width * 0.040),
                              ),
                            ),
                            Text(
                              'Inicio: ${filteredOs[index]['dataInicial'] ?? 0}',
                              style: TextStyle(
                                fontSize: (MediaQuery.of(context).size.width * 0.0350),
                              ),
                            ),
                            Text(
                              'Limite: ${filteredOs[index]['dataFinal'] ?? 0}',
                              style: TextStyle(
                                fontSize: (MediaQuery.of(context).size.width * 0.0350),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      child: Text(
                        '${filteredOs[index]['status'] ?? ''}',
                        style: TextStyle(
                          color: _getStatusColor(filteredOs[index]['status'] ?? ''),
                          fontWeight: FontWeight.bold,
                          fontSize: (MediaQuery.of(context).size.width * 0.030),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),



      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Map<String, dynamic> permissions = await _getCiKey();
          bool hasPermissionToAdd = false;
          for (var permissao in permissions['permissoes']) {
            if (permissao['aOs'] == '1') {
              hasPermissionToAdd = true;
              break;
            }
          }
          if (hasPermissionToAdd) {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => OsAddScreen()),
            // );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text('Você não tem permissão para adicionar Ordens de Serviço.'),
              ),
            );
          }
        },
        child: Icon(Icons.add),

      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        context: context, // Passe o contexto aqui
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}