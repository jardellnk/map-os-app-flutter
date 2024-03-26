import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/config/constants.dart';
import 'package:mapos_app/pages/clients/clients_manager.dart';
import 'package:mapos_app/pages/clients/clientes_add.dart';
import 'package:mapos_app/widgets/bottom_navigation_bar.dart';
import 'package:mapos_app/main.dart';

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  int _selectedIndex = 3;
  List<dynamic> clientes = [];
  List<dynamic> filteredClientes = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  int _currentPage = 0; // Página atual

  @override
  void initState() {
    super.initState();
    _getClientes();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _getClientes(page: _currentPage + 1);
    }
  }

  Future<Map<String, dynamic>> _getCiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    String permissoesString = prefs.getString('permissoes') ?? '[]';
    List<dynamic> permissoes = jsonDecode(permissoesString);
    return {'ciKey': ciKey, 'permissoes': permissoes};
  }

  Future<void> _getClientes({int page = 0}) async {
    Map<String, dynamic> keyAndPermissions = await _getCiKey();
    String ciKey = keyAndPermissions['ciKey'] ?? '';
    Map<String, String> headers = {
      'X-API-KEY': ciKey,
    };

    var url =
        '${APIConfig.baseURL}${APIConfig.clientesEndpoint}';

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        List<dynamic> newClientes = data['result'] ?? [];
        setState(() {
          if (page == 0) {
            clientes = newClientes;
          } else {
            clientes.addAll(newClientes);
          }
          filteredClientes = List.from(clientes);
          _currentPage = page;
        });
      } else {
        _logout(context);
      }

    } else {
      print('Falha ao carregar clientes');
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
      filteredClientes =
          List.from(clientes); // Restaurar lista filtrada para a original
    });
  }

  Future<void> _filterClientes(String searchText) async {
    if (searchText.isEmpty) {
      setState(() {
        filteredClientes = List.from(clientes); // Restaurar a lista original
      });
      return;
    }

    try {
      final Map<String, dynamic> keyAndPermissions = await _getCiKey();
      final String ciKey = keyAndPermissions['ciKey'] ?? '';
      Map<String, String> headers = {
        'X-API-KEY': ciKey,
      };
      final url =
          '${APIConfig.baseURL}${APIConfig.clientesEndpoint}?search=$searchText';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        final List<dynamic> data = responseData['result'];
        setState(() {
          filteredClientes = List.from(data);
        });
      } else {
        print('Falha ao carregar clientes: ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar clientes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: !isSearching
            ? Text('Clientes',
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.05))
            : TextField(
                controller: searchController,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.05),
                onChanged: (value) {
                  _filterClientes(value);
                },
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true, // Preenchimento ativado
                  fillColor: Color(0xff535772), // Cor de fundo personalizada
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
      body: filteredClientes.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: filteredClientes.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Card(
                    child: ListTile(
                      onTap: () async {
                        Map<String, dynamic> permissions = await _getCiKey();
                        bool hasPermissionToEdit = false;
                        for (var permissao in permissions['permissoes']) {
                          if (permissao['eCliente'] == '1') {
                            hasPermissionToEdit = true;
                            break;
                          }
                        }
                        if (hasPermissionToEdit) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClienteEditScreen(
                                cliente: filteredClientes[index],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                  'Você não tem permissão para editar clientes.'),
                            ),
                          );
                        }
                      },
                      contentPadding: EdgeInsets.all(16.0),
                      title: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF333649),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                '${filteredClientes[index]['idClientes'] ?? 0}',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.04, // 4% da largura da tela
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${filteredClientes[index]['nomeCliente'] ?? 0}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04, // 4% da largura da tela
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Cel: ${filteredClientes[index]['celular'] ?? 0}',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.029, // 4% da largura da tela
                                      ),
                                    ),
                                    SizedBox(width: 8.0),
                                    Text(
                                      'Tel: ${filteredClientes[index]['telefone'] ?? 0}',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.029, // 4% da largura da tela
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
            if (permissao['aCliente'] == '1') {
              hasPermissionToAdd = true;
              break;
            }
          }
          if (hasPermissionToAdd) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClienteAddScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content:
                    Text('Você não tem permissão para adicionar clientes.'),
              ),
            );
          }
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        activeIndex: _selectedIndex,
        context: context,
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

Future<Map<String, dynamic>> _getUserData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String ciKey = prefs.getString('token') ?? '';
  String permissoesString = prefs.getString('permissoes') ?? '[]';
  List<dynamic> permissoes = jsonDecode(permissoesString);
  return {'ci_key': ciKey, 'permissoes': permissoes};
}

void _logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Limpa os dados de autenticação
  await prefs.remove('token');
  await prefs.remove('permissoes');
  // Navega para a tela de login e remove todas as rotas anteriores
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginPage(() {})),
    (Route<dynamic> route) => false,
  );
}
