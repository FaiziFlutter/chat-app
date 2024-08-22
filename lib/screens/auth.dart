import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:chat_app/authentication_file/firebase_credentials.dart';
import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  bool _isLogIn = true;
  var _email = '';
  var _password = '';
  bool isAuntheticating = false;
  File? _selectedImage;

  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid || !_isLogIn && _selectedImage == null) {
      return;
    }
    _form.currentState!.save();
    try {
      setState(() {
        isAuntheticating = true;
      });
      if (_isLogIn) {
        final userCredential = await firebaseAuthInstance
            .signInWithEmailAndPassword(email: _email, password: _password);
      } else {
        final userCredential = await firebaseAuthInstance
            .createUserWithEmailAndPassword(email: _email, password: _password);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_image')
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = storageRef.getDownloadURL();
        print(imageUrl);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication Failed.'),
        ),
      );
      setState(() {
        isAuntheticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: width,
                height: height * 0.4,
                child: Image.asset(
                  'assets/chat.png',
                ),
              ),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      if (!_isLogIn)
                        UserImagePicker(
                          image: (image) {
                            _selectedImage = image;
                          },
                        ),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _email = newValue!;
                        },
                      ),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _password = newValue!;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (isAuntheticating) const CircularProgressIndicator(),
                      if (!isAuntheticating)
                        ElevatedButton(
                          onPressed: _submit,
                          child: _isLogIn
                              ? const Text('Log In')
                              : const Text('Sign Up'),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogIn = !_isLogIn;
                          });
                        },
                        child: Text(
                          _isLogIn
                              ? "Create an Account"
                              : "Already have an account",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
