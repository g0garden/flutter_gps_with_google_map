import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraPosition initialPosition = const CameraPosition(
    target: LatLng(
      37.5214,
      126.9246,
    ),
    zoom: 15, //높을수록 확대
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: initialPosition,
          ),
        )
      ],
    ));
  }
}
