import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/location_provider.dart';
import 'package:go_router/go_router.dart';
import '../property/property_name_search_args.dart';

class MapLocationScreen extends ConsumerStatefulWidget {
  const MapLocationScreen({super.key});

  @override
  ConsumerState<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends ConsumerState<MapLocationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _center = const LatLng(20.5937, 78.9629); // India default
  bool _isLoadingAddress = false;
  String _currentAddress = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _determineInitialLocation();
  }

  Future<void> _determineInitialLocation() async {
    final state = ref.read(locationProvider);
    if (state.lat != null && state.lng != null) {
      _center = LatLng(state.lat!, state.lng!);
      _updateAddress(_center);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
      });
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_center));
      _updateAddress(_center);
    } catch (e) {
      // Fallback to default
      _updateAddress(_center);
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    final geocoding = ref.read(googleGeocodingServiceProvider);
    final label = await geocoding.reverseGeocode(
      lat: position.latitude,
      lng: position.longitude,
    );
    if (mounted) {
      setState(() {
        _currentAddress = label ?? 'Unknown Location';
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final GoogleMapController controller = await _controller.future;
      final newCenter = LatLng(pos.latitude, pos.longitude);
      controller.animateCamera(CameraUpdate.newLatLng(newCenter));
      _updateAddress(newCenter);
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Choose Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            initialCameraPosition: CameraPosition(target: _center, zoom: 15.0),
            onCameraMove: (position) {
              _center = position.target;
            },
            onCameraIdle: () {
              _updateAddress(_center);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Center Marker Pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Adjust for pin tip
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ),
          // Autocomplete Search Bar at the top
          Positioned(top: 16, left: 16, right: 16, child: _buildSearchBar()),
          // Confirm Button at the bottom
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: _buildConfirmCard(),
          ),
          // GPS Button
          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6C5CE7),
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.trim().isEmpty)
            return const Iterable<String>.empty();
          final geocoding = ref.read(googleGeocodingServiceProvider);
          return await geocoding.autocomplete(textEditingValue.text);
        },
        onSelected: (String selection) async {
          await ref.read(locationProvider.notifier).setManual(selection);
          if (mounted) {
            Navigator.of(context).pop();
            context.push('/name-search-results', extra: PropertyNameSearchArgs(query: selection, mode: ''));
          }
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Search for a locality or city...',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Location',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLoadingAddress ? 'Loading...' : _currentAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed:
                  _isLoadingAddress || _currentAddress == 'Unknown Location'
                  ? null
                  : () async {
                      await ref
                          .read(locationProvider.notifier)
                          .setPickedLocation(
                            _currentAddress,
                            _center.latitude,
                            _center.longitude,
                          );
                      if (mounted) {
                        Navigator.of(context).pop();
                        context.push('/name-search-results', extra: PropertyNameSearchArgs(query: _currentAddress, mode: ''));
                      }
                    },
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
