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

Random rand = new Random();


class BeatBlock extends TuneBlock {

  // millis through the measure so far
  int playTimer = 0;

  // This will be 4, 8, or 16
  int numBeats;

  // milliseconds per beat for this block
  int beatLength;

  // index into the beat array
  int beatIndex = -1;

  bool isPlaying = false;

  List<BeatButton> beats;

  Button muteButton;


  BeatBlock(Map json, TunePad workspace) : super(json, workspace) {
    numBeats = json['beats'];
    beatLength = millisPerMeasure ~/ numBeats;
    hasTopConnector = false;
    hasBottomConnector = false;
    Sounds.loadSound("${top.code}", json['file']);
    muteButton = new BlockButton(this, "mute");
    _buttons.add(muteButton);


    num arc = PI * 2 / numBeats;
    num r = 0.775 * BLOCK_WIDTH;

    beats = new List<BeatButton>();
    for (int i=0; i<numBeats; i++) {
      beats.add(
        new BeatButton(this)
          ..centerX = r * cos(PI * -0.5 + arc * i)
          ..centerY = r * sin(PI * -0.5 + arc * i)
      );
      _buttons.add(beats[i]);
    }
  }


  bool animate(int millis) {
    super.animate(millis);
    if (isPlaying) {
      playTimer = (millis.round() % millisPerMeasure);
    }
    return isPlaying || _dragging;
  }


  TuneBlock eval(int millis) {
    if (isPlaying) {
      playTimer = (millis.round() % millisPerMeasure);
      if (playTimer ~/ beatLength != beatIndex) {
        beatIndex = playTimer ~/ beatLength;
        if (beats[beatIndex].value > 0) {
          Sounds.playSound("${top.code}");
          beats[beatIndex].value = 200;
        }
      }
    }
    return this;
  }


  void draw(CanvasRenderingContext2D ctx) {
    num r1 = BLOCK_WIDTH / 2;
    num r2 = r1 * 2.0;
    num r3 = r1 * 1.55;
    ctx.save();
    {
      ctx.translate(cx, cy);
      ctx.rotate(-PI / 2);

      // spinning arc
      if (isPlaying) {
        ctx.rotate(PI / -16);
        ctx.fillStyle = "rgba(255, 0, 0, 0.2)";
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.arc(0, 0, r2, 0, PI * 2 * playTimer / millisPerMeasure, false);
        ctx.closePath();
        ctx.fill();
        ctx.rotate(PI / 16);
      }

      // beat marks
      /*
      num arc = PI * 2 / numBeats;
      for (int i=0; i<numBeats; i++) {
        ctx.fillStyle = (beats[i] > 0) ? "rgba(255, 0, 0, 0.7)" : "white";
        ctx.beginPath();
        num r4 = 10 + 10 * (beats[i] / 200);
        ctx.arc(r3, 0, r4, 0, PI * 2, true);
        ctx.fill();
        ctx.rotate(arc);
      }
      */

      // center "puck"
      ctx.fillStyle = "#333";
      ctx.strokeStyle = "#eee";
      ctx.beginPath();
      ctx.arc(0, 0, r1, 0, PI * 2, true);
      ctx.lineWidth = 3;
      ctx.stroke();
      ctx.shadowOffsetX = 0;
      ctx.shadowOffsetY = 0;
      ctx.shadowBlur = 10;
      ctx.shadowColor = "rgba(0, 0, 0, 0.6)";
      ctx.fill();

      // topcode
      top.x = 0.0;
      top.y = 0.0;
      //top.draw(ctx);

    }
    ctx.restore();

    _drawButtons(ctx);
  }

  void buttonCallback(BlockButton target) {
    if (target is BeatButton) {
      target.toggle();
    } else {
      isPlaying = !isPlaying;
      muteButton.image.src = isPlaying ? "images/buttons/volume-up.svg" : "images/buttons/mute.svg";
    }
  }

}


class BeatButton extends BlockButton {

  int value;

  BeatButton(BeatBlock block) : super(block, "mute") {
    value = rand.nextInt(2);
    width = 20;
    height = 20;
  }


  void toggle() {
    value = (value > 0) ? 0 : 1;
  }


  bool animate(int millis) {
    if (value > 30) value -= 5;
  }


  void draw(CanvasRenderingContext2D ctx) {
    ctx.fillStyle = (value > 0) ? "rgba(255, 0, 0, 0.7)" : "white";
    ctx.beginPath();
    num r = 10 + 10 * value / 200;    
    ctx.arc(centerX, centerY, r, 0, PI * 2, true);
    ctx.fill();
  }
}

