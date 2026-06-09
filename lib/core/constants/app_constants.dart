class AppConstants {
  static const String bibleApiBaseUrl = 'https://bible-api.com';
  static const String defaultTranslation = 'web';

  /// Curated MVP verses for browse (free catalog subset per PRD)
  static const List<String> curatedReferences = [
    'John 3:16',
    'Psalm 23:1',
    'Philippians 4:13',
    'Jeremiah 29:11',
    'Proverbs 3:5',
    'Romans 8:28',
    'Isaiah 41:10',
    'Matthew 6:33',
    'Joshua 1:9',
    'Psalm 46:1',
    '1 Corinthians 13:4',
    'Ephesians 2:8',
    'Galatians 5:22',
    'Hebrews 11:1',
    'James 1:5',
    '1 John 4:19',
    'Genesis 1:1',
    'Psalm 119:105',
    'Matthew 28:19',
    'Romans 12:2',
  ];

  static const List<String> bibleBooks = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
    'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
    'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah', 'Lamentations',
    'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk',
    'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
    'Matthew', 'Mark', 'Luke', 'John', 'Acts',
    'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
    'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews',
    'James', '1 Peter', '2 Peter', '1 John', '2 John',
    '3 John', 'Jude', 'Revelation',
  ];
}
