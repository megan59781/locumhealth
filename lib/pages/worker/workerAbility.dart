import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';

class WorkerAbility extends StatefulWidget {
  final String workerId;

  const WorkerAbility({super.key, required this.workerId});

  @override
  State createState() => WorkerAbilityState();
}

class WorkerAbilityState extends State<WorkerAbility> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    updateView(widget.workerId);
  }

  Future<void> updateView(String workerId) async {
    // updates the day button with the current day + times availability
    dbhandler
        .child('Ability')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          List<String> workerAbilities = [];
          var abilityKey = data.keys.first;
          var abilityData = data[abilityKey];
          abilityData.forEach((key, value) {
            if (key != 'worker_id') {
              workerAbilities.add(key);
            }
          });
          print("HERE LIST: $workerAbilities");
          // TO DO - update the view with the ability
          setState(() {
            selectedAbilitys = workerAbilities; // Update selected abilities
          });
        }
      }
    });
  }

  Future<void> addAbilitysDb(String workerId) async {
    dbhandler
        .child('Ability')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          var abilityKey = data.keys.first;
          //var abilityData = data[abilityKey];
          for (String ability in selectedAbilitys) {
            await dbhandler.child("Ability").child(abilityKey).update({
              ability: true,
            });
          }
        }
      } else {
        Map<String, dynamic> abilityList = {
          "worker_id": widget.workerId,
        };
        for (String ability in selectedAbilitys) {
          abilityList.addAll({
            ability: true,
          });
        }
        await dbhandler.child("Ability").push().set(abilityList);
      }
    });
  }

  List<String> selectedAbilitys = [];
  static const List<String> selections = <String>[
    'First Aid',
    'Manual Handling',
    'Medication Administration',
    'Mental Health Training',
    'Elderly Care Training',
    'Child Care Training',
    'Disability Care Training',
    'Palliative Care Training',
    'Dementia Care Training',
    'Stoma Training',
    'Catheter Training',
    'PEG Feeding Training',
    'Restrained Training',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 60),
                const DisplayText(
                    text: "Select Your Abilities",
                    fontSize: 30,
                    colour: Colors.black),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      final String ability = selections[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: selectedAbilitys.contains(ability),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value != null && value) {
                                    selectedAbilitys.add(ability);
                                  } else {
                                    selectedAbilitys.remove(ability);
                                  }
                                });
                              },
                            ),
                            Text(
                              ability,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                decorationStyle: TextDecorationStyle.wavy,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    itemCount: selections.length,
                  ),
                ),
                const SizedBox(height: 30),
                PushButton(
                  buttonSize: 70,
                  text: 'Submit Abilities',
                  onPress: () {
                    addAbilitysDb(widget.workerId);
                    //Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 30),
              ]),
        ),
      ),
    );
  }
}
