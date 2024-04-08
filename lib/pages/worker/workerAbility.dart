import 'package:flutter/material.dart';
import 'package:fyp/templates/displayText.dart';

class WorkerAbility extends StatefulWidget {
  final String workerId;

  const WorkerAbility({Key? key, required this.workerId}) : super(key: key);

  @override
  State createState() => WorkerAbilityState();
}

class WorkerAbilityState extends State<WorkerAbility> {
  List<String> selectedAbilitys = [];
  static const List<String> selections = <String>[
    'First Aid',
    'Manual Handling',
    'Medicication Administration',
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
              ]),
        ),
      ),
    );
  }
}
