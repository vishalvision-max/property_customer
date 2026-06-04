import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class ScheduledVisitsScreen extends StatelessWidget {
  const ScheduledVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('My Scheduled Visits'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: const EmptyState(
              title: 'No scheduled visits yet',
              message: 'You have not scheduled any property visits yet.',
              asset: 'assets/illustrations/empty_favorites.svg',
            ),
          ),
        ),
      ),
    );
  }
}
