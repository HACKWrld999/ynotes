import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';
import 'package:ynotes/core/logic/schoolLife/controller.dart';
import 'package:ynotes/core/utils/themeUtils.dart';
import 'package:ynotes/globals.dart';

class SchoolLifePage extends StatefulWidget {
  const SchoolLifePage({Key? key}) : super(key: key);
  @override
  _SchoolLifePageState createState() => _SchoolLifePageState();
}

class _SchoolLifePageState extends State<SchoolLifePage> {
  @override
  Widget build(BuildContext context) {
    MediaQueryData screenSize = MediaQuery.of(context);
    return Container(
        height: screenSize.size.height,
        width: screenSize.size.width,
        child: ChangeNotifierProvider<SchoolLifeController>.value(
            value: appSys.schoolLifeController,
            child: Consumer<SchoolLifeController>(builder: (context, model, child) {
              return Container(
                height: screenSize.size.height,
                width: screenSize.size.width,
                child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                        vertical: screenSize.size.width / 5 * 0.1, horizontal: screenSize.size.width / 5 * 0.05),
                    itemCount: (model.tickets ?? []).length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildTicket(model.tickets![index]);
                    }),
              );
            })));
  }

  Widget buildCircle(SchoolLifeTicket ticket) {
    IconData? icon;
    if (ticket.type == "Absence") {
      icon = MdiIcons.alert;
    }
    if (ticket.type == "Retard") {
      icon = MdiIcons.clockAlertOutline;
    }
    if (ticket.type == "Repas") {
      icon = MdiIcons.foodOff;
    }

    var screenSize = MediaQuery.of(context);
    return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColorDark),
        child: FittedBox(
            child: Icon(
          icon,
          color: ThemeUtils.textColor(),
        )),
        padding: EdgeInsets.all(screenSize.size.width / 5 * 0.15),
        width: screenSize.size.width / 5 * 0.8,
        height: screenSize.size.width / 5 * 0.8,
        margin: EdgeInsets.all(10));
  }

  Widget buildNoTickets() {
    MediaQueryData screenSize = MediaQuery.of(context);

    return Center(
      child: Container(
        height: screenSize.size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.stamper,
              size: screenSize.size.width / 5 * 1.2,
              color: ThemeUtils.textColor(),
            ),
            Text(
              "Pas de données.",
              style: TextStyle(fontFamily: "Asap", color: ThemeUtils.textColor(), fontSize: 20),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTicket(SchoolLifeTicket ticket) {
    MediaQueryData screenSize = MediaQuery.of(context);
    return Container(
      width: screenSize.size.width / 5 * 4.2,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        color: Theme.of(context).primaryColor,
        child: Row(
          children: [
            buildCircle(ticket),
            SizedBox(width: screenSize.size.width / 5 * 0.1),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.libelle!,
                      style: TextStyle(
                          color: ThemeUtils.textColor(), fontFamily: "Asap", fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      "Motif : " + ticket.motif!,
                      style: TextStyle(color: ThemeUtils.textColor(), fontFamily: "Asap", fontSize: 15),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      "Date : " + ticket.displayDate!,
                      style: TextStyle(color: ThemeUtils.textColor(), fontFamily: "Asap", fontSize: 15),
                      textAlign: TextAlign.left,
                    ),
                    RichText(
                        text: TextSpan(
                            style: TextStyle(
                                color: ticket.isJustified! ? Colors.green : Colors.orange,
                                fontFamily: "Asap",
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                            children: [
                          TextSpan(
                            text: ticket.isJustified! ? "Justifié " : "A justifier ",
                          ),
                          WidgetSpan(
                              child: Icon(ticket.isJustified! ? MdiIcons.check : MdiIcons.exclamation,
                                  color: ticket.isJustified! ? Colors.green : Colors.orange))
                        ])),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    appSys.schoolLifeController.refresh(force: true);
  }

  Widget separator(BuildContext context, String text) {
    MediaQueryData screenSize = MediaQuery.of(context);

    return Container(
      height: screenSize.size.height / 10 * 0.35,
      margin: EdgeInsets.only(
        top: screenSize.size.height / 10 * 0.1,
        left: screenSize.size.width / 5 * 0.25,
        bottom: screenSize.size.height / 10 * 0.1,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Text(
          text,
          style:
              TextStyle(color: ThemeUtils.textColor(), fontFamily: "Asap", fontSize: 25, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
