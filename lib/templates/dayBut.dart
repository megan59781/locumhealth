import 'package:flutter/material.dart';

class DayButton extends StatefulWidget {
  final String text;
  final bool selected;
  final Function()? onPress;

  const DayButton({
    super.key,
    required this.text,
    required this.selected,
    required this.onPress,
  });

  @override
  _DayButtonState createState() => _DayButtonState();
}

class _DayButtonState extends State<DayButton> {
  bool clicked = false; // Added state for icon highlighting

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        height: 80,
        width: 50,
        decoration: BoxDecoration(
          //border: Border.all(color: Colors.blueGrey[300]!, width: 1),
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.blueGrey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey[300]!.withOpacity(0.5), // Shadow color
              spreadRadius: 1.5,
              blurRadius: 0,
              offset: const Offset(0, 0), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Material(
            // elevation: 5, // Adjust the elevation for the shadow effect
            // shadowColor: Colors.blueGrey[800]!.withOpacity(0.5),
            color: Colors.blueGrey[50], // button color
            child: InkWell(
              onTap: () {
                // Call the provided onPress function
                if (widget.onPress != null) {
                  widget.onPress!();
                }
              }, // button pressed
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  widget.selected
                      ? Icon(
                          Icons.check_circle_outline,
                          color: Colors.green[600],
                          size: 35,
                        )
                      : const Icon(
                          Icons.highlight_off_outlined,
                          color: Color(0xFF280387),
                          size: 35,
                        ),
                  Text(
                    widget.text,
                    style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(
        height: 80,
        width: 1,
      )
    ]);
  }
}
