class QspAction {
  final int index;
  final String name;
  final String image;

  const QspAction({
    required this.index,
    required this.name,
    required this.image,
  });

  @override
  String toString() => 'QspAction($index: "$name", image: "$image")';
}

class QspObject {
  final int index;
  final String name;
  final String image;

  const QspObject({
    required this.index,
    required this.name,
    required this.image,
  });

  @override
  String toString() => 'QspObject($index: "$name", image: "$image")';
}

class QspMenuItem {
  final String name;
  final String image;

  const QspMenuItem({
    required this.name,
    required this.image,
  });
}

class QspErrorInfo {
  final int errorNum;
  final String errorDesc;
  final String locName;
  final int actIndex;
  final int lineNum;
  final String codeLine;

  const QspErrorInfo({
    required this.errorNum,
    required this.errorDesc,
    required this.locName,
    required this.actIndex,
    required this.lineNum,
    required this.codeLine,
  });

  @override
  String toString() =>
      'QspErrorInfo(#$errorNum: $errorDesc in $locName line $lineNum)';
}

class QspGameState {
  final String mainDesc;
  final String varsDesc;
  final List<QspAction> actions;
  final List<QspObject> objects;
  final bool isMainDescChanged;
  final bool isVarsDescChanged;
  final bool isActionsChanged;
  final bool isObjectsChanged;

  const QspGameState({
    this.mainDesc = '',
    this.varsDesc = '',
    this.actions = const [],
    this.objects = const [],
    this.isMainDescChanged = false,
    this.isVarsDescChanged = false,
    this.isActionsChanged = false,
    this.isObjectsChanged = false,
  });

  QspGameState copyWith({
    String? mainDesc,
    String? varsDesc,
    List<QspAction>? actions,
    List<QspObject>? objects,
    bool? isMainDescChanged,
    bool? isVarsDescChanged,
    bool? isActionsChanged,
    bool? isObjectsChanged,
  }) {
    return QspGameState(
      mainDesc: mainDesc ?? this.mainDesc,
      varsDesc: varsDesc ?? this.varsDesc,
      actions: actions ?? this.actions,
      objects: objects ?? this.objects,
      isMainDescChanged: isMainDescChanged ?? this.isMainDescChanged,
      isVarsDescChanged: isVarsDescChanged ?? this.isVarsDescChanged,
      isActionsChanged: isActionsChanged ?? this.isActionsChanged,
      isObjectsChanged: isObjectsChanged ?? this.isObjectsChanged,
    );
  }
}
