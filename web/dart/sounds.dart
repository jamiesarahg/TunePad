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

/**
 * Convenience class for dealing with web audio
 */
class Sounds {

  // one reference to the browser's audio context
  static AudioContext audio = new AudioContext();

  // contains all loaded sounds
  static Map sounds = new Map();

  // global mute 
  static bool mute = false;


/**
 * Loads a sound into the system
 */
  static void loadSound(String name, String url) {
    if (!hasSound(name)) {
      HttpRequest request = new HttpRequest();
      request.open("GET", url, async: true);
      request.responseType = "arraybuffer";
      request.onLoad.listen((e) {
        audio.decodeAudioData(request.response).then((AudioBuffer buffer) {
          if (buffer != null) sounds[name] = buffer;
        });      
      });
      request.onError.listen((e) => print("BufferLoader: XHR error"));
      request.send();
    }
  }


/** 
 * Returns true if the sound has been loaded
 */
  static bool hasSound(String name) {
    return (sounds[name] != null);
  }


/**
 * Play a sound 
 *    volume: 0.0 - 1.0
 *    playback rate: 1.0 default
 */
  static void playSound(String name, [num volume = 1.0, playback = 1.0 ]) {
    if (sounds[name] != null && !mute) {
      AudioBufferSourceNode source = audio.createBufferSource();
      source.buffer = sounds[name];
      source.loop = false;
      source.playbackRate.value = playback;

      // gain node for volue
      GainNode gain = audio.createGain();
      source.connectNode(gain);
      gain.gain.value = volume;
      gain.connectNode(audio.destination);

      source.start(0);
    }
  }
}