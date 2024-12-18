import 'package:flutter/material.dart';

class TimeIndicator extends StatelessWidget {
  final String time;

  const TimeIndicator({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timer),
        SizedBox(width: 5),
        Text("مدة التوصيل المتوقعة"),
        SizedBox(width: 30),
        Text(time,
        style: TextStyle(
          fontSize: 15,
           color: Color.fromRGBO( 0, 0, 0,1), 
                      
                
          fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 10),
        Text("دقيقة",   
          style: TextStyle(
          fontSize: 15,
           color: Color.fromRGBO( 0, 0, 0,1), 
                      
                
          fontWeight: FontWeight.bold,
          ),
),
      ],
    );
  }
}