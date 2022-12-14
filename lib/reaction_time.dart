import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_for_teamproject/Theme/color.dart';
import 'package:flash_for_teamproject/Theme/font.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:sliding_number/sliding_number.dart';
import 'package:time/time.dart';

class ReactionTime extends StatefulWidget {
  const ReactionTime({
    Key? key,
  }) : super(key: key);

  @override
  _ReactionTimeState createState() => _ReactionTimeState();
}

class _ReactionTimeState extends State<ReactionTime> {
  _ReactionTimeState({Key? key});
  bool isStarted = false; //게임 시작 여부
  bool isTimeToTouch = false; //false시 ready, true시 touch
  bool isKeepGoing = false; //true시 KeepGoing페이지

  Timer _timer = new Timer(const Duration(), () {}); //타이머
  var _time = 0; //타이머 시간 표시
  var _reactionTime = 0;
  var _RandomTime = 0;
  var _totalReactionTime = 0; //반응속도 총합
  int second = 0; //걸린 시간 초
  var milisecond = '0'; //걸린 시간 ms

  var _isPlaying = false; // 타이머 작동/정지 여부
  var playCount = 5; //한 번에 총 n번 플레이한다
  var missTouchCount = 0; //잘못 누른 횟수
  var score = 0; //최종 점수. 점수 공식은 _totalReactionTime + (500 * missTouchCount)
  final audioPlayer = AudioPlayer();

  Widget screenChange() {
    if (playCount <= 0) {
      return ReactionTimeResult();
    } else if (isStarted == false &&
        isTimeToTouch == false &&
        isKeepGoing == false) {
      return ReactionTimeNotStarted();
    } else if (isStarted == true &&
        isTimeToTouch == false &&
        isKeepGoing == false) {
      return ReactionTimeReady();
    } else if (isStarted == true &&
        isTimeToTouch == true &&
        isKeepGoing == false) {
      return ReactionTimeTouch();
    } else if (isStarted == true &&
        isTimeToTouch == true &&
        isKeepGoing == true) {
      return ReactionTimeKeepGoing();
    } else {
      return ReactionTimeError();
    }
  }

  Future<DocumentReference> addScoreToReactionTime(int score) {
    return FirebaseFirestore.instance
        .collection('ReactionTime')
        .add(<String, dynamic>{
      'score': score,
      'name': FirebaseAuth.instance.currentUser!.displayName,
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: screenChange(),
      ),
    );
  }

  Widget ReactionTimeNotStarted() {
    return MaterialButton(
      color: ReturnColor('blue'),
      minWidth: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      onPressed: (() {
        print('hello'); //잘 되는지 확인
        setState(() {
          if (isStarted == false) {
            isStarted = true;
          }
          _RandomTime = Random().nextInt(2000) + 1000;
        });
        _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
          if (this.mounted) {
            setState(() {
              _time = _time + 1;
            });
          }
        });
        Future.delayed(Duration(milliseconds: (_RandomTime)), () async {
          setState(() {
            isTimeToTouch = true;
            _isPlaying = true;
          });
        });
      }),
      child: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          SizedBox(
            width: 330,
            height: 50,
            child: Text(
              'Reaction Time',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 100,
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Center(
              child: Text(
                'When the red screen turns green, Touch the screen as quickly as you can.',
                style: ABeeZee(20, 23.64),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Text(
              'Touch to Start',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget ReactionTimeReady() {
    return MaterialButton(
      color: ReturnColor('red'),
      minWidth: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      onPressed: (() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wrong Touch! +500ms penalty'),
            action: SnackBarAction(
              label: 'Okay',
              onPressed: () {},
            ),
          ),
        );
        missTouchCount = missTouchCount + 1;
      }),
      child: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          SizedBox(
            width: 330,
            height: 50,
            child: Text(
              'Reaction Time',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 100,
          ),
          SizedBox(
              width: 100,
              height: 100,
              child: Icon(
                Icons.hourglass_top,
                size: 100,
                color: ReturnColor('white'),
              )),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Text(
              'Ready...',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget ReactionTimeTouch() {
    return MaterialButton(
      color: ReturnColor('green'),
      minWidth: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      onPressed: (() {
        print(_time);
        audioPlayer.play(AssetSource('sound/reaction_time_pop.wav'));
        setState(() {
          isKeepGoing = true;
          _timer.cancel();
          _time = _time - (_RandomTime ~/ 10);
          second = (_time * 10).milliseconds.inSeconds;
          milisecond = '${_time % 100}'.padLeft(2, '0');
          _reactionTime = _time;
          playCount = playCount - 1;
          _totalReactionTime = _totalReactionTime + _reactionTime;
        });
        print(_time);
        print(_RandomTime);
        print(_totalReactionTime);
      }),
      child: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          SizedBox(
            width: 330,
            height: 50,
            child: Text(
              'Reaction Time',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 100,
          ),
          SizedBox(
              width: 100,
              height: 100,
              child: Icon(Icons.hourglass_bottom,
                  size: 100, color: ReturnColor('white'))),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Text(
              'Touch!',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget ReactionTimeKeepGoing() {
    return MaterialButton(
      color: ReturnColor('blue'),
      minWidth: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      onPressed: (() {
        setState(() {
          _RandomTime = Random().nextInt(2000) + 1000;
          isStarted = true;
          isTimeToTouch = false;
          isKeepGoing = false;
          _isPlaying = false;
          _time = 0;
        });
        print(_time);

        _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
          if (this.mounted) {
            setState(() {
              _time = _time + 1;
            });
          }
        });
        Future.delayed(Duration(milliseconds: _RandomTime), () async {
          setState(() {
            isTimeToTouch = true;
            _isPlaying = true;
          });
        });
      }),
      child: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          SizedBox(
            width: 330,
            height: 50,
            child: Text(
              'Reaction Time',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 150,
          ),
          SizedBox(
              width: 330,
              height: 100,
              child: Text(
                '$second.$milisecond s',
                style: Timetravel(40, 42.6),
                textAlign: TextAlign.center,
              )),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Text(
              'Touch to\nKeep Going',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 40,
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Text(
              '${playCount} Times Left',
              style: ABeeZee(20, 23.64),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget ReactionTimeResult() {
    score = (_totalReactionTime * 10) + (500 * missTouchCount);

    return MaterialButton(
      color: ReturnColor('blue'),
      minWidth: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      onPressed: (() {}),
      child: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          SizedBox(
            width: 330,
            height: 50,
            child: Text(
              'Reaction Time',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'Result',
                  style: ABeeZee(32, 37.82),
                  textAlign: TextAlign.center,
                ),
              )),
          SlidingNumber(
            number: score,
            style: Timetravel(40, 42.6),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutQuint,
          ),
          SizedBox(
            height: 50,
          ),
          SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  '${_totalReactionTime / 100} s',
                  style: ABeeZee(32, 37.82),
                  textAlign: TextAlign.center,
                ),
              )),
          SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  '${missTouchCount} Times Miss',
                  style: ABeeZee(32, 37.82),
                  textAlign: TextAlign.center,
                ),
              )),
          MaterialButton(
            minWidth: 100,
            height: 100,
            onPressed: (() {
              Navigator.pop(context);
              _timer.cancel();
              addScoreToReactionTime(score);
            }),
            child: Icon(
              Icons.home,
              size: 50,
              color: ReturnColor('white'),
            ),
          )
        ],
      ),
    );
  }

  Widget ReactionTimeError() {
    return MaterialButton(
      color: ReturnColor('red'),
      minWidth: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      onPressed: (() {
        setState(() {
          isStarted = false;
          isTimeToTouch = false;
          isKeepGoing = false;
        });
      }),
      child: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          SizedBox(
            width: 330,
            height: 50,
            child: Text(
              'Reaction Time',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 100,
          ),
          SizedBox(
              width: 100,
              height: 100,
              child:
                  Icon(Icons.warning, size: 100, color: ReturnColor('white'))),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Text(
              'ERROR!',
              style: ABeeZee(40, 47.28),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 300,
            height: 110,
            child: Text(
              'Touch The Screen\nTo Restart',
              style: ABeeZee(20, 25),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
