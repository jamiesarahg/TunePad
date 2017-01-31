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
  
  Socket current = null;

  // 1, 2, 4, 8, 16, or 32 (higher means faster)
  // pause time == millisPerMeasure / temp;
  int tempo = 8; // millisPerMeasure  // millisPerBeat


  PlayHead(this.current);

  void stepProgram(int millis) {
    if (current != null) {
      if (millis % (millisPerMeasure ~/ tempo) == 0) {
        current = current.parent.advance(this);
        if (current != null) {
          current.eval(this);
        }
      }
    }
  }


  bool animate(int millis) {

  }

}