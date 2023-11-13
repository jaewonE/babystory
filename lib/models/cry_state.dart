enum CryIntensity { low, medium, high }

List<String> CryIntensityList = CryIntensity.values.map((e) => e.name).toList();

enum CryType { sad, hug, diaper, hungry, sleepy, awake, uncomfortable }

List<String> CryTypeList = CryType.values.map((e) => e.name).toList();

class CryState {
  late DateTime time;
  late CryType type;
  late CryIntensity intensity;
  late String? audioURL;
  late Map<String, double> predictMap;

  double? duration;

  CryState({
    required this.time,
    required this.type,
    required this.intensity,
    required this.predictMap,
    this.audioURL,
    this.duration,
  });

  CryState.fromJson(Map<String, dynamic> json) {
    time = json['time'] ?? DateTime.now();
    predictMap = _getTypeFromStateMap(json['predictMap']);
    type = predictMap.keys.toList()[0] as CryType;
    intensity = CryIntensity.values[json['intensity']];
    audioURL = json['audioURL'];
  }

  Map<String, double> _getTypeFromStateMap(Map<String, dynamic> stateMap) {
    Map<String, double> tempPredictMap = {};
    var keys = stateMap.keys.toList();

    while (keys.isNotEmpty) {
      String maxKey = keys[0];
      for (var key in keys) {
        if (stateMap[key]! > stateMap[maxKey]!) {
          maxKey = key;
        }
      }
      tempPredictMap[maxKey] = stateMap[maxKey];
      stateMap.remove(maxKey);
      keys.remove(maxKey);
    }
    return tempPredictMap;
  }

  Map<String, double> getPredictMap({int? limit}) {
    var keys = predictMap.keys.toList();
    limit ??= keys.length;

    Map<String, double> returnMap = {};
    for (var i = 0; i < limit; i++) {
      returnMap[keys[i]] = predictMap[keys[i]]!;
    }
    return returnMap;
  }
}
