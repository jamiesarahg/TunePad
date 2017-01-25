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


class StartBlock extends TuneBlock {

  // used to toggle play / pause for the block chain
  bool _playing = true;

  // which block is currently vocalizing
  TuneBlock _playHead;


  StartBlock(Map json, TunePad workspace) : super(json, workspace) {
    hasBottomConnector = false;  // start blocks are always at the bottom of the stack
    color = json['color'];
    _playHead = this;
  }


  void play() {
    _playing = true;
  }

  void pause() {
    _playing = false;
  }

  void playPause() {
    if (_playing) {
      pause();
    } else {
      play();
    }
  }

  void stop() {
    _playing = false;
    _playHead = this;
  }

  bool get isPlaying => _playing;

  TuneBlock get playHead => _playHead;


/**
 * Start blocks take on the role of evaluating the programs by 
 * calling eval() on the playhead and advancing the flow of control.
 */
  void stepProgram(num millis) {
    while (_playing && _playHead != null) {

      // evaluate the current block
      TuneBlock next = _playHead.eval(millis);

      // the current block is still playing, so we do nothing...
      if (next == _playHead) {
        return;
      }

      // we've reached the end of the chain
      else if (next == null) {
        stop();
        workspace.draw();
      }

      // we're passing control onto a new block
      else {
        _playHead = next;
        workspace.draw();
      }
    }
  }


  TuneBlock eval(num millis) {
    return above; // start lock always returns next block in chain immediately
  }


  void draw(CanvasRenderingContext2D ctx) {
    super.draw(ctx);
    ctx.fillStyle = _dragging ? "white" : "rgba(255, 255, 255, 0.8)";
    ctx.strokeStyle = _dragging ? "white" : "rgba(255, 255, 255, 0.8)";
    num r = _width / 7;

    ctx.beginPath();
    ctx.arc(cx, cy, _width * 0.35, 0, PI * 2, true);
    ctx.lineWidth = 6;
    ctx.stroke();

    // draw a pause button
    if (_playing) {
      ctx.fillRect(cx - r*0.75, cy - r, r/2, r*2);
      ctx.fillRect(cx + r*0.25, cy - r, r/2, r*2);
    } 

    // draw a play button (triangle)
    else {
      num x = cx + 2;
      ctx.beginPath();
      ctx.moveTo(x - r, cy - r);
      ctx.lineTo(x + r, cy);
      ctx.lineTo(x - r, cy + r);
      ctx.closePath();
      ctx.fill();
    }
  }


  bool animate(int millis) {
    return _dragging;
  }


  void touchUp(Contact c) {
    playPause();
    super.touchUp(c);
  }
}

