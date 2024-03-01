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
    return Row(
      children: [
        SizedBox(
          height: 80,
          width: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              color: Colors.blueGrey[200], // button color
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
                        : Icon(
                            Icons.highlight_off_outlined,
                            color: Colors.red[600],
                            size: 35,
                          ),
                    Text(
                      widget.text,
                      style: const TextStyle(fontSize: 20),
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
      ],
    );
  }
}
