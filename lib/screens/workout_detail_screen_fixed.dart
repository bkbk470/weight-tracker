// This is a test file to verify the syntax
// The error is on line 1046 where there's a space before the spread operator
// It should be: if (exercise.sets.length > 1) ...[
// NOT: if (exercise.sets.length > 1) ..[

void main() {
  // Correct syntax:
  if (true) ...[
    print('This is correct'),
  ];
  
  // The error was probably this (note the space):
  // if (true) ..[
  //   print('This causes syntax error'),
  // ];
}
