import 'package:flutter/material.dart';

class SimpleClosedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const SimpleClosedAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.15);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 253, 253, 253),
      elevation: 0, // Removes the shadow
      leading: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black, // Text color
            fontWeight: FontWeight.normal, // Font weight to match the style
            fontSize: 16.0, // Adjust font size
          ),
        ),
      ),
      centerTitle: true, // Center the title
      toolbarHeight: 54,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.15),
        child: Container(
          color: Colors.grey, // border color
          height: 0.15, // border height
        ),
      ),
    );
  }
}