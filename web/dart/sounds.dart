part of TunePad;

class Sounds {

  static AudioContext audio = new AudioContext();

  static Map sounds = new Map();
  static bool mute = false;


  static void loadSound(String name, String url) {
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


  static bool hasSound(String name) {
    return (sounds[name] != null);
  }


  static void playSound(String name, { volume : 1.0, playback : 1.0 }) {
    if (sounds[name] != null && !mute) {
      AudioBufferSourceNode source = audio.createBufferSource();
      source.buffer = sounds[name];
      source.loop = false;
      source.playbackRate.value = playback;

      GainNode gain = audio.createGain();
      source.connectNode(gain);
      gain.connectNode(audio.destination);
      gain.gain.value = volume;
      //source.connectNode(audio.destination, 0, 0);
      source.start(0);
    }
  }
}