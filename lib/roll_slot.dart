import 'dart:math';

import 'package:flutter/material.dart';
import 'package:roll_slot_machine/roll_slot_controller.dart';

typedef void SelectedItemCallback({
  required int currentIndex,
  required Widget currentWidget,
});

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

  final SelectedItemCallback? onItemSelected;

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
    this.onItemSelected,
    this.shuffleList = true,
    this.additionalListToEndAndStart = true,
    this.itemPadding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  _RollSlotState createState() => _RollSlotState();
}

class _RollSlotState extends State<RollSlot> {
  List<FixedExtentScrollController> _controllers = [];
  List<Widget> currentList = [];
  int currentIndex = 0;

  @override
  void initState() {
    //shuffleAndFillTheList();
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

  void addListenerScrollController(ScrollController scrollController) {
    scrollController.addListener(() {
      final currentScrollPixels = scrollController.position.pixels;
      if (currentScrollPixels % widget.itemExtend == 0) {
        currentIndex = currentScrollPixels ~/ widget.itemExtend;
        final Widget currentWidget = currentList.elementAt(currentIndex);
        print('index : $currentIndex');
        if (widget.onItemSelected != null) {
          widget.onItemSelected!(
            currentIndex: currentIndex,
            currentWidget: currentWidget,
          );
        }
      }
    });
  }

  void shuffleAndFillTheList() {
    if (widget.children.isNotEmpty) {
      double d = (widget.duration.inMilliseconds / 100);
      if (widget.additionalListToEndAndStart) {
        addToCurrentList();
      }
      while (currentList.length < d) {
        addToCurrentList();
      }
      if (widget.additionalListToEndAndStart) {
        addToCurrentList();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          jump();
        });
      }
    }
  }

  /// Gets the [randomIndex] an animate the [RollSlot] to that item
  Future<void> animateToRandomly() async {
    // await _controllers[0].animateTo(
    //   random * widget.itemExtend,
    //   curve: Curves.elasticInOut,
    //   duration: widget.duration * (1 / widget.speed),
    // );
    late int random;
    List<Future> listOfFutures = [];

    for (var i = 0; i < _controllers.length; i++) {
      random = randomIndex();
      listOfFutures.add(_controllers[i].animateTo(
        random * widget.itemExtend,
        curve: Curves.elasticInOut,
        duration: widget.duration * (1 / widget.speed),
      ));
      // await _controllers[i].animateTo(
      //   random * widget.itemExtend,
      //   curve: Curves.elasticInOut,
      //   duration: widget.duration * (1 / widget.speed),
      // );
    }
    await Future.wait(listOfFutures);

    // _controllers.forEach((element) async {
    //   random = randomIndex();

    //   await element.animateTo(
    //     random * widget.itemExtend,
    //     curve: Curves.elasticInOut,
    //     duration: widget.duration * (1 / widget.speed),
    //   );
    // });

    if (widget.rollSlotController != null) {
      widget.rollSlotController!.currentIndex = random % widget.children.length;
    }
  }

  /// When [additionalListToEndAndStart] is true,
  /// This method adds the [widget.children] to beginning and end of the list
  ///
  /// for being able to show items if the random number hits edge cases
  void addToCurrentList() {
    setState(() {
      if (widget.shuffleList) {
        currentList.addAll(widget.children.toList()..shuffle());
      } else {
        currentList.addAll(widget.children.toList());
      }
    });
  }

  /// Helping to jump the first item that can be random.
  ///
  /// It is using only when the [additionalListToEndAndStart] is true.
  void jump() {
    _controllers.forEach((element) {
      element.jumpTo(widget.itemExtend * widget.children.length);
    });
  }

  /// Returns a random number.
  int randomIndex() {
    int randomInt;

    randomInt = Random().nextInt(widget.children.length);
    return randomInt == currentIndex ? randomIndex() : randomInt;
  }
}
