import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:maps/map.dart';
import 'package:path_provider/path_provider.dart';

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
                  );
              tiles!.downloadMap();
            },
            child: const Text("Download Tiles")),
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
            child: const Text("Get all tiles")),
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MapView()));
            },
            child: const Text("Show map from download folder")),
            ElevatedButton(
            onPressed: () {
              tiles = DownloadTileHalper(
                  options: DownloadTileOptions(
                      southWest: LatLng(56.09962, 101.506805),
                      northEast: LatLng(56.206704, 101.729279) 
                      ),
                      // tileLayerOptions: TileLayerOptions(
                      //                       urlTemplate:"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      //                       subdomains: ['a', 'b', 'c'],
                      //                       attributionBuilder: (_) {
                      //                         return Text("© OpenStreetMap contributors");
                      //                       })
                        );
              tiles!.downloadMap();
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

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool mapFromCache = true;
  late String source;

  @override
  void initState() {
    getDownloadsDirectory().then((value) {
      setState(() {
        source = "${value!.path}\\_";
        print("SOURCE: $source");
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: mapFromCache
              ? const Text("Map from Provider")
              : const Text("Map from Cache"),
          actions: [
            Switch(
                value: mapFromCache,
                onChanged: (v) {
                  setState(() {
                    mapFromCache = v;
                  });
                })
          ],
        ),
        body: FlutterMap(
            options: MapOptions(
              center: LatLng(56.1325, 101.614),
            ),
            layers: [
              TileLayerOptions(
                  urlTemplate: mapFromCache || source == null
                      ? 'http://127.0.0.1:8000/services/world/tiles/{z}/{x}/{y}.png'
                      : source + "\\{z}\\{x}\\{y}.png",
                  tileProvider: mapFromCache ? ExteralTail() : InternalTail())
            ]));
  }
}

class InternalTail extends TileProvider {
  @override
  ImageProvider<Object> getImage(Coords<num> coords, TileLayerOptions options) {
    if (File(getTileUrl(coords, options)).existsSync()) {
      return FileImage(File(getTileUrl(coords, options)));
    } else {
      return const AssetImage("assets/blank_tile.png");
    }
  }
}

class ExteralTail extends TileProvider {
  @override
  ImageProvider<Object> getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(getTileUrl(coords, options));
  }
}
