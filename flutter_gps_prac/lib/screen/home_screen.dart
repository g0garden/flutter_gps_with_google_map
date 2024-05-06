import 'package:flutter/cupertino.dart';
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

  bool isWorkedIn = false;

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
                flex: 2,
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    this.controller = controller;
                  },
                  initialCameraPosition: initialPosition,
                  mapType: MapType.normal,
                  myLocationEnabled: true, //현위치 표시
                  myLocationButtonEnabled: false, //현위치가기 버튼
                  zoomControlsEnabled: false,
                  markers: {
                    //출근해야하는 회사의 위치라고 생각해봐
                    const Marker(
                      markerId: MarkerId('123'),
                      position: LatLng(
                        37.5214,
                        126.9246,
                      ),
                    ),
                  },
                  //완전 그 회사건물의 위치에 못오더라도, 반경 100m 이내면 출근 가능하게 해주자
                  circles: {
                    Circle(
                      circleId: CircleId('indistance'),
                      center: LatLng(
                        37.5214,
                        126.9246,
                      ),
                      radius: 100,
                      fillColor: Colors.blue.withOpacity(0.3),
                      strokeColor: Colors.blue,
                      strokeWidth: 1,
                    )
                  },
                ),
              ),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isWorkedIn ? Icons.check : Icons.timelapse_outlined,
                    color: isWorkedIn ? Colors.green : Colors.blue,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  if (!isWorkedIn)
                    OutlinedButton(
                        onPressed: workInCheckPressed, child: Text('출근하기'))
                ],
              ))
            ],
          );
        },
      ),
    );
  }

  workInCheckPressed() async {
    final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('출근하기'),
            content: Text('출근을 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('취소'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('출근하기'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ],
          );
        });

    if (result) {
      setState(() {
        isWorkedIn = result;
      });
    }
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
