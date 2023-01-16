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
  final Curve animationCurve;

  final double diameterRation;

  final double itemExtend;

  final double perspective;

  final double squeeze;

  final Function(
      {List<int>? upperResults,
      List<int>? currentResults,
      List<int>? belowResults})? onSelected;

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
    this.animationCurve = Curves.elasticInOut,
    this.onSelected,
    this.itemPadding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  _RollSlotState createState() => _RollSlotState();
}

class _RollSlotState extends State<RollSlot> {
  List<FixedExtentScrollController> _controllers = [];
  List<List<Widget>> _items = [];
  final List<int> currentIndexes = [];
  final List<int> belowIndexes = [];
  final List<int> upperIndexes = [];
  bool isAlreadyFetched = false;

  bool canRoll = true;
  @override
  void initState() {
    addRollSlotControllerListener();

    for (var i = 0; i < widget.numberOfRows; i++) {
      _items.add([]);
      _controllers.add(
        FixedExtentScrollController(
            // initialItem: Random().nextInt(
            //   widget.children.length,
            // ),
            ),
      );
      _items[i].addAll(widget.children);
      _items[i].shuffle();
      currentIndexes.add(0);
      upperIndexes.add(0);
      belowIndexes.add(0);
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
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (widget.onSelected != null && isAlreadyFetched == false) {
          widget.onSelected!(
            currentResults: currentIndexes,
            belowResults: belowIndexes,
            upperResults: upperIndexes,
          );
          isAlreadyFetched = true;
          return true;
        } else {
          return false;
        }
      },
      child: Row(
        children: _controllers
            .map(
              (scrollController) => Flexible(
                child: ListWheelScrollView.useDelegate(
                  onSelectedItemChanged: (value) {
                    currentIndexes[_controllers.indexOf(scrollController)] =
                        value;
                    upperIndexes[_controllers.indexOf(scrollController)] =
                        ((value - 1) % widget.children.length);
                    belowIndexes[_controllers.indexOf(scrollController)] =
                        ((value + 1) % widget.children.length);
                  },
                  physics: FixedExtentScrollPhysics(
                      parent: NeverScrollableScrollPhysics()),
                  itemExtent: widget.itemExtend,
                  diameterRatio: widget.diameterRation,
                  controller: scrollController,
                  squeeze: widget.squeeze,
                  perspective: widget.perspective,
                  childDelegate: ListWheelChildLoopingListDelegate(
                    children:
                        _items[_controllers.indexOf(scrollController)].map(
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
      ),
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

  /// Gets the [randomIndex] an animate the [RollSlot] to that item
  Future<void> animateToRandomly() async {
    if (canRoll) {
      canRoll = false;
      isAlreadyFetched = false;
      late int random;
      List<Future> listOfFutures = [];

      for (var i = 0; i < _controllers.length; i++) {
        random = randomIndex(i);

        listOfFutures.add(
          _controllers[i].animateTo(
            random * widget.itemExtend,
            curve: widget.animationCurve,
            duration: widget.duration * (1 / widget.speed),
          ),
        );
      }
      await Future.wait(listOfFutures);

      canRoll = true;
    } else
      return null;
  }

  /// Returns a random number.
  int randomIndex(int i) {
    int randomInt;

    randomInt = Random().nextInt(widget.children.length * 123);

    return randomInt == currentIndexes[i] ? randomIndex(i) : randomInt;
  }
}
