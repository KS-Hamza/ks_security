import 'package:businessmanagemant/Subscription/subscription_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';
import 'edit_subscription.dart';
import '../encryption.dart';

class ViewSubscriptionPage extends StatefulWidget {
  final String subscriptionId;

  const ViewSubscriptionPage({Key? key, required this.subscriptionId}) : super(key: key);

  @override
  _ViewSubscriptionPageState createState() => _ViewSubscriptionPageState();
}

class _ViewSubscriptionPageState extends State<ViewSubscriptionPage> {
  Map<String, dynamic>? subscriptionData;
  bool isLoading = true;
  bool isPasswordVisible = false;
  bool isUsernameVisible = false;
  final ApiServices apiServices = ApiServices();
  final AESEncryptionHelper encryptionHelper = AESEncryptionHelper();

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionDetails();
  }

  Future<void> _fetchSubscriptionDetails() async {
    try {
      final Map<String, dynamic>? fetchedData = await apiServices.fetchSubscriptionById(widget.subscriptionId);
      if (fetchedData != null) {
        setState(() {
          subscriptionData = fetchedData;
          // Decrypt the fields if present
          if (subscriptionData != null) {
            subscriptionData!['service_name'] = _safelyDecrypt(subscriptionData!['service_name']);
            subscriptionData!['username'] = _safelyDecrypt(subscriptionData!['username']);
            subscriptionData!['password'] = _safelyDecrypt(subscriptionData!['password']);
            subscriptionData!['url'] = _safelyDecrypt(subscriptionData!['url']);
            subscriptionData!['other_description'] = _safelyDecrypt(subscriptionData!['other_description']);
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Failed to load subscription details.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching subscription details: $e');
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

  Future<void> _refreshSubscriptionDetails() async {
    setState(() {
      isLoading = true;
    });
    await _fetchSubscriptionDetails();
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

  Future<void> _deleteSubscription() async {
    final bool confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    try {
      final success = await apiServices.deleteSubscription(widget.subscriptionId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription deleted successfully!')),
        );
        // Navigate back to the subscription list screen and trigger a refresh
        Navigator.of(context).pop(true); // Pass `true` to indicate successful deletion
      } else {
        throw Exception('Failed to delete subscription.');
      }
    } catch (e) {
      _showErrorDialog('Error deleting subscription: $e');
    }
  }


  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: const Text('Are you sure you want to delete this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;
  }
  void _onDeleteSubscription() async {
    await _deleteSubscription();
  }

  void _onEditSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSubscription(subscriptionId: widget.subscriptionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Subscription Details",
          style: GoogleFonts.roboto(fontSize: 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xce9e5eb),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.transparent,
              Colors.transparent,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _refreshSubscriptionDetails,
          child: subscriptionData != null
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(
                      color: Colors.transparent,
                      width: 3.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField('Service Name:', subscriptionData!['service_name']),
                        const SizedBox(height: 10),
                        _buildTextField('URL:', subscriptionData!['url']),
                        const SizedBox(height: 10),
                        _buildToggleableTextField(
                          'Username:',
                          subscriptionData!['username'],
                          isUsernameVisible,
                              () => setState(() {
                            isUsernameVisible = !isUsernameVisible;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _buildToggleableTextField(
                          'Password:',
                          subscriptionData!['password'],
                          isPasswordVisible,
                              () => setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField('Auto Renewal:', subscriptionData!['auto_renewal'] == "1" ? "Yes" : "No"),
                        const SizedBox(height: 10),
                        _buildTextField('Next Renewal Date:', subscriptionData!['next_renewal_date']),
                        const SizedBox(height: 10),
                        _buildTextField('Expiry Date:', subscriptionData!['expiry_date']),
                        const SizedBox(height: 10),
                        _buildTextField('Other Description:', subscriptionData!['other_description']),
                        const SizedBox(height: 10),
                        _buildTextField('Active:', subscriptionData!['active'] == "1" ? "Active" : "Inactive"),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildGradientButton(
                              label: 'Delete',
                              icon: Icons.delete,
                              onPressed: _onDeleteSubscription,
                              colors: [Colors.pink, Colors.redAccent],
                              textColor: Colors.white,
                            ),
                            _buildGradientButton(
                              label: 'Edit',
                              icon: Icons.edit,
                              onPressed: _onEditSubscription,
                              colors: [Colors.blue, Colors.purple],
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              : const Center(child: Text('No details available')),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    final isCopyable = ['Service Name:', 'URL:', 'Username:', 'Password:', 'Other Description:'].contains(label);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            initialValue: value,
            readOnly: true,
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.black),
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: isCopyable
                  ? IconButton(
                icon: const Icon(Icons.copy, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied!')),
                  );
                },
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleableTextField(String label, String value, bool isVisible, VoidCallback toggleVisibility) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            key: ValueKey(isVisible),
            initialValue: isVisible ? value : '••••••••',
            readOnly: true,
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.black),
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: toggleVisibility,
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> colors,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
