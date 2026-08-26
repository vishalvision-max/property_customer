import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/services/google_geocoding_service.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/location_provider.dart';

const _orange = Color(0xFFFF8000);

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
      final saved = LatLng(state.lat!, state.lng!);
      setState(() => _center = saved);
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.newLatLng(saved));
      _updateAddress(saved);
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

  /// Small form to name and save an address — used both when picking an
  /// autocomplete suggestion and when confirming a pin dropped on the map.
  /// Purely saves the address; it never navigates into property search.
  Future<void> _showSaveAddressDialog({
    required String initialLabel,
    required double lat,
    required double lng,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _SaveAddressDialog(initialLabel: initialLabel),
    );

    if (name == null) return;
    final savedLabel = name.isEmpty ? initialLabel : name;
    try {
      await ref
          .read(locationProvider.notifier)
          .setPickedLocation(savedLabel, lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save address: $e')));
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber,
        content: Text(
          'Address saved: $savedLabel',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    // Give the snackbar a moment to actually be visible before this screen
    // (and its Scaffold/ScaffoldMessenger) gets popped and removed.
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// "Confirm Location" is the default/primary way of setting the current
  /// location — it sets it directly using the auto-detected address, with no
  /// naming prompt. The naming dialog is only for explicitly saving an
  /// address (via the search bar or the saved-addresses list).
  Future<void> _confirmLocation() async {
    try {
      await ref
          .read(locationProvider.notifier)
          .setPickedLocation(
            _currentAddress,
            _center.latitude,
            _center.longitude,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not set location: $e')));
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber,
        content: Text(
          'Location set: $_currentAddress',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
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
    // Height reserved by the confirm card so the map (and its native controls)
    // are never covered by it.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const confirmCardHeight = 168.0;

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
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            initialCameraPosition: CameraPosition(target: _center, zoom: 15.0),
            padding: EdgeInsets.only(
              top: 72,
              bottom: confirmCardHeight + bottomInset,
            ),
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
          // Center Marker Pin — offset to match the map's visible region,
          // which is shifted up by the confirm card reserved below.
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            bottom: confirmCardHeight + bottomInset,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.0), // Adjust for pin tip
                child: Icon(Icons.location_on, size: 50, color: _orange),
              ),
            ),
          ),
          // Autocomplete Search Bar at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildSearchBar(), _buildSavedAddresses()],
            ),
          ),
          // Confirm Button at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildConfirmCard(),
              ),
            ),
          ),
          // GPS Button
          Positioned(
            bottom: confirmCardHeight + bottomInset + 12,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: _orange,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddresses() {
    final saved = ref.watch(locationProvider).saved;
    if (saved.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: saved.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final addr = saved[i];
            return InputChip(
              backgroundColor: Colors.white,
              avatar: const Icon(
                Icons.history_rounded,
                size: 15,
                color: _orange,
              ),
              label: Text(
                addr.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () async {
                final newCenter = LatLng(addr.lat, addr.lng);
                setState(() => _center = newCenter);
                final controller = await _controller.future;
                await controller.animateCamera(
                  CameraUpdate.newLatLng(newCenter),
                );
                await ref.read(locationProvider.notifier).selectSaved(addr);
                _updateAddress(newCenter);
              },
              onDeleted: () =>
                  ref.read(locationProvider.notifier).removeSaved(addr.label),
            );
          },
        ),
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
      child: Autocomplete<PlacePrediction>(
        displayStringForOption: (option) => option.description,
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.trim().isEmpty) {
            return const Iterable<PlacePrediction>.empty();
          }
          final geocoding = ref.read(googleGeocodingServiceProvider);
          return await geocoding.autocomplete(textEditingValue.text);
        },
        onSelected: (PlacePrediction selection) async {
          // Let RawAutocomplete finish tearing down its suggestions overlay
          // before we push a dialog — doing it in the same frame can crash.
          FocusManager.instance.primaryFocus?.unfocus();
          await Future<void>.delayed(Duration.zero);
          if (!mounted) return;

          double lat = _center.latitude;
          double lng = _center.longitude;
          try {
            final geocoding = ref.read(googleGeocodingServiceProvider);
            final resolved = await geocoding.placeDetails(selection.placeId);
            if (resolved != null) {
              lat = resolved.lat;
              lng = resolved.lng;
              final newCenter = LatLng(lat, lng);
              if (mounted) setState(() => _center = newCenter);
              final controller = await _controller.future;
              await controller.animateCamera(CameraUpdate.newLatLng(newCenter));
            }
          } catch (_) {
            // Fall back to the map's current center if resolving fails.
          }

          if (!mounted) return;
          await _showSaveAddressDialog(
            initialLabel: selection.description,
            lat: lat,
            lng: lng,
          );
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
              const Icon(Icons.place, color: _orange),
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
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed:
                  _isLoadingAddress || _currentAddress == 'Unknown Location'
                  ? null
                  : _confirmLocation,
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

/// Owns its TextEditingController via normal State lifecycle so Flutter only
/// disposes it after this dialog's exit transition actually finishes —
/// disposing it manually right after showDialog() returns races with the
/// still-animating TextField and crashes.
class _SaveAddressDialog extends StatefulWidget {
  final String initialLabel;

  const _SaveAddressDialog({required this.initialLabel});

  @override
  State<_SaveAddressDialog> createState() => _SaveAddressDialogState();
}

class _SaveAddressDialogState extends State<_SaveAddressDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialLabel,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Save Address'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'e.g. Home, Office, Sector 150 Noida',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _orange),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
