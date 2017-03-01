/*
 * TunePad
 *
 * Michael S. Horn
 * Northwestern University
 * michael-horn@northwestern.edu
 * Copyright 2017, Michael S. Horn
 *
 * This project was funded by the National Science Foundation (grant DRL-1612619).
 * Any opinions, findings and conclusions or recommendations expressed in this
 * material are those of the author(s) and do not necessarily reflect the views
 * of the National Science Foundation (NSF).
 */
part of TunePad;

const int trackHeight = 30;  
const int visibleMeasures = 4;

/**
 * Shows tracks playing out rythms over time. 
 */
class TuneScore {

  // width of the score in pixels
  num left, bottom, width;

  // duration of the visible track in millis
  int duration = millisPerMeasure * visibleMeasures;  // show 12 measures

  // list of tracks in the score
  List<TuneTrack> tracks = new List<TuneTrack>();

  // background color
  String background = "#555";

  // current elapsed time in millis
  int now = 0;

  TuneScore(this.left, this.bottom, this.width) {
    tracks.add(new TuneTrack(this));
  }

  num get height => tracks.length * trackHeight;


  addNote(int track, int startTime, int duration, String color) {
    if (track >= 0 && track < tracks.length) {
      tracks[track].addNote(startTime, duration, color);
    }
  }


  num trackToY(int track) {
    return bottom - height + track * trackHeight;
  }


  num timeToX(int time) {
    return (left + width) - (now - time) * width / duration;
  }


  num timeToWidth(int time) {
    return time * width / duration;
  }


  bool animate(int millis) {
    now = millis;
    return false;
  }


  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.fillStyle = background;
      ctx.fillRect(left, bottom - height, width, height);
      for (int i=0; i<tracks.length; i++) {
        tracks[i].draw(ctx, bottom - height + i * trackHeight);
      }
    }
    ctx.restore();
  }
}


class TuneTrack {

  TuneScore score;

  List<TuneNote> notes = new List<TuneNote>();

  TuneTrack(this.score);

  void addNote(int startTime, int duration, String color) {
    notes.add(new TuneNote(startTime, duration, color));
  }


  void draw(CanvasRenderingContext2D ctx, num top) {
    ctx.save();
    {
      ctx.strokeStyle = "#999";
      for (int i=notes.length - 1; i >= 0; i--) {
        TuneNote note = notes[i];
        ctx.fillStyle = note.color;
        ctx.fillRect(
          score.timeToX(note.start), top, 
          score.timeToWidth(millisPerBeat), trackHeight);
      }
    }
    ctx.restore();
  }
}


class TuneNote {

  int start; // start time in millis
  int duration; // duration in millis
  String color; 

  TuneNote(this.start, this.duration, this.color);
}