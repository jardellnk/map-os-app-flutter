import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:mapos_app/assets/app_colors.dart';
import 'package:mapos_app/config/constants.dart';

class Audit extends StatefulWidget {
  @override
  _AuditState createState() => _AuditState();
}

class _AuditState extends State<Audit> {
  List<Map<String, String>> _auditData = [];
  int _currentPage = 1;
  bool _isLoading = false;
  ScrollController _scrollController = ScrollController();

  String _currentTheme = 'TemaSecundario'; // Tema padrão

  @override
  void initState() {
    super.initState();
    _getTheme();
    _getAudit();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'TemaSecundario';
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getAudit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ciKey = prefs.getString('token') ?? '';
    Map<String, String> headers = {
      'Authorization': 'Bearer $ciKey',
    };
    var url =
        '${APIConfig.baseURL}${APIConfig
        .auditoriaEndpoint}/?page=$_currentPage';

    setState(() {
      _isLoading = true;
    });

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        List<dynamic> resultList = data['result'];
        List<Map<String, String>> auditList = resultList.map((item) {
          return {
            'idLogs': item['idLogs'].toString(),
            'usuario': item['usuario'].toString(),
            'tarefa': item['tarefa'].toString(),
            'data': item['data'].toString(),
            'hora': item['hora'].toString(),
            'ip': item['ip'].toString(),
          };
        }).toList();
        setState(() {
          _auditData.addAll(auditList);
          _isLoading = false;
          _currentPage++; // Incrementing page for next load
        });
      } else {
        print('Key "result" not found in API response');
      }
    } else {
      print('Failed to load audit data');
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _getAudit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentTheme == 'TemaPrimario'
          ? TemaPrimario.backgroundColor
          : TemaSecundario.backgroundColor,
      appBar: AppBar(
        title: Text('Logs/Auditoria'),
      ),
      body: _isLoading && _auditData.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        controller: _scrollController,
        itemCount: _auditData.length + 1,
        itemBuilder: (context, index) {
          if (index < _auditData.length) {
            final auditEntry = _auditData[index];
            final date = auditEntry['data'] ?? '';
            final formattedDate =
            DateFormat('dd-MM-yyy').format(DateTime.parse(date));

            bool shouldStartNewGroup =
                index == 0 || _auditData[index - 1]['data'] != date;

            return shouldStartNewGroup
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _currentTheme == 'TemaPrimario'
                          ? TemaPrimario.ColorText
                          : TemaSecundario.ColorText,
                    ),
                  ),
                ),
                _buildExpansionTile(auditEntry),
              ],
            )
                : _buildExpansionTile(auditEntry);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget _buildExpansionTile(Map<String, String> auditEntry) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Espaço entre os cards
      decoration: BoxDecoration(
        color: _currentTheme == 'TemaPrimario'
            ? TemaPrimario.listagemCard
            : TemaSecundario.listagemCard,

        borderRadius: BorderRadius.circular(8), // Borda arredondada
      ),
      child: ExpansionTile(
        title: Text(
          auditEntry['tarefa'] ?? '',
          style: TextStyle(
            color: _currentTheme == 'TemaPrimario'
                ? TemaPrimario.ColorText
                : TemaSecundario.ColorText,
          ),
        ),
        children: [
          ListTile(
            title: Text('Usuario: ${auditEntry['usuario'] ?? ''}',
              style: TextStyle(
                color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.ColorText
                    : TemaSecundario.ColorText,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data: ${auditEntry['data'] ?? ''}',
                  style: TextStyle(
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.ColorText
                        : TemaSecundario.ColorText,
                  ),
                ),
                Text('Hora: ${auditEntry['hora'] ?? ''}',
                  style: TextStyle(
                    color: _currentTheme == 'TemaPrimario'
                    ? TemaPrimario.ColorText
                    : TemaSecundario.ColorText,
                  ),
                ),
                Text('IP: ${auditEntry['ip'] ?? ''}',
                  style: TextStyle(
                    color: _currentTheme == 'TemaPrimario'
                        ? TemaPrimario.ColorText
                        : TemaSecundario.ColorText,
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