import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'Provider_statemanagement/Login_provider.dart';

class CustomDrawer extends StatefulWidget {
  final String username;

  const CustomDrawer({super.key, required this.username});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    final username = Provider.of<LoginProvider>(context,listen: false).userName;
    // Debug print to verify username is passed correctly
    debugPrint(username);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2CAE9F),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text(
                          'Welcome, ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          username.toString().toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('Subscription'),
            selected: true, // If this is the selected screen
            onTap: () {
              Navigator.pushNamed(context, '/subscription');
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.book),
            title: const Text('Setup Books'),
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Currency'),
                onTap: () {
                  Navigator.pushNamed(context, '/currency');
                },
              ),
              ListTile(
                leading: const Icon(Icons.comment_bank),
                title: const Text('Bank Account Status'),
                onTap: () {
                  Navigator.pushNamed(context, '/bankAccountStatus');
                },
              ),
              ListTile(
                leading: const Icon(Icons.merge_type),
                title: const Text('Bank Account Type'),
                onTap: () {
                  Navigator.pushNamed(context, '/bankAccountType');
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Payment Method'),
                onTap: () {
                  Navigator.pushNamed(context, '/paymentMethod');
                },
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login_page', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
