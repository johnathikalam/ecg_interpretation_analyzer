import 'dart:io';
import 'dart:ui' as ui;
import 'package:ecg_analyzer/Screens/scatter_graph_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pick_color/pick_color.dart';

import '../Services/image_converter.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  File? imageFile;
  Offset point1 = const Offset(50, 250);
  Offset point2 = const Offset(50, 50);
  Offset point3 = const Offset(100, 320);
  Offset point4 = const Offset(550, 320);
  PickerResponse? userResponse;
  bool isColorPickerVisible = false;
  TextEditingController x1Controller = TextEditingController();
  TextEditingController x2Controller = TextEditingController();
  TextEditingController y1Controller = TextEditingController();
  TextEditingController y2Controller = TextEditingController();
  Size? imageSize;
  var containerSize;
  int? selectedPointIndex;
  double scaleX = 1;
  double scaleY = 1;
  List<Color> dominantColors = [];
  // bool isImageLoaded = false;

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        imageFile = File(image.path);
        // isImageLoaded = true;
      });
      _getImageDominantColors(imageFile!);
      var decodedImage = await decodeImageFromList(imageFile!.readAsBytesSync());
      imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      if (kDebugMode) {
        print("Image width .....................................${imageSize!.width}");
        print("Image height ....................................${imageSize!.height}");
      }

      containerSize = Size(MediaQuery.sizeOf(context).width * 0.8, MediaQuery.sizeOf(context).height);

      if (mounted) {
        setState(() {
          // Calculate scale factors
          scaleX = decodedImage.width / (MediaQuery.of(context).size.width * 0.8);
          scaleY = decodedImage.height / MediaQuery.of(context).size.height;
        });
      }
      // Calculate scale factors
      // scaleX = imageSize!.width / containerSize.width;
      // scaleY = imageSize!.height / containerSize.height;
      if (kDebugMode) {
        print("scaleX : $scaleX");
        print("scaleY : $scaleY");
        print("imageWidth : ${imageSize!.width}");
        print("imageHeight : ${imageSize!.height}");
        print("containerSize.width : $containerSize.width");
        print("containerSize.height : $containerSize.height");
      }
    }
    const snackBar = SnackBar(
      backgroundColor: Colors.blue,
      content: Text(
        "Use four draggable red points to calibrate the X and Y axes ",
        style: TextStyle(color: Colors.white),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void updatePosition(Offset newPosition, int pointIndex) {
    setState(() {
      switch (pointIndex) {
        case 1:
          point1 = newPosition;
          break;
        case 2:
          point2 = newPosition;
          break;
        case 3:
          point3 = newPosition;
          break;
        case 4:
          point4 = newPosition;
          break;
      }
    });
  }

  Future<void> _getImageDominantColors(imagePath) async {
    // Load the image from assets
    // final ByteData imageData = await rootBundle.load(imagePath);
    var bytes = await imagePath.readAsBytes();
    // final Uint8List bytes = imagePath.buffer.asUint8List();

    // Decode the image to get ui.Image
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    // Get the pixel data
    final ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    // Extract pixel data and find dominant colors
    final Uint8List pixelData = byteData.buffer.asUint8List();
    final Map<int, int> colorCountMap = {};

    // Analyze the pixel data in RGBA format
    for (int i = 0; i < pixelData.length; i += 4) {
      int red = pixelData[i];
      int green = pixelData[i + 1];
      int blue = pixelData[i + 2];
      int alpha = pixelData[i + 3];

      // Only consider fully opaque pixels
      if (alpha == 255) {
        int colorValue = (red << 16) | (green << 8) | blue;

        // Count how often each color appears
        if (colorCountMap.containsKey(colorValue)) {
          colorCountMap[colorValue] = colorCountMap[colorValue]! + 1;
        } else {
          colorCountMap[colorValue] = 1;
        }
      }
    }

    // Sort colors by frequency
    final List<MapEntry<int, int>> sortedColors = colorCountMap.entries.toList();
    sortedColors.sort((a, b) => b.value.compareTo(a.value));


    // Convert the top 5 dominant colors to Color objects
    List<Color> extractedColors = sortedColors.take(5).map((entry) {
      int colorValue = entry.key;
      return Color((0xFF << 24) | colorValue);
    }).toList();

    setState(() {
      dominantColors = extractedColors;
    });
    print("dominantColors : $dominantColors");
  }

  @override
  void initState() {
    super.initState();
    pickImageFromGallery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title:Center(child:Text("Image Convertor"))),
      body: imageFile == null
          ? Center(
        child: GestureDetector(
          onTap: pickImageFromGallery,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text("Upload Image"),
          ),
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  Container(
                    color: Colors.blue,
                    width: MediaQuery.sizeOf(context).width*.8,
                      height: MediaQuery.sizeOf(context).height,
                      child: Image.file(imageFile!,
                        fit: BoxFit.fitWidth,
                          )),
                  buildDraggablePoint(point1, 1),
                  buildDraggablePoint(point2, 2),
                  buildDraggablePoint(point3, 3),
                  buildDraggablePoint(point4, 4),
                  if (isColorPickerVisible)
                    Positioned.fill(
                      child: buildColorPicker(),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text('Coordinates', style: TextStyle(fontSize: 18)),
                  Text('x1: ${(point3.dx*scaleX).toStringAsFixed(2)}, ${(point3.dy*scaleY).toStringAsFixed(2)}'),
                  Text('x2: ${(point4.dx*scaleX).toStringAsFixed(2)}, ${(point4.dy*scaleY).toStringAsFixed(2)}'),
                  Text('y1: ${(point1.dx*scaleX).toStringAsFixed(2)}, ${(point1.dy*scaleY).toStringAsFixed(2)}'),
                  Text('y2: ${(point2.dx*scaleX).toStringAsFixed(2)}, ${(point2.dy*scaleY).toStringAsFixed(2)}'),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: TextFormField(
                          controller: x1Controller,
                          decoration: const InputDecoration(
                            hintText: "X1",
                            hintStyle: TextStyle(fontSize: 13),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10,),
                      SizedBox(
                        width: 50,
                        child: TextFormField(
                          controller: x2Controller,
                          decoration: const InputDecoration(
                            hintText: "X2",
                            hintStyle: TextStyle(fontSize: 13),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: TextFormField(
                          controller: y1Controller,
                          decoration: const InputDecoration(
                            hintText: "Y1",
                            hintStyle: TextStyle(fontSize: 13),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10,),
                      SizedBox(
                        width: 50,
                        child: TextFormField(
                          controller: y2Controller,
                          decoration: const InputDecoration(
                            hintText: "Y2",
                            hintStyle: TextStyle(fontSize: 13),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: dominantColors
                        .map((color) => GestureDetector(
                      onTap: () {
                        int red = color.red;
                        int green = color.green;
                        int blue = color.blue;
                        String hexCode = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

                        userResponse = PickerResponse(color, red, green, blue, hexCode, 0.0, 0.0,);
                        setState(() {});
                        print("Selected color: $color");
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 3.5),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: color,
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(5)
                        ),
                      ),
                    ),
                    ).toList(),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Text(
                        "Selected Color: ",
                        style: TextStyle(
                            color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isColorPickerVisible = !isColorPickerVisible;
                          });
                          const snackBar = SnackBar(
                            backgroundColor: Colors.blue,
                            content: Text(
                              "Please pick the color from the image",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: userResponse?.selectionColor ?? Colors.red,
                              border: Border.all(color: Colors.black, width: 1),
                              borderRadius: BorderRadius.circular(5)),
                        ),
                      )
                    ],
                  ),
                  Text("Hex Code: ${userResponse?.hexCode ?? "#ff0000"}",
                      style: const TextStyle(
                          color: Colors.black)),
                  // isColorPickerVisible?
                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.grey,
                  //   ),
                  //   onPressed: () {
                  //     setState(() {
                  //       isColorPickerVisible = !isColorPickerVisible;
                  //     });
                  //     },
                  //   child: const Text("Done",style: TextStyle(color: Colors.white),),
                  // ):Container(),
                  const SizedBox(height: 5),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () async {
                      if (x1Controller.text.isNotEmpty && x2Controller.text.isNotEmpty && y1Controller.text.isNotEmpty && y2Controller.text.isNotEmpty) {

                        if (kDebugMode) {
                          print(
                              'x1: ${(point3.dx*scaleX).toStringAsFixed(2)}, ${(point3.dy*scaleY)
                                  .toStringAsFixed(2)}');
                          print(
                              'x2: ${(point4.dx*scaleX).toStringAsFixed(2)}, ${(point4.dy*scaleY)
                                  .toStringAsFixed(2)}');
                          print(
                              'y1: ${(point1.dx*scaleX).toStringAsFixed(2)}, ${(point1.dy*scaleY)
                                  .toStringAsFixed(2)}');
                          print(
                              'y2: ${(point2.dx*scaleX).toStringAsFixed(2)}, ${(point2.dy*scaleY)
                                  .toStringAsFixed(2)}');
                          print('X - Axis: ${x1Controller.text} - ${x2Controller
                              .text}');
                          print('Y - Axis: ${y1Controller.text} - ${y2Controller
                              .text}');
                          print(
                              'hexa code : ${userResponse?.hexCode ??
                                  "#ff0000"}');
                        }

                        final data = await image_converter(
                            imageFile!,
                            userResponse?.hexCode,
                            [point3.dx*scaleX, point4.dx*scaleX, point1.dx*scaleX, point2.dx*scaleX],
                            [point3.dy*scaleY, point4.dy*scaleY, point1.dy*scaleY, point2.dy*scaleY],
                            [x1Controller.text,
                              y1Controller.text,
                              x2Controller.text,
                              y1Controller.text,
                              x1Controller.text,
                              y1Controller.text,
                              x2Controller.text,
                              y2Controller.text
                            ]);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ScatterGraphScreen(data)));
                      }
                      else{
                        const snackBar = SnackBar(
                          backgroundColor: Colors.blue,
                          content: Text(
                            "Please fill all the necessary fields",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                      // image_converter(imageFile!);
                    },
                    child: const Text("Continue",style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
              const SizedBox(width: 10),
            ],
          ),
    );
  }

  Widget buildDraggablePoint(Offset position, int pointIndex) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          updatePosition(
            Offset(position.dx + details.delta.dx * 3, position.dy + details.delta.dy * 3),
            pointIndex,
          );
        },
        onTap: () {
          setState(() {
            selectedPointIndex = pointIndex;
          });
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
           Padding(
             padding: const EdgeInsets.only(left: 25, top: 25),
             child: Text(
               pointIndex==4?'x2'
                   :pointIndex==3?'x1'
                   :'y$pointIndex',
               style: TextStyle(
                   color: pointIndex==4 ? Colors.green:
                   pointIndex==3 ? Colors.green:
                   Colors.blue,
                   fontWeight: FontWeight.w500),
             ),
           ),const SizedBox(width: 50,height: 50,),
          ],
        ),
      ),
    );
  }

  Widget buildColorPicker() {
    return ColorPicker(
      showMarker: false,
      onChanged: (response) {
        setState(() {
          userResponse = response;
        });
      },
      child: SizedBox(
          width:MediaQuery.sizeOf(context).width*.8,
          height: MediaQuery.sizeOf(context).height,
          child: Image.file(imageFile!,fit: BoxFit.fitWidth,)),
    );
  }
  // Future<void> _showMyDialog(BuildContext context) async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false, // User must tap a button to close the dialog
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Data to Transfer'),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Image.file(imageFile!),
  //               const SizedBox(height: 10,),
  //               Text('x1: ${point3.dx.toStringAsFixed(2)}, ${point3.dy.toStringAsFixed(2)}',style: GoogleFonts.lato(),),
  //               Text('x2: ${point4.dx.toStringAsFixed(2)}, ${point4.dy.toStringAsFixed(2)}',style: GoogleFonts.lato(),),
  //               Text('y1: ${point1.dx.toStringAsFixed(2)}, ${point1.dy.toStringAsFixed(2)}',style: GoogleFonts.lato(),),
  //               Text('y2: ${point2.dx.toStringAsFixed(2)}, ${point2.dy.toStringAsFixed(2)}',style: GoogleFonts.lato(),),
  //               const SizedBox(height: 10,),
  //               Text('X - Axis: ${x1Controller.text} - ${x2Controller.text}',style: GoogleFonts.lato(),),
  //               Text('Y - Axis: ${y1Controller.text} - ${y2Controller.text}',style: GoogleFonts.lato(),),
  //               const SizedBox(height: 10,),
  //               Row(
  //                 children: [
  //                   Text('hexa code : ${userResponse?.hexCode ?? "#ff0000"}',style: GoogleFonts.lato(),),
  //                   const SizedBox(width: 10,),
  //                   Container(
  //                     width: 20,
  //                     height: 20,
  //                     decoration: BoxDecoration(
  //                         color: userResponse?.selectionColor ?? Colors.red,
  //                         border: Border.all(color: Colors.black, width: 1),
  //                         borderRadius: BorderRadius.circular(5)),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('OK'),
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Closes the dialog
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

}
