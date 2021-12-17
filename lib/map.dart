import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class DownloadTileHalper{
  final double lat;
  final double lng; 
  final double rad;

  DownloadTileHalper({
    required this.lat,
    required this.lng,
    required this.rad
  });

  List<LatLng> circleToOutline({int circleDegrees = 360}) {
  double d = rad / 1.852 / 3437.670013352;

  final List<LatLng> output = [];
  for (int x = 0; x <= circleDegrees; x++) {
    double brng = x * math.pi / 180;
    final double latRadians = math.asin(math.sin(lat) * math.cos(d) +
        math.cos(lat) * math.sin(d) * math.cos(brng));
    final double lngRadians = lng +
        math.atan2(math.sin(brng) * math.sin(d) * math.cos(lat),
            math.cos(d) - math.sin(lat) * math.sin(latRadians));

    output.add(
      LatLng(
        latRadians * 180 / math.pi,
        (lngRadians * 180 / math.pi).clamp(-180, 180),
      ),
    );
  }

  return output;
}


  static List<Coords<num>> _circleTiles(
    List<LatLng> circleOutline,
    int minZoom,
    int maxZoom, {
    Crs crs = const Epsg3857(),
    CustomPoint<num> tileSize = const CustomPoint(256, 256),
  }) {
    final Map<int, Map<int, List<BigInt>>> outlineTileNums = {};

    final List<Coords<num>> coords = [];

    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = {};

      for (LatLng node in circleOutline) {
        /*
        The below code has been retained on purpose.
        DO NOT remove it.
        
        final double n = math.pow(2, zoomLvl).toDouble();
        final int x = ((node.longitude + 180.0) / 360.0 * n).toInt();
        final int y =
            ((1.0 - _asinh(math.tan(node.latitudeInRad)) / math.pi) / 2.0 * n)
                .toInt();
        */

        final CustomPoint<num> tile = crs
            .latLngToPoint(node, zoomLvl.toDouble())
            .unscaleBy(tileSize)
            .floor();

        if (outlineTileNums[zoomLvl]![tile.x.toInt()] == null) {
          outlineTileNums[zoomLvl]![tile.x.toInt()] = [
            BigInt.parse("999999999999999999"),
            BigInt.parse("-999999999999999999")
          ];
        }

        outlineTileNums[zoomLvl]![tile.x.toInt()] = [
          tile.y.toInt() < (outlineTileNums[zoomLvl]![tile.x.toInt()]![0].toInt())
              ? BigInt.from(tile.y.toInt())
              : (outlineTileNums[zoomLvl]![tile.x.toInt()]![0]),
          tile.y.toInt() > (outlineTileNums[zoomLvl]![tile.x.toInt()]![1].toInt())
              ? BigInt.from(tile.y.toInt())
              : (outlineTileNums[zoomLvl]![tile.x.toInt()]![1]),
        ];
      }

      for (int x in outlineTileNums[zoomLvl]!.keys) {
        for (int y = outlineTileNums[zoomLvl]![x]![0].toInt();
            y <= outlineTileNums[zoomLvl]![x]![1].toInt();
            y++) {
          coords.add(
            Coords(x.toDouble(), y.toDouble())..z = zoomLvl.toDouble(),
          );
        }
      }
    }

    return coords;
  }

  Future<void> _getAndSaveTile(
    Coords<num> coord,
    TileLayerOptions options,
    http.Client client,
    Function(String, dynamic) errorHandler,
    String cacheName
  ) async {
    String url = "";
    try {
      final coordDouble = Coords(coord.x.toDouble(), coord.y.toDouble())
        ..z = coord.z.toDouble();
      url = getTileUrl(coordDouble, options);
      print(url);
      final bytes = (await client.get(Uri.parse(url))).bodyBytes;
      await saveTile(
        bytes,
        coord,
        cacheName: cacheName,
      );
    } catch (e) {
      errorHandler(url, e);
    }
  }

   String getTileUrl(Coords coords, TileLayerOptions options) {
    var urlTemplate = (options.wmsOptions != null)
        ? options.wmsOptions!
            .getUrl(coords, options.tileSize.toInt(), options.retinaMode)
        : options.urlTemplate;

    var z = _getZoomForUrl(coords, options);

    var data = <String, String>{
      'x': coords.x.round().toString(),
      'y': coords.y.round().toString(),
      'z': z.round().toString(),
      's': getSubdomain(coords, options),
      'r': '@2x',
    };
    if (options.tms) {
      data['y'] = invertY(coords.y.round(), z.round()).toString();
    }

    var allOpts = Map<String, String>.from(data)
      ..addAll(options.additionalOptions);
    return options.templateFunction(urlTemplate!, allOpts);
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  String getSubdomain(Coords coords, TileLayerOptions options) {
    if (options.subdomains.isEmpty) {
      return '';
    }
    var index = (coords.x + coords.y).round() % options.subdomains.length;
    return options.subdomains[index];
  }

  double _getZoomForUrl(Coords coords, TileLayerOptions options) {
    var zoom = coords.z;

    if (options.zoomReverse) {
      zoom = options.maxZoom - zoom;
    }

    return zoom += options.zoomOffset;
  }


  static Future<void> saveTile(Uint8List tile, Coords coords,
      {String cacheName = 'mainCache'}) async {
        print("save tile");
  //   await (await _getInstance().database).insert(
  //       _kTilesTable,
  //       {
  //         _kZoomLevelColumn: coords.z,
  //         _kTileColumnColumn: coords.x,
  //         _kTileRowColumn: coords.y,
  //         _kUpdateDateColumn: (DateTime.now().millisecondsSinceEpoch ~/ 1000),
  //         _kTileDataColumn: tile,
  //         _kCacheNameColumn: cacheName
  //       },
  //       conflictAlgorithm: ConflictAlgorithm.replace);
  // }
    
    //save
}
}