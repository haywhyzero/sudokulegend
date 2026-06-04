import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_riverpod/legacy.dart';

class ProfileState {
  final String name;
  final String username;
  final String email;
  final Country? country;
  final String? avatarUrl;
  final File? localAvatar;

  const ProfileState({
    this.name = '',
    this.username = '',
    this.email = '',
    this.country,
    this.avatarUrl,
    this.localAvatar,
  });

  ProfileState copyWith({
    String? name,
    String? username,
    String? email,
    Country? country,
    String? avatarUrl,
    File? localAvatar,
  }) =>
      ProfileState(
        name: name ?? this.name,
        username: username ?? this.username,
        email: email ?? this.email,
        country: country ?? this.country,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        localAvatar: localAvatar ?? this.localAvatar,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  ProfileNotifier()
      : super(const ProfileState(
          name: 'Guest',
          username: 'anon',
          email: 'Login to edit profile',
          country: null,
        ));

  Future<void> updateProfile({
    required String name,
    required String username,
    required String email,
    Country? country,
  }) async {
    state = state.copyWith(
      name: name,
      username: username,
      email: email,
      country: country,
    );

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'username': username,
          'email': email,
          'country': country?.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving profile to Firestore: $e');
      }
    }
  }

  Future<void> updateAvatar(File file) async {
    state = state.copyWith(localAvatar: file);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final fileName = 'avatars/${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        final ref = _storage.ref().child(fileName);
        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        state = state.copyWith(avatarUrl: url, localAvatar: null);

        await _firestore.collection('users').doc(user.uid).update({
          'avatarUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error uploading avatar: $e');
      }
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
