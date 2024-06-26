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

  bool isWorkedIn = false; //출근했는지 여부
  bool canWorkedIn = false; //출근가능한 거리인지 여부

  final double okDistance = 100;

  late final GoogleMapController controller;

  @override
  initState() {
    super.initState();

    Geolocator.getPositionStream().listen((event) {
      print(event); //latitude longtitude 받아올 수 있음

      //거리계산 하기
      final start = LatLng(
        37.5214,
        126.9246,
      );

      final end = LatLng(event.latitude, event.longitude);

      final distance = Geolocator.distanceBetween(
          start.latitude, start.longitude, end.latitude, end.longitude);

      setState(() {
        if (distance > okDistance) {
          canWorkedIn = false;
        } else {
          canWorkedIn = true;
        }
      });
    });
  }

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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                  child: _GoogleMaps(
                    initialCarmeraLocation: initialPosition,
                    onMapCreated: (GoogleMapController controller) {
                      this.controller = controller;
                    },
                    isWorkedIn: isWorkedIn,
                    canWorkedIn: canWorkedIn,
                    distance: okDistance,
                  )),
              Expanded(
                  child: _BottomWorkedInButton(
                canWorkedIn: canWorkedIn,
                isWorkedIn: isWorkedIn,
                workInCheckPressed: workInCheckPressed,
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

class _GoogleMaps extends StatelessWidget {
  final CameraPosition initialCarmeraLocation;
  final MapCreatedCallback onMapCreated;
  final bool canWorkedIn;
  final bool isWorkedIn;
  final double distance;

  const _GoogleMaps(
      {required this.initialCarmeraLocation,
      required this.onMapCreated,
      required this.canWorkedIn,
      required this.isWorkedIn,
      required this.distance,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: initialCarmeraLocation,
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
          radius: distance,
          fillColor: canWorkedIn
              ? Colors.blue.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          strokeColor: canWorkedIn ? Colors.blue : Colors.red,
          strokeWidth: 1,
        )
      },
    );
  }
}

class _BottomWorkedInButton extends StatelessWidget {
  final bool canWorkedIn;
  final bool isWorkedIn;
  final VoidCallback workInCheckPressed;
  const _BottomWorkedInButton(
      {required this.canWorkedIn,
      required this.isWorkedIn,
      required this.workInCheckPressed,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isWorkedIn ? Icons.check : Icons.timelapse_outlined,
          color: isWorkedIn ? Colors.green : Colors.blue,
        ),
        SizedBox(
          height: 16,
        ),
        //아직 출근전이고, 출근지 100M이내이면 버튼보이게
        if (!isWorkedIn && canWorkedIn)
          OutlinedButton(onPressed: workInCheckPressed, child: Text('출근하기'))
      ],
    );
  }
}
