import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'Subscription/subscription_list_screen.dart';
import 'Credentials/credential_list_screen.dart';
import 'bank/bank_details_list_screen.dart';
import 'drawer.widget.dart';
import 'api_services.dart';
import 'encryption.dart'; // Import AESEncryptionHelper

class DashboardScreen extends StatefulWidget {
  final String username;
  final int? userId;

  final dynamic title;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.title,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiServices _apiServices = ApiServices();
  final AESEncryptionHelper _encryptionHelper = AESEncryptionHelper(); // Initialize AESEncryptionHelper
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>?> _nearToExpireItems;
  late Future<Map<String, dynamic>?> _expiredItems;
  late Future<Map<String, List<Map<String, String>>>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _fetchFavorites();
    _nearToExpireItems = _apiServices.fetchNearToExpireItems(widget.userId!);
    _expiredItems = _apiServices.fetchExpireItems(widget.userId!);
  }
  Future<void> _refreshData() async {
    setState(() {
      _favoritesFuture = _fetchFavorites();
      _nearToExpireItems = _apiServices.fetchNearToExpireItems(widget.userId!);
      _expiredItems = _apiServices.fetchExpireItems(widget.userId!);
    });
  }
  String decrypt(String encryptedText) {
    try {
      return _encryptionHelper.decrypt(
          encryptedText); // Decrypt using AESEncryptionHelper
    } catch (e) {
      print("Decryption error: $e");
      return 'Decryption failed'; // Return a placeholder if decryption fails
    }
  }

  Future<Map<String, List<Map<String, String>>>> _fetchFavorites() async {
    try {
      final favoriteBanks = await _apiServices.fetchFavoriteBankDetails(
          widget.userId!);
      final favoriteSubscription = await _apiServices.fetchFavoriteSubscription(
          widget.userId!);
      final favoriteCredentials = await _apiServices.fetchFavoriteCredentials(
          widget.userId!);

      return {
        'banks': (favoriteBanks?['data'] ?? []).map<Map<String, String>>((
            item) {
          return {'name': decrypt(item['bank_name'])};
        }).toList(),
        'subscription': (favoriteSubscription?['data'] ?? []).map<
            Map<String, String>>((item) {
          return {'name': decrypt(item['service_name'])};
        }).toList(),
        'credentials': (favoriteCredentials?['data'] ?? []).map<
            Map<String, String>>((item) {
          return {'name': decrypt(item['username'])};
        }).toList(),
      };
    } catch (e) {
      print("Error fetching favorites: $e");
      return {'banks': [], 'subscription': [], 'credentials': []};
    }
  }
  void _showExpiredItemsSheet() async {
    final expiredItems = await _expiredItems;

    showMaterialModalBottomSheet(
      context: context,
      builder: (context) =>
          SingleChildScrollView(
            controller: ModalScrollController.of(context),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: expiredItems != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Expired Items",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (expiredItems['subscription'].isEmpty &&
                      expiredItems['bank_details'].isEmpty)
                    const Center(
                      child: Text(
                        "No expired items found.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ..._buildExpiredItemsList(expiredItems),
                ],
              )
                  : const Center(
                child: Text(
                  "Failed to load expired items.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),
          ),
    );
  }

  List<Widget> _buildExpiredItemsList(Map<String, dynamic> data) {
    List<Widget> itemWidgets = [];
    final subscriptions = data['subscription'] as List<dynamic>;
    final bankDetails = data['bank_details'] as List<dynamic>;

    if (subscriptions.isNotEmpty) {
      itemWidgets.add(Text(
        "Expired Subscriptions",
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ));
      itemWidgets.addAll(subscriptions.map((item) {
        final decryptedName = decrypt(item['service_name']);
        return _expiredItemCard(
          title: decryptedName ?? 'Unknown Subscription',
          subtitle: "Expired on ${item['expiry_date']}",
        );
      }));
    }

    if (bankDetails.isNotEmpty) {
      itemWidgets.add(const SizedBox(height: 20));
      itemWidgets.add(Text(
        "Expired Bank Details",
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ));
      itemWidgets.addAll(bankDetails.map((item) {
        final decryptedAccountName = decrypt(item['account_name']);
        return _expiredItemCard(
          title: decryptedAccountName ?? 'Unknown Bank Account',
          subtitle: "Expired on ${item['card_expiry_date']}",
        );
      }));
    }

    return itemWidgets;
  }

  Widget _expiredItemCard({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SubscriptionListScreen(username: widget.username),
            ),
          );
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CredentialListScreen(),
            ),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BankDetailsListScreen(username: widget.username),
            ),
          );
          break;
        case 3:
          _showExpiredItemsSheet();
          break;
        case 4:
          _scaffoldKey.currentState?.openDrawer();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2CAE9F),
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: Colors.white,
              onPressed: () {},
            ),
          ],
        ),
        drawer: const CustomDrawer(username: '',),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Your Favourites",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FutureBuilder<Map<String, List<Map<String, String>>>>(
                      future: _favoritesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(child: Text("Failed to load favorites."));
                        } else {
                          final favorites = snapshot.data!;
                          var modules = [
                            {'title': 'Favorite Banks', 'items': favorites['banks'] ?? []},
                            {'title': 'Favorite Subscriptions', 'items': favorites['subscription'] ?? []},
                            {'title': 'Favorite Credentials', 'items': favorites['credentials'] ?? []},
                          ];

                          return ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: modules.length,
                            itemBuilder: (context, moduleIndex) {
                              var module = modules[moduleIndex];
                              var items = module['items'] as List<Map<String, String>>;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Text(
                                      module['title'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  items.isEmpty
                                      ? Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Center(
                                      child: Text(
                                        "No ${module['title']} available",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  )
                                      : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      var item = items[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.3),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'] ?? 'Unknown Item',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Icon(
                                                Icons.favorite,
                                                color: Colors.redAccent,
                                                size: 28,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Soon to Expire",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: _nearToExpireItems,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(child: Text("Error loading data."));
                        } else if (!snapshot.hasData ||
                            (snapshot.data!['subscription'] == null &&
                                snapshot.data!['bank_details'] == null)) {
                          return Center(
                            child: Text(
                              "No data available",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        } else {
                          var subscriptions =
                          snapshot.data!['subscription'] as List<dynamic>;
                          var bankDetails =
                          snapshot.data!['bank_details'] as List<dynamic>;

                          var items = [
                            ...subscriptions.map((item) => {
                              'name': decrypt(item['service_name']),
                              'days_left': item['days_until_expiry'],
                            }),
                            ...bankDetails.map((item) => {
                              'name': decrypt(item['account_name']),
                              'days_left': item['days_until_expiry'],
                            })
                          ];

                          if (items.isEmpty) {
                            return Center(
                              child: Text(
                                "No data available",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              var item = items[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'] ?? 'Unknown Item',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Expiring in ${item['days_left'] ?? 'N/A'} days",
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.redAccent,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),


        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF2CAE9F),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.subscriptions,
                size: 28,
              ),
              label: 'Subscription',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.key,
                size: 28,
              ),
              label: 'Credentials',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_balance,
                size: 28,
              ),
              label: 'Bank',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.timer_off_outlined,
                size: 28,
              ),
              label: 'Expired',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.account_circle,
                size: 28,
              ),
              label: 'Account',
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}