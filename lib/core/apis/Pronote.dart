import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ynotes/core/apis/Pronote/PronoteAPI.dart';
import 'package:ynotes/core/apis/Pronote/PronoteCas.dart';
import 'package:ynotes/core/apis/Pronote/converters/account.dart';
import 'package:ynotes/core/apis/Pronote/pronoteMethods.dart';
import 'package:ynotes/core/apis/model.dart';
import 'package:ynotes/core/apis/utils.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/logic/shared/loginController.dart';
import 'package:ynotes/core/offline/data/agenda/lessons.dart';
import 'package:ynotes/core/offline/data/disciplines/disciplines.dart';
import 'package:ynotes/core/offline/data/homework/homework.dart';
import 'package:ynotes/core/offline/data/polls/polls.dart';
import 'package:ynotes/core/offline/offline.dart';
import 'package:ynotes/core/utils/loggingUtils.dart';
import 'package:ynotes/core/utils/nullSafeMapGetter.dart';
import 'package:ynotes/globals.dart';
import 'package:ynotes/ui/screens/settings/settingsPage.dart';

class APIPronote extends API {
  bool loginLock = false;

  late PronoteClient localClient;

  int loginReqNumber = 0;

  APIPronote(Offline offlineController) : super(offlineController) {
    localClient = PronoteClient("");
  }

  @override
  Future<List> apiStatus() async {
    return [1, "Pas de problème connu."];
  }

  @override
  Future app(String appname, {String? args, String? action, CloudItem? folder}) async {
    switch (appname) {
    }
  }

  @override
  Future<http.Request> downloadRequest(Document document) async {
    String url = await localClient.downloadUrl(document);
    http.Request request = http.Request('GET', Uri.parse(url));
    return request;
  }

  @override
  Future<List<DateTime>> getDatesNextHomework() {
    throw UnimplementedError();
  }

  @override
  @override
  Future<List<Discipline>?> getGrades({bool? forceReload}) async {
    return (await PronoteMethod(localClient, this.offlineController).fetchAnyData(
        PronoteMethod(localClient, this.offlineController).grades,
        DisciplinesOffline(offlineController).getDisciplines,
        "grades",
        forceFetch: forceReload ?? false));
  }

  @override
  Future<List<Homework>?> getHomeworkFor(DateTime? dateHomework, {bool? forceReload}) async {
    return (await PronoteMethod(localClient, this.offlineController).fetchAnyData(
        PronoteMethod(localClient, this.offlineController).homeworkFor,
        HomeworkOffline(offlineController).getHomeworkFor,
        "homework for",
        forceFetch: forceReload ?? false,
        offlineArguments: dateHomework,
        onlineArguments: dateHomework));
  }

  @override
  Future<List<Homework>?> getNextHomework({bool? forceReload}) async {
    return (await PronoteMethod(localClient, this.offlineController).fetchAnyData(
        PronoteMethod(localClient, this.offlineController).nextHomework,
        HomeworkOffline(offlineController).getAllHomework,
        "homework",
        forceFetch: forceReload ?? false));
  }

  @override
  Future<List<Lesson>?> getNextLessons(DateTime dateToUse, {bool? forceReload}) async {
    List<Lesson>? lessons = await PronoteMethod(localClient, this.offlineController).fetchAnyData(
        PronoteMethod(localClient, this.offlineController).lessons, LessonsOffline(offlineController).get, "lessons",
        forceFetch: forceReload ?? false, onlineArguments: dateToUse, offlineArguments: await getWeek(dateToUse));

    return lessons
        ?.where((lesson) =>
            DateTime.parse(DateFormat("yyyy-MM-dd").format(lesson.start!)) ==
            DateTime.parse(DateFormat("yyyy-MM-dd").format(dateToUse)))
        .toList();
  }

  getOfflinePeriods() async {
    try {
      List<Period> listPeriods = [];
      List<Discipline>? disciplines = await DisciplinesOffline(offlineController).getDisciplines();
      List<Grade> grades =
          (disciplines ?? []).map((e) => e.gradesList).toList().map((e) => e).expand((element) => element!).toList();
      grades.forEach((grade) {
        if (!listPeriods.any((period) => period.name == grade.periodName)) {
          listPeriods.add(Period(grade.periodName, grade.periodCode));
        }
      });

      listPeriods.sort((a, b) => a.name!.compareTo(b.name!));

      return listPeriods;
    } catch (e) {
      Logger.log("PRONOTE", "Error while collecting offline periods.");
      Logger.log("ERROR", e.toString());
    }
  }

  getOnlinePeriods() async {
    try {
      List<Period> listPeriod = [];
      if (localClient.localPeriods != null) {
        localClient.localPeriods.forEach((pronotePeriod) {
          listPeriod.add(Period(pronotePeriod.name, pronotePeriod.id));
        });

        return listPeriod;
      } else {
        var listPronotePeriods = localClient.periods();
        //refresh local pronote periods
        localClient.localPeriods = [];
        (listPronotePeriods).forEach((pronotePeriod) {
          listPeriod.add(Period(pronotePeriod.name, pronotePeriod.id));
        });
        return listPeriod;
      }
    } catch (e) {
      Logger.log("PRONOTE", "Error while getting periods.");
      Logger.log("ERROR", e.toString());
    }
  }

  Future<List<PollInfo>?> getPronotePolls({bool? forceReload}) async {
    List<PollInfo>? listPolls = [];
    List<PollInfo>? pollsFromInternet = (await PronoteMethod(localClient, this.offlineController).fetchAnyData(
      PronoteMethod(localClient, this.offlineController).polls,
      PollsOffline(offlineController).get,
      "polls",
      forceFetch: forceReload ?? false,
    ));
    listPolls.addAll(pollsFromInternet ?? []);
    return listPolls;
  }

  @override
  Future<List<SchoolLifeTicket>> getSchoolLife({bool forceReload = false}) async {
    return [];
  }

  @override
  Future<List> login(username, password, {Map? additionnalSettings}) async {
    Logger.log("PRONOTE", "username: $username / pwd: $password / url: ${additionnalSettings?["url"] ?? 'null'}");
    int req = 0;

    //we wait a random time (0 to 1 second) to never trigger the function at the same time
    Random random = new Random();
    await Future.delayed(Duration(milliseconds: (random.nextDouble() * 100).round()), () => "1");
    while (loginLock == true && req < 8 && appSys.loginController.actualState != loginStatus.loggedIn) {
      Logger.log("PRONOTE", "Locked, trying in 15 seconds...");
      req++;
      await Future.delayed(Duration(seconds: 15), () => "1");
    }
    if (loginLock == false && loginReqNumber < 5) {
      loginReqNumber = 0;
      loginLock = true;
      try {
        var cookies = await callCas(additionnalSettings?["cas"], username, password, additionnalSettings?["url"] ?? "");
        localClient = PronoteClient(additionnalSettings?["url"],
            username: username,
            password: password,
            mobileLogin: additionnalSettings?["mobileCasLogin"] ?? false,
            cookies: cookies,
            qrCodeLogin: additionnalSettings?["qrCodeLogin"] ?? false);

        bool? login = await localClient.init();
        if (login ?? false) {
          if (localClient.paramsUser != null) {
            appSys.account = PronoteAccountConverter.account(localClient.paramsUser!);
          }

          if (appSys.account != null && appSys.account!.managableAccounts != null) {
            await storage.write(key: "appAccount", value: jsonEncode(appSys.account!.toJson()));
            appSys.currentSchoolAccount = appSys.account!.managableAccounts![0];
          } else {
            loginLock = false;
            Logger.log("PRONOTE", "Impossible to collect accounts.");
            return [0, "Impossible de collecter les comptes."];
          }

          this.loggedIn = true;
          loginLock = false;
          return ([1, "Bienvenue ${appSys.account?.name ?? "Invité"}!"]);
        } else {
          loginLock = false;
          return ([
            0,
            "Oups, une erreur a eu lieu. Vérifiez votre mot de passe et les autres informations de connexion.",
            localClient.stepsLogger
          ]);
        }
      } catch (e) {
        loginLock = false;
        final String err = e.toString();
        localClient.stepsLogger.add("❌ Pronote login failed : " + err);
        Logger.log("PRONOTE", "Login failed.");
        Logger.log("ERROR", err);
        String error = "Une erreur a eu lieu. " + err;
        if (err.contains("invalid url")) {
          error = "L'URL entrée est invalide";
        }
        if (err.contains("split")) {
          error =
              "Le format de l'URL entrée est invalide. Vérifiez qu'il correspond bien à celui fourni par votre établissement";
        }
        if (err.contains("runes")) {
          error = "Le mot de passe et/ou l'identifiant saisi(s) est/sont incorrect(s)";
        }
        if (err.contains("IP")) {
          error =
              "Une erreur inattendue  a eu lieu. Pronote a peut-être temporairement suspendu votre adresse IP. Veuillez recommencer dans quelques minutes.";
        }
        if (err.contains("SocketException")) {
          error = "Impossible de se connecter à l'adresse saisie. Vérifiez cette dernière et votre connexion.";
        }
        if (err.contains("Invalid or corrupted pad block")) {
          if (additionnalSettings?["qrCodeLogin"] ?? false) {
            error = "Le QR code est invalide / expiré";
          } else {
            error = "Le mot de passe et/ou l'identifiant saisi(s) est/sont incorrect(s)";
          }
        }
        if (err.contains("HTML PAGE")) {
          error = "Problème de page HTML.";
        }
        if (err.contains("nombre d'erreurs d'authentification autorisées")) {
          error =
              "Vous avez dépassé le nombre d'erreurs d'authentification authorisées ! Réessayez dans quelques minutes.";
        }
        if (err.contains("Failed login request")) {
          error = "Impossible de se connecter à l'URL renseignée. Vérifiez votre connexion et l'URL entrée.";
        }
        Logger.saveLog(object: "ERROR", text: "Pronote: " + error);
        return ([0, error, localClient.stepsLogger]);
      }
    } else {
      loginReqNumber++;
      return [0, null];
    }
  }

  Future<bool> setPronotePollRead(PollInfo poll, PollQuestion question) async {
    try {
      String publicID = mapGet(localClient.paramsUser, ["donneesSec", "donnees", "ressource", "N"]);
      int publicType = mapGet(localClient.paramsUser, ["donneesSec", "donnees", "ressource", "G"]);
      String publicName = mapGet(localClient.paramsUser, ["donneesSec", "donnees", "ressource", "L"]);

      var data = {
        "donnees": {
          "listeActualites": [
            {
              "N": poll.id,
              "E": publicType,
              "validationDirecte": true,
              "genrePublic": publicType,
              "public": {"N": publicID, "G": publicType, "L": publicName},
              "lue": poll.read,
              "supprimee": false,
              "marqueLueSeulement": false,
              "saisieActualite": false,
              "listeQuestions": [
                {
                  "N": question.id,
                  "L": question.questionName,
                  "E": 2,
                  "genreReponse": 2,
                  "reponse": {
                    "N": 0,
                    "E": 1,
                    "Actif": true,
                    "avecReponse": true,
                    "valeurReponse": "",
                    "_validationSaisie": true
                  }
                }
              ]
            }
          ],
          "saisieActualite": false
        }
      };
      Logger.log("PRONOTE", "Poll: ${jsonEncode(data)}");
      var a = await PronoteMethod(localClient, this.offlineController)
          .request("SaisieActualites", null, data: data, onglet: 8);
      Logger.log("PRONOTE", a);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setPronotePolls(PollInfo poll, PollQuestion question, PollChoice choice) async {
    try {
      String publicID = mapGet(localClient.paramsUser, ["donneesSec", "donnees", "ressource", "N"]);
      int publicType = mapGet(localClient.paramsUser, ["donneesSec", "donnees", "ressource", "G"]);
      String publicName = mapGet(localClient.paramsUser, ["donneesSec", "donnees", "ressource", "L"]);

      var data = {
        "donnees": {
          "listeActualites": [
            {
              "N": poll.id,
              "E": publicType,
              "validationDirecte": true,
              "genrePublic": publicType,
              "public": {"N": publicID, "G": publicType, "L": publicName},
              "lue": poll.read,
              "supprimee": false,
              "marqueLueSeulement": false,
              "saisieActualite": false,
              "listeQuestions": [
                {
                  "N": question.id,
                  "L": question.questionName,
                  "E": 2,
                  "genreReponse": 2,
                  "reponse": {
                    "N": question.answerID,
                    "E": 2,
                    "Actif": true,
                    "valeurReponse": {"_T": 8, "V": "[" + choice.rank.toString() + "]"},
                    "avecReponse": true,
                    "_validationSaisie": true
                  }
                }
              ]
            }
          ],
          "saisieActualite": false
        }
      };
      Logger.log("PRONOTE", "Poll: ${jsonEncode(data)}");
      var a = await PronoteMethod(localClient, this.offlineController)
          .request("SaisieActualites", null, data: data, onglet: 8);
      Logger.log("PRONOTE", a);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool?> testNewGrades() async {
    return null;
  }

  @override
  Future uploadFile(String contexte, String id, String filepath) {
    throw UnimplementedError();
  }
}
