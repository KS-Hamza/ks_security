import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import '../encryption.dart';
 // Ensure you have this helper class imported

class EditCredentialScreen extends StatefulWidget {
  final String credentialId;

  EditCredentialScreen({required this.credentialId});

  @override
  _EditCredentialScreenState createState() => _EditCredentialScreenState();
}

class _EditCredentialScreenState extends State<EditCredentialScreen> {
  final ApiServices apiServices = ApiServices();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
 // final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  bool isLoading = true;
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper(); // Instantiate the encryption helper

  @override
  void initState() {
    super.initState();
    _fetchCredential();
  }

  Future<void> _fetchCredential() async {
    final response = await apiServices.fetchCredentialById(widget.credentialId);
    setState(() {
      isLoading = false;
      if (response != null) {
        // Decrypt fetched data
       // nameController.text = encryptionHelper.decrypt(response['data']['name'] ?? '');
        usernameController.text = encryptionHelper.decrypt(response['data']['username'] ?? '');
        passwordController.text = encryptionHelper.decrypt(response['data']['password'] ?? '');
        remarksController.text = encryptionHelper.decrypt(response['data']['remarks'] ?? '');
      }
    });
  }

  Future<void> _updateCredential() async {
    if (_formKey.currentState!.validate()) {
      // Encrypt data before sending to the server
      //final encryptedName = encryptionHelper.encrypt(nameController.text);
      final encryptedUsername = encryptionHelper.encrypt(usernameController.text);
      final encryptedPassword = encryptionHelper.encrypt(passwordController.text);
      final encryptedRemarks = encryptionHelper.encrypt(remarksController.text);

      final credentialData = {
        //'name': encryptedName,
        'username': encryptedUsername,
        'password': encryptedPassword,
        'remarks': encryptedRemarks,
      };

      final success = await apiServices.updateCredential(widget.credentialId, credentialData);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credential updated successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update credential")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Credential",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  Column(
                    children: [
                  //    _buildInputField("Name", nameController, Icons.account_circle),
                      _buildInputField("Username", usernameController, Icons.person),
                      _buildInputField("Password", passwordController, Icons.lock, obscureText: true),
                      _buildInputField("Remarks", remarksController, Icons.document_scanner_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _updateCredential,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Update",
                      style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.black),
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }
}
