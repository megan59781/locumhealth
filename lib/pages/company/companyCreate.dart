import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fyp/templates/dateTimeText.dart';
import 'package:fyp/templates/displayText.dart';
import 'package:fyp/templates/pushBut.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CompanyCreateJob extends StatefulWidget {
  final String companyId;

  CompanyCreateJob({super.key, required this.companyId});

  @override
  State createState() => CompanyCreateJobState();
}

class CompanyCreateJobState extends State<CompanyCreateJob> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.now();

  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();

  Future<void> _dateSelector(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime(2024, 6));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<TimeOfDay> _selectTime(TextEditingController controller) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (newTime != null) {
      setState(() {
        selectedTime = newTime;
        controller.text = selectedTime.format(context);
      });
    }
    return selectedTime;
  }

  Future<void> _timeSelector(BuildContext context, String currentTime,
      Function(TimeOfDay) updateSelected) {
    TextEditingController timeController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Please Select the Time'),
          content: SizedBox(
            height: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DisplayText(
                    text: "Selected Time", fontSize: 25, colour: Colors.black),
                const SizedBox(height: 5),
                TextFormField(
                  controller: timeController,
                  decoration: InputDecoration(
                    hintText: currentTime,
                    border: const OutlineInputBorder(),
                  ),
                  onTap: () => _selectTime(timeController),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                updateSelected(TimeOfDay.now());
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 120),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Submit'),
              onPressed: () {
                // TO DO SAVE TIMES
                TimeOfDay currentTime = TimeOfDay.fromDateTime(
                    DateTime.parse("2024-01-01 ${timeController.text}"));
                updateSelected(currentTime);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> addJobDb(String date, String companyId, TimeOfDay startTime,
      TimeOfDay endTime, String location, BuildContext context) async {
    String jobId = const Uuid().v4();

    Map<String, dynamic> job = {
      "job_id": jobId,
      "company_id": companyId,
      "date": date,
      "day_start_time": startTime.format(context),
      "day_end_time": endTime.format(context),
      "location": location,
    };

    try {
      await dbhandler.child("Jobs").push().set(job);
      //Navigator.of(context).pop();
    } catch (error) {
      print("Error saving to Firebase: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateString = DateFormat('dd/MM/yyyy').format(selectedDate);
    String companyId = widget.companyId;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 10),
            const DisplayText(
                text: 'Create a New Job', fontSize: 34, colour: Colors.black),
            const SizedBox(height: 50),
            const DisplayText(
                text: 'Select Date of the Job',
                fontSize: 30,
                colour: Colors.deepPurple),
            const SizedBox(height: 10),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DisplayText(
                      text: 'Date: ', fontSize: 30, colour: Colors.black),
                  DateTimeText(
                    text: dateString,
                    icon: const Icon(Icons.date_range_outlined),
                    onPress: () => _dateSelector(context),
                  ),
                ]),
            const SizedBox(height: 50),
            const DisplayText(
                text: 'Select Time of the Job',
                fontSize: 30,
                colour: Colors.deepPurple),
            const SizedBox(height: 10),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DisplayText(
                      text: 'Start:', fontSize: 30, colour: Colors.black),
                  DateTimeText(
                      text: startTime.format(context),
                      icon: const Icon(Icons.update_outlined),
                      onPress: () =>
                          _timeSelector(context, startTime.format(context),
                              (currentTime) {
                            setState(() {
                              startTime = currentTime;
                            });
                          }))
                ]),
            const SizedBox(height: 20),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DisplayText(
                      text: ' End: ', fontSize: 30, colour: Colors.black),
                  DateTimeText(
                    text: endTime.format(context),
                    icon: const Icon(Icons.history_outlined),
                    onPress: () => _timeSelector(
                        context, endTime.format(context), (currentTime) {
                      setState(() {
                        endTime = currentTime;
                      });
                    }),
                  ),
                ]),
            const SizedBox(height: 40),
            PushButton(
              buttonSize: 60,
              text: 'Create Job',
              onPress: () async {
                addJobDb(dateString, companyId, startTime, endTime,
                    "po1", context);
              },
            ),
          ]),
        ),
      ),
    );
  }
}
