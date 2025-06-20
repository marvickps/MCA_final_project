import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/route_controller.dart';
import '../widgets/map_widget.dart';
import '../widgets/route_info_widget.dart';
import '../widgets/summary_widget.dart';

class ItineraryMapScreen extends StatefulWidget {
  final int id;
  final String day;

  const ItineraryMapScreen({Key? key, required this.id, required this.day}) : super(key: key);

  @override
  State<ItineraryMapScreen> createState() => _ItineraryMapScreenState();
}

class _ItineraryMapScreenState extends State<ItineraryMapScreen> {
  bool _showInfo = true;
  int _selectedTabIndex = 0;
  double _infoPanelRatio = 0.3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ItineraryRouteController>(
        context,
        listen: false,
      );
      controller.loadSampleItineraryData(widget.id , widget.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Itinerary'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final controller = Provider.of<ItineraryRouteController>(
                context,
                listen: false,
              );
              controller.loadSampleItineraryData(widget.id, widget.day);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final mapHeight = _showInfo ? height * (1 - _infoPanelRatio) : height;
          final double infoHeight = _showInfo ? height * _infoPanelRatio : 0;

          return Column(
            children: [
              SizedBox(
                height: mapHeight,
                child: ItineraryMapWidget(id: widget.id, day: widget.day),
              ),
              if (_showInfo)
                SizedBox(
                  height: infoHeight,
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            _infoPanelRatio -= details.delta.dy / height;
                            _infoPanelRatio = _infoPanelRatio.clamp(0.2, 0.8);
                          });
                        },
                        child: Container(
                          color: Colors.grey[400],
                          height: 8,
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedTabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedTabIndex == 0
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        width: 3.0,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.summarize,
                                          color: _selectedTabIndex == 0
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Trip Summary',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _selectedTabIndex == 0
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedTabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedTabIndex == 1
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        width: 3.0,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: _selectedTabIndex == 1
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Daily Itinerary',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _selectedTabIndex == 1
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedTabIndex,
                          children: const [
                            TripSummaryWidget(),
                            ItineraryInfoWidget(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showInfo = !_showInfo;
          });
        },
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        child: Icon(_showInfo ? Icons.expand_more : Icons.expand_less),
      ),
    );
  }
}
