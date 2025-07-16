class Counter {
  int count = -1;
  int selected = 0;

  Counter(this.selected);

  int next() {
    count++;
    return count;
  }

  bool isSelected() {
    return selected == count;
  }
}
