import 'package:flutter/material.dart';

/// a box to be displayed in a [TimelineEditorTrack] with a [start] and a [duration]
class TimelineEditorBox {
  /// duration in seconds of the box
  final Duration duration;

  /// the start time in seconds of this box
  final Duration start;

  /// optional  custom child to display in this box
  final Widget child;

  /// background color of this box
  final Color color;

  /// optional [PopupMenuEntry] list to display if a user long press this box
  final List<PopupMenuEntry> menuEntries;

  /// optional callback when a user click on one of the [menuEntries]
  final void Function(Object selectedItem) onSelectedMenuItem;

  ///  optional callback when the box is tapped/clicked
  final void Function(Duration start, Duration duration) onTap;

  /// optional callback that will activate the
  /// possibility of moving this box
  final void Function(Duration duration) onMoved;

  /// if [onMoved] is set this callback will be called when
  /// the user stop the move
  final VoidCallback onMovedEnd;

  const TimelineEditorBox(this.start, this.duration,
      {this.child,
      this.color,
      this.onTap,
      this.menuEntries,
      this.onSelectedMenuItem,
      this.onMoved,
      this.onMovedEnd});
}

/// a box to be displayed in a [TimelineEditorTrack] with only a [start]
/// as the end will be the start of the next box of the timeline
class TimelineEditorContinuousBox {
  /// the start time in seconds of this box
  final Duration start;

  /// the custom child to display in this box
  final Widget child;

  /// background color of this box
  final Color color;

  /// optional [PopupMenuEntry] list to display if a user long press this box
  final List<PopupMenuEntry> menuEntries;

  /// optional callback when a user click on one of the [menuEntries]
  final void Function(Object selectedItem) onSelectedMenuItem;

  ///  optional callback when the box is tapped/clicked
  final void Function(Duration start, Duration duration) onTap;

  /// optional callback that will activate the
  /// possibility of moving this box
  final void Function(Duration seconds) onMoved;

  /// if [onMoved] is set this callback will be called when
  /// the user stop the move
  final VoidCallback onMovedEnd;

  const TimelineEditorContinuousBox(this.start,
      {this.child,
      this.color,
      this.onTap,
      this.menuEntries,
      this.onSelectedMenuItem,
      this.onMoved,
      this.onMovedEnd});
}

/// A track that can be used with the [timeline_editor] builder
class TimelineEditorTrack extends StatefulWidget {
  final List<TimelineEditorBox> boxes;
  final List<TimelineEditorContinuousBox> continuousBoxes;
  final double pixelsPerSeconds;

  /// height of this track
  final double trackHeight;

  final Duration duration;

  final Color defaultColor;

  const TimelineEditorTrack(
      {Key key,
      @required this.boxes,
      @required this.pixelsPerSeconds,
      @required this.duration,
      this.trackHeight = 100,
      this.defaultColor})
      : continuousBoxes = null,
        super(key: key);

  TimelineEditorTrack.fromContinuous(
      {Key key,
      @required this.continuousBoxes,
      @required this.pixelsPerSeconds,
      @required this.duration,
      this.trackHeight = 100,
      this.defaultColor})
      : boxes = null;

  @override
  _TimelineEditorTrackState createState() => _TimelineEditorTrackState();
}

class _TimelineEditorTrackState extends State<TimelineEditorTrack> {
  List<TimelineEditorBox> boxes;

  @override
  void initState() {
    setup();
    super.initState();
  }

  @override
  void didUpdateWidget(TimelineEditorTrack oldWidget) {
    if (oldWidget.continuousBoxes != widget.continuousBoxes ||
        boxes != widget.boxes) {
      setup();
    }
    super.didUpdateWidget(oldWidget);
  }

  void setup() {
    if (widget.boxes != null) {
      boxes = widget.boxes;
    } else {
      var sortedStart = widget.continuousBoxes.toList();
      sortedStart.sort((a, b) => b.start.compareTo(a.start));
      TimelineEditorContinuousBox previous;
      List<TimelineEditorBox> targetBoxes = List<TimelineEditorBox>();
      for (var box in sortedStart) {
        var duration = previous == null
            ? widget.duration - box.start
            : previous.start - box.start;
        previous = box;
        targetBoxes.insert(
            0,
            TimelineEditorBox(
              box.start,
              duration,
              child: box.child,
              color: box.color,
              onTap: box.onTap,
              menuEntries: box.menuEntries,
              onSelectedMenuItem: box.onSelectedMenuItem,
              onMoved: box.onMoved,
              onMovedEnd: box.onMovedEnd,
            ));
      }
      boxes = targetBoxes;
    }
  }

  double globalMoveSinceLastSend = 0;
  void _onDragUpdate(DragUpdateDetails details, TimelineEditorBox box) {
    if (box.onMoved != null) {
      globalMoveSinceLastSend += details.delta.dx;
      var numberOfSeconds = details.delta.dx / widget.pixelsPerSeconds;
      var durationMove =
          Duration(milliseconds: (numberOfSeconds * 1000).toInt());
      if (box.start + durationMove < Duration.zero) {
        box.onMoved(Duration.zero);
      } else
        box.onMoved(durationMove);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      overflow: Overflow.clip,
      children: boxes
          .map((b) => ClipRect(
                child: Builder(
                  builder: (context) => GestureDetector(
                    onTap: b.onTap == null
                        ? null
                        : () => b.onTap(b.start, b.duration),
                    onHorizontalDragStart: b.onMoved == null
                        ? null
                        : (_) => globalMoveSinceLastSend = 0,
                    onHorizontalDragUpdate:
                        b.onMoved == null ? null : (d) => _onDragUpdate(d, b),
                    onHorizontalDragEnd:
                        b.onMovedEnd == null ? null : (_) => b.onMovedEnd(),
                    child: TimelineSlot(
                      pixelPerSeconds: widget.pixelsPerSeconds,
                      height: widget.trackHeight,
                      duration: b.duration,
                      start: b.start,
                      color: b.color ?? widget.defaultColor ?? Colors.red,
                      child: b.child,
                      menuEntries: b.menuEntries,
                      onSelectedMenuItem: b.onSelectedMenuItem,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// used to display a box in the [TimelineEditorTrack]
class TimelineSlot extends StatelessWidget {
  const TimelineSlot({
    Key key,
    @required this.pixelPerSeconds,
    @required this.duration,
    @required this.start,
    @required this.height,
    this.menuEntries,
    this.onSelectedMenuItem,
    this.color,
    this.child,
  }) : super(key: key);

  final double pixelPerSeconds;
  final double height;
  final Duration duration;
  final Duration start;
  final Color color;
  final Widget child;
  final List<PopupMenuEntry> menuEntries;

  /// optional callback when a user click on one of the [menuEntries]
  final void Function(Object selectedItem) onSelectedMenuItem;

  void _showCustomMenu(BuildContext context) async {
    if (menuEntries != null) {
      final RenderBox button = context.findRenderObject();
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(button.size.bottomRight(Offset.zero),
              ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      );

      var result = await showMenu(
          context: context,
          items: menuEntries, //<PopupMenuEntry>[PlusMinusEntry()],
          position: position);
      if (onSelectedMenuItem != null) {
        onSelectedMenuItem(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: (start.inMilliseconds / 1000) * pixelPerSeconds),
      child: SizedBox(
        width: (duration.inMilliseconds / 1000) * pixelPerSeconds,
        height: height ?? 100,
        child: Builder(
          builder: (context) => GestureDetector(
            onLongPress:
                menuEntries == null ? null : () => _showCustomMenu(context),
            child: Card(
              margin: EdgeInsets.all(1.0),
              color: color,
              elevation: 2,
              child: child != null ? child : Container(),
            ),
          ),
        ),
      ),
    );
  }
}
