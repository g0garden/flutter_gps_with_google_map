import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  late final GoogleMapController controller;

  checkPermission() async {
    //gps 확인
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      throw Exception('gps를 활성화 해주세요');
    }

    //현재 앱의 권한 상태 확인하기
    LocationPermission checkedPermission = await Geolocator.checkPermission();

    if (checkedPermission == LocationPermission.denied) {
      //요청전 기본 denied 상태라, 요청가능한 상태
      checkedPermission = await Geolocator.requestPermission();
    }

    if (checkedPermission != LocationPermission.always &&
        checkedPermission != LocationPermission.whileInUse) {
      throw Exception('위치 권한을 허가해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '오늘도출근',
          style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              onPressed: myLocationPressed,
              icon: const Icon(
                Icons.my_location,
                color: Colors.amber,
              ))
        ],
      ),
      body: FutureBuilder(
        future: checkPermission(), //비동기함수
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            child:
            Text(snapshot.error.toString()); //throw한 error 내용 들어옴
          }
          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    this.controller = controller;
                  },
                  initialCameraPosition: initialPosition,
                  mapType: MapType.normal,
                  myLocationEnabled: true, //현위치 표시
                  myLocationButtonEnabled: false, //현위치가기 버튼
                  zoomControlsEnabled: false,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  myLocationPressed() async {
    //현위치 받아와서 이동하기
    final location = await Geolocator.getCurrentPosition();

    controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(location.latitude, location.longitude),
      ),
    );
  }
}
