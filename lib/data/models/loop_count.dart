enum LoopCount {
  five(5, '5×'),
  ten(10, '10×'),
  twentyFive(25, '25×'),
  unlimited(-1, 'Unlimited');

  const LoopCount(this.value, this.label);

  final int value;
  final String label;

  bool get isUnlimited => value < 0;
}
