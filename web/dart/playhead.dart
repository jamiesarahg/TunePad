/*
 * TunePad
 *
 * Michael S. Horn
 * Northwestern University
 * michael-horn@northwestern.edu
 * Copyright 2016, Michael S. Horn
 *
 * This project was funded by the National Science Foundation (grant DRL-1612619).
 * Any opinions, findings and conclusions or recommendations expressed in this
 * material are those of the author(s) and do not necessarily reflect the views
 * of the National Science Foundation (NSF).
 */
 
part of TunePad;


class PlayHead {
  
  Socket start = null;
  Socket current = null;

  // 1, 2, 4, 8, 16, or 32 (higher means faster)
  // pause time == millisPerMeasure / temp;
  int tempo = 8; // millisPerMeasure  // millisPerBeat

  num gain = 0.6;

  bool paused = false;

  PlayLink parent;


  PlayHead(this.start, this.parent) {
    current = start;
  }


  PlayHead.copy(PlayHead other) {
    start = other.start;
    current = other.current;
    tempo = other.tempo;
    paused = false;
    parent = other.parent;
  }


  bool get isDone => current == null;


  void restart() {
    current = start;
    tempo = 8;
    paused = false;
  }


  void resume() {
    paused = false;
  }


  void pause() {
    paused = true;
  }


  void stepProgram(int millis) {

    if (paused || current == null) return;

    // advance on the next matching beat
    if (millis % (millisPerMeasure ~/ tempo) == 0) {

      Socket source = null;
      while (current != null && current != source) {
        if (source == null && current != start) source = current;
        current = current.advance(this);
        if (current != null) {
          current.eval(this);
          if (!current.skipAhead(this)) break;
        }
      }
    }
  }


  bool animate(int millis) { }

}