import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_services.dart';
import '../encryption.dart';

class AddCredential extends StatefulWidget {
  final int userId;

  const AddCredential({super.key, required this.userId});

  @override
  _AddCredentialState createState() => _AddCredentialState();
}

class _AddCredentialState extends State<AddCredential> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  bool _passwordVisible = false;

  final ApiServices _apiServices = ApiServices();

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  Future<void> _saveCredential() async {
    final encryptionHelper = AESEncryptionHelper();

    if (_formKey.currentState!.validate()) {
      try {
        final encryptedUsername = encryptionHelper.encrypt(usernameController.text);
        final encryptedPassword = encryptionHelper.encrypt(passwordController.text);
        final encryptedRemarks = encryptionHelper.encrypt(remarksController.text);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://karsaazebs.com/BMS/api/v1.php?table=credentials&action=insert'),
        );
        request.fields['user_id'] = widget.userId.toString();
        request.fields['username'] = encryptedUsername;
        request.fields['password'] = encryptedPassword;
        request.fields['remarks'] = encryptedRemarks;
        request.headers['Authorization'] = _apiServices.authHeader;
        request.headers['Content-Type'] = 'multipart/form-data';

        var response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credential added successfully!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add credential: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding credential: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add New Credential",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField("Username", usernameController, Icons.person),
                      const SizedBox(height: 20),
                      _buildPasswordField("Password", passwordController),
                      const SizedBox(height: 20),
                      _buildInputField("Remarks", remarksController, Icons.description, isOptional: true),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveCredential,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Save",
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black),
            hintText: "Enter $label",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (!isOptional && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !_passwordVisible,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Colors.black),
            hintText: "Enter $label",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
