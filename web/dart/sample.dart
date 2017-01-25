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

class SoundBlock extends TuneBlock {

  // when this block first starts vocalizing (millis)
  num _startTime = -1;  

  // used to animate sound playback
  AnalyserNode _analyzer = null;
  Uint8List _audioData;


  SoundBlock(Map json, TunePad workspace) : super(json, workspace) { 
    Sounds.loadSound("${top.code}", json['file']);
    _analyzer = audio.createAnalyser();
    _analyzer.fftSize = 512;
    _audioData = new Uint8List(_analyzer.frequencyBinCount);    
  }


  TuneBlock eval(num millis) {
    if (_startTime < 0) {
      _startTime = millis;
      _playSound("${top.code}");
      return this;
    } 
    else if (millis - _startTime >= millisPerMeasure) {
      _startTime = -1;
      return above;
    }
    else {
      return this;
    }
  }


  bool animate(num millis) {
    bool refresh = false;
    if (super.animate(millis)) refresh = true;
    if (_startTime > 0) refresh = true;
    return refresh;
  }


  void draw(CanvasRenderingContext2D ctx) {
    super.draw(ctx);

    if (_startTime > 0) {
      _analyzer.getByteTimeDomainData(_audioData);
      num alpha = min(1.0, (_audioData[50] - 128).abs() / 64.0);  // 128
      ctx.fillStyle = "rgba(255, 255, 255, $alpha)";
      ctx.fillRect(blockX, blockY, _width, _width);
      ctx.strokeStyle = "white";
      ctx.lineWidth = 4;
      ctx.strokeRect(blockX, blockY, _width, _width);
    }

    top.x = cx;
    top.y = cy;
    top.diameter = _width * 0.65;
    //top.draw(ctx);

    ctx.save(); 
    {
      ctx.translate(cx - _width / 2, cy);
      AudioBuffer buffer = Sounds.sounds["${top.code}"];
      if (buffer != null) {
        Float32List data = buffer.getChannelData(0);
        int samples = 75;
        int stride = data.length ~/ samples;
        ctx.lineWidth = 0.5;
        ctx.strokeStyle = "white";
        ctx.beginPath();
        ctx.moveTo(0, 0);
        for (int i=0; i<samples; i++) {
          ctx.lineTo(i, data[i * stride] * 30);
        }
        ctx.stroke();
      }
    }
    ctx.restore();

  }


  void _playSound(String key) {
    AudioBuffer buffer = Sounds.sounds[key];

    if (buffer != null) {
      var source = audio.createBufferSource();
      source.buffer = buffer;
      source.connectNode(_analyzer);
      _analyzer.connectNode(audio.destination);
      source.start(0);
    }    
  }
}

