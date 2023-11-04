// ignore: file_names
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:excel/excel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';

class SiteSurveyPage extends StatefulWidget {
  const SiteSurveyPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SiteSurveyPageState createState() => _SiteSurveyPageState();
}

class _SiteSurveyPageState extends State<SiteSurveyPage> {
  final Set<Marker> _markers = {};
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    addCustomIcon();
    super.initState();
  }

  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), 'assets/custom_marker.png')
        .then((icon) {
      setState(() {
        markerIcon = icon;
      });
    });
  }

  void showPotholeAlert() {
    Fluttertoast.showToast(
      msg: "Drive carefully, pothole here",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER, // Center the toast
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor:
          "linear-gradient(to top, red, transparent)", // Background color for web
      webPosition: "center", // Center the toast on web
      timeInSecForIosWeb: 2,
    );
  }

  Future<void> checkDistanceFromMarkers() async {
    final Position userPosition = await Geolocator.getCurrentPosition();
    const double radiusThreshold = 20.0;

    for (final Marker marker in _markers) {
      final LatLng markerPosition = marker.position;
      final double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        markerPosition.latitude,
        markerPosition.longitude,
      );

      if (distance <= radiusThreshold) {
        showPotholeAlert();
        return;
      }
    }
  }

  void startLocationUpdates() {
    const Duration checkInterval = Duration(seconds: 1);
    Timer.periodic(checkInterval, (timer) {
      checkDistanceFromMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        // Load and process Excel data here
        _loadAndProcessExcelData();
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(43.05129558, -76.14981),
        zoom: 16,
      ),
      markers: _markers,
    );
  }

  void _loadAndProcessExcelData() async {
    // Load your Excel data from a file (update 'file' with the path to your Excel file)
    var file =
        '/Users/vaibhavrajani/Desktop/FSS-Mobile-main 2/lib/data/cityline.xlsx';
    var bytes = File(file).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    // Assuming the Excel sheet has columns: "X" (latitude), "Y" (longitude), "Category"
    for (var table in excel.tables.keys) {
      for (var rowIndex = 0;
          rowIndex < excel.tables[table]!.maxRows;
          rowIndex++) {
        var row = excel.tables[table]!.rows[rowIndex];
        if (rowIndex == 0) {
          continue;
        }

        double? latitude = double.tryParse(row[0]!.value.toString());
        double? longitude = double.tryParse(row[1]!.value.toString());
        String category = row[2]!.value.toString();

        if (latitude != null && longitude != null && category == "Potholes") {
          // Add a red marker for "Pothole" GeoLocation
          _addMarker(LatLng(latitude, longitude));
        }
      }
    }
  }

  void _addMarker(LatLng position) {
    _markers.add(Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      icon: markerIcon,
      onTap: () {
        showPotholeAlert();
      },
    ));
  }
}
