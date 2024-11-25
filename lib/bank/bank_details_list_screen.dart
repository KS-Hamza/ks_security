import 'package:businessmanagemant/bank/add_new_bank_details.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For handling file operations
import 'package:provider/provider.dart'; // Import provider
import '../api_services.dart';
import '../encryption.dart'; // Import your encryption helper
import '../drawer.widget.dart'; // Ensure this import points to your CustomDrawer
import '../bottom.widget.dart'; // Import your BottomNavBar widget
import 'view_bank_details_page.dart'; // Ensure this points to your bank details view page
import '../Provider_statemanagement/Login_provider.dart';
import 'package:http/http.dart' as http;// Import LoginProvider

class BankDetailsListScreen extends StatefulWidget {
  const BankDetailsListScreen({Key? key, required String username}) : super(key: key);

  @override
  _BankDetailsListScreenState createState() => _BankDetailsListScreenState();
}

class _BankDetailsListScreenState extends State<BankDetailsListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> bankDetailsList = [];
  List<Map<String, dynamic>> filteredBankDetailsList = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Map<int, File?> imageFiles = {};
  final ApiServices apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper(); // Initialize the encryption helper
  String selectedFilter = "all";

  @override
  void initState() {
    super.initState();
    _fetchBankDetailsList();
    searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBankDetailsList() async {
    final int? userId = Provider.of<LoginProvider>(context, listen: false).userId;

    if (userId == null) {
      _showErrorDialog('User not logged in. Redirecting to login.');
      Navigator.pushReplacementNamed(context, '/login_page');
      return;
    }

    try {
      final Map<String, dynamic>? fetchedData = await apiServices.fetchBankList(userId);
      if (fetchedData != null && fetchedData['data'] != null) {
        setState(() {
          bankDetailsList = List<Map<String, dynamic>>.from(fetchedData['data']).map((bankDetail) {
            try {
              final decryptedBankName = _safelyDecrypt(bankDetail['bank_name']);
              final decryptedBalance = _safelyDecrypt(bankDetail['balance']);
              return {
                'id': bankDetail['id'],
                'bank_name': decryptedBankName,
                'balance': decryptedBalance,
                'favourite': bankDetail['favourite']?.toString() ?? "0",
              };
            } catch (decryptionError) {
              print('Decryption failed for ID ${bankDetail['id']}: $decryptionError');
              return {
                'id': bankDetail['id'],
                'bank_name': bankDetail['bank_name'],
                'balance': bankDetail['balance'],

              };
            }
          }).toList();
          filteredBankDetailsList = bankDetailsList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('No bank details found or failed to load.');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to load bank details: $e');
    }
  }


  String _safelyDecrypt(String? encryptedData) {
    try {
      if (encryptedData == null) return 'Not provided';
      return encryptionHelper.decrypt(encryptedData);
    } catch (e) {
      print('Decryption error: $e');
      return 'Decryption failed';
    }
  }

  void _filterList() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredBankDetailsList = bankDetailsList.where((bankDetail) {
        String bankName = bankDetail['bank_name']?.toLowerCase() ?? '';
        return bankName.contains(query);
      }).toList();
    });
  }

  void _filterByType(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "active") {
        filteredBankDetailsList = bankDetailsList
            .where((bankDetail) => bankDetail['account_status'] == "Active")
            .toList();
      } else if (filter == "inactive") {
        filteredBankDetailsList = bankDetailsList
            .where((bankDetail) => bankDetail['account_status'] == "Inactive")
            .toList();
      } else {
        filteredBankDetailsList = bankDetailsList;
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await _fetchBankDetailsList();
  }

  void _onView(int index) {
    String bankId = filteredBankDetailsList[index]['id'].toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewBankDetailsPage(bankId: bankId),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFiles[index] = File(pickedFile.path);
      });
    }
  }

  void _onFabTapped() {
    final int? userId = Provider.of<LoginProvider>(context, listen: false).userId;

    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddBankDetails(userId: userId)),
      );
    } else {
      print('Error: userId is null, redirecting to LoginPage');
      Navigator.pushReplacementNamed(context, '/login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          "Bank Details List",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0x0ce9e5eb),
        elevation: 0,
      ),
      drawer: const CustomDrawer(username: '',),
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
                  hintText: "Search bank details...",
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
              child: isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 6.0,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bank Details Loading...',
                      style: GoogleFonts.robotoCondensed(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  : filteredBankDetailsList.isEmpty
                  ? Center(
                child: Text(
                  "No bank details found.",
                  style: GoogleFonts.roboto(fontSize: 20, color: Colors.black),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 25),
                  itemCount: filteredBankDetailsList.length,
                  itemBuilder: (context, index) {
                    final bankDetail = filteredBankDetailsList[index];
                    final decryptedBankName = bankDetail['bank_name'];
                    final decryptedBalance = bankDetail['balance'];

                    return GestureDetector(
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          side: const BorderSide(
                            color: Colors.transparent,
                            width: 0.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: imageFiles[index] != null
                                  ? FileImage(imageFiles[index]!)
                                  : null,
                              child: (imageFiles[index] == null)
                                  ? const Icon(Icons.account_balance, color: Colors.black)
                                  : null,
                            ),
                            title: Text(
                              decryptedBankName ?? 'No Bank Name',
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              "Balance: Rs:${decryptedBalance ?? '0'}",
                              style: GoogleFonts.roboto(color: Colors.black),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                  onPressed: () => _onView(index),
                                ),
                                IconButton(
                                  icon: Icon(
                                    bankDetail['favourite'] == "1"
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: bankDetail['favourite'] == "1"
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    final String currentlyFavorite = bankDetail['favourite'] == "1" ? "0" : "1";

                                    try {
                                      final String url = currentlyFavorite == "0"
                                          ? 'https://karsaazebs.com/BMS/api/favourite/bank_isnot_favourite.php?id=${bankDetail['id']}'
                                          : 'https://karsaazebs.com/BMS/api/favourite/bank_is_favourite.php?id=${bankDetail['id']}';

                                      final response = await http.get(Uri.parse(url), headers: {
                                        'Authorization': ApiServices().authHeader,
                                      });

                                      if (response.statusCode == 200 || response.statusCode == 201) {
                                        setState(() {
                                          bankDetail['favourite'] = currentlyFavorite;
                                        });
                                      } else {
                                        throw Exception('Failed to update favorite status');
                                      }
                                    } catch (e) {
                                      print('Error updating favorite status: $e');
                                    }
                                  },
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )

              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        scaffoldKey: _scaffoldKey,
        onTapFunctions: [
              () {
            Navigator.pushNamed(context, '/dashboard'); // Navigate to dashboard
          },
              () {
            print("Other function tapped");
          },
        ],
        onFabTapped: _onFabTapped, // Call the FAB function when pressed
      ),
    );
  }
}
