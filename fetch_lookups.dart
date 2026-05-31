// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  final typesReq = await client.getUrl(Uri.parse('https://houseiana-api-prod.jollyisland-881a1746.eastus.azurecontainerapps.io/api/lookups/PropertyType'));
  final typesRes = await typesReq.close();
  final typesBody = await typesRes.transform(utf8.decoder).join();
  print('Property Types:');
  print(typesBody);

  final amReq = await client.getUrl(Uri.parse('https://houseiana-api-prod.jollyisland-881a1746.eastus.azurecontainerapps.io/api/lookups/Amenities'));
  final amRes = await amReq.close();
  final amBody = await amRes.transform(utf8.decoder).join();
  print('Amenities:');
  print(amBody);
  
  client.close();
}
