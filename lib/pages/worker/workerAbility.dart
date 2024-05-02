import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/helpBut.dart';
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
    super.initState(); // update abilities on load
    updateView(widget.workerId);
  }

  // Update the view with the selected abilities from database
  Future<void> updateView(String workerId) async {
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
              // add all but worker_id to abilities
              workerAbilities.add(key);
            }
          });
          setState(() {
            selectedAbilitys = workerAbilities; // Update selected abilities
          });
        }
      }
    });
  }

  // Add the selected abilities to the database
  Future<void> addAbilitysDb(String workerId) async {
    dbhandler
        .child('Ability')
        .orderByChild('worker_id')
        .equalTo(workerId)
        .onValue
        .take(1)
        .listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) { //if already added abilities update 
          var abilityKey = data.keys.first;
          for (String ability in selectedAbilitys) {
            await dbhandler.child("Ability").child(abilityKey).update({
              ability: true, // set key as the abiiity and value as true to state selected
            });
          }
        }
      } else { // if no abilities added yet add new with worker_id
        Map<String, dynamic> abilityList = {
          "worker_id": widget.workerId,
        };
        for (String ability in selectedAbilitys) {
          abilityList.addAll({ // add all selected abilities to the list
            ability: true,
          });
        }
        await dbhandler.child("Ability").push().set(abilityList);
      }
    });
  }

  // List of selected abilities
  // Same as companycreate job abilitys
  List<String> selectedAbilitys = [];
  static const List<String> selections = <String>[ // IF UPDATED HERE ALSO UPDATE IN COMPANYCREATEJOB
    'First Aid',
    'Manual Handling',
    'Medication Administration',
    'Mental Health Training',
    'Elderly Care Training',
    'Child Care Training',
    'Disability are Training',
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
      backgroundColor: const Color(0xffFCFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xffFCFAFC),
        title: const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(
            child: DisplayText(
                text: "Selected Abilities", fontSize: 36, colour: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: SafeArea(
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 25),
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
                                  if (value != null && value) { // if value is true add ability to selected
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
                const SizedBox(height: 40),
                PushButton( // Submit button to save abilities
                  buttonSize: 70,
                  text: 'Submit Abilities',
                  onPress: () {
                    addAbilitysDb(widget.workerId); // Add abilities to database on submit
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Abilities Updated!"), // inform user abilities updated
                    ));
                  },
                ),
                const SizedBox(height: 15),
                Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(top: 20, right: 30),
                  child: const HelpButton( // Help button to display to user how to use the page
                      message:
                          "Select the checkbox to tick the abilities you can do \n\n"
                          "Click the submit button to save your abilities, you can't delete abilities once saved, but you can add more",
                      title: "Ability"),
                ),
                const SizedBox(height: 25),
              ]),
        ),
      ),
    );
  }
}
