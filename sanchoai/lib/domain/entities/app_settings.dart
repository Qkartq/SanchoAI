class AppSettings {
  String modelPath;
  String mmprojPath;
  String systemPrompt;
  double temperature;
  int maxTokens;
  int contextWindow;
  String theme;
  String language;

  AppSettings({
    this.modelPath = '',
    this.mmprojPath = '',
    this.systemPrompt = 'You are a helpful AI assistant.',
    this.temperature = 0.7,
    this.maxTokens = 512,
    this.contextWindow = 2048,
    this.theme = 'system',
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
    'modelPath': modelPath,
    'mmprojPath': mmprojPath,
    'systemPrompt': systemPrompt,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'contextWindow': contextWindow,
    'theme': theme,
    'language': language,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    modelPath: json['modelPath'] ?? '',
    mmprojPath: json['mmprojPath'] ?? '',
    systemPrompt: json['systemPrompt'] ?? 'You are a helpful AI assistant.',
    temperature: (json['temperature'] ?? 0.7).toDouble(),
    maxTokens: json['maxTokens'] ?? 512,
    contextWindow: json['contextWindow'] ?? 2048,
    theme: json['theme'] ?? 'system',
    language: json['language'] ?? 'en',
  );
}
