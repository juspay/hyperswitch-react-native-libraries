@module("react-native") @scope("UIManager")
external dispatchViewManagerCommand: (
  ~viewId: int,
  ~commandId: int,
  ~commandArgs: array<int>,
) => unit = "dispatchViewManagerCommand"
