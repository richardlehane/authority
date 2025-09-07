import 'package:fluent_ui/fluent_ui.dart'
    show FluentIcons, Icon, SizedBox, Text, TreeViewItem;
import 'node.dart' show NodeType;

typedef Ref = (NodeType, int);

enum TreeOp { drop, child, sibling, up, down }

class TreeNode {
  Ref ref = (NodeType.none, 0);
  String? itemno;
  String? title;
  List<TreeNode>? children;

  TreeNode(this.ref, this.itemno, this.title, this.children);

  bool equals(TreeNode n) {
    if (ref != n.ref) return false;
    if (itemno != n.itemno) return false;
    if (title != n.title) return false;
    if (children?.length != n.children?.length) return false;
    if (children == null && n.children == null) return true;
    for (int i = 0; i < children!.length; i++) {
      if (!children![i].equals(n.children![i])) return false;
    }
    return true;
  }
}

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

List<TreeViewItem> treeFrom(List<TreeNode> nodes) {
  return List<TreeViewItem>.generate(
    nodes.length,
    (int i) => makeItem(
      nodes[i].ref,
      nodes[i].itemno,
      nodes[i].title,
      nodes[i].children,
    ),
  );
}

TreeViewItem makeItem(
  Ref ref,
  String? itemno,
  String? title,
  List<TreeNode>? list,
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
    children: (list == null) ? [] : treeFrom(list),
  );
}

Ref? getSelected(List<TreeViewItem>? list) {
  if (list == null) return null;
  for (final element in list) {
    if (element.selected ?? false) return element.value;
    final cref = getSelected(element.children);
    if (cref != null) return cref;
  }
  return null;
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
  int? index,
  bool? selected,
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
    value: (index == null) ? old.value : (old.value.$1, index),
    selected: (selected == null) ? old.selected : selected,
    expanded: old.expanded,
    children: list,
  );
}

TreeViewItem Function(int i) _moveGenerator(
  List<TreeViewItem> old,
  Ref ref,
  Counter ctr,
  bool up,
) {
  return (int i) {
    if (up) {
      if (old[i].value.ref.$1.like(ref.$1)) {
        if (up && i < old.length - 1 && old[i].value.ref == ref) {
          i++;
        } else if (old[i].value.ref == ref) {
          if (up) {
            if (i > 0) i--;
          } else {
            if (i < old.length - 1) i++;
          }
        } else if (!up && i > 0 && old[i - 1].value.ref == ref) {
          i--;
        }
      }
    }
    int index = ctr.next(old[i].value.$1);
    bool selected = ctr.isSelected();
    return _copyItemWithChildren(
      old[i],
      List.generate(
        old[i].children.length,
        _moveGenerator(old[i].children, ref, ctr, up),
      ),
      index: index,
      selected: selected,
    );
  };
}

TreeViewItem Function(int i) _siblingGenerator(
  List<TreeViewItem> old,
  Ref ref,
  Counter ctr,
  NodeType nt,
) {
  bool next = false;
  bool decrement = false;

  return (int i) {
    if (next) {
      next = false;
      decrement = true;
      final ti = makeItem((nt, ctr.next(nt)), null, null, []);
      ti.selected = true;
      return ti;
    }
    if (decrement) {
      i--;
    } else if (old[i].value == ref) {
      next = true;
    }
    int index = ctr.next(old[i].value.$1);
    return _copyItemWithChildren(
      old[i],
      List.generate(
        _treeContains(old[i].children, ref)
            ? old[i].children.length + 1
            : old[i].children.length,
        _siblingGenerator(old[i].children, ref, ctr, nt),
      ),
      index: index,
      selected: false,
    );
  };
}

TreeViewItem Function(int i) _childGenerator(
  List<TreeViewItem> old,
  Ref ref,
  Counter ctr,
  NodeType nt,
) {
  return (int i) {
    // add child as the last sibling
    if (i == old.length) {
      final ti = makeItem((nt, ctr.next(nt)), null, null, []);
      ti.selected = true;
      return ti;
    }
    int index = ctr.next(old[i].value.$1);
    return _copyItemWithChildren(
      old[i],
      List.generate(
        (old[i].value == ref)
            ? old[i].children.length + 1
            : old[i].children.length,
        _childGenerator(old[i].children, ref, ctr, nt),
      ),
      index: index,
      selected: false,
    );
  };
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
    int index = ctr.next(old[i].value.$1);
    bool selected = ctr.isSelected();
    return _copyItemWithChildren(
      old[i],
      List.generate(
        _treeContains(old[i].children, ref)
            ? old[i].children.length - 1
            : old[i].children.length,
        _dropGenerator(old[i].children, ref, ctr),
      ),
      index: index,
      selected: selected,
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
  TreeNode? node, // for copy/paste
}) {
  switch (op) {
    case TreeOp.sibling:
      return List.generate(
        _treeContains(old, ref) ? old.length + 1 : old.length,
        _siblingGenerator(old, ref, ctr!, nt!),
      );
    case TreeOp.child:
      return List.generate(
        (ref.$1 == NodeType.contextType) ? old.length + 1 : old.length,
        _childGenerator(old, ref, ctr!, nt!),
      );
    case TreeOp.up:
      return List.generate(old.length, _moveGenerator(old, ref, ctr!, true));
    case TreeOp.down:
      return List.generate(old.length, _moveGenerator(old, ref, ctr!, false));
    default:
      return List.generate(
        _treeContains(old, ref) ? old.length - 1 : old.length,
        _dropGenerator(old, ref, ctr!),
      );
  }
}
