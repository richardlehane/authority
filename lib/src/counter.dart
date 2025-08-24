import 'node.dart' show NodeType;

class Counter {
  int count = -1;
  NodeType thisNt = NodeType.rootType;
  int selected = 0;
  NodeType selectedNt = NodeType.termType;

  Counter(this.selected, this.selectedNt);

  int next(NodeType nt) {
    if (!thisNt.termOrClass() && thisNt != nt) count = -1;
    thisNt = nt;
    count++;
    return count;
  }

  bool isSelected() {
    return thisNt == selectedNt && selected == count;
  }
}
