import 'package:flutter/material.dart';
import '../../domain/entities/vehicle.dart';
import '../pages/preview_page.dart';

class SearchSection extends StatefulWidget {
  const SearchSection({
    super.key,
    required this.allVehicles,
    required this.favoriteKeys,
    required this.onToggleFavorite,
  });

  final List<Vehicle> allVehicles;
  final Set<String> favoriteKeys;
  final ValueChanged<Vehicle> onToggleFavorite;

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  String _searchQuery = '';
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            style: const TextStyle(color: Color(0xFFF3EAD5)),
            cursorColor: _gold,
            decoration: InputDecoration(
              hintText: '搜尋特定名稱、品牌、類型...',
              hintStyle: const TextStyle(color: Color(0xFF9C8D67), fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: _gold),
              filled: true,
              fillColor: const Color(0x33000000),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x44D4AF37)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 1.5),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Text(
          '輸入關鍵字以搜尋車款',
          style: TextStyle(color: Color(0xFF9C8D67)),
        ),
      );
    }

    final searchedVehicles = widget.allVehicles.where((vehicle) {
      final model = vehicle.model.toLowerCase();
      final brand = vehicle.brand.toLowerCase();
      final country = vehicle.spec.country.toLowerCase();
      return model.contains(_searchQuery) ||
             brand.contains(_searchQuery) ||
             country.contains(_searchQuery);
    }).toList();

    if (searchedVehicles.isEmpty) {
      return const Center(
        child: Text(
          '找不到符合的車款',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return PreviewPage(
      favoriteKeys: widget.favoriteKeys,
      onToggleFavorite: widget.onToggleFavorite,
      selectedCountries: searchedVehicles.map((v) => v.spec.country).toSet(),
      allApiVehicles: searchedVehicles,
      storageKeyPrefix: 'search_results',
    );
  }
}