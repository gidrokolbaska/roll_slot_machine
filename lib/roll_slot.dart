import 'dart:math';

import 'package:flutter/material.dart';
import 'package:roll_slot_machine/roll_slot_controller.dart';

class RollSlot extends StatefulWidget {
  late final RollSlotController? rollSlotController;

  final List<Widget> children;
  final int numberOfRows;
  final Duration duration;
  final Curve curve;
  final double speed;

  final double diameterRation;

  final double itemExtend;

  final double perspective;

  final double squeeze;
  final Function(List<int>)? onSelected;

  final bool shuffleList;

  final bool additionalListToEndAndStart;

  final EdgeInsets itemPadding;

  RollSlot({
    Key? key,
    required this.itemExtend,
    required this.children,
    this.numberOfRows = 1,
    this.rollSlotController,
    this.duration = const Duration(milliseconds: 3600),
    this.curve = Curves.elasticOut,
    this.speed = 1.6,
    this.diameterRation = 1,
    this.perspective = 0.002,
    this.squeeze = 1.4,
    this.shuffleList = true,
    this.onSelected,
    this.additionalListToEndAndStart = true,
    this.itemPadding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  _RollSlotState createState() => _RollSlotState();
}

class _RollSlotState extends State<RollSlot> {
  List<FixedExtentScrollController> _controllers = [];

  int currentIndex = 0;
  final List<int> results = [];
  bool canRoll = true;
  @override
  void initState() {
    addRollSlotControllerListener();
    for (var i = 0; i < widget.numberOfRows; i++) {
      _controllers.add(FixedExtentScrollController());
      addListenerScrollController(_controllers[i]);
    }

    super.initState();
  }

  @override
  void dispose() {
    _controllers.forEach((element) {
      element.dispose();
    });
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _controllers
          .map(
            (scrollController) => Flexible(
              child: ListWheelScrollView.useDelegate(
                physics: FixedExtentScrollPhysics(
                    parent: NeverScrollableScrollPhysics()),
                itemExtent: widget.itemExtend,
                diameterRatio: widget.diameterRation,
                controller: scrollController,
                squeeze: widget.squeeze,
                perspective: widget.perspective,
                childDelegate: ListWheelChildLoopingListDelegate(
                  children: widget.children.map(
                    (_widget) {
                      return Padding(
                        padding: widget.itemPadding,
                        child: _widget,
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void addRollSlotControllerListener() {
    if (widget.rollSlotController != null) {
      widget.rollSlotController!.addListener(() {
        if (widget.rollSlotController!.state ==
            RollSlotControllerState.animateRandomly) {
          animateToRandomly();
        }
      });
    }
  }

  void addListenerScrollController(
      FixedExtentScrollController scrollController) {
    scrollController.addListener(() {
      final currentScrollPixels = scrollController.position.pixels;
      if (currentScrollPixels % widget.itemExtend == 0) {
        currentIndex =
            (currentScrollPixels ~/ widget.itemExtend) % widget.children.length;

        results.add(currentIndex);
        print(results.length);
      }
    });
  }

  /// Gets the [randomIndex] an animate the [RollSlot] to that item
  Future<void> animateToRandomly() async {
    if (canRoll) {
      canRoll = false;
      results.clear();
      results.length = 0;

      late int random;
      List<Future> listOfFutures = [];

      for (var i = 0; i < _controllers.length; i++) {
        random = randomIndex();

        listOfFutures.add(_controllers[i].animateTo(
          random * widget.itemExtend,
          curve: Curves.elasticInOut,
          duration: widget.duration * (1 / widget.speed),
        ));
      }
      await Future.wait(listOfFutures);
      if (widget.onSelected != null) {
        widget.onSelected!(results);
      }
      canRoll = true;
    } else
      return null;
  }

  /// Returns a random number.
  int randomIndex() {
    int randomInt;

    randomInt = Random().nextInt(widget.children.length * 123);

    return randomInt == currentIndex ? randomIndex() : randomInt;
  }
}
