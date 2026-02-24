import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_strings.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.properties),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter options
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Properties will be displayed here'),
      ),
    );
  }
}
