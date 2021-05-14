import 'package:flutter/material.dart';
import 'package:ynotes/core/apis/model.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';

class SchoolLifeController extends ChangeNotifier {
  final api;
  API? _api;
 
  List<SchoolLifeTicket>? tickets;

  SchoolLifeController(this.api) {
    _api = api;
  }

  Future<void> refresh({bool force = false, refreshFromOffline = false}) async {
    print("Refresh school_life tickets");
    notifyListeners();

    if (refreshFromOffline) {
      tickets = await _api!.getSchoolLife();
      notifyListeners();
    } else {
      tickets = await _api!.getSchoolLife();
      notifyListeners();
    }
    notifyListeners();
  }
}
