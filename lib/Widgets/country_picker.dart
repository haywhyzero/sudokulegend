import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

void showCountryPickerBottomSheet(BuildContext context) {
  showCountryPicker(
    context: context,
    showPhoneCode: false, // set true if you want phone codes too
    countryListTheme: CountryListThemeData(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      backgroundColor: Colors.white,
      inputDecoration: InputDecoration(
        hintText: "Search country",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      searchTextStyle: const TextStyle(fontSize: 16),
      bottomSheetHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    onSelect: (Country country) {
      print('Selected country: ${country.name} ${country.flagEmoji}');
      // Save to your user profile here
      Navigator.pop(context);
    },
  );
}