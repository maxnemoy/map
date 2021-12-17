import 'package:flutter/material.dart';
//import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:maps/pages/animated_map_controller.dart';
// import 'package:maps/pages/circle.dart';
// import 'package:maps/pages/custom_crs/custom_crs.dart';
// import 'package:maps/pages/esri.dart';
// import 'package:maps/pages/home.dart';
// import 'package:maps/pages/interactive_test_page.dart';
// import 'package:maps/pages/live_location.dart';
// import 'package:maps/pages/many_markers.dart';
// import 'package:maps/pages/map_controller.dart';
// import 'package:maps/pages/map_inside_listview.dart';
// import 'package:maps/pages/marker_anchor.dart';
// import 'package:maps/pages/marker_rotate.dart';
// import 'package:maps/pages/moving_markers.dart';
// import 'package:maps/pages/network_tile_provider.dart';
// import 'package:maps/pages/offline_map.dart';
// import 'package:maps/pages/on_tap.dart';
// import 'package:maps/pages/overlay_image.dart';
// import 'package:maps/pages/plugin_api.dart';
// import 'package:maps/pages/plugin_scalebar.dart';
// import 'package:maps/pages/plugin_zoombuttons.dart';
// import 'package:maps/pages/polyline.dart';
// import 'package:maps/pages/reset_tile_layer.dart';
// import 'package:maps/pages/sliding_map.dart';
// import 'package:maps/pages/stateful_markers.dart';
// import 'package:maps/pages/tap_to_add.dart';
// import 'package:maps/pages/tile_builder_example.dart';
// import 'package:maps/pages/tile_loading_error_handle.dart';
// import 'package:maps/pages/widgets.dart';
// import 'package:maps/pages/wms_tile_layer.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FlutterMap(
      options: MapOptions(
        center: LatLng(56.1325, 101.614),
        zoom: 13.0,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "http://127.0.0.1:8000/services/world/tiles/{z}/{x}/{y}.png",
          //subdomains: ['a', 'b', 'c'],
          attributionBuilder: (_) {
            return Text("© maxnemoy map");
          },
        ),
        MarkerLayerOptions(
          markers: [
            Marker(
              width: 10.0,
              height: 10.0,
              point: LatLng(56.1325, 101.614),
              builder: (ctx) => Container(
                
                child: Container(width: 1, height: 1, color: Colors.red,),
              ),
            ),
          ],
        ),
      ],
    ));
  }
}



// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Map Example',
//       theme: ThemeData(
//         primarySwatch: mapBoxBlue,
//       ),
//       home: HomePage(),
//       routes: <String, WidgetBuilder>{
//         NetworkTileProviderPage.route: (context) => NetworkTileProviderPage(),
//         WidgetsPage.route: (context) => WidgetsPage(),
//         TapToAddPage.route: (context) => TapToAddPage(),
//         EsriPage.route: (context) => EsriPage(),
//         PolylinePage.route: (context) => PolylinePage(),
//         MapControllerPage.route: (context) => MapControllerPage(),
//         AnimatedMapControllerPage.route: (context) =>
//             AnimatedMapControllerPage(),
//         MarkerAnchorPage.route: (context) => MarkerAnchorPage(),
//         PluginPage.route: (context) => PluginPage(),
//         PluginScaleBar.route: (context) => PluginScaleBar(),
//         PluginZoomButtons.route: (context) => PluginZoomButtons(),
//         OfflineMapPage.route: (context) => OfflineMapPage(),
//         OnTapPage.route: (context) => OnTapPage(),
//         MarkerRotatePage.route: (context) => MarkerRotatePage(),
//         MovingMarkersPage.route: (context) => MovingMarkersPage(),
//         CirclePage.route: (context) => CirclePage(),
//         OverlayImagePage.route: (context) => OverlayImagePage(),
//         SlidingMapPage.route: (_) => SlidingMapPage(),
//         WMSLayerPage.route: (context) => WMSLayerPage(),
//         CustomCrsPage.route: (context) => CustomCrsPage(),
//         LiveLocationPage.route: (context) => LiveLocationPage(),
//         TileLoadingErrorHandle.route: (context) => TileLoadingErrorHandle(),
//         TileBuilderPage.route: (context) => TileBuilderPage(),
//         InteractiveTestPage.route: (context) => InteractiveTestPage(),
//         ManyMarkersPage.route: (context) => ManyMarkersPage(),
//         StatefulMarkersPage.route: (context) => StatefulMarkersPage(),
//         MapInsideListViewPage.route: (context) => MapInsideListViewPage(),
//         ResetTileLayerPage.route: (context) => ResetTileLayerPage(),
//       },
//     );
//   }
// }

// // Generated using Material Design Palette/Theme Generator
// // http://mcg.mbitson.com/
// // https://github.com/mbitson/mcg
// const int _bluePrimary = 0xFF395afa;
// const MaterialColor mapBoxBlue = MaterialColor(
//   _bluePrimary,
//   <int, Color>{
//     50: Color(0xFFE7EBFE),
//     100: Color(0xFFC4CEFE),
//     200: Color(0xFF9CADFD),
//     300: Color(0xFF748CFC),
//     400: Color(0xFF5773FB),
//     500: Color(_bluePrimary),
//     600: Color(0xFF3352F9),
//     700: Color(0xFF2C48F9),
//     800: Color(0xFF243FF8),
//     900: Color(0xFF172EF6),
//   },
// );