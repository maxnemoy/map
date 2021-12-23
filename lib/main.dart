import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:maps/map.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController latController = TextEditingController(text: "56.1325");
  TextEditingController lngController = TextEditingController(text: "101.614");
  TextEditingController zoomMin = TextEditingController(text: "8");
  TextEditingController zoomMax = TextEditingController(text: "10");
  TextEditingController widthController = TextEditingController(text: "10");
  TextEditingController heigthController = TextEditingController(text: "10");
  List<int> zooms = [1, 2, 3, 4, 5];
  DownloadTileHalper? tiles;

  List<String> urlsList = [];
  List<TileInfo> tilesList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        TextField(
          controller: latController,
          decoration: const InputDecoration(label: Text("LTD")),
        ),
        TextField(
          controller: lngController,
          decoration: const InputDecoration(label: Text("LNG")),
        ),
        TextField(
          controller: widthController,
          decoration: const InputDecoration(label: Text("Width")),
        ),
        TextField(
          controller: heigthController,
          decoration: const InputDecoration(label: Text("Heigth")),
        ),
        TextField(
          controller: zoomMin,
          decoration: const InputDecoration(label: Text("Zoom min")),
        ),
        TextField(
          controller: zoomMax,
          decoration: const InputDecoration(label: Text("Zoom Max")),
        ),
        ElevatedButton(
            onPressed: () {
              tiles = DownloadTileHalper(
                  options: DownloadTileOptions(
                      lat: double.parse(latController.text),
                      lng: double.parse(lngController.text),
                      width: double.parse(widthController.text),
                      heigth: double.parse(heigthController.text),
                      zoomMin: int.parse(zoomMin.text),
                      zoomMax: int.parse(zoomMax.text)),
                      tileLayerOptions: TileLayerOptions(
                                            urlTemplate:"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                            subdomains: ['a', 'b', 'c'],
                                            attributionBuilder: (_) {
                                              return Text("© OpenStreetMap contributors");
                                            })
                        );
              setState(() {
                urlsList = tiles!.getTilesUrls;
                tilesList = tiles!.getTilesAddress;
              });
            },
            child: const Text("Get all tiles from center/h/w")),
                        ElevatedButton(
            onPressed: () {
              tiles = DownloadTileHalper(
                  options: DownloadTileOptions(
                      zoomMax: 10,
                      zoomMin: 10,
                      southWest: LatLng(20.09962, 101.506805),
                      northEast: LatLng(56.206704, 101.729279) 
                      ),
                      // tileLayerOptions: TileLayerOptions(
                      //                       urlTemplate:"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      //                       subdomains: ['a', 'b', 'c'],
                      //                       attributionBuilder: (_) {
                      //                         return Text("© OpenStreetMap contributors");
                      //                       })
                        );
              setState(() {
                urlsList = tiles!.getTilesUrls;
                tilesList = tiles!.getTilesAddress;
              });
            },
            child: const Text("Get all tiles from sw/ne")),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text("TILES"),
                    Expanded(
                        child: ListView(
                      children: tilesList
                          .map((element) => ListTile(
                                title: Text(element.toString()),
                              ))
                          .toList(),
                    ))
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text("URLS"),
                    Expanded(
                        child: ListView(
                      children: urlsList
                          .map((element) => ListTile(
                                title: Text(element.toString()),
                              ))
                          .toList(),
                    ))
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    ));
  }
}