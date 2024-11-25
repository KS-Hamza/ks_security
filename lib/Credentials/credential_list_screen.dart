import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Provider_statemanagement/Login_provider.dart';
import 'package:http/http.dart' as http;
import '../api_services.dart';
import '../encryption.dart'; // Import your encryption helper
import 'add_new_credential1.dart';
import 'credential_view_screen.dart';
import '../drawer.widget.dart'; // Ensure this import points to your CustomDrawer
import '../bottom.widget.dart'; // Import the updated BottomNavBar

class CredentialListScreen extends StatefulWidget {
  const CredentialListScreen({Key? key}) : super(key: key);

  @override
  _CredentialListScreenState createState() => _CredentialListScreenState();
}

class _CredentialListScreenState extends State<CredentialListScreen> {
  final ApiServices apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper(); // Initialize the encryption helper
  List<Map<String, dynamic>> credentialList = [];
  List<Map<String, dynamic>> filteredCredentialList = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  String selectedFilter = "all";
  final ImagePicker _picker = ImagePicker();
  Map<int, File?> imageFiles = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Scaffold key

  @override
  void initState() {
    super.initState();
    _fetchCredentialList();
    searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCredentialList() async {
    final int? userId = Provider.of<LoginProvider>(context, listen: false).userId;

    // Check if the user is logged in
    if (userId == null) {
      _showErrorDialog('User not logged in. Redirecting to login.');
      Navigator.pushReplacementNamed(context, '/login_page');
      return;
    }

    try {
      // Fetch credential data from the API
      final Map<String, dynamic>? fetchedData = await apiServices.fetchCredentialList(userId);
      print("Fetched Data: $fetchedData"); // Debugging: check raw fetched data

      // Verify fetched data structure
      if (fetchedData != null && fetchedData.containsKey('data') && fetchedData['data'] is List) {
        List<dynamic> rawData = fetchedData['data'];

        setState(() {
          // Process and decrypt each credential
          credentialList = rawData.map((credential) {
            try {
              // Ensure credential is a map and contains required fields
              if (credential is Map<String, dynamic> && credential.containsKey('username')) {
                final decryptedUsername = _safelyDecrypt(credential['username']);
                final decryptedUrl = _safelyDecrypt(credential['url'] ?? '');


                return {
                  'id': credential['id'],
                  'username': decryptedUsername,
                  'url': decryptedUrl,
                  'status': credential['status'],
                  'favourite': credential['favourite']?.toString() ?? "0",
                };
              } else {
                // Log missing fields or invalid data format
                print("Invalid credential data format: $credential");
                return {
                  'id': credential['id'] ?? 'Unknown',
                  'username': 'Unknown',
                  'url': 'Unknown',
                  'status': credential['status'] ?? 'Unknown',
                };
              }
            } catch (decryptionError) {
              // Handle decryption errors gracefully
              print('Decryption failed for ID ${credential['id']}: $decryptionError');
              return {
                'id': credential['id'] ?? 'Unknown',
                'username': credential['username'] ?? 'Encrypted Data',
                'url': credential['url'] ?? 'Encrypted Data',
                'status': credential['status'] ?? 'Unknown',
              };
            }
          }).toList();

          // Update filtered list and loading status
          filteredCredentialList = credentialList;
          isLoading = false;
        });
      } else {
        // Handle missing data key or unexpected format
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('No credentials found or failed to load.');
        print('No credentials found or data in unexpected format.');
      }
    } catch (e) {
      // Catch any other errors during fetching or processing
      setState(() {
        isLoading = false;
      });
      print('Error in fetching credentials: $e');
      _showErrorDialog('Failed to load credentials: $e');
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
      filteredCredentialList = credentialList.where((credential) {
        String username = (credential['username'] ?? '').toLowerCase();
        return username.contains(query);
      }).toList();
    });
  }

  void _filterByType(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "active") {
        filteredCredentialList = credentialList
            .where((credential) => credential['status'] == "Active")
            .toList();
      } else if (filter == "inactive") {
        filteredCredentialList = credentialList
            .where((credential) => credential['status'] == "Inactive")
            .toList();
      } else {
        filteredCredentialList = credentialList;
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
    await _fetchCredentialList();
  }

  void _onView(int index) {
    String credentialId = filteredCredentialList[index]['id'].toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CredentialViewScreen(credentialId: credentialId),
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

  // Define the _onFabTapped method
  void _onFabTapped() {
    final int? userId = Provider.of<LoginProvider>(context, listen: false).userId;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddCredential(userId: userId)),
      );
    } else {
      print('Error: userId is null, redirecting to LoginPage');
      Navigator.pushReplacementNamed(context, '/login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the scaffold key
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
          "Credentials",
          style: GoogleFonts.roboto(fontSize: 25,color: Colors.black),

        ),
        backgroundColor: const Color(0xce9e5eb),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(username: '',), // Your custom drawer remains unchanged
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
              padding: const EdgeInsets.all(15.0),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  hintText: "Search credentials...",
                  hintStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            /*Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _filterButton('All', 'all'),
                  _filterButton('Active', 'active'),
                  _filterButton('Inactive', 'inactive'),
                ],
              ),
            ),*/
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
                      'Credentials Loading...',
                      style: GoogleFonts.robotoCondensed(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  : filteredCredentialList.isEmpty
                  ? Center(
                child: Text(
                  "No credentials found.",
                  style: GoogleFonts.roboto(fontSize: 20, color: Colors.black),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 25),
                  itemCount: filteredCredentialList.length,
                  itemBuilder: (context, index) {
                    final credential = filteredCredentialList[index];

                    return GestureDetector(
                      onTap: () => _onView(index),
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
                                  ? const Icon(Icons.vpn_key, color: Colors.black)
                                  : null,
                            ),
                            title: Text(
                              credential['username'] ?? 'No Username',
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
                                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                  onPressed: () => _onView(index),
                                ),
                                IconButton(
                                  icon: Icon(
                                    credential['favourite'] == "1" ? Icons.favorite : Icons.favorite_border,
                                    color: credential['favourite'] == "1" ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    final String currentlyFavorite = credential['favourite'] == "1" ? "0" : "1";

                                    // Print current state
                                    print('Current Favorite State: ${credential['favourite']}');

                                    // Toggle the favorite state in the UI optimistically

                                    try {
                                      final String url = currentlyFavorite == "0"
                                          ? 'https://karsaazebs.com/BMS/api/favourite/credentials_isnot_favourite.php?id=${credential['id']}'
                                          : 'https://karsaazebs.com/BMS/api/favourite/credentials_is_favourite.php?id=${credential['id']}';

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
                                        credential['favourite'] = currentlyFavorite; // Toggle state on success
                                      });

                                      // Log the successful state change
                                      print('After API Success - Favorite State: ${credential['favourite']}, Visibility Icon: ${credential['service_name']}');
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
            Navigator.pushNamed(context, '/dashboard'); // Navigate to Dashboard
          },
              () {
            // No action needed for the center empty item
          },
              () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ],
        onFabTapped: _onFabTapped, // Handle FAB action
      ),
    );
  }

  Widget _filterButton(String title, String type) {
    bool isSelected = selectedFilter == type;
    return GestureDetector(
      onTap: () => _filterByType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Colors.pink, Colors.purple])
              : null,
          color: isSelected ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
