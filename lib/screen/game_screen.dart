import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int width = 10, height = 20;
  String difficulty = '보통';
  List<String> dropdownList = ['쉬움', '보통', '어려움'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지뢰찾기'),
        centerTitle: true,
        actions: [
          Container(
            width: 80.0,
            margin: const EdgeInsets.only(right: 5.0),
            padding: const EdgeInsets.only(left: 5.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                isExpanded: true,
                borderRadius: BorderRadius.circular(5.0),
                items: dropdownList.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Center(child: Text(item)),
                  );
                }).toList(),
                value: difficulty,
                onChanged: (String? value) {
                  setState(() {
                    difficulty = value!;

                    // easy: 6, 12
                    // normal: 10, 20
                    // hard: 13, 26
                    switch (difficulty) {
                      case '쉬움':
                        width = 6;
                        height = 12;
                        break;
                      case '보통':
                        width = 10;
                        height = 20;
                        break;
                      case '어려움':
                        width = 13;
                        height = 26;
                        break;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: GameMainUI(
        x: width,
        y: height,
      ),
    );
  }
}

class GameMainUI extends StatefulWidget {
  final int x, y;

  const GameMainUI({Key? key, required this.x, required this.y})
      : super(key: key);

  @override
  State<GameMainUI> createState() => _GameMainUIState();
}

class _GameMainUIState extends State<GameMainUI> {
  var dx = [-1, 1, 0, 0, -1, 1, -1, 1];
  var dy = [0, 0, -1, 1, -1, -1, 1, 1];

  static const green = Color(0xFF8DB94D);
  static const lightGreen = Color(0xFFA2C658);
  static const ivory = Color(0xFFDDC1A3);
  static const darkIvory = Color(0xFFD0B89D);

  bool isFirst = true;
  bool isFailed = false;
  bool isReBuilded = false;
  int digCnt = 0;

  final backColors = [
    for (int c = 0; c < 40; c++)
      [
        for (int r = 0; r < 20; r++)
          (c % 2 + r % 2) % 2 == 0 ? darkIvory : ivory
      ]
  ];
  var frontColors = [
    for (int c = 0; c < 40; c++)
      [
        for (int r = 0; r < 20; r++)
          (c % 2 + r % 2) % 2 == 0 ? green : lightGreen
      ]
  ];
  var field = [
    for (int c = 0; c < 40; c++) [for (int r = 0; r < 20; r++) 0]
  ];
  var flag = [
    for (int c = 0; c < 40; c++) [for (int r = 0; r < 20; r++) 0]
  ];
  var isClicked = [
    for (int c = 0; c < 40; c++) [for (int r = 0; r < 20; r++) false]
  ];

  // initState 에서 초기화
  late int flagCnt; // 현재 깃발 개수
  late int width;
  late int height;

  void _changeColor(int x, int y) {
    frontColors[y][x] = frontColors[y][x] != backColors[y][x]
        ? backColors[y][x]
        : frontColors[y][x];
  }

  void dig(int x, int y) {
    // 첫 터치 기준으로 맵 생성
    if (isFirst) {
      mineGenerator(x, y);
      isFirst = false;
    }

    // 파려는 곳이 깃발일 때
    if (flag[y][x] == 9) return;

    // 파려는 곳이 지뢰일 때
    if (field[y][x] == 9) {
      isFailed = true;
      return;
    }

    // 그냥 땅 파기
    if (field[y][x] != 0 && frontColors[y][x] != backColors[y][x]) {
      _changeColor(x, y);
      digCnt++;
      return;
    }

    // 주변에 지뢰가 없는 땅들 한번에 파주기 (재귀로 구현)
    if (field[y][x] == 0) {
      _changeColor(x, y);
      digCnt++;

      for (int i = 0; i < 8; i++) {
        int nx = x + dx[i];
        int ny = y + dy[i];

        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        if (frontColors[ny][nx] == backColors[ny][nx]) continue;

        dig(nx, ny);
      }
    } // 깃발 제외한 주변 땅 파기
    else if (field[y][x] == flag[y][x]) {
      for (int i = 0; i < 8; i++) {
        int nx = x + dx[i];
        int ny = y + dy[i];

        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        if (frontColors[ny][nx] == backColors[ny][nx] || flag[ny][nx] == 9)
          continue;

        dig(nx, ny);
      }
    }
  }

  bool isBorderingPossible(int x, int y) {
    // 팠던 땅의 테두리 표시 유무 감별
    // (주변에 안 판 땅 개수와 깃발 개수를 세어 x, y 필드의 숫자 비교)
    int cnt = 0;
    int flagCnt = 0;
    if (frontColors[y][x] == backColors[y][x]) {
      for (int i = 0; i < 8; i++) {
        int nx = x + dx[i];
        int ny = y + dy[i];

        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;

        if (frontColors[ny][nx] != backColors[ny][nx]) cnt++;
        if (flag[ny][nx] == 9) flagCnt++;
      }
    }

    // 테스트용
    // 깃발 / 파기 옵션 넣어서 setFlag 넣어야 함
    if (frontColors[y][x] != backColors[y][x]) setFlag(x, y);

    return (frontColors[y][x] != backColors[y][x] ||
        (flagCnt == field[y][x] && cnt != field[y][x]));
  }

  Border makeBorder(int x, int y) {
    // 클릭 테두리
    if (isClicked[y][x]) {
      isClicked[y][x] = false;
      return Border.all(
        color: const Color(0xFF558A34),
        width: 3.0,
      );
    }

    // left, right, top, bottom
    var isBoundary = [false, false, false, false];

    const border = [
      BorderSide(
        color: Color(0xFF8EAD4D),
        width: 1.5,
      ),
      BorderSide.none,
    ];

    // 경계선 탐색

    final isFront = frontColors[y][x] == backColors[y][x];

    for (int i = 0; i < 4; i++) {
      int nx = x + dx[i];
      int ny = y + dy[i];

      if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;

      isBoundary[i] = isFront != (frontColors[ny][nx] == backColors[ny][nx]);
    }

    return Border(
      left: border[isBoundary[0] ? 0 : 1],
      right: border[isBoundary[1] ? 0 : 1],
      top: border[isBoundary[2] ? 0 : 1],
      bottom: border[isBoundary[3] ? 0 : 1],
    );
  }

  void mineGenerator(int x, int y) {
    int mines = width * height ~/ 6;

    while (mines > 0) {
      int rx = Random().nextInt(width);
      int ry = Random().nextInt(height);

      if (field[ry][rx] == 9) continue;
      if (rx <= x + 1 && rx >= x - 1 && ry <= y + 1 && ry >= y - 1) continue;

      field[ry][rx] = 9;
      mines--;

      // counter
      for (int k = 0; k < 8; k++) {
        int nx = rx + dx[k];
        int ny = ry + dy[k];

        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        if (field[ny][nx] == 9) continue;

        field[ny][nx]++;
      }
    }
  }

  void setFlag(int x, int y) {
    // 깃발이 이미 꽂혀 있을 때
    if (flag[y][x] == 9) {
      flagCnt++;
      int cnt = 0;

      for (int i = 0; i < 8; i++) {
        int nx = x + dx[i];
        int ny = y + dy[i];

        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        if (flag[ny][nx] == 9) {
          cnt++;
          continue;
        }

        flag[ny][nx]--;
      }
      // 깃발 표시(9) 사라지고 주변 깃발 개수(cnt)
      flag[y][x] = cnt;
    } else {
      // 깃발 꽂기
      flag[y][x] = 9;
      flagCnt--;

      for (int i = 0; i < 8; i++) {
        int nx = x + dx[i];
        int ny = y + dy[i];

        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        if (flag[ny][nx] == 9) continue;

        flag[ny][nx]++;
      }
    }
  }

  Widget? setContent(int x, int y) {
    const numColors = [
      Colors.blueAccent,
      Color(0xFF558A34),
      Colors.red,
      Colors.deepPurpleAccent,
      Colors.yellow,
      Colors.teal,
      Colors.orange,
      Colors.grey
    ];

    // 파인 땅이면 텍스트 위젯 리턴
    if (frontColors[y][x] == backColors[y][x]) {
      return field[y][x] != 0
          ? LayoutBuilder(
              builder: (context, constraints) => Text('${field[y][x]}',
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.7,
                    fontWeight: FontWeight.bold,
                    color: numColors[field[y][x] - 1],
                  )))
          : null;
    } else {
      // 파이지 않은 땅일때 깃발이 꽂혀있다면 깃발 아이콘 리턴
      return flag[y][x] == 9
          ? LayoutBuilder(
              builder: (context, constraints) => Icon(
                    Icons.flag,
                    size: constraints.maxWidth * 0.7,
                  ))
          : null;
    }
  }

  void reBuild() {
    // init data
    isFirst = true;
    isFailed = false;
    digCnt = 0;

    frontColors = [
      for (int c = 0; c < 40; c++)
        [
          for (int r = 0; r < 20; r++)
            (c % 2 + r % 2) % 2 == 0 ? green : lightGreen
        ]
    ];
    field = [
      for (int c = 0; c < 40; c++) [for (int r = 0; r < 20; r++) 0]
    ];
    flag = [
      for (int c = 0; c < 40; c++) [for (int r = 0; r < 20; r++) 0]
    ];

    flagCnt = width * height ~/ 6;

    isReBuilded = true;
  }

  @override
  void initState() {
    super.initState();
    flagCnt = widget.x * widget.y ~/ 6;
    width = widget.x;
    height = widget.y;
  }

  @override
  void didUpdateWidget(GameMainUI oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 난이도 변경 시 초기화
    if (oldWidget.x != widget.x) {
      width = widget.x;
      height = widget.y;
      reBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = digCnt == width * height - width * height ~/ 6;
    final isEnd = isSuccess || isFailed;
    Future.delayed(Duration.zero, () {
      isReBuilded = false;
    });

    // 끝나면 다이얼로그 출력
    if (isEnd) {
      Future.delayed(const Duration(milliseconds: 800), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            if (isSuccess) {
              return AlertDialog(
                title: const Text('이걸 깨네'),
                content: const Text('어케 했누...'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        reBuild();
                      });
                    },
                    child: const Text('다시하쉴?'),
                  ),
                  TextButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    child: const Text('나갈랭'),
                  ),
                ],
              );
            } else {
              return AlertDialog(
                title: const Text('퍼-엉'),
                content: const Text('풉ㅋ'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        reBuild();
                      });
                    },
                    child: const Text('다시하쉴?'),
                  ),
                  TextButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    child: const Text('나갈랭'),
                  ),
                ],
              );
            }
          },
        );
      });
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      child: Column(
        children: [
          // InfoUIField
          Container(
            margin: const EdgeInsets.fromLTRB(0, 10.0, 0, 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flag),
                Text(
                  ': $flagCnt',
                  style: const TextStyle(
                    fontSize: 20.0,
                  ),
                ),
                // TimerUI
                TimerUI(
                  isPlaying: !isFirst,
                  isEnd: isEnd,
                  isReBuilded: isReBuilded,
                ),
              ],
            ),
          ),
          // GameUIField
          Expanded(
            child: Stack(
              children: [
                // GameField
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int r = 0; r < width; r++)
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int c = 0; c < height; c++)
                              Flexible(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: frontColors[c][r],
                                    ),
                                    child: Center(child: setContent(r, c)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                  ],
                ),

                // BorderField
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int r = 0; r < width; r++)
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int c = 0; c < height; c++)
                              Flexible(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isFirst) {
                                        dig(r, c);
                                      }

                                      if (isBorderingPossible(r, c)) {
                                        isClicked[c][r] = true;
                                      }
                                    });
                                  },
                                  onDoubleTap: () {
                                    setState(() {
                                      dig(r, c);
                                    });
                                  },
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: isEnd && !isSuccess && field[c][r] == 9
                                        ? Container(
                                            color: Colors.red,
                                            child: LayoutBuilder(
                                                builder: (context, constraints) =>
                                                    Icon(
                                                      Icons.center_focus_weak_rounded,
                                                      color: Colors.black,
                                                      size: constraints.maxWidth * 0.9,
                                                    )
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              border: makeBorder(r, c),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimerUI extends StatefulWidget {
  final bool isPlaying, isEnd, isReBuilded;

  const TimerUI(
      {Key? key,
      required this.isPlaying,
      required this.isEnd,
      required this.isReBuilded})
      : super(key: key);

  @override
  State<TimerUI> createState() => _TimerUIState();
}

class _TimerUIState extends State<TimerUI> {
  Timer? timer;
  int time = 0;

  void increaseTime() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        time++;
      });
    });
  }

  @override
  void didUpdateWidget(TimerUI oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 첫 클릭 시 실행됨
    if (!oldWidget.isPlaying && widget.isPlaying) {
      increaseTime();
    }

    // 끝났을 때 실행됨
    if (widget.isEnd) {
      timer!.cancel();
    }

    // 게임 재시작 될 때 시간 초기화
    if (!oldWidget.isReBuilded && widget.isReBuilded) {
      if (timer != null) timer!.cancel(); 
      time = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 50.0),
      child: Row(
        children: [
          const Icon(Icons.timer),
          Text(
            ': $time',
            style: const TextStyle(
              fontSize: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}
