import 'package:businessmanagemant/encryption.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import 'edit_credential_screen.dart';
import 'package:flutter/services.dart';

class CredentialViewScreen extends StatefulWidget {
  final String credentialId;

  CredentialViewScreen({required this.credentialId});

  @override
  _CredentialViewScreenState createState() => _CredentialViewScreenState();
}

class _CredentialViewScreenState extends State<CredentialViewScreen> {
  final ApiServices apiServices = ApiServices();
  Map<String, dynamic>? credential;
  bool isLoading = true;
  bool isPasswordVisible = false;

  // Variables for decrypted data
  String? _decryptedPlatform;
  String? _decryptedUsername;
  String? _decryptedPassword;
  String? _decryptedUrl;
  String? _decryptedRemarks;

  @override
  void initState() {
    super.initState();
    _fetchCredential();
  }

  Future<void> _fetchCredential() async {
    final response = await apiServices.fetchCredentialById(widget.credentialId);
    setState(() {

      isLoading = false;
      credential = response?['data'];
    });

    if (credential != null) {
      _decryptData();
    }
  }

  Future<void> _decryptData() async {
    final encryptionHelper = AESEncryptionHelper();

    try {
      //print("Encrypted Platform: ${credential!['platform']}");
      print("Encrypted Username: ${credential!['username']}");
      print("Encrypted Password: ${credential!['password']}");
     // print("Encrypted URL: ${credential!['url']}");
      print("Encrypted Remarks: ${credential!['remarks']}");

      setState(() {
        //_decryptedPlatform = encryptionHelper.decrypt(credential!['platform']);
        //print("Decrypted Platform: $_decryptedPlatform");

        _decryptedUsername = encryptionHelper.decrypt(credential!['username']);
        print("Decrypted Username: $_decryptedUsername");

        _decryptedPassword = encryptionHelper.decrypt(credential!['password']);
        print("Decrypted Password: $_decryptedPassword");

       // _decryptedUrl = encryptionHelper.decrypt(credential!['url']);
        //print("Decrypted URL: $_decryptedUrl");

        _decryptedRemarks = encryptionHelper.decrypt(credential!['remarks']);
        print("Decrypted Remarks: $_decryptedRemarks");
      });
    } catch (e) {
      print("Decryption failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decryption failed. Please check the key.')),
      );
    }
  }

  /*Future<void> _decryptData() async {
    try {
      // Print the encrypted data before decryption for debugging
      print("Encrypted Platform: ${credential!['platform']}");
      print("Encrypted Username: ${credential!['username']}");
      print("Encrypted Password: ${credential!['password']}");
      print("Encrypted URL: ${credential!['url']}");
      print("Encrypted Remarks: ${credential!['remarks']}");

      setState(() {
        _decryptedPlatform = JWTUtils.decryptData(credential!['platform']);
        print("Decrypted Platform: $_decryptedPlatform"); // Print after decryption

        _decryptedUsername = JWTUtils.decryptData(credential!['username']);
        print("Decrypted Username: $_decryptedUsername"); // Print after decryption

        _decryptedPassword = JWTUtils.decryptData(credential!['password']);
        print("Decrypted Password: $_decryptedPassword"); // Print after decryption

        _decryptedUrl = JWTUtils.decryptData(credential!['url']);
        print("Decrypted URL: $_decryptedUrl"); // Print after decryption

        _decryptedRemarks = JWTUtils.decryptData(credential!['remarks']);
        print("Decrypted Remarks: $_decryptedRemarks"); // Print after decryption
      });
    } catch (e) {
      print("Decryption failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decryption failed. Please check the key.')),
      );
    }
  }*/


  // Delete credential
  Future<void> _deleteCredential() async {
    bool deleteConfirmed = await _showDeleteConfirmationDialog();
    if (deleteConfirmed) {
      bool success = await apiServices.deleteCredential(widget.credentialId);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credential deleted successfully!')),
        );
      } else {
        _showErrorDialog('Failed to delete credential.');
      }
    }
  }

  // Edit credential
  void _onEditCredential() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCredentialScreen(credentialId: widget.credentialId),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this credential?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ??
        false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Credential Details",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xce9e5eb),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : credential == null
          ? const Center(child: Text('No details available'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.white.withOpacity(0.9),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //_buildDetailField('Platform', _decryptedPlatform ?? 'Encrypted'),
                    _buildDetailField('Username', _decryptedUsername ?? 'Encrypted'),
                    _buildSensitiveDetailField(
                      'Password',
                      _decryptedPassword ?? 'Encrypted',
                      isVisible: isPasswordVisible,
                      toggleVisibility: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    //_buildDetailField('URL', _decryptedUrl ?? 'Encrypted'),
                    _buildDetailField('Remarks', _decryptedRemarks ?? 'Encrypted'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGradientButton(
                  label: 'Delete',
                  icon: Icons.delete,
                  onPressed: _deleteCredential,
                  colors: [Colors.redAccent, Colors.pinkAccent],
                ),
                _buildGradientButton(
                  label: 'Edit',
                  icon: Icons.edit,
                  onPressed: _onEditCredential,
                  colors: [Colors.blue, Colors.purple],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$label copied!')));
                },
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSensitiveDetailField(String label, String value,
      {required bool isVisible, required VoidCallback toggleVisibility}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  isVisible ? value : '●●●●●',
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
                ),
              ),
              IconButton(
                icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: toggleVisibility,
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$label copied!')));
                },
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
