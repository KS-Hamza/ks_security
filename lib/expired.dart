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

  const DashboardScreen({
    super.key,
    required this.username,
    required String title,
    this.userId,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiServices _apiServices = ApiServices();
  final AESEncryptionHelper _encryptionHelper = AESEncryptionHelper();
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
      return _encryptionHelper.decrypt(encryptedText);
    } catch (e) {
      print("Decryption error: $e");
      return 'Decryption failed';
    }
  }

  Future<Map<String, List<Map<String, String>>>> _fetchFavorites() async {
    try {
      final favoriteBanks =
      await _apiServices.fetchFavoriteBankDetails(widget.userId!);
      final favoriteSubscription =
      await _apiServices.fetchFavoriteSubscription(widget.userId!);
      final favoriteCredentials =
      await _apiServices.fetchFavoriteCredentials(widget.userId!);

      return {
        'banks': (favoriteBanks?['data'] ?? []).map<Map<String, String>>((item) {
          return {'name': decrypt(item['bank_name'])};
        }).toList(),
        'subscription': (favoriteSubscription?['data'] ?? [])
            .map<Map<String, String>>((item) {
          return {'name': decrypt(item['service_name'])};
        }).toList(),
        'credentials': (favoriteCredentials?['data'] ?? [])
            .map<Map<String, String>>((item) {
          return {'name': decrypt(item['username'])};
        }).toList(),
      };
    } catch (e) {
      print("Error fetching favorites: $e");
      return {'banks': [], 'subscription': [], 'credentials': []};
    }
  }

  Widget _buildSection(String title, List<Map<String, String>> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...items.map((item) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                item['name'] ?? 'Unknown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ],
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

  void _showExpiredItemsSheet() async {
    final expiredItems = await _expiredItems;

    showMaterialModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
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
                    style:
                    TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              else
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
        return ListTile(
          title: Text(decryptedName ?? 'Unknown Subscription'),
          subtitle: Text("Expired on ${item['expiry_date']}"),
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
        return ListTile(
          title: Text(decryptedAccountName ?? 'Unknown Bank Account'),
          subtitle: Text("Expired on ${item['card_expiry_date']}"),
        );
      }));
    }

    return itemWidgets;
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
          title: Text(
            widget.username,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2CAE9F),
        ),
        drawer: const CustomDrawer(username: ''),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            children: [
              _buildSection("Your Favourites", []),
            ],
          ),
        ),
      ),
    );
  }
}
