import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadTileOptions {
  /// Center point Latitude
  final double? lat;

  /// Center poit Longitude
  final double? lng;

  /// Area widht(km)
  final double? width;

  /// Area heigth(km)
  final double? heigth;

  /// Minimum zoom
  final int zoomMin;

  /// Maximum Zoom
  final int zoomMax;

  /// Tile size (default 256)
  final int tileSize;

  /// South-West area point
  final LatLng? southWest;

  /// North-East area point
  final LatLng? northEast;

  final Size? mapEmbedSize;
  final MapSizeRatio mapSizeRatio;

  late RectangleRegion region;

  DownloadTileOptions(
      {this.lat,
      this.lng,
      this.width,
      this.heigth,
      this.zoomMin = 9,
      this.zoomMax = 10,
      this.tileSize = 256,
      this.southWest,
      this.northEast,
      this.mapEmbedSize,
      MapSizeRatio? mapSizeRatio}) : mapSizeRatio = mapSizeRatio ?? MapSizeRatio() {
        if (buildFromPoints) {
            region = RectangleRegion(
                LatLngBounds.fromPoints([southWest!, northEast!]));
        } else {
          region = RectangleRegion.fromSize(
              LatLng(lat!, lng!), width!, heigth!);
        }
      }

  bool get buildFromPoints => southWest != null && northEast != null;
}

class MapSizeRatio{
  final double widthRatio;
  final double heightRatio;

  MapSizeRatio({this.heightRatio = 1, this.widthRatio = 1});
}

class DownloadTileHalper {
  final DownloadTileOptions options;

  final TileLayerOptions _tileLayerOptions;

  DownloadTileHalper(
      {required this.options, TileLayerOptions? tileLayerOptions})
      : _tileLayerOptions = tileLayerOptions ??
            TileLayerOptions(
              urlTemplate:
                  "http://127.0.0.1:8000/services/world/tiles/{z}/{x}/{y}.png",
            );

  void downloadMap() {
    List<Coords> coords = _getCoordinats();
    for (Coords element in coords) {
      _getAndSaveTile(element, _tileLayerOptions, http.Client(), (e, s) {});
    }
  }

  List<TileInfo> get getTilesAddress => _getCoordinats().map<TileInfo>((element) {
      List<String> address = _getTileUrl(element, _tileLayerOptions).split("/");
      return TileInfo(
          z: address[address.length - 3],
          x: address[address.length - 2],
          y: address[address.length - 1]);
    }).toList();
  

  List<String> get getTilesUrls => _getCoordinats().map<String>((element) {
      return _getTileUrl(element, _tileLayerOptions);
    }).toList();

  List<Coords> _getCoordinats() => _rectangleTiles({
      'bounds': options.region.bounds,
      "minZoom": options.zoomMin,
      "maxZoom": options.zoomMax,
      "crs": const Epsg3857(),
      "tileSize": CustomPoint(options.tileSize, options.tileSize)
    });

  LatLngBounds _embedMapInArea(double zoom){
    final double halfScreenHeight = _calculateScreenHeightInDegrees(zoom) / options.mapSizeRatio.heightRatio;
    final double halfScreenWidth = _calculateScreenWidthInDegrees(zoom) / options.mapSizeRatio.widthRatio;
    final area = 
      LatLngBounds(LatLng(
        (options.region.bounds.southWest!.latitude + halfScreenHeight).clamp(-90, 90),
        (options.region.bounds.southWest!.longitude + halfScreenWidth).clamp(-180, 180),
      ),
      LatLng(
        (options.region.bounds.northEast!.latitude - halfScreenHeight).clamp(-90, 90),
        (options.region.bounds.northEast!.longitude - halfScreenWidth).clamp(-180, 180),
      ));
    return area;
  }

  List<Coords<num>> _rectangleTiles(Map<String, dynamic> input) {
    LatLngBounds bounds = input['bounds'];
    final int minZoom = input['minZoom'];
    final int maxZoom = input['maxZoom'];
    final Crs crs = input['crs'];
    final CustomPoint<num> tileSize = input['tileSize'];

    final coords = <Coords<num>>[];
    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      if(options.mapEmbedSize != null){
        bounds = _embedMapInArea(zoomLvl.toDouble());
      }
      final nwCustomPoint = crs
          .latLngToPoint(bounds.northWest, zoomLvl.toDouble())
          .unscaleBy(tileSize)
          .floor();
      final seCustomPoint = crs
              .latLngToPoint(bounds.southEast, zoomLvl.toDouble())
              .unscaleBy(tileSize)
              .ceil() -
          CustomPoint(1, 1);
      for (num x = nwCustomPoint.x; x <= seCustomPoint.x; x++) {
        for (num y = nwCustomPoint.y; y <= seCustomPoint.y; y++) {
          coords.add(Coords(x, y)..z = zoomLvl);
        }
      }
    }
    return coords;
  }

  String _getTileUrl(Coords<num> coord, TileLayerOptions options) {
    final coordDouble = Coords(coord.x.toDouble(), coord.y.toDouble())
      ..z = coord.z.toDouble();
    return getTileUrl(coordDouble, options);
  }

  Future<void> _getAndSaveTile(Coords<num> coord, TileLayerOptions options,
      http.Client client, Function(String, dynamic) errorHandler) async {
    String url = "";
    try {
      final coordDouble = Coords(coord.x.toDouble(), coord.y.toDouble())
        ..z = coord.z.toDouble();
      url = getTileUrl(coordDouble, options);
      final bytes = (await client.get(Uri.parse(url))).bodyBytes;

      await saveTile(
        bytes,
        coord,
        cacheName: url,
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
    final directory = await getDownloadsDirectory();
    Uri u = Uri.parse(cacheName);
    var l = u.pathSegments.length;
    String zoom = u.pathSegments[l - 3];
    String x = u.pathSegments[l - 2];
    String y = u.pathSegments[l - 1];

    Directory zoomDir =
        Directory("${directory!.path}\\_\\$zoom\\$x");
    await zoomDir.create(recursive: true);

    File file = File("${directory.path}\\_\\$zoom\\$x\\$y");
    file.writeAsBytes(tile);
  }

  double _calculateScreenWidthInDegrees(double zoom) {
    final degreesPerPixel = 360 / math.pow(2, zoom + 8);
    return options.mapEmbedSize!.width * degreesPerPixel;
  }

  double _calculateScreenHeightInDegrees(double zoom) =>
      options.mapEmbedSize!.height * 170.102258 / math.pow(2, zoom + 8);
}

class RectangleRegion {
  late LatLngBounds bounds;

  RectangleRegion(this.bounds);

  RectangleRegion.fromSize(LatLng centerPoint, double width, double height) {    
    var lat1 = (centerPoint.latitude + (height / 2 / 6356) * (180 / pi)).clamp(-90.0, 90.0);
    var long1 = (centerPoint.longitude + (width / 2 / 6356) * (180 / pi)/ 
            math.cos(lat1 * pi / 180)).clamp(-180.0, 180.0);
    
    var lat2 = (centerPoint.latitude - (height / 2 / 6356) * (180 / pi)).clamp(-90.0, 90.0);
    var long2 = (centerPoint.longitude -
        (width / 2 / 6356) *
            (180 / pi) /
            math.cos(lat2 * pi / 180)).clamp(-180.0, 180.0);

    bounds = LatLngBounds.fromPoints([
      LatLng(lat1, long1),
      LatLng(lat2, long2),
    ]);
  }
}

class TileInfo {
  final String z;
  final String x;
  final String y;

  TileInfo({required this.z, required this.x, required this.y});

  @override
  String toString() {
    return "/$z/$x/$y";
  }
}