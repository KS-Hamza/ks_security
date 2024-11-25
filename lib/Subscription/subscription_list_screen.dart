import 'dart:io';
import 'package:businessmanagemant/Subscription/subscription_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Provider_statemanagement/Login_provider.dart';
import '../api_services.dart';
import '../encryption.dart';
import 'add_new_subscription.dart';
import '../Subscription_payment/add_new_subscription_payments.dart';
import 'view_subscription_page.dart';
import '../Subscription_payment/show_payments.dart';
import '../drawer.widget.dart';
import '../bottom.widget.dart';
import 'package:http/http.dart' as http;

class SubscriptionListScreen extends StatefulWidget {
  final String username;

  const SubscriptionListScreen({super.key, required this.username});

  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Map<int, File?> imageFiles = {};
  Map<int, double> slidePositions = {};
  String selectedFilter = "all";
  late SubscriptionProvider subscriptionProvider;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterList);
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    final int? userId = Provider.of<LoginProvider>(context, listen: false).userId;
    if (userId != null) {
      await Provider.of<SubscriptionProvider>(context, listen: false).fetchSubscriptions(userId);
    } else {
      _showErrorDialog('User not logged in. Redirecting to login.');
      Navigator.pushReplacementNamed(context, '/login_page');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterList() {
    subscriptionProvider.filterSubscriptions(searchController.text.toLowerCase());
  }

  void _filterByType(String filter) {
    subscriptionProvider.filterByType(filter);
    setState(() => selectedFilter = filter);
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onFabTapped() {
    final int? userId = Provider.of<LoginProvider>(context, listen: false).userId;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddSubscription(userId: userId)),
      );
    } else {
      _showErrorDialog('User not logged in.');
      Navigator.pushReplacementNamed(context, '/login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          "Subscription List",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2CAE9F),
        elevation: 0,
      ),
      drawer: const CustomDrawer(username: 'widget.username',),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xce9e5eb),
              Color(0xce9e5eb),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 10, left: 15, right: 15),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  hintText: "Search subscriptions...",
                  hintStyle: const TextStyle(color: Colors.black),
                  fillColor: Colors.white.withOpacity(0.9),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: subscriptionProvider.isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 5,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Subscription Loading...',
                      style: GoogleFonts.robotoCondensed(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  : subscriptionProvider.filteredSubscriptions.isEmpty
                  ? Center(
                child: Text(
                  "No subscriptions found.",
                  style: GoogleFonts.roboto(fontSize: 20, color: Colors.black),
                ),
              )
             : RefreshIndicator(
                onRefresh: _fetchSubscriptions,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 25),
                  itemCount: subscriptionProvider.filteredSubscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = subscriptionProvider.filteredSubscriptions[index];
                    double slidePosition = slidePositions[index] ?? 0.0;

                    return GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        if (details.primaryDelta != null && details.primaryDelta!.abs() > 5) {
                          setState(() {
                            slidePositions[index] = (slidePosition - details.primaryDelta!).clamp(0.0, 120.0);
                          });
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        setState(() {
                          slidePositions[index] = slidePositions[index]! > 30 ? 120.0 : 0.0;
                        });
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [

                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.green),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddNewSubscriptionPayments(
                                          subscriptionId: subscription['id'].toString(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(-slidePosition, 0),
                            child: Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                side: const BorderSide(color: Colors.transparent, width: 0.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: subscription['image_url'] != null
                                        ? NetworkImage(subscription['image_url'])
                                        : null,
                                    child: (subscription['image_url'] == null)
                                        ? const Icon(Icons.subscriptions, color: Colors.black)
                                        : null,
                                  ),
                                  title: Text(
                                    subscription['service_name'] ?? 'No Service Name',
                                    style: GoogleFonts.robotoCondensed(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    subscription['favourite'] ?? 'No Favourite',
                                    style: GoogleFonts.robotoCondensed(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.blue),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewSubscriptionPage(
                                              subscriptionId: subscription['id'].toString(),
                                            ),
                                          ),
                                        ),
                                      ),
                                     IconButton(
                    icon: Icon(
                    subscription['favourite'] == "1" ? Icons.favorite : Icons.favorite_border,
                    color: subscription['favourite'] == "1" ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                    final String currentlyFavorite = subscription['favourite'] == "1" ? "0" : "1";

                    // Print current state
                    print('Current Favorite State: ${subscription['favourite']}');

                    // Toggle the favorite state in the UI optimistically

                    try {
                      final String url = currentlyFavorite == "0"
                          ? 'https://karsaazebs.com/BMS/api/favourite/subscription_isnot_favourite.php?id=${subscription['id']}'
                          : 'https://karsaazebs.com/BMS/api/favourite/subscription_is_favourite.php?id=${subscription['id']}';

                      // Call the API
                      final response = await http.get(Uri.parse(url), headers: {
                        'Authorization': ApiServices().authHeader,
                      });

                      print('API Response Status Code: ${response.statusCode}');
                      print('API Response Body: ${response.body}');

                      if (response.statusCode != 200 && response.statusCode != 201) {
                        // Revert state if the API call fails
                        throw Exception('Failed to update favorite status');
                      }

                      setState(() {
                        subscription['favourite'] = currentlyFavorite; // Toggle state on success
                      });

                      // Log the successful state change
                      print('After API Success - Favorite State: ${subscription['favourite']}, Visibility Icon: ${subscription['service_name']}');
                    } catch (error) {
                      print('Error updating favorite status: $error');

                      // Optionally print additional details if the API call fails
                      print('Error Details: ${error.toString()}');
                    }

                    },
                    )
                                    ],
                                  ),
                                ),

                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        scaffoldKey: _scaffoldKey,
        onTapFunctions: [
              () {
            Navigator.pushNamed(context, '/dashboard');
          },
        ],
        onFabTapped: _onFabTapped,
      ),
    );
  }
}
