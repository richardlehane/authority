import 'package:fluent_ui/fluent_ui.dart'
    show FluentIcons, Icon, SizedBox, Text, TreeViewItem;
import 'node.dart' show NodeType;

typedef Ref = (NodeType, int);

class Counter {
  int count = -1;
  NodeType thisNt = NodeType.rootType;
  Ref selected;

  Counter([this.selected = (NodeType.termType, 0)]);

  int next(NodeType nt) {
    if (!thisNt.like(nt)) count = -1;
    thisNt = nt;
    count++;
    return count;
  }

  bool isSelected() {
    return thisNt == selected.$1 && count == selected.$2;
  }
}

enum TreeOp { drop, child, sibling, up, down }

TreeViewItem makeItem(
  Ref ref,
  bool selected,
  String? itemno,
  String? title,
  List<TreeViewItem> list,
) {
  final label = (itemno == null && title == null)
      ? null
      : (itemno == null)
      ? title
      : (title == null)
      ? itemno
      : "$itemno ${title}";
  return TreeViewItem(
    leading: switch (ref.$1) {
      NodeType.termType => Icon(FluentIcons.fabric_folder),
      NodeType.classType => Icon(FluentIcons.page),
      NodeType.contextType => Icon(FluentIcons.page_list),
      _ => null,
    },
    content: (label == null) ? SizedBox() : Text(label),
    value: ref,
    selected: selected,
    children: list,
  );
}

TreeViewItem? treeNth(Ref ref, List<TreeViewItem>? list) {
  if (list == null) return null;
  TreeViewItem? prev;
  for (final element in list) {
    if (!ref.$1.like(element.value.$1)) continue;
    if (element.value == ref) {
      return element;
    }
    if (element.value.$2 > ref.$2) {
      if (prev != null) {
        final TreeViewItem? el = treeNth(ref, prev.children);
        if (el != null) {
          return el;
        }
      } else {
        return null;
      }
    }
    prev = element;
  }
  return null;
}

int treeDescendants(TreeViewItem item) {
  int tally = item.children.length;
  for (final element in item.children) {
    tally += treeDescendants(element);
  }
  return tally;
}

bool _treeContains(List<TreeViewItem> list, Ref ref) {
  for (final element in list) {
    if (element.value == ref) return true;
  }
  return false;
}

TreeViewItem _copyItemWithChildren(
  TreeViewItem old,
  List<TreeViewItem> list, {
  Counter? ctr,
}) {
  return TreeViewItem(
    leading: switch (old.value.$1) {
      NodeType.termType => Icon(FluentIcons.fabric_folder),
      NodeType.classType => Icon(FluentIcons.page),
      NodeType.contextType => Icon(FluentIcons.page_list),
      _ => null,
    },
    content: (old.content is Text)
        ? Text((old.content as Text).data!)
        : SizedBox(),
    value: (ctr == null) ? old.value : (old.value.$1, ctr.next(old.value.$1)),
    selected: (ctr == null) ? old.selected : ctr.isSelected(),
    expanded: old.expanded,
    children: list,
  );
}

TreeViewItem Function(int i) _dropGenerator(
  List<TreeViewItem> old,
  Ref ref,
  Counter ctr,
) {
  bool seen = false;

  return (int i) {
    if (old[i].value == ref) seen = true;
    if (seen) i++;
    return _copyItemWithChildren(
      old[i],
      List.generate(
        _treeContains(old[i].children, ref)
            ? old[i].children.length - 1
            : old[i].children.length,
        _dropGenerator(old[i].children, ref, ctr),
      ),
      ctr: ctr,
    );
  };
}

// to do: implement!
List<TreeViewItem> mutate(
  List<TreeViewItem> old,
  TreeOp op,
  Ref ref, {
  Counter? ctr,
  NodeType? nt,
  String? itemno,
  String? title,
}) {
  return List.generate(
    _treeContains(old, ref) ? old.length - 1 : old.length,
    _dropGenerator(old, ref, ctr!),
  );
}

bool treesEqual(List<TreeViewItem> a, List<TreeViewItem> b) {
  if (a.length != b.length) return false;
  for (final ea in a) {
    for (final eb in b) {
      if (ea.value != eb.value) return false;
      if (ea.selected != eb.selected) return false;
      if (!(treesEqual(ea.children, eb.children))) return false;
    }
  }
  return true;
}
