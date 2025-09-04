import 'package:fluent_ui/fluent_ui.dart'
    show FluentIcons, Icon, ItemExtension, SizedBox, Text, TreeViewItem;
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

TreeViewItem copyItemWithChildren(TreeViewItem old, List<TreeViewItem> list) {
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
    value: old.value,
    selected: old.selected,
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

bool treeContains(List<TreeViewItem> list, int n, NodeType nt) {
  for (final element in list) {
    if (element.value.$1 == nt && element.value.$2 == n) return true;
  }
  return false;
}

TreeViewItem Function(int i) dropGenerator(
  List<TreeViewItem> old,
  (NodeType, int) rec,
) {
  bool seen = false;

  return (int i) {
    if (old[i].value == rec) seen = true;
    if (seen) i++;
    return copyItemWithChildren(
      old[i],
      List.generate(
        treeContains(old[i].children, rec.$2, rec.$1)
            ? old[i].children.length - 1
            : old[i].children.length,
        dropGenerator(old[i].children, rec),
      ),
    );
  };
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
  return List.generate(
    treeContains(old, n, nt) ? old.length - 1 : old.length,
    dropGenerator(old, (nt, n)),
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
