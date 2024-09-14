import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PlaceholderRedacted extends StatelessWidget {
  const PlaceholderRedacted({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define item dimensions and aspect ratio
        double itemWidth = 350;
        double itemHeight = 142;
        double aspectRatio = itemWidth / itemHeight;

        // Calculate the number of columns and rows based on available width and height
        double totalWidth = constraints.maxWidth;
        double totalHeight = constraints.maxHeight;

        // Padding around the grid
        double padding = 0;
        int columnCount = ((totalWidth - 2 * padding) / itemWidth).floor();

        // Ensure at least 1 column
        columnCount = columnCount > 0 ? columnCount : 1;

        // Calculate the number of rows that fit within the available height
        double rowHeight = itemHeight + padding;
        int rowCount = ((totalHeight - 2 * padding) / rowHeight).floor();

        // Ensure at least 1 row
        rowCount = rowCount > 0 ? rowCount : 1;

        // Total item count
        int itemCount = columnCount * rowCount;

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount, // Number of columns
            childAspectRatio: aspectRatio, // Maintain item aspect ratio
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Container(
              width: itemWidth,
              height: itemHeight,
              margin: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.black12,
                    highlightColor: Colors.white,
                    child: Container(
                      width: 134,
                      height: 142,
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 142,
                      width: 206,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Shimmer.fromColors(
                            baseColor: Colors.black12,
                            highlightColor: Colors.white,
                            child: Container(
                              height: 20,
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                            ),
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.black12,
                            highlightColor: Colors.white,
                            child: Container(
                              height: 50,
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                            ),
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.black12,
                            highlightColor: Colors.white,
                            child: Container(
                              height: 20,
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}