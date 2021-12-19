import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadTileHalper {
  final double lat;
  final double lng;
  final double rad;
  final int zoomMin;
  final int zoomMax;
  final String urlTemplate;
  final int tileSize;

  DownloadTileHalper(
      {required this.lat,
      required this.lng,
      required this.rad,
      this.zoomMin = 5,
      this.zoomMax = 10,
      this.tileSize = 256,
      this.urlTemplate =
          "http://127.0.0.1:8000/services/world/tiles/{z}/{x}/{y}.png"});

  void getMap() {
    print("MAP GET: \nLat: $lat  \nLng: $lng \nR: $rad");
    var rig = CircleRegion(LatLng(lat, lng), rad);
    List<LatLng> list = rig.toList();
    List<Coords> coords = rectangleTiles({
      //'circleOutline': list,
      'bounds': LatLngBounds.fromPoints(list),
      "minZoom": zoomMin,
      "maxZoom": zoomMax,
      "crs": const Epsg3857(),
      "tileSize": CustomPoint(tileSize, tileSize)
    });
    print(coords.length);
    coords.forEach((element) => _getAndSaveTile(
            element,
            TileLayerOptions(
              urlTemplate: urlTemplate,
              //subdomains: null
              // urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              // subdomains: ['a', 'b', 'c'],
            ),
            http.Client(), (e, s) {
          print(s);
        }, "someName"));
  }


  List<String> getTilesAddress(){
    List<String> tiles = [];
    print("MAP GET: \nLat: $lat  \nLng: $lng \nR: $rad");
    var rig = CircleRegion(LatLng(lat, lng), rad);
    List<LatLng> list = rig.toList();
    List<Coords> coords = rectangleTiles({
      //'circleOutline': list,
      'bounds': LatLngBounds.fromPoints(list),
      "minZoom": zoomMin,
      "maxZoom": zoomMax,
      "crs": const Epsg3857(),
      "tileSize": CustomPoint(tileSize, tileSize)
    });
    print(coords.length);
    coords.forEach((element) { 
     String address = _getTileUrl(element, TileLayerOptions(  urlTemplate: urlTemplate,
              //subdomains: null
              // urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              // subdomains: ['a', 'b', 'c'],
            ));
            tiles.add(address);
            
            });
      
    return tiles;
  }


  List<Coords<num>> rectangleTiles(Map<String, dynamic> input) {
    final LatLngBounds bounds = input['bounds'];
    final int minZoom = input['minZoom'];
    final int maxZoom = input['maxZoom'];
    final Crs crs = input['crs'];
    final CustomPoint<num> tileSize = input['tileSize'];

    final coords = <Coords<num>>[];
    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
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

  static List<Coords<num>> _getCoords(Map<String, dynamic> input) {
    final List<LatLng> circleOutline = input['circleOutline'];
    final int minZoom = input['minZoom'];
    final int maxZoom = input['maxZoom'];
    final Crs crs = input['crs'];
    final CustomPoint<num> tileSize = input['tileSize'];

    final Map<int, Map<int, List<int>>> outlineTileNums = {};

    final List<Coords<num>> coords = [];

    for (int zoomLvl = minZoom; zoomLvl <= maxZoom; zoomLvl++) {
      outlineTileNums[zoomLvl] = {};

      for (LatLng node in circleOutline) {
        final tile = crs
            .latLngToPoint(node, zoomLvl.toDouble())
            .unscaleBy(tileSize)
            .floor();

        outlineTileNums[zoomLvl]![tile.x.toInt()] ??= [
          1000000000000,
          -1000000000000
        ];

        outlineTileNums[zoomLvl]![tile.x.toInt()] = [
          tile.y < outlineTileNums[zoomLvl]![tile.x.toInt()]![0]
              ? tile.y.toInt()
              : outlineTileNums[zoomLvl]![tile.x.toInt()]![0],
          tile.y > outlineTileNums[zoomLvl]![tile.x.toInt()]![1]
              ? tile.y.toInt()
              : outlineTileNums[zoomLvl]![tile.x.toInt()]![1],
        ];
      }

      for (int x in outlineTileNums[zoomLvl]!.keys) {
        for (int y = outlineTileNums[zoomLvl]![x]![0];
            y <= outlineTileNums[zoomLvl]![x]![1];
            y++) {
          coords
              .add(Coords(x.toDouble(), y.toDouble())..z = zoomLvl.toDouble());
        }
      }
    }

    return coords;
  }

    String _getTileUrl(Coords<num> coord,   TileLayerOptions options)  {
      final coordDouble = Coords(coord.x.toDouble(), coord.y.toDouble())
        ..z = coord.z.toDouble();
      return getTileUrl(coordDouble, options);
  }

  Future<void> _getAndSaveTile(
      Coords<num> coord,
      TileLayerOptions options,
      http.Client client,
      Function(String, dynamic) errorHandler,
      String cacheName) async {
    String url = "";
    try {
      print("COORD ${coord}");
      final coordDouble = Coords(coord.x.toDouble(), coord.y.toDouble())
        ..z = coord.z.toDouble();
      url = getTileUrl(coordDouble, options);
      print(url);
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
    print(u.pathSegments);
    var l = u.pathSegments.length;
    String zoom = u.pathSegments[l - 3];
    String x = u.pathSegments[l - 2];
    String y = u.pathSegments[l - 1];
    // Directory zoomDir = Directory("${directory!.path}\\_\\$zoom");
    // zoomDir.exists().then((value) {
    //   if (!value)
    //     zoomDir.create().then((_) {
    //       return;
    //     });
    // });

    // Directory xDir = Directory("${directory.path}\\_\\$zoom\\$x");
    // xDir.exists().then((value) {
    //   if (!value)
    //     xDir.create().then((_) {
    //       return;
    //     });
    // });
    Directory zoomDir = Directory("${directory!.path}\\_\\mainStore\\$zoom\\$x");
    await zoomDir.create(recursive: true);

    File file = File("${directory.path}\\_\\mainStore\\$zoom\\$x\\$y");
    file.writeAsBytes(tile);
  }
}

class DownloadableRegion {
  /// The shape that this region conforms to
  final RegionType type;

  /// The original `BaseRegion`, used internally for recovery purposes
  final BaseRegion originalRegion;

  /// All the verticies on the outline of a polygon
  final List<LatLng> points;

  /// The minimum zoom level to fetch tiles for
  final int minZoom;

  /// The maximum zoom level to fetch tiles for
  final int maxZoom;

  /// The options used to fetch tiles
  final TileLayerOptions options;

  /// The number of download threads allowed to run simultaneously
  ///
  /// This will significatly increase speed, at the expense of faster battery drain. Note that some servers may forbid multithreading, in which case this should be set to 1.
  ///
  /// Set to 1 to disable multithreading. Defaults to 10.
  final int parallelThreads;

  /// Whether to skip downloading tiles that already exist
  ///
  /// Defaults to `false`, so that existing tiles will be updated.
  final bool preventRedownload;

  /// Whether to remove tiles that are entirely sea
  ///
  /// The checks are conducted by comparing the bytes of the tile at x:0, y:0, and z:19 to the bytes of the currently downloading tile. If they match, the tile is deleted, otherwise the tile is kept.
  ///
  /// This option is therefore not supported when using satelite tiles (because of the variations from tile to tile), on maps where the tile 0/0/19 is not entirely sea, or on servers where zoom level 19 is not supported. If not supported, set this to `false` to avoid wasting unnecessary time and to avoid errors.
  ///
  /// This is a storage saving feature, not a time saving or data saving feature: tiles still have to be fully downloaded before they can be checked.
  ///
  /// Set to `false` to keep sea tiles, which is the default.
  final bool seaTileRemoval;

  /// The map projection to use to calculate tiles. Defaults to `Espg3857()`.
  final Crs crs;

  /// A function that takes any type of error as an argument to be called in the event a tile fetch fails
  final Function(dynamic)? errorHandler;

  /// Avoid construction using this method. Use [BaseRegion.toDownloadable] to generate [DownloadableRegion]s from other regions.
  DownloadableRegion.internal(
    this.points,
    this.minZoom,
    this.maxZoom,
    this.options,
    this.type,
    this.originalRegion, {
    this.parallelThreads = 10,
    this.preventRedownload = false,
    this.seaTileRemoval = false,
    this.crs = const Epsg3857(),
    this.errorHandler,
  })  : assert(
          minZoom <= maxZoom,
          '`minZoom` should be less than or equal to `maxZoom`',
        ),
        assert(
          parallelThreads >= 1,
          '`parallelThreads` should be more than or equal to 1. Set to 1 to disable multithreading',
        );
}

enum RegionType {
  /// A region containing 2 points representing the top-left and bottom-right corners of a rectangle
  rectangle,

  /// A region containing all the points along it's outline (one every degree) representing a circle
  circle,

  /// A region with the border as the loci of a line at it's center representing multiple diagonal rectangles
  line,
}

abstract class BaseRegion {
  /// Create a downloadable region out of this region
  ///
  /// Returns a [DownloadableRegion] to be passed to the `StorageCachingTileProvider().downloadRegion()`, `StorageCachingTileProvider().downloadRegionBackground()`, or `StorageCachingTileProvider().checkRegion()` function.
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    bool preventRedownload = false,
    bool seaTileRemoval,
    Crs crs = const Epsg3857(),
    Function(dynamic)? errorHandler,
  });

  /// Create a list of all the `LatLng`s along the outline of this region
  ///
  /// Not supported on line regions: use `toOutlines()` instead.
  ///
  /// Returns a `List<LatLng>` which can be used anywhere.
  List<LatLng> toList();
}

class CircleRegion extends BaseRegion {
  /// The center of the circle as a `LatLng`
  final LatLng center;

  /// The radius of the circle as a `double` in km
  final double radius;

  /// Creates a circular region using a center point and a radius
  CircleRegion(this.center, this.radius);

  @override
  DownloadableRegion toDownloadable(
    int minZoom,
    int maxZoom,
    TileLayerOptions options, {
    int parallelThreads = 10,
    bool preventRedownload = false,
    bool seaTileRemoval = false,
    Crs crs = const Epsg3857(),
    Function(dynamic)? errorHandler,
  }) {
    return DownloadableRegion.internal(
      toList(),
      minZoom,
      maxZoom,
      options,
      RegionType.circle,
      this,
      parallelThreads: parallelThreads,
      preventRedownload: preventRedownload,
      seaTileRemoval: seaTileRemoval,
      crs: crs,
      errorHandler: errorHandler,
    );
  }

  @override
  List<LatLng> toList() {
    final double rad = radius / 1.852 / 3437.670013352;
    final double lat = center.latitudeInRad;
    final double lon = center.longitudeInRad;
    final List<LatLng> output = [];

    for (int x = 0; x <= 360; x++) {
      final double brng = x * math.pi / 180;
      final double latRadians = math.asin(
        math.sin(lat) * math.cos(rad) +
            math.cos(lat) * math.sin(rad) * math.cos(brng),
      );
      final double lngRadians = lon +
          math.atan2(
            math.sin(brng) * math.sin(rad) * math.cos(lat),
            math.cos(rad) - math.sin(lat) * math.sin(latRadians),
          );

      output.add(
        LatLng(
          latRadians * 180 / math.pi,
          (lngRadians * 180 / math.pi)
              .clamp(-180, 180), // Clamped to fix errors with flutter_map
        ),
      );
    }

    return output;
  }
}
