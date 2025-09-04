import 'package:fluent_ui/fluent_ui.dart'
    show TreeViewItem, FluentIcons, Icon, SizedBox, Text;
import 'node.dart' show NodeType;

class Counter {
  int count = -1;
  NodeType thisNt = NodeType.rootType;
  int selected = 0;
  NodeType selectedNt = NodeType.termType;

  Counter(this.selected, this.selectedNt);

  int next(NodeType nt) {
    if (!thisNt.like(nt)) count = -1;
    thisNt = nt;
    count++;
    return count;
  }

  bool isSelected() {
    return thisNt == selectedNt && selected == count;
  }
}

enum TreeOp { drop, child, sibling, up, down }

TreeViewItem makeItem(
  int n,
  NodeType nt,
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
    leading: switch (nt) {
      NodeType.termType => Icon(FluentIcons.fabric_folder),
      NodeType.classType => Icon(FluentIcons.page),
      NodeType.contextType => Icon(FluentIcons.page_list),
      _ => null,
    },
    content: (label == null) ? SizedBox() : Text(label),
    value: (nt, n),
    selected: selected,
    children: list,
  );
}

TreeViewItem? treeNth(int n, NodeType nt, List<TreeViewItem>? list) {
  if (list == null) return null;
  TreeViewItem? prev;
  for (final element in list) {
    if (!nt.like(element.value.$1)) continue;
    if (element.value.$2 == n) {
      return element;
    }
    if (element.value.$2 > n) {
      if (prev != null) {
        final TreeViewItem? el = treeNth(n, nt, prev.children);
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

// to do: implement!
List<TreeViewItem> mutate(
  List<TreeViewItem> old,
  TreeOp op,
  int n,
  NodeType nt,
  String? itemno,
  String? title,
) {
  return [];
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

bool prune(int n, NodeType nt, List<TreeViewItem>? list, TreeOp op) {
  if (list == null) return false;
  TreeViewItem? prev;
  int idx = 0;
  for (final element in list) {
    if (!nt.like(element.value.$1)) continue;
    if (element.value.$2 == n) {
      switch (op) {
        case TreeOp.drop:
          list.removeAt(idx);
        case TreeOp.child:
          element.children.add(makeItem(0, nt, false, null, null, []));
        case TreeOp.sibling:
          list.insert(idx, makeItem(0, nt, false, null, null, []));
        default:
      }
      return true;
    }
    if (element.value.$2 > n) {
      if (prev != null) {
        if (prune(n, nt, prev.children, op)) return true;
      } else {
        return false;
      }
    }
    idx++;
    prev = element;
  }
  return false;
}
