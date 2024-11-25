import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';

class BottomNavBar extends StatefulWidget {
  final List<Function> onTapFunctions;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function() onFabTapped;

  const BottomNavBar({
    Key? key,
    required this.onTapFunctions,
    required this.scaffoldKey,
    required this.onFabTapped,
  }) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState;(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      widget.scaffoldKey.currentState?.openDrawer();
    } else if (widget.onTapFunctions.isNotEmpty && widget.onTapFunctions.length > index) {
      widget.onTapFunctions[index].call();
    } else {
      debugPrint("No function provided for index $index");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            child: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home,
                    size: 24,
                    color: _selectedIndex == 0 ? const Color(0xFF2CAE9F) : Colors.grey,
                  ),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: SizedBox.shrink(),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.account_circle,
                    size: 26,
                    color: _selectedIndex == 2 ? const Color(0xFF2CAE9F) : Colors.grey,
                  ),
                  label: 'Account',
                ),
              ],
              backgroundColor: Colors.transparent,
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xFF2CAE9F),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: GoogleFonts.roboto(
                fontSize: 12,
              ),
              onTap: _onItemTapped,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              iconSize: 24,
            ),
          ),
        ),
        Positioned(
          top: -15,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: FloatingActionButton(
            onPressed: widget.onFabTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2CAE9F),
              ),
              child: const Icon(
                Icons.add,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
